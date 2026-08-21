public class CopilotException extends Exception {
    public static void logException(Exception e, String context) {
        System.debug('Exception in ' + context + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
    }
}