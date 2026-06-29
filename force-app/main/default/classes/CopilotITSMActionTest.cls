@isTest
public class CopilotITSMActionTest {

    @isTest
    static void testCopilotCreateIncidentAction() {
        // Create an active user to test requester email resolution
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        String uniqueName = 'itsmtestuser' + DateTime.now().getTime() + '@test.com';
        User testUser = new User(
            Alias = 'copilt',
            Email = 'testcopilotuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueName
        );
        insert testUser;

        // Test Request 1: High/High -> Critical priority, Network category
        CopilotCreateIncidentAction.Request req1 = new CopilotCreateIncidentAction.Request();
        req1.subject = 'Network connection failure';
        req1.description = 'The internet connection is completely down at the main office.';
        req1.category = 'Network';
        req1.urgency = 'High';
        req1.impact = 'High';
        req1.requesterEmail = 'testcopilotuser@test.com';

        // Test Request 2: Medium/Medium -> Medium priority, Hardware category
        CopilotCreateIncidentAction.Request req2 = new CopilotCreateIncidentAction.Request();
        req2.subject = 'Printer toner low';
        req2.description = 'Toner needs replacement in the 3rd floor printer.';
        req2.category = 'Hardware';
        req2.urgency = 'Medium';
        req2.impact = 'Medium';

        // Test Request 3: Low/Low -> Low priority, Software category
        CopilotCreateIncidentAction.Request req3 = new CopilotCreateIncidentAction.Request();
        req3.subject = 'Slack configuration request';
        req3.description = 'Requesting Slack workspace notification update.';
        req3.category = 'Software';
        req3.urgency = 'Low';
        req3.impact = 'Low';

        Test.startTest();
        List<CopilotCreateIncidentAction.Result> results = CopilotCreateIncidentAction.createIncident(
            new List<CopilotCreateIncidentAction.Request>{req1, req2, req3}
        );
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 results');
        
        System.assert(results[0].isSuccess, 'Req1 should succeed');
        System.assertNotEquals(null, results[0].incidentId, 'Req1 incidentId should be set');
        System.assertEquals('Critical', results[0].priority, 'Calculated Priority should be Critical');
        Incident inc1 = [SELECT Category, Priority, ReportedById, OwnerId FROM Incident WHERE Id = :results[0].incidentId];
        System.assertEquals('Network', inc1.Category);
        System.assertEquals('Critical', inc1.Priority);
        System.assertEquals(testUser.Id, inc1.ReportedById);

        System.assert(results[1].isSuccess, 'Req2 should succeed');
        System.assertEquals('Medium', results[1].priority, 'Calculated Priority should be Medium');
        Incident inc2 = [SELECT Category, Priority FROM Incident WHERE Id = :results[1].incidentId];
        System.assertEquals('Hardware', inc2.Category);
        System.assertEquals('Medium', inc2.Priority);

        System.assert(results[2].isSuccess, 'Req3 should succeed');
        System.assertEquals('Low', results[2].priority, 'Calculated Priority should be Low');
        Incident inc3 = [SELECT Category, Priority FROM Incident WHERE Id = :results[2].incidentId];
        System.assertEquals('Software', inc3.Category);
        System.assertEquals('Low', inc3.Priority);
    }

    @isTest
    static void testCopilotCreateIncidentActionWithContact() {
        // Create an Account (Industry is required by validation/trigger)
        Account acc = new Account(Name = 'Test Tech Account', Industry = 'Technology');
        insert acc;

        Contact c = new Contact(
            LastName = 'Reporter',
            Email = 'reporter@itsmtest.com',
            AccountId = acc.Id
        );
        insert c;

        CopilotCreateIncidentAction.Request req = new CopilotCreateIncidentAction.Request();
        req.subject = 'Laptop boot failure';
        req.description = 'Laptop displays blue screen upon booting.';
        req.category = 'Hardware';
        req.urgency = 'High';
        req.impact = 'Medium';
        req.requesterEmail = 'reporter@itsmtest.com';

        Test.startTest();
        List<CopilotCreateIncidentAction.Result> results = CopilotCreateIncidentAction.createIncident(
            new List<CopilotCreateIncidentAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
        Incident inc = [SELECT Category, Priority, ReportedById FROM Incident WHERE Id = :results[0].incidentId];
        System.assertEquals(acc.Id, inc.ReportedById, 'ReportedById should match contact account');
    }

    @isTest
    static void testCopilotCreateServiceRequestAction() {
        CopilotCreateServiceRequestAction.Request req = new CopilotCreateServiceRequestAction.Request();
        req.subject = 'VPN Access Request';
        req.description = 'Need VPN access to connect to internal environments.';
        req.priority = 'Medium';
        req.requesterEmail = 'test@example.com';

        Test.startTest();
        List<CopilotCreateServiceRequestAction.Result> results = CopilotCreateServiceRequestAction.createServiceRequest(
            new List<CopilotCreateServiceRequestAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
        System.assertNotEquals(null, results[0].serviceRequestId);
        System.assertNotEquals(null, results[0].serviceRequestNumber);

        ServiceRequest sr = [SELECT Subject, Description, Priority, Status FROM ServiceRequest WHERE Id = :results[0].serviceRequestId];
        System.assertEquals('VPN Access Request', sr.Subject);
        System.assertEquals('Medium', sr.Priority);
        System.assertEquals('New', sr.Status);
    }

    @isTest
    static void testCopilotCheckTicketStatusAction() {
        // Insert test Incident
        Incident inc = new Incident(
            Subject = 'Status Test Incident',
            Description = 'Status check test',
            Category = 'Software',
            Urgency = 'Medium',
            Impact = 'Medium',
            Priority = 'Medium',
            Status = 'New'
        );
        insert inc;
        
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        // Insert test ServiceRequest
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Status Test SR',
            Description = 'Status check test',
            Priority = 'Low',
            Status = 'Submitted'
        );
        insert sr;

        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotCheckTicketStatusAction.Request req1 = new CopilotCheckTicketStatusAction.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;

        CopilotCheckTicketStatusAction.Request req2 = new CopilotCheckTicketStatusAction.Request();
        req2.ticketNumber = insertedSR.Name;

        CopilotCheckTicketStatusAction.Request req3 = new CopilotCheckTicketStatusAction.Request();
        req3.ticketNumber = 'NON_EXISTENT_NUMBER';

        Test.startTest();
        List<CopilotCheckTicketStatusAction.Result> results = CopilotCheckTicketStatusAction.checkTicketStatus(
            new List<CopilotCheckTicketStatusAction.Request>{req1, req2, req3}
        );
        Test.stopTest();

        System.assertEquals(3, results.size());

        // Assert req1 (Incident)
        System.assert(results[0].isSuccess);
        System.assertEquals(true, results[0].found);
        System.assertEquals('Incident', results[0].ticketType);
        System.assertEquals('New', results[0].status);
        System.assertEquals('Medium', results[0].priority);

        // Assert req2 (Service Request)
        System.assert(results[1].isSuccess);
        System.assertEquals(true, results[1].found);
        System.assertEquals('Service Request', results[1].ticketType);
        System.assertEquals('Submitted', results[1].status);
        System.assertEquals('Low', results[1].priority);

        // Assert req3 (Not Found)
        System.assert(results[2].isSuccess);
        System.assertEquals(false, results[2].found);
    }

    @isTest
    static void testCopilotSearchKnowledgeAction() {
        CopilotSearchKnowledgeAction.Request req = new CopilotSearchKnowledgeAction.Request();
        req.searchQuery = 'VPN';

        // Mock SOSL Results
        Id mockId = Id.valueOf('01I000000000000'); // Fake Id
        List<Id> fixedSearchResults = new List<Id>{mockId};
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        List<CopilotSearchKnowledgeAction.Result> results = CopilotSearchKnowledgeAction.searchKnowledge(
            new List<CopilotSearchKnowledgeAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
    }

    @isTest
    static void testCopilotEscalateTicketAction() {
        // Insert test Incident
        Incident inc = new Incident(
            Subject = 'Escalate Test Incident',
            Description = 'Escalate test',
            Category = 'Software',
            Urgency = 'High',
            Impact = 'High',
            Priority = 'High',
            Status = 'New'
        );
        insert inc;
        
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        // Insert test Service Request
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Escalate Test SR',
            Description = 'Escalate test',
            Priority = 'High',
            Status = 'New'
        );
        insert sr;

        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotEscalateTicketAction.Request req1 = new CopilotEscalateTicketAction.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;
        req1.escalationReason = 'Critical issue blocking work';

        CopilotEscalateTicketAction.Request req2 = new CopilotEscalateTicketAction.Request();
        req2.ticketNumber = insertedSR.Name;
        req2.escalationReason = 'Access request escalation';

        Test.startTest();
        List<CopilotEscalateTicketAction.Result> results = CopilotEscalateTicketAction.escalateTicket(
            new List<CopilotEscalateTicketAction.Request>{req1, req2}
        );
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assert(results[0].isSuccess);
        System.assert(results[1].isSuccess);

        Incident updatedInc = [SELECT Priority, Status FROM Incident WHERE Id = :inc.Id];
        System.assertEquals('Critical', updatedInc.Priority);
        System.assertEquals('Escalated', updatedInc.Status);

        ServiceRequest updatedSR = [SELECT Priority, Status FROM ServiceRequest WHERE Id = :sr.Id];
        System.assertEquals('Critical', updatedSR.Priority);
        System.assertEquals('Escalated', updatedSR.Status);
    }

    @isTest
    static void testCopilotCreateIncidentActionLwc() {
        Test.startTest();
        CopilotCreateIncidentAction.Result result = CopilotCreateIncidentAction.createIncidentLwc(
            'LWC Test Subject',
            'LWC Test Description',
            'Network',
            'High',
            'High',
            'lwctest@example.com',
            'Internet',
            'Normal',
            'New',
            'Critical'
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.isSuccess, 'Result should be successful');
        System.assertNotEquals(null, result.incidentId, 'Incident Id should be populated');
        System.assertNotEquals(null, result.incidentNumber, 'Incident Number should be populated');
        System.assertEquals('Critical', result.priority, 'Priority override should match');
    }

    @isTest
    static void testCopilotUpdateTicketAction() {
        // Insert test Incident
        Incident inc = new Incident(
            Subject = 'Update Test Incident',
            Description = 'Update test description',
            Category = 'Software',
            Urgency = 'Low',
            Impact = 'Low',
            Priority = 'Low',
            Status = 'New'
        );
        insert inc;
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        // Insert test Service Request
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Update Test SR',
            Description = 'Update test description',
            Priority = 'Low',
            Status = 'New'
        );
        insert sr;
        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        // Request 1: Update Incident Priority to High and Status to In Progress
        CopilotUpdateTicketAction.Request req1 = new CopilotUpdateTicketAction.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;
        req1.priority = 'High';
        req1.status = 'In Progress';

        // Request 2: Update Service Request Priority to Critical
        CopilotUpdateTicketAction.Request req2 = new CopilotUpdateTicketAction.Request();
        req2.ticketNumber = insertedSR.Name;
        req2.priority = 'Critical';

        // Request 3: Non-existent ticket number
        CopilotUpdateTicketAction.Request req3 = new CopilotUpdateTicketAction.Request();
        req3.ticketNumber = 'NON_EXISTENT_TICKET';
        req3.priority = 'High';

        Test.startTest();
        List<CopilotUpdateTicketAction.Result> results = CopilotUpdateTicketAction.updateTicket(
            new List<CopilotUpdateTicketAction.Request>{req1, req2, req3}
        );
        Test.stopTest();

        System.assertEquals(3, results.size());

        // Assert Req 1
        System.assert(results[0].isSuccess);
        System.assertEquals('Incident', results[0].ticketType);
        System.assertEquals('High', results[0].priority);
        System.assertEquals('In Progress', results[0].status);
        Incident updatedInc = [SELECT Priority, Status FROM Incident WHERE Id = :inc.Id];
        System.assertEquals('High', updatedInc.Priority);
        System.assertEquals('In Progress', updatedInc.Status);

        // Assert Req 2
        System.assert(results[1].isSuccess);
        System.assertEquals('Service Request', results[1].ticketType);
        System.assertEquals('Critical', results[1].priority);
        ServiceRequest updatedSR = [SELECT Priority, Status FROM ServiceRequest WHERE Id = :sr.Id];
        System.assertEquals('Critical', updatedSR.Priority);

        // Assert Req 3
        System.assert(!results[2].isSuccess);
        System.assertNotEquals(null, results[2].errorMessage);
    }
}

