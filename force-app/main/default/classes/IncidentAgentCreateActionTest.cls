@isTest
public class IncidentAgentCreateActionTest {

    @isTest
    static void testCreateIncidentAndLinkRelatedItems() {
        // Create a test Account
        Account testAcc = new Account(Name = 'Test Incident Account');
        insert testAcc;

        // Create a test User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testincidentuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testincidentuser' + DateTime.now().getTime() + '@example.com'
        );
        insert testUser;

        // Create an Asset assigned to the test User and Account
        Asset testAsset = new Asset(
            Name = 'Test Laptop',
            OwnerId = testUser.Id,
            AccountId = testAcc.Id,
            Status = 'Purchased'
        );
        insert testAsset;

        // Create a Configuration Item linked to the Asset
        ConfigurationItem testCI = new ConfigurationItem(
            Name = 'Test CI Laptop',
            AssetId = testAsset.Id,
            ConfigurationItem = 'EXT-CI-123'
        );
        insert testCI;

        // Prepare Action Request
        IncidentAgentCreateAction.Request req = new IncidentAgentCreateAction.Request();
        req.subject = 'VPN Issue';
        req.description = 'Cannot connect to VPN from home';
        req.category = 'Network';
        req.urgency = 'High';
        req.impact = 'Medium';
        req.requesterEmail = 'testincidentuser@example.com';

        Test.startTest();
        List<IncidentAgentCreateAction.Result> results = IncidentAgentCreateAction.createIncident(
            new List<IncidentAgentCreateAction.Request>{ req }
        );
        Test.stopTest();

        // Assert results
        System.assertEquals(1, results.size(), 'Should return one result');
        IncidentAgentCreateAction.Result res = results[0];
        System.assertEquals(true, res.isSuccess, 'Action should succeed: ' + res.errorMessage);
        System.assertNotEquals(null, res.incidentId, 'Incident Id should not be null');
        System.assertNotEquals(null, res.incidentNumber, 'Incident number should be returned');
        System.assertEquals('High', res.priority, 'Priority should be High based on High urgency and Medium impact');

        // Verify IncidentRelatedItem was created
        List<IncidentRelatedItem> iris = [
            SELECT Id, IncidentId, AssetId 
            FROM IncidentRelatedItem 
            WHERE IncidentId = :res.incidentId
        ];
        System.assertEquals(1, iris.size(), 'Should create exactly one IncidentRelatedItem');
        System.assertEquals(testAsset.Id, iris[0].AssetId, 'Asset ID should match');

        // Verify IncidentConfigurationItem was created
        List<IncidentConfigurationItem> icis = [
            SELECT Id, IncidentId, ConfigurationItemId 
            FROM IncidentConfigurationItem 
            WHERE IncidentId = :res.incidentId
        ];
        System.assertEquals(1, icis.size(), 'Should create exactly one IncidentConfigurationItem');
        System.assertEquals(testCI.Id, icis[0].ConfigurationItemId, 'Configuration Item ID should match');
    }
}