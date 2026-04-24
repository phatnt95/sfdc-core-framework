@isTest
private class CollectionUtilsTest {

    @isTest
    static void testExtractIds() {
        List<Account> accs = new List<Account>{
            new Account(Id = '001000000000001AAA', Name = 'A'),
            new Account(Id = '001000000000002AAA', Name = 'B')
        };
        
        Set<Id> ids = CollectionUtils.extractIds(accs, 'Id');
        System.assertEquals(2, ids.size());
        System.assert(ids.contains('001000000000001AAA'));
        
        // Null test
        System.assertEquals(0, CollectionUtils.extractIds(null, 'Id').size());
    }

    @isTest
    static void testExtractStrings() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'Acc1', Industry = 'Tech'),
            new Account(Name = 'Acc2', Industry = 'Edu')
        };
        
        Set<String> names = CollectionUtils.extractStrings(accs, 'Name');
        System.assertEquals(2, names.size());
        System.assert(names.contains('Acc1'));
        
        // Null test
        System.assertEquals(0, CollectionUtils.extractStrings(null, 'Name').size());
    }

    @isTest
    static void testMapById() {
        List<Account> accs = new List<Account>{
            new Account(Id = '001000000000001AAA', Name = 'A')
        };
        
        Map<Id, Account> accMap = (Map<Id, Account>) CollectionUtils.mapById(accs, 'Id');
        System.assertEquals(1, accMap.size());
        System.assert(accMap.containsKey('001000000000001AAA'));
        System.assertEquals('A', accMap.get('001000000000001AAA').Name);
    }

    @isTest
    static void testMapByString() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'Acc1', Industry = 'Tech')
        };
        
        Map<String, Account> accMap = (Map<String, Account>) CollectionUtils.mapByString(accs, 'Name');
        System.assertEquals(1, accMap.size());
        System.assert(accMap.containsKey('Acc1'));
    }

    @isTest
    static void testGroupById() {
        List<Contact> cons = new List<Contact>{
            new Contact(Id = '003000000000001AAA', AccountId = '001000000000001AAA'),
            new Contact(Id = '003000000000002AAA', AccountId = '001000000000001AAA')
        };
        
        Map<Id, List<Contact>> grouped = (Map<Id, List<Contact>>) CollectionUtils.groupById(cons, 'AccountId');
        System.assertEquals(1, grouped.size());
        System.assertEquals(2, grouped.get('001000000000001AAA').size());
    }

    @isTest
    static void testGroupByString() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'A', Industry = 'Tech'),
            new Account(Name = 'B', Industry = 'Tech'),
            new Account(Name = 'C', Industry = 'Edu')
        };
        
        Map<String, List<Account>> grouped = (Map<String, List<Account>>) CollectionUtils.groupByString(accs, 'Industry');
        System.assertEquals(2, grouped.size());
        System.assertEquals(2, grouped.get('Tech').size());
        System.assertEquals(1, grouped.get('Edu').size());
    }

    @isTest
    static void testFilterByField() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'A', Industry = 'Tech'),
            new Account(Name = 'B', Industry = 'Edu')
        };
        
        List<Account> filtered = (List<Account>) CollectionUtils.filterByField(accs, 'Industry', 'Tech');
        System.assertEquals(1, filtered.size());
        System.assertEquals('A', filtered[0].Name);
    }

    @isTest
    static void testFilterByFieldIn() {
        List<Account> accs = new List<Account>{
            new Account(Name = 'A', Industry = 'Tech'),
            new Account(Name = 'B', Industry = 'Edu'),
            new Account(Name = 'C', Industry = 'Fin')
        };
        
        List<Account> filtered = (List<Account>) CollectionUtils.filterByFieldIn(accs, 'Industry', new Set<String>{'Tech', 'Edu'});
        System.assertEquals(2, filtered.size());
    }
    
    @isTest
    static void testCrossObjectExtract() {
        Account acc = new Account(Name = 'Parent Acc');
        Contact con = new Contact(LastName = 'Test');
        con.putSObject('Account', acc);
        
        List<Contact> cons = new List<Contact>{con};
        
        Set<String> names = CollectionUtils.extractStrings(cons, 'Account.Name');
        System.assertEquals(1, names.size());
        System.assert(names.contains('Parent Acc'));
    }

    @isTest
    static void testInvalidFieldException() {
        List<Account> accs = new List<Account>{new Account(Name = 'A')};
        try {
            CollectionUtils.extractIds(accs, 'InvalidField__c');
            System.assert(false, 'Should throw exception');
        } catch (CollectionUtils.CollectionUtilsException e) {
            System.assert(e.getMessage().contains('Invalid field'), 'Correct exception message');
        }
    }
    
    @isTest
    static void testBulkPerformance() {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 10000; i++) {
            accs.add(new Account(Name = 'Acc ' + i, Industry = 'Tech'));
        }
        
        Test.startTest();
        Map<String, List<Account>> grouped = (Map<String, List<Account>>) CollectionUtils.groupByString(accs, 'Industry');
        Test.stopTest();
        
        System.assertEquals(1, grouped.size());
        System.assertEquals(10000, grouped.get('Tech').size());
    }
}