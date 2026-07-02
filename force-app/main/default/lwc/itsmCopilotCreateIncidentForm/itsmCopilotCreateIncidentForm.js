import { LightningElement, api, track } from 'lwc';

export default class ItsmCopilotCreateIncidentForm extends LightningElement {
    subject = '';
    description = '';
    status = 'New';
    priority = 'Moderate';
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

    connectedCallback() {
        // Dispatch initial default values to ensure the agent receives them on load
        this.dispatchChange();
    }

    handleSubject(event) {
        this.subject = event.target.value;
        this.dispatchChange();
    }

    handleDescription(event) {
        this.description = event.target.value;
        this.dispatchChange();
    }

    handleStatus(event) {
        this.status = event.detail.value;
        this.dispatchChange();
    }

    handlePriority(event) {
        this.priority = event.detail.value;
        this.dispatchChange();
    }

    handleUrgency(event) {
        this.urgency = event.detail.value;
        this.dispatchChange();
    }

    handleImpact(event) {
        this.impact = event.detail.value;
        this.dispatchChange();
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
