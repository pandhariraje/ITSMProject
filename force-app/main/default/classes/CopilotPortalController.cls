public with sharing class CopilotPortalController {
    
    public class TicketWrapper {
        @AuraEnabled public Id id {get;set;}
        @AuraEnabled public String ticketNumber {get;set;}
        @AuraEnabled public String subject {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String priority {get;set;}
        @AuraEnabled public String ticketType {get;set;}
        @AuraEnabled public Datetime createdDate {get;set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<TicketWrapper> getOpenTickets() {
        List<TicketWrapper> tickets = new List<TicketWrapper>();
        Id userId = UserInfo.getUserId();
        
        // Fetch incidents
        for (Incident inc : [SELECT Id, IncidentNumber, Subject, Status, Priority, CreatedDate 
                              FROM Incident 
                              WHERE ReportedById = :userId AND Status != 'Closed' AND Status != 'Resolved'
                              WITH USER_MODE 
                              ORDER BY CreatedDate DESC LIMIT 50]) {
            TicketWrapper tw = new TicketWrapper();
            tw.id = inc.Id;
            tw.ticketNumber = inc.IncidentNumber;
            tw.subject = inc.Subject;
            tw.status = inc.Status;
            tw.priority = inc.Priority;
            tw.ticketType = 'Incident';
            tw.createdDate = inc.CreatedDate;
            tickets.add(tw);
        }

        // Fetch service requests
        for (ServiceRequest sr : [SELECT Id, Name, Subject, Status, Priority, CreatedDate 
                                  FROM ServiceRequest 
                                  WHERE ReportedById = :userId AND Status != 'Closed' AND Status != 'Resolved'
                                  WITH USER_MODE 
                                  ORDER BY CreatedDate DESC LIMIT 50]) {
            TicketWrapper tw = new TicketWrapper();
            tw.id = sr.Id;
            tw.ticketNumber = sr.Name;
            tw.subject = sr.Subject;
            tw.status = sr.Status;
            tw.priority = sr.Priority;
            tw.ticketType = 'Service Request';
            tw.createdDate = sr.CreatedDate;
            tickets.add(tw);
        }

        return tickets;
    }

    @AuraEnabled
    public static void submitFeedback(Integer rating, String comments) {
        Customer_Feedback__c fb = new Customer_Feedback__c();
        fb.Rating__c = rating;
        fb.Comments__c = comments;
        fb.User__c = UserInfo.getUserId();
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Customer_Feedback__c>{fb});
        insert decision.getRecords();
    }

    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> searchArticles(String queryTerm) {
        if (String.isBlank(queryTerm)) {
            return new List<Knowledge__kav>();
        }
        String escapedQuery = String.escapeSingleQuotes(queryTerm.trim());
        String soslQuery = 'FIND \'' + escapedQuery + '\' IN ALL FIELDS RETURNING Knowledge__kav(Id, Title, Summary, Question__c, Answer__c, Procedure_Steps__c, Workaround__c)';
        List<List<SObject>> searchList = Search.query(soslQuery, AccessLevel.USER_MODE);
        if (!searchList.isEmpty()) {
            return (List<Knowledge__kav>) searchList[0];
        }
        return new List<Knowledge__kav>();
    }
}