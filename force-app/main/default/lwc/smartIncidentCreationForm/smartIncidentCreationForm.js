import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SmartIncidentCreationForm extends LightningElement {

    subject = '';
    description = '';
    status = 'New';
    priority = 'Moderate';
    urgency = 'Medium';
    impact = 'Medium';
    category = '';

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
            this.category = val.category || this.category;
        }
    }

    @track statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Open', value: 'Open' },
        { label: 'In Process', value: 'In Process' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Problem Created', value: 'Problem Created' },
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

    @track categoryOptions = [
        { label: 'Network', value: 'Network' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Software', value: 'Software' }
    ];

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

    handleCategory(event) {
        this.category = event.detail.value;
    }

    createIncident() {
        if (!this.subject || !this.description) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill in required fields (Subject and Description).',
                    variant: 'error'
                })
            );
            return;
        }

        // Dispatch valuechange event to Agentforce so the invocable Apex action can perform the DML
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    subject: this.subject,
                    description: this.description,
                    status: this.status,
                    priority: this.priority,
                    urgency: this.urgency,
                    impact: this.impact,
                    category: this.category,
                    isSuccess: true,
                    isCancelled: false
                }
            }
        }));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    isSuccess: false,
                    isCancelled: true
                }
            }
        }));
    }
}
