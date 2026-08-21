public with sharing class CopilotEmployeeEscalate {

    public class Request {
        @InvocableVariable(label='Ticket Number')
        public String ticketNumber;

        @InvocableVariable(label='Escalation Reason' required=true)
        public String escalationReason;
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
        label='Copilot Employee: Escalate Ticket'
        description='Escalates ticket to Critical and routes to IT Support Queue.'
    )
    public static List<Result> escalateTicket(List<Request> requests) {
        List<Result> results = new List<Result>();

        // Query IT Support Queue
        List<Group> queues = [
            SELECT Id, DeveloperName 
            FROM Group 
            WHERE Type = 'Queue' 
            AND DeveloperName = 'IT_Support_Queue'
            WITH USER_MODE
            LIMIT 1
        ];
        Id supportQueueId = !queues.isEmpty() ? queues[0].Id : null;

        // Query supported SObject types for this Queue
        Set<String> supportedSObjects = new Set<String>();
        if (supportQueueId != null) {
            List<QueueSObject> queueSObjects = [
                SELECT SobjectType 
                FROM QueueSObject 
                WHERE QueueId = :supportQueueId
                WITH USER_MODE
            ];
            for (QueueSObject qso : queueSObjects) {
                supportedSObjects.add(qso.SobjectType.toLowerCase());
            }
        }

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
                    inc.Priority = 'Critical';
                    inc.Status = 'Escalated';
                    if (supportQueueId != null && supportedSObjects.contains('incident')) {
                        inc.OwnerId = supportQueueId;
                    }
                    update as user inc;

                    // Log SLA Task
                    Task t = new Task();
                    t.Subject = 'SLA Escalation Alert for Incident ' + tNum;
                    t.Description = 'Reason: ' + req.escalationReason;
                    t.Priority = 'High';
                    t.Status = 'Not Started';
                    t.WhatId = inc.Id;
                    insert as user t;

                    res.isSuccess = true;
                    res.successMessage = 'Incident ' + tNum + ' has been escalated and routed to IT Support Queue.';
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
                        sr.Priority = 'Critical';
                        sr.Status = 'Escalated';
                        if (supportQueueId != null && supportedSObjects.contains('servicerequest')) {
                            sr.OwnerId = supportQueueId;
                        }
                        update as user sr;

                        // Log SLA Task
                        Task t = new Task();
                        t.Subject = 'SLA Escalation Alert for Service Request ' + tNum;
                        t.Description = 'Reason: ' + req.escalationReason;
                        t.Priority = 'High';
                        t.Status = 'Not Started';
                        t.WhatId = sr.Id;
                        insert as user t;

                        res.isSuccess = true;
                        res.successMessage = 'Service Request ' + tNum + ' has been escalated and routed to IT Support Queue.';
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