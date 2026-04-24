/**
 * @description       : Utility class for interacting with SObject instances safely
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-24
 * @last modified by  : 
**/
public inherited sharing class SObjectUtils {


    /**
     * @description Returns a Set of API names for fields that have changed between old and new records.
     * Safely handles unqueried fields by using getPopulatedFieldsAsMap.
     * @param oldRecord The original SObject state
     * @param newRecord The new SObject state
     * @return Set<String> The API names of fields that have different values
     */
    public static Set<String> getChangedFields(SObject oldRecord, SObject newRecord) {
        Set<String> changedFields = new Set<String>();
        if (oldRecord == null || newRecord == null) return changedFields;
        if (oldRecord.getSObjectType() != newRecord.getSObjectType()) return changedFields;

        Map<String, Object> oldMap = oldRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newMap = newRecord.getPopulatedFieldsAsMap();
        
        Set<String> allPopulatedFields = new Set<String>();
        allPopulatedFields.addAll(oldMap.keySet());
        allPopulatedFields.addAll(newMap.keySet());
        
        for (String fieldName : allPopulatedFields) {
            Object oldVal = oldMap.containsKey(fieldName) ? oldMap.get(fieldName) : null;
            Object newVal = newMap.containsKey(fieldName) ? newMap.get(fieldName) : null;
            
            if (oldVal != newVal) {
                changedFields.add(fieldName);
            }
        }
        return changedFields;
    }

    /**
     * @description Returns true if ANY field in the provided set has changed.
     * Highly useful in Domain.onAfterUpdate() to trigger Service logic.
     * @param oldRecord The original SObject state
     * @param newRecord The new SObject state
     * @param fieldsToCheck A set of field API names to check for changes
     * @return Boolean True if at least one field has changed, false otherwise
     */
    public static Boolean hasChanged(SObject oldRecord, SObject newRecord, Set<String> fieldsToCheck) {
        if (oldRecord == null || newRecord == null || fieldsToCheck == null || fieldsToCheck.isEmpty()) {
            return false;
        }
        if (oldRecord.getSObjectType() != newRecord.getSObjectType()) return false;
        
        Map<String, Object> oldMap = oldRecord.getPopulatedFieldsAsMap();
        Map<String, Object> newMap = newRecord.getPopulatedFieldsAsMap();
        
        for (String fieldName : fieldsToCheck) {
            Object oldVal = oldMap.containsKey(fieldName) ? oldMap.get(fieldName) : null;
            Object newVal = newMap.containsKey(fieldName) ? newMap.get(fieldName) : null;
            
            if (oldVal != newVal) {
                return true;
            }
        }
        return false;
    }

    // --- 2.2. Structure Handling ---

    /**
     * @description Safely gets a cross-object field value (e.g. 'Account.Owner.Name') without throwing NPE
     * @param record The source SObject
     * @param fieldPath The dot-notated path to the field
     * @return Object The value of the field or null if inaccessible
     */
    public static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) return null;
        
        if (!fieldPath.contains('.')) {
            try {
                return record.get(fieldPath);
            } catch (Exception e) {
                return null; // Field not queried or invalid
            }
        }
        
        List<String> parts = fieldPath.split('\\.');
        SObject currentObj = record;
        
        for (Integer i = 0; i < parts.size() - 1; i++) {
            try {
                currentObj = currentObj.getSObject(parts[i]);
            } catch (Exception e) {
                return null;
            }
            if (currentObj == null) {
                return null;
            }
        }
        
        try {
            return currentObj.get(parts[parts.size() - 1]);
        } catch (Exception e) {
            return null;
        }
    }

    // --- 2.3. Safe Cloning ---

    /**
     * @description Clones a record and nullifies specified fields (e.g., External_Id__c, Status__c)
     * @param originalRecord The record to clone
     * @param fieldsToExclude Set of field API names to clear out in the cloned record
     * @return SObject The cloned record
     */
    public static SObject cloneRecord(SObject originalRecord, Set<String> fieldsToExclude) {
        if (originalRecord == null) return null;
        
        // .clone(preserveId = false, isDeepClone = true, preserveReadonlyTimestamps = false, preserveAutonumber = false)
        SObject clonedRecord = originalRecord.clone(false, true, false, false);
        
        if (fieldsToExclude != null && !fieldsToExclude.isEmpty()) {
            for (String fieldName : fieldsToExclude) {
                try {
                    clonedRecord.put(fieldName, null);
                } catch (Exception e) {
                    // Ignore if field is readonly or invalid
                }
            }
        }
        return clonedRecord;
    }
}