import { LightningElement, api, track } from 'lwc';
import createIncidentLwc from '@salesforce/apex/ITSMCopilotCreateIncidentAction.createIncidentLwc';

export default class ItsmCopilotCreateIncidentForm extends LightningElement {
    @api subject = '';
    @api description = '';
    @api category = '';
    @api urgency = 'Medium';
    @api impact = 'Medium';
    @api priority = 'Medium';
    @api status = 'New';

    @track localSubject = '';
    @track localDescription = '';
    @track localCategory = '';
    @track localUrgency = 'Medium';
    @track localImpact = 'Medium';
    @track localPriority = 'Medium';
    @track localStatus = 'New';

    _value;

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
        if (val) {
            this.localSubject = val.subject || '';
            this.localDescription = val.description || '';
            this.localCategory = val.category || '';
            this.localUrgency = val.urgency || 'Medium';
            this.localImpact = val.impact || 'Medium';
            this.localPriority = val.priority || 'Medium';
            this.localStatus = val.status || 'New';
        }
    }

    connectedCallback() {
        if (!this.value) {
            this.localSubject = this.subject || '';
            this.localDescription = this.description || '';
            this.localCategory = this.category || '';
            this.localUrgency = this.urgency || 'Medium';
            this.localImpact = this.impact || 'Medium';
            this.localPriority = this.priority || 'Medium';
            this.localStatus = this.status || 'New';
        }
    }

    @api incidentId = '';
    @api incidentNumber = '';
    @api isSuccess = false;
    @api errorMessage = '';

    @track isLoading = false;
    @track isSubmitted = false;
    @track isCancelled = false;
    @track customError = '';

    categoryOptions = [
        { label: '--None--', value: '' },
        { label: 'Software', value: 'Software' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Network', value: 'Network' },
        { label: 'Access', value: 'Access' }
    ];

    urgencyOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    impactOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    priorityOptions = [
        { label: 'Critical', value: 'Critical' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
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

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        if (fieldName === 'subject') {
            this.localSubject = event.target.value;
        } else if (fieldName === 'description') {
            this.localDescription = event.target.value;
        } else if (fieldName === 'category') {
            this.localCategory = event.target.value;
        } else if (fieldName === 'urgency') {
            this.localUrgency = event.target.value;
            this.calculatePriority();
        } else if (fieldName === 'impact') {
            this.localImpact = event.target.value;
            this.calculatePriority();
        } else if (fieldName === 'priority') {
            this.localPriority = event.target.value;
        } else if (fieldName === 'status') {
            this.localStatus = event.target.value;
        }
    }

    calculatePriority() {
        if (this.localImpact === 'High' && this.localUrgency === 'High') {
            this.localPriority = 'Critical';
        } else if (this.localImpact === 'High' || this.localUrgency === 'High') {
            this.localPriority = 'High';
        } else if (this.localImpact === 'Low' && this.localUrgency === 'Low') {
            this.localPriority = 'Low';
        } else {
            this.localPriority = 'Medium';
        }
    }

    handleCancel() {
        this.isCancelled = true;
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    actionStatus: 'Cancelled',
                    message: 'Incident creation has been cancelled. No record was created.'
                }
            }
        }));
    }

    handleSubmit() {
        const isInputsValid = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!isInputsValid) {
            return;
        }

        this.isLoading = true;
        this.customError = '';

        createIncidentLwc({
            subject: this.localSubject,
            description: this.localDescription,
            category: this.localCategory,
            urgency: this.localUrgency,
            impact: this.localImpact,
            priority: this.localPriority,
            status: this.localStatus
        })
        .then((result) => {
            this.isLoading = false;
            if (result.isSuccess) {
                this.incidentId = result.incidentId;
                this.incidentNumber = result.incidentNumber;
                this.isSuccess = true;
                this.isSubmitted = true;
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
                this.customError = "I couldn't create the Incident due to an error. Please review the information and try again.";
            }
        })
        .catch(() => {
            this.isLoading = false;
            this.isSuccess = false;
            this.customError = "I couldn't create the Incident due to an error. Please review the information and try again.";
        });
    }

    handleNextAction(event) {
        const selectedAction = event.target.dataset.action;
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    nextAction: selectedAction
                }
            }
        }));
    }
}
