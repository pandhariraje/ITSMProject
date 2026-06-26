global class IncidentManagementFormWrapper {
    @AuraEnabled
    @InvocableVariable(label='Subject' description='Subject of the incident')
    global String subject;

    @AuraEnabled
    @InvocableVariable(label='Description' description='Description of the incident')
    global String description;

    @AuraEnabled
    @InvocableVariable(label='Category' description='Category of the incident')
    global String category;

    @AuraEnabled
    @InvocableVariable(label='Urgency' description='Urgency of the incident')
    global String urgency;

    @AuraEnabled
    @InvocableVariable(label='Impact' description='Impact of the incident')
    global String impact;

    @AuraEnabled
    @InvocableVariable(label='Priority' description='Priority of the incident')
    global String priority;

    @AuraEnabled
    @InvocableVariable(label='Status' description='Status of the incident')
    global String status;

    @AuraEnabled
    @InvocableVariable(label='Incident ID' description='Incident record ID')
    global String incidentId;

    @AuraEnabled
    @InvocableVariable(label='Incident Number' description='Incident auto-number reference')
    global String incidentNumber;

    global IncidentManagementFormWrapper() {}
}
