/**
 * @description       : Advanced Date Utilities for Business Logic
 * @author            : 
 * @group             : 
 * @last modified on  : 2026-04-23
 * @last modified by  : 
**/
public inherited sharing class DateUtils {

    // --- 2.1. Checking & Classification ---

    /**
     * @description Check if a date falls on a Saturday or Sunday
     * @param d The date to check
     * @return Boolean True if weekend, false otherwise
     */
    public static Boolean isWeekend(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        String dayOfWeek = dt.format('E'); // Outputs Thu, Fri, Sat, Sun, etc.
        return dayOfWeek == 'Sat' || dayOfWeek == 'Sun';
    }

    /**
     * @description Check if a year is a leap year
     * @param year The year integer
     * @return Boolean True if leap year
     */
    public static Boolean isLeapYear(Integer year) {
        if (year == null) throw new IllegalArgumentException('Year cannot be null');
        return Date.isLeapYear(year);
    }

    /**
     * @description Check if a date falls within a start and end date boundary (inclusive)
     * @param target The date to check
     * @param startD The start boundary
     * @param endD The end boundary
     * @return Boolean True if within range
     */
    public static Boolean isBetween(Date target, Date startD, Date endD) {
        if (target == null || startD == null || endD == null) throw new IllegalArgumentException('Parameters cannot be null');
        return target >= startD && target <= endD;
    }

    // --- 2.2. Boundary Logic ---

    /**
     * @description Returns the first day of the given date's month
     * @param d The source date
     * @return Date The first day of the month
     */
    public static Date startOfMonth(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        return d.toStartOfMonth();
    }

    /**
     * @description Returns the last day of the given date's month
     * @param d The source date
     * @return Date The last day of the month
     */
    public static Date endOfMonth(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        return Date.newInstance(d.year(), d.month(), Date.daysInMonth(d.year(), d.month()));
    }

    /**
     * @description Returns the first day of the given date's quarter
     * @param d The source date
     * @return Date The first day of the quarter
     */
    public static Date startOfQuarter(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        Integer month = d.month();
        Integer startMonth = month - Math.mod(month - 1, 3);
        return Date.newInstance(d.year(), startMonth, 1);
    }

    /**
     * @description Returns the last day of the given date's quarter
     * @param d The source date
     * @return Date The last day of the quarter
     */
    public static Date endOfQuarter(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        Integer month = d.month();
        Integer endMonth = month + (3 - Math.mod(month - 1, 3)) - 1;
        return Date.newInstance(d.year(), endMonth, Date.daysInMonth(d.year(), endMonth));
    }

    /**
     * @description Returns January 1st of the given date's year
     * @param d The source date
     * @return Date January 1st
     */
    public static Date startOfYear(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        return Date.newInstance(d.year(), 1, 1);
    }

    /**
     * @description Returns December 31st of the given date's year
     * @param d The source date
     * @return Date December 31st
     */
    public static Date endOfYear(Date d) {
        if (d == null) throw new IllegalArgumentException('Date cannot be null');
        return Date.newInstance(d.year(), 12, 31);
    }

    // --- 2.3. Distance & Difference Calculation ---

    /**
     * @description Returns exact month differences including fraction based on days
     * @param startD The start date
     * @param endD The end date
     * @return Decimal Exact months difference
     */
    public static Decimal monthsBetween(Date startD, Date endD) {
        if (startD == null || endD == null) throw new IllegalArgumentException('Parameters cannot be null');
        Integer fullMonths = startD.monthsBetween(endD);
        Date added = startD.addMonths(fullMonths);
        Integer daysDiff = added.daysBetween(endD);
        Integer daysInEndMonth = Date.daysInMonth(endD.year(), endD.month());
        Decimal fraction = (Decimal)daysDiff / daysInEndMonth;
        return fullMonths + fraction;
    }

    /**
     * @description Calculates full years passed (e.g. for calculating exact age)
     * @param startD The start date (e.g. birthdate)
     * @param endD The end date (e.g. today)
     * @return Integer Full years
     */
    public static Integer yearsBetween(Date startD, Date endD) {
        if (startD == null || endD == null) throw new IllegalArgumentException('Parameters cannot be null');
        Integer years = endD.year() - startD.year();
        
        // Handle Leap year edge case for February 29th
        Integer startMonth = startD.month();
        Integer startDay = startD.day();
        if (startMonth == 2 && startDay == 29 && !Date.isLeapYear(endD.year())) {
            startDay = 28; // Treat leap anniversary as Feb 28 on non-leap years
        }
        
        Date anniversary = Date.newInstance(endD.year(), startMonth, startDay);
        if (endD < anniversary) {
            years--;
        }
        return years;
    }

    /**
     * @description Finds the next occurrence of a specific weekday. 1=Mon, ..., 7=Sun
     * @param d The start date
     * @param dayOfWeek The target day of week (1-7)
     * @return Date The next occurrence
     */
    public static Date nextOccurrence(Date d, Integer dayOfWeek) {
        if (d == null || dayOfWeek == null || dayOfWeek < 1 || dayOfWeek > 7) {
            throw new IllegalArgumentException('Invalid parameters');
        }
        
        Date knownSunday = Date.newInstance(1900, 1, 7);
        Integer diff = knownSunday.daysBetween(d);
        Integer currentDayOfWeek = Math.mod(diff, 7);
        
        if (diff >= 0) {
            if (currentDayOfWeek == 0) currentDayOfWeek = 7;
        } else {
            if (currentDayOfWeek == 0) currentDayOfWeek = 7;
            else currentDayOfWeek = 7 + currentDayOfWeek;
        }
        
        Integer daysToAdd = dayOfWeek - currentDayOfWeek;
        if (daysToAdd <= 0) {
            daysToAdd += 7;
        }
        return d.addDays(daysToAdd);
    }

    // --- 2.4. Fiscal Year Logic ---

    /**
     * @description Returns the Fiscal Year for a given date and custom fiscal start month
     * @param d The date
     * @param fiscalStartMonth The start month of the fiscal year (1-12)
     * @return Integer The fiscal year
     */
    public static Integer getFiscalYear(Date d, Integer fiscalStartMonth) {
        if (d == null || fiscalStartMonth == null || fiscalStartMonth < 1 || fiscalStartMonth > 12) {
            throw new IllegalArgumentException('Invalid parameters');
        }
        if (d.month() >= fiscalStartMonth) {
            return d.year();
        } else {
            return d.year() - 1;
        }
    }

    /**
     * @description Returns the Fiscal Quarter (1-4) based on a custom fiscal start month
     * @param d The date
     * @param fiscalStartMonth The start month of the fiscal year (1-12)
     * @return Integer The fiscal quarter (1-4)
     */
    public static Integer getFiscalQuarter(Date d, Integer fiscalStartMonth) {
        if (d == null || fiscalStartMonth == null || fiscalStartMonth < 1 || fiscalStartMonth > 12) {
            throw new IllegalArgumentException('Invalid parameters');
        }
        Integer monthOffset = d.month() - fiscalStartMonth;
        if (monthOffset < 0) {
            monthOffset += 12;
        }
        return (monthOffset / 3) + 1;
    }

    // --- 2.5. String Handling & Integration ---

    /**
     * @description Parse ISO8601 safely into Datetime
     * @param isoString The ISO8601 string
     * @return Datetime The parsed Datetime
     */
    public static Datetime parseISO8601(String isoString) {
        if (String.isBlank(isoString)) throw new IllegalArgumentException('String cannot be empty');
        String cleanStr = isoString.trim();
        if (!cleanStr.startsWith('"')) {
            cleanStr = '"' + cleanStr + '"';
        }
        return (Datetime)JSON.deserialize(cleanStr, Datetime.class);
    }

    /**
     * @description Format Datetime to specific string pattern to fix default locale issues
     * @param dt The Datetime
     * @param formatPattern The specific Java SimpleDateFormat pattern
     * @return String Formatted date string
     */
    public static String formatToLocale(Datetime dt, String formatPattern) {
        if (dt == null) throw new IllegalArgumentException('Datetime cannot be null');
        if (String.isBlank(formatPattern)) {
            return dt.format();
        }
        return dt.format(formatPattern);
    }
}