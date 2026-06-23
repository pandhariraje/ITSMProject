public with sharing class CheckTicketStatusAction {

    public class Request {
        @InvocableVariable(label='Ticket Number' description='The incident or service request ticket number (e.g. 00000001 or SR-0001)' required=true)
        public String ticketNumber;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the operation completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if query failed')
        public String errorMessage;

        @InvocableVariable(label='Found' description='Whether the ticket was found in the system')
        public Boolean found;

        @InvocableVariable(label='Ticket Type' description='Incident or Service Request')
        public String ticketType;

        @InvocableVariable(label='Ticket Number' description='The retrieved ticket number')
        public String ticketNumber;

        @InvocableVariable(label='Status' description='Current ticket status')
        public String status;

        @InvocableVariable(label='Priority' description='Current ticket priority')
        public String priority;

        @InvocableVariable(label='Assigned Team' description='Name of the assigned team/group')
        public String assignedTeam;

        @InvocableVariable(label='Last Updated Date' description='The date and time the ticket was last updated')
        public Datetime lastUpdatedDate;

        @InvocableVariable(label='Ticket ID' description='The ID of the ticket record')
        public Id ticketId;
    }

    @InvocableMethod(
        label='Check ITSM Ticket Status'
        description='Retrieves the status, priority, assigned team, and last updated date for a given Incident or Service Request ticket.'
    )
    public static List<Result> checkTicketStatus(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        Set<String> ticketNumbers = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.ticketNumber)) {
                ticketNumbers.add(req.ticketNumber.trim());
            }
        }

        // Search Incidents
        Map<String, Incident> incidentMap = new Map<String, Incident>();
        if (!ticketNumbers.isEmpty()) {
            List<Incident> incidents = [
                SELECT Id, IncidentNumber, Status, Priority, LastModifiedDate, AssignedGroupId 
                FROM Incident 
                WHERE IncidentNumber IN :ticketNumbers
                WITH USER_MODE
            ];
            for (Incident inc : incidents) {
                incidentMap.put(inc.IncidentNumber, inc);
            }
        }

        // Search Service Requests
        Map<String, ServiceRequest> serviceRequestMap = new Map<String, ServiceRequest>();
        if (!ticketNumbers.isEmpty()) {
            List<ServiceRequest> serviceRequests = [
                SELECT Id, Name, Status, Priority, LastModifiedDate, AssignedGroupId 
                FROM ServiceRequest 
                WHERE Name IN :ticketNumbers
                WITH USER_MODE
            ];
            for (ServiceRequest sr : serviceRequests) {
                serviceRequestMap.put(sr.Name, sr);
            }
        }

        // Resolve Queue/Group Names
        Set<Id> groupIds = new Set<Id>();
        for (Incident inc : incidentMap.values()) {
            if (inc.AssignedGroupId != null) {
                groupIds.add(inc.AssignedGroupId);
            }
        }
        for (ServiceRequest sr : serviceRequestMap.values()) {
            if (sr.AssignedGroupId != null) {
                groupIds.add(sr.AssignedGroupId);
            }
        }

        Map<Id, String> groupNames = new Map<Id, String>();
        if (!groupIds.isEmpty()) {
            for (Group g : [SELECT Id, Name FROM Group WHERE Id IN :groupIds WITH USER_MODE]) {
                groupNames.put(g.Id, g.Name);
            }
        }

        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            r.found = false;
            String tNum = req.ticketNumber.trim();

            if (incidentMap.containsKey(tNum)) {
                Incident inc = incidentMap.get(tNum);
                r.found = true;
                r.ticketType = 'Incident';
                r.ticketId = inc.Id;
                r.ticketNumber = inc.IncidentNumber;
                r.status = inc.Status;
                r.priority = inc.Priority;
                r.lastUpdatedDate = inc.LastModifiedDate;
                if (inc.AssignedGroupId != null && groupNames.containsKey(inc.AssignedGroupId)) {
                    r.assignedTeam = groupNames.get(inc.AssignedGroupId);
                } else {
                    r.assignedTeam = 'Unassigned';
                }
            } else if (serviceRequestMap.containsKey(tNum)) {
                ServiceRequest sr = serviceRequestMap.get(tNum);
                r.found = true;
                r.ticketType = 'Service Request';
                r.ticketId = sr.Id;
                r.ticketNumber = sr.Name;
                r.status = sr.Status;
                r.priority = sr.Priority;
                r.lastUpdatedDate = sr.LastModifiedDate;
                if (sr.AssignedGroupId != null && groupNames.containsKey(sr.AssignedGroupId)) {
                    r.assignedTeam = groupNames.get(sr.AssignedGroupId);
                } else {
                    r.assignedTeam = 'Unassigned';
                }
            } else {
                r.errorMessage = 'Ticket number not found in either Incidents or Service Requests.';
            }
            results.add(r);
        }

        return results;
    }
}
