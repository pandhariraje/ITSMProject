public with sharing class CopilotEscalateTicketAction {

    public class Request {
        @InvocableVariable(label='Ticket Number' description='The incident or service request ticket number to escalate (e.g. 00000001)' required=true)
        public String ticketNumber;

        @InvocableVariable(label='Escalation Reason' description='The reason for escalating the ticket' required=false)
        public String escalationReason;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the escalation completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if escalation failed')
        public String errorMessage;

        @InvocableVariable(label='Success Message' description='Confirmation message detailing the routing and notification')
        public String successMessage;
    }

    @InvocableMethod(
        label='Copilot Escalate Ticket'
        description='Escalates a ticket to Critical priority, routes it to the appropriate Queue, and creates a manager SLA task notification.'
    )
    public static List<Result> escalateTicket(List<Request> requests) {
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
                SELECT Id, IncidentNumber, Priority, Category, Status, OwnerId 
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
                SELECT Id, Name, Priority, Status, OwnerId 
                FROM ServiceRequest 
                WHERE Name IN :ticketNumbers
                WITH USER_MODE
            ];
            for (ServiceRequest sr : serviceRequests) {
                serviceRequestMap.put(sr.Name, sr);
            }
        }

        // Query support queues to route to
        Map<String, Id> queueMap = new Map<String, Id>();
        List<Group> queues = [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Type = 'Queue' 
            AND DeveloperName IN ('High_Priority_Incidents_Queue', 'Software_Major_Incident_Queue', 'Major_Incident_Queue', 'Hardware_Major_Incident_Queue', 'Network_Major_Incident_Queue')
            WITH USER_MODE
        ];
        for (Group q : queues) {
            queueMap.put(q.DeveloperName, q.Id);
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        List<Task> tasksToCreate = new List<Task>();

        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            String tNum = req.ticketNumber.trim();

            if (incidentMap.containsKey(tNum)) {
                Incident inc = incidentMap.get(tNum);
                inc.Priority = 'Critical';
                inc.Status = 'Escalated';

                // Route to Queue based on Category
                Id targetQueueId = null;
                String assignedQueueName = 'High Priority Incidents Queue';
                
                if (inc.Category == 'Software' && queueMap.containsKey('Software_Major_Incident_Queue')) {
                    targetQueueId = queueMap.get('Software_Major_Incident_Queue');
                    assignedQueueName = 'Software Major Incident Queue';
                } else if (inc.Category == 'Network' && queueMap.containsKey('Network_Major_Incident_Queue')) {
                    targetQueueId = queueMap.get('Network_Major_Incident_Queue');
                    assignedQueueName = 'Network Major Incident Queue';
                } else if (inc.Category == 'Hardware' && queueMap.containsKey('Hardware_Major_Incident_Queue')) {
                    targetQueueId = queueMap.get('Hardware_Major_Incident_Queue');
                    assignedQueueName = 'Hardware Major Incident Queue';
                } else if (queueMap.containsKey('High_Priority_Incidents_Queue')) {
                    targetQueueId = queueMap.get('High_Priority_Incidents_Queue');
                }

                if (targetQueueId != null) {
                    inc.OwnerId = targetQueueId;
                    inc.AssignedGroupId = targetQueueId;
                }

                recordsToUpdate.add(inc);

                // Create SLA alert task
                Task slaTask = new Task();
                slaTask.Subject = 'SLA Escalation Alert for Incident ' + inc.IncidentNumber;
                slaTask.Description = 'Critical manual escalation requested.\nReason: ' + 
                                      (String.isNotBlank(req.escalationReason) ? req.escalationReason : 'No reason specified') + 
                                      '\nEscalated to: ' + assignedQueueName;
                slaTask.Priority = 'High';
                slaTask.Status = 'Not Started';
                slaTask.WhatId = inc.Id;
                slaTask.OwnerId = (inc.OwnerId != null && String.valueOf(inc.OwnerId).startsWith('005')) ? inc.OwnerId : UserInfo.getUserId();
                tasksToCreate.add(slaTask);

                r.successMessage = 'Incident ' + inc.IncidentNumber + ' has been escalated to Critical and routed to ' + assignedQueueName + '. A manager SLA task has been logged.';
            } else if (serviceRequestMap.containsKey(tNum)) {
                ServiceRequest sr = serviceRequestMap.get(tNum);
                sr.Priority = 'Critical';
                sr.Status = 'Escalated';

                recordsToUpdate.add(sr);

                // Create SLA alert task
                Task slaTask = new Task();
                slaTask.Subject = 'SLA Escalation Alert for Service Request ' + sr.Name;
                slaTask.Description = 'Critical manual escalation requested.\nReason: ' + 
                                      (String.isNotBlank(req.escalationReason) ? req.escalationReason : 'No reason specified');
                slaTask.Priority = 'High';
                slaTask.Status = 'Not Started';
                slaTask.WhatId = sr.Id;
                slaTask.OwnerId = (sr.OwnerId != null && String.valueOf(sr.OwnerId).startsWith('005')) ? sr.OwnerId : UserInfo.getUserId();
                tasksToCreate.add(slaTask);

                r.successMessage = 'Service Request ' + sr.Name + ' has been escalated to Critical. A manager SLA task has been logged.';
            } else {
                r.isSuccess = false;
                r.errorMessage = 'Ticket number ' + req.ticketNumber + ' not found.';
            }
            results.add(r);
        }

        if (!recordsToUpdate.isEmpty()) {
            try {
                SObjectAccessDecision decisionUpdate = Security.stripInaccessible(AccessType.UPDATABLE, recordsToUpdate);
                update decisionUpdate.getRecords();

                if (!tasksToCreate.isEmpty()) {
                    SObjectAccessDecision decisionInsert = Security.stripInaccessible(AccessType.CREATABLE, tasksToCreate);
                    insert decisionInsert.getRecords();
                }
            } catch (Exception e) {
                for (Result res : results) {
                    if (res.isSuccess) {
                        res.isSuccess = false;
                        res.errorMessage = e.getMessage();
                        res.successMessage = null;
                    }
                }
            }
        }

        return results;
    }
}
