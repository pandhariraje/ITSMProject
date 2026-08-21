@IsTest
private class ITSMCopilotIncidentActionsTest {

    @IsTest
    static void testCreateIncident() {
        ITSMCopilotCreateIncidentAction.Request req = new ITSMCopilotCreateIncidentAction.Request();
        req.subject = 'Test Printer Issue';
        req.description = 'Printer in hall B is jammed';
        req.category = 'Hardware';
        req.urgency = 'High';
        req.impact = 'High';
        req.status = 'New';

        Test.startTest();
        List<ITSMCopilotCreateIncidentAction.Result> results = ITSMCopilotCreateIncidentAction.createIncident(
            new List<ITSMCopilotCreateIncidentAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Creation should succeed');
        System.assertNotEquals(null, results[0].incidentId, 'Incident ID should not be null');
        System.assertEquals('Critical', results[0].priority, 'Priority should be Critical for High/High');
    }

    @IsTest
    static void testCreateIncidentLwc() {
        Test.startTest();
        ITSMCopilotCreateIncidentAction.Result res = ITSMCopilotCreateIncidentAction.createIncidentLwc(
            'LWC Test Incident',
            'Description via LWC',
            'Software',
            'Medium',
            'Medium',
            'user@example.com',
            'New',
            'Moderate'
        );
        Test.stopTest();

        System.assertEquals(true, res.isSuccess, 'LWC creation should succeed');
        System.assertEquals('Moderate', res.priority, 'Priority should match input');
    }

    @IsTest
    static void testUpdateIncident() {
        ITSMCopilotCreateIncidentAction.Result createRes = ITSMCopilotCreateIncidentAction.createIncidentLwc(
            'Initial Subject',
            'Initial Description',
            'Software',
            'Low',
            'Low',
            '',
            'New',
            'Low'
        );

        ITSMCopilotUpdateIncidentAction.Request updateReq = new ITSMCopilotUpdateIncidentAction.Request();
        updateReq.incidentId = createRes.incidentId;
        updateReq.subject = 'Updated Subject via Test';
        updateReq.status = 'In Process';
        updateReq.priority = 'High';

        Test.startTest();
        List<ITSMCopilotUpdateIncidentAction.Result> results = ITSMCopilotUpdateIncidentAction.updateIncident(
            new List<ITSMCopilotUpdateIncidentAction.Request>{ updateReq }
        );
        ITSMCopilotUpdateIncidentAction.Result detailsRes = ITSMCopilotUpdateIncidentAction.getIncidentDetailsLwc(createRes.incidentId);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals('Updated Subject via Test', results[0].subject);
        System.assertEquals('In Process', results[0].status);
        System.assertEquals(true, detailsRes.isSuccess);
    }
}