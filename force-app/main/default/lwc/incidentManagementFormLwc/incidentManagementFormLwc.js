import { LightningElement, api, track, wire } from 'lwc';
import getIncidentFieldsMetadata from '@salesforce/apex/IncidentMetadataController.getIncidentFieldsMetadata';
import createIncident from '@salesforce/apex/IncidentManagementController.createIncident';
import updateIncident from '@salesforce/apex/IncidentManagementController.updateIncident';
import searchIncidents from '@salesforce/apex/IncidentManagementController.searchIncidents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IncidentManagementFormLwc extends LightningElement {
    @api label = 'Incident Management';

    _value;
    @api 
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
        if (val) {
            this.incidentId = val.incidentId || '';
            this.incidentNumber = val.incidentNumber || '';
            this.isEditMode = !!this.incidentId;
            if (this.isEditMode) {
                this.activeTab = 'edit';
            }
        } else {
            this.incidentId = '';
            this.incidentNumber = '';
            this.isEditMode = false;
            this.activeTab = 'create';
        }
        this.initializeValues();
    }

    @track fields = [];
    @track fieldValues = {
        Subject: '',
        Description: '',
        Category: '',
        Urgency: '',
        Impact: '',
        Priority: '',
        Status: ''
    };
    @track isLoading = true;
    @track error = '';
    @track isSuccess = false;
    @track incidentId = '';
    @track incidentNumber = '';

    @track activeTab = 'create'; // 'create' or 'edit'
    @track searchKey = '';
    @track searchResults = [];
    @track isSearching = false;

    @wire(getIncidentFieldsMetadata)
    wiredMetadata({ error, data }) {
        if (data) {
            this.fields = data.map(field => {
                let options = [];
                let val = '';
                if (field.picklistOptions) {
                    options = field.picklistOptions.map(opt => {
                        if (opt.isDefault) {
                            val = opt.value;
                        }
                        return {
                            label: opt.label,
                            value: opt.value
                        };
                    });
                }

                // Fallback default values if database does not specify a default
                if (!val && field.type === 'picklist') {
                    if (field.fieldName === 'Urgency') val = 'High';
                    else if (field.fieldName === 'Impact') val = 'High';
                    else if (field.fieldName === 'Priority') val = 'Critical';
                    else if (field.fieldName === 'Status') val = 'New';
                }

                this.fieldValues[field.fieldName] = val;

                // Determine column spans for premium grid alignment
                let gridClass = 'grid-col-6'; // default: half width (col-6)
                if (field.fieldName === 'Subject' || field.fieldName === 'Description') {
                    gridClass = 'grid-col-12'; // full width (col-12)
                } else if (field.fieldName === 'Urgency' || field.fieldName === 'Impact' || field.fieldName === 'Priority') {
                    gridClass = 'grid-col-4'; // one-third width (col-4)
                }

                return {
                    ...field,
                    isPicklist: field.type === 'picklist',
                    isTextarea: field.type === 'textarea',
                    isInput: field.type !== 'picklist' && field.type !== 'textarea',
                    options: options,
                    value: val,
                    gridClass: gridClass
                };
            });
            this.initializeValues();
            this.isLoading = false;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.isLoading = false;
        }
    }

    connectedCallback() {
        // Wired method handles data fetching and loading states.
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

    handleTabChange(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        if (this.activeTab === 'create') {
            this.isEditMode = false;
            this.incidentId = '';
            this.incidentNumber = '';
            // reset form fields to defaults
            this.fields = this.fields.map(f => {
                let val = '';
                if (f.fieldName === 'Urgency') val = 'High';
                else if (f.fieldName === 'Impact') val = 'High';
                else if (f.fieldName === 'Priority') val = 'Critical';
                else if (f.fieldName === 'Status') val = 'New';
                
                this.fieldValues[f.fieldName] = val;
                return { ...f, value: val };
            });
            this.isSuccess = false;
            this.error = '';
        } else {
            this.searchResults = [];
            this.searchKey = '';
        }
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
        if (this.searchKey.length >= 2) {
            this.isSearching = true;
            searchIncidents({ searchTerm: this.searchKey })
                .then(results => {
                    this.searchResults = results;
                    this.isSearching = false;
                })
                .catch(err => {
                    this.error = err.body ? err.body.message : err.message;
                    this.isSearching = false;
                });
        } else {
            this.searchResults = [];
        }
    }

    handleSelectIncident(event) {
        const selectedId = event.currentTarget.dataset.id;
        const selected = this.searchResults.find(item => item.incidentId === selectedId);
        if (selected) {
            this.incidentId = selected.incidentId;
            this.incidentNumber = selected.incidentNumber;
            this.isEditMode = true;
            
            // Populate fields
            this.fields = this.fields.map(f => {
                // Check wrapper property mapping
                // Map fields correctly to values from the wrapper (check case)
                let val = '';
                if (f.fieldName === 'Subject') val = selected.subject;
                else if (f.fieldName === 'Description') val = selected.description;
                else if (f.fieldName === 'Category') val = selected.category;
                else if (f.fieldName === 'Status') val = selected.status;
                else if (f.fieldName === 'Urgency') val = selected.urgency;
                else if (f.fieldName === 'Impact') val = selected.impact;
                else if (f.fieldName === 'Priority') val = selected.priority;

                this.fieldValues[f.fieldName] = val || '';
                return { ...f, value: val || '' };
            });
            
            this.searchResults = [];
            this.searchKey = '';
            this.error = '';
            this.isSuccess = false;
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

    get submitButtonLabel() {
        return this.isEditMode ? 'Update Incident' : 'Submit Incident';
    }

    get formHeaderTitle() {
        return this.isEditMode ? `Update Incident: ${this.incidentNumber}` : 'Report New Incident';
    }

    get formHeaderSub() {
        return this.isEditMode ? 'Modify the details of the incident below.' : 'Please enter the details below to log your technical issue.';
    }

    get isCreateTabActive() {
        return this.activeTab === 'create';
    }

    get isEditTabActive() {
        return this.activeTab === 'edit';
    }

    get createTabClass() {
        return `tab-button ${this.isCreateTabActive ? 'active' : ''}`;
    }

    get editTabClass() {
        return `tab-button ${this.isEditTabActive ? 'active' : ''}`;
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

        if (this.isEditMode) {
            updateIncident({
                incidentId: this.incidentId,
                subject: this.fieldValues.Subject,
                description: this.fieldValues.Description,
                urgency: this.fieldValues.Urgency,
                impact: this.fieldValues.Impact,
                priority: this.fieldValues.Priority,
                status: this.fieldValues.Status,
                category: this.fieldValues.Category
            })
            .then(result => {
                this.isLoading = false;
                this.isSuccess = true;
                this.incidentId = result.incidentId;
                this.incidentNumber = result.incidentNumber;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Incident Updated Successfully',
                        message: `Incident Number: ${result.incidentNumber}\nStatus: ${result.status}\nPriority: ${result.priority}`,
                        variant: 'success'
                    })
                );

                this.dispatchValueChange(result);
            })
            .catch(err => {
                this.isLoading = false;
                this.error = err.body ? err.body.message : err.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Unable to update Incident.',
                        message: 'Please try again.',
                        variant: 'error'
                    })
                );
            });
        } else {
            createIncident({
                subject: this.fieldValues.Subject,
                description: this.fieldValues.Description,
                urgency: this.fieldValues.Urgency,
                impact: this.fieldValues.Impact,
                priority: this.fieldValues.Priority,
                status: this.fieldValues.Status,
                category: this.fieldValues.Category
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

                this.dispatchValueChange(result);
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
    }

    dispatchValueChange(result) {
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                    value: {
                        incidentId: this.incidentId,
                        incidentNumber: this.incidentNumber,
                        subject: this.fieldValues.Subject,
                        description: this.fieldValues.Description,
                        category: this.fieldValues.Category,
                        urgency: this.fieldValues.Urgency,
                        impact: this.fieldValues.Impact,
                        priority: result.priority,
                        status: result.status
                    }
                }
            })
        );
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
