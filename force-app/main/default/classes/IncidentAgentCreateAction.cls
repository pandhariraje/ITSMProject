public with sharing class IncidentAgentCreateAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=true)
        public String description;

        @InvocableVariable(label='Category' description='Category of the incident (Network, Hardware, Software)' required=true)
        public String category;

        @InvocableVariable(label='Urgency' description='Urgency level (Low, Medium, High)' required=true)
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level (Low, Medium, High)' required=true)
        public String impact;

        @InvocableVariable(label='Requester Email' description='Email of the employee requesting the incident' required=false)
        public String requesterEmail;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the incident was created successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if creation failed')
        public String errorMessage;

        @InvocableVariable(label='Incident ID' description='The ID of the created incident record')
        public Id incidentId;

        @InvocableVariable(label='Incident Number' description='The auto-number reference of the created incident')
        public String incidentNumber;

        @InvocableVariable(label='Priority' description='Automatically determined priority')
        public String priority;

        @InvocableVariable(label='Status' description='Status of the created incident')
        public String status;
    }

    @InvocableMethod(
        label='Incident Agent Create Action'
        description='Creates an Incident and associates the caller\'s assigned Configuration Item and Asset.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            try {
                // 1. Resolve ReportedById
                Id reporterId = UserInfo.getUserId();
                if (String.isNotBlank(req.requesterEmail)) {
                    List<User> users = [SELECT Id FROM User WHERE Email = :req.requesterEmail.trim() AND IsActive = true LIMIT 1];
                    if (!users.isEmpty()) {
                        reporterId = users[0].Id;
                    } else {
                        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :req.requesterEmail.trim() LIMIT 1];
                        if (!contacts.isEmpty()) {
                            reporterId = contacts[0].Id;
                        }
                    }
                }

                // 2. Query caller's assigned Assets
                List<Asset> assignedAssets = [
                    SELECT Id, Name 
                    FROM Asset 
                    WHERE OwnerId = :reporterId OR ContactId = :reporterId
                ];

                // 3. Create and populate Incident record
                Incident inc = new Incident();
                inc.Subject = req.subject;
                inc.Description = req.description;
                inc.Category = req.category;
                inc.Urgency = req.urgency;
                inc.Impact = req.impact;
                inc.Status = 'New';
                inc.ReportedById = reporterId;

                // Priority calculation
                String calculatedPriority = 'Medium';
                if (req.impact == 'High') {
                    if (req.urgency == 'High') calculatedPriority = 'Critical';
                    else if (req.urgency == 'Medium') calculatedPriority = 'High';
                } else if (req.impact == 'Medium') {
                    if (req.urgency == 'High') calculatedPriority = 'High';
                    else if (req.urgency == 'Medium') calculatedPriority = 'Medium';
                    else calculatedPriority = 'Low';
                } else {
                    if (req.urgency == 'High') calculatedPriority = 'Medium';
                    else calculatedPriority = 'Low';
                }
                inc.Priority = calculatedPriority;

                // Strip inaccessible/respect FLS and insert Incident
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Incident>{ inc });
                List<SObject> recordsToInsert = decision.getRecords();
                if (recordsToInsert.isEmpty()) {
                    res.isSuccess = false;
                    res.errorMessage = 'You do not have permission to create Incident records.';
                    results.add(res);
                    continue;
                }
                insert recordsToInsert;
                Incident insertedInc = (Incident) recordsToInsert[0];

                // Query Incident details to return auto-number
                Incident detailInc = [SELECT IncidentNumber, Status, Priority FROM Incident WHERE Id = :insertedInc.Id LIMIT 1];

                // 4. Create relationships if assets exist
                if (!assignedAssets.isEmpty()) {
                    Set<Id> assetIds = new Set<Id>();
                    for (Asset ast : assignedAssets) {
                        assetIds.add(ast.Id);
                    }

                    // Query ConfigurationItems linked to these Assets
                    List<ConfigurationItem> configItems = [
                        SELECT Id, AssetId 
                        FROM ConfigurationItem 
                        WHERE AssetId IN :assetIds
                    ];

                    List<IncidentRelatedItem> irisToInsert = new List<IncidentRelatedItem>();
                    for (Asset ast : assignedAssets) {
                        IncidentRelatedItem iri = new IncidentRelatedItem();
                        iri.IncidentId = insertedInc.Id;
                        iri.AssetId = ast.Id;
                        irisToInsert.add(iri);
                    }

                    List<IncidentConfigurationItem> icisToInsert = new List<IncidentConfigurationItem>();
                    for (ConfigurationItem ci : configItems) {
                        IncidentConfigurationItem ici = new IncidentConfigurationItem();
                        ici.IncidentId = insertedInc.Id;
                        ici.ConfigurationItemId = ci.Id;
                        ici.RelationshipType = 'Impacted';
                        icisToInsert.add(ici);
                    }

                    if (!irisToInsert.isEmpty()) {
                        SObjectAccessDecision irDecision = Security.stripInaccessible(AccessType.CREATABLE, irisToInsert);
                        insert irDecision.getRecords();
                    }
                    if (!icisToInsert.isEmpty()) {
                        SObjectAccessDecision iciDecision = Security.stripInaccessible(AccessType.CREATABLE, icisToInsert);
                        insert iciDecision.getRecords();
                    }
                }

                res.isSuccess = true;
                res.incidentId = insertedInc.Id;
                res.incidentNumber = detailInc.IncidentNumber;
                res.status = detailInc.Status;
                res.priority = detailInc.Priority;
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}