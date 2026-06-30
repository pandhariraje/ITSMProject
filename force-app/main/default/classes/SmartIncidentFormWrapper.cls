global class SmartIncidentFormWrapper {
    @AuraEnabled
    @InvocableVariable(label='Subject' description='Subject of the incident')
    global String subject;

    @AuraEnabled
    @InvocableVariable(label='Description' description='Detailed description of the incident')
    global String description;

    @AuraEnabled
    @InvocableVariable(label='Urgency' description='Urgency (High, Medium, Low)')
    global String urgency;

    @AuraEnabled
    @InvocableVariable(label='Impact' description='Impact (High, Medium, Low)')
    global String impact;

    @AuraEnabled
    @InvocableVariable(label='Priority' description='Priority (Critical, High, Moderate, Low)')
    global String priority;

    @AuraEnabled
    @InvocableVariable(label='Status' description='Status of the incident')
    global String status;

    @AuraEnabled
    @InvocableVariable(label='Category' description='Category of the incident')
    global String category;

    @AuraEnabled
    @InvocableVariable(label='Incident ID' description='Record Id of created incident')
    global String incidentId;

    @AuraEnabled
    @InvocableVariable(label='Incident Number' description='Auto-number reference of created incident')
    global String incidentNumber;

    @AuraEnabled
    @InvocableVariable(label='Is Success' description='Success status flag')
    global Boolean isSuccess;

    @AuraEnabled
    @InvocableVariable(label='Error Message' description='User-friendly error message')
    global String errorMessage;

    @AuraEnabled
    @InvocableVariable(label='Is Cancelled' description='Cancelled status flag')
    global Boolean isCancelled;

    global SmartIncidentFormWrapper() {
        this.isSuccess = false;
        this.isCancelled = false;
    }
}
