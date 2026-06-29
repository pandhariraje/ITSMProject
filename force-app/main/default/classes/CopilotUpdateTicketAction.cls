public with sharing class CopilotUpdateTicketAction {

    public class Request {
        @InvocableVariable(label='Ticket Number' description='The incident or service request ticket number (e.g. 00000001 or SR-0001)' required=true)
        public String ticketNumber;

        @InvocableVariable(label='Priority' description='New priority to set for the ticket (e.g. Low, Medium, High, Critical)' required=false)
        public String priority;

        @InvocableVariable(label='Status' description='New status to set for the ticket (e.g. New, Open, In Progress, On Hold, Resolved, Closed, Escalated)' required=false)
        public String status;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the update completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if update failed')
        public String errorMessage;

        @InvocableVariable(label='Success Message' description='Confirmation message detailing the updated fields')
        public String successMessage;

        @InvocableVariable(label='Ticket Type' description='Incident or Service Request')
        public String ticketType;

        @InvocableVariable(label='Ticket Number' description='The retrieved ticket number')
        public String ticketNumber;

        @InvocableVariable(label='Status' description='Current ticket status after update')
        public String status;

        @InvocableVariable(label='Priority' description='Current ticket priority after update')
        public String priority;

        @InvocableVariable(label='Ticket ID' description='The record ID of the ticket')
        public Id ticketId;
    }

    @InvocableMethod(
        label='Copilot Update Ticket'
        description='Updates the status and/or priority of an existing Incident or Service Request by ticket number.'
    )
    public static List<Result> updateTicket(List<Request> requests) {
        List<Result> results = new List<Result>();

        Set<String> ticketNumbers = new Set<String>();
        for (Request req : requests) {
            if (req != null && String.isNotBlank(req.ticketNumber)) {
                ticketNumbers.add(req.ticketNumber.trim());
            }
        }

        // Search Incidents
        Map<String, Incident> incidentMap = new Map<String, Incident>();
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
        }

        // Search Service Requests
        Map<String, ServiceRequest> serviceRequestMap = new Map<String, ServiceRequest>();
        if (!ticketNumbers.isEmpty()) {
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

        List<SObject> recordsToUpdate = new List<SObject>();
        List<Integer> resultIndexesToUpdate = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Result r = new Result();
            r.isSuccess = true;

            if (req == null || String.isBlank(req.ticketNumber)) {
                r.isSuccess = false;
                r.errorMessage = 'Ticket number cannot be blank.';
                results.add(r);
                continue;
            }

            String tNum = req.ticketNumber.trim();
            Boolean fieldChanged = false;
            List<String> updatesMade = new List<String>();

            if (incidentMap.containsKey(tNum)) {
                Incident inc = incidentMap.get(tNum);
                r.ticketType = 'Incident';
                r.ticketId = inc.Id;
                r.ticketNumber = inc.IncidentNumber;

                if (String.isNotBlank(req.priority) && !req.priority.equalsIgnoreCase(inc.Priority)) {
                    inc.Priority = req.priority;
                    fieldChanged = true;
                    updatesMade.add('Priority to ' + req.priority);
                }
                if (String.isNotBlank(req.status) && !req.status.equalsIgnoreCase(inc.Status)) {
                    inc.Status = req.status;
                    fieldChanged = true;
                    updatesMade.add('Status to ' + req.status);
                }

                r.status = inc.Status;
                r.priority = inc.Priority;

                if (fieldChanged) {
                    recordsToUpdate.add(inc);
                    resultIndexesToUpdate.add(i);
                    r.successMessage = 'Incident ' + inc.IncidentNumber + ' updated successfully (' + String.join(updatesMade, ', ') + ').';
                } else {
                    r.successMessage = 'No changes were needed for Incident ' + inc.IncidentNumber + '.';
                }

            } else if (serviceRequestMap.containsKey(tNum)) {
                ServiceRequest sr = serviceRequestMap.get(tNum);
                r.ticketType = 'Service Request';
                r.ticketId = sr.Id;
                r.ticketNumber = sr.Name;

                if (String.isNotBlank(req.priority) && !req.priority.equalsIgnoreCase(sr.Priority)) {
                    sr.Priority = req.priority;
                    fieldChanged = true;
                    updatesMade.add('Priority to ' + req.priority);
                }
                if (String.isNotBlank(req.status) && !req.status.equalsIgnoreCase(sr.Status)) {
                    sr.Status = req.status;
                    fieldChanged = true;
                    updatesMade.add('Status to ' + req.status);
                }

                r.status = sr.Status;
                r.priority = sr.Priority;

                if (fieldChanged) {
                    recordsToUpdate.add(sr);
                    resultIndexesToUpdate.add(i);
                    r.successMessage = 'Service Request ' + sr.Name + ' updated successfully (' + String.join(updatesMade, ', ') + ').';
                } else {
                    r.successMessage = 'No changes were needed for Service Request ' + sr.Name + '.';
                }

            } else {
                r.isSuccess = false;
                r.errorMessage = 'Ticket number ' + tNum + ' not found in Incidents or Service Requests.';
            }

            results.add(r);
        }

        if (!recordsToUpdate.isEmpty()) {
            try {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, recordsToUpdate);
                update decision.getRecords();
            } catch (Exception e) {
                for (Integer idx : resultIndexesToUpdate) {
                    Result res = results[idx];
                    res.isSuccess = false;
                    res.errorMessage = e.getMessage();
                    res.successMessage = null;
                }
            }
        }

        return results;
    }
}
