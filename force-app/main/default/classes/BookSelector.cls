/**
 * Selector class for Book__c object
 * Centralizes all SOQL queries for Book__c following Salesforce best practices
 */
public with sharing class BookSelector {

    /**
     * Get all books with required fields for display
     * @return List of Book__c records
     */
    public static List<Book__c> getAllBooks() {
        return [
            SELECT Id, Name, Author__c, Description__c, Price__c,
                   Cover_Image__c, Published_Date__c
            FROM Book__c
            WITH SECURITY_ENFORCED
            ORDER BY Published_Date__c DESC NULLS LAST, Name
        ];
    }

    /**
     * Get books by Ids
     * @param bookIds Set of Book Ids
     * @return List of Book__c records
     */
    public static List<Book__c> getBooksById(Set<Id> bookIds) {
        if (bookIds == null || bookIds.isEmpty()) {
            return new List<Book__c>();
        }

        return [
            SELECT Id, Name, Author__c, Description__c, Price__c,
                   Cover_Image__c, Published_Date__c
            FROM Book__c
            WHERE Id IN :bookIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Get book by single Id
     * @param bookId Book Id
     * @return Book__c record or null
     */
    public static Book__c getBookById(Id bookId) {
        if (bookId == null) {
            return null;
        }

        List<Book__c> books = getBooksById(new Set<Id>{ bookId });
        return books.isEmpty() ? null : books[0];
    }
}