@isTest
private class CalloutUtilsTest {

    // Mock class to simulate HTTP responses
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public Boolean isError;
        public Integer callCount = 0;
        
        public MockHttpResponseGenerator(Boolean isError) {
            this.isError = isError;
        }

        public HTTPResponse respond(HTTPRequest req) {
            callCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (isError) {
                res.setBody('{"error": "Internal Server Error"}');
                res.setStatusCode(500);
            } else {
                res.setBody('{"success": true, "data": "Test Data"}');
                res.setStatusCode(200);
            }
            return res;
        }
    }
    
    // Wrapper class for testing JSON parsing
    private class TestResponseWrapper {
        public Boolean success;
        public String data;
    }

    @isTest
    static void testSuccessfulCallout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(false));
        
        CalloutUtils.CalloutRequest request = new CalloutUtils.CalloutRequest();
        request.namedCredential = 'Test_Credential';
        request.path = '/api/test/success';
        request.method = 'GET';
        request.debugMode = true; // Set to true to hit logging block for 2xx responses
        
        Test.startTest();
        HttpResponse res = CalloutUtils.execute(request);
        Test.stopTest();
        
        System.assertEquals(200, res.getStatusCode(), 'Expected HTTP 200 OK');
        
        // Test parsing the successful response
        TestResponseWrapper parsedRes = (TestResponseWrapper) CalloutUtils.parseResponse(res, TestResponseWrapper.class);
        System.assertNotEquals(null, parsedRes, 'Parsed response should not be null');
        System.assertEquals(true, parsedRes.success, 'Success flag should be true');
        System.assertEquals('Test Data', parsedRes.data, 'Data field should match mock body');
    }
    
    @isTest
    static void testFailedCalloutWithRetry() {
        MockHttpResponseGenerator mock = new MockHttpResponseGenerator(true);
        Test.setMock(HttpCalloutMock.class, mock);
        
        CalloutUtils.CalloutRequest request = new CalloutUtils.CalloutRequest();
        request.namedCredential = 'Test_Credential';
        request.path = '/api/test/error';
        request.method = 'POST';
        request.body = '{"username": "test", "password": "sensitive"}'; // also tests masking indirectly via logger
        request.maxRetries = 1;
        
        Test.startTest();
        HttpResponse res = CalloutUtils.execute(request);
        Test.stopTest();
        
        System.assertEquals(500, res.getStatusCode(), 'Expected HTTP 500 after exhausting retries');
        System.assertEquals(2, mock.callCount, 'Should have made 1 initial call and 1 retry');
    }
    
    @isTest
    static void testMissingNamedCredential() {
        CalloutUtils.CalloutRequest request = new CalloutUtils.CalloutRequest();
        // Do not set namedCredential to trigger validation exception
        
        Test.startTest();
        try {
            CalloutUtils.execute(request);
            System.assert(false, 'Should throw exception for missing Named Credential');
        } catch (CalloutUtils.CalloutException e) {
            System.assertEquals('Named Credential is required.', e.getMessage(), 'Validation error message should match');
        }
        Test.stopTest();
    }

    @isTest
    static void testBuilderPattern() {
        CalloutUtils.CalloutRequest req = new CalloutUtils.HttpRequestBuilder()
            .setNamedCredential('My_System')
            .setPath('/v1/users')
            .get()
            .addQueryParam('status', 'active')
            .addQueryParam('name', 'John Doe')
            .setHeader('Custom-Header', 'TestValue')
            .setBearerToken('my_secret_token')
            .setTimeout(60000)
            .build();

        System.assertEquals('GET', req.method, 'Method should be GET');
        System.assertEquals('/v1/users?status=active&name=John+Doe', req.path, 'Path and Query Params should be correctly formatted and encoded');
        System.assertEquals('TestValue', req.headers.get('Custom-Header'), 'Custom header should be set');
        System.assertEquals('Bearer my_secret_token', req.headers.get('Authorization'), 'Bearer token should be properly formatted');
    }

    @isTest
    static void testJsonBody() {
        Map<String, String> payload = new Map<String, String>{
            'key1' => 'value1'
        };

        CalloutUtils.CalloutRequest req = new CalloutUtils.HttpRequestBuilder()
            .setNamedCredential('My_System')
            .setPath('/v1/data')
            .post()
            .setJsonBody(payload)
            .build();

        System.assertEquals('POST', req.method, 'Method should be POST');
        System.assertEquals('application/json', req.headers.get('Content-Type'), 'Content-Type should be automatically set to application/json');
        System.assertEquals('{"key1":"value1"}', req.body, 'Body should be a JSON string');
    }

    @isTest
    static void testExistingQueryParamsInEndpoint() {
        CalloutUtils.CalloutRequest req = new CalloutUtils.HttpRequestBuilder()
            .setNamedCredential('My_System')
            .setPath('/search?type=account')
            .addQueryParam('q', 'test query')
            .build();

        System.assertEquals('/search?type=account&q=test+query', req.path, 'Should append correctly using & if ? already exists');
    }
    
    @isTest
    static void testConvenienceMethods() {
        CalloutUtils.HttpRequestBuilder builder = new CalloutUtils.HttpRequestBuilder();
        System.assertEquals('PUT', builder.put().build().method, 'Should set method to PUT');
        System.assertEquals('DELETE', builder.del().build().method, 'Should set method to DELETE');
        System.assertEquals('PATCH', builder.patch().build().method, 'Should set method to PATCH');
    }
}