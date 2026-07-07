public with sharing class CopilotEmployeeSearchKnowledge {

    public class Request {
        @InvocableVariable(label='Search Query' required=true)
        public String searchQuery;
    }

    public class Result {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Articles')
        public List<CopilotEmployeeWrapper.ArticleResult> articles;
    }

    @InvocableMethod(
        label='Copilot Employee: Search Knowledge Base'
        description='Executes SOSL queries on Knowledge Articles.'
    )
    public static List<Result> searchKnowledge(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            res.isSuccess = true;
            res.articles = new List<CopilotEmployeeWrapper.ArticleResult>();

            if (String.isBlank(req.searchQuery)) {
                res.isSuccess = false;
                res.errorMessage = 'Search query cannot be blank.';
                results.add(res);
                continue;
            }

            try {
                String escapedQuery = String.escapeSingleQuotes(req.searchQuery.trim());
                // Query standard Knowledge__kav fields Title, Summary, UrlName
                String soslQuery = 'FIND \'' + escapedQuery + '\' IN ALL FIELDS RETURNING Knowledge__kav(Id, Title, Summary, UrlName)';
                
                List<List<SObject>> searchList = Search.query(soslQuery, AccessLevel.USER_MODE);
                
                if (!searchList.isEmpty() && !searchList[0].isEmpty()) {
                    for (SObject sobj : searchList[0]) {
                        CopilotEmployeeWrapper.ArticleResult art = new CopilotEmployeeWrapper.ArticleResult();
                        art.id = (String) sobj.get('Id');
                        art.title = (String) sobj.get('Title');
                        art.summary = (String) sobj.get('Summary');
                        art.urlName = (String) sobj.get('UrlName');
                        res.articles.add(art);
                    }
                }
            } catch (Exception e) {
                res.isSuccess = false;
                res.errorMessage = CopilotEmployeeExceptionHandler.handleException(e);
            }
            results.add(res);
        }

        return results;
    }
}
