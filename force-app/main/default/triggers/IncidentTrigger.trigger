trigger IncidentTrigger on Incident (after insert, after update) {

    if(Trigger.isAfter){

        if(Trigger.isInsert){
            IncidentTriggerHandler.handleRecurringIncidents(Trigger.new);
        }

        if(Trigger.isUpdate){
            IncidentTriggerHandler.handleRecurringIncidentsOnUpdate(
                Trigger.new,
                Trigger.oldMap
            );
        }
    }
}