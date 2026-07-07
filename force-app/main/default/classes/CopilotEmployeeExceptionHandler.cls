public with sharing class CopilotEmployeeExceptionHandler {
    public static String handleException(Exception e) {
        String msg = e.getMessage();
        System.debug(LoggingLevel.ERROR, 'Exception occurred: ' + msg + '\n' + e.getStackTraceString());
        return msg;
    }
}
