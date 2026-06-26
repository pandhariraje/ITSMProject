public with sharing class GetIncidentDetailsAction {
    public class Request {
        @InvocableVariable(label='Incident Number or ID' description='The incident number (e.g. INC00000003) or Record ID' required=true)
        public String ticketNumber;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the operation completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Found' description='Whether the ticket was found in the system')
        public Boolean found;

        @InvocableVariable(label='Incident Form Details' description='Incident form details for pre-population')
        public IncidentManagementFormWrapper incidentForm;

        @InvocableVariable(label='Error Message' description='Error message if query failed')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Incident Details for Management'
        description='Retrieves all fields of an Incident by Incident Number or Record ID and wraps it in an IncidentManagementFormWrapper.'
    )
    public static List<Result> getIncidentDetails(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            r.found = false;
            
            if (String.isBlank(req.ticketNumber)) {
                r.isSuccess = false;
                r.errorMessage = 'Ticket number cannot be empty.';
                results.add(r);
                continue;
            }

            String searchVal = req.ticketNumber.trim();
            
            try {
                List<Incident> incidents = [
                    SELECT Id, IncidentNumber, Subject, Description, Category, Status, Urgency, Impact, Priority 
                    FROM Incident 
                    WHERE IncidentNumber = :searchVal OR Id = :searchVal
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (!incidents.isEmpty()) {
                    Incident inc = incidents[0];
                    r.found = true;
                    
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
                    
                    r.incidentForm = wrapper;
                } else {
                    r.errorMessage = 'Incident ticket not found: ' + searchVal;
                }
            } catch (Exception e) {
                r.isSuccess = false;
                r.errorMessage = 'Error retrieving incident details: ' + e.getMessage();
            }
            results.add(r);
        }
        return results;
    }
}
