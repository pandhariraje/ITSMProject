public without sharing class ITSM_Copilot_CreateIncidentAction {
    public class Request {
        @InvocableVariable(label='Incident Form Data' description='Incident form wrapper data' required=true)
        public ITSM_Copilot_NewIncidentFormWrapper incidentForm;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the operation succeeded')
        @AuraEnabled
        public Boolean isSuccess;
        @InvocableVariable(label='Error Message' description='Details of any error')
        @AuraEnabled
        public String errorMessage;
        @InvocableVariable(label='Incident ID' description='The ID of the created incident')
        @AuraEnabled
        public Id incidentId;
        @InvocableVariable(label='Incident Number' description='The incident ticket number')
        @AuraEnabled
        public String incidentNumber;
        @InvocableVariable(label='Success Message' description='Success message to display')
        @AuraEnabled
        public String successMessage;
    }

    @InvocableMethod(
        label='ITSM Copilot Create Incident from Form'
        description='Creates an Incident record in system mode from the LWC form data with automated priority and owner assignment.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        // Query active portal user
        Id activePortalUserId = null;
        List<User> activePortalUsers = [
            SELECT Id 
            FROM User 
            WHERE Profile.Name = 'Employee Customer profile' AND IsActive = true AND LastLoginDate != null
            ORDER BY LastLoginDate DESC 
            LIMIT 1
        ];
        if (!activePortalUsers.isEmpty()) {
            activePortalUserId = activePortalUsers[0].Id;
        }

        // Query queues for assignment
        Set<String> queueNames = new Set<String>{
            'Hardware_Major_Incident_Queue', 'Hardware_High_Incident_Queue', 'Hardware_Normal_Incident_Queue',
            'Network_Major_Incident_Queue', 'Network_High_Incident_Queue', 'Network_Normal_Incident_Queue',
            'Software_Major_Incident_Queue', 'Software_High_Incident_Queue', 'Software_Normal_Incident_Queue'
        };
        Map<String, Id> queueMap = new Map<String, Id>();
        for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames]) {
            queueMap.put(g.DeveloperName, g.Id);
        }

        for (Request req : requests) {
            ITSM_Copilot_NewIncidentFormWrapper form = req.incidentForm;
            Result r = new Result();
            
            if (form != null && String.isNotBlank(form.incidentId)) {
                r.isSuccess = true;
                r.incidentId = form.incidentId;
                r.incidentNumber = form.incidentNumber;
                r.successMessage = 'Incident ' + form.incidentNumber + ' has been created successfully.';
                results.add(r);
                continue;
            }
            
            if (form == null || String.isBlank(form.subject) || String.isBlank(form.urgency) || String.isBlank(form.impact)) {
                r.isSuccess = false;
                r.errorMessage = 'Required fields (Subject, Urgency, Impact) are missing.';
                results.add(r);
                continue;
            }

            try {
                Incident inc = new Incident();
                inc.Subject = form.subject;
                inc.Description = form.description;
                inc.Category = form.category;
                inc.Type = 'Normal';
                inc.Urgency = form.urgency;
                inc.Impact = form.impact;
                inc.Status = String.isNotBlank(form.status) ? form.status : 'New';

                // Resolve Owner & Reporter
                Boolean isEmployeeCustomer = false;
                if (activePortalUserId != null) {
                    List<User> pUsers = [
                        SELECT Id, Profile.Name, UserRole.DeveloperName 
                        FROM User 
                        WHERE Id = :activePortalUserId AND IsActive = true 
                        LIMIT 1
                    ];
                    if (!pUsers.isEmpty()) {
                        User u = pUsers[0];
                        inc.ReportedById = u.Id;
                        isEmployeeCustomer = (u.Profile != null && u.Profile.Name == 'Employee Customer profile') || 
                                             (u.UserRole != null && u.UserRole.DeveloperName == 'PAdmiCustomerPersonAccount');
                    }
                }
                if (inc.ReportedById == null) {
                    inc.ReportedById = UserInfo.getUserId();
                }

                // Calculate Priority
                String calculatedPriority = 'Medium';
                if (form.impact == 'High') {
                    if (form.urgency == 'High') calculatedPriority = 'Critical';
                    else if (form.urgency == 'Medium') calculatedPriority = 'High';
                } else if (form.impact == 'Medium') {
                    if (form.urgency == 'High') calculatedPriority = 'High';
                    else if (form.urgency == 'Medium') calculatedPriority = 'Medium';
                    else calculatedPriority = 'Low';
                } else {
                    if (form.urgency == 'High') calculatedPriority = 'Medium';
                    else calculatedPriority = 'Low';
                }
                inc.Priority = calculatedPriority;

                // Route dynamic queue
                String queueDevName = '';
                String cat = String.isNotBlank(form.category) ? form.category : 'Software';
                if (cat == 'Hardware') {
                    if (calculatedPriority == 'Critical') queueDevName = 'Hardware_Major_Incident_Queue';
                    else if (calculatedPriority == 'High') queueDevName = 'Hardware_High_Incident_Queue';
                    else queueDevName = 'Hardware_Normal_Incident_Queue';
                } else if (cat == 'Network') {
                    if (calculatedPriority == 'Critical') queueDevName = 'Network_Major_Incident_Queue';
                    else if (calculatedPriority == 'High') queueDevName = 'Network_High_Incident_Queue';
                    else queueDevName = 'Network_Normal_Incident_Queue';
                } else {
                    if (calculatedPriority == 'Critical') queueDevName = 'Software_Major_Incident_Queue';
                    else if (calculatedPriority == 'High') queueDevName = 'Software_High_Incident_Queue';
                    else queueDevName = 'Software_Normal_Incident_Queue';
                }

                if (isEmployeeCustomer) {
                    inc.OwnerId = inc.ReportedById;
                    if (queueMap.containsKey(queueDevName)) {
                        inc.AssignedGroupId = queueMap.get(queueDevName);
                    }
                } else {
                    if (queueMap.containsKey(queueDevName)) {
                        inc.OwnerId = queueMap.get(queueDevName);
                        inc.AssignedGroupId = queueMap.get(queueDevName);
                    }
                }

                insert inc;
                
                Incident details = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];
                r.isSuccess = true;
                r.incidentId = inc.Id;
                r.incidentNumber = details.IncidentNumber;
                r.successMessage = 'Incident ' + details.IncidentNumber + ' has been created successfully.';
            } catch (Exception e) {
                r.isSuccess = false;
                r.errorMessage = e.getMessage();
            }
            results.add(r);
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
        String status
    ) {
        Request req = new Request();
        req.incidentForm = new ITSM_Copilot_NewIncidentFormWrapper();
        req.incidentForm.subject = subject;
        req.incidentForm.description = description;
        req.incidentForm.category = category;
        req.incidentForm.urgency = urgency;
        req.incidentForm.impact = impact;
        req.incidentForm.status = status;
        
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