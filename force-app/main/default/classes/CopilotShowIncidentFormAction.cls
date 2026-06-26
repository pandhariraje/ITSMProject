public with sharing class CopilotShowIncidentFormAction {

    public class Request {
        @InvocableVariable(label='Subject' description='Subject of the incident' required=false)
        public String subject;

        @InvocableVariable(label='Description' description='Description of the incident' required=false)
        public String description;

        @InvocableVariable(label='Category' description='Category of the incident' required=false)
        public String category;

        @InvocableVariable(label='Urgency' description='Urgency level: Low, Medium, High' required=false)
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level: Low, Medium, High' required=false)
        public String impact;

        @InvocableVariable(label='Status' description='Status of the incident' required=false)
        public String status;

        @InvocableVariable(label='Priority' description='Priority of the incident' required=false)
        public String priority;
    }

    public class Result {
        @InvocableVariable(label='Incident Form' description='The incident form data structure')
        @AuraEnabled
        public CopilotIncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Show Create Incident Form'
        description='Returns pre-populated input fields for the Create Incident form LWC popup.'
    )
    public static List<Result> showIncidentForm(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            CopilotIncidentFormWrapper wrapper = new CopilotIncidentFormWrapper();
            wrapper.subject = req.subject;
            wrapper.description = req.description;
            wrapper.category = req.category;
            wrapper.urgency = req.urgency;
            wrapper.impact = req.impact;
            wrapper.status = req.status;
            wrapper.priority = req.priority;
            res.incidentForm = wrapper;
            results.add(res);
        }
        return results;
    }
}
