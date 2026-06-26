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
        for (IncidentMetadataController.FieldMetadata fm : metadata) {
            if (fm.fieldName == 'Subject') {
                foundSubject = true;
                System.assertEquals('string', fm.type, 'Subject type should be string');
            }
        }
        System.assert(foundSubject, 'Subject metadata should be retrieved');
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
            'New'
        );
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result should not be null');
        System.assertNotEquals(null, res.incidentId, 'Incident Id should not be null');
        System.assertNotEquals(null, res.incidentNumber, 'Incident Number should not be null');
        System.assertEquals('New', res.status, 'Status should match');
        System.assertEquals('Low', res.priority, 'Priority should match');

        Incident inserted = [SELECT Subject, Description FROM Incident WHERE Id = :res.incidentId];
        System.assertEquals('Test Subject', inserted.Subject);
        System.assertEquals('Test Description', inserted.Description);
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
                'New'
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
}
