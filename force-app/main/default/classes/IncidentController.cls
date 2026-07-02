public with sharing class IncidentController {

    // Returns picklist values for a field on Incident
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String fieldApiName) {

        List<String> values = new List<String>();

        Schema.SObjectType incidentType = Schema.getGlobalDescribe().get('Incident');

        if (incidentType == null) {
            throw new AuraHandledException('Incident object is not available.');
        }

        Map<String, Schema.SObjectField> fieldMap =
            incidentType.getDescribe().fields.getMap();

        if (!fieldMap.containsKey(fieldApiName)) {
            throw new AuraHandledException('Invalid field : ' + fieldApiName);
        }

        Schema.DescribeFieldResult describeField =
            fieldMap.get(fieldApiName).getDescribe();

        for (Schema.PicklistEntry pe : describeField.getPicklistValues()) {
            if (pe.isActive()) {
                values.add(pe.getValue());
            }
        }

        return values;
    }

    // Creates Incident
    @AuraEnabled
    public static Id createIncident(
        String subject,
        String description,
        String status,
        String priority,
        String urgency,
        String impact
    ) {

        try {

            Incident incident = new Incident();

            incident.Subject = subject;
            incident.Description = description;
            incident.Status = status;
            incident.Priority = priority;
            incident.Urgency = urgency;
            incident.Impact = impact;

            insert incident;

            return incident.Id;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}