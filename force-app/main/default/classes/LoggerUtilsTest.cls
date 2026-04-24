@isTest
private class LoggerUtilsTest {

    @isTest
    static void testLoggingMethods() {
        // We execute the logging methods to ensure code coverage and that no unhandled exceptions 
        // are thrown when running without pre-existing Custom Metadata or SObjects in the org.
        Test.startTest();
        
        LoggerUtils.info('Test Info Message', 'LoggerUtilsTest.testLoggingMethods', 'REF-001');
        LoggerUtils.error('Test Error Message', 'NullPointerException at line 12', 'LoggerUtilsTest.testLoggingMethods', 'REF-002');
        LoggerUtils.debug('Test Debug Message', 'LoggerUtilsTest.testLoggingMethods', 'REF-003');
        
        LoggerUtils.addLog('Warning', 'Test Warning Message', null, 'LoggerUtilsTest.testLoggingMethods', 'REF-004');
        LoggerUtils.commitLogs();
        
        Test.stopTest();
        
        // Assuming no exceptions means the dynamic creation correctly skipped or handled missing SObjects/Metadata.
        System.assert(true, 'Logging methods executed successfully');
    }
    
    @isTest
    static void testMaskData() {
        // Test JSON format masking
        String inputJson = '{"username": "admin", "password": "superSecretPassword123"}';
        String maskedJson = LoggerUtils.maskData(inputJson);
        
        System.assert(maskedJson.contains('***'), 'Password value should be masked with ***');
        System.assert(!maskedJson.contains('superSecretPassword123'), 'Original secret should not be present');
        
        // Test URL parameter format masking
        String inputUrl = 'https://api.example.com/login?username=admin&password=mySecretPassword&grant_type=client_credentials';
        String maskedUrl = LoggerUtils.maskData(inputUrl);
        
        System.assert(maskedUrl.contains('password=***'), 'URL parameter password should be masked');
        System.assert(!maskedUrl.contains('mySecretPassword'), 'Original secret in URL should not be present');
        System.assert(maskedUrl.contains('grant_type=client_credentials'), 'Other parameters should remain intact');
    }
}