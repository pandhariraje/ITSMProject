public with sharing class CopilotEmployeeSearchIncident {

    public class Request {
        @InvocableVariable(label='Ticket Number' description='Incident or Service Request Number' required=true)
        public String ticketNumber;
    }

    public class Result {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Found')
        public Boolean found;

        @InvocableVariable(label='Ticket Type')
        public String ticketType;

        @InvocableVariable(label='Ticket Number')
        public String ticketNumber;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Priority')
        public String priority;

        @InvocableVariable(label='Ticket ID')
        public Id ticketId;
    }

    @InvocableMethod(
        label='Copilot Employee: Search Incident/Ticket Status'
        description='Queries Incident or Service Request record status and details.'
    )
    public static List<Result> checkTicketStatus(List<Request> requests) {
        List<Result> results = new List<Result>();

        Set<String> ticketNumbers = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.ticketNumber)) {
                ticketNumbers.add(req.ticketNumber.trim());
            }
        }

        Map<String, Incident> incidentMap = new Map<String, Incident>();
        Map<String, ServiceRequest> serviceRequestMap = new Map<String, ServiceRequest>();

        if (!ticketNumbers.isEmpty()) {
            List<Incident> incidents = [
                SELECT Id, IncidentNumber, Status, Priority 
                FROM Incident 
                WHERE IncidentNumber IN :ticketNumbers
                WITH USER_MODE
            ];
            for (Incident inc : incidents) {
                incidentMap.put(inc.IncidentNumber, inc);
            }

            List<ServiceRequest> serviceRequests = [
                SELECT Id, Name, Status, Priority 
                FROM ServiceRequest 
                WHERE Name IN :ticketNumbers
                WITH USER_MODE
            ];
            for (ServiceRequest sr : serviceRequests) {
                serviceRequestMap.put(sr.Name, sr);
            }
        }

        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            r.found = false;

            if (String.isBlank(req.ticketNumber)) {
                r.isSuccess = false;
                r.errorMessage = 'Ticket number cannot be blank.';
                results.add(r);
                continue;
            }

            String tNum = req.ticketNumber.trim();

            if (incidentMap.containsKey(tNum)) {
                Incident inc = incidentMap.get(tNum);
                r.found = true;
                r.ticketType = 'Incident';
                r.ticketId = inc.Id;
                r.ticketNumber = inc.IncidentNumber;
                r.status = inc.Status;
                r.priority = inc.Priority;
            } else if (serviceRequestMap.containsKey(tNum)) {
                ServiceRequest sr = serviceRequestMap.get(tNum);
                r.found = true;
                r.ticketType = 'Service Request';
                r.ticketId = sr.Id;
                r.ticketNumber = sr.Name;
                r.status = sr.Status;
                r.priority = sr.Priority;
            } else {
                r.isSuccess = true;
                r.found = false;
                r.errorMessage = 'Ticket number not found.';
            }
            results.add(r);
        }

        return results;
    }
}