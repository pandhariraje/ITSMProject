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
        String status,
        String category
    ) {
        try {
            Incident inc = new Incident();
            inc.Subject = subject;
            inc.Description = description;
            inc.Urgency = urgency;
            inc.Impact = impact;
            inc.Priority = priority;
            inc.Status = status;
            inc.Category = category;

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

    @AuraEnabled
    public static IncidentManagementFormWrapper getIncidentById(Id incidentId) {
        try {
            Incident inc = [
                SELECT Id, IncidentNumber, Subject, Description, Category, Status, Urgency, Impact, Priority 
                FROM Incident 
                WHERE Id = :incidentId
                WITH USER_MODE
            ];
            IncidentManagementFormWrapper wrapper = new IncidentManagementFormWrapper();
            wrapper.incidentId = inc.Id;
            wrapper.incidentNumber = inc.IncidentNumber;
            wrapper.subject = inc.Subject;
            wrapper.description = inc.Description;
            wrapper.category = inc.Category;
            wrapper.status = inc.Status;
            wrapper.urgency = inc.Urgency;
            wrapper.impact = inc.Impact;
            wrapper.priority = inc.Priority;
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to find Incident: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<IncidentManagementFormWrapper> searchIncidents(String searchTerm) {
        try {
            String queryTerm = '%' + searchTerm + '%';
            List<Incident> incidents = [
                SELECT Id, IncidentNumber, Subject, Description, Category, Status, Urgency, Impact, Priority 
                FROM Incident 
                WHERE IncidentNumber LIKE :queryTerm OR Subject LIKE :queryTerm
                WITH USER_MODE
                LIMIT 10
            ];
            List<IncidentManagementFormWrapper> results = new List<IncidentManagementFormWrapper>();
            for (Incident inc : incidents) {
                IncidentManagementFormWrapper wrapper = new IncidentManagementFormWrapper();
                wrapper.incidentId = inc.Id;
                wrapper.incidentNumber = inc.IncidentNumber;
                wrapper.subject = inc.Subject;
                wrapper.description = inc.Description;
                wrapper.category = inc.Category;
                wrapper.status = inc.Status;
                wrapper.urgency = inc.Urgency;
                wrapper.impact = inc.Impact;
                wrapper.priority = inc.Priority;
                results.add(wrapper);
            }
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching Incidents: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static IncidentResult updateIncident(
        Id incidentId,
        String subject,
        String description,
        String urgency,
        String impact,
        String priority,
        String status,
        String category
    ) {
        try {
            Incident inc = new Incident(Id = incidentId);
            inc.Subject = subject;
            inc.Description = description;
            inc.Urgency = urgency;
            inc.Impact = impact;
            inc.Priority = priority;
            inc.Status = status;
            inc.Category = category;

            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Incident>{ inc });
            List<SObject> recordsToUpdate = decision.getRecords();
            if (recordsToUpdate.isEmpty()) {
                throw new AuraHandledException('Permission denied to update Incident.');
            }
            
            update recordsToUpdate;

            Incident updated = [
                SELECT Id, IncidentNumber, Status, Priority 
                FROM Incident 
                WHERE Id = :incidentId
                WITH USER_MODE
            ];

            IncidentResult res = new IncidentResult();
            res.incidentId = updated.Id;
            res.incidentNumber = updated.IncidentNumber;
            res.status = updated.Status;
            res.priority = updated.Priority;

            return res;
        } catch (Exception e) {
            throw new AuraHandledException('Unable to update Incident. ' + e.getMessage());
        }
    }
}
