/**
 * @description       : Advanced String Utilities for formatting, masking, and extracting
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-24
 * @last modified by  : 
**/
public inherited sharing class StringUtils {

    // --- 2.1 Data Masking ---
    
    /**
     * @description Mask an email address (e.g. john.doe@gmail.com -> j******e@gmail.com)
     * @param email The email address to mask
     * @return String The masked email address
     */
    public static String maskEmail(String email) {
        if (String.isBlank(email)) return email;
        List<String> parts = email.split('@');
        if (parts.size() != 2) return email; // Invalid email format
        
        String username = parts[0];
        String domain = parts[1];
        String maskedUser;
        
        if (username.length() <= 1) {
            maskedUser = username;
        } else if (username.length() == 2) {
            maskedUser = username.substring(0, 1) + '*';
        } else {
            String middle = username.substring(1, username.length() - 1);
            String maskedMiddle = middle.replaceAll('.', '*');
            maskedUser = username.substring(0, 1) + maskedMiddle + username.substring(username.length() - 1);
        }
        
        return maskedUser + '@' + domain;
    }

    /**
     * @description Mask credit card keeping only the last 4 digits visible, preserving format
     * @param cardNumber The credit card number to mask
     * @return String The masked credit card number
     */
    public static String maskCreditCard(String cardNumber) {
        if (String.isBlank(cardNumber)) return cardNumber;
        String cleanNum = cardNumber.replaceAll('[^0-9]', '');
        if (cleanNum.length() <= 4) return cardNumber;
        
        Integer digitsFound = 0;
        String result = '';
        
        for (Integer i = cardNumber.length() - 1; i >= 0; i--) {
            String c = cardNumber.substring(i, i+1);
            if (c.isNumeric()) {
                digitsFound++;
                if (digitsFound <= 4) {
                    result = c + result;
                } else {
                    result = '*' + result;
                }
            } else {
                result = c + result;
            }
        }
        return result;
    }

    /**
     * @description Mask a phone number keeping the first 3 and last 3 digits visible
     * @param phone The phone number to mask
     * @return String The masked phone number
     */
    public static String maskPhone(String phone) {
        if (String.isBlank(phone)) return phone;
        Integer totalDigits = phone.replaceAll('[^0-9]', '').length();
        if (totalDigits <= 6) return phone;
        
        Integer digitsFound = 0;
        String result = '';
        
        for (Integer i = phone.length() - 1; i >= 0; i--) {
            String c = phone.substring(i, i+1);
            if (c.isNumeric()) {
                digitsFound++;
                if (digitsFound <= 3 || digitsFound > totalDigits - 3) {
                    result = c + result;
                } else {
                    result = '*' + result;
                }
            } else {
                result = c + result;
            }
        }
        return result;
    }

    // --- 2.2 Naming Convention Formatters ---

    /**
     * @description Convert string to camelCase (e.g. First Name -> firstName)
     * @param input The string to convert
     * @return String The camelCase formatted string
     */
    public static String toCamelCase(String input) {
        if (String.isBlank(input)) return input;
        List<String> parts = input.split('[^a-zA-Z0-9]+');
        String result = '';
        Boolean isFirst = true;
        
        for (String part : parts) {
            if (String.isBlank(part)) continue;
            if (isFirst) {
                result += part.toLowerCase();
                isFirst = false;
            } else {
                result += part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase();
            }
        }
        return result;
    }

    /**
     * @description Convert string to snake_case (e.g. firstName -> first_name)
     * @param input The string to convert
     * @return String The snake_case formatted string
     */
    public static String toSnakeCase(String input) {
        if (String.isBlank(input)) return input;
        String s = input.replaceAll('([a-z])([A-Z]+)', '$1_$2').toLowerCase();
        s = s.replaceAll('[^a-z0-9]+', '_');
        return s.replaceAll('^_|_$', '');
    }

    /**
     * @description Convert string to kebab-case (e.g. First Name -> first-name)
     * @param input The string to convert
     * @return String The kebab-case formatted string
     */
    public static String toKebabCase(String input) {
        if (String.isBlank(input)) return input;
        String s = input.replaceAll('([a-z])([A-Z]+)', '$1-$2').toLowerCase();
        s = s.replaceAll('[^a-z0-9]+', '-');
        return s.replaceAll('^-|-$', '');
    }

    /**
     * @description Capitalize the first letter of each word
     * @param input The string to capitalize
     * @return String The capitalized string
     */
    public static String capitalizeWords(String input) {
        if (String.isBlank(input)) return input;
        List<String> parts = input.split(' ');
        List<String> capParts = new List<String>();
        
        for (String part : parts) {
            if (String.isBlank(part)) {
                capParts.add(part);
            } else {
                capParts.add(part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase());
            }
        }
        return String.join(capParts, ' ');
    }

    // --- 2.3 Extraction & Matching ---

    /**
     * @description Extract substring between two tags
     * @param target The target string
     * @param openTag The starting tag/string
     * @param closeTag The ending tag/string
     * @return String The extracted substring
     */
    public static String extractBetween(String target, String openTag, String closeTag) {
        if (String.isBlank(target) || String.isBlank(openTag) || String.isBlank(closeTag)) return null;
        Integer startIndex = target.indexOf(openTag);
        if (startIndex == -1) return null;
        
        startIndex += openTag.length();
        Integer endIndex = target.indexOf(closeTag, startIndex);
        if (endIndex == -1) return null;
        
        return target.substring(startIndex, endIndex);
    }

    /**
     * @description Check if target contains ANY of the search strings
     * @param target The string to search in
     * @param searchStrings The list of strings to search for
     * @return Boolean True if any match is found
     */
    public static Boolean containsAny(String target, List<String> searchStrings) {
        if (String.isBlank(target) || searchStrings == null || searchStrings.isEmpty()) return false;
        for (String s : searchStrings) {
            if (s != null && target.contains(s)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Check if target contains ALL of the search strings
     * @param target The string to search in
     * @param searchStrings The list of strings to search for
     * @return Boolean True if all match are found
     */
    public static Boolean containsAll(String target, List<String> searchStrings) {
        if (String.isBlank(target) || searchStrings == null || searchStrings.isEmpty()) return false;
        for (String s : searchStrings) {
            if (s == null || !target.contains(s)) {
                return false;
            }
        }
        return true;
    }

    // --- 2.4 Initialization & Default Values ---

    /**
     * @description Returns input if not blank, else defaultValue
     * @param input The input string
     * @param defaultValue The default fallback
     * @return String The selected string
     */
    public static String defaultIfBlank(String input, String defaultValue) {
        return String.isNotBlank(input) ? input : defaultValue;
    }

    /**
     * @description Generate a random string of given length
     * @param length The desired length
     * @param includeSpecialChars Whether to include special characters
     * @return String The randomly generated string
     */
    public static String generateRandomString(Integer length, Boolean includeSpecialChars) {
        if (length == null || length <= 0) return '';
        String alphaNum = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String specials = '!@#$%^&*()-_=+[]{}|;:,.<>?';
        String chars = alphaNum + (includeSpecialChars ? specials : '');
        
        String result = '';
        for (Integer i = 0; i < length; i++) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            result += chars.substring(idx, idx + 1);
        }
        return result;
    }
}