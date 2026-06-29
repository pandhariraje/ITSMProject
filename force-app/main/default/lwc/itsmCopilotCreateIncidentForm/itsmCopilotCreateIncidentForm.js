import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import INCIDENT_OBJECT from '@salesforce/schema/Incident';
import SUBJECT_FIELD from '@salesforce/schema/Incident.Subject';
import DESCRIPTION_FIELD from '@salesforce/schema/Incident.Description';
import STATUS_FIELD from '@salesforce/schema/Incident.Status';
import PRIORITY_FIELD from '@salesforce/schema/Incident.Priority';
import URGENCY_FIELD from '@salesforce/schema/Incident.Urgency';
import IMPACT_FIELD from '@salesforce/schema/Incident.Impact';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

import createIncident from '@salesforce/apex/ITSMCopilotCreateIncidentAction.createIncident';

export default class ItsmCopilotCreateIncidentForm extends LightningElement {
    @api subject = '';
    @api description = '';
    @api status = 'New';
    @api priority = 'Medium';
    @api urgency = 'Medium';
    @api impact = 'Medium';

    @track statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Open', value: 'Open' },
        { label: 'In Process', value: 'In Process' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Closed', value: 'Closed' }
    ];
    @track priorityOptions = [
        { label: 'Critical', value: 'Critical' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
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

    createIncident() {
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

        createIncident({
            subject: this.subject,
            description: this.description,
            status: this.status,
            priority: this.priority,
            urgency: this.urgency,
            impact: this.impact
        })
        .then(result => {
            this.isLoading = false;
            if (result.isSuccess) {
                this.incidentNumber = result.incidentNumber;
                this.isSubmitted = true;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Incident Created Successfully (' + result.incidentNumber + ')',
                        variant: 'success'
                    })
                );

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
                this.customError = result.errorMessage || 'Error creating incident.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.customError,
                        variant: 'error'
                    })
                );
            }
        })
        .catch(error => {
            this.isLoading = false;
            this.customError = error.body ? error.body.message : 'Error creating incident.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.customError,
                    variant: 'error'
                })
            );
        });
    }
}
