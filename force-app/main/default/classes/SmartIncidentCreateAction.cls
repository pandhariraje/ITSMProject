public with sharing class SmartIncidentCreateAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=true)
        public String description;

        @InvocableVariable(label='Status' description='Status of the incident')
        public String status;

        @InvocableVariable(label='Priority' description='Priority level (Critical, High, Moderate, Low)')
        public String priority;

        @InvocableVariable(label='Urgency' description='Urgency level (High, Medium, Low)')
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (High, Medium, Low)')
        public String impact;

        @InvocableVariable(label='Category' description='Category of the incident')
        public String category;
    }

    public class Result {
        @InvocableVariable(label='Incident Form' description='The completed incident details wrapper')
        @AuraEnabled
        public SmartIncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Smart Incident Create Action'
        description='Creates an Incident record in Salesforce for Smart Incident Agent.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            res.incidentForm = SmartIncidentController.createIncident(
                req.subject,
                req.description,
                req.status,
                req.priority,
                req.urgency,
                req.impact,
                req.category
            );
            results.add(res);
        }
        return results;
    }
}
