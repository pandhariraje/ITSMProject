public with sharing class CopilotNotificationHelper {

    public class NotificationRequest {
        @InvocableVariable(label='Recipient Email' description='Email of the recipient' required=true)
        public String recipientEmail;
        @InvocableVariable(label='Subject' description='Subject of the notification' required=true)
        public String subject;
        @InvocableVariable(label='Body' description='Body text of the notification' required=true)
        public String body;
    }

    @InvocableMethod(label='Send IT Support Notification' description='Sends email notification regarding IT Support activities.')
    public static void sendNotification(List<NotificationRequest> requests) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (NotificationRequest req : requests) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{req.recipientEmail});
            email.setSubject(req.subject);
            email.setPlainTextBody(req.body);
            emails.add(email);
        }
        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug('Error sending email notification: ' + e.getMessage());
            }
        }
    }
}