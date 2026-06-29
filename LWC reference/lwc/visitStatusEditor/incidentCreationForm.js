import { LightningElement, wire, track } from 'lwc';
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

import createIncident from '@salesforce/apex/IncidentController.createIncident';

export default class IncidentCreationForm extends LightningElement {

    subject='';
    description='';
    status='';
    priority='';
    urgency='';
    impact='';

    @track statusOptions=[];
    @track priorityOptions=[];
    @track urgencyOptions=[];
    @track impactOptions=[];

    @wire(getObjectInfo,{objectApiName:INCIDENT_OBJECT})
    objectInfo;

    @wire(getPicklistValues,{
        recordTypeId:'$objectInfo.data.defaultRecordTypeId',
        fieldApiName:STATUS_FIELD
    })
    statusPicklist({data}){
        if(data){
            this.statusOptions=data.values;
        }
    }

    @wire(getPicklistValues,{
        recordTypeId:'$objectInfo.data.defaultRecordTypeId',
        fieldApiName:PRIORITY_FIELD
    })
    priorityPicklist({data}){
        if(data){
            this.priorityOptions=data.values;
        }
    }

    @wire(getPicklistValues,{
        recordTypeId:'$objectInfo.data.defaultRecordTypeId',
        fieldApiName:URGENCY_FIELD
    })
    urgencyPicklist({data}){
        if(data){
            this.urgencyOptions=data.values;
        }
    }

    @wire(getPicklistValues,{
        recordTypeId:'$objectInfo.data.defaultRecordTypeId',
        fieldApiName:IMPACT_FIELD
    })
    impactPicklist({data}){
        if(data){
            this.impactOptions=data.values;
        }
    }

    handleSubject(event){
        this.subject=event.target.value;
    }

    handleDescription(event){
        this.description=event.target.value;
    }

    handleStatus(event){
        this.status=event.detail.value;
    }

    handlePriority(event){
        this.priority=event.detail.value;
    }

    handleUrgency(event){
        this.urgency=event.detail.value;
    }

    handleImpact(event){
        this.impact=event.detail.value;
    }

    createIncident(){

        createIncident({
            subject:this.subject,
            description:this.description,
            status:this.status,
            priority:this.priority,
            urgency:this.urgency,
            impact:this.impact
        })
        .then(result=>{
            this.dispatchEvent(
                new ShowToastEvent({
                    title:'Success',
                    message:'Incident Created Successfully',
                    variant:'success'
                })
            );
        })
        .catch(error=>{
            this.dispatchEvent(
                new ShowToastEvent({
                    title:'Error',
                    message:error.body.message,
                    variant:'error'
                })
            );
        });
    }

}