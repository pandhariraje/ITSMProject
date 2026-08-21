public with sharing class CopilotEmployeeUpdateIncident {

    public class Request {
        @InvocableVariable(label='Ticket Number' required=true)
        public String ticketNumber;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Status')
        public String status;
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
        label='Copilot Employee: Update Incident/Ticket'
        description='Updates fields on an Incident or Service Request record.'
    )
    public static List<Result> updateTicket(List<Request> requests) {
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
                    SELECT Id, Status, Priority 
                    FROM Incident 
                    WHERE IncidentNumber = :tNum
                    WITH USER_MODE 
                    LIMIT 1
                ];

                if (!incidents.isEmpty()) {
                    Incident inc = incidents[0];
                    if (String.isNotBlank(req.status)) inc.Status = req.status;
                    if (String.isNotBlank(req.priority)) inc.Priority = req.priority;
                    update as user inc;
                    res.isSuccess = true;
                    res.successMessage = 'Incident ' + tNum + ' updated successfully.';
                } else {
                    List<ServiceRequest> serviceRequests = [
                        SELECT Id, Status, Priority 
                        FROM ServiceRequest 
                        WHERE Name = :tNum
                        WITH USER_MODE 
                        LIMIT 1
                    ];

                    if (!serviceRequests.isEmpty()) {
                        ServiceRequest sr = serviceRequests[0];
                        if (String.isNotBlank(req.status)) sr.Status = req.status;
                        if (String.isNotBlank(req.priority)) sr.Priority = req.priority;
                        update as user sr;
                        res.isSuccess = true;
                        res.successMessage = 'Service Request ' + tNum + ' updated successfully.';
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