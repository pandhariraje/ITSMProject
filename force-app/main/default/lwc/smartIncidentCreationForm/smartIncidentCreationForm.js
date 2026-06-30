import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import INCIDENT_OBJECT from '@salesforce/schema/Incident';
import STATUS_FIELD from '@salesforce/schema/Incident.Status';
import PRIORITY_FIELD from '@salesforce/schema/Incident.Priority';
import URGENCY_FIELD from '@salesforce/schema/Incident.Urgency';
import IMPACT_FIELD from '@salesforce/schema/Incident.Impact';
import CATEGORY_FIELD from '@salesforce/schema/Incident.Category';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import createIncident from '@salesforce/apex/SmartIncidentController.createIncident';

export default class SmartIncidentCreationForm extends LightningElement {

    @api subject = '';
    @api description = '';
    @api status = 'New';
    @api priority = 'Moderate';
    @api urgency = 'Medium';
    @api impact = 'Medium';
    @api category = '';

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

    @track categoryOptions = [];

    @wire(getObjectInfo, { objectApiName: INCIDENT_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    statusPicklist({ data }) {
        if (data && data.values && data.values.length > 0) {
            this.statusOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: PRIORITY_FIELD
    })
    priorityPicklist({ data }) {
        if (data && data.values && data.values.length > 0) {
            this.priorityOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: URGENCY_FIELD
    })
    urgencyPicklist({ data }) {
        if (data && data.values && data.values.length > 0) {
            this.urgencyOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: IMPACT_FIELD
    })
    impactPicklist({ data }) {
        if (data && data.values && data.values.length > 0) {
            this.impactOptions = data.values;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: CATEGORY_FIELD
    })
    categoryPicklist({ data }) {
        if (data && data.values && data.values.length > 0) {
            this.categoryOptions = data.values;
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

        createIncident({
            subject: this.subject,
            description: this.description,
            status: this.status,
            priority: this.priority,
            urgency: this.urgency,
            impact: this.impact,
            category: this.category
        })
        .then(result => {
            if (result && result.isSuccess) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your Incident has been created successfully.',
                        variant: 'success'
                    })
                );
                // Dispatch custom event for Agentforce session wrapper
                this.dispatchEvent(new CustomEvent('valuechange', {
                    detail: {
                        value: {
                            incidentId: result.incidentId,
                            incidentNumber: result.incidentNumber,
                            subject: result.subject,
                            status: result.status,
                            priority: result.priority,
                            category: result.category,
                            isSuccess: true,
                            isCancelled: false
                        }
                    }
                }));
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result?.errorMessage || 'I couldn\'t create the Incident due to an error.',
                        variant: 'error'
                    })
                );
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'I couldn\'t create the Incident due to an error. Please review the information and try again.',
                    variant: 'error'
                })
            );
        });
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
