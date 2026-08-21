public with sharing class CreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Incident Form Data' description='The incident form data.' required=false)
        public CopilotIncidentFormWrapper incidentData;

        @InvocableVariable(label='Subject' description='The subject of the incident' required=false)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=false)
        public String description;

        @InvocableVariable(label='Category' description='Optional category override' required=false)
        public String category;

        @InvocableVariable(label='Priority' description='Optional priority override' required=false)
        public String priority;

        @InvocableVariable(label='Urgency' description='Urgency level: Low, Medium, High' required=false)
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level: Low, Medium, High' required=false)
        public String impact;

        @InvocableVariable(label='Requester Email' description='Email of the employee requesting the incident' required=false)
        public String requesterEmail;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the incident was created successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        public String errorMessage;

        @InvocableVariable(label='Incident ID' description='The ID of the created incident record')
        public Id incidentId;

        @InvocableVariable(label='Incident Number' description='The auto-number reference of the created incident')
        public String incidentNumber;
    }

    @InvocableMethod(
        label='Create ITSM Incident'
        description='Creates an Incident record with automated categorization and priority assignment.'
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
            String reqEmail = req.incidentData != null && String.isNotBlank(req.incidentData.requesterEmail) ? req.incidentData.requesterEmail : req.requesterEmail;
            if (String.isNotBlank(reqEmail)) {
                emails.add(reqEmail.trim());
            }
        }

        Map<String, Id> emailToReporterId = new Map<String, Id>();
        if (!emails.isEmpty()) {
            for (User u : [SELECT Id, Email FROM User WHERE Email IN :emails AND IsActive = true WITH USER_MODE]) {
                emailToReporterId.put(u.Email.toLowerCase(), u.Id);
            }
            // Fallback to contacts if not user - map to contact's AccountId
            for (Contact c : [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :emails WITH USER_MODE]) {
                if (!emailToReporterId.containsKey(c.Email.toLowerCase())) {
                    if (c.AccountId != null) {
                        emailToReporterId.put(c.Email.toLowerCase(), c.AccountId);
                    }
                }
            }
        }

        for (Request req : requests) {
            String reqSubject = req.incidentData != null && String.isNotBlank(req.incidentData.subject) ? req.incidentData.subject : req.subject;
            String reqDescription = req.incidentData != null && String.isNotBlank(req.incidentData.description) ? req.incidentData.description : req.description;
            String reqCategory = req.incidentData != null && String.isNotBlank(req.incidentData.category) ? req.incidentData.category : req.category;
            String reqPriority = req.incidentData != null && String.isNotBlank(req.incidentData.priority) ? req.incidentData.priority : req.priority;
            String reqUrgency = req.incidentData != null && String.isNotBlank(req.incidentData.urgency) ? req.incidentData.urgency : req.urgency;
            String reqImpact = req.incidentData != null && String.isNotBlank(req.incidentData.impact) ? req.incidentData.impact : req.impact;
            String reqEmail = req.incidentData != null && String.isNotBlank(req.incidentData.requesterEmail) ? req.incidentData.requesterEmail : req.requesterEmail;

            Incident inc = new Incident();
            inc.Subject = reqSubject;
            inc.Description = reqDescription;
            inc.Status = 'New';

            // 1. Auto-Categorization Logic
            String resolvedCategory = 'Software'; // Default
            String textToAnalyze = ((reqSubject != null ? reqSubject : '') + ' ' + (reqDescription != null ? reqDescription : '')).toLowerCase();
            
            if (String.isNotBlank(reqCategory)) {
                resolvedCategory = reqCategory;
            } else {
                if (textToAnalyze.contains('vpn') || textToAnalyze.contains('wi-fi') || textToAnalyze.contains('wifi') || textToAnalyze.contains('network') || textToAnalyze.contains('outage') || textToAnalyze.contains('internet')) {
                    resolvedCategory = 'Network';
                } else if (textToAnalyze.contains('printer') || textToAnalyze.contains('print') || textToAnalyze.contains('toner') || textToAnalyze.contains('laptop') || textToAnalyze.contains('hardware') || textToAnalyze.contains('keyboard') || textToAnalyze.contains('mouse') || textToAnalyze.contains('screen')) {
                    resolvedCategory = 'Hardware';
                }
            }
            inc.Category = resolvedCategory;

            // 2. Auto-Priority Assignment Logic
            String resolvedPriority = 'Medium'; // Default
            if (String.isNotBlank(reqPriority)) {
                resolvedPriority = reqPriority;
            } else {
                if (textToAnalyze.contains('outage') || textToAnalyze.contains('critical') || textToAnalyze.contains('down') || textToAnalyze.contains('cannot work') || textToAnalyze.contains('emergency') || textToAnalyze.contains('blocked')) {
                    resolvedPriority = 'Critical';
                } else if (textToAnalyze.contains('printer') || textToAnalyze.contains('minor') || textToAnalyze.contains('reset') || textToAnalyze.contains('install')) {
                    resolvedPriority = 'Low';
                }
            }
            inc.Priority = resolvedPriority;

            // 2b. Auto-Urgency Assignment (required field)
            String resolvedUrgency = 'High'; // Default
            if (String.isNotBlank(reqUrgency)) {
                resolvedUrgency = reqUrgency;
            } else {
                if (resolvedPriority == 'Critical') {
                    resolvedUrgency = 'High';
                } else if (resolvedPriority == 'Low') {
                    resolvedUrgency = 'Low';
                }
            }
            inc.Urgency = resolvedUrgency;

            // 2c. Auto-Impact Assignment (required field)
            String resolvedImpact = 'High'; // Default
            if (String.isNotBlank(reqImpact)) {
                resolvedImpact = reqImpact;
            } else {
                if (textToAnalyze.contains('entire team') || textToAnalyze.contains('all users') || textToAnalyze.contains('company-wide') || textToAnalyze.contains('outage') || textToAnalyze.contains('everyone')) {
                    resolvedImpact = 'High';
                } else if (textToAnalyze.contains('only me') || textToAnalyze.contains('just me') || textToAnalyze.contains('minor')) {
                    resolvedImpact = 'Low';
                }
            }
            inc.Impact = resolvedImpact;

            // 2d. Auto-Type Assignment (Recurring detection)
            String resolvedType = 'Normal'; // Default
            if (textToAnalyze.contains('recurring') || textToAnalyze.contains('repeat') || textToAnalyze.contains('multiple times') || textToAnalyze.contains('frequent') || textToAnalyze.contains('again and again')) {
                resolvedType = 'Recurring';
            }
            inc.Type = resolvedType;

            // 3. Resolve Requester
            Id requesterId = UserInfo.getUserId(); // Default
            if (String.isNotBlank(reqEmail) && emailToReporterId.containsKey(reqEmail.toLowerCase())) {
                requesterId = emailToReporterId.get(reqEmail.toLowerCase());
            }
            inc.ReportedById = requesterId;

            // 4. Determine dynamic queue assignment based on category and priority
            String queueDevName = '';
            if (resolvedCategory == 'Hardware') {
                if (resolvedPriority == 'Critical') {
                    queueDevName = 'Hardware_Major_Incident_Queue';
                } else if (resolvedPriority == 'High') {
                    queueDevName = 'Hardware_High_Incident_Queue';
                } else {
                    queueDevName = 'Hardware_Normal_Incident_Queue';
                }
            } else if (resolvedCategory == 'Network') {
                if (resolvedPriority == 'Critical') {
                    queueDevName = 'Network_Major_Incident_Queue';
                } else if (resolvedPriority == 'High') {
                    queueDevName = 'Network_High_Incident_Queue';
                } else {
                    queueDevName = 'Network_Normal_Incident_Queue';
                }
            } else { // Software (default)
                if (resolvedPriority == 'Critical') {
                    queueDevName = 'Software_Major_Incident_Queue';
                } else if (resolvedPriority == 'High') {
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
                // Insert under user mode to respect FLS/CRUD
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, incidentsToInsert);
                List<SObject> recordsToInsert = decision.getRecords();
                if (recordsToInsert.isEmpty()) {
                    for (Request req : requests) {
                        Result r = new Result();
                        r.isSuccess = false;
                        r.errorMessage = 'You do not have permission to create Incidents.';
                        results.add(r);
                    }
                    return results;
                }
                insert recordsToInsert;
                
                List<Incident> insertedIncidents = [
                    SELECT Id, IncidentNumber 
                    FROM Incident 
                    WHERE Id IN :recordsToInsert
                ];
                
                Map<Id, String> incIdToNum = new Map<Id, String>();
                for (Incident i : insertedIncidents) {
                    incIdToNum.put(i.Id, i.IncidentNumber);
                }

                for (Integer idx = 0; idx < requests.size(); idx++) {
                    Incident insertedInc = (Incident) recordsToInsert[idx];
                    Result r = new Result();
                    r.isSuccess = true;
                    r.incidentId = insertedInc.Id;
                    r.incidentNumber = incIdToNum.get(insertedInc.Id);
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
}