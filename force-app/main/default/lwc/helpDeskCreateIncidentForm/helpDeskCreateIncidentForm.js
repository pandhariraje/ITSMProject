import { LightningElement, api, track } from 'lwc';

export default class HelpDeskCreateIncidentForm extends LightningElement {
    subject = '';
    description = '';
    status = 'New';
    priority = 'Medium';
    urgency = 'Medium';
    impact = 'Medium';

    @track statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Open', value: 'Open' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Closed', value: 'Closed' }
    ];
    @track priorityOptions = [
        { label: 'Critical', value: 'Critical' },
        { label: 'High', value: 'High' },
        { label: 'Moderate', value: 'Moderate' },
        { label: 'Low', value: 'Low' }
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

    @track isLoading = false;
    @track isSubmitted = false;
    @track customError = '';
    @track incidentNumber = '';

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
            this.status = val.status || this.status;
            this.priority = val.priority || this.priority;
            this.urgency = val.urgency || this.urgency;
            this.impact = val.impact || this.impact;
        }
    }

    handleSubject(event) {
        this.subject = event.target.value;
    }

    handleDescription(event) {
        this.description = event.target.value;
    }

    handleStatus(event) {
        this.status = event.detail.value;
    }

    handlePriority(event) {
        this.priority = event.detail.value;
    }

    handleUrgency(event) {
        this.urgency = event.detail.value;
    }

    handleImpact(event) {
        this.impact = event.detail.value;
    }

    handleSubmit() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')
        ].reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if (allValid) {
            this.dispatchChange();
        }
    }

    dispatchChange() {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    subject: this.subject,
                    description: this.description,
                    status: this.status,
                    priority: this.priority,
                    urgency: this.urgency,
                    impact: this.impact
                }
            }
        }));
    }
}