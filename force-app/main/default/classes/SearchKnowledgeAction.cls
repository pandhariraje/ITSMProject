public with sharing class SearchKnowledgeAction {

    public class Request {
        @InvocableVariable(label='Search Query' description='The search term to look for in Knowledge Articles' required=true)
        public String searchQuery;
    }

    public class ArticleResult {
        @InvocableVariable(label='Title' description='Title of the article')
        public String title;

        @InvocableVariable(label='Summary' description='Summary of the article')
        public String summary;

        @InvocableVariable(label='Question' description='The question answered by this article')
        public String question;

        @InvocableVariable(label='Answer' description='The answer provided by this article')
        public String answer;

        @InvocableVariable(label='Procedure Steps' description='Steps to resolve the issue')
        public String procedureSteps;

        @InvocableVariable(label='Workaround' description='Workaround if applicable')
        public String workaround;
    }

    public class Result {
        @InvocableVariable(label='Is Success' description='Whether the query completed successfully')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Error message if query failed')
        public String errorMessage;

        @InvocableVariable(label='Articles' description='Matching knowledge articles')
        public List<ArticleResult> articles;
    }

    @InvocableMethod(
        label='Search Knowledge Articles'
        description='Searches Salesforce Knowledge Articles using SOSL and returns matching results.'
    )
    public static List<Result> searchKnowledge(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = true;
            r.articles = new List<ArticleResult>();

            if (String.isBlank(req.searchQuery)) {
                r.isSuccess = false;
                r.errorMessage = 'Search query cannot be blank.';
                results.add(r);
                continue;
            }

            try {
                // Perform SOSL query on Knowledge__kav
                String escapedQuery = String.escapeSingleQuotes(req.searchQuery.trim());
                String soslQuery = 'FIND \'' + escapedQuery + '\' IN ALL FIELDS RETURNING Knowledge__kav(Title, Summary, Question__c, Answer__c, Procedure_Steps__c, Workaround__c)';
                
                // Execute search in User Mode
                List<List<SObject>> searchList = Search.query(soslQuery, AccessLevel.USER_MODE);
                
                if (!searchList.isEmpty() && !searchList[0].isEmpty()) {
                    List<Knowledge__kav> kavs = (List<Knowledge__kav>) searchList[0];
                    for (Knowledge__kav kav : kavs) {
                        ArticleResult art = new ArticleResult();
                        art.title = kav.Title;
                        art.summary = kav.Summary;
                        art.question = kav.Question__c;
                        art.answer = kav.Answer__c;
                        art.procedureSteps = kav.Procedure_Steps__c;
                        art.workaround = kav.Workaround__c;
                        r.articles.add(art);
                    }
                }
            } catch (Exception e) {
                r.isSuccess = false;
                r.errorMessage = e.getMessage();
            }
            
            results.add(r);
        }

        return results;
    }
}
