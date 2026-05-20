import { LightningElement, api, wire } from 'lwc';
import getReviewsForBook from '@salesforce/apex/BookController.getReviewsForBook';
import getBookById from '@salesforce/apex/BookController.getBookById';

export default class BookReview extends LightningElement {
    @api bookId;
    reviews = [];
    book;
    error;
    isLoadingReviews = true;
    isLoadingBook = true;

    @wire(getBookById, { bookId: '$bookId' })
    wiredBook({ error, data }) {
        this.isLoadingBook = false;
        if (data) {
            this.book = data;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getReviewsForBook, { bookId: '$bookId' })
    wiredReviews({ error, data }) {
        this.isLoadingReviews = false;
        if (data) {
            this.reviews = data.map((review) => ({
                ...review,
                stars: this.generateStars(review.Rating__c),
                formattedDate: this.formatDate(review.Review_Date__c)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.reviews = [];
        }
    }

    get isLoading() {
        return this.isLoadingBook || this.isLoadingReviews;
    }

    get hasReviews() {
        return this.reviews && this.reviews.length > 0;
    }

    get hasError() {
        return this.error !== undefined;
    }

    get reviewCount() {
        return this.reviews?.length || 0;
    }

    get averageRating() {
        if (!this.hasReviews) {
            return 0;
        }
        const sum = this.reviews.reduce((acc, review) => {
            return acc + (parseFloat(review.Rating__c) || 0);
        }, 0);
        return (sum / this.reviews.length).toFixed(1);
    }

    get averageStars() {
        return this.generateStars(this.averageRating);
    }

    generateStars(rating) {
        const stars = [];
        const ratingNum = parseFloat(rating) || 0;
        const fullStars = Math.floor(ratingNum);
        const hasHalfStar = ratingNum % 1 >= 0.5;

        for (let i = 1; i <= 5; i++) {
            if (i <= fullStars) {
                stars.push({ id: i, filled: true, half: false });
            } else if (i === fullStars + 1 && hasHalfStar) {
                stars.push({ id: i, filled: false, half: true });
            } else {
                stars.push({ id: i, filled: false, half: false });
            }
        }
        return stars;
    }

    formatDate(dateString) {
        if (!dateString) {
            return 'Unknown date';
        }
        return new Date(dateString).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closereview'));
    }
}