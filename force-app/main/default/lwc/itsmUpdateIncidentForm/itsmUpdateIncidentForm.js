import { LightningElement, api, track } from 'lwc';
import updateIncidentLwc from '@salesforce/apex/ITSMCopilotUpdateIncidentAction.updateIncidentLwc';
import getIncidentDetailsLwc from '@salesforce/apex/ITSMCopilotUpdateIncidentAction.getIncidentDetailsLwc';

export default class ItsmUpdateIncidentForm extends LightningElement {
    @api incidentId = '';
    @api incidentNumber = '';
    @api subject = '';
    @api description = '';
    @api urgency = 'Medium';
    @api impact = 'Medium';
    @api status = 'In Process';
    @api priority = 'Moderate';

    @track localIdentifier = '';
    @track localSubject = '';
    @track localDescription = '';
    @track localUrgency = 'Medium';
    @track localImpact = 'Medium';
    @track localStatus = 'In Process';
    @track localPriority = 'Moderate';

    @track isLoading = false;
    @track customError = '';

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
        this.localIdentifier = this.incidentNumber || this.incidentId || '';
        this.localSubject = this.subject || '';
        this.localDescription = this.description || '';
        this.localUrgency = this.urgency || 'Medium';
        this.localImpact = this.impact || 'Medium';
        this.localStatus = this.status || 'In Process';
        this.localPriority = this.priority || 'Moderate';

        if (this.localIdentifier) {
            this.fetchDetails();
        }
    }

    fetchDetails() {
        if (!this.localIdentifier) return;
        this.isLoading = true;
        getIncidentDetailsLwc({ recordIdentifier: this.localIdentifier })
            .then((result) => {
                this.isLoading = false;
                if (result.isSuccess) {
                    if (result.subject) this.localSubject = result.subject;
                    if (result.status) this.localStatus = result.status;
                    if (result.priority) this.localPriority = result.priority;
                    if (result.incidentId) this.incidentId = result.incidentId;
                    if (result.incidentNumber) this.incidentNumber = result.incidentNumber;
                }
            })
            .catch(() => {
                this.isLoading = false;
            });
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        if (fieldName === 'identifier') {
            this.localIdentifier = event.target.value;
        } else if (fieldName === 'subject') {
            this.localSubject = event.target.value;
        } else if (fieldName === 'description') {
            this.localDescription = event.target.value;
        } else if (fieldName === 'urgency') {
            this.localUrgency = event.target.value;
        } else if (fieldName === 'impact') {
            this.localImpact = event.target.value;
        } else if (fieldName === 'priority') {
            this.localPriority = event.target.value;
        } else if (fieldName === 'status') {
            this.localStatus = event.target.value;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel', { detail: { action: 'cancel' } }));
    }

    handleSubmit() {
        if (!this.localIdentifier) {
            this.customError = 'Incident Record ID or Number is required.';
            return;
        }

        this.isLoading = true;
        this.customError = '';

        updateIncidentLwc({
            incidentId: this.incidentId || (this.localIdentifier.startsWith('015') ? this.localIdentifier : ''),
            incidentNumber: this.incidentNumber || (!this.localIdentifier.startsWith('015') ? this.localIdentifier : ''),
            subject: this.localSubject,
            description: this.localDescription,
            urgency: this.localUrgency,
            impact: this.localImpact,
            priority: this.localPriority,
            status: this.localStatus,
            commentText: ''
        })
        .then((result) => {
            this.isLoading = false;
            if (result.isSuccess) {
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
                this.customError = result.errorMessage;
            }
        })
        .catch((error) => {
            this.isLoading = false;
            this.customError = error.body ? error.body.message : error.message;
        });
    }
}