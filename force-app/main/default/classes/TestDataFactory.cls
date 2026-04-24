/**
 * @description       : Centralized Utility for Generating Mock Data for Unit Tests
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : 
**/
@isTest
public class TestDataFactory {
    
    // --- Setup Data Caches (Lazy Loading) ---
    private static Id standardProfileId;
    
    public static Id getStandardProfileId() {
        if (standardProfileId == null) {
            standardProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        }
        return standardProfileId;
    }

    // --- Helper for Mocking IDs ---
    public static void assignMockIds(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        Schema.SObjectType sObjectType = records[0].getSObjectType();
        for (SObject record : records) {
            if (record.Id == null) {
                record.Id = MockIdGenerator.generate(sObjectType);
            }
        }
    }

    // --- Generic SObject Creation Engine ---
    public static List<SObject> createRecords(
        Schema.SObjectType sObjectType,
        SObject overrideFields,
        Integer count,
        Boolean doInsert
    ) {
        List<SObject> records = new List<SObject>();
        
        // Setup default fields
        Map<String, Object> defaultFields = getDefaultFields(sObjectType);
        
        // Setup override fields
        Map<String, Object> overrides = new Map<String, Object>();
        if (overrideFields != null) {
            Map<String, Object> popFields = overrideFields.getPopulatedFieldsAsMap();
            for (String fieldName : popFields.keySet()) {
                overrides.put(fieldName, popFields.get(fieldName));
            }
        }

        for (Integer i = 0; i < count; i++) {
            SObject record = sObjectType.newSObject();
            
            // Apply defaults
            for (String fieldName : defaultFields.keySet()) {
                record.put(fieldName, defaultFields.get(fieldName));
            }
            
            // Apply overrides (this overwrites default if provided)
            for (String fieldName : overrides.keySet()) {
                record.put(fieldName, overrides.get(fieldName));
            }
            
            records.add(record);
        }

        if (doInsert) {
            // Bypass Triggers for Test Setup Phase
            bypassAllTriggers();
            insert records;
            clearAllTriggersBypass();
        } else {
            // Assign fake IDs for in-memory testing
            assignMockIds(records);
        }

        return records;
    }

    // --- Default Mapping Dictionary ---
    private static Map<String, Object> getDefaultFields(Schema.SObjectType sObjectType) {
        Map<String, Object> defaults = new Map<String, Object>();
        String typeName = sObjectType.getDescribe().getName();
        
        switch on typeName {
            when 'Account' {
                defaults.put('Name', 'Test Account');
                defaults.put('Industry', 'Technology');
            }
            when 'Contact' {
                defaults.put('LastName', 'Test Contact');
                defaults.put('Email', 'test@example.com');
            }
            when 'User' {
                String uniqueVal = String.valueOf(DateTime.now().getTime()) + Math.round(Math.random() * 1000);
                defaults.put('LastName', 'TestUser');
                defaults.put('Email', 'user' + uniqueVal + '@example.com');
                defaults.put('Username', 'user' + uniqueVal + '@example.com');
                defaults.put('Alias', 'tuser');
                defaults.put('TimeZoneSidKey', 'America/Los_Angeles');
                defaults.put('LocaleSidKey', 'en_US');
                defaults.put('EmailEncodingKey', 'UTF-8');
                defaults.put('ProfileId', getStandardProfileId());
                defaults.put('LanguageLocaleKey', 'en_US');
            }
        }
        return defaults;
    }

    // --- Wrapper Methods for Common Objects ---
    
    public static List<Account> createAccounts(Account overrideFields, Integer count, Boolean doInsert) {
        return (List<Account>) createRecords(Account.SObjectType, overrideFields, count, doInsert);
    }
    
    public static List<Contact> createContacts(Contact overrideFields, Integer count, Boolean doInsert) {
        return (List<Contact>) createRecords(Contact.SObjectType, overrideFields, count, doInsert);
    }

    public static List<User> createUsers(User overrideFields, Integer count, Boolean doInsert) {
        return (List<User>) createRecords(User.SObjectType, overrideFields, count, doInsert);
    }

    // --- Relationship Tree Building (Clusters) ---
    
    /**
     * @description Automatically builds Account -> Contacts hierarchy
     */
    public static Map<String, List<SObject>> createAccountWithContacts(Integer numAccounts, Integer contactsPerAccount, Boolean doInsert) {
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();
        
        // Generate Accounts
        List<Account> accounts = createAccounts(null, numAccounts, false);
        
        if (doInsert) {
            bypassAllTriggers();
            insert accounts;
        } else {
            assignMockIds(accounts);
        }
        result.put('Accounts', accounts);
        
        // Generate Contacts mapped to Accounts
        List<Contact> allContacts = new List<Contact>();
        for (Account acc : accounts) {
            Contact overrideContact = new Contact(AccountId = acc.Id);
            List<Contact> accContacts = createContacts(overrideContact, contactsPerAccount, false);
            allContacts.addAll(accContacts);
        }
        
        if (doInsert) {
            insert allContacts;
            clearAllTriggersBypass();
        } else {
            assignMockIds(allContacts);
        }
        result.put('Contacts', allContacts);
        
        return result;
    }
    
    // --- Trigger Bypass Helpers ---
    
    private static void bypassAllTriggers() {
        // Here you would list all handlers to bypass, or if TriggerBaseHandler supports global bypass
        TriggerBaseHandler.bypass('AccountTriggerHandler');
        TriggerBaseHandler.bypass('ContactTriggerHandler');
    }
    
    private static void clearAllTriggersBypass() {
        TriggerBaseHandler.clearAllBypasses();
    }
}