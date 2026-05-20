/**
 * Controller class for Book and Review Lightning Web Components
 * Handles data retrieval for LWC components
 */
public with sharing class BookController {
  /**
   * Get all books for display in book list
   * @return List of Book__c records
   */
  @AuraEnabled(cacheable=true)
  public static List<Book__c> getAllBooks() {
    try {
      return BookSelector.getAllBooks();
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error retrieving books: ' + e.getMessage()
      );
    }
  }

  /**
   * Get reviews for a specific book
   * @param bookId Id of the book
   * @return List of Review__c records
   */
  @AuraEnabled(cacheable=true)
  public static List<Review__c> getReviewsForBook(Id bookId) {
    try {
      if (bookId == null) {
        throw new AuraHandledException('Book ID is required');
      }
      return ReviewSelector.getReviewsByBookId(bookId);
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error retrieving reviews: ' + e.getMessage()
      );
    }
  }

  /**
   * Create a new review for a book
   * @param bookId Id of the book being reviewed
   * @param rating Rating value (1-5)
   * @param comment Review comment text
   * @param reviewerName Name of the reviewer
   * @return The created Review__c record
   */
  @AuraEnabled
  public static Review__c createReview(
    Id bookId,
    String rating,
    String comment,
    String reviewerName
  ) {
    try {
      if (bookId == null) {
        throw new AuraHandledException('Book ID is required');
      }
      if (String.isBlank(rating)) {
        throw new AuraHandledException('Rating is required');
      }
      if (String.isBlank(comment)) {
        throw new AuraHandledException('Comment is required');
      }
      if (String.isBlank(reviewerName)) {
        throw new AuraHandledException('Reviewer name is required');
      }

      Integer ratingValue = Integer.valueOf(rating);
      if (ratingValue < 1 || ratingValue > 5) {
        throw new AuraHandledException('Rating must be between 1 and 5');
      }

      Review__c review = new Review__c(
        Book__c = bookId,
        Rating__c = rating,
        Comment__c = comment,
        Reviewer_Name__c = reviewerName,
        Review_Date__c = Date.today()
      );
      insert review;
      return review;
    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error creating review: ' + e.getMessage()
      );
    }
  }

  /**
   * Get book details by Id
   * @param bookId Id of the book
   * @return Book__c record
   */
  @AuraEnabled(cacheable=true)
  public static Book__c getBookById(Id bookId) {
    try {
      if (bookId == null) {
        throw new AuraHandledException('Book ID is required');
      }
      Book__c book = BookSelector.getBookById(bookId);
      if (book == null) {
        throw new AuraHandledException('Book not found');
      }
      return book;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error retrieving book: ' + e.getMessage()
      );
    }
  }
}
