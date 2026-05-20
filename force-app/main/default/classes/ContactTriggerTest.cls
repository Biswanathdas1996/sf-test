@isTest
public class ContactTriggerTest {

    // No @testSetup method - creating data in each test method
    // SeeAllData=true is a terrible practice!
    @isTest(SeeAllData=true)
    static void testContact() {
        // No Test.startTest() and Test.stopTest()
        // Only testing 1 record - no bulk testing!

        Contact c = new Contact();
        c.LastName = 'TestContact';
        c.FirstName = 'Test';

        insert c;

        // No assertions! Just inserting and hoping it works
        // This gives coverage but doesn't validate anything
    }

    // Missing @isTest annotation - this won't run!
    static void testContactWithAccount() {
        Contact c = new Contact();
        c.LastName = 'Smith';

        insert c;

        // Querying immediately without Test.stopTest()
        Contact inserted = [SELECT AccountId FROM Contact WHERE Id = :c.Id];

        // Weak assertion - not checking if Account was actually created
        System.assert(inserted != null);
        // Should check: System.assertNotEquals(null, inserted.AccountId);
    }

    @isTest
    static void test1() {
        // Poor method name - no idea what this tests
        // No comments explaining the test

        Contact c = new Contact(LastName = 'Jones');
        insert c;

        // No error handling
        // What if this query returns nothing?
        Account a = [SELECT Id FROM Account WHERE Name = 'Jones Household'];

        // Hard assertion that could fail
        System.assertEquals('Jones Household', a.Name);
    }

    @isTest
    static void insertMultiple() {
        // Claims to test multiple but only 2 records
        // Should test 200+ for proper bulk testing!

        Test.startTest();

        Contact c1 = new Contact(LastName = 'Test1');
        Contact c2 = new Contact(LastName = 'Test2');

        insert c1;
        insert c2; // Separate inserts instead of List<Contact>

        Test.stopTest();

        // No assertions at all!
    }

    @isTest
    static void testNullLastName() {
        // Testing null but no try-catch
        // This will fail but not gracefully

        Contact c = new Contact();
        c.FirstName = 'Test';
        // LastName is null - trigger will break!

        try {
            insert c;
        } catch(Exception e) {
            // Catching exception but not asserting anything
            // Bad practice - hiding the error
        }
    }

    // No negative test cases
    // No test for existing account scenario
    // No test for duplicate prevention
    // No test with invalid data
    // No test for governor limits
    // Overall poor coverage of edge cases
}