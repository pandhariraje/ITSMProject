public with sharing class CopilotCreateServiceRequestAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the service request' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the service request' required=true)
        public String description;

        @InvocableVariable(label='Priority' description='Priority level (Low, Medium, High, Critical)' required=true)
        public String priority;

        @InvocableVariable(label='Requester Email' description='Email of the employee requesting the service request' required=false)
        public String requesterEmail;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the service request was created successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        public String errorMessage;

        @InvocableVariable(label='Service Request ID' description='The ID of the created service request record')
        public Id serviceRequestId;

        @InvocableVariable(label='Service Request Number' description='The auto-number reference of the created service request')
        public String serviceRequestNumber;
    }

    @InvocableMethod(
        label='Copilot Create Service Request'
        description='Creates a ServiceRequest record with user-provided details.'
    )
    public static List<Result> createServiceRequest(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<ServiceRequest> serviceRequestsToInsert = new List<ServiceRequest>();

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
            ServiceRequest sr = new ServiceRequest();
            sr.Subject = req.subject;
            sr.Description = req.description;
            sr.Priority = req.priority;
            sr.Status = 'New';

            // Resolve ReportedById
            Id reporterId = UserInfo.getUserId();
            if (String.isNotBlank(req.requesterEmail) && emailToReporterId.containsKey(req.requesterEmail.toLowerCase())) {
                reporterId = emailToReporterId.get(req.requesterEmail.toLowerCase());
            }
            sr.ReportedById = reporterId;

            serviceRequestsToInsert.add(sr);
        }

        if (!serviceRequestsToInsert.isEmpty()) {
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, serviceRequestsToInsert);
                List<SObject> recordsToInsert = decision.getRecords();
                if (recordsToInsert.isEmpty()) {
                    for (Request req : requests) {
                        Result r = new Result();
                        r.isSuccess = false;
                        r.errorMessage = 'Permission denied to create Service Request.';
                        results.add(r);
                    }
                    return results;
                }
                insert recordsToInsert;

                List<ServiceRequest> insertedSRs = [
                    SELECT Id, Name 
                    FROM ServiceRequest 
                    WHERE Id IN :recordsToInsert
                ];
                Map<Id, String> srIdToNum = new Map<Id, String>();
                for (ServiceRequest s : insertedSRs) {
                    srIdToNum.put(s.Id, s.Name);
                }

                for (Integer i = 0; i < requests.size(); i++) {
                    ServiceRequest created = (ServiceRequest) recordsToInsert[i];
                    Result r = new Result();
                    r.isSuccess = true;
                    r.serviceRequestId = created.Id;
                    r.serviceRequestNumber = srIdToNum.get(created.Id);
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
