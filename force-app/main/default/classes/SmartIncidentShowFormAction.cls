global with sharing class SmartIncidentShowFormAction {

    global class Request {
        @InvocableVariable(label='Incident Form' description='The incident form data structure' required=false)
        global SmartIncidentFormWrapper incidentForm;
    }

    global class Result {
        @InvocableVariable(label='Incident Form' description='The incident form data structure')
        @AuraEnabled
        global SmartIncidentFormWrapper incidentForm;
    }

    @InvocableMethod(
        label='Smart Incident Show Form Action'
        description='Launches the custom LWC screen form for Smart Incident Agent.'
    )
    global static List<Result> showForm(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            if (req.incidentForm == null) {
                req.incidentForm = new SmartIncidentFormWrapper();
            }

            // If LWC submitted the form (isSuccess = True), perform or query DML
            if (req.incidentForm.isSuccess == true) {
                try {
                    Incident insertedInc;
                    if (String.isNotBlank(req.incidentForm.incidentId)) {
                        insertedInc = [
                            SELECT Id, IncidentNumber, Subject, Status, Priority, Category 
                            FROM Incident 
                            WHERE Id = :req.incidentForm.incidentId 
                            WITH USER_MODE 
                            LIMIT 1
                        ];
                    } else {
                        Incident inc = new Incident();
                        inc.Subject = req.incidentForm.subject;
                        inc.Description = req.incidentForm.description;
                        inc.Status = String.isNotBlank(req.incidentForm.status) ? req.incidentForm.status : 'New';
                        inc.Priority = String.isNotBlank(req.incidentForm.priority) ? req.incidentForm.priority : 'Moderate';
                        inc.Urgency = String.isNotBlank(req.incidentForm.urgency) ? req.incidentForm.urgency : 'Medium';
                        inc.Impact = String.isNotBlank(req.incidentForm.impact) ? req.incidentForm.impact : 'Medium';
                        inc.Category = req.incidentForm.category;

                        insert as user inc;

                        insertedInc = [
                            SELECT Id, IncidentNumber, Subject, Status, Priority, Category 
                            FROM Incident 
                            WHERE Id = :inc.Id 
                            WITH USER_MODE 
                            LIMIT 1
                        ];
                    }

                    res.incidentForm = new SmartIncidentFormWrapper();
                    res.incidentForm.isSuccess = true;
                    res.incidentForm.incidentId = insertedInc.Id;
                    res.incidentForm.incidentNumber = insertedInc.IncidentNumber;
                    res.incidentForm.subject = insertedInc.Subject;
                    res.incidentForm.status = insertedInc.Status;
                    res.incidentForm.priority = insertedInc.Priority;
                    res.incidentForm.category = insertedInc.Category;
                    res.incidentForm.isCancelled = false;
                } catch (Exception e) {
                    res.incidentForm = req.incidentForm;
                    res.incidentForm.isSuccess = false;
                    res.incidentForm.errorMessage = e.getMessage();
                }
            } else {
                // Otherwise, populate defaults for rendering
                if (String.isBlank(req.incidentForm.status)) {
                    req.incidentForm.status = 'New';
                }
                if (String.isBlank(req.incidentForm.urgency)) {
                    req.incidentForm.urgency = 'Medium';
                }
                if (String.isBlank(req.incidentForm.impact)) {
                    req.incidentForm.impact = 'Medium';
                }
                if (String.isBlank(req.incidentForm.priority)) {
                    req.incidentForm.priority = 'Moderate';
                }
                res.incidentForm = req.incidentForm;
            }
            results.add(res);
        }
        return results;
    }
}
