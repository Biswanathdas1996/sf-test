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
      books.add(
        new Book__c(
          Name = 'Test Book ' + i,
          Author__c = 'Test Author ' + Math.mod(i, 10),
          Description__c = 'Test Description for book ' + i,
          Price__c = 10.00 + i,
          Cover_Image__c = 'https://example.com/book' + i + '.jpg',
          Published_Date__c = Date.today().addDays(-i)
        )
      );
    }
    insert books;

    // Create reviews for first 5 books
    List<Review__c> reviews = new List<Review__c>();
    List<Book__c> booksWithReviews = [SELECT Id FROM Book__c LIMIT 5];

    for (Book__c book : booksWithReviews) {
      for (Integer i = 1; i <= 10; i++) {
        reviews.add(
          new Review__c(
            Book__c = book.Id,
            Reviewer_Name__c = 'Reviewer ' + i,
            Rating__c = String.valueOf(Math.mod(i, 5) + 1),
            Comment__c = 'This is a test review comment ' + i,
            Review_Date__c = Date.today().addDays(-i)
          )
        );
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

    System.assert(
      books.size() > 200,
      'Should handle bulk retrieval of 200+ records'
    );
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
      System.assertEquals(
        testBook.Id,
        review.Book__c,
        'All reviews should belong to the requested book'
      );
      System.assertNotEquals(
        null,
        review.Reviewer_Name__c,
        'Reviewer name should not be null'
      );
      System.assertNotEquals(
        null,
        review.Rating__c,
        'Rating should not be null'
      );
    }
  }

  @isTest
  static void testGetReviewsForBook_NoReviews() {
    // Get a book that has no reviews (beyond the first 5)
    Book__c bookWithoutReviews = [
      SELECT Id
      FROM Book__c
      ORDER BY Name DESC
      LIMIT 1
    ];

    Test.startTest();
    List<Review__c> reviews = BookController.getReviewsForBook(
      bookWithoutReviews.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, reviews, 'Reviews list should not be null');
    System.assertEquals(
      0,
      reviews.size(),
      'Should return empty list when no reviews exist'
    );
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

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for null book ID'
    );
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

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for null ID'
    );
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

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for non-existent book'
    );
    System.assert(
      exceptionMessage.contains('Book not found') ||
      exceptionMessage.contains('Error'),
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

    System.assertEquals(
      books1.size(),
      books2.size(),
      'Cacheable method should return consistent results'
    );
  }

  @isTest
  static void testCacheable_GetReviewsForBook() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];

    Test.startTest();
    List<Review__c> reviews1 = BookController.getReviewsForBook(testBook.Id);
    List<Review__c> reviews2 = BookController.getReviewsForBook(testBook.Id);
    Test.stopTest();

    System.assertEquals(
      reviews1.size(),
      reviews2.size(),
      'Cacheable method should return consistent results'
    );
  }

  @isTest
  static void testCreateReview_Success() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Integer reviewsBefore = [
      SELECT COUNT()
      FROM Review__c
      WHERE Book__c = :testBook.Id
    ];

    Test.startTest();
    Review__c review = BookController.createReview(
      testBook.Id,
      '4',
      'Great book!',
      'Test User'
    );
    Test.stopTest();

    System.assertNotEquals(null, review, 'Created review should not be null');
    System.assertNotEquals(null, review.Id, 'Created review should have an Id');
    System.assertEquals(
      testBook.Id,
      review.Book__c,
      'Review should be linked to the book'
    );
    System.assertEquals('4', review.Rating__c, 'Rating should match');
    System.assertEquals(
      'Great book!',
      review.Comment__c,
      'Comment should match'
    );
    System.assertEquals(
      'Test User',
      review.Reviewer_Name__c,
      'Reviewer name should match'
    );
    System.assertEquals(
      Date.today(),
      review.Review_Date__c,
      'Review date should be today'
    );

    Integer reviewsAfter = [
      SELECT COUNT()
      FROM Review__c
      WHERE Book__c = :testBook.Id
    ];
    System.assertEquals(
      reviewsBefore + 1,
      reviewsAfter,
      'Should have one more review'
    );
  }

  @isTest
  static void testCreateReview_NullBookId() {
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(null, '3', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for null book ID'
    );
    System.assert(
      exceptionMessage.contains('Book ID is required'),
      'Exception message should indicate book ID is required'
    );
  }

  @isTest
  static void testCreateReview_BlankRating() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for blank rating'
    );
    System.assert(
      exceptionMessage.contains('Rating is required'),
      'Exception message should indicate rating is required'
    );
  }

  @isTest
  static void testCreateReview_BlankComment() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '3', '', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for blank comment'
    );
    System.assert(
      exceptionMessage.contains('Comment is required'),
      'Exception message should indicate comment is required'
    );
  }

  @isTest
  static void testCreateReview_BlankReviewerName() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '3', 'Comment', '');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for blank reviewer name'
    );
    System.assert(
      exceptionMessage.contains('Reviewer name is required'),
      'Exception message should indicate reviewer name is required'
    );
  }

  @isTest
  static void testCreateReview_InvalidRating() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '6', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for invalid rating'
    );
    System.assert(
      exceptionMessage.contains('Rating must be between 1 and 5'),
      'Exception message should indicate valid rating range'
    );
  }

  @isTest
  static void testCreateReview_RatingBelowMinimum() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '0', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for rating below minimum'
    );
    System.assert(
      exceptionMessage.contains('Rating must be between 1 and 5'),
      'Exception message should indicate valid rating range'
    );

    // Verify no review was created
    Integer reviewCount = [
      SELECT COUNT()
      FROM Review__c
      WHERE Book__c = :testBook.Id
    ];
    System.assertEquals(
      10,
      reviewCount,
      'Should not create review with invalid rating'
    );
  }

  @isTest
  static void testCreateReview_NonNumericRating() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, 'abc', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for non-numeric rating'
    );
    System.assert(
      exceptionMessage.contains('Error creating review') ||
        exceptionMessage.contains('Invalid') ||
        exceptionMessage.contains('Rating'),
      'Exception message should indicate rating error'
    );

    // Verify no review was created
    Integer reviewCount = [
      SELECT COUNT()
      FROM Review__c
      WHERE Book__c = :testBook.Id
    ];
    System.assertEquals(
      10,
      reviewCount,
      'Should not create review with non-numeric rating'
    );
  }

  @isTest
  static void testCreateReview_NegativeRating() {
    Book__c testBook = [SELECT Id FROM Book__c LIMIT 1];
    Boolean exceptionThrown = false;
    String exceptionMessage = '';

    Test.startTest();
    try {
      BookController.createReview(testBook.Id, '-1', 'Comment', 'Reviewer');
      System.assert(false, 'Should have thrown AuraHandledException');
    } catch (AuraHandledException e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();

    System.assert(
      exceptionThrown,
      'Should throw AuraHandledException for negative rating'
    );
    System.assert(
      exceptionMessage.contains('Rating must be between 1 and 5'),
      'Exception message should indicate valid rating range'
    );
  }
}
