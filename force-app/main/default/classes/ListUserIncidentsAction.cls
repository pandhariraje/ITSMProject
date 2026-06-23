public with sharing class ListUserIncidentsAction {

    public class Request {
        @InvocableVariable(label='Status Filter' description='Optional status filter (e.g. Open, Closed, New, In Progress)' required=false)
        public String statusFilter;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the operation completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if query failed')
        public String errorMessage;

        @InvocableVariable(label='Incidents' description='List of matching incident records')
        public List<IncidentDetails> incidents;
    }

    public class IncidentDetails {
        @InvocableVariable(label='Incident Number')
        public String incidentNumber;

        @InvocableVariable(label='Subject')
        public String subject;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Created Date')
        public Datetime createdDate;

        @InvocableVariable(label='Incident ID')
        public Id incidentId;
    }

    @InvocableMethod(
        label='List User Incidents'
        description='Retrieves Incidents related to the current user, optionally filtered by status.'
    )
    public static List<Result> listUserIncidents(List<Request> requests) {
        List<Result> results = new List<Result>();
        Id currentUserId = UserInfo.getUserId();

        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            r.incidents = new List<IncidentDetails>();

            try {
                String statusFilter = req.statusFilter;
                List<Incident> queryResults;

                if (String.isNotBlank(statusFilter)) {
                    String cleanFilter = statusFilter.trim();
                    if (cleanFilter.equalsIgnoreCase('Open')) {
                        queryResults = [
                            SELECT Id, IncidentNumber, Subject, Status, Priority, CreatedDate 
                            FROM Incident 
                            WHERE (ReportedById = :currentUserId OR CreatedById = :currentUserId)
                              AND Status NOT IN ('Closed', 'Resolved')
                            WITH USER_MODE
                            ORDER BY CreatedDate DESC
                        ];
                    } else if (cleanFilter.equalsIgnoreCase('Closed')) {
                        queryResults = [
                            SELECT Id, IncidentNumber, Subject, Status, Priority, CreatedDate 
                            FROM Incident 
                            WHERE (ReportedById = :currentUserId OR CreatedById = :currentUserId)
                              AND Status IN ('Closed', 'Resolved')
                            WITH USER_MODE
                            ORDER BY CreatedDate DESC
                        ];
                    } else {
                        queryResults = [
                            SELECT Id, IncidentNumber, Subject, Status, Priority, CreatedDate 
                            FROM Incident 
                            WHERE (ReportedById = :currentUserId OR CreatedById = :currentUserId)
                              AND Status = :cleanFilter
                            WITH USER_MODE
                            ORDER BY CreatedDate DESC
                        ];
                    }
                } else {
                    queryResults = [
                        SELECT Id, IncidentNumber, Subject, Status, Priority, CreatedDate 
                        FROM Incident 
                        WHERE (ReportedById = :currentUserId OR CreatedById = :currentUserId)
                        WITH USER_MODE
                        ORDER BY CreatedDate DESC
                    ];
                }

                for (Incident inc : queryResults) {
                    IncidentDetails det = new IncidentDetails();
                    det.incidentId = inc.Id;
                    det.incidentNumber = inc.IncidentNumber;
                    det.subject = inc.Subject;
                    det.status = inc.Status;
                    det.priority = inc.Priority;
                    det.createdDate = inc.CreatedDate;
                    r.incidents.add(det);
                }
            } catch (Exception e) {
                r.isSuccess = false;
                r.errorMessage = e.getMessage();
            }
            results.add(r);
        }
        return results;
    }
}
