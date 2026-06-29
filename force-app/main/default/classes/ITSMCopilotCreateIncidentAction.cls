public with sharing class ITSMCopilotCreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=true)
        @AuraEnabled
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=true)
        @AuraEnabled
        public String description;

        @InvocableVariable(label='Status' description='Status of the incident' required=false)
        @AuraEnabled
        public String status;

        @InvocableVariable(label='Priority' description='Priority level (Critical, High, Moderate, Low)' required=false)
        @AuraEnabled
        public String priority;

        @InvocableVariable(label='Urgency' description='Urgency level (High, Medium, Low)' required=false)
        @AuraEnabled
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (High, Medium, Low)' required=false)
        @AuraEnabled
        public String impact;
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
            Result res = createSingleIncident(req);
            results.add(res);
        }
        return results;
    }

    @AuraEnabled
    public static Result createIncident(
        String subject,
        String description,
        String status,
        String priority,
        String urgency,
        String impact
    ) {
        Request req = new Request();
        req.subject = subject;
        req.description = description;
        req.status = status;
        req.priority = priority;
        req.urgency = urgency;
        req.impact = impact;
        return createSingleIncident(req);
    }

    private static Result createSingleIncident(Request req) {
        Result res = new Result();
        try {
            Incident inc = new Incident();
            inc.Subject = req.subject;
            inc.Description = req.description;
            inc.Status = req.status;
            inc.Priority = req.priority;
            inc.Urgency = req.urgency;
            inc.Impact = req.impact;

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
