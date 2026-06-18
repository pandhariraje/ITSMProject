public with sharing class CreateIncidentAction {

    public class Request {
        @InvocableVariable(label='Subject' description='The subject of the incident' required=true)
        public String subject;

        @InvocableVariable(label='Description' description='The detailed description of the incident' required=true)
        public String description;

        @InvocableVariable(label='Category' description='Optional category override' required=false)
        public String category;

        @InvocableVariable(label='Priority' description='Optional priority override' required=false)
        public String priority;

        @InvocableVariable(label='Urgency' description='Urgency level: Low, Medium, High' required=false)
        public String urgency;

        @InvocableVariable(label='Impact' description='Impact level: Low, Medium, High' required=false)
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
    }

    @InvocableMethod(
        label='Create ITSM Incident'
        description='Creates an Incident record with automated categorization and priority assignment.'
    )
    public static List<Result> createIncident(List<Request> requests) {
        List<Result> results = new List<Result>();
        List<Incident> incidentsToInsert = new List<Incident>();
        
        // Resolve Requesters in bulk if emails are provided
        Set<String> emails = new Set<String>();
        for (Request req : requests) {
            if (String.isNotBlank(req.requesterEmail)) {
                emails.add(req.requesterEmail.trim());
            }
        }

        Map<String, Id> emailToUserId = new Map<String, Id>();
        if (!emails.isEmpty()) {
            for (User u : [SELECT Id, Email FROM User WHERE Email IN :emails AND IsActive = true WITH USER_MODE]) {
                emailToUserId.put(u.Email.toLowerCase(), u.Id);
            }
            // Fallback to contacts if not user
            for (Contact c : [SELECT Id, Email FROM Contact WHERE Email IN :emails WITH USER_MODE]) {
                if (!emailToUserId.containsKey(c.Email.toLowerCase())) {
                    emailToUserId.put(c.Email.toLowerCase(), c.Id);
                }
            }
        }

        for (Request req : requests) {
            Incident inc = new Incident();
            inc.Subject = req.subject;
            inc.Description = req.description;
            inc.Status = 'New';

            // 1. Auto-Categorization Logic
            String resolvedCategory = 'Software'; // Default
            String textToAnalyze = (req.subject + ' ' + req.description).toLowerCase();
            
            if (String.isNotBlank(req.category)) {
                resolvedCategory = req.category;
            } else {
                if (textToAnalyze.contains('vpn') || textToAnalyze.contains('wi-fi') || textToAnalyze.contains('wifi') || textToAnalyze.contains('network') || textToAnalyze.contains('outage') || textToAnalyze.contains('internet')) {
                    resolvedCategory = 'Network';
                } else if (textToAnalyze.contains('printer') || textToAnalyze.contains('print') || textToAnalyze.contains('toner') || textToAnalyze.contains('laptop') || textToAnalyze.contains('hardware') || textToAnalyze.contains('keyboard') || textToAnalyze.contains('mouse') || textToAnalyze.contains('screen')) {
                    resolvedCategory = 'Hardware';
                }
            }
            inc.Category = resolvedCategory;

            // 2. Auto-Priority Assignment Logic
            String resolvedPriority = 'Medium'; // Default
            if (String.isNotBlank(req.priority)) {
                resolvedPriority = req.priority;
            } else {
                if (textToAnalyze.contains('outage') || textToAnalyze.contains('critical') || textToAnalyze.contains('down') || textToAnalyze.contains('cannot work') || textToAnalyze.contains('emergency') || textToAnalyze.contains('blocked')) {
                    resolvedPriority = 'Critical';
                } else if (textToAnalyze.contains('printer') || textToAnalyze.contains('minor') || textToAnalyze.contains('reset') || textToAnalyze.contains('install')) {
                    resolvedPriority = 'Low';
                }
            }
            inc.Priority = resolvedPriority;

            // 2b. Auto-Urgency Assignment (required field)
            String resolvedUrgency = 'High'; // Default
            if (String.isNotBlank(req.urgency)) {
                resolvedUrgency = req.urgency;
            } else {
                if (resolvedPriority == 'Critical') {
                    resolvedUrgency = 'High';
                } else if (resolvedPriority == 'Low') {
                    resolvedUrgency = 'Low';
                }
            }
            inc.Urgency = resolvedUrgency;

            // 2c. Auto-Impact Assignment (required field)
            String resolvedImpact = 'High'; // Default
            if (String.isNotBlank(req.impact)) {
                resolvedImpact = req.impact;
            } else {
                if (textToAnalyze.contains('entire team') || textToAnalyze.contains('all users') || textToAnalyze.contains('company-wide') || textToAnalyze.contains('outage') || textToAnalyze.contains('everyone')) {
                    resolvedImpact = 'High';
                } else if (textToAnalyze.contains('only me') || textToAnalyze.contains('just me') || textToAnalyze.contains('minor')) {
                    resolvedImpact = 'Low';
                }
            }
            inc.Impact = resolvedImpact;

            // 3. Resolve Requester
            Id requesterId = UserInfo.getUserId(); // Default
            if (String.isNotBlank(req.requesterEmail) && emailToUserId.containsKey(req.requesterEmail.toLowerCase())) {
                requesterId = emailToUserId.get(req.requesterEmail.toLowerCase());
            }
            inc.ReportedById = requesterId;

            incidentsToInsert.add(inc);
        }

        if (!incidentsToInsert.isEmpty()) {
            try {
                // Insert under user mode to respect FLS/CRUD
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, incidentsToInsert);
                insert decision.getRecords();
                
                List<Incident> insertedIncidents = [
                    SELECT Id, IncidentNumber 
                    FROM Incident 
                    WHERE Id IN :decision.getRecords()
                ];
                
                Map<Id, String> incIdToNum = new Map<Id, String>();
                for (Incident i : insertedIncidents) {
                    incIdToNum.put(i.Id, i.IncidentNumber);
                }

                for (Integer idx = 0; idx < requests.size(); idx++) {
                    Incident insertedInc = (Incident) decision.getRecords()[idx];
                    Result r = new Result();
                    r.isSuccess = true;
                    r.incidentId = insertedInc.Id;
                    r.incidentNumber = incIdToNum.get(insertedInc.Id);
                    results.add(r);
                }
            } catch (Exception e) {
                for (Request req : requests) {
                    Result r = new Result();
                    r.isSuccess = false;
                    r.errorMessage = e.getMessage();
                    results.add(r);
                }
            }
        }

        return results;
    }
}
