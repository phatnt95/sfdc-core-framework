@isTest
private class DateUtilsTest {

    @isTest
    static void testIsWeekend() {
        Date saturday = Date.newInstance(2023, 10, 14); // Oct 14, 2023 is Sat
        Date monday = Date.newInstance(2023, 10, 16);
        
        System.assertEquals(true, DateUtils.isWeekend(saturday), 'Saturday should be weekend');
        System.assertEquals(false, DateUtils.isWeekend(monday), 'Monday should not be weekend');
    }

    @isTest
    static void testIsLeapYear() {
        System.assertEquals(true, DateUtils.isLeapYear(2024), '2024 is a leap year');
        System.assertEquals(false, DateUtils.isLeapYear(2023), '2023 is not a leap year');
    }

    @isTest
    static void testIsBetween() {
        Date startD = Date.newInstance(2023, 1, 1);
        Date endD = Date.newInstance(2023, 12, 31);
        Date targetIn = Date.newInstance(2023, 6, 15);
        Date targetOut = Date.newInstance(2024, 1, 1);
        
        System.assertEquals(true, DateUtils.isBetween(targetIn, startD, endD), 'Target is inside range');
        System.assertEquals(false, DateUtils.isBetween(targetOut, startD, endD), 'Target is outside range');
    }

    @isTest
    static void testBoundaryLogic() {
        Date d = Date.newInstance(2023, 5, 15); // Q2
        
        System.assertEquals(Date.newInstance(2023, 5, 1), DateUtils.startOfMonth(d), 'Start of Month');
        System.assertEquals(Date.newInstance(2023, 5, 31), DateUtils.endOfMonth(d), 'End of Month');
        
        System.assertEquals(Date.newInstance(2023, 4, 1), DateUtils.startOfQuarter(d), 'Start of Quarter (Q2 begins April)');
        System.assertEquals(Date.newInstance(2023, 6, 30), DateUtils.endOfQuarter(d), 'End of Quarter (Q2 ends June)');
        
        System.assertEquals(Date.newInstance(2023, 1, 1), DateUtils.startOfYear(d), 'Start of Year');
        System.assertEquals(Date.newInstance(2023, 12, 31), DateUtils.endOfYear(d), 'End of Year');
    }

    @isTest
    static void testMonthsBetween() {
        Date d1 = Date.newInstance(2023, 1, 15);
        Date d2 = Date.newInstance(2023, 3, 30);
        Decimal diff = DateUtils.monthsBetween(d1, d2);
        // Full months = 2 (Jan 15 to Mar 15)
        // Days diff = 15
        // Days in end month (March) = 31
        // Expected = 2 + 15/31 = 2.4838...
        System.assert(diff > 2 && diff < 3, 'Difference should have fraction');
    }

    @isTest
    static void testYearsBetween() {
        Date d1 = Date.newInstance(2000, 5, 20);
        Date d2 = Date.newInstance(2023, 5, 19);
        Date d3 = Date.newInstance(2023, 5, 20);
        
        System.assertEquals(22, DateUtils.yearsBetween(d1, d2), 'Not yet passed anniversary');
        System.assertEquals(23, DateUtils.yearsBetween(d1, d3), 'Passed anniversary');
        
        // Leap year test
        Date leap1 = Date.newInstance(2000, 2, 29);
        Date nonLeap2 = Date.newInstance(2001, 2, 28);
        System.assertEquals(1, DateUtils.yearsBetween(leap1, nonLeap2), 'Leap year anniversary test');
    }

    @isTest
    static void testNextOccurrence() {
        Date d = Date.newInstance(2023, 10, 11); // Wednesday
        Date nextMonday = DateUtils.nextOccurrence(d, 1);
        System.assertEquals(Date.newInstance(2023, 10, 16), nextMonday, 'Next Monday is 16th');
        
        // Negative test (before 1900 benchmark)
        Date oldDate = Date.newInstance(1899, 12, 25); // Christmas 1899 was Monday
        Date nextSunday = DateUtils.nextOccurrence(oldDate, 7);
        System.assertEquals(Date.newInstance(1899, 12, 31), nextSunday, 'Next Sunday is 31st');
    }

    @isTest
    static void testFiscalYearLogic() {
        // Fiscal start = April (4)
        Date feb2023 = Date.newInstance(2023, 2, 10);
        Date apr2023 = Date.newInstance(2023, 4, 10);
        
        System.assertEquals(2022, DateUtils.getFiscalYear(feb2023, 4), 'Feb belongs to previous FY when FY starts in Apr');
        System.assertEquals(2023, DateUtils.getFiscalYear(apr2023, 4), 'Apr belongs to current FY');
        
        // Quarters
        // Apr-Jun = Q1, Jul-Sep = Q2, Oct-Dec = Q3, Jan-Mar = Q4
        System.assertEquals(4, DateUtils.getFiscalQuarter(feb2023, 4), 'Feb is Q4');
        System.assertEquals(1, DateUtils.getFiscalQuarter(apr2023, 4), 'Apr is Q1');
        System.assertEquals(3, DateUtils.getFiscalQuarter(Date.newInstance(2023, 12, 1), 4), 'Dec is Q3');
    }

    @isTest
    static void testParsingAndFormatting() {
        Datetime dt = DateUtils.parseISO8601('2023-10-15T15:30:00Z');
        System.assertEquals(2023, dt.yearGmt(), 'Should parse ISO8601 Year');
        System.assertEquals(10, dt.monthGmt(), 'Should parse ISO8601 Month');
        
        String formatted = DateUtils.formatToLocale(dt, 'yyyy/MM/dd');
        System.assert(formatted.contains('2023'), 'Format should output correctly');
    }
    
    @isTest
    static void testExceptions() {
        Boolean caught = false;
        try {
            DateUtils.isWeekend(null);
        } catch (IllegalArgumentException e) {
            caught = true;
        }
        System.assert(caught, 'Should catch null exception');
    }
}