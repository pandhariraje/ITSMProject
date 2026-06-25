import { LightningElement, api, track, wire } from 'lwc';
import createIncidentLwc from '@salesforce/apex/CopilotCreateIncidentAction.createIncidentLwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import INCIDENT_OBJECT from '@salesforce/schema/Incident';
import PRIORITY_FIELD from '@salesforce/schema/Incident.Priority';
import URGENCY_FIELD from '@salesforce/schema/Incident.Urgency';
import IMPACT_FIELD from '@salesforce/schema/Incident.Impact';

export default class CreateIncidentFormLwc extends LightningElement {
    // Inputs (pre-populated by flow/agent)
    @api subject = '';
    @api description = '';
    @api category = '';
    @api urgency = '';
    @api impact = '';
    @api requesterEmail = '';
    @api subCategory = '';
    @api type = '';
    @api status = 'New';
    @api priority = '';

    _value;

    @api
    get value() {
        return this._value;
    }

    set value(val) {
        this._value = val;
        if (val) {
            this.subject = val.subject || '';
            this.description = val.description || '';
            this.category = val.category || '';
            this.urgency = val.urgency || '';
            this.impact = val.impact || '';
            this.status = val.status || 'New';
            this.priority = val.priority || '';
        }
    }


    // Outputs (returned to flow/agent)
    @api incidentId = '';
    @api incidentNumber = '';
    @api isSuccess = false;
    @api errorMessage = '';

    @track isLoading = false;
    @track customError = '';
    @track priorityOptions = [];
    @track urgencyOptions = [];
    @track impactOptions = [];

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

    @wire(getObjectInfo, { objectApiName: INCIDENT_OBJECT })
    incidentInfo;

    @wire(getPicklistValues, { recordTypeId: '$incidentInfo.data.defaultRecordTypeId', fieldApiName: PRIORITY_FIELD })
    wiredPriorityValues({ error, data }) {
        if (data) {
            this.priorityOptions = data.values;
        } else if (error) {
            console.error('Error fetching priority picklist values', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$incidentInfo.data.defaultRecordTypeId', fieldApiName: URGENCY_FIELD })
    wiredUrgencyValues({ error, data }) {
        if (data) {
            this.urgencyOptions = data.values;
        } else if (error) {
            console.error('Error fetching urgency picklist values', error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$incidentInfo.data.defaultRecordTypeId', fieldApiName: IMPACT_FIELD })
    wiredImpactValues({ error, data }) {
        if (data) {
            this.impactOptions = data.values;
        } else if (error) {
            console.error('Error fetching impact picklist values', error);
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        this[fieldName] = event.target.value;
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
            requesterEmail: this.requesterEmail,
            subCategory: this.subCategory,
            type: this.type,
            status: this.status,
            priority: this.priority
        })
        .then((result) => {
            this.isLoading = false;
            if (result.isSuccess) {
                this.incidentId = result.incidentId;
                this.incidentNumber = result.incidentNumber;
                this.isSuccess = true;
                this.errorMessage = '';
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
