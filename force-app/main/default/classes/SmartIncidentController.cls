public with sharing class SmartIncidentController {

    @AuraEnabled
    public static SmartIncidentFormWrapper createIncident(
        String subject,
        String description,
        String status,
        String priority,
        String urgency,
        String impact,
        String category
    ) {
        SmartIncidentFormWrapper res = new SmartIncidentFormWrapper();
        try {
            Incident inc = new Incident();
            inc.Subject = subject;
            inc.Description = description;
            inc.Status = String.isNotBlank(status) ? status : 'New';
            inc.Priority = String.isNotBlank(priority) ? priority : 'Moderate';
            inc.Urgency = String.isNotBlank(urgency) ? urgency : 'Medium';
            inc.Impact = String.isNotBlank(impact) ? impact : 'Medium';
            inc.Category = category;

            insert inc;

            Incident insertedInc = [
                SELECT Id, IncidentNumber, Subject, Status, Priority, Category 
                FROM Incident 
                WHERE Id = :inc.Id 
                WITH USER_MODE 
                LIMIT 1
            ];

            res.isSuccess = true;
            res.incidentId = insertedInc.Id;
            res.incidentNumber = insertedInc.IncidentNumber;
            res.subject = insertedInc.Subject;
            res.status = insertedInc.Status;
            res.priority = insertedInc.Priority;
            res.category = insertedInc.Category;
        } catch (Exception e) {
            res.isSuccess = false;
            res.errorMessage = 'I couldn\'t create the Incident due to an error. Please review the information and try again.';
        }
        return res;
    }
}
