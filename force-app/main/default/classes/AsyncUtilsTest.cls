@isTest
private class AsyncUtilsTest {

    public class MockQueueable implements Queueable {
        public void execute(QueueableContext context) {
            // Validate context is indeed async inside Queueable
            System.assertEquals(true, AsyncUtils.isAsyncContext(), 'Inside Queueable it should be true');
        }
    }

    @isTest
    static void testIsAsyncContext() {
        // In standard synchronous test context, this should be false
        System.assertEquals(false, AsyncUtils.isAsyncContext(), 'Initial context is sync');
    }

    @isTest
    static void testSafeEnqueueJob() {
        Test.startTest();
        AsyncUtils.safeEnqueueJob(new MockQueueable());
        Test.stopTest();
        
        System.assert(true, 'Enqueue should succeed without exception');
    }
    
    @isTest
    static void testSafeEnqueueJobNull() {
        Test.startTest();
        // Should return early and not throw exception
        AsyncUtils.safeEnqueueJob(null);
        Test.stopTest();
        
        System.assert(true, 'Null job should be handled safely');
    }
}