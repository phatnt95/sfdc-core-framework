@isTest
public class MockIdGenerator {
    private static Integer fakeIdCount = 0;
    private static final String ID_PATTERN = '000000000000';

    /**
     * @description Generates a valid fake Salesforce Id for a given SObjectType
     */
    public static Id generate(Schema.SObjectType sObjectType) {
        fakeIdCount++;
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        String countStr = String.valueOf(fakeIdCount);
        String fakeIdPrefix = ID_PATTERN.substring(0, 12 - countStr.length());
        return Id.valueOf(keyPrefix + fakeIdPrefix + countStr);
    }
}