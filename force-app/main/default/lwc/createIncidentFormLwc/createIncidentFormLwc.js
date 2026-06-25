import { LightningElement, api, track } from 'lwc';
import createIncidentLwc from '@salesforce/apex/CopilotCreateIncidentAction.createIncidentLwc';

export default class CreateIncidentFormLwc extends LightningElement {
    // Inputs (pre-populated by flow/agent)
    @api subject = '';
    @api description = '';
    @api category = 'Software';
    @api urgency = 'Medium';
    @api impact = 'Medium';
    @api requesterEmail = '';
    @api subCategory = '';
    @api type = 'Normal';
    @api status = 'New';
    @api priority = 'Medium';

    // Local tracked variables to avoid @api read-only mutation errors
    @track localSubject = '';
    @track localDescription = '';
    @track localCategory = 'Software';
    @track localUrgency = 'Medium';
    @track localImpact = 'Medium';
    @track localStatus = 'New';
    @track localPriority = 'Medium';
    @track localRequesterEmail = '';
    @track localSubCategory = '';
    @track localType = 'Normal';

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
            this.localCategory = val.category || 'Software';
            this.localUrgency = val.urgency || 'Medium';
            this.localImpact = val.impact || 'Medium';
            this.localStatus = val.status || 'New';
            this.localPriority = val.priority || 'Medium';
            this.localRequesterEmail = val.requesterEmail || '';
            this.localSubCategory = val.subCategory || '';
            this.localType = val.type || 'Normal';
        }
    }

    connectedCallback() {
        // Initialize local tracked values from API inputs if value is not set
        if (!this.value) {
            this.localSubject = this.subject || '';
            this.localDescription = this.description || '';
            this.localCategory = this.category || 'Software';
            this.localUrgency = this.urgency || 'Medium';
            this.localImpact = this.impact || 'Medium';
            this.localStatus = this.status || 'New';
            this.localPriority = this.priority || 'Medium';
            this.localRequesterEmail = this.requesterEmail || '';
            this.localSubCategory = this.subCategory || '';
            this.localType = this.type || 'Normal';
        }
    }

    // Outputs (returned to flow/agent)
    @api incidentId = '';
    @api incidentNumber = '';
    @api isSuccess = false;
    @api errorMessage = '';

    @track isLoading = false;
    @track customError = '';

    categoryOptions = [
        { label: 'Network', value: 'Network' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Software', value: 'Software' }
    ];

    statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Closed', value: 'Closed' }
    ];

    priorityOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' },
        { label: 'Critical', value: 'Critical' }
    ];

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

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        if (fieldName === 'subject') {
            this.localSubject = event.target.value;
        } else if (fieldName === 'description') {
            this.localDescription = event.target.value;
        } else if (fieldName === 'category') {
            this.localCategory = event.target.value;
        } else if (fieldName === 'status') {
            this.localStatus = event.target.value;
        } else if (fieldName === 'urgency') {
            this.localUrgency = event.target.value;
        } else if (fieldName === 'impact') {
            this.localImpact = event.target.value;
        } else if (fieldName === 'priority') {
            this.localPriority = event.target.value;
        } else if (fieldName === 'requesterEmail') {
            this.localRequesterEmail = event.target.value;
        } else if (fieldName === 'subCategory') {
            this.localSubCategory = event.target.value;
        } else if (fieldName === 'type') {
            this.localType = event.target.value;
        }
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
            requesterEmail: this.localRequesterEmail,
            subCategory: this.localSubCategory,
            type: this.localType,
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

                // Dispatch Custom Event valuechange to notify the Atlas Reasoner of input completion
                this.dispatchEvent(new CustomEvent('valuechange', {
                    detail: {
                        value: {
                            subject: this.localSubject,
                            description: this.localDescription,
                            category: this.localCategory,
                            urgency: this.localUrgency,
                            impact: this.localImpact,
                            status: this.localStatus,
                            priority: this.localPriority,
                            requesterEmail: this.localRequesterEmail,
                            subCategory: this.localSubCategory,
                            type: this.localType
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

    get incidentRecordUrl() {
        return `/lightning/r/Incident/${this.incidentId}/view`;
    }
}
