@isTest
private class BaseSelectorTest {
    
    // Concrete selector class for testing
    private class AccountSelector extends BaseSelector {
        public override Schema.SObjectType getSObjectType() {
            return Account.SObjectType;
        }

        public override List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField>{
                Account.Id,
                Account.Name
            };
        }
        
        // Expose protected method for testing
        public BaseSelector.SOQLBuilder getTestBuilder() {
            return this.newQueryBuilder();
        }
    }

    @isTest
    static void testNewQueryBuilder() {
        AccountSelector selector = new AccountSelector();
        BaseSelector.SOQLBuilder builder = selector.getTestBuilder();
        
        String query = builder.build();
        System.assert(query.containsIgnoreCase('SELECT'), 'Query should start with SELECT');
        System.assert(query.containsIgnoreCase('Name'), 'Query should contain Name field');
        System.assert(query.containsIgnoreCase('FROM Account'), 'Query should target Account');
        System.assert(query.containsIgnoreCase('WITH SECURITY_ENFORCED'), 'Security enforced should be enabled by default');
    }

    @isTest
    static void testSelectById() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        AccountSelector selector = new AccountSelector();
        List<Account> results = (List<Account>)selector.selectById(new Set<Id>{acc.Id});

        System.assertEquals(1, results.size(), 'Should return 1 record');
        System.assertEquals(acc.Id, results[0].Id, 'Ids should match');
        System.assertEquals('Test Account', results[0].Name, 'Names should match');
    }

    @isTest
    static void testSelectByIdEmpty() {
        AccountSelector selector = new AccountSelector();
        List<Account> results = (List<Account>)selector.selectById(new Set<Id>());
        System.assertEquals(0, results.size(), 'Should return empty list for empty ids');
    }

    @isTest
    static void testSelectByIdWithConfig() {
        Account acc = new Account(Name = 'Test Config', Industry = 'Technology');
        insert acc;

        AccountSelector selector = new AccountSelector();
        BaseSelector.QueryConfig config = new BaseSelector.QueryConfig()
            .withAdditionalField('Industry')
            .withLimit(1)
            .withOrderBy('Name DESC')
            .withUserMode();

        List<Account> results = (List<Account>)selector.selectById(new Set<Id>{acc.Id}, config);
        
        System.assertEquals(1, results.size(), 'Should return 1 record');
        System.assertEquals('Technology', (String)results[0].get('Industry'), 'Additional field should be queried');
    }
    
    @isTest
    static void testQueryConfigMethods() {
        BaseSelector.QueryConfig config = new BaseSelector.QueryConfig()
            .withAdditionalFields(new List<String>{'Phone', 'Website'})
            .withOffset(10);
            
        System.assertEquals(2, config.additionalFields.size(), 'Additional fields should be added');
        System.assertEquals(10, config.offsetCount, 'Offset should be 10');
    }

    @isTest
    static void testBuilderWithSObject() {
        BaseSelector.SOQLBuilder builder = new BaseSelector.SOQLBuilder(Account.sObjectType)
            .selectField('Id')
            .selectFields('Name, Industry')
            .selectFields(new List<String>{'Phone', 'Website'})
            .selectFields(new Set<String>{'CreatedDate'})
            .whereCondition('Industry = \'Technology\'')
            .whereCondition('Phone != null')
            .orderBy('Name ASC NULLS LAST')
            .setLimit(10)
            .setOffset(5)
            .withSecurityEnforced();

        String expectedQuery = 'SELECT Id, Name, Industry, Phone, Website, CreatedDate FROM Account WHERE Industry = \'Technology\' AND Phone != null WITH SECURITY_ENFORCED ORDER BY Name ASC NULLS LAST LIMIT 10 OFFSET 5';
        String actualQuery = builder.build();
        
        System.assert(actualQuery.contains('SELECT '), 'Should contain SELECT');
        System.assert(actualQuery.contains('FROM Account'), 'Should contain FROM Account');
        System.assert(actualQuery.contains('WHERE Industry = \'Technology\' AND Phone != null'), 'Where condition is wrong');
        System.assert(actualQuery.contains('WITH SECURITY_ENFORCED'), 'Missing WITH SECURITY_ENFORCED');
        System.assert(actualQuery.contains('ORDER BY Name ASC NULLS LAST'), 'Missing ORDER BY');
        System.assert(actualQuery.contains('LIMIT 10'), 'Missing LIMIT');
        System.assert(actualQuery.contains('OFFSET 5'), 'Missing OFFSET');
    }

    @isTest
    static void testSubQuery() {
        BaseSelector.SOQLBuilder subQuery = new BaseSelector.SOQLBuilder('Contacts')
            .selectFields('Id, LastName');
            
        BaseSelector.SOQLBuilder mainQuery = new BaseSelector.SOQLBuilder('Account')
            .selectField('Id')
            .selectSubQuery(subQuery);
            
        String actualQuery = mainQuery.build();
        System.assert(actualQuery.contains('(SELECT Id, LastName FROM Contacts)'), 'Subquery not generated properly');
    }

    @isTest
    static void testSanitize() {
        String dirtyInput = 'O\'Connor';
        String cleanInput = BaseSelector.sanitize(dirtyInput);
        System.assertEquals('O\\\'Connor', cleanInput, 'Should be escaped');
        
        System.assertEquals(null, BaseSelector.sanitize(null), 'Should handle null');
    }

    @isTest
    static void testExecute() {
        Account acc = new Account(Name = 'Test Execute Account');
        insert acc;
        
        List<SObject> results = new BaseSelector.SOQLBuilder('Account')
            .selectFields('Id, Name')
            .whereCondition('Name = \'' + BaseSelector.sanitize(acc.Name) + '\'')
            .withUserMode()
            .execute();
            
        System.assertEquals(1, results.size(), 'Should return 1 account');
        System.assertEquals('Test Execute Account', (String)results[0].get('Name'), 'Name should match');
        
        List<SObject> defaultResults = new BaseSelector.SOQLBuilder('Account')
            .whereCondition('Id = \'' + acc.Id + '\'')
            .execute();
        System.assertEquals(1, defaultResults.size(), 'Should return 1 account');
    }
    
    @isTest
    static void testEmptySelect() {
        BaseSelector.SOQLBuilder builder = new BaseSelector.SOQLBuilder('Contact');
        String q = builder.build();
        System.assert(q.contains('SELECT Id FROM Contact'), 'Default should be SELECT Id');
    }
}