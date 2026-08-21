import { LightningElement, api, track } from 'lwc';
import createIncidentLwc from '@salesforce/apex/ITSMCopilotCreateIncidentAction.createIncidentLwc';

export default class ItsmCreateIncidentForm extends LightningElement {
    @api subject = '';
    @api description = '';
    @api category = 'Software';
    @api urgency = 'Medium';
    @api impact = 'Medium';
    @api status = 'New';
    @api priority = 'Moderate';

    @track localSubject = '';
    @track localDescription = '';
    @track localCategory = 'Software';
    @track localUrgency = 'Medium';
    @track localImpact = 'Medium';
    @track localStatus = 'New';
    @track localPriority = 'Moderate';

    @track isLoading = false;
    @track customError = '';

    @api incidentId = '';
    @api incidentNumber = '';
    @api isSuccess = false;
    @api errorMessage = '';

    urgencyOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];

    impactOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];

    priorityOptions = [
        { label: 'Critical', value: 'Critical' },
        { label: 'High', value: 'High' },
        { label: 'Moderate', value: 'Moderate' },
        { label: 'Low', value: 'Low' }
    ];

    statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Open', value: 'Open' },
        { label: 'In Process', value: 'In Process' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Problem Created', value: 'Problem Created' },
        { label: 'Closed', value: 'Closed' }
    ];

    connectedCallback() {
        this.localSubject = this.subject || '';
        this.localDescription = this.description || '';
        this.localCategory = this.category || 'Software';
        this.localUrgency = this.urgency || 'Medium';
        this.localImpact = this.impact || 'Medium';
        this.localStatus = this.status || 'New';
        this.localPriority = this.priority || 'Moderate';
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        if (fieldName === 'subject') this.localSubject = event.target.value;
        else if (fieldName === 'description') this.localDescription = event.target.value;
        else if (fieldName === 'urgency') this.localUrgency = event.target.value;
        else if (fieldName === 'impact') this.localImpact = event.target.value;
        else if (fieldName === 'priority') this.localPriority = event.target.value;
        else if (fieldName === 'status') this.localStatus = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', { detail: { action: 'cancel' } }));
    }

    handleSubmit() {
        const isInputsValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsValid) return;

        this.isLoading = true;
        this.customError = '';

        createIncidentLwc({
            subject: this.localSubject,
            description: this.localDescription,
            category: this.localCategory,
            urgency: this.localUrgency,
            impact: this.localImpact,
            requesterEmail: '',
            status: this.localStatus,
            priority: this.localPriority
        })
        .then((result) => {
            this.isLoading = false;
            if (result.isSuccess) {
                this.incidentId = result.incidentId;
                this.incidentNumber = result.incidentNumber;
                this.isSuccess = true;
                this.errorMessage = '';

                this.dispatchEvent(new CustomEvent('valuechange', {
                    detail: {
                        value: {
                            incidentId: result.incidentId,
                            incidentNumber: result.incidentNumber,
                            subject: result.subject,
                            status: result.status,
                            priority: result.priority,
                            isSuccess: true
                        }
                    }
                }));
            } else {
                this.isSuccess = false;
                this.errorMessage = result.errorMessage;
                this.customError = result.errorMessage;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            this.isSuccess = false;
            this.errorMessage = error.body ? error.body.message : error.message;
            this.customError = this.errorMessage;
        });
    }
}