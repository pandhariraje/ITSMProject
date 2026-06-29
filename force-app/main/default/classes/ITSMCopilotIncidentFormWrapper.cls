global class ITSMCopilotIncidentFormWrapper {
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
    @InvocableVariable(label='Urgency' description='Urgency of the incident (High, Medium, Low)')
    global String urgency;

    @AuraEnabled
    @InvocableVariable(label='Impact' description='Impact of the incident (High, Medium, Low)')
    global String impact;

    @AuraEnabled
    @InvocableVariable(label='Priority' description='Priority of the incident (Critical, High, Moderate, Low)')
    global String priority;

    @AuraEnabled
    @InvocableVariable(label='Status' description='Status of the incident (New, Open, In Process, Resolved, Completed, Problem Created, Closed)')
    global String status = 'New';

    global ITSMCopilotIncidentFormWrapper() {}
}
