public with sharing class CopilotEmployeeCreateServiceRequest {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the service request' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the service request' required=true)
        public String description;

        @InvocableVariable(label='Priority' description='Priority level (Low, Medium, High, Critical)' required=true)
        public String priority;
    }

    public class Result {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Service Request ID')
        public Id serviceRequestId;

        @InvocableVariable(label='Service Request Number')
        public String serviceRequestNumber;
    }

    @InvocableMethod(
        label='Copilot Employee: Create Service Request'
        description='Creates a ServiceRequest record in Salesforce.'
    )
    public static List<Result> createServiceRequest(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            try {
                ServiceRequest sr = new ServiceRequest();
                sr.Subject = req.subject;
                sr.Description = req.description;
                sr.Priority = req.priority;
                sr.Status = 'New';

                insert as user sr;

                ServiceRequest freshSR = [SELECT Id, Name FROM ServiceRequest WHERE Id = :sr.Id LIMIT 1];
                res.isSuccess = true;
                res.serviceRequestId = freshSR.Id;
                res.serviceRequestNumber = freshSR.Name;
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = CopilotEmployeeExceptionHandler.handleException(e);
            }
            results.add(res);
        }

        return results;
    }
}
