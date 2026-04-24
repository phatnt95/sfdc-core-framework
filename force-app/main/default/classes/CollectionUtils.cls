/**
 * @description       : Utility class for Collections (List, Set, Map) on SObjects
 * @author            : PHAT NGUYEN
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : PHAT NGUYEN
**/

public with sharing class CollectionUtils {
    public class CollectionUtilsException extends Exception {}

    /**
     * @description Extract Ids from a list of records
     * @param records The list of SObject records
     * @param fieldName The API name of the Id field
     * @return Set<Id> A set of extracted Ids
     */
    public static Set<Id> extractIds(List<SObject> records, String fieldName) {
        Set<Id> results = new Set<Id>();
        if (records == null || records.isEmpty()) return results;
        
        for (SObject record : records) {
            Id val = (Id) getFieldValue(record, fieldName);
            if (val != null) {
                results.add(val);
            }
        }
        return results;
    }

    /**
     * @description Extract Strings from a list of records
     * @param records The list of SObject records
     * @param fieldName The API name of the String field
     * @return Set<String> A set of extracted Strings
     */
    public static Set<String> extractStrings(List<SObject> records, String fieldName) {
        Set<String> results = new Set<String>();
        if (records == null || records.isEmpty()) return results;
        
        for (SObject record : records) {
            String val = (String) getFieldValue(record, fieldName);
            if (val != null) {
                results.add(val);
            }
        }
        return results;
    }

    /**
     * @description Map a list of records by an Id field
     * @param records The list of SObject records
     * @param fieldName The API name of the Id field to use as the map key
     * @return Map<Id, SObject> A map of records keyed by the specified Id
     */
    public static Map<Id, SObject> mapById(List<SObject> records, String fieldName) {
        if (records == null || records.isEmpty()) return new Map<Id, SObject>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type mapType = Type.forName('Map<Id, ' + sObjType + '>');
        Map<Id, SObject> results = mapType != null ? (Map<Id, SObject>) mapType.newInstance() : new Map<Id, SObject>();
        
        for (SObject record : records) {
            Id key = (Id) getFieldValue(record, fieldName);
            if (key != null) {
                results.put(key, record);
            }
        }
        return results;
    }

    /**
     * @description Map a list of records by a String field
     * @param records The list of SObject records
     * @param fieldName The API name of the String field to use as the map key
     * @return Map<String, SObject> A map of records keyed by the specified String
     */
    public static Map<String, SObject> mapByString(List<SObject> records, String fieldName) {
        if (records == null || records.isEmpty()) return new Map<String, SObject>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type mapType = Type.forName('Map<String, ' + sObjType + '>');
        Map<String, SObject> results = mapType != null ? (Map<String, SObject>) mapType.newInstance() : new Map<String, SObject>();
        
        for (SObject record : records) {
            String key = (String) getFieldValue(record, fieldName);
            if (key != null) {
                results.put(key, record);
            }
        }
        return results;
    }

    /**
     * @description Group a list of records by an Id field
     * @param records The list of SObject records
     * @param fieldName The API name of the Id field to use as the group key
     * @return Map<Id, List<SObject>> A map of record lists grouped by the specified Id
     */
    public static Map<Id, List<SObject>> groupById(List<SObject> records, String fieldName) {
        if (records == null || records.isEmpty()) return new Map<Id, List<SObject>>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type mapType = Type.forName('Map<Id, List<' + sObjType + '>>');
        Map<Id, List<SObject>> results = mapType != null ? (Map<Id, List<SObject>>) mapType.newInstance() : new Map<Id, List<SObject>>();
        
        Type listType = Type.forName('List<' + sObjType + '>');
        
        for (SObject record : records) {
            Id key = (Id) getFieldValue(record, fieldName);
            if (key != null) {
                if (!results.containsKey(key)) {
                    results.put(key, listType != null ? (List<SObject>) listType.newInstance() : new List<SObject>());
                }
                results.get(key).add(record);
            }
        }
        return results;
    }

    /**
     * @description Group a list of records by a String field
     * @param records The list of SObject records
     * @param fieldName The API name of the String field to use as the group key
     * @return Map<String, List<SObject>> A map of record lists grouped by the specified String
     */
    public static Map<String, List<SObject>> groupByString(List<SObject> records, String fieldName) {
        if (records == null || records.isEmpty()) return new Map<String, List<SObject>>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type mapType = Type.forName('Map<String, List<' + sObjType + '>>');
        Map<String, List<SObject>> results = mapType != null ? (Map<String, List<SObject>>) mapType.newInstance() : new Map<String, List<SObject>>();
        
        Type listType = Type.forName('List<' + sObjType + '>');
        
        for (SObject record : records) {
            String key = (String) getFieldValue(record, fieldName);
            if (key != null) {
                if (!results.containsKey(key)) {
                    results.put(key, listType != null ? (List<SObject>) listType.newInstance() : new List<SObject>());
                }
                results.get(key).add(record);
            }
        }
        return results;
    }

    /**
     * @description Filter a list of records by a specific field value
     * @param records The list of SObject records
     * @param fieldName The API name of the field to check
     * @param value The value to match
     * @return List<SObject> A filtered list of records
     */
    public static List<SObject> filterByField(List<SObject> records, String fieldName, Object value) {
        if (records == null || records.isEmpty()) return new List<SObject>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type listType = Type.forName('List<' + sObjType + '>');
        List<SObject> results = listType != null ? (List<SObject>) listType.newInstance() : new List<SObject>();
        
        for (SObject record : records) {
            Object recordVal = getFieldValue(record, fieldName);
            if (recordVal == value) {
                results.add(record);
            }
        }
        return results;
    }
    
    /**
     * @description Filter a list of records where the field value is in a set of Ids
     * @param records The list of SObject records
     * @param fieldName The API name of the Id field
     * @param values The set of valid Ids
     * @return List<SObject> A filtered list of records
     */
    public static List<SObject> filterByFieldIn(List<SObject> records, String fieldName, Set<Id> values) {
        if (records == null || records.isEmpty() || values == null || values.isEmpty()) return new List<SObject>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type listType = Type.forName('List<' + sObjType + '>');
        List<SObject> results = listType != null ? (List<SObject>) listType.newInstance() : new List<SObject>();
        
        for (SObject record : records) {
            Id recordVal = (Id) getFieldValue(record, fieldName);
            if (recordVal != null && values.contains(recordVal)) {
                results.add(record);
            }
        }
        return results;
    }
    
    /**
     * @description Filter a list of records where the field value is in a set of Strings
     * @param records The list of SObject records
     * @param fieldName The API name of the String field
     * @param values The set of valid Strings
     * @return List<SObject> A filtered list of records
     */
    public static List<SObject> filterByFieldIn(List<SObject> records, String fieldName, Set<String> values) {
        if (records == null || records.isEmpty() || values == null || values.isEmpty()) return new List<SObject>();
        
        String sObjType = String.valueOf(records[0].getSObjectType());
        Type listType = Type.forName('List<' + sObjType + '>');
        List<SObject> results = listType != null ? (List<SObject>) listType.newInstance() : new List<SObject>();
        
        for (SObject record : records) {
            String recordVal = (String) getFieldValue(record, fieldName);
            if (recordVal != null && values.contains(recordVal)) {
                results.add(record);
            }
        }
        return results;
    }

    /**
     * @description Helper to get field value safely (supports cross-object e.g., Account.OwnerId)
     * @param record The SObject record
     * @param fieldPath The field API name or cross-object path
     * @return Object The retrieved field value
     */
    private static Object getFieldValue(SObject record, String fieldPath) {
        if (record == null || String.isBlank(fieldPath)) return null;
        
        try {
            if (!fieldPath.contains('.')) {
                return record.get(fieldPath);
            }
            
            // Handle cross object references
            List<String> parts = fieldPath.split('\\.');
            SObject currentSObj = record;
            for (Integer i = 0; i < parts.size() - 1; i++) {
                currentSObj = currentSObj.getSObject(parts[i]);
                if (currentSObj == null) {
                    return null;
                }
            }
            return currentSObj.get(parts[parts.size() - 1]);
        } catch (SObjectException e) {
            throw new CollectionUtilsException('Invalid field API Name or unqueried field: ' + fieldPath);
        } catch (Exception e) {
            throw new CollectionUtilsException('Error retrieving field ' + fieldPath + ': ' + e.getMessage());
        }
    }
}