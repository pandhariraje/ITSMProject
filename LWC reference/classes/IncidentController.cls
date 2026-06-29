public with sharing class IncidentController {

    @AuraEnabled
    public static Id createIncident(
        String subject,
        String description,
        String status,
        String priority,
        String urgency,
        String impact
    ){

        Incident inc = new Incident();

        inc.Subject = subject;
        inc.Description = description;
        inc.Status = status;
        inc.Priority = priority;
        inc.Urgency = urgency;
        inc.Impact = impact;

        insert inc;

        return inc.Id;
    }

}