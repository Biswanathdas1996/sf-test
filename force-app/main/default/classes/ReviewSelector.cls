/**
 * Selector class for Review__c object
 * Centralizes all SOQL queries for Review__c following Salesforce best practices
 */
public with sharing class ReviewSelector {

    /**
     * Get reviews by Book Ids
     * @param bookIds Set of Book Ids
     * @return List of Review__c records
     */
    public static List<Review__c> getReviewsByBookIds(Set<Id> bookIds) {
        if (bookIds == null || bookIds.isEmpty()) {
            return new List<Review__c>();
        }

        return [
            SELECT Id, Name, Book__c, Reviewer_Name__c, Rating__c,
                   Comment__c, Review_Date__c
            FROM Review__c
            WHERE Book__c IN :bookIds
            WITH SECURITY_ENFORCED
            ORDER BY Review_Date__c DESC NULLS LAST, CreatedDate DESC
        ];
    }

    /**
     * Get reviews for a single book
     * @param bookId Book Id
     * @return List of Review__c records
     */
    public static List<Review__c> getReviewsByBookId(Id bookId) {
        if (bookId == null) {
            return new List<Review__c>();
        }

        return getReviewsByBookIds(new Set<Id>{ bookId });
    }

    /**
     * Get review by Id
     * @param reviewId Review Id
     * @return Review__c record or null
     */
    public static Review__c getReviewById(Id reviewId) {
        if (reviewId == null) {
            return null;
        }

        List<Review__c> reviews = [
            SELECT Id, Name, Book__c, Reviewer_Name__c, Rating__c,
                   Comment__c, Review_Date__c
            FROM Review__c
            WHERE Id = :reviewId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return reviews.isEmpty() ? null : reviews[0];
    }
}