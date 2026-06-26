import { LightningElement, api, track } from 'lwc';
import getIncidentFieldsMetadata from '@salesforce/apex/IncidentMetadataController.getIncidentFieldsMetadata';
import createIncident from '@salesforce/apex/IncidentManagementController.createIncident';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IncidentManagementFormLwc extends LightningElement {
    @api label = 'Report New Incident';

    _value;
    @api 
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
        this.initializeValues();
    }

    @track fields = [];
    @track fieldValues = {
        Subject: '',
        Description: '',
        Urgency: 'Medium',
        Impact: 'Medium',
        Priority: 'Low',
        Status: 'New'
    };
    @track isLoading = false;
    @track error = '';
    @track isSuccess = false;
    @track incidentId = '';
    @track incidentNumber = '';

    connectedCallback() {
        this.isLoading = true;
        getIncidentFieldsMetadata()
            .then(result => {
                this.fields = result.map(field => {
                    let options = [];
                    if (field.picklistOptions) {
                        options = field.picklistOptions.map(opt => ({
                            label: opt.label,
                            value: opt.value
                        }));
                    }

                    // Default values
                    let val = '';
                    if (field.fieldName === 'Urgency') val = 'Medium';
                    else if (field.fieldName === 'Impact') val = 'Medium';
                    else if (field.fieldName === 'Priority') val = 'Low';
                    else if (field.fieldName === 'Status') val = 'New';
                    
                    this.fieldValues[field.fieldName] = val;

                    return {
                        ...field,
                        isPicklist: field.type === 'picklist',
                        isTextarea: field.type === 'textarea',
                        isInput: field.type !== 'picklist' && field.type !== 'textarea',
                        options: options,
                        value: val
                    };
                });
                this.initializeValues();
                this.isLoading = false;
            })
            .catch(err => {
                this.error = err.body ? err.body.message : err.message;
                this.isLoading = false;
            });
    }

    initializeValues() {
        if (this._value && this.fields.length > 0) {
            this.fields = this.fields.map(f => {
                const apiFieldName = f.fieldName.toLowerCase();
                const key = Object.keys(this._value).find(k => k.toLowerCase() === apiFieldName);
                const val = (key && this._value[key]) ? this._value[key] : f.value;
                this.fieldValues[f.fieldName] = val;
                return { ...f, value: val };
            });
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        const val = event.target.value;
        this.fieldValues[fieldName] = val;

        this.fields = this.fields.map(f => {
            if (f.fieldName === fieldName) {
                return { ...f, value: val };
            }
            return f;
        });
    }

    get isSubmitDisabled() {
        if (this.isLoading) return true;
        for (const field of this.fields) {
            if (field.isRequired) {
                const val = this.fieldValues[field.fieldName];
                if (val === undefined || val === null || String(val).trim() === '') {
                    return true;
                }
            }
        }
        return false;
    }

    handleSubmit() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')
        ].reduce((validSoFar, inputFields) => {
            inputFields.reportValidity();
            return validSoFar && inputFields.checkValidity();
        }, true);

        if (!allValid) {
            return;
        }

        this.isLoading = true;
        this.error = '';

        createIncident({
            subject: this.fieldValues.Subject,
            description: this.fieldValues.Description,
            urgency: this.fieldValues.Urgency,
            impact: this.fieldValues.Impact,
            priority: this.fieldValues.Priority,
            status: this.fieldValues.Status
        })
        .then(result => {
            this.isLoading = false;
            this.isSuccess = true;
            this.incidentId = result.incidentId;
            this.incidentNumber = result.incidentNumber;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Incident Created Successfully',
                    message: `Incident Number: ${result.incidentNumber}\nStatus: ${result.status}\nPriority: ${result.priority}`,
                    variant: 'success'
                })
            );

            this.dispatchEvent(
                new CustomEvent('valuechange', {
                    detail: {
                        value: {
                            incidentId: this.incidentId,
                            incidentNumber: this.incidentNumber,
                            subject: this.fieldValues.Subject,
                            description: this.fieldValues.Description,
                            urgency: this.fieldValues.Urgency,
                            impact: this.fieldValues.Impact,
                            priority: result.priority,
                            status: result.status
                        }
                    }
                })
            );
        })
        .catch(err => {
            this.isLoading = false;
            this.error = err.body ? err.body.message : err.message;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Unable to create Incident.',
                    message: 'Please try again.',
                    variant: 'error'
                })
            );
        });
    }

    handleCancel() {
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                    value: null
                }
            })
        );
    }

    get incidentRecordUrl() {
        return `/lightning/r/Incident/${this.incidentId}/view`;
    }
}
