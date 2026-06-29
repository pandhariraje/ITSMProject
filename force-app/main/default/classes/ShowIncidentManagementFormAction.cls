public with sharing class ShowIncidentManagementFormAction {
    public class Request {
        @InvocableVariable(label='Ticket Number or ID' description='The incident ticket number (e.g. INC-00000002) or Record ID' required=false)
        public String ticketNumber;

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
                res.incidentForm = req.incidentForm;
            } else if (String.isNotBlank(req.ticketNumber)) {
                String searchVal = req.ticketNumber.trim();
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
                        IncidentManagementFormWrapper wrapper = new IncidentManagementFormWrapper();
                        wrapper.incidentId = inc.Id;
                        wrapper.incidentNumber = inc.IncidentNumber;
                        wrapper.subject = inc.Subject;
                        wrapper.description = inc.Description;
                        wrapper.category = inc.Category;
                        wrapper.status = inc.Status;
                        wrapper.urgency = inc.Urgency;
                        wrapper.impact = inc.Impact;
                        wrapper.priority = inc.Priority;
                        res.incidentForm = wrapper;
                    }
                } catch (Exception e) {
                    System.debug('Error fetching incident for form: ' + e.getMessage());
                }
            }
            results.add(res);
        }
        return results;
    }
}
