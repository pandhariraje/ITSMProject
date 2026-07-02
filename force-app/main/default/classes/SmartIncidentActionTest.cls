@isTest
private class SmartIncidentActionTest {

    @isTest
    static void testSmartIncidentControllerSuccess() {
        Test.startTest();
        SmartIncidentFormWrapper res = SmartIncidentController.createIncident(
            'Test Network Issue',
            'Cannot access internal portal',
            'New',
            'High',
            'High',
            'Medium',
            'Software'
        );
        Test.stopTest();

        System.assert(res.isSuccess, 'Expected incident creation to succeed');
        System.assertNotEquals(null, res.incidentId, 'Incident ID should be returned');
        System.assertNotEquals(null, res.incidentNumber, 'Incident Number should be returned');
        System.assertEquals('Test Network Issue', res.subject, 'Subject should match');
    }

    @isTest
    static void testSmartIncidentCreateAction() {
        SmartIncidentCreateAction.Request req = new SmartIncidentCreateAction.Request();
        req.subject = 'VPN Error';
        req.description = 'VPN failed to connect';
        req.status = 'New';
        req.priority = 'Moderate';
        req.urgency = 'Medium';
        req.impact = 'Medium';

        Test.startTest();
        List<SmartIncidentCreateAction.Result> results = SmartIncidentCreateAction.createIncident(
            new List<SmartIncidentCreateAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assert(results[0].incidentForm.isSuccess, 'Expected success flag true');
    }

    @isTest
    static void testSmartIncidentShowFormAction() {
        SmartIncidentShowFormAction.Request req = new SmartIncidentShowFormAction.Request();

        Test.startTest();
        List<SmartIncidentShowFormAction.Result> results = SmartIncidentShowFormAction.showForm(
            new List<SmartIncidentShowFormAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assertNotEquals(null, results[0].incidentForm, 'Form wrapper should not be null');
    }

    @isTest
    static void testSmartIncidentShowFormActionSubmit() {
        SmartIncidentShowFormAction.Request req = new SmartIncidentShowFormAction.Request();
        req.incidentForm = new SmartIncidentFormWrapper();
        req.incidentForm.subject = 'Test Show Form Submit';
        req.incidentForm.description = 'Testing DML via Action class';
        req.incidentForm.status = 'New';
        req.incidentForm.priority = 'Moderate';
        req.incidentForm.urgency = 'Medium';
        req.incidentForm.impact = 'Medium';
        req.incidentForm.category = 'Software';
        req.incidentForm.isSuccess = true;

        Test.startTest();
        List<SmartIncidentShowFormAction.Result> results = SmartIncidentShowFormAction.showForm(
            new List<SmartIncidentShowFormAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Expected 1 result');
        System.assert(results[0].incidentForm.isSuccess, 'Expected success flag true');
        System.assertNotEquals(null, results[0].incidentForm.incidentId, 'Incident ID should be generated');
        System.assertNotEquals(null, results[0].incidentForm.incidentNumber, 'Incident Number should be populated');
    }
}
