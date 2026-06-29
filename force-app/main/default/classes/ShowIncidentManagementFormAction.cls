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
            if (req.incidentForm != null) {
                String searchVal = req.incidentForm.incidentNumber;
                if (String.isBlank(searchVal)) {
                    searchVal = req.incidentForm.incidentId;
                }
                if (String.isNotBlank(searchVal)) {
                    searchVal = searchVal.trim();
                    String altSearchVal = searchVal.contains('-') ? searchVal.replace('-', '') : (searchVal.startsWith('INC') && searchVal.length() > 3 ? 'INC-' + searchVal.substring(3) : searchVal);
                    
                    try {
                        List<Incident> incidents = [
                            SELECT Id, IncidentNumber, Subject, Description, Category, Status, Urgency, Impact, Priority 
                            FROM Incident 
                            WHERE IncidentNumber = :searchVal OR IncidentNumber = :altSearchVal OR Id = :searchVal
                            WITH USER_MODE
                            LIMIT 1
                        ];

                        if (!incidents.isEmpty()) {
                            Incident inc = incidents[0];
                            req.incidentForm.incidentId = inc.Id;
                            req.incidentForm.incidentNumber = inc.IncidentNumber;
                            if (String.isBlank(req.incidentForm.subject)) req.incidentForm.subject = inc.Subject;
                            if (String.isBlank(req.incidentForm.description)) req.incidentForm.description = inc.Description;
                            if (String.isBlank(req.incidentForm.category)) req.incidentForm.category = inc.Category;
                            if (String.isBlank(req.incidentForm.status)) req.incidentForm.status = inc.Status;
                            if (String.isBlank(req.incidentForm.urgency)) req.incidentForm.urgency = inc.Urgency;
                            if (String.isBlank(req.incidentForm.impact)) req.incidentForm.impact = inc.Impact;
                            if (String.isBlank(req.incidentForm.priority)) req.incidentForm.priority = inc.Priority;
                        }
                    } catch (Exception e) {
                        System.debug('Error fetching incident for form: ' + e.getMessage());
                    }
                }
            }
            res.incidentForm = req.incidentForm;
            results.add(res);
        }
        return results;
    }
}
