public with sharing class CopilotShowIncidentFormAction {

    public class Request {
        @InvocableVariable(label='Incident Form' description='The incident form data structure' required=false)
        public CopilotIncidentFormWrapper incidentForm;
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
            res.incidentForm = req.incidentForm;
            results.add(res);
        }
        return results;
    }
}
