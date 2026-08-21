import { LightningElement, api, track } from 'lwc';
import createIncidentLwc from '@salesforce/apex/ITSM_Copilot_CreateIncidentAction.createIncidentLwc';

export default class ItsmCopilotNewIncidentForm extends LightningElement {
    @track subject = '';
    @track description = '';
    @track category = 'Software';
    @track urgency = 'Medium';
    @track impact = 'Medium';
    @track status = 'New';
    @track isLoading = false;
    @track isSuccess = false;
    @track incidentId = '';
    @track incidentNumber = '';
    @track customError = '';

    @track categoryOptions = [
        { label: 'Software', value: 'Software' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Network', value: 'Network' }
    ];

    @track urgencyOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    @track impactOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    _value;

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
        if (val) {
            this.subject = val.subject || this.subject;
            this.description = val.description || this.description;
            this.category = val.category || this.category;
            this.urgency = val.urgency || this.urgency;
            this.impact = val.impact || this.impact;
            this.status = val.status || this.status;
        }
    }

    connectedCallback() {
        // Do not dispatch change on load to prevent premature execution
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleCategoryChange(event) {
        this.category = event.detail.value;
    }

    handleUrgencyChange(event) {
        this.urgency = event.detail.value;
    }

    handleImpactChange(event) {
        this.impact = event.detail.value;
    }

    dispatchChange() {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    incidentId: this.incidentId,
                    incidentNumber: this.incidentNumber,
                    subject: this.subject,
                    description: this.description,
                    category: this.category,
                    urgency: this.urgency,
                    impact: this.impact,
                    status: this.status
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
            subject: this.subject,
            description: this.description,
            category: this.category,
            urgency: this.urgency,
            impact: this.impact,
            status: this.status
        })
        .then((result) => {
            this.isLoading = false;
            if (result.isSuccess) {
                this.incidentId = result.incidentId;
                this.incidentNumber = result.incidentNumber;
                this.isSuccess = true;
                this.customError = '';
                
                // Dispatch final completion event to Agentforce
                this.dispatchChange();
            } else {
                this.isSuccess = false;
                this.customError = result.errorMessage;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            this.isSuccess = false;
            this.customError = error.body ? error.body.message : error.message;
        });
    }

    get incidentRecordUrl() {
        return `/lightning/r/Incident/${this.incidentId}/view`;
    }
}