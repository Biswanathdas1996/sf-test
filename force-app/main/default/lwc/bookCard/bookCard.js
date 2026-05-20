import { LightningElement, api } from 'lwc';

export default class BookCard extends LightningElement {
    @api book;

    get formattedPrice() {
        return this.book?.Price__c
            ? new Intl.NumberFormat('en-US', {
                  style: 'currency',
                  currency: 'USD'
              }).format(this.book.Price__c)
            : 'N/A';
    }

    get formattedDate() {
        if (!this.book?.Published_Date__c) {
            return 'Unknown';
        }
        return new Date(this.book.Published_Date__c).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    get coverImageUrl() {
        return this.book?.Cover_Image__c || 'https://via.placeholder.com/200x300?text=No+Cover';
    }

    get truncatedDescription() {
        const maxLength = 150;
        if (!this.book?.Description__c) {
            return 'No description available.';
        }
        return this.book.Description__c.length > maxLength
            ? this.book.Description__c.substring(0, maxLength) + '...'
            : this.book.Description__c;
    }

    handleCardClick() {
        const selectEvent = new CustomEvent('bookselect', {
            detail: {
                bookId: this.book.Id
            }
        });
        this.dispatchEvent(selectEvent);
    }

    handleKeyPress(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleCardClick();
        }
    }
}