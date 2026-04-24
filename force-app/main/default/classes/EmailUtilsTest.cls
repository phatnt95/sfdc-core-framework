@isTest
private class EmailUtilsTest {
    
    @isTest
    static void testEmailBuilderManual() {
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .setToAddresses(new List<String>{'test@example.com'})
            .setCcAddresses(new List<String>{'cc@example.com'})
            .setSubject('Test Subject')
            .setHtmlBody('<b>HTML</b>')
            .setPlainTextBody('TEXT')
            .setSenderDisplayName('Test Sender');
            
        Messaging.SingleEmailMessage msg = builder.build();
        
        System.assertEquals(1, msg.getToAddresses().size(), 'To address should be set');
        System.assertEquals('Test Subject', msg.getSubject(), 'Subject should match');
        System.assertEquals('<b>HTML</b>', msg.getHtmlBody(), 'HTML body should match');
        System.assertEquals('Test Sender', msg.getSenderDisplayName(), 'Sender Display Name should match');
    }

    @isTest
    static void testEmailBuilderWithAttachment() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test Content')
        );
        
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .addAttachment(cv);
            
        Messaging.SingleEmailMessage msg = builder.build();
        System.assertNotEquals(null, msg.getFileAttachments(), 'Attachments should not be null');
        System.assertEquals(1, msg.getFileAttachments().size(), 'There should be 1 attachment');
        System.assertEquals('test.txt', msg.getFileAttachments()[0].getFileName(), 'Filename should match PathOnClient');
    }
    
    @isTest
    static void testEmailBuilderWithAttachmentNoPath() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test File Only Title',
            VersionData = Blob.valueOf('Test Content')
        );
        
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .addAttachment(cv);
            
        Messaging.SingleEmailMessage msg = builder.build();
        System.assertEquals('Test File Only Title', msg.getFileAttachments()[0].getFileName(), 'Filename should fallback to Title');
    }

    @isTest
    static void testSendEmailsMissingTemplate() {
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .useTemplate('NonExistentTemplate_12345');
            
        Boolean exceptionThrown = false;
        try {
            EmailUtils.sendEmails(new List<EmailUtils.EmailBuilder>{builder});
        } catch (EmailUtils.EmailUtilsException ex) {
            exceptionThrown = true;
            System.assert(ex.getMessage().contains('Email Template not found'), 'Exception should mention missing template');
        }
        System.assert(exceptionThrown, 'Should throw exception for missing template');
    }

    @isTest
    static void testSendEmailsMissingOrgWideEmail() {
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .useOrgWideEmail('nonexistent@example.com');
            
        Boolean exceptionThrown = false;
        try {
            EmailUtils.sendEmails(new List<EmailUtils.EmailBuilder>{builder});
        } catch (EmailUtils.EmailUtilsException ex) {
            exceptionThrown = true;
            System.assert(ex.getMessage().contains('OrgWideEmailAddress not found'), 'Exception should mention missing OWEA');
        }
        System.assert(exceptionThrown, 'Should throw exception for missing OrgWideEmailAddress');
    }
    
    @isTest
    static void testSendEmailsWithErrorsLogged() {
        // Send email without setting recipient or targetObjectId to force a failure
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .setSubject('Fail me');
            
        Test.startTest();
        // This will not throw exception but will log error via LoggerUtils
        EmailUtils.sendEmails(new List<EmailUtils.EmailBuilder>{builder});
        Test.stopTest();
        
        // Assert no unhandled exception occurred and error was caught gracefully
        System.assert(true, 'Send email handled its error gracefully without crashing');
    }
    
    @isTest
    static void testSendEmailsEmptyList() {
        Test.startTest();
        EmailUtils.sendEmails(new List<EmailUtils.EmailBuilder>());
        Test.stopTest();
        System.assert(true, 'Should handle empty list without errors');
    }
    
    @isTest
    static void testTargetAndWhatId() {
        Id fakeTargetId = '003000000000001AAA'; // Contact fake Id
        Id fakeWhatId = '001000000000001AAA'; // Account fake Id
        
        EmailUtils.EmailBuilder builder = new EmailUtils.EmailBuilder()
            .setTargetObjectId(fakeTargetId)
            .setWhatId(fakeWhatId);
            
        Messaging.SingleEmailMessage msg = builder.build();
        System.assertEquals(fakeTargetId, msg.getTargetObjectId(), 'Target Object ID should match');
        System.assertEquals(fakeWhatId, msg.getWhatId(), 'What ID should match');
    }
}