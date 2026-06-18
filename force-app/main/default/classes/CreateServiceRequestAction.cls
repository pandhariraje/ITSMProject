public with sharing class CreateServiceRequestAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the service request' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the service request' required=true)
        public String description;

        @InvocableVariable(label='Status' description='The status of the service request' required=false)
        public String status;
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
        label='Create ITSM Service Request'
        description='Creates a ServiceRequest record with user-provided details.'
    )
    public static List<Result> createServiceRequest(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<ServiceRequest> serviceRequestsToInsert = new List<ServiceRequest>();

        for (Request req : requests) {
            ServiceRequest sr = new ServiceRequest();
            sr.Subject = req.subject;
            sr.Description = req.description;
            sr.Status = String.isNotBlank(req.status) ? req.status : 'New';
            serviceRequestsToInsert.add(sr);
        }

        if (!serviceRequestsToInsert.isEmpty()) {
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, serviceRequestsToInsert);
                insert decision.getRecords();

                List<ServiceRequest> insertedSRs = [
                    SELECT Id, Name 
                    FROM ServiceRequest 
                    WHERE Id IN :decision.getRecords()
                ];

                Map<Id, String> srIdToNum = new Map<Id, String>();
                for (ServiceRequest s : insertedSRs) {
                    srIdToNum.put(s.Id, s.Name);
                }

                for (Integer idx = 0; idx < requests.size(); idx++) {
                    ServiceRequest insertedSR = (ServiceRequest) decision.getRecords()[idx];
                    Result r = new Result();
                    r.isSuccess = true;
                    r.serviceRequestId = insertedSR.Id;
                    r.serviceRequestNumber = srIdToNum.get(insertedSR.Id);
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
