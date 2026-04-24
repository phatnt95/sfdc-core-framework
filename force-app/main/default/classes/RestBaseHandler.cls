/**
 * @description       : Standardized Base Framework for Inbound REST APIs
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : PHAT NGUYEN
**/
public abstract class RestBaseHandler {

    // Standard Response Wrapper
    public class StandardResponse {
        public Boolean isSuccess { get; set; }
        public Integer statusCode { get; set; }
        public Object data { get; set; }
        public List<ErrorDetail> errors { get; set; }
        
        public StandardResponse() {
            this.isSuccess = true;
            this.statusCode = 200;
            this.errors = new List<ErrorDetail>();
        }
    }
    
    public class ErrorDetail {
        public String errorCode { get; set; }
        public String message { get; set; }
        
        public ErrorDetail(String errorCode, String message) {
            this.errorCode = errorCode;
            this.message = message;
        }
    }
    
    // Custom Exception for Client Errors
    public class RestClientException extends Exception {
        public Integer statusCode;
        public String errorCode;
    }

    /**
     * @description Template method to execute the standard flow
     */
    public void execute() {
        Long startTime = System.currentTimeMillis();
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        if (res == null) {
            res = new RestResponse();
            RestContext.response = res;
        }
        
        StandardResponse stdRes = new StandardResponse();
        Exception caughtException = null;
        
        try {
            // Call abstract method implemented by concrete class
            Object resultData = processRequest(req);
            stdRes.data = resultData;
            
        } catch (RestClientException rce) {
            stdRes.isSuccess = false;
            stdRes.statusCode = rce.statusCode != null ? rce.statusCode : 400;
            stdRes.errors.add(new ErrorDetail(rce.errorCode != null ? rce.errorCode : 'BAD_REQUEST', rce.getMessage()));
            caughtException = rce;
        } catch (Exception e) {
            stdRes.isSuccess = false;
            stdRes.statusCode = 500;
            stdRes.errors.add(new ErrorDetail('INTERNAL_SERVER_ERROR', e.getMessage()));
            caughtException = e;
        } finally {
            // Set Response body and status
            res.statusCode = stdRes.statusCode;
            res.addHeader('Content-Type', 'application/json');
            String jsonResponseBody = JSON.serialize(stdRes);
            res.responseBody = Blob.valueOf(jsonResponseBody);
            
            // Auto Logging
            Long executionTime = System.currentTimeMillis() - startTime;
            logRequest(req, stdRes.statusCode, jsonResponseBody, caughtException, executionTime);
        }
    }
    
    private void logRequest(RestRequest req, Integer statusCode, String responseBody, Exception ex, Long executionTime) {
        String reqBody = req != null && req.requestBody != null ? req.requestBody.toString() : '';
        String reqUri = req != null ? req.requestURI : 'Unknown URI';
        String reqMethod = req != null ? req.httpMethod : 'Unknown Method';
        
        String logMessage = 'URI: ' + reqUri + '\n' +
                            'Method: ' + reqMethod + '\n' +
                            'Execution Time: ' + executionTime + ' ms\n' +
                            'Request Body:\n' + reqBody + '\n\n' +
                            'Response Body:\n' + responseBody;
                            
        String context = 'InboundREST.' + reqUri;
        
        if (ex != null || statusCode >= 400) {
            String stackTrace = ex != null ? ex.getStackTraceString() : null;
            LoggerUtils.error(logMessage, stackTrace, context, null);
        } else {
            LoggerUtils.info(logMessage, context, null);
        }
    }
    
    /**
     * @description Must be implemented by concrete classes
     */
    protected abstract Object processRequest(RestRequest req);
}