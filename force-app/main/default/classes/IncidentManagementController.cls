public with sharing class IncidentManagementController {

    public class IncidentResult {
        @AuraEnabled public String incidentId;
        @AuraEnabled public String incidentNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
    }

    @AuraEnabled
    public static IncidentResult createIncident(
        String subject,
        String description,
        String urgency,
        String impact,
        String priority,
        String status
    ) {
        try {
            Incident inc = new Incident();
            inc.Subject = subject;
            inc.Description = description;
            inc.Urgency = urgency;
            inc.Impact = impact;
            inc.Priority = priority;
            inc.Status = status;

            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Incident>{ inc });
            List<SObject> recordsToInsert = decision.getRecords();
            if (recordsToInsert.isEmpty()) {
                throw new AuraHandledException('Permission denied to create Incident.');
            }
            
            insert recordsToInsert;

            Incident inserted = [
                SELECT Id, IncidentNumber, Status, Priority 
                FROM Incident 
                WHERE Id = :recordsToInsert[0].Id
                WITH USER_MODE
            ];

            IncidentResult res = new IncidentResult();
            res.incidentId = inserted.Id;
            res.incidentNumber = inserted.IncidentNumber;
            res.status = inserted.Status;
            res.priority = inserted.Priority;

            return res;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to create Incident. ' + e.getMessage());
        }
    }
}
