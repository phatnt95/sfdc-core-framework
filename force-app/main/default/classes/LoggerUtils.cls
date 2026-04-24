/**
 * @description       : Dynamic Logging Framework based on Custom Metadata configuration
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : PHAT NGUYEN
**/

public with sharing class LoggerUtils {
    
    // Configuration Holder
    public class LogConfig {
        public String logObjectName;
        public String levelField;
        public String messageField;
        public String stackTraceField;
        public String contextField;
        public String referenceIdField;
        public Boolean usePlatformEvent;
        public String eventObjectName;
        public String eventPayloadField;
        public Set<String> maskingKeys;
    }
    
    private static LogConfig config;
    private static List<SObject> logBuffer = new List<SObject>();
    
    static {
        loadConfiguration();
    }
    
    /**
     * @description Load configuration from Custom Metadata Type
     */
    private static void loadConfiguration() {
        config = new LogConfig();
        // Fallback default values
        config.logObjectName = 'System_Log__c';
        config.levelField = 'Log_Level__c';
        config.messageField = 'Message__c';
        config.stackTraceField = 'Stack_Trace__c';
        config.contextField = 'Context__c';
        config.referenceIdField = 'Reference_Id__c';
        config.usePlatformEvent = true;
        config.eventObjectName = 'System_Log_Event__e';
        config.eventPayloadField = 'Payload__c';
        config.maskingKeys = new Set<String>{'password', 'token', 'secret', 'authorization'};
        
        // Attempt to load from CMDT
        try {
            String query = 'SELECT Log_Object_Name__c, Level_Field__c, Message_Field__c, Stack_Trace_Field__c, Context_Field__c, Reference_Id_Field__c, Use_Platform_Event__c, Event_Object_Name__c, Event_Payload_Field__c, Masking_Keys__c FROM Logger_Setting__mdt WHERE DeveloperName = \'Default\' LIMIT 1';
            SObject cmdt = Database.query(query);
            if (cmdt != null) {
                config.logObjectName = (String)cmdt.get('Log_Object_Name__c');
                config.levelField = (String)cmdt.get('Level_Field__c');
                config.messageField = (String)cmdt.get('Message_Field__c');
                config.stackTraceField = (String)cmdt.get('Stack_Trace_Field__c');
                config.contextField = (String)cmdt.get('Context_Field__c');
                config.referenceIdField = (String)cmdt.get('Reference_Id_Field__c');
                config.usePlatformEvent = (Boolean)cmdt.get('Use_Platform_Event__c');
                config.eventObjectName = (String)cmdt.get('Event_Object_Name__c');
                config.eventPayloadField = (String)cmdt.get('Event_Payload_Field__c');
                
                String keys = (String)cmdt.get('Masking_Keys__c');
                if (String.isNotBlank(keys)) {
                    config.maskingKeys = new Set<String>();
                    for(String key : keys.split(',')) {
                        config.maskingKeys.add(key.trim().toLowerCase());
                    }
                }
            }
        } catch (Exception e) {
            // Ignore error, stick to defaults
        }
    }
    
    /**
     * @description Log info
     * @param message The log message
     * @param context The context or class.method name
     * @param referenceId An optional reference ID for correlation
     */
    public static void info(String message, String context, String referenceId) {
        log('Info', message, null, context, referenceId, true);
    }
    
    /**
     * @description Log error
     * @param message The log message or error description
     * @param stackTrace The exception stack trace
     * @param context The context or class.method name
     * @param referenceId An optional reference ID for correlation
     */
    public static void error(String message, String stackTrace, String context, String referenceId) {
        log('Error', message, stackTrace, context, referenceId, true);
    }
    
    /**
     * @description Log debug
     * @param message The log message
     * @param context The context or class.method name
     * @param referenceId An optional reference ID for correlation
     */
    public static void debug(String message, String context, String referenceId) {
        log('Debug', message, null, context, referenceId, true);
    }
    
    /**
     * @description Adds a log to buffer. Does not commit.
     * @param level The log level (e.g. Info, Error, Debug)
     * @param message The log message
     * @param stackTrace The exception stack trace (if any)
     * @param context The context or class.method name
     * @param referenceId An optional reference ID for correlation
     */
    public static void addLog(String level, String message, String stackTrace, String context, String referenceId) {
        log(level, message, stackTrace, context, referenceId, false);
    }
    
    /**
     * @description Create and optionally commit log record
     * @param level The log level
     * @param message The log message
     * @param stackTrace The exception stack trace
     * @param context The context or class.method name
     * @param referenceId An optional reference ID for correlation
     * @param doCommit Whether to immediately commit the log
     */
    private static void log(String level, String message, String stackTrace, String context, String referenceId, Boolean doCommit) {
        try {
            SObject logRecord = createSObject(config.logObjectName);
            if (logRecord == null) return;
            
            if (String.isNotBlank(config.levelField)) setFieldValue(logRecord, config.levelField, level);
            if (String.isNotBlank(config.messageField)) setFieldValue(logRecord, config.messageField, maskData(message));
            if (String.isNotBlank(config.stackTraceField)) setFieldValue(logRecord, config.stackTraceField, stackTrace);
            if (String.isNotBlank(config.contextField)) setFieldValue(logRecord, config.contextField, context);
            if (String.isNotBlank(config.referenceIdField)) setFieldValue(logRecord, config.referenceIdField, referenceId);
            
            logBuffer.add(logRecord);
            
            if (doCommit) {
                commitLogs();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'LoggerUtils Error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Commits all logs in buffer
     */
    public static void commitLogs() {
        if (logBuffer.isEmpty()) return;
        
        try {
            if (config.usePlatformEvent && String.isNotBlank(config.eventObjectName)) {
                List<SObject> events = new List<SObject>();
                for (SObject logRec : logBuffer) {
                    SObject evt = createSObject(config.eventObjectName);
                    if (evt != null) {
                        setFieldValue(evt, config.eventPayloadField, JSON.serialize(logRec));
                        events.add(evt);
                    }
                }
                if (!events.isEmpty()) {
                    EventBus.publish(events);
                }
            } else {
                SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.CREATABLE, logBuffer);
                Database.insert(securityDecision.getRecords(), false);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to commit logs: ' + e.getMessage());
        } finally {
            logBuffer.clear();
        }
    }
    
    private static SObject createSObject(String apiName) {
        try {
            Type t = Type.forName(apiName);
            if (t != null) {
                return (SObject)t.newInstance();
            } else {
                Schema.SObjectType sot = Schema.getGlobalDescribe().get(apiName);
                if(sot != null) return sot.newSObject();
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create object for API Name: ' + apiName);
        }
        return null;
    }
    
    private static void setFieldValue(SObject obj, String fieldApiName, Object value) {
        if (obj != null && String.isNotBlank(fieldApiName) && value != null) {
            try {
                obj.put(fieldApiName, value);
            } catch (Exception e) {
                // Ignore if field doesn't exist
            }
        }
    }
    
    /**
     * @description Simple data masking logic
     */
    @TestVisible
    private static String maskData(String payload) {
        if (String.isBlank(payload) || config.maskingKeys == null || config.maskingKeys.isEmpty()) {
            return payload;
        }
        
        String masked = payload;
        for (String key : config.maskingKeys) {
            // Mask JSON: "password":"mysecret" -> "password":"***"
            String regexJson = '(?i)("' + key + '"\\s*:\\s*")([^"]*)(")';
            masked = masked.replaceAll(regexJson, '$1***$3');
            
            // Mask URL params: password=mysecret& -> password=***&
            String regexUrl = '(?i)(' + key + '=)([^&]+)';
            masked = masked.replaceAll(regexUrl, '$1***');
        }
        return masked;
    }
}