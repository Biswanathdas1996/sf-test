/**
 * Test class for ReviewSelector
 * Tests all SOQL query methods with bulk data
 */
@isTest
private class ReviewSelectorTest {

    @TestSetup
    static void setupTestData() {
        // Create test books
        List<Book__c> books = new List<Book__c>();
        for (Integer i = 1; i <= 10; i++) {
            books.add(new Book__c(
                Name = 'Test Book ' + i,
                Author__c = 'Test Author ' + i,
                Description__c = 'Test Description ' + i,
                Price__c = 10.00 + i,
                Published_Date__c = Date.today().addDays(-i)
            ));
        }
        insert books;

        // Create 200+ reviews for bulk testing
        List<Review__c> reviews = new List<Review__c>();
        Integer reviewCount = 0;
        for (Book__c book : books) {
            for (Integer i = 1; i <= 21; i++) {
                reviewCount++;
                reviews.add(new Review__c(
                    Book__c = book.Id,
                    Reviewer_Name__c = 'Reviewer ' + reviewCount,
                    Rating__c = String.valueOf(Math.mod(i, 5) + 1),
                    Comment__c = 'This is a test review comment ' + reviewCount,
                    Review_Date__c = Date.today().addDays(-i)
                ));
            }
        }
        insert reviews;
    }

    @isTest
    static void testGetReviewsByBookIds_Success() {
        List<Book__c> testBooks = [SELECT Id FROM Book__c LIMIT 3];
        Set<Id> bookIds = new Set<Id>();
        for (Book__c book : testBooks) {
            bookIds.add(book.Id);
        }

        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookIds(bookIds);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(63, reviews.size(), 'Should return 63 reviews (21 per book × 3 books)');

        // Verify all reviews belong to requested books
        for (Review__c review : reviews) {
            System.assert(bookIds.contains(review.Book__c), 'Review should belong to requested books');
            System.assertNotEquals(null, review.Reviewer_Name__c, 'Reviewer name should not be null');
        }
    }

    @isTest
    static void testGetReviewsByBookIds_BulkQuery() {
        List<Book__c> testBooks = [SELECT Id FROM Book__c];
        Set<Id> bookIds = new Set<Id>();
        for (Book__c book : testBooks) {
            bookIds.add(book.Id);
        }

        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookIds(bookIds);
        Test.stopTest();

        System.assertEquals(210, reviews.size(), 'Should handle bulk query of 210 reviews');
    }

    @isTest
    static void testGetReviewsByBookIds_OrderedCorrectly() {
        Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];

        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookIds(new Set<Id>{ testBook.Id });
        Test.stopTest();

        // Verify reviews are ordered by Review_Date__c DESC
        System.assert(reviews.size() > 1, 'Should have multiple reviews to test ordering');

        Date previousDate = reviews[0].Review_Date__c;
        for (Integer i = 1; i < Math.min(10, reviews.size()); i++) {
            Date currentDate = reviews[i].Review_Date__c;
            System.assert(
                previousDate >= currentDate,
                'Reviews should be ordered by review date descending'
            );
            previousDate = currentDate;
        }
    }

    @isTest
    static void testGetReviewsByBookIds_EmptySet() {
        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookIds(new Set<Id>());
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(0, reviews.size(), 'Should return empty list for empty set');
    }

    @isTest
    static void testGetReviewsByBookIds_NullSet() {
        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookIds(null);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(0, reviews.size(), 'Should return empty list for null set');
    }

    @isTest
    static void testGetReviewsByBookId_Success() {
        Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];

        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookId(testBook.Id);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(21, reviews.size(), 'Should return 21 reviews for the book');

        // Verify all reviews belong to the book
        for (Review__c review : reviews) {
            System.assertEquals(testBook.Id, review.Book__c, 'All reviews should belong to the requested book');
        }
    }

    @isTest
    static void testGetReviewsByBookId_NullId() {
        Test.startTest();
        List<Review__c> reviews = ReviewSelector.getReviewsByBookId(null);
        Test.stopTest();

        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
        System.assertEquals(0, reviews.size(), 'Should return empty list for null Id');
    }

    @isTest
    static void testGetReviewById_Success() {
        Review__c testReview = [SELECT Id, Reviewer_Name__c FROM Review__c LIMIT 1];

        Test.startTest();
        Review__c review = ReviewSelector.getReviewById(testReview.Id);
        Test.stopTest();

        System.assertNotEquals(null, review, 'Review should not be null');
        System.assertEquals(testReview.Id, review.Id, 'Should return the correct review');
        System.assertNotEquals(null, review.Book__c, 'Book reference should be populated');
    }

    @isTest
    static void testGetReviewById_NullId() {
        Test.startTest();
        Review__c review = ReviewSelector.getReviewById(null);
        Test.stopTest();

        System.assertEquals(null, review, 'Should return null for null Id');
    }

    @isTest
    static void testGetReviewById_NonExistentId() {
        // Create a fake ID that doesn't exist
        Id fakeId = 'a01000000000000AAA';

        Test.startTest();
        Review__c review = ReviewSelector.getReviewById(fakeId);
        Test.stopTest();

        System.assertEquals(null, review, 'Should return null for non-existent Id');
    }
}