@isTest
public class CopilotPortalControllerTest {
    
    @isTest
    static void testGetOpenTicketsAndSubmitFeedback() {
        // Create an Incident
        Incident inc = new Incident(
            Subject = 'Portal Test Incident',
            Description = 'Test incident description',
            Category = 'Network',
            Urgency = 'High',
            Impact = 'High',
            Priority = 'Critical',
            Status = 'New',
            ReportedById = UserInfo.getUserId()
        );
        insert inc;

        // Create a ServiceRequest
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Portal Test SR',
            Description = 'Test SR description',
            Priority = 'High',
            Status = 'New',
            ReportedById = UserInfo.getUserId()
        );
        insert sr;

        Test.startTest();
        List<CopilotPortalController.TicketWrapper> tickets = CopilotPortalController.getOpenTickets();
        CopilotPortalController.submitFeedback(5, 'Excellent support assistant!');
        
        // Mock SOSL search results
        List<Id> fixedSearchResults = new List<Id>();
        Test.setFixedSearchResults(fixedSearchResults);
        List<Knowledge__kav> articles = CopilotPortalController.searchArticles('VPN');
        Test.stopTest();

        System.assertNotEquals(0, tickets.size(), 'Should return tickets');
        System.assertNotEquals(null, articles, 'Articles list should not be null');
        List<Customer_Feedback__c> feedback = [SELECT Rating__c, Comments__c FROM Customer_Feedback__c];
        System.assertEquals(1, feedback.size(), 'Should have saved 1 feedback record');
        System.assertEquals(5, feedback[0].Rating__c);
    }
}