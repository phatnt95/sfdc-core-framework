@isTest
private class StringUtilsTest {

    @isTest
    static void testMaskEmail() {
        System.assertEquals('j******e@gmail.com', StringUtils.maskEmail('john.doe@gmail.com'), 'Standard email mask');
        System.assertEquals('a@gmail.com', StringUtils.maskEmail('a@gmail.com'), 'Single char user mask');
        System.assertEquals('a*@gmail.com', StringUtils.maskEmail('ab@gmail.com'), 'Two char user mask');
        System.assertEquals(null, StringUtils.maskEmail(null), 'Null input');
        System.assertEquals('invalidemail', StringUtils.maskEmail('invalidemail'), 'Invalid format returns as is');
    }

    @isTest
    static void testMaskCreditCard() {
        System.assertEquals('**** **** **** 1234', StringUtils.maskCreditCard('4111 1111 1111 1234'), 'Mask with spaces');
        System.assertEquals('************1234', StringUtils.maskCreditCard('4111111111111234'), 'Mask without spaces');
        System.assertEquals('123', StringUtils.maskCreditCard('123'), 'Too short returns as is');
        System.assertEquals(null, StringUtils.maskCreditCard(null), 'Null input');
    }

    @isTest
    static void testMaskPhone() {
        System.assertEquals('+84 1** *** 789', StringUtils.maskPhone('+84 123 456 789'), 'Mask phone with spaces');
        System.assertEquals('090***321', StringUtils.maskPhone('090123321'), 'Mask phone without spaces');
        System.assertEquals('12345', StringUtils.maskPhone('12345'), 'Too short returns as is');
        System.assertEquals(null, StringUtils.maskPhone(null), 'Null input');
    }

    @isTest
    static void testFormatters() {
        // Camel Case
        System.assertEquals('firstName', StringUtils.toCamelCase('First Name'), 'Space to camel');
        System.assertEquals('firstName', StringUtils.toCamelCase('first_name'), 'Snake to camel');
        System.assertEquals('firstName', StringUtils.toCamelCase('-first-name-'), 'Kebab to camel');
        System.assertEquals(null, StringUtils.toCamelCase(null), 'Null input');

        // Snake Case
        System.assertEquals('first_name', StringUtils.toSnakeCase('firstName'), 'Camel to snake');
        System.assertEquals('first_name', StringUtils.toSnakeCase('First Name'), 'Space to snake');
        System.assertEquals('first_name', StringUtils.toSnakeCase('first-name'), 'Kebab to snake');
        System.assertEquals(null, StringUtils.toSnakeCase(null), 'Null input');

        // Kebab Case
        System.assertEquals('first-name', StringUtils.toKebabCase('firstName'), 'Camel to kebab');
        System.assertEquals('first-name', StringUtils.toKebabCase('First Name'), 'Space to kebab');
        System.assertEquals('first-name', StringUtils.toKebabCase('first_name'), 'Snake to kebab');
        System.assertEquals(null, StringUtils.toKebabCase(null), 'Null input');

        // Capitalize Words
        System.assertEquals('Nguyen Van A', StringUtils.capitalizeWords('nguyen van a'), 'Lower to cap');
        System.assertEquals('Nguyen  Van A', StringUtils.capitalizeWords('nguyen  van a'), 'Handle extra spaces');
        System.assertEquals(null, StringUtils.capitalizeWords(null), 'Null input');
    }

    @isTest
    static void testExtractBetween() {
        String xml = '<name>John</name>';
        System.assertEquals('John', StringUtils.extractBetween(xml, '<name>', '</name>'), 'Extract standard');
        System.assertEquals(null, StringUtils.extractBetween(xml, '<age>', '</age>'), 'Extract fail');
        System.assertEquals(null, StringUtils.extractBetween(null, 'a', 'b'), 'Extract null target');
    }

    @isTest
    static void testContainsAnyAll() {
        String target = 'Hello world from Salesforce';
        List<String> wordsAny = new List<String>{'Salesforce', 'Apex'};
        List<String> wordsAll = new List<String>{'Hello', 'Salesforce'};
        List<String> wordsAllFail = new List<String>{'Hello', 'Apex'};
        
        System.assertEquals(true, StringUtils.containsAny(target, wordsAny), 'Contains Any True');
        System.assertEquals(false, StringUtils.containsAny(target, new List<String>{'Java'}), 'Contains Any False');
        
        System.assertEquals(true, StringUtils.containsAll(target, wordsAll), 'Contains All True');
        System.assertEquals(false, StringUtils.containsAll(target, wordsAllFail), 'Contains All False');
        
        System.assertEquals(false, StringUtils.containsAny(null, wordsAny), 'Contains Any Null Target');
    }

    @isTest
    static void testDefaultsAndGeneration() {
        System.assertEquals('default', StringUtils.defaultIfBlank('', 'default'), 'Default applied');
        System.assertEquals('input', StringUtils.defaultIfBlank('input', 'default'), 'Default not applied');
        
        String rand1 = StringUtils.generateRandomString(10, false);
        System.assertEquals(10, rand1.length(), 'Random 10');
        
        String rand2 = StringUtils.generateRandomString(15, true);
        System.assertEquals(15, rand2.length(), 'Random 15 with specials');
        
        System.assertEquals('', StringUtils.generateRandomString(0, false), 'Random 0');
    }
}