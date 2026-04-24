@isTest
private class SObjectUtilsTest {
    
    @isTest
    static void testGetChangedFields() {
        Account oldAcc = new Account(Name = 'Old Name', Industry = 'Technology');
        Account newAcc = new Account(Name = 'New Name', Industry = 'Technology');
        
        Set<String> changed = SObjectUtils.getChangedFields(oldAcc, newAcc);
        System.assertEquals(1, changed.size(), 'Should detect 1 changed field');
        System.assert(changed.contains('Name'), 'Name should be detected as changed');
        
        System.assertEquals(0, SObjectUtils.getChangedFields(null, newAcc).size(), 'Should handle null safely');
        
        // Test different objects
        Contact con = new Contact(LastName = 'Test');
        System.assertEquals(0, SObjectUtils.getChangedFields(oldAcc, con).size(), 'Should handle different SObjectTypes safely');
    }

    @isTest
    static void testHasChanged() {
        Account oldAcc = new Account(Name = 'Old Name', Industry = 'Technology');
        Account newAcc = new Account(Name = 'New Name', Industry = 'Agriculture');
        
        System.assertEquals(true, SObjectUtils.hasChanged(oldAcc, newAcc, new Set<String>{'Name'}), 'Should detect Name change');
        System.assertEquals(true, SObjectUtils.hasChanged(oldAcc, newAcc, new Set<String>{'Industry'}), 'Should detect Industry change');
        System.assertEquals(false, SObjectUtils.hasChanged(oldAcc, newAcc, new Set<String>{'Phone'}), 'Should not detect change for unpopulated/unchanged field');
        
        System.assertEquals(false, SObjectUtils.hasChanged(null, newAcc, new Set<String>{'Name'}), 'Should handle null safely');
    }

    @isTest
    static void testGetFieldValue() {
        // Simulate a cross-object structure in memory
        String jsonStr = '{"attributes":{"type":"Contact"},"LastName":"Doe","Account":{"attributes":{"type":"Account"},"Name":"Acme"}}';
        Contact con = (Contact) JSON.deserialize(jsonStr, Contact.class);
        
        System.assertEquals('Doe', SObjectUtils.getFieldValue(con, 'LastName'), 'Should retrieve direct field');
        System.assertEquals('Acme', SObjectUtils.getFieldValue(con, 'Account.Name'), 'Should retrieve cross-object field');
        System.assertEquals(null, SObjectUtils.getFieldValue(con, 'Account.Industry'), 'Should handle missing field safely');
        System.assertEquals(null, SObjectUtils.getFieldValue(con, 'Owner.Name'), 'Should handle missing parent safely');
        System.assertEquals(null, SObjectUtils.getFieldValue(null, 'LastName'), 'Should handle null record safely');
    }

    @isTest
    static void testCloneRecord() {
        Account original = new Account(Name = 'Template', Industry = 'Technology', Phone = '123456');
        
        Set<String> fieldsToExclude = new Set<String>{'Phone', 'Industry', 'NonExistentField__c'};
        Account cloned = (Account) SObjectUtils.cloneRecord(original, fieldsToExclude);
        
        System.assertNotEquals(null, cloned, 'Cloned record should not be null');
        System.assertEquals('Template', cloned.Name, 'Unexcluded field should carry over');
        System.assertEquals(null, cloned.Industry, 'Excluded field should be nullified');
        System.assertEquals(null, cloned.Phone, 'Excluded field should be nullified');
        
        System.assertEquals(null, SObjectUtils.cloneRecord(null, fieldsToExclude), 'Should handle null safely');
    }
}