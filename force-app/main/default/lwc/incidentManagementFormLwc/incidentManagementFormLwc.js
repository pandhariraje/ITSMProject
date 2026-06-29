import { LightningElement, api, track, wire } from 'lwc';
import getIncidentFieldsMetadata from '@salesforce/apex/IncidentMetadataController.getIncidentFieldsMetadata';
import createIncident from '@salesforce/apex/IncidentManagementController.createIncident';
import updateIncident from '@salesforce/apex/IncidentManagementController.updateIncident';
import searchIncidents from '@salesforce/apex/IncidentManagementController.searchIncidents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class IncidentManagementFormLwc extends LightningElement {
    @api label = 'Incident Management';

    // Inputs (pre-populated by Agentforce / Flow)
    @api incidentId = '';
    @api incidentNumber = '';
    @api subject = '';
    @api description = '';
    @api category = '';
    @api urgency = '';
    @api impact = '';
    @api priority = '';
    @api status = '';

    // Local tracked variables
    @track localIncidentId = '';
    @track localIncidentNumber = '';
    @track localSubject = '';
    @track localDescription = '';
    @track localCategory = 'Software';
    @track localUrgency = 'High';
    @track localImpact = 'High';
    @track localPriority = 'Critical';
    @track localStatus = 'New';

    @track isLoading = false;
    @track error = '';
    @track isSuccess = false;

    @track activeTab = 'create'; // 'create' or 'edit'
    @track isEditMode = false;
    @track searchKey = '';
    @track searchResults = [];
    @track isSearching = false;

    @track categoryOptions = [
        { label: 'Software', value: 'Software' },
        { label: 'Hardware', value: 'Hardware' },
        { label: 'Network', value: 'Network' }
    ];
    @track statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Open', value: 'Open' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Resolved', value: 'Resolved' },
        { label: 'Closed', value: 'Closed' },
        { label: 'Escalated', value: 'Escalated' }
    ];
    @track priorityOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' },
        { label: 'Critical', value: 'Critical' }
    ];
    @track urgencyOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];
    @track impactOptions = [
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' }
    ];

    _value;
    @api 
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
        if (val) {
            this.syncFromObject(val);
        }
    }

    @wire(getIncidentFieldsMetadata)
    wiredMetadata({ error, data }) {
        if (data) {
            data.forEach(field => {
                if (field.picklistOptions && field.picklistOptions.length > 0) {
                    const opts = field.picklistOptions.map(opt => ({ label: opt.label, value: opt.value }));
                    if (field.fieldName === 'Category') this.categoryOptions = opts;
                    else if (field.fieldName === 'Status') this.statusOptions = opts;
                    else if (field.fieldName === 'Priority') this.priorityOptions = opts;
                    else if (field.fieldName === 'Urgency') this.urgencyOptions = opts;
                    else if (field.fieldName === 'Impact') this.impactOptions = opts;
                }
            });
        }
    }

    connectedCallback() {
        if (this._value) {
            this.syncFromObject(this._value);
        } else {
            this.syncFromProps();
        }
    }

    syncFromProps() {
        this.localIncidentId = this.incidentId || '';
        this.localIncidentNumber = this.incidentNumber || '';
        this.localSubject = this.subject || '';
        this.localDescription = this.description || '';
        this.localCategory = this.category || 'Software';
        this.localUrgency = this.urgency || 'High';
        this.localImpact = this.impact || 'High';
        this.localPriority = this.priority || 'Critical';
        this.localStatus = this.status || 'New';
        
        this.isEditMode = !!this.localIncidentId || !!this.localIncidentNumber;
        if (this.isEditMode) {
            this.activeTab = 'edit';
        }
    }

    syncFromObject(val) {
        const getVal = (propName) => {
            const key = Object.keys(val).find(k => k.toLowerCase() === propName.toLowerCase());
            return key && val[key] !== undefined && val[key] !== null ? val[key] : '';
        };

        this.localIncidentId = getVal('incidentId') || getVal('id') || this.incidentId || '';
        this.localIncidentNumber = getVal('incidentNumber') || this.incidentNumber || '';
        this.localSubject = getVal('subject') || this.subject || '';
        this.localDescription = getVal('description') || this.description || '';
        this.localCategory = getVal('category') || this.category || 'Software';
        this.localUrgency = getVal('urgency') || this.urgency || 'High';
        this.localImpact = getVal('impact') || this.impact || 'High';
        this.localPriority = getVal('priority') || this.priority || 'Critical';
        this.localStatus = getVal('status') || this.status || 'New';

        this.isEditMode = !!this.localIncidentId || !!this.localIncidentNumber;
        if (this.isEditMode) {
            this.activeTab = 'edit';
        }
    }

    handleTabChange(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        if (this.activeTab === 'create') {
            this.isEditMode = false;
            this.localIncidentId = '';
            this.localIncidentNumber = '';
            this.localSubject = '';
            this.localDescription = '';
            this.localCategory = 'Software';
            this.localUrgency = 'High';
            this.localImpact = 'High';
            this.localPriority = 'Critical';
            this.localStatus = 'New';
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
            this.localIncidentId = selected.incidentId;
            this.localIncidentNumber = selected.incidentNumber;
            this.localSubject = selected.subject || '';
            this.localDescription = selected.description || '';
            this.localCategory = selected.category || 'Software';
            this.localStatus = selected.status || 'New';
            this.localUrgency = selected.urgency || 'High';
            this.localImpact = selected.impact || 'High';
            this.localPriority = selected.priority || 'Critical';
            this.isEditMode = true;
            
            this.searchResults = [];
            this.searchKey = '';
            this.error = '';
            this.isSuccess = false;
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.dataset.name;
        const val = event.target.value;
        if (fieldName === 'subject') this.localSubject = val;
        else if (fieldName === 'description') this.localDescription = val;
        else if (fieldName === 'category') this.localCategory = val;
        else if (fieldName === 'status') this.localStatus = val;
        else if (fieldName === 'urgency') this.localUrgency = val;
        else if (fieldName === 'impact') this.localImpact = val;
        else if (fieldName === 'priority') this.localPriority = val;
    }

    get formHeaderTitle() {
        return this.isEditMode ? `Update Incident: ${this.localIncidentNumber}` : 'Report New Incident';
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

    get showSearchSection() {
        return this.isEditTabActive && !this.isEditMode;
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

        if (this.isEditMode && this.localIncidentId) {
            updateIncident({
                incidentId: this.localIncidentId,
                subject: this.localSubject,
                description: this.localDescription,
                urgency: this.localUrgency,
                impact: this.localImpact,
                priority: this.localPriority,
                status: this.localStatus,
                category: this.localCategory
            })
            .then(result => {
                this.isLoading = false;
                this.isSuccess = true;
                this.localIncidentId = result.incidentId;
                this.localIncidentNumber = result.incidentNumber;

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
            });
        } else {
            createIncident({
                subject: this.localSubject,
                description: this.localDescription,
                urgency: this.localUrgency,
                impact: this.localImpact,
                priority: this.localPriority,
                status: this.localStatus,
                category: this.localCategory
            })
            .then(result => {
                this.isLoading = false;
                this.isSuccess = true;
                this.localIncidentId = result.incidentId;
                this.localIncidentNumber = result.incidentNumber;

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
            });
        }
    }

    dispatchValueChange(result) {
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                    value: {
                        incidentId: this.localIncidentId,
                        incidentNumber: this.localIncidentNumber,
                        subject: this.localSubject,
                        description: this.localDescription,
                        category: this.localCategory,
                        urgency: this.localUrgency,
                        impact: this.localImpact,
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
        return `/lightning/r/Incident/${this.localIncidentId}/view`;
    }
}
