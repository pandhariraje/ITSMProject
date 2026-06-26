public with sharing class ShowIncidentManagementFormAction {
    public class Request {
        @InvocableVariable(label='Incident Form' description='The incident form data structure' required=false)
        public IncidentManagementFormWrapper incidentForm;
    }

    public class Result {
        @InvocableVariable(label='Incident Form' description='The incident form data structure')
        @AuraEnabled
        public IncidentManagementFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Show Incident Management Form'
        description='Returns pre-populated input fields for the Incident Management form LWC.'
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
