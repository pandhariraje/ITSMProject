public with sharing class CopilotEmployeeWrapper {

    public class IncidentFormInput {
        @InvocableVariable(label='Subject' required=true)
        public String subject;

        @InvocableVariable(label='Description' required=true)
        public String description;

        @InvocableVariable(label='Category' required=false)
        public String category;

        @InvocableVariable(label='Urgency' required=false)
        public String urgency;

        @InvocableVariable(label='Impact' required=false)
        public String impact;

        @InvocableVariable(label='Status' required=false)
        public String status;

        @InvocableVariable(label='Priority' required=false)
        public String priority;
    }

    public class ArticleResult {
        @InvocableVariable(label='Article ID')
        public String id;

        @InvocableVariable(label='Title')
        public String title;

        @InvocableVariable(label='Summary')
        public String summary;

        @InvocableVariable(label='Url Name')
        public String urlName;
    }
}
