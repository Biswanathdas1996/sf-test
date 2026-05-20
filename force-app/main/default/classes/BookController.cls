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
            throw new AuraHandledException('Error retrieving books: ' + e.getMessage());
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
            throw new AuraHandledException('Error retrieving reviews: ' + e.getMessage());
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
            throw new AuraHandledException('Error retrieving book: ' + e.getMessage());
        }
    }
}