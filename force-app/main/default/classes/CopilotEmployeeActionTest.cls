@isTest
public class CopilotEmployeeActionTest {

    @isTest
    static void testCreateIncident() {
        CopilotEmployeeWrapper.IncidentFormInput input = new CopilotEmployeeWrapper.IncidentFormInput();
        input.subject = 'Laptop screen issue';
        input.description = 'Flickering display';
        input.category = 'Hardware';
        input.urgency = 'Medium';
        input.impact = 'Medium';
        input.status = 'New';

        CopilotEmployeeCreateIncident.Request req = new CopilotEmployeeCreateIncident.Request();
        req.incidentData = input;

        Test.startTest();
        List<CopilotEmployeeCreateIncident.Result> results = CopilotEmployeeCreateIncident.createIncident(
            new List<CopilotEmployeeCreateIncident.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertNotEquals(null, results[0].incidentId);
        System.assertNotEquals(null, results[0].incidentNumber);
    }

    @isTest
    static void testCreateIncidentFail() {
        CopilotEmployeeCreateIncident.Request req = new CopilotEmployeeCreateIncident.Request();
        req.incidentData = null;

        Test.startTest();
        List<CopilotEmployeeCreateIncident.Result> results = CopilotEmployeeCreateIncident.createIncident(
            new List<CopilotEmployeeCreateIncident.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
    }

    @isTest
    static void testCreateServiceRequest() {
        CopilotEmployeeCreateServiceRequest.Request req = new CopilotEmployeeCreateServiceRequest.Request();
        req.subject = 'VPN access request';
        req.description = 'Need access for remote work';
        req.priority = 'Medium';

        Test.startTest();
        List<CopilotEmployeeCreateServiceRequest.Result> results = CopilotEmployeeCreateServiceRequest.createServiceRequest(
            new List<CopilotEmployeeCreateServiceRequest.Request>{req}
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertNotEquals(null, results[0].serviceRequestId);
        System.assertNotEquals(null, results[0].serviceRequestNumber);
    }

    @isTest
    static void testSearchIncident() {
        // Insert test Incident
        Incident inc = new Incident(
            Subject = 'Search Incident',
            Description = 'Search incident description',
            Status = 'New',
            Priority = 'Medium'
        );
        insert inc;
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        // Insert test ServiceRequest
        ServiceRequest sr = new ServiceRequest(
            Subject = 'Search SR',
            Description = 'Search SR description',
            Status = 'New',
            Priority = 'Medium'
        );
        insert sr;
        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotEmployeeSearchIncident.Request req1 = new CopilotEmployeeSearchIncident.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;

        CopilotEmployeeSearchIncident.Request req2 = new CopilotEmployeeSearchIncident.Request();
        req2.ticketNumber = insertedSR.Name;

        CopilotEmployeeSearchIncident.Request req3 = new CopilotEmployeeSearchIncident.Request();
        req3.ticketNumber = 'NON_EXISTENT';

        CopilotEmployeeSearchIncident.Request req4 = new CopilotEmployeeSearchIncident.Request();
        req4.ticketNumber = '';

        Test.startTest();
        List<CopilotEmployeeSearchIncident.Result> results = CopilotEmployeeSearchIncident.checkTicketStatus(
            new List<CopilotEmployeeSearchIncident.Request>{req1, req2, req3, req4}
        );
        Test.stopTest();

        System.assertEquals(4, results.size());
        System.assertEquals(true, results[0].found);
        System.assertEquals('Incident', results[0].ticketType);

        System.assertEquals(true, results[1].found);
        System.assertEquals('Service Request', results[1].ticketType);

        System.assertEquals(false, results[2].found);
        System.assertEquals(false, results[3].isSuccess);
    }

    @isTest
    static void testUpdateIncident() {
        Incident inc = new Incident(
            Subject = 'Update Incident',
            Description = 'Update desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert inc;
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        ServiceRequest sr = new ServiceRequest(
            Subject = 'Update SR',
            Description = 'Update SR desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert sr;
        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotEmployeeUpdateIncident.Request req1 = new CopilotEmployeeUpdateIncident.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;
        req1.status = 'In Progress';
        req1.priority = 'High';

        CopilotEmployeeUpdateIncident.Request req2 = new CopilotEmployeeUpdateIncident.Request();
        req2.ticketNumber = insertedSR.Name;
        req2.status = 'In Progress';
        req2.priority = 'High';

        CopilotEmployeeUpdateIncident.Request req3 = new CopilotEmployeeUpdateIncident.Request();
        req3.ticketNumber = 'NON_EXISTENT';

        CopilotEmployeeUpdateIncident.Request req4 = new CopilotEmployeeUpdateIncident.Request();
        req4.ticketNumber = '';

        Test.startTest();
        List<CopilotEmployeeUpdateIncident.Result> results = CopilotEmployeeUpdateIncident.updateTicket(
            new List<CopilotEmployeeUpdateIncident.Request>{req1, req2, req3, req4}
        );
        Test.stopTest();

        System.assertEquals(4, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(true, results[1].isSuccess);
        System.assertEquals(false, results[2].isSuccess);
        System.assertEquals(false, results[3].isSuccess);
    }

    @isTest
    static void testCloseIncident() {
        Incident inc = new Incident(
            Subject = 'Close Incident',
            Description = 'Close desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert inc;
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        ServiceRequest sr = new ServiceRequest(
            Subject = 'Close SR',
            Description = 'Close SR desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert sr;
        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotEmployeeCloseIncident.Request req1 = new CopilotEmployeeCloseIncident.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;
        req1.resolutionNotes = 'Resolved issue';

        CopilotEmployeeCloseIncident.Request req2 = new CopilotEmployeeCloseIncident.Request();
        req2.ticketNumber = insertedSR.Name;
        req2.resolutionNotes = 'Resolved request';

        CopilotEmployeeCloseIncident.Request req3 = new CopilotEmployeeCloseIncident.Request();
        req3.ticketNumber = 'NON_EXISTENT';

        CopilotEmployeeCloseIncident.Request req4 = new CopilotEmployeeCloseIncident.Request();
        req4.ticketNumber = '';

        Test.startTest();
        List<CopilotEmployeeCloseIncident.Result> results = CopilotEmployeeCloseIncident.closeTicket(
            new List<CopilotEmployeeCloseIncident.Request>{req1, req2, req3, req4}
        );
        Test.stopTest();

        System.assertEquals(4, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(true, results[1].isSuccess);
        System.assertEquals(false, results[2].isSuccess);
        System.assertEquals(false, results[3].isSuccess);
    }

    @isTest
    static void testSearchKnowledge() {
        CopilotEmployeeSearchKnowledge.Request req1 = new CopilotEmployeeSearchKnowledge.Request();
        req1.searchQuery = 'VPN';

        CopilotEmployeeSearchKnowledge.Request req2 = new CopilotEmployeeSearchKnowledge.Request();
        req2.searchQuery = '';

        // Mock Knowledge record ID
        Id mockId = Id.valueOf('01I000000000000');
        Test.setFixedSearchResults(new List<Id>{mockId});

        Test.startTest();
        List<CopilotEmployeeSearchKnowledge.Result> results = CopilotEmployeeSearchKnowledge.searchKnowledge(
            new List<CopilotEmployeeSearchKnowledge.Request>{req1, req2}
        );
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals(false, results[1].isSuccess);
    }

    @isTest
    static void testEscalate() {
        Incident inc = new Incident(
            Subject = 'Escalate Incident',
            Description = 'Escalate desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert inc;
        Incident insertedInc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        ServiceRequest sr = new ServiceRequest(
            Subject = 'Escalate SR',
            Description = 'Escalate SR desc',
            Status = 'New',
            Priority = 'Low'
        );
        insert sr;
        ServiceRequest insertedSR = [SELECT Name FROM ServiceRequest WHERE Id = :sr.Id];

        CopilotEmployeeEscalate.Request req1 = new CopilotEmployeeEscalate.Request();
        req1.ticketNumber = insertedInc.IncidentNumber;
        req1.escalationReason = 'Critical laptop boot failure';

        CopilotEmployeeEscalate.Request req2 = new CopilotEmployeeEscalate.Request();
        req2.ticketNumber = insertedSR.Name;
        req2.escalationReason = 'Need immediate access';

        CopilotEmployeeEscalate.Request req3 = new CopilotEmployeeEscalate.Request();
        req3.ticketNumber = 'NON_EXISTENT';

        CopilotEmployeeEscalate.Request req4 = new CopilotEmployeeEscalate.Request();
        req4.ticketNumber = '';

        Test.startTest();
        List<CopilotEmployeeEscalate.Result> results = CopilotEmployeeEscalate.escalateTicket(
            new List<CopilotEmployeeEscalate.Request>{req1, req2, req3, req4}
        );
        Test.stopTest();

        System.assertEquals(4, results.size());
        System.assertEquals(true, results[0].isSuccess, 'Failure in req1: ' + results[0].errorMessage);
        System.assertEquals(true, results[1].isSuccess, 'Failure in req2: ' + results[1].errorMessage);
        System.assertEquals(false, results[2].isSuccess);
        System.assertEquals(false, results[3].isSuccess);
    }
}