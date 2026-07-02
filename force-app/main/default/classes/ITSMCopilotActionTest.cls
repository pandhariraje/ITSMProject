@isTest
private class ITSMCopilotActionTest {

    @isTest
    static void testShowIncidentFormAction() {
        ITSMCopilotIncidentFormWrapper wrapper = new ITSMCopilotIncidentFormWrapper();
        wrapper.subject = 'Test Incident';
        wrapper.description = 'Test Description';
        wrapper.urgency = 'Medium';
        wrapper.impact = 'Medium';
        wrapper.priority = 'Moderate';
        wrapper.status = 'New';

        ITSMCopilotShowIncidentFormAction.Request req = new ITSMCopilotShowIncidentFormAction.Request();
        req.incidentForm = wrapper;

        Test.startTest();
        List<ITSMCopilotShowIncidentFormAction.Result> results = ITSMCopilotShowIncidentFormAction.showIncidentForm(new List<ITSMCopilotShowIncidentFormAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assertEquals('Test Incident', results[0].incidentForm.subject, 'Subject should match');
    }

    @isTest
    static void testCreateIncidentAction() {
        ITSMCopilotIncidentFormWrapper wrapper = new ITSMCopilotIncidentFormWrapper();
        wrapper.subject = 'Laptop display flickering';
        wrapper.description = 'Screen blinks off and on randomly';
        wrapper.urgency = 'High';
        wrapper.impact = 'Medium';
        wrapper.priority = 'High';
        wrapper.status = 'New';

        ITSMCopilotCreateIncidentAction.Request req = new ITSMCopilotCreateIncidentAction.Request();
        req.incidentData = wrapper;

        Test.startTest();
        List<ITSMCopilotCreateIncidentAction.Result> results = ITSMCopilotCreateIncidentAction.createIncident(new List<ITSMCopilotCreateIncidentAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assert(results[0].isSuccess, 'Expected creation to succeed');
        System.assertNotEquals(null, results[0].incidentId, 'Incident ID should not be null');
        System.assertEquals('Laptop display flickering', results[0].subject, 'Subject should match');
    }
}
