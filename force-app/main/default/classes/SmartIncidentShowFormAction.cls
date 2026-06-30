public with sharing class SmartIncidentShowFormAction {

    public class Request {
        @InvocableVariable(label='Incident Form' description='The incident form data structure' required=false)
        public SmartIncidentFormWrapper incidentForm;
    }

    public class Result {
        @InvocableVariable(label='Incident Form' description='The incident form data structure')
        @AuraEnabled
        public SmartIncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Smart Incident Show Form Action'
        description='Launches the custom LWC screen form for Smart Incident Agent.'
    )
    public static List<Result> showForm(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            if (req.incidentForm == null) {
                req.incidentForm = new SmartIncidentFormWrapper();
            }
            if (String.isBlank(req.incidentForm.status)) {
                req.incidentForm.status = 'New';
            }
            if (String.isBlank(req.incidentForm.urgency)) {
                req.incidentForm.urgency = 'Medium';
            }
            if (String.isBlank(req.incidentForm.impact)) {
                req.incidentForm.impact = 'Medium';
            }
            if (String.isBlank(req.incidentForm.priority)) {
                req.incidentForm.priority = 'Moderate';
            }
            res.incidentForm = req.incidentForm;
            results.add(res);
        }
        return results;
    }
}
