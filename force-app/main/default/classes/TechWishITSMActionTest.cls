@isTest
public class TechWishITSMActionTest {

    @isTest
    static void testCreateIncidentAction() {
        // Test 1: Auto-categorize VPN issue as Network and Critical priority
        CreateIncidentAction.Request req1 = new CreateIncidentAction.Request();
        req1.subject = 'VPN issues at home';
        req1.description = 'The VPN connection is completely down and blocked, cannot work.';
        req1.requesterEmail = 'nonexistent.user@techwish.com'; // Should default to current user

        // Test 2: Auto-categorize printer issue as Hardware and Low priority
        CreateIncidentAction.Request req2 = new CreateIncidentAction.Request();
        req2.subject = 'Printer paper jam';
        req2.description = 'Printer on 2nd floor has a minor paper jam. Please reset.';
        req2.category = 'Hardware'; // override category
        req2.priority = 'Low'; // override priority

        // Create an active user to test requester email resolution
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        String uniqueName = 'itsmtestuser' + DateTime.now().getTime() + '@test.com';
        User testUser = new User(
            Alias = 'itsmt',
            Email = 'testitsmuser@techwish.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueName
        );
        insert testUser;

        CreateIncidentAction.Request req3 = new CreateIncidentAction.Request();
        req3.subject = 'Software installation error';
        req3.description = 'Received an error when installing Slack.';
        req3.requesterEmail = 'testitsmuser@techwish.com';

        Test.startTest();
        List<CreateIncidentAction.Result> results = CreateIncidentAction.createIncident(
            new List<CreateIncidentAction.Request>{req1, req2, req3}
        );
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 results');
        
        // Assert req1 (VPN / Down -> Network / Critical)
        System.assert(results[0].isSuccess, 'Req1 should succeed');
        System.assertNotEquals(null, results[0].incidentId, 'Req1 incidentId should not be null');
        System.assertNotEquals(null, results[0].incidentNumber, 'Req1 incidentNumber should not be null');
        Incident inc1 = [SELECT Category, Priority, ReportedById, OwnerId, AssignedGroupId FROM Incident WHERE Id = :results[0].incidentId];
        System.assertEquals('Network', inc1.Category, 'Category should be Network');
        System.assertEquals('Critical', inc1.Priority, 'Priority should be Critical');
        Id netMajorQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Network_Major_Incident_Queue' LIMIT 1].Id;
        System.assertEquals(netMajorQueueId, inc1.OwnerId, 'Owner should be Network Major Queue');
        System.assertEquals(netMajorQueueId, inc1.AssignedGroupId, 'Assigned Group should be Network Major Queue');

        // Assert req2 (Printer / Low override)
        System.assert(results[1].isSuccess, 'Req2 should succeed');
        Incident inc2 = [SELECT Category, Priority, OwnerId, AssignedGroupId FROM Incident WHERE Id = :results[1].incidentId];
        System.assertEquals('Hardware', inc2.Category, 'Category should be Hardware override');
        System.assertEquals('Low', inc2.Priority, 'Priority should be Low override');
        Id hwNormalQueueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Hardware_Normal_Incident_Queue' LIMIT 1].Id;
        System.assertEquals(hwNormalQueueId, inc2.OwnerId, 'Owner should be Hardware Normal Queue');
        System.assertEquals(hwNormalQueueId, inc2.AssignedGroupId, 'Assigned Group should be Hardware Normal Queue');

        // Assert req3 (Requester Email resolution)
        System.assert(results[2].isSuccess, 'Req3 should succeed');
        Incident inc3 = [SELECT Category, Priority, ReportedById FROM Incident WHERE Id = :results[2].incidentId];
        System.assertEquals(testUser.Id, inc3.ReportedById, 'ReportedById should match the test user');
    }

    @isTest
    static void testCreateIncidentActionWithContact() {
        // Create an Account (Industry is required by AccountBeforeInsertIndustryRequired trigger)
        Account acc = new Account(Name = 'Test Tech Account', Industry = 'Technology');
        insert acc;

        // Create a Contact
        Contact c = new Contact(
            LastName = 'Biradar',
            Email = 'pandharirb@gmail.com',
            AccountId = acc.Id
        );
        insert c;

        CreateIncidentAction.Request req = new CreateIncidentAction.Request();
        req.subject = 'Printer not working';
        req.description = 'Hardware issue with the printer button.';
        req.requesterEmail = 'pandharirb@gmail.com';

        Test.startTest();
        List<CreateIncidentAction.Result> results = CreateIncidentAction.createIncident(
            new List<CreateIncidentAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 result');
        System.assert(results[0].isSuccess, 'Should succeed');
        System.assertNotEquals(null, results[0].incidentId, 'Incident ID should not be null');

        Incident inc = [SELECT Category, Priority, ReportedById FROM Incident WHERE Id = :results[0].incidentId];
        System.assertEquals('Hardware', inc.Category, 'Category should be Hardware');
        System.assertEquals(acc.Id, inc.ReportedById, 'ReportedById should match the Contact\'s Account ID');
    }

    @isTest
    static void testCreateServiceRequestAction() {
        CreateServiceRequestAction.Request req = new CreateServiceRequestAction.Request();
        req.subject = 'Laptop Request';
        req.description = 'New developer laptop request with 32GB RAM.';
        req.status = 'New';

        Test.startTest();
        List<CreateServiceRequestAction.Result> results = CreateServiceRequestAction.createServiceRequest(
            new List<CreateServiceRequestAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return 1 result');
        System.assert(results[0].isSuccess, 'Service request creation should succeed');
        System.assertNotEquals(null, results[0].serviceRequestId, 'serviceRequestId should not be null');
        System.assertNotEquals(null, results[0].serviceRequestNumber, 'serviceRequestNumber should not be null');

        ServiceRequest sr = [SELECT Subject, Description, Status FROM ServiceRequest WHERE Id = :results[0].serviceRequestId];
        System.assertEquals('Laptop Request', sr.Subject);
        System.assertEquals('New developer laptop request with 32GB RAM.', sr.Description);
        System.assertEquals('New', sr.Status);
    }

    @isTest
    static void testCheckTicketStatusAction() {
        // Create an incident
        Incident inc = new Incident(
            Subject = 'Test Incident Status',
            Description = 'Checking ticket status',
            Status = 'New',
            Priority = 'Medium'
        );
        insert inc;
        
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        // Create a service request
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Test SR Status',
            Description = 'Checking service request status',
            Status = 'Submitted'
        );
        insert sr;

        ServiceRequest insertedSr = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CheckTicketStatusAction.Request req1 = new CheckTicketStatusAction.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;

        CheckTicketStatusAction.Request req2 = new CheckTicketStatusAction.Request();
        req2.ticketNumber = insertedSr.Name;

        CheckTicketStatusAction.Request req3 = new CheckTicketStatusAction.Request();
        req3.ticketNumber = 'INC-INVALID-999';

        Test.startTest();
        List<CheckTicketStatusAction.Result> results = CheckTicketStatusAction.checkTicketStatus(
            new List<CheckTicketStatusAction.Request>{req1, req2, req3}
        );
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should return 3 status results');
        
        // Assert incident status
        System.assert(results[0].isSuccess);
        System.assert(results[0].found);
        System.assertEquals('Incident', results[0].ticketType);
        System.assertEquals(inc.Id, results[0].ticketId);
        System.assertEquals('New', results[0].status);
        System.assertEquals('Medium', results[0].priority);

        // Assert service request status
        System.assert(results[1].isSuccess);
        System.assert(results[1].found);
        System.assertEquals('Service Request', results[1].ticketType);
        System.assertEquals(sr.Id, results[1].ticketId);
        System.assertEquals('Submitted', results[1].status);

        // Assert invalid ticket
        System.assert(results[2].isSuccess);
        System.assert(!results[2].found);
    }

    @isTest
    static void testSearchKnowledgeAction() {
        SearchKnowledgeAction.Request req = new SearchKnowledgeAction.Request();
        req.searchQuery = 'VPN connection';

        // Setup mock SOSL search results
        Id mockArticleId = getFakeId(Knowledge__kav.SObjectType);
        
        // Note: For custom fields on Knowledge__kav, we can set up search results or mock it.
        // Let's create an actual Knowledge__kav record in the test database if possible, or just set search results
        List<Id> fixedSearchResults = new List<Id>{mockArticleId};
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        List<SearchKnowledgeAction.Result> results = SearchKnowledgeAction.searchKnowledge(
            new List<SearchKnowledgeAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
    }

    private static Id getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(sot.getDescribe().getKeyPrefix());
        return (Id)(result + '000000000001');
    }

    @isTest
    static void testEscalateIncidentAction() {
        // Create an Incident
        Incident inc = new Incident(
            Subject = 'Critical Outage',
            Description = 'Network connectivity is down in Office A',
            Category = 'Network',
            Status = 'New',
            Priority = 'Medium'
        );
        insert inc;

        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        EscalateIncidentAction.Request req = new EscalateIncidentAction.Request();
        req.ticketNumber = insertedInc.IncidentNumber;
        req.escalationReason = 'Severe outage affecting multiple users.';

        Test.startTest();
        List<EscalateIncidentAction.Result> results = EscalateIncidentAction.escalateIncident(
            new List<EscalateIncidentAction.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess);
        System.assertNotEquals(null, results[0].successMessage);

        Incident updatedInc = [SELECT Status, Priority, OwnerId, AssignedGroupId FROM Incident WHERE Id = :inc.Id];
        System.assertEquals('Escalated', updatedInc.Status);
        System.assertEquals('Critical', updatedInc.Priority);
        System.assertEquals(updatedInc.OwnerId, updatedInc.AssignedGroupId);

        // Verify task creation
        List<Task> tasks = [SELECT Subject, Description, Priority, Status FROM Task WHERE WhatId = :inc.Id];
        System.assertEquals(1, tasks.size(), 'One SLA Task should be created');
        System.assertEquals('SLA Escalation Alert for Incident ' + insertedInc.IncidentNumber, tasks[0].Subject);
        System.assert(tasks[0].Description.contains('Severe outage affecting multiple users.'));
        System.assertEquals('High', tasks[0].Priority);
    }

    @isTest
    static void testListUserIncidentsAction() {
        // Create incidents for current user
        Id currentUserId = UserInfo.getUserId();
        
        List<Incident> testIncidents = new List<Incident>{
            new Incident(Subject = 'Open Incident 1', Status = 'New', ReportedById = currentUserId),
            new Incident(Subject = 'Open Incident 2', Status = 'In Progress', ReportedById = currentUserId),
            new Incident(Subject = 'Closed Incident 1', Status = 'Closed', ReportedById = currentUserId, ResolutionSummary = 'Fixed it', Closure_Notes__c = 'Fixed it'),
            new Incident(Subject = 'Resolved Incident 1', Status = 'Resolved', ReportedById = currentUserId, ResolutionSummary = 'Solved it', Closure_Notes__c = 'Solved it')
        };
        insert testIncidents;

        // Test 1: No filter (should return all 4)
        ListUserIncidentsAction.Request reqAll = new ListUserIncidentsAction.Request();
        reqAll.statusFilter = null;

        // Test 2: 'Open' filter (should return 2 open incidents)
        ListUserIncidentsAction.Request reqOpen = new ListUserIncidentsAction.Request();
        reqOpen.statusFilter = 'Open';

        // Test 3: 'Closed' filter (should return 2 closed/resolved incidents)
        ListUserIncidentsAction.Request reqClosed = new ListUserIncidentsAction.Request();
        reqClosed.statusFilter = 'Closed';

        // Test 4: Specific status 'New' (should return 1 incident)
        ListUserIncidentsAction.Request reqNew = new ListUserIncidentsAction.Request();
        reqNew.statusFilter = 'New';

        Test.startTest();
        List<ListUserIncidentsAction.Result> results = ListUserIncidentsAction.listUserIncidents(
            new List<ListUserIncidentsAction.Request>{reqAll, reqOpen, reqClosed, reqNew}
        );
        Test.stopTest();

        System.assertEquals(4, results.size());
        
        // Assert all filter
        System.assert(results[0].isSuccess);
        System.assertEquals(4, results[0].incidents.size());
        for (ListUserIncidentsAction.IncidentDetails det : results[0].incidents) {
            System.assertNotEquals(null, det.incidentId);
        }

        // Assert open filter (New and In Progress)
        System.assert(results[1].isSuccess);
        System.assertEquals(2, results[1].incidents.size());
        for (ListUserIncidentsAction.IncidentDetails det : results[1].incidents) {
            System.assertNotEquals('Closed', det.status);
            System.assertNotEquals('Resolved', det.status);
        }

        // Assert closed filter (Closed and Resolved)
        System.assert(results[2].isSuccess);
        System.assertEquals(2, results[2].incidents.size());
        for (ListUserIncidentsAction.IncidentDetails det : results[2].incidents) {
            System.assert(det.status == 'Closed' || det.status == 'Resolved');
        }

        // Assert specific status 'New'
        System.assert(results[3].isSuccess);
        System.assertEquals(1, results[3].incidents.size());
        System.assertEquals('New', results[3].incidents[0].status);
    }
}
