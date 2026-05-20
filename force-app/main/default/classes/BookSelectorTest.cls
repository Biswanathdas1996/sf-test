/**
 * Test class for BookSelector
 * Tests all SOQL query methods with bulk data
 */
@isTest
private class BookSelectorTest {

    @TestSetup
    static void setupTestData() {
        List<Book__c> books = new List<Book__c>();

        // Create 200+ books for bulk testing
        for (Integer i = 1; i <= 205; i++) {
            books.add(new Book__c(
                Name = 'Test Book ' + i,
                Author__c = 'Test Author ' + Math.mod(i, 10),
                Description__c = 'Test Description for book ' + i,
                Price__c = 10.00 + i,
                Cover_Image__c = 'https://example.com/book' + i + '.jpg',
                Published_Date__c = Date.today().addDays(-i)
            ));
        }

        insert books;
    }

    @isTest
    static void testGetAllBooks_Success() {
        Test.startTest();
        List<Book__c> books = BookSelector.getAllBooks();
        Test.stopTest();

        System.assertNotEquals(null, books, 'Books list should not be null');
        System.assertEquals(205, books.size(), 'Should return all 205 books');

        // Verify fields are populated
        for (Book__c book : books) {
            System.assertNotEquals(null, book.Name, 'Book name should not be null');
            System.assertNotEquals(null, book.Author__c, 'Author should not be null');
        }
    }

    @isTest
    static void testGetAllBooks_OrderedCorrectly() {
        Test.startTest();
        List<Book__c> books = BookSelector.getAllBooks();
        Test.stopTest();

        // Verify books are ordered by Published_Date__c DESC
        System.assert(books.size() > 1, 'Should have multiple books to test ordering');

        Date previousDate = books[0].Published_Date__c;
        for (Integer i = 1; i < Math.min(10, books.size()); i++) {
            Date currentDate = books[i].Published_Date__c;
            System.assert(
                previousDate >= currentDate,
                'Books should be ordered by published date descending'
            );
            previousDate = currentDate;
        }
    }

    @isTest
    static void testGetBooksById_Success() {
        List<Book__c> testBooks = [SELECT Id FROM Book__c LIMIT 5];
        Set<Id> bookIds = new Set<Id>();
        for (Book__c book : testBooks) {
            bookIds.add(book.Id);
        }

        Test.startTest();
        List<Book__c> books = BookSelector.getBooksById(bookIds);
        Test.stopTest();

        System.assertNotEquals(null, books, 'Books list should not be null');
        System.assertEquals(5, books.size(), 'Should return exactly 5 books');

        // Verify all requested books are returned
        Set<Id> returnedIds = new Set<Id>();
        for (Book__c book : books) {
            returnedIds.add(book.Id);
        }
        System.assertEquals(bookIds, returnedIds, 'Should return exactly the requested books');
    }

    @isTest
    static void testGetBooksById_BulkQuery() {
        List<Book__c> testBooks = [SELECT Id FROM Book__c];
        Set<Id> bookIds = new Set<Id>();
        for (Book__c book : testBooks) {
            bookIds.add(book.Id);
        }

        Test.startTest();
        List<Book__c> books = BookSelector.getBooksById(bookIds);
        Test.stopTest();

        System.assertEquals(205, books.size(), 'Should handle bulk query of 205 records');
    }

    @isTest
    static void testGetBooksById_EmptySet() {
        Test.startTest();
        List<Book__c> books = BookSelector.getBooksById(new Set<Id>());
        Test.stopTest();

        System.assertNotEquals(null, books, 'Books list should not be null');
        System.assertEquals(0, books.size(), 'Should return empty list for empty set');
    }

    @isTest
    static void testGetBooksById_NullSet() {
        Test.startTest();
        List<Book__c> books = BookSelector.getBooksById(null);
        Test.stopTest();

        System.assertNotEquals(null, books, 'Books list should not be null');
        System.assertEquals(0, books.size(), 'Should return empty list for null set');
    }

    @isTest
    static void testGetBookById_Success() {
        Book__c testBook = [SELECT Id, Name FROM Book__c LIMIT 1];

        Test.startTest();
        Book__c book = BookSelector.getBookById(testBook.Id);
        Test.stopTest();

        System.assertNotEquals(null, book, 'Book should not be null');
        System.assertEquals(testBook.Id, book.Id, 'Should return the correct book');
        System.assertNotEquals(null, book.Name, 'Book name should be populated');
    }

    @isTest
    static void testGetBookById_NullId() {
        Test.startTest();
        Book__c book = BookSelector.getBookById(null);
        Test.stopTest();

        System.assertEquals(null, book, 'Should return null for null Id');
    }

    @isTest
    static void testGetBookById_NonExistentId() {
        // Create a fake ID that doesn't exist
        Id fakeId = 'a00000000000000AAA';

        Test.startTest();
        Book__c book = BookSelector.getBookById(fakeId);
        Test.stopTest();

        System.assertEquals(null, book, 'Should return null for non-existent Id');
    }
}