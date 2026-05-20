import { LightningElement, wire } from 'lwc';
import getAllBooks from '@salesforce/apex/BookController.getAllBooks';

export default class BookList extends LightningElement {
    books = [];
    selectedBookId;
    error;
    isLoading = true;

    @wire(getAllBooks)
    wiredBooks({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.books = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.books = [];
        }
    }

    get hasBooks() {
        return this.books && this.books.length > 0;
    }

    get hasError() {
        return this.error !== undefined;
    }

    handleBookSelect(event) {
        this.selectedBookId = event.detail.bookId;
    }

    handleCloseReviews() {
        this.selectedBookId = null;
    }
}