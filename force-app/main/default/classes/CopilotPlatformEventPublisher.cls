public with sharing class CopilotPlatformEventPublisher {
    
    public class EventRequest {
        @InvocableVariable(label='Event Name' description='Name of the event' required=true)
        public String eventName;
        @InvocableVariable(label='Payload' description='JSON payload of the event' required=true)
        public String payload;
    }

    @InvocableMethod(label='Publish IT Support Event' description='Publishes a telemetry event for IT Support Copilot.')
    public static void publishEvent(List<EventRequest> requests) {
        List<IT_Support_Event__e> events = new List<IT_Support_Event__e>();
        for (EventRequest req : requests) {
            IT_Support_Event__e ev = new IT_Support_Event__e();
            ev.Event_Name__c = req.eventName;
            ev.Payload__c = req.payload;
            events.add(ev);
        }
        if (!events.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(events);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error publishing event: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
    }
}