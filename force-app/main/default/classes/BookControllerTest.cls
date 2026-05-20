/**
 * Test class for BookController
 * Tests all @AuraEnabled methods with positive and negative scenarios
 */
@isTest
private class BookControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create test books
        List<Book__c> books = new List<Book__c>();
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

        // Create reviews for first 5 books
        List<Review__c> reviews = new List<Review__c>();
        List<Book__c> booksWithReviews = [SELECT Id FROM Book__c LIMIT 5];

        for (Book__c book : booksWithReviews) {
            for (Integer i = 1; i <= 10; i++) {
                reviews.add(new Review__c(
                    Book__c = book.Id,
                    Reviewer_Name__c = 'Reviewer ' + i,
                    Rating__c = String.valueOf(Math.mod(i, 5) + 1),
                    Comment__c = 'This is a test review comment ' + i,
                    Review_Date__c = Date.today().addDays(-i)
                ));
            }
        }
        insert reviews;
    }

    @isTest
    static void testGetAllBooks_Success() {
        Test.startTest();
        List<Book__c> books = BookController.getAllBooks();
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
    static void testGetAllBooks_BulkData() {
        Test.startTest();
        List<Book__c> books = BookController.getAllBooks();
        Test.stopTest();

        System.assert(books.size() > 200, 'Should handle bulk retrieval of 200+ records');
    }

    @isTest
    static void testGetReviewsForBook_Success() {
        Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];

        Test.startTest();
        List<Review__c> reviews = BookController.getReviewsForBook(testBook.Id);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(10, reviews.size(), 'Should return 10 reviews');

        // Verify all reviews belong to the book
        for (Review__c review : reviews) {
            System.assertEquals(testBook.Id, review.Book__c, 'All reviews should belong to the requested book');
            System.assertNotEquals(null, review.Reviewer_Name__c, 'Reviewer name should not be null');
            System.assertNotEquals(null, review.Rating__c, 'Rating should not be null');
        }
    }

    @isTest
    static void testGetReviewsForBook_NoReviews() {
        // Get a book that has no reviews (beyond the first 5)
        Book__c bookWithoutReviews = [SELECT Id FROM Book__c ORDER BY Name DESC LIMIT 1];

        Test.startTest();
        List<Review__c> reviews = BookController.getReviewsForBook(bookWithoutReviews.Id);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(0, reviews.size(), 'Should return empty list when no reviews exist');
    }

    @isTest
    static void testGetReviewsForBook_NullBookId() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            BookController.getReviewsForBook(null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw AuraHandledException for null book ID');
        System.assert(
            exceptionMessage.contains('Book ID is required'),
            'Exception message should indicate book ID is required'
        );
    }

    @isTest
    static void testGetBookById_Success() {
        Book__c testBook = [SELECT Id, Name FROM Book__c LIMIT 1];

        Test.startTest();
        Book__c book = BookController.getBookById(testBook.Id);
        Test.stopTest();

        System.assertNotEquals(null, book, 'Book should not be null');
        System.assertEquals(testBook.Id, book.Id, 'Should return the correct book');
        System.assertEquals(testBook.Name, book.Name, 'Book name should match');
        System.assertNotEquals(null, book.Author__c, 'Author should be populated');
    }

    @isTest
    static void testGetBookById_NullId() {
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            BookController.getBookById(null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw AuraHandledException for null ID');
        System.assert(
            exceptionMessage.contains('Book ID is required'),
            'Exception message should indicate book ID is required'
        );
    }

    @isTest
    static void testGetBookById_NonExistentId() {
        // Create a fake ID that doesn't exist
        Id fakeId = 'a00000000000000AAA';
        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            BookController.getBookById(fakeId);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Should throw AuraHandledException for non-existent book');
        System.assert(
            exceptionMessage.contains('Book not found') || exceptionMessage.contains('Error'),
            'Exception message should indicate book was not found'
        );
    }

    @isTest
    static void testCacheable_GetAllBooks() {
        // Test that the method is cacheable
        Test.startTest();
        List<Book__c> books1 = BookController.getAllBooks();
        List<Book__c> books2 = BookController.getAllBooks();
        Test.stopTest();

        System.assertEquals(books1.size(), books2.size(), 'Cacheable method should return consistent results');
    }

    @isTest
    static void testCacheable_GetReviewsForBook() {
        Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];

        Test.startTest();
        List<Review__c> reviews1 = BookController.getReviewsForBook(testBook.Id);
        List<Review__c> reviews2 = BookController.getReviewsForBook(testBook.Id);
        Test.stopTest();

        System.assertEquals(reviews1.size(), reviews2.size(), 'Cacheable method should return consistent results');
    }
}