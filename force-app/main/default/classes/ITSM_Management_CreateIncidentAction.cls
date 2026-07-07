public with sharing class ITSM_Management_CreateIncidentAction {

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

        @InvocableVariable(label='Status' description='The status of the incident' required=false)
        public String status;

        @InvocableVariable(label='Portal Contact ID' description='Contact ID of the portal user' required=false)
        public String contactId;
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

        @InvocableVariable(label='Priority' description='Automatically determined priority')
        public String priority;

        @InvocableVariable(label='Success Message' description='Confirmation success message')
        public String successMessage;
    }

    @InvocableMethod(
        label='ITSM Management Create Incident'
        description='Creates an Incident record with automated priority assignment and queue routing from conversation variables.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Incident> incidentsToInsert = new List<Incident>();

        // Query current user's profile and role to decide on ownership
        Id currentUserId = UserInfo.getUserId();
        List<User> users = [
            SELECT Id, Profile.Name, UserRole.Name 
            FROM User 
            WHERE Id = :currentUserId 
            LIMIT 1
        ];

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

        // Query the most recently logged-in portal user (Employee Customer profile)
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

        // Fallback to AuthSession if no recent login dates found
        if (activePortalUserId == null) {
            try {
                List<AuthSession> portalSessions = [
                    SELECT UsersId 
                    FROM AuthSession 
                    WHERE SessionType = 'ChatterNetworks' 
                    ORDER BY LastModifiedDate DESC 
                    LIMIT 1
                ];
                if (!portalSessions.isEmpty()) {
                    activePortalUserId = portalSessions[0].UsersId;
                }
            } catch (Exception e) {
                System.debug('Error querying AuthSession: ' + e.getMessage());
            }
        }

        for (Request req : requests) {
            Incident inc = new Incident();
            inc.Subject = req.subject;
            inc.Description = req.description;
            inc.Category = req.category;
            inc.Type = 'Normal';
            inc.Urgency = req.urgency;
            inc.Impact = req.impact;
            inc.Status = String.isNotBlank(req.status) ? req.status : 'New';

            // Resolve portal user from active session, then ContactId, then running user
            Id reporterUserId = null;
            Boolean isEmployeeCustomer = false;
            
            if (activePortalUserId != null) {
                List<User> portalUsersList = [
                    SELECT Id, Profile.Name, UserRole.DeveloperName 
                    FROM User 
                    WHERE Id = :activePortalUserId AND IsActive = true 
                    LIMIT 1
                ];
                if (!portalUsersList.isEmpty()) {
                    User u = portalUsersList[0];
                    reporterUserId = u.Id;
                    isEmployeeCustomer = (u.Profile != null && u.Profile.Name == 'Employee Customer profile') || 
                                         (u.UserRole != null && u.UserRole.DeveloperName == 'PAdmiCustomerPersonAccount');
                }
            }
            
            if (reporterUserId == null && String.isNotBlank(req.contactId)) {
                List<User> portalUsers = [
                    SELECT Id, Profile.Name, UserRole.DeveloperName 
                    FROM User 
                    WHERE ContactId = :req.contactId AND IsActive = true 
                    LIMIT 1
                ];
                if (!portalUsers.isEmpty()) {
                    User u = portalUsers[0];
                    reporterUserId = u.Id;
                    isEmployeeCustomer = (u.Profile != null && u.Profile.Name == 'Employee Customer profile') || 
                                         (u.UserRole != null && u.UserRole.DeveloperName == 'PAdmiCustomerPersonAccount');
                }
            }
            
            if (reporterUserId == null) {
                reporterUserId = currentUserId;
                if (!users.isEmpty()) {
                    User u = users[0];
                    isEmployeeCustomer = (u.Profile != null && u.Profile.Name == 'Employee Customer profile') || 
                                         (u.UserRole != null && (u.UserRole.Name == 'PAdmi Customer Person Account' || u.UserRole.DeveloperName == 'PAdmiCustomerPersonAccount')) ||
                                         (UserInfo.getUserType() != 'Standard');
                }
            }

            inc.ReportedById = reporterUserId;

            // Determine Priority automatically from Impact and Urgency
            String calculatedPriority = 'Medium';
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
            inc.Priority = calculatedPriority;

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

            if (isEmployeeCustomer) {
                inc.OwnerId = reporterUserId;
                if (queueMap.containsKey(queueDevName)) {
                    inc.AssignedGroupId = queueMap.get(queueDevName);
                }
            } else {
                if (queueMap.containsKey(queueDevName)) {
                    inc.OwnerId = queueMap.get(queueDevName);
                    inc.AssignedGroupId = queueMap.get(queueDevName);
                }
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
                    r.successMessage = 'Incident ' + details.IncidentNumber + ' has been created successfully.';
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
