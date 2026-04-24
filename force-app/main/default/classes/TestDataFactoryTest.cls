@isTest
private class TestDataFactoryTest {
    
    @isTest
    static void testMockIdGenerator() {
        Id accId = MockIdGenerator.generate(Account.SObjectType);
        System.assertNotEquals(null, accId, 'Generated ID should not be null');
        System.assertEquals(Account.SObjectType, accId.getSobjectType(), 'Generated ID should belong to Account');
        
        Id conId = MockIdGenerator.generate(Contact.SObjectType);
        System.assertNotEquals(accId, conId, 'Should generate distinct IDs');
    }
    
    @isTest
    static void testCreateRecordsInMemory() {
        Account overrideAcc = new Account(Name = 'Override Name', AnnualRevenue = 1000);
        List<Account> accs = TestDataFactory.createAccounts(overrideAcc, 5, false);
        
        System.assertEquals(5, accs.size(), 'Should create 5 accounts');
        for(Account acc : accs) {
            System.assertEquals('Override Name', acc.Name, 'Should override Name');
            System.assertEquals('Technology', acc.Industry, 'Should apply default Industry');
            System.assertEquals(1000, acc.AnnualRevenue, 'Should apply override AnnualRevenue');
            System.assertNotEquals(null, acc.Id, 'Mock ID should be populated');
        }
    }
    
    @isTest
    static void testCreateRecordsInsert() {
        Contact overrideCon = new Contact(FirstName = 'John');
        List<Contact> cons = TestDataFactory.createContacts(overrideCon, 2, true);
        
        System.assertEquals(2, [SELECT count() FROM Contact WHERE FirstName = 'John'], 'Contacts should be inserted successfully');
    }
    
    @isTest
    static void testCreateUser() {
        List<User> users = TestDataFactory.createUsers(null, 1, false);
        System.assertEquals(1, users.size(), 'Should create 1 user');
        System.assertNotEquals(null, users[0].ProfileId, 'ProfileId should be populated from lazy cache');
    }
    
    @isTest
    static void testRelationshipTreeInMemory() {
        Map<String, List<SObject>> result = TestDataFactory.createAccountWithContacts(2, 3, false);
        
        List<Account> accs = (List<Account>) result.get('Accounts');
        List<Contact> cons = (List<Contact>) result.get('Contacts');
        
        System.assertEquals(2, accs.size(), 'Should create 2 Accounts');
        System.assertEquals(6, cons.size(), 'Should create 6 Contacts'); 
        
        System.assertEquals(accs[0].Id, cons[0].AccountId, 'Contact 0 should be mapped to Account 0');
        System.assertEquals(accs[1].Id, cons[5].AccountId, 'Contact 5 should be mapped to Account 1');
    }
    
    @isTest
    static void testRelationshipTreeInsert() {
        Map<String, List<SObject>> result = TestDataFactory.createAccountWithContacts(1, 2, true);
        List<Account> accs = (List<Account>) result.get('Accounts');
        
        System.assertEquals(1, [SELECT count() FROM Account], 'Account should be inserted');
        System.assertEquals(2, [SELECT count() FROM Contact WHERE AccountId = :accs[0].Id], 'Contacts should be inserted and mapped to Account');
    }
}