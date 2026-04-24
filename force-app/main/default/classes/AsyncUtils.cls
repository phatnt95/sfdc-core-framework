/**
 * @description       : Utility class to manage asynchronous executions and protect against governor limits.
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-24
 * @last modified by  : 
**/
public inherited sharing class AsyncUtils {

    /**
     * @description Checks if the current context is asynchronous (future, batch, or queueable).
     * @return True if in an async context, false otherwise.
     */
    public static Boolean isAsyncContext() {
        return System.isFuture() || System.isBatch() || System.isQueueable();
    }

    /**
     * @description Safely enqueues a Queueable job. If the queueable jobs limit is reached,
     * logs a critical error using LoggerUtils without crashing the system.
     * @param job The Queueable job to enqueue.
     */
    public static void safeEnqueueJob(Queueable job) {
        if (job == null) {
            return;
        }

        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(job);
        } else {
            String jobPayload = '';
            try {
                jobPayload = JSON.serialize(job);
            } catch (Exception e) {
                jobPayload = 'Serialization failed: ' + e.getMessage();
            }
            // Log the error with job payload as reference/context
            LoggerUtils.error('Queueable Limits Exceeded. Failed to enqueue job.', null, 'AsyncUtils.safeEnqueueJob', jobPayload);
        }
    }
}