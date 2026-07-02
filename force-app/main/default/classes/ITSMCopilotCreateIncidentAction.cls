public with sharing class ITSMCopilotCreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Incident Form Data' description='The incident form data.' required=true)
        public ITSMCopilotIncidentFormWrapper incidentData;
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
    }

    @InvocableMethod(
        label='ITSMCopilot Create Incident Action'
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

    private static Result createSingleIncident(ITSMCopilotIncidentFormWrapper wrapper) {
        Result res = new Result();
        try {
            Incident inc = new Incident();
            inc.Subject = wrapper.subject;
            inc.Description = wrapper.description;
            inc.Status = wrapper.status;
            inc.Priority = wrapper.priority;
            inc.Urgency = wrapper.urgency;
            inc.Impact = wrapper.impact;

            insert inc;

            Incident insertedInc = [SELECT Id, IncidentNumber, Subject, Status, Priority FROM Incident WHERE Id = :inc.Id WITH USER_MODE LIMIT 1];

            res.isSuccess = true;
            res.incidentId = insertedInc.Id;
            res.incidentNumber = insertedInc.IncidentNumber;
            res.subject = insertedInc.Subject;
            res.status = insertedInc.Status;
            res.priority = insertedInc.Priority;
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }
}
