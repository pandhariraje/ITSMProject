@isTest
public class IncidentManagementTest {

    @isTest
    static void testGetIncidentFieldsMetadata() {
        Test.startTest();
        List<IncidentMetadataController.FieldMetadata> metadata = IncidentMetadataController.getIncidentFieldsMetadata();
        Test.stopTest();

        System.assertNotEquals(null, metadata, 'Metadata list should not be null');
        System.assert(metadata.size() > 0, 'Metadata list should contain items');
        
        Boolean foundSubject = false;
        Boolean foundPicklistOption = false;
        for (IncidentMetadataController.FieldMetadata fm : metadata) {
            if (fm.fieldName == 'Subject') {
                foundSubject = true;
                System.assertEquals('string', fm.type, 'Subject type should be string');
            }
            if (fm.type == 'picklist' && fm.picklistOptions.size() > 0) {
                foundPicklistOption = true;
                System.assertNotEquals(null, fm.picklistOptions[0].isDefault, 'isDefault should be populated');
            }
        }
        System.assert(foundSubject, 'Subject metadata should be retrieved');
        System.assert(foundPicklistOption, 'Picklist metadata should be retrieved');
    }

    @isTest
    static void testCreateIncidentSuccess() {
        Test.startTest();
        IncidentManagementController.IncidentResult res = IncidentManagementController.createIncident(
            'Test Subject',
            'Test Description',
            'Medium',
            'Medium',
            'Low',
            'New',
            'Software'
        );
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result should not be null');
        System.assertNotEquals(null, res.incidentId, 'Incident Id should not be null');
        System.assertNotEquals(null, res.incidentNumber, 'Incident Number should not be null');
        System.assertEquals('New', res.status, 'Status should match');
        System.assertEquals('Low', res.priority, 'Priority should match');

        Incident inserted = [SELECT Subject, Description, Category FROM Incident WHERE Id = :res.incidentId];
        System.assertEquals('Test Subject', inserted.Subject);
        System.assertEquals('Test Description', inserted.Description);
        System.assertEquals('Software', inserted.Category);
    }

    @isTest
    static void testCreateIncidentFailure() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            // Pass null to Subject to trigger exception if required, or cause DML failure
            IncidentManagementController.createIncident(
                null,
                null,
                'Medium',
                'Medium',
                'Low',
                'New',
                'Software'
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
    }

    @isTest
    static void testShowIncidentForm() {
        IncidentManagementFormWrapper wrapper = new IncidentManagementFormWrapper();
        wrapper.subject = 'Test Subject';
        wrapper.description = 'Test Description';

        ShowIncidentManagementFormAction.Request req = new ShowIncidentManagementFormAction.Request();
        req.incidentForm = wrapper;

        Test.startTest();
        List<ShowIncidentManagementFormAction.Result> results = ShowIncidentManagementFormAction.showIncidentForm(
            new List<ShowIncidentManagementFormAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Results size should be 1');
        System.assertEquals('Test Subject', results[0].incidentForm.subject, 'Subject should match');
    }

    @isTest
    static void testGetIncidentById() {
        Incident inc = new Incident(
            Subject = 'Test Incident',
            Status = 'New',
            Urgency = 'Medium',
            Impact = 'Medium',
            Priority = 'Low'
        );
        insert inc;

        Test.startTest();
        IncidentManagementFormWrapper wrapper = IncidentManagementController.getIncidentById(inc.Id);
        Test.stopTest();

        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals(inc.Id, wrapper.incidentId, 'Incident Id should match');
        System.assertEquals('Test Incident', wrapper.subject, 'Subject should match');
    }

    @isTest
    static void testGetIncidentByIdFailure() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            IncidentManagementController.getIncidentById(null);
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown for invalid Id');
    }

    @isTest
    static void testSearchIncidents() {
        Incident inc = new Incident(
            Subject = 'Searchable Subject',
            Status = 'New',
            Urgency = 'Medium',
            Impact = 'Medium',
            Priority = 'Low'
        );
        insert inc;

        Test.startTest();
        List<IncidentManagementFormWrapper> results = IncidentManagementController.searchIncidents('Searchable');
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results list should not be null');
        System.assert(results.size() > 0, 'Results list should contain items');
        System.assertEquals('Searchable Subject', results[0].subject, 'Subject should match');
    }

    @isTest
    static void testUpdateIncidentSuccess() {
        Incident inc = new Incident(
            Subject = 'Original Subject',
            Status = 'New',
            Urgency = 'Medium',
            Impact = 'Medium',
            Priority = 'Low'
        );
        insert inc;

        Test.startTest();
        IncidentManagementController.IncidentResult res = IncidentManagementController.updateIncident(
            inc.Id,
            'Updated Subject',
            'Updated Description',
            'High',
            'High',
            'Critical',
            'Open',
            'Software'
        );
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result should not be null');
        System.assertEquals(inc.Id, res.incidentId, 'Id should match');
        System.assertEquals('Open', res.status, 'Status should match');
        System.assertEquals('Critical', res.priority, 'Priority should match');

        Incident updated = [SELECT Subject, Description, Category FROM Incident WHERE Id = :inc.Id];
        System.assertEquals('Updated Subject', updated.Subject);
        System.assertEquals('Updated Description', updated.Description);
        System.assertEquals('Software', updated.Category);
    }

    @isTest
    static void testUpdateIncidentFailure() {
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            IncidentManagementController.updateIncident(
                null,
                'Updated Subject',
                'Updated Description',
                'High',
                'High',
                'Critical',
                'Open',
                'Software'
            );
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Exception should be thrown for invalid Id');
    }

    @isTest
    static void testGetIncidentDetailsActionSuccess() {
        Incident inc = new Incident(
            Subject = 'Action Subject',
            Status = 'New',
            Urgency = 'Medium',
            Impact = 'Medium',
            Priority = 'Low'
        );
        insert inc;

        inc = [SELECT IncidentNumber FROM Incident WHERE Id = :inc.Id];

        GetIncidentDetailsAction.Request req = new GetIncidentDetailsAction.Request();
        req.ticketNumber = inc.IncidentNumber;

        Test.startTest();
        List<GetIncidentDetailsAction.Result> results = GetIncidentDetailsAction.getIncidentDetails(
            new List<GetIncidentDetailsAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Results size should be 1');
        System.assertEquals(true, results[0].isSuccess, 'Should be success');
        System.assertEquals(true, results[0].found, 'Should find the incident');
        System.assertEquals('Action Subject', results[0].incidentForm.subject, 'Subject should match');
    }

    @isTest
    static void testGetIncidentDetailsActionNotFound() {
        GetIncidentDetailsAction.Request req = new GetIncidentDetailsAction.Request();
        req.ticketNumber = 'INC99999999';

        Test.startTest();
        List<GetIncidentDetailsAction.Result> results = GetIncidentDetailsAction.getIncidentDetails(
            new List<GetIncidentDetailsAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Results size should be 1');
        System.assertEquals(true, results[0].isSuccess, 'Should be success');
        System.assertEquals(false, results[0].found, 'Should not find the incident');
    }
}
