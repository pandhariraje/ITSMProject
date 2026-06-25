global class CopilotIncidentFormWrapper {
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
    @InvocableVariable(label='Status' description='Status of the incident')
    global String status = 'New';

    @AuraEnabled
    @InvocableVariable(label='Priority' description='Priority of the incident')
    global String priority;

    @AuraEnabled
    @InvocableVariable(label='Requester Email' description='Requester Email')
    global String requesterEmail;

    @AuraEnabled
    @InvocableVariable(label='SubCategory' description='SubCategory')
    global String subCategory;

    @AuraEnabled
    @InvocableVariable(label='Type' description='Type of incident')
    global String type;

    global CopilotIncidentFormWrapper() {}
}
