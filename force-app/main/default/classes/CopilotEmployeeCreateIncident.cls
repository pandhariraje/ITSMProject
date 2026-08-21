public with sharing class CopilotEmployeeCreateIncident {

    public class Request {
        @InvocableVariable(label='Incident Data' description='Incident input form details' required=true)
        public CopilotEmployeeWrapper.IncidentFormInput incidentData;
    }

    public class Result {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Incident ID')
        public Id incidentId;

        @InvocableVariable(label='Incident Number')
        public String incidentNumber;
    }

    @InvocableMethod(label='Copilot Employee: Create Incident' description='Inserts a new Incident ticket with the supplied details.')
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            if (req.incidentData == null) {
                res.isSuccess = false;
                res.errorMessage = 'No incident data provided.';
                results.add(res);
                continue;
            }

            try {
                Incident inc = new Incident();
                inc.Subject = req.incidentData.subject;
                inc.Description = req.incidentData.description;
                inc.Category = req.incidentData.category;
                inc.Urgency = req.incidentData.urgency;
                inc.Impact = req.incidentData.impact;
                inc.Status = String.isNotBlank(req.incidentData.status) ? req.incidentData.status : 'New';
                
                if (String.isNotBlank(req.incidentData.priority)) {
                    inc.Priority = req.incidentData.priority;
                }

                insert as user inc;

                Incident freshInc = [SELECT Id, IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];
                res.isSuccess = true;
                res.incidentId = freshInc.Id;
                res.incidentNumber = freshInc.IncidentNumber;
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = CopilotEmployeeExceptionHandler.handleException(e);
            }
            results.add(res);
        }

        return results;
    }
}