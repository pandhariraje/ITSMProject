public class IncidentTriggerHandler {

    public static void handleRecurringIncidents(List<Incident> incidents){

        List<Incident> recurringIncidents = new List<Incident>();
        Set<String> subjects = new Set<String>();

        for(Incident inc : incidents){

            if(inc.Type == 'Recurring' && inc.Subject != null){
                recurringIncidents.add(inc);
                subjects.add(inc.Subject);
            }
        }

        if(recurringIncidents.isEmpty()){
            return;
        }

        // Get existing Problems
        Map<String, Problem> problemMap = new Map<String, Problem>();

        for(Problem pr : [
            SELECT Id, Subject
            FROM Problem
            WHERE Subject IN :subjects
        ]){
            problemMap.put(pr.Subject , pr);
        }

        // Create Problems if not existing
        List<Problem> problemsToInsert = new List<Problem>();

        for(String subject : subjects){

            if(!problemMap.containsKey(subject)){

                Problem pr = new Problem();
                pr.Subject = subject;

                problemsToInsert.add(pr);
            }
        }

        if(!problemsToInsert.isEmpty()){
            insert problemsToInsert;

            for(Problem p : problemsToInsert){
                problemMap.put(p.Subject , p);
            }
        }

        // Create Junction records
        List<ProblemIncident> relations = new List<ProblemIncident>();

        for(Incident inc : recurringIncidents){

            Problem pr = problemMap.get(inc.Subject);

            if(pr != null){

                ProblemIncident rel = new ProblemIncident();

                rel.IssueId = inc.Id;
                rel.RelatedIssueId = pr.Id;

                relations.add(rel);
            }
        }

        if(!relations.isEmpty()){
            insert relations;
        }
    }


    public static void handleRecurringIncidentsOnUpdate(List<Incident> newList, Map<Id,Incident> oldMap){

        List<Incident> incidentsToProcess = new List<Incident>();

        for(Incident inc : newList){

            Incident oldInc = oldMap.get(inc.Id);

            if(inc.Type == 'Recurring' && oldInc.Type != 'Recurring'){
                incidentsToProcess.add(inc);
            }
        }

        handleRecurringIncidents(incidentsToProcess);
    }
}