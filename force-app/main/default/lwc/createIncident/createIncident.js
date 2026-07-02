import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getPicklistValues from '@salesforce/apex/IncidentController.getPicklistValues';
import createIncident from '@salesforce/apex/IncidentController.createIncident';

export default class CreateIncident extends LightningElement {

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

    @track subject = '';
    @track description = '';
    @track status = '';
    @track priority = '';
    @track urgency = '';
    @track impact = '';

    @track statusOptions = [];
    @track priorityOptions = [];
    @track urgencyOptions = [];
    @track impactOptions = [];

    @track isLoading = false;

    connectedCallback() {
        this.loadPicklists();
    }

    loadPicklists() {

        this.loadPicklist('Status', 'statusOptions', 'status');
        this.loadPicklist('Priority', 'priorityOptions', 'priority');
        this.loadPicklist('Urgency', 'urgencyOptions', 'urgency');
        this.loadPicklist('Impact', 'impactOptions', 'impact');

    }

    loadPicklist(fieldName, optionName, valueName) {

        getPicklistValues({
            fieldApiName: fieldName
        })
        .then(result => {

            this[optionName] = result.map(item => {
                return {
                    label: item,
                    value: item
                };
            });

            if(result.length > 0){
                this[valueName] = result[0];
            }

        })
        .catch(error => {

            this.showToast(
                'Error',
                error.body.message,
                'error'
            );

        });

    }

    handleSubject(event){
        this.subject = event.target.value;
    }

    handleDescription(event){
        this.description = event.target.value;
    }

    handleStatus(event){
        this.status = event.detail.value;
    }

    handlePriority(event){
        this.priority = event.detail.value;
    }

    handleUrgency(event){
        this.urgency = event.detail.value;
    }

    handleImpact(event){
        this.impact = event.detail.value;
    }

    validateFields(){

        if(!this.subject){
            this.showToast(
                'Validation Error',
                'Subject is required.',
                'error'
            );
            return false;
        }

        if(!this.status){
            this.showToast(
                'Validation Error',
                'Status is required.',
                'error'
            );
            return false;
        }

        if(!this.priority){
            this.showToast(
                'Validation Error',
                'Priority is required.',
                'error'
            );
            return false;
        }

        if(!this.urgency){
            this.showToast(
                'Validation Error',
                'Urgency is required.',
                'error'
            );
            return false;
        }

        if(!this.impact){
            this.showToast(
                'Validation Error',
                'Impact is required.',
                'error'
            );
            return false;
        }

        return true;

    }

    handleCreate(){

        if(!this.validateFields()){
            return;
        }

        this.isLoading = true;

        createIncident({

            subject : this.subject,
            description : this.description,
            status : this.status,
            priority : this.priority,
            urgency : this.urgency,
            impact : this.impact

        })

        .then(result=>{

            this.showToast(
                'Success',
                'Incident created successfully.',
                'success'
            );

            console.log('Incident Id : '+result);

            this.clearForm();

            this.dispatchEvent(
                new CustomEvent('incidentcreated',{
                    detail:{
                        incidentId:result
                    }
                })
            );

            // Dispatch valuechange event for Agentforce reasoner integration
            this.dispatchEvent(new CustomEvent('valuechange', {
                detail: {
                    value: {
                        incidentId: result,
                        subject: this.subject,
                        description: this.description,
                        status: this.status,
                        priority: this.priority,
                        urgency: this.urgency,
                        impact: this.impact,
                        isSuccess: true,
                        isCancelled: false
                    }
                }
            }));

        })

        .catch(error=>{

            this.showToast(
                'Error',
                error.body.message,
                'error'
            );

        })

        .finally(()=>{

            this.isLoading = false;

        });

    }

    handleCancel(){

        this.clearForm();

        // Dispatch valuechange event for Agentforce reasoner integration
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                value: {
                    isSuccess: false,
                    isCancelled: true
                }
            }
        }));

    }

    clearForm(){

        this.subject='';

        this.description='';

        if(this.statusOptions.length>0){
            this.status=this.statusOptions[0].value;
        }

        if(this.priorityOptions.length>0){
            this.priority=this.priorityOptions[0].value;
        }

        if(this.urgencyOptions.length>0){
            this.urgency=this.urgencyOptions[0].value;
        }

        if(this.impactOptions.length>0){
            this.impact=this.impactOptions[0].value;
        }

    }

    showToast(title,message,variant){

        this.dispatchEvent(

            new ShowToastEvent({

                title:title,

                message:message,

                variant:variant

            })

        );

    }

}