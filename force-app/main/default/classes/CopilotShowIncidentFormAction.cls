public with sharing class CopilotShowIncidentFormAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=false)
        @AuraEnabled
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=false)
        @AuraEnabled
        public String description;

        @InvocableVariable(label='Category' description='Category of the incident (Network, Hardware, Software)' required=false)
        @AuraEnabled
        public String category;

        @InvocableVariable(label='Urgency' description='Urgency level (Low, Medium, High)' required=false)
        @AuraEnabled
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (Low, Medium, High)' required=false)
        @AuraEnabled
        public String impact;

        @InvocableVariable(label='Status' description='The status of the incident' required=false)
        @AuraEnabled
        public String status;

        @InvocableVariable(label='Priority' description='Priority level' required=false)
        @AuraEnabled
        public String priority;
    }

    public class IncidentFormWrapper {
        @InvocableVariable(label='Subject' description='The subject of the incident')
        @AuraEnabled
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident')
        @AuraEnabled
        public String description;

        @InvocableVariable(label='Category' description='Category of the incident (Network, Hardware, Software)')
        @AuraEnabled
        public String category;

        @InvocableVariable(label='Urgency' description='Urgency level (Low, Medium, High)')
        @AuraEnabled
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (Low, Medium, High)')
        @AuraEnabled
        public String impact;

        @InvocableVariable(label='Status' description='The status of the incident')
        @AuraEnabled
        public String status;

        @InvocableVariable(label='Priority' description='Priority level')
        @AuraEnabled
        public String priority;
    }

    public class Result {
        @InvocableVariable(label='Incident Form' description='The incident form data structure')
        @AuraEnabled
        public IncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Show Create Incident Form'
        description='Returns pre-populated input fields for the Create Incident form LWC popup.'
    )
    public static List<Result> showIncidentForm(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            IncidentFormWrapper wrapper = new IncidentFormWrapper();
            wrapper.subject = req.subject;
            wrapper.description = req.description;
            wrapper.category = req.category;
            wrapper.urgency = req.urgency;
            wrapper.impact = req.impact;
            wrapper.status = String.isNotBlank(req.status) ? req.status : 'New';
            wrapper.priority = req.priority;
            res.incidentForm = wrapper;
            results.add(res);
        }
        return results;
    }
}
