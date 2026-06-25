public with sharing class CopilotCreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=true)
        public String description;

        @InvocableVariable(label='Category' description='Category of the incident (Network, Hardware, Software)' required=true)
        public String category;

        @InvocableVariable(label='Urgency' description='Urgency level (Low, Medium, High)' required=true)
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (Low, Medium, High)' required=true)
        public String impact;

        @InvocableVariable(label='Requester Email' description='Email of the employee requesting the incident' required=false)
        public String requesterEmail;

        @InvocableVariable(label='SubCategory' description='Optional subcategory' required=false)
        public String subCategory;

        @InvocableVariable(label='Type' description='Optional incident type' required=false)
        public String type;

        @InvocableVariable(label='Status' description='The status of the incident' required=false)
        @AuraEnabled
        public String status;

        @InvocableVariable(label='Priority' description='Optional priority override' required=false)
        @AuraEnabled
        public String priority;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the incident was created successfully')
        @AuraEnabled
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        @AuraEnabled
        public String errorMessage;

        @InvocableVariable(label='Incident ID' description='The ID of the created incident record')
        @AuraEnabled
        public Id incidentId;

        @InvocableVariable(label='Incident Number' description='The auto-number reference of the created incident')
        @AuraEnabled
        public String incidentNumber;

        @InvocableVariable(label='Priority' description='Automatically determined priority')
        @AuraEnabled
        public String priority;
    }

    @InvocableMethod(
        label='Copilot Create Incident'
        description='Creates an Incident record with automated priority assignment and queue routing.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Incident> incidentsToInsert = new List<Incident>();

        // Query queues for assignment
        Set<String> queueNames = new Set<String>{
            'Hardware_Major_Incident_Queue', 'Hardware_High_Incident_Queue', 'Hardware_Normal_Incident_Queue',
            'Network_Major_Incident_Queue', 'Network_High_Incident_Queue', 'Network_Normal_Incident_Queue',
            'Software_Major_Incident_Queue', 'Software_High_Incident_Queue', 'Software_Normal_Incident_Queue'
        };
        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames WITH USER_MODE]) {
            queueMap.put(g.DeveloperName, g.Id);
        }

        // Resolve Requesters in bulk if emails are provided
        Set<String> emails = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.requesterEmail)) {
                emails.add(req.requesterEmail.trim());
            }
        }

        Map<String, Id> emailToReporterId = new Map<String, Id>();
        if (!emails.isEmpty()) {
            for (User u : [SELECT Id, Email FROM User WHERE Email IN :emails AND IsActive = true WITH USER_MODE]) {
                emailToReporterId.put(u.Email.toLowerCase(), u.Id);
            }
            for (Contact c : [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails WITH USER_MODE]) {
                if (!emailToReporterId.containsKey(c.Email.toLowerCase()) && c.AccountId != null) {
                    emailToReporterId.put(c.Email.toLowerCase(), c.AccountId);
                }
            }
        }

        for (Request req : requests) {
            Incident inc = new Incident();
            inc.Subject = req.subject;
            inc.Description = req.description;
            inc.Category = req.category;
            inc.SubCategory = req.subCategory;
            inc.Type = String.isNotBlank(req.type) ? req.type : 'Normal';
            inc.Urgency = req.urgency;
            inc.Impact = req.impact;
            inc.Status = String.isNotBlank(req.status) ? req.status : 'New';

            // Determine Priority automatically from Impact and Urgency
            String calculatedPriority = 'Medium';
            if (String.isNotBlank(req.priority)) {
                calculatedPriority = req.priority;
            } else {
                if (req.impact == 'High') {
                    if (req.urgency == 'High') {
                        calculatedPriority = 'Critical';
                    } else if (req.urgency == 'Medium') {
                        calculatedPriority = 'High';
                    } else {
                        calculatedPriority = 'Medium';
                    }
                } else if (req.impact == 'Medium') {
                    if (req.urgency == 'High') {
                        calculatedPriority = 'High';
                    } else if (req.urgency == 'Medium') {
                        calculatedPriority = 'Medium';
                    } else {
                        calculatedPriority = 'Low';
                    }
                } else { // Low
                    if (req.urgency == 'High') {
                        calculatedPriority = 'Medium';
                    } else {
                        calculatedPriority = 'Low';
                    }
                }
            }
            inc.Priority = calculatedPriority;

            // Resolve ReportedById
            Id reporterId = UserInfo.getUserId();
            if (String.isNotBlank(req.requesterEmail) && emailToReporterId.containsKey(req.requesterEmail.toLowerCase())) {
                reporterId = emailToReporterId.get(req.requesterEmail.toLowerCase());
            }
            inc.ReportedById = reporterId;

            // Determine dynamic queue assignment based on category and priority
            String queueDevName = '';
            String cat = String.isNotBlank(req.category) ? req.category : 'Software';
            if (cat == 'Hardware') {
                if (calculatedPriority == 'Critical') {
                    queueDevName = 'Hardware_Major_Incident_Queue';
                } else if (calculatedPriority == 'High') {
                    queueDevName = 'Hardware_High_Incident_Queue';
                } else {
                    queueDevName = 'Hardware_Normal_Incident_Queue';
                }
            } else if (cat == 'Network') {
                if (calculatedPriority == 'Critical') {
                    queueDevName = 'Network_Major_Incident_Queue';
                } else if (calculatedPriority == 'High') {
                    queueDevName = 'Network_High_Incident_Queue';
                } else {
                    queueDevName = 'Network_Normal_Incident_Queue';
                }
            } else { // Software
                if (calculatedPriority == 'Critical') {
                    queueDevName = 'Software_Major_Incident_Queue';
                } else if (calculatedPriority == 'High') {
                    queueDevName = 'Software_High_Incident_Queue';
                } else {
                    queueDevName = 'Software_Normal_Incident_Queue';
                }
            }

            if (queueMap.containsKey(queueDevName)) {
                inc.OwnerId = queueMap.get(queueDevName);
                inc.AssignedGroupId = queueMap.get(queueDevName);
            }

            incidentsToInsert.add(inc);
        }

        if (!incidentsToInsert.isEmpty()) {
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, incidentsToInsert);
                List<SObject> recordsToInsert = decision.getRecords();
                if (recordsToInsert.isEmpty()) {
                    for (Request req : requests) {
                        Result r = new Result();
                        r.isSuccess = false;
                        r.errorMessage = 'Permission denied to create Incident.';
                        results.add(r);
                    }
                    return results;
                }
                insert recordsToInsert;

                List<Incident> insertedIncidents = [
                    SELECT Id, IncidentNumber, Priority 
                    FROM Incident 
                    WHERE Id IN :recordsToInsert
                ];
                Map<Id, Incident> insertedMap = new Map<Id, Incident>(insertedIncidents);

                for (Integer i = 0; i < requests.size(); i++) {
                    Incident created = (Incident) recordsToInsert[i];
                    Incident details = insertedMap.get(created.Id);
                    Result r = new Result();
                    r.isSuccess = true;
                    r.incidentId = created.Id;
                    r.incidentNumber = details.IncidentNumber;
                    r.priority = details.Priority;
                    results.add(r);
                }
            } catch (Exception e) {
                for (Request req : requests) {
                    Result r = new Result();
                    r.isSuccess = false;
                    r.errorMessage = e.getMessage();
                    results.add(r);
                }
            }
        }

        return results;
    }

    @AuraEnabled
    public static Result createIncidentLwc(
        String subject,
        String description,
        String category,
        String urgency,
        String impact,
        String requesterEmail,
        String subCategory,
        String type,
        String status,
        String priority
    ) {
        Request req = new Request();
        req.subject = subject;
        req.description = description;
        req.category = category;
        req.urgency = urgency;
        req.impact = impact;
        req.requesterEmail = requesterEmail;
        req.subCategory = subCategory;
        req.type = type;
        req.status = status;
        req.priority = priority;
        
        List<Result> results = createIncident(new List<Request>{ req });
        if (results != null && !results.isEmpty()) {
            return results[0];
        }
        Result failResult = new Result();
        failResult.isSuccess = false;
        failResult.errorMessage = 'Unknown error creating incident.';
        return failResult;
    }
}
