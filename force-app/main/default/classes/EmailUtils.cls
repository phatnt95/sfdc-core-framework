/**
 * @description       : Utility Framework to standardize Email sending via Builder Pattern
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : 
**/
public inherited sharing class EmailUtils {
    
    public class EmailUtilsException extends Exception {}

    // Caches to avoid duplicate SOQL in bulk processing
    private static Map<String, Id> templateCache = new Map<String, Id>();
    private static Map<String, Id> orgWideEmailCache = new Map<String, Id>();

    /**
     * @description Inner class providing a Fluent Interface for building a single email message
     */
    public class EmailBuilder {
        private Messaging.SingleEmailMessage email;
        public String templateDeveloperName { get; private set; }
        public String orgWideEmailAddress { get; private set; }
        
        public EmailBuilder() {
            this.email = new Messaging.SingleEmailMessage();
        }
        
        public EmailBuilder setToAddresses(List<String> toAddresses) {
            this.email.setToAddresses(toAddresses);
            return this;
        }
        
        public EmailBuilder setCcAddresses(List<String> ccAddresses) {
            this.email.setCcAddresses(ccAddresses);
            return this;
        }
        
        public EmailBuilder setSubject(String subject) {
            this.email.setSubject(subject);
            return this;
        }
        
        public EmailBuilder setHtmlBody(String htmlBody) {
            this.email.setHtmlBody(htmlBody);
            return this;
        }
        
        public EmailBuilder setPlainTextBody(String plainTextBody) {
            this.email.setPlainTextBody(plainTextBody);
            return this;
        }
        
        public EmailBuilder setTargetObjectId(Id targetObjectId) {
            this.email.setTargetObjectId(targetObjectId);
            return this;
        }
        
        public EmailBuilder setWhatId(Id whatId) {
            this.email.setWhatId(whatId);
            return this;
        }
        
        public EmailBuilder setSenderDisplayName(String displayName) {
            this.email.setSenderDisplayName(displayName);
            return this;
        }
        
        public EmailBuilder useTemplate(String developerName) {
            this.templateDeveloperName = developerName;
            return this;
        }
        
        public EmailBuilder useOrgWideEmail(String oweaAddress) {
            this.orgWideEmailAddress = oweaAddress;
            return this;
        }
        
        public EmailBuilder addAttachment(ContentVersion cv) {
            if (cv != null && cv.VersionData != null) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(String.isNotBlank(cv.PathOnClient) ? cv.PathOnClient : cv.Title);
                efa.setBody(cv.VersionData);
                
                List<Messaging.EmailFileAttachment> attachments = this.email.getFileAttachments();
                if (attachments == null) {
                    attachments = new List<Messaging.EmailFileAttachment>();
                }
                attachments.add(efa);
                this.email.setFileAttachments(attachments);
            }
            return this;
        }
        
        public Messaging.SingleEmailMessage build() {
            return this.email;
        }
    }

    /**
     * @description Send a batch of emails. Resolves templates and OrgWideEmailAddresses efficiently.
     * @param builders List of EmailBuilder instances configured for each email to send
     */
    public static void sendEmails(List<EmailBuilder> builders) {
        if (builders == null || builders.isEmpty()) return;
        
        // 1. Limits Check
        if (Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations()) {
            throw new EmailUtilsException('Exceeded Salesforce Email Invocation Limits.');
        }

        Set<String> templateNames = new Set<String>();
        Set<String> oweaAddresses = new Set<String>();
        
        for (EmailBuilder b : builders) {
            if (String.isNotBlank(b.templateDeveloperName)) {
                templateNames.add(b.templateDeveloperName);
            }
            if (String.isNotBlank(b.orgWideEmailAddress)) {
                oweaAddresses.add(b.orgWideEmailAddress);
            }
        }
        
        // 2. Resolve Templates using Cache
        if (!templateNames.isEmpty()) {
            List<String> namesToQuery = new List<String>();
            for (String name : templateNames) {
                if (!templateCache.containsKey(name)) {
                    namesToQuery.add(name);
                }
            }
            if (!namesToQuery.isEmpty()) {
                for (EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :namesToQuery]) {
                    templateCache.put(et.DeveloperName, et.Id);
                }
            }
        }
        
        // 3. Resolve OrgWideEmailAddresses using Cache
        if (!oweaAddresses.isEmpty()) {
            List<String> addressesToQuery = new List<String>();
            for (String address : oweaAddresses) {
                if (!orgWideEmailCache.containsKey(address)) {
                    addressesToQuery.add(address);
                }
            }
            if (!addressesToQuery.isEmpty()) {
                for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :addressesToQuery]) {
                    orgWideEmailCache.put(owea.Address, owea.Id);
                }
            }
        }
        
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        // 4. Finalize Configuration
        for (EmailBuilder b : builders) {
            Messaging.SingleEmailMessage msg = b.build();
            
            // Apply Template
            if (String.isNotBlank(b.templateDeveloperName)) {
                Id templateId = templateCache.get(b.templateDeveloperName);
                if (templateId == null) {
                    throw new EmailUtilsException('Email Template not found: ' + b.templateDeveloperName);
                }
                msg.setTemplateId(templateId);
                // Template replaces manual body and subject
                msg.setSubject(null);
                msg.setHtmlBody(null);
                msg.setPlainTextBody(null);
            }
            
            // Apply OrgWideEmail
            if (String.isNotBlank(b.orgWideEmailAddress)) {
                Id oweaId = orgWideEmailCache.get(b.orgWideEmailAddress);
                if (oweaId == null) {
                    throw new EmailUtilsException('OrgWideEmailAddress not found: ' + b.orgWideEmailAddress);
                }
                msg.setOrgWideEmailAddressId(oweaId);
            }
            
            emailsToSend.add(msg);
        }
        
        // 5. Send and Handle Results
        if (!emailsToSend.isEmpty()) {
            // Send allowing partial success
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
            
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult res = results[i];
                if (!res.isSuccess()) {
                    String errorMsg = 'Failed to send email. Errors: ';
                    for (Messaging.SendEmailError err : res.getErrors()) {
                        errorMsg += '[' + err.getStatusCode() + '] ' + err.getMessage() + '; ';
                    }
                    
                    Messaging.SingleEmailMessage failedMsg = emailsToSend[i];
                    String targetInfo = 'TargetObjectId: ' + failedMsg.getTargetObjectId();
                    if (failedMsg.getToAddresses() != null) {
                        targetInfo = 'To: ' + String.join(failedMsg.getToAddresses(), ',');
                    }
                    
                    // Log error safely without halting transaction
                    LoggerUtils.error(errorMsg, null, 'EmailUtils.sendEmails', targetInfo);
                }
            }
        }
    }
}