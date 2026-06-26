@IsTest
private class CopilotShowIncidentFormActionTest {

    @IsTest
    static void testShowIncidentForm() {
        CopilotShowIncidentFormAction.Request req1 = new CopilotShowIncidentFormAction.Request();
        CopilotIncidentFormWrapper w1 = new CopilotIncidentFormWrapper();
        w1.subject = 'Internet connection is down';
        w1.description = 'The router in room 204 is flashing red.';
        w1.category = 'Network';
        w1.urgency = 'High';
        w1.impact = 'High';
        w1.status = 'New';
        w1.priority = 'Medium';
        req1.incidentForm = w1;

        CopilotShowIncidentFormAction.Request req2 = new CopilotShowIncidentFormAction.Request();
        CopilotIncidentFormWrapper w2 = new CopilotIncidentFormWrapper();
        w2.subject = 'Broken keyboard';
        w2.description = 'Spaceship key is stuck.';
        w2.category = 'Hardware';
        w2.urgency = 'Low';
        w2.impact = 'Low';
        w2.status = null;
        w2.priority = null;
        req2.incidentForm = w2;

        List<CopilotShowIncidentFormAction.Request> requests = new List<CopilotShowIncidentFormAction.Request>{ req1, req2 };

        Test.startTest();
        List<CopilotShowIncidentFormAction.Result> results = CopilotShowIncidentFormAction.showIncidentForm(requests);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return exactly 2 results.');

        // Verify request 1
        System.assertNotEquals(null, results[0].incidentForm, 'incidentForm should not be null');
        System.assertEquals('Internet connection is down', results[0].incidentForm.subject);
        System.assertEquals('The router in room 204 is flashing red.', results[0].incidentForm.description);
        System.assertEquals('Network', results[0].incidentForm.category);
        System.assertEquals('High', results[0].incidentForm.urgency);
        System.assertEquals('High', results[0].incidentForm.impact);
        System.assertEquals('New', results[0].incidentForm.status);
        System.assertEquals('Medium', results[0].incidentForm.priority);

        // Verify request 2
        System.assertNotEquals(null, results[1].incidentForm, 'incidentForm should not be null');
        System.assertEquals('Broken keyboard', results[1].incidentForm.subject);
        System.assertEquals('Spaceship key is stuck.', results[1].incidentForm.description);
        System.assertEquals('Hardware', results[1].incidentForm.category);
        System.assertEquals('Low', results[1].incidentForm.urgency);
        System.assertEquals('Low', results[1].incidentForm.impact);
        System.assertEquals(null, results[1].incidentForm.status, 'Status should be null.');
        System.assertEquals(null, results[1].incidentForm.priority);
    }
}
