public with sharing class ITSMCopilotUpdateIncidentAction {

    public class Request {
        @InvocableVariable(label='Incident ID' description='The ID of the incident to update' required=false)
        @AuraEnabled public String incidentId;

        @InvocableVariable(label='Incident Number' description='The Incident Number (e.g. INC-000001)' required=false)
        @AuraEnabled public String incidentNumber;

        @InvocableVariable(label='Subject' description='Updated subject' required=false)
        @AuraEnabled public String subject;

        @InvocableVariable(label='Description' description='Updated description' required=false)
        @AuraEnabled public String description;

        @InvocableVariable(label='Urgency' description='Updated urgency level' required=false)
        @AuraEnabled public String urgency;

        @InvocableVariable(label='Impact' description='Updated impact level' required=false)
        @AuraEnabled public String impact;

        @InvocableVariable(label='Priority' description='Updated priority' required=false)
        @AuraEnabled public String priority;

        @InvocableVariable(label='Status' description='Updated status' required=false)
        @AuraEnabled public String status;

        @InvocableVariable(label='Comment Text' description='Comment or update notes to add' required=false)
        @AuraEnabled public String commentText;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the update succeeded')
        @AuraEnabled public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if update failed')
        @AuraEnabled public String errorMessage;

        @InvocableVariable(label='Incident ID' description='The ID of the updated incident')
        @AuraEnabled public Id incidentId;

        @InvocableVariable(label='Incident Number' description='The reference number of the updated incident')
        @AuraEnabled public String incidentNumber;

        @InvocableVariable(label='Subject' description='Current subject')
        @AuraEnabled public String subject;

        @InvocableVariable(label='Status' description='Current status')
        @AuraEnabled public String status;

        @InvocableVariable(label='Priority' description='Current priority')
        @AuraEnabled public String priority;
    }

    @InvocableMethod(
        label='ITSM Copilot Update Incident'
        description='Updates an existing Incident record and optionally appends comments.'
    )
    public static List<Result> updateIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(executeUpdate(req));
        }
        return results;
    }

    @AuraEnabled
    public static Result updateIncidentLwc(
        String incidentId,
        String incidentNumber,
        String subject,
        String description,
        String urgency,
        String impact,
        String priority,
        String status,
        String commentText
    ) {
        Request req = new Request();
        req.incidentId = incidentId;
        req.incidentNumber = incidentNumber;
        req.subject = subject;
        req.description = description;
        req.urgency = urgency;
        req.impact = impact;
        req.priority = priority;
        req.status = status;
        req.commentText = commentText;
        return executeUpdate(req);
    }

    @AuraEnabled(cacheable=true)
    public static Result getIncidentDetailsLwc(String recordIdentifier) {
        Result res = new Result();
        try {
            List<Incident> incs = new List<Incident>();
            if (String.isNotBlank(recordIdentifier)) {
                if (recordIdentifier.startsWith('015') || recordIdentifier.length() == 18 || recordIdentifier.length() == 15) {
                    incs = [SELECT Id, IncidentNumber, Subject, Description, Urgency, Impact, Priority, Status FROM Incident WHERE Id = :recordIdentifier WITH USER_MODE LIMIT 1];
                }
                if (incs.isEmpty()) {
                    incs = [SELECT Id, IncidentNumber, Subject, Description, Urgency, Impact, Priority, Status FROM Incident WHERE IncidentNumber = :recordIdentifier WITH USER_MODE LIMIT 1];
                }
            }
            if (!incs.isEmpty()) {
                Incident inc = incs[0];
                res.isSuccess = true;
                res.incidentId = inc.Id;
                res.incidentNumber = inc.IncidentNumber;
                res.subject = inc.Subject;
                res.status = inc.Status;
                res.priority = inc.Priority;
            } else {
                res.isSuccess = false;
                res.errorMessage = 'Incident not found.';
            }
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    private static Result executeUpdate(Request req) {
        Result res = new Result();
        try {
            List<Incident> incs = new List<Incident>();
            if (String.isNotBlank(req.incidentId)) {
                incs = [SELECT Id, IncidentNumber, Subject, Description, Urgency, Impact, Priority, Status FROM Incident WHERE Id = :req.incidentId WITH USER_MODE LIMIT 1];
            } else if (String.isNotBlank(req.incidentNumber)) {
                incs = [SELECT Id, IncidentNumber, Subject, Description, Urgency, Impact, Priority, Status FROM Incident WHERE IncidentNumber = :req.incidentNumber WITH USER_MODE LIMIT 1];
            }

            if (incs.isEmpty()) {
                res.isSuccess = false;
                res.errorMessage = 'Target incident could not be identified.';
                return res;
            }

            Incident inc = incs[0];
            if (String.isNotBlank(req.subject)) inc.Subject = req.subject;
            if (String.isNotBlank(req.description)) inc.Description = req.description;
            if (String.isNotBlank(req.urgency)) inc.Urgency = req.urgency;
            if (String.isNotBlank(req.impact)) inc.Impact = req.impact;
            if (String.isNotBlank(req.priority)) inc.Priority = req.priority;
            if (String.isNotBlank(req.status)) inc.Status = req.status;

            update as user inc;

            Incident queried = [SELECT Id, IncidentNumber, Subject, Status, Priority FROM Incident WHERE Id = :inc.Id WITH USER_MODE LIMIT 1];
            res.isSuccess = true;
            res.incidentId = queried.Id;
            res.incidentNumber = queried.IncidentNumber;
            res.subject = queried.Subject;
            res.status = queried.Status;
            res.priority = queried.Priority;
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = e.getMessage();
        }
        return res;
    }
}