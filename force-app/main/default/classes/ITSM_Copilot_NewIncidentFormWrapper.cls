global class ITSM_Copilot_NewIncidentFormWrapper {
    @AuraEnabled
    @InvocableVariable(label='Incident ID' description='ID of the incident')
    global String incidentId;

    @AuraEnabled
    @InvocableVariable(label='Incident Number' description='Number of the incident')
    global String incidentNumber;

    @AuraEnabled
    @InvocableVariable(label='Subject' description='Subject of the incident')
    global String subject;

    @AuraEnabled
    @InvocableVariable(label='Description' description='Description of the incident')
    global String description;

    @AuraEnabled
    @InvocableVariable(label='Category' description='Category of the incident (Hardware, Software, Network)')
    global String category;

    @AuraEnabled
    @InvocableVariable(label='Urgency' description='Urgency of the incident (High, Medium, Low)')
    global String urgency;

    @AuraEnabled
    @InvocableVariable(label='Impact' description='Impact of the incident (High, Medium, Low)')
    global String impact;

    @AuraEnabled
    @InvocableVariable(label='Priority' description='Priority of the incident')
    global String priority;

    @AuraEnabled
    @InvocableVariable(label='Status' description='Status of the incident')
    global String status = 'New';

    global ITSM_Copilot_NewIncidentFormWrapper() {}
}