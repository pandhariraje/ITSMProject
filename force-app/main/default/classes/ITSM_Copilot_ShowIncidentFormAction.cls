public without sharing class ITSM_Copilot_ShowIncidentFormAction {

    public class Request {
        @InvocableVariable(label='Incident Form Data' description='The incident form data structure' required=true)
        public ITSM_Copilot_NewIncidentFormWrapper incidentForm;
    }

    public class Result {
        @InvocableVariable(label='Incident Form Data' description='The incident form data structure')
        @AuraEnabled
        public ITSM_Copilot_NewIncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='ITSM Copilot Show Create Incident Form'
        description='Returns pre-populated input fields for the ITSM Copilot Create Incident form LWC popup.'
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