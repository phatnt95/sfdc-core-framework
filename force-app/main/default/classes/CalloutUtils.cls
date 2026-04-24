/**
 * @description       : Standardized Integration Utility
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : PHAT NGUYEN
**/
public with sharing class CalloutUtils {
    
    public class CalloutRequest {
        public String namedCredential;
        public String path;
        public String method;
        public Map<String, String> headers;
        public String body;
        public Integer timeout;
        public Boolean debugMode; // If true, logs even 200 OK responses
        public Integer maxRetries;
        
        public CalloutRequest() {
            this.method = 'GET';
            this.headers = new Map<String, String>{
                'Content-Type' => 'application/json'
            };
            this.timeout = 120000;
            this.debugMode = false;
            this.maxRetries = 0;
        }
    }
    
    public class CalloutException extends Exception {}
    
    /**
     * @description Smart Router to handle callout context
     * @param req The CalloutRequest object (created from HttpRequestBuilder)
     * @param requireAsync Flag indicating if async execution is required to avoid DML errors
     */
    public static void doCallout(CalloutRequest req, Boolean requireAsync) {
        if (requireAsync && !AsyncUtils.isAsyncContext()) {
            // Requires Async and currently in Sync -> Safely enqueue to Queueable
            AsyncUtils.safeEnqueueJob(new CalloutQueueable(req));
        } else {
            // Already in Async, OR does not require Async -> Execute synchronously immediately
            execute(req);
        }
    }

    /**
     * @description Queueable class for background execution
     */
    public class CalloutQueueable implements Queueable, Database.AllowsCallouts {
        private CalloutRequest req;
        
        public CalloutQueueable(CalloutRequest req) {
            this.req = req;
        }
        
        public void execute(QueueableContext context) {
            // Call the synchronous execution method within the Queueable context
            CalloutUtils.execute(this.req);
        }
    }
    /**
     * @description Execute callout
     * @param req The CalloutRequest configuration detailing the callout parameters
     * @return HttpResponse The result of the HTTP callout
     */
    public static HttpResponse execute(CalloutRequest req) {
        HttpRequest httpReq = new HttpRequest();
        
        if (String.isBlank(req.namedCredential)) {
            throw new CalloutException('Named Credential is required.');
        }
        
        httpReq.setEndpoint('callout:' + req.namedCredential + (String.isNotBlank(req.path) ? req.path : ''));
        httpReq.setMethod(req.method);
        httpReq.setTimeout(req.timeout);
        
        if (req.headers != null) {
            for (String key : req.headers.keySet()) {
                httpReq.setHeader(key, req.headers.get(key));
            }
        }
        
        if (String.isNotBlank(req.body)) {
            httpReq.setBody(req.body);
        }
        
        Http http = new Http();
        HttpResponse res;
        Integer attempt = 0;
        Boolean isSuccess = false;
        
        while (attempt <= req.maxRetries && !isSuccess) {
            try {
                res = http.send(httpReq);
                
                // Determine if we need to log
                Boolean isError = res.getStatusCode() >= 400;
                if (isError || req.debugMode) {
                    logCallout(req, res, null);
                }
                
                // Retry logic for 5xx errors
                if (res.getStatusCode() >= 500 && attempt < req.maxRetries) {
                    attempt++;
                    continue;
                }
                
                isSuccess = true;
                
            } catch (Exception e) {
                if (attempt == req.maxRetries) {
                    logCallout(req, null, e);
                    throw new CalloutException('Callout failed after ' + attempt + ' retries: ' + e.getMessage(), e);
                }
                attempt++;
            }
        }
        
        return res;
    }
    
    /**
     * @description Parses response to Generic Type
     * @param res The HttpResponse containing the JSON body
     * @param parseType The Apex Type class to deserialize into
     * @return Object The deserialized JSON castable to the provided Type
     */
    public static Object parseResponse(HttpResponse res, Type parseType) {
        if (res != null && String.isNotBlank(res.getBody())) {
            return JSON.deserialize(res.getBody(), parseType);
        }
        return null;
    }
    
    /**
     * @description Logs callout request, response, and exceptions into LoggerUtils
     * @param req The CalloutRequest containing original request details
     * @param res The received HttpResponse (can be null if an exception occurred)
     * @param ex Any exception encountered during the request (can be null if successful)
     */
    private static void logCallout(CalloutRequest req, HttpResponse res, Exception ex) {
        String context = 'CalloutUtils.' + req.namedCredential;
        String logBody = 'Endpoint: ' + req.path + '\n' +
                         'Method: ' + req.method + '\n' +
                         'Request Payload:\n' + (req.body != null ? req.body : '') + '\n\n';
                         
        if (res != null) {
            logBody += 'Response Status: ' + res.getStatusCode() + ' ' + res.getStatus() + '\n' +
                       'Response Body:\n' + res.getBody();
            
            if (res.getStatusCode() >= 400) {
                LoggerUtils.error(logBody, null, context, null);
            } else {
                LoggerUtils.info(logBody, context, null);
            }
        } else if (ex != null) {
            logBody += 'Exception: ' + ex.getMessage();
            LoggerUtils.error(logBody, ex.getStackTraceString(), context, null);
        }
    }

    /**
     * @description Builder pattern for CalloutRequest to simplify callout construction.
     */
    public class HttpRequestBuilder {
        private CalloutRequest request;
        private Map<String, String> queryParams;

        public HttpRequestBuilder() {
            this.request = new CalloutRequest();
            this.queryParams = new Map<String, String>();
        }

        /**
         * @description Sets the Named Credential for the callout
         * @param namedCredential The Named Credential API name
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setNamedCredential(String namedCredential) {
            this.request.namedCredential = namedCredential;
            return this;
        }

        /**
         * @description Sets the endpoint path
         * @param path The URL path to append
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setPath(String path) {
            this.request.path = path;
            return this;
        }

        /**
         * @description Sets the HTTP Method
         * @param method The HTTP method
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setMethod(String method) {
            this.request.method = method;
            return this;
        }

        public HttpRequestBuilder get() { return this.setMethod('GET'); }
        public HttpRequestBuilder post() { return this.setMethod('POST'); }
        public HttpRequestBuilder put() { return this.setMethod('PUT'); }
        public HttpRequestBuilder del() { return this.setMethod('DELETE'); }
        public HttpRequestBuilder patch() { return this.setMethod('PATCH'); }

        /**
         * @description Sets the callout timeout
         * @param timeout The timeout in milliseconds
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setTimeout(Integer timeout) {
            this.request.timeout = timeout;
            return this;
        }

        /**
         * @description Adds a query parameter
         * @param key The parameter key
         * @param value The parameter value
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder addQueryParam(String key, String value) {
            if (String.isNotBlank(key) && value != null) {
                this.queryParams.put(key, value);
            }
            return this;
        }

        /**
         * @description Sets a custom header
         * @param key The header key
         * @param value The header value
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setHeader(String key, String value) {
            if (String.isNotBlank(key) && String.isNotBlank(value)) {
                this.request.headers.put(key, value);
            }
            return this;
        }

        /**
         * @description Helper to set Authorization Bearer Token
         * @param token The token
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setBearerToken(String token) {
            return this.setHeader('Authorization', 'Bearer ' + token);
        }

        /**
         * @description Serializes an object to JSON and sets as body
         * @param payload The payload object
         * @return HttpRequestBuilder For method chaining
         */
        public HttpRequestBuilder setJsonBody(Object payload) {
            if (payload != null) {
                this.request.body = JSON.serialize(payload, true);
                this.setHeader('Content-Type', 'application/json');
            }
            return this;
        }

        public CalloutRequest build() {
            String finalEndpoint = this.request.path != null ? this.request.path : '';
            
            if (!this.queryParams.isEmpty()) {
                List<String> paramList = new List<String>();
                for (String key : this.queryParams.keySet()) {
                    String encodedKey = EncodingUtil.urlEncode(key, 'UTF-8');
                    String encodedValue = EncodingUtil.urlEncode(this.queryParams.get(key), 'UTF-8');
                    paramList.add(encodedKey + '=' + encodedValue);
                }
                
                String queryStr = String.join(paramList, '&');
                if (finalEndpoint.contains('?')) {
                    finalEndpoint += '&' + queryStr;
                } else {
                    finalEndpoint += '?' + queryStr;
                }
            }
            
            this.request.path = finalEndpoint;
            return this.request;
        }
    }
}