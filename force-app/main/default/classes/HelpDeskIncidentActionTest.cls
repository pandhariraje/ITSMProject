@isTest
private class HelpDeskIncidentActionTest {

    @isTest
    static void testCreateIncidentAction() {
        HelpDeskIncidentFormWrapper wrapper = new HelpDeskIncidentFormWrapper();
        wrapper.subject = 'Test Subject';
        wrapper.description = 'Test Description';
        wrapper.category = 'Software';
        wrapper.urgency = 'High';
        wrapper.impact = 'High';
        wrapper.status = 'New';

        HelpDeskCreateIncidentAction.Request req = new HelpDeskCreateIncidentAction.Request();
        req.incidentData = wrapper;

        Test.startTest();
        List<HelpDeskCreateIncidentAction.Result> results = HelpDeskCreateIncidentAction.createIncident(
            new List<HelpDeskCreateIncidentAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertNotEquals(null, results[0].incidentId);
        System.assertNotEquals(null, results[0].incidentNumber);
    }

    @isTest
    static void testCreateIncidentActionLwc() {
        Test.startTest();
        HelpDeskCreateIncidentAction.Result result = HelpDeskCreateIncidentAction.createIncidentLwc(
            'LWC Subject', 'LWC Desc', 'Hardware', 'Medium', 'Medium', 'New', 'Medium'
        );
        Test.stopTest();

        System.assertEquals(true, result.isSuccess);
        System.assertNotEquals(null, result.incidentId);
    }

    @isTest
    static void testCreateServiceRequestAction() {
        HelpDeskCreateServiceRequestAction.Request req = new HelpDeskCreateServiceRequestAction.Request();
        req.subject = 'New Laptop';
        req.description = 'Need a macbook';
        req.priority = 'Medium';
        req.requesterEmail = 'test@example.com';

        Test.startTest();
        List<HelpDeskCreateServiceRequestAction.Result> results = HelpDeskCreateServiceRequestAction.createServiceRequest(
            new List<HelpDeskCreateServiceRequestAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertNotEquals(null, results[0].serviceRequestId);
    }

    @isTest
    static void testCheckTicketStatusAction() {
        // Create an Incident first
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Status = 'New',
            Priority = 'Medium',
            Urgency = 'Medium',
            Impact = 'Medium'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];

        // Create a Service Request
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Test SR Status',
            Status = 'New',
            Priority = 'Medium'
        );
        insert sr;

        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id LIMIT 1];

        HelpDeskCheckTicketStatusAction.Request reqInc = new HelpDeskCheckTicketStatusAction.Request();
        reqInc.ticketNumber = insertedInc.IncidentNumber;

        HelpDeskCheckTicketStatusAction.Request reqSR = new HelpDeskCheckTicketStatusAction.Request();
        reqSR.ticketNumber = insertedSR.Name;

        HelpDeskCheckTicketStatusAction.Request reqNotFound = new HelpDeskCheckTicketStatusAction.Request();
        reqNotFound.ticketNumber = 'INC99999999';

        Test.startTest();
        List<HelpDeskCheckTicketStatusAction.Result> results = HelpDeskCheckTicketStatusAction.checkTicketStatus(
            new List<HelpDeskCheckTicketStatusAction.Request>{ reqInc, reqSR, reqNotFound }
        );
        Test.stopTest();

        System.assertEquals(3, results.size());
        System.assertEquals(true, results[0].found);
        System.assertEquals('Incident', results[0].ticketType);
        System.assertEquals(true, results[1].found);
        System.assertEquals('Service Request', results[1].ticketType);
        System.assertEquals(false, results[2].found);
    }

    @isTest
    static void testUpdateTicketAction() {
        // Create an Incident first
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Status = 'New',
            Priority = 'Medium',
            Urgency = 'Medium',
            Impact = 'Medium'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];

        HelpDeskUpdateTicketAction.Request req = new HelpDeskUpdateTicketAction.Request();
        req.ticketNumber = insertedInc.IncidentNumber;
        req.priority = 'High';
        req.status = 'In Progress';

        Test.startTest();
        List<HelpDeskUpdateTicketAction.Result> results = HelpDeskUpdateTicketAction.updateTicket(
            new List<HelpDeskUpdateTicketAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals('In Progress', results[0].status);
        System.assertEquals('High', results[0].priority);
    }

    @isTest
    static void testGetIncidentDetailsAction() {
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Status = 'New',
            Priority = 'Medium',
            Urgency = 'Medium',
            Impact = 'Medium'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];

        HelpDeskGetIncidentDetailsAction.Request req = new HelpDeskGetIncidentDetailsAction.Request();
        req.ticketNumber = insertedInc.IncidentNumber;

        Test.startTest();
        List<HelpDeskGetIncidentDetailsAction.Result> results = HelpDeskGetIncidentDetailsAction.getIncidentDetails(
            new List<HelpDeskGetIncidentDetailsAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(true, results[0].found);
        System.assertNotEquals(null, results[0].incidentForm);
        System.assertEquals('Test Incident Status', results[0].incidentForm.subject);
    }

    @isTest
    static void testShowIncidentManagementFormAction() {
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Status = 'New',
            Priority = 'Medium',
            Urgency = 'Medium',
            Impact = 'Medium'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];

        HelpDeskIncidentManagementFormWrapper wrapper = new HelpDeskIncidentManagementFormWrapper();
        wrapper.incidentNumber = insertedInc.IncidentNumber;

        HelpDeskShowIncidentManagementFormAction.Request req = new HelpDeskShowIncidentManagementFormAction.Request();
        req.incidentForm = wrapper;

        Test.startTest();
        List<HelpDeskShowIncidentManagementFormAction.Result> results = HelpDeskShowIncidentManagementFormAction.showIncidentForm(
            new List<HelpDeskShowIncidentManagementFormAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].incidentForm);
        System.assertEquals('Test Incident Status', results[0].incidentForm.subject);
    }

    @isTest
    static void testSearchKnowledgeAction() {
        // Create Knowledge Article
        Knowledge__kav art = new Knowledge__kav(
            Title = 'How to reset VPN',
            UrlName = 'How-to-reset-VPN',
            Summary = 'Steps to reset VPN connection.',
            Question__c = 'How to reset VPN?',
            Answer__c = 'Reboot your router.',
            Language = 'en_US'
        );
        insert art;

        // Retrieve published version ID or just query inserted record
        Knowledge__kav insertedArt = [SELECT Id FROM Knowledge__kav WHERE Id = :art.Id LIMIT 1];

        // Mock SOSL Search results
        Id [] fixedSearchResults = new Id[1];
        fixedSearchResults[0] = insertedArt.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        HelpDeskSearchKnowledgeAction.Request req = new HelpDeskSearchKnowledgeAction.Request();
        req.searchQuery = 'VPN';

        Test.startTest();
        List<HelpDeskSearchKnowledgeAction.Result> results = HelpDeskSearchKnowledgeAction.searchKnowledge(
            new List<HelpDeskSearchKnowledgeAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(1, results[0].articles.size());
        System.assertEquals('How to reset VPN', results[0].articles[0].title);
    }

    @isTest
    static void testEscalateTicketAction() {
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Status = 'New',
            Priority = 'Medium',
            Urgency = 'Medium',
            Impact = 'Medium',
            Category = 'Software'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id LIMIT 1];

        HelpDeskEscalateTicketAction.Request req = new HelpDeskEscalateTicketAction.Request();
        req.ticketNumber = insertedInc.IncidentNumber;
        req.escalationReason = 'Critical business impact';

        Test.startTest();
        List<HelpDeskEscalateTicketAction.Result> results = HelpDeskEscalateTicketAction.escalateTicket(
            new List<HelpDeskEscalateTicketAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        
        Incident updatedInc = [SELECT Status, Priority FROM Incident WHERE Id = :inc.Id LIMIT 1];
        System.assertEquals('Escalated', updatedInc.Status);
        System.assertEquals('Critical', updatedInc.Priority);
    }

    @isTest
    static void testIncidentMetadataController() {
        Test.startTest();
        List<HelpDeskIncidentMetadataController.FieldMetadata> meta = HelpDeskIncidentMetadataController.getIncidentFieldsMetadata();
        Test.stopTest();

        System.assertNotEquals(0, meta.size());
    }

    @isTest
    static void testIncidentManagementController() {
        Test.startTest();
        // Create
        HelpDeskIncidentManagementController.IncidentResult createRes = HelpDeskIncidentManagementController.createIncident(
            'Mgmt Subject', 'Mgmt Desc', 'High', 'High', 'High', 'New', 'Software'
        );
        System.assertNotEquals(null, createRes.incidentId);

        // Get By Id
        HelpDeskIncidentManagementFormWrapper details = HelpDeskIncidentManagementController.getIncidentById(createRes.incidentId);
        System.assertEquals('Mgmt Subject', details.subject);

        // Search
        List<HelpDeskIncidentManagementFormWrapper> searchRes = HelpDeskIncidentManagementController.searchIncidents(createRes.incidentNumber);
        System.assertEquals(1, searchRes.size());

        // Update
        HelpDeskIncidentManagementController.IncidentResult updateRes = HelpDeskIncidentManagementController.updateIncident(
            createRes.incidentId, 'Mgmt Subject Updated', 'Mgmt Desc', 'High', 'High', 'High', 'In Progress', 'Software'
        );
        System.assertEquals('In Progress', updateRes.status);
        Test.stopTest();
    }
}
