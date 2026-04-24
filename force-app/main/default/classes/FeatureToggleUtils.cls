/**
 * @description       : Utility class for evaluating feature flags, trigger bypasses, and endpoint switching.
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-24
 * @last modified by  : 
**/
public inherited sharing class FeatureToggleUtils {

    // Cache the feature flags map using getAll() to avoid SOQL queries
    @TestVisible
    private static Map<String, Feature_Flag__mdt> featureFlags {
        get {
            if (featureFlags == null) {
                featureFlags = Feature_Flag__mdt.getAll();
            }
            return featureFlags;
        }
        set;
    }

    // Cache the current user's profile name
    @TestVisible
    private static String currentUserProfileName {
        get {
            if (currentUserProfileName == null) {
                // Ensure safe querying, executed only once per transaction
                List<Profile> profiles = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
                currentUserProfileName = profiles.isEmpty() ? '' : profiles[0].Name;
            }
            return currentUserProfileName;
        }
        set;
    }

    /**
     * @description Checks if a specific feature is enabled.
     * Evaluates the Is_Active__c flag and the Target_Profiles__c list.
     * @param featureName DeveloperName of the Feature_Flag__mdt record.
     * @return true if enabled, false otherwise.
     */
    public static Boolean isEnabled(String featureName) {
        if (String.isBlank(featureName) || !featureFlags.containsKey(featureName)) {
            return false;
        }

        Feature_Flag__mdt flag = featureFlags.get(featureName);
        
        if (!flag.Is_Active__c) {
            return false;
        }

        // Check target profiles if defined (comma-separated list)
        if (String.isNotBlank(flag.Target_Profiles__c)) {
            List<String> allowedProfiles = flag.Target_Profiles__c.split(',');
            Boolean isProfileAllowed = false;
            for (String profileName : allowedProfiles) {
                if (profileName.trim().equalsIgnoreCase(currentUserProfileName)) {
                    isProfileAllowed = true;
                    break;
                }
            }
            return isProfileAllowed;
        }

        // If no target profiles defined, it's globally active
        return true;
    }

    /**
     * @description Checks if the trigger for a given SObject should be bypassed.
     * Combines Custom Permission check with Feature Flag configuration.
     * Expected Feature Flag DeveloperName format: Disable_[SObjectName]_Trigger
     * @param sObjectName The API name of the SObject (e.g. Account, Custom_Obj__c).
     * @return true if the trigger is bypassed, false otherwise.
     */
    public static Boolean isTriggerBypassed(String sObjectName) {
        // 1. Check custom permission first (Global bypass for Integration/Admin)
        if (FeatureManagement.checkPermission('Bypass_All_Triggers')) {
            return true;
        }

        // 2. Check Custom Metadata flag
        if (String.isBlank(sObjectName)) {
            return false;
        }
        
        // Example: Disable_Account_Trigger or Disable_Custom_Obj_Trigger
        String baseName = sObjectName.replace('__c', '').replace('__mdt', '');
        String featureName = 'Disable_' + baseName + '_Trigger';
        
        // Note: If the feature is enabled (Active), it means the trigger is BYPASSED (Disabled)
        return isEnabled(featureName);
    }

    /**
     * @description Returns the appropriate endpoint (Live or Mock) based on a feature toggle.
     * Expected Feature Flag DeveloperName format: [serviceName]
     * @param serviceName The DeveloperName of the service configuration in Feature_Flag__mdt.
     * @return The endpoint URL as a String.
     */
    public static String getEndpoint(String serviceName) {
        if (String.isBlank(serviceName) || !featureFlags.containsKey(serviceName)) {
            return null; 
        }
        
        Feature_Flag__mdt flag = featureFlags.get(serviceName);
        
        // If feature is active, return Live, else return Mock
        if (isEnabled(serviceName)) {
            return flag.Live_Endpoint__c;
        } else {
            return flag.Mock_Endpoint__c;
        }
    }
}