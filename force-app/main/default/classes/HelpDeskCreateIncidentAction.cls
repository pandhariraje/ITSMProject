public without sharing class HelpDeskCreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Incident Form Data' description='The incident form data.' required=true)
        public HelpDeskIncidentFormWrapper incidentData;
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

        @InvocableVariable(label='Subject' description='Subject of the created incident')
        @AuraEnabled
        public String subject;

        @InvocableVariable(label='Status' description='Status of the created incident')
        @AuraEnabled
        public String status;

        @InvocableVariable(label='Priority' description='Priority of the created incident')
        @AuraEnabled
        public String priority;

        @InvocableVariable(label='Success Message' description='Success message to display')
        @AuraEnabled
        public String successMessage;
    }

    @InvocableMethod(
        label='HelpDesk Create Incident Action'
        description='Creates an Incident record in Salesforce and returns details.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            if (req.incidentData == null) {
                res.isSuccess = false;
                res.errorMessage = 'Incident data is missing.';
                results.add(res);
                continue;
            }
            res = createSingleIncident(req.incidentData);
            results.add(res);
        }
        return results;
    }

    private static Result createSingleIncident(HelpDeskIncidentFormWrapper wrapper) {
        Result res = new Result();
        try {
            Incident inc = new Incident();
            inc.Subject = wrapper.subject;
            inc.Description = wrapper.description;
            inc.Category = wrapper.category;
            inc.Type = 'Normal';
            inc.Urgency = wrapper.urgency;
            inc.Impact = wrapper.impact;
            inc.Status = String.isNotBlank(wrapper.status) ? wrapper.status : 'New';

            // Resolve active portal user dynamically (generic for all Digital Experience Site users)
            Id activePortalUserId = null;
            try {
                // Find the most active portal session in the last 15 minutes
                List<AuthSession> sessions = [
                    SELECT UsersId 
                    FROM AuthSession 
                    WHERE (SessionType = 'ChatterNetworks' OR Users.UserType IN ('PowerCustomerSuccess', 'CustomerSuccess', 'PowerPartner'))
                      AND LastModifiedDate >= :System.now().addMinutes(-15)
                    ORDER BY LastModifiedDate DESC 
                    LIMIT 1
                ];
                if (!sessions.isEmpty()) {
                    activePortalUserId = sessions[0].UsersId;
                }
            } catch (Exception e) {
                System.debug('Error resolving portal session: ' + e.getMessage());
            }

            // Fallback to active portal users login check if no active AuthSession is found
            if (activePortalUserId == null) {
                List<User> portalUsers = [
                    SELECT Id 
                    FROM User 
                    WHERE UserType IN ('PowerCustomerSuccess', 'CustomerSuccess', 'PowerPartner') 
                      AND IsActive = true 
                      AND LastLoginDate != null
                    ORDER BY LastLoginDate DESC 
                    LIMIT 1
                ];
                if (!portalUsers.isEmpty()) {
                    activePortalUserId = portalUsers[0].Id;
                }
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

            // Resolve Owner & Reporter
            Boolean isEmployeeCustomer = false;
            if (activePortalUserId != null) {
                List<User> pUsers = [
                    SELECT Id, UserType 
                    FROM User 
                    WHERE Id = :activePortalUserId AND IsActive = true 
                    LIMIT 1
                ];
                if (!pUsers.isEmpty()) {
                    User u = pUsers[0];
                    inc.ReportedById = u.Id;
                    isEmployeeCustomer = (u.UserType != 'Standard');
                }
            }
            if (inc.ReportedById == null) {
                inc.ReportedById = UserInfo.getUserId();
            }

            // Calculate Priority or use user-provided priority
            String finalPriority = 'Medium';
            if (String.isNotBlank(wrapper.priority)) {
                finalPriority = wrapper.priority;
            } else {
                if (wrapper.impact == 'High') {
                    if (wrapper.urgency == 'High') finalPriority = 'Critical';
                    else if (wrapper.urgency == 'Medium') finalPriority = 'High';
                } else if (wrapper.impact == 'Medium') {
                    if (wrapper.urgency == 'High') finalPriority = 'High';
                    else if (wrapper.urgency == 'Medium') finalPriority = 'Medium';
                    else finalPriority = 'Low';
                } else {
                    if (wrapper.urgency == 'High') finalPriority = 'Medium';
                    else finalPriority = 'Low';
                }
            }
            inc.Priority = finalPriority;

            // Route dynamic queue
            String queueDevName = '';
            String cat = String.isNotBlank(wrapper.category) ? wrapper.category : 'Software';
            if (cat == 'Hardware') {
                if (finalPriority == 'Critical') queueDevName = 'Hardware_Major_Incident_Queue';
                else if (finalPriority == 'High') queueDevName = 'Hardware_High_Incident_Queue';
                else queueDevName = 'Hardware_Normal_Incident_Queue';
            } else if (cat == 'Network') {
                if (finalPriority == 'Critical') queueDevName = 'Network_Major_Incident_Queue';
                else if (finalPriority == 'High') queueDevName = 'Network_High_Incident_Queue';
                else queueDevName = 'Network_Normal_Incident_Queue';
            } else {
                if (finalPriority == 'Critical') queueDevName = 'Software_Major_Incident_Queue';
                else if (finalPriority == 'High') queueDevName = 'Software_High_Incident_Queue';
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

            Incident insertedInc = [SELECT Id, IncidentNumber, Subject, Status, Priority FROM Incident WHERE Id = :inc.Id LIMIT 1];

            res.isSuccess = true;
            res.incidentId = insertedInc.Id;
            res.incidentNumber = insertedInc.IncidentNumber;
            res.subject = insertedInc.Subject;
            res.status = insertedInc.Status;
            res.priority = insertedInc.Priority;
            res.successMessage = 'Incident ' + insertedInc.IncidentNumber + ' has been created successfully.';
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    @AuraEnabled
    public static Result createIncidentLwc(
        String subject,
        String description,
        String category,
        String urgency,
        String impact,
        String status,
        String priority
    ) {
        HelpDeskIncidentFormWrapper wrapper = new HelpDeskIncidentFormWrapper();
        wrapper.subject = subject;
        wrapper.description = description;
        wrapper.category = category;
        wrapper.urgency = urgency;
        wrapper.impact = impact;
        wrapper.status = status;
        wrapper.priority = priority;
        return createSingleIncident(wrapper);
    }
}