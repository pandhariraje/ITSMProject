public with sharing class CopilotEmployeeCloseIncident {

    public class Request {
        @InvocableVariable(label='Ticket Number' required=true)
        public String ticketNumber;

        @InvocableVariable(label='Resolution Notes' required=true)
        public String resolutionNotes;
    }

    public class Result {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Success Message')
        public String successMessage;
    }

    @InvocableMethod(
        label='Copilot Employee: Close Incident/Ticket'
        description='Closes an Incident or Service Request with resolution notes.'
    )
    public static List<Result> closeTicket(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            if (String.isBlank(req.ticketNumber)) {
                res.isSuccess = false;
                res.errorMessage = 'Ticket number is required.';
                results.add(res);
                continue;
            }

            try {
                String tNum = req.ticketNumber.trim();
                List<Incident> incidents = [
                    SELECT Id, Status, ResolutionSummary 
                    FROM Incident 
                    WHERE IncidentNumber = :tNum
                    WITH USER_MODE 
                    LIMIT 1
                ];

                if (!incidents.isEmpty()) {
                    Incident inc = incidents[0];
                    inc.Status = 'Closed';
                    inc.ResolutionSummary = req.resolutionNotes;
                    update as user inc;
                    res.isSuccess = true;
                    res.successMessage = 'Incident ' + tNum + ' closed successfully.';
                } else {
                    List<ServiceRequest> serviceRequests = [
                        SELECT Id, Status, Description
                        FROM ServiceRequest 
                        WHERE Name = :tNum
                        WITH USER_MODE 
                        LIMIT 1
                    ];

                    if (!serviceRequests.isEmpty()) {
                        ServiceRequest sr = serviceRequests[0];
                        sr.Status = 'Closed';
                        sr.Description = (String.isNotBlank(sr.Description) ? sr.Description : '') + '\nResolution: ' + req.resolutionNotes;
                        update as user sr;
                        res.isSuccess = true;
                        res.successMessage = 'Service Request ' + tNum + ' closed successfully.';
                    } else {
                        res.isSuccess = false;
                        res.errorMessage = 'Ticket ' + tNum + ' not found.';
                    }
                }
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = CopilotEmployeeExceptionHandler.handleException(e);
            }
            results.add(res);
        }

        return results;
    }
}
