@isTest
private class RestBaseHandlerTest {
    
    // Concrete Implementation for Testing Success
    private class SuccessHandler extends RestBaseHandler {
        protected override Object processRequest(RestRequest req) {
            return new Map<String, String>{ 'hello' => 'world' };
        }
    }

    // Concrete Implementation for Testing Client Error
    private class ClientErrorHandler extends RestBaseHandler {
        protected override Object processRequest(RestRequest req) {
            RestBaseHandler.RestClientException ex = new RestBaseHandler.RestClientException('Invalid parameter');
            ex.errorCode = 'INVALID_PARAM';
            ex.statusCode = 400;
            throw ex;
        }
    }
    
    // Concrete Implementation for Testing Server Error
    private class ServerErrorHandler extends RestBaseHandler {
        protected override Object processRequest(RestRequest req) {
            throw new CalloutException('Simulated Server Error');
        }
    }

    @isTest
    static void testSuccessFlow() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/test/success';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        SuccessHandler handler = new SuccessHandler();
        handler.execute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(200, res.statusCode);
        
        Map<String, Object> stdRes = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(true, stdRes.get('isSuccess'));
        System.assertNotEquals(null, stdRes.get('data'));
    }
    
    @isTest
    static void testClientErrorFlow() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/test/client-error';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"test": true}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        ClientErrorHandler handler = new ClientErrorHandler();
        handler.execute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(400, res.statusCode);
        
        Map<String, Object> stdRes = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(false, stdRes.get('isSuccess'));
        List<Object> errors = (List<Object>) stdRes.get('errors');
        System.assertEquals(1, errors.size());
        Map<String, Object> firstError = (Map<String, Object>) errors[0];
        System.assertEquals('INVALID_PARAM', firstError.get('errorCode'));
    }
    
    @isTest
    static void testServerErrorFlow() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/test/server-error';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        ServerErrorHandler handler = new ServerErrorHandler();
        handler.execute();
        
        RestResponse res = RestContext.response;
        System.assertEquals(500, res.statusCode);
        
        Map<String, Object> stdRes = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());
        System.assertEquals(false, stdRes.get('isSuccess'));
        List<Object> errors = (List<Object>) stdRes.get('errors');
        Map<String, Object> firstError = (Map<String, Object>) errors[0];
        System.assertEquals('INTERNAL_SERVER_ERROR', firstError.get('errorCode'));
    }
}