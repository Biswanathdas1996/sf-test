import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getReviewsForBook from "@salesforce/apex/BookController.getReviewsForBook";
import getBookById from "@salesforce/apex/BookController.getBookById";
import createReview from "@salesforce/apex/BookController.createReview";

export default class BookReview extends LightningElement {
  @api bookId;
  reviews = [];
  book;
  error;
  isLoadingReviews = true;
  isLoadingBook = true;

  showForm = false;
  isSubmitting = false;
  submitError;
  submitSuccess = false;

  reviewerName = "";
  rating = "";
  comment = "";

  wiredReviewsResult;

  ratingOptions = [
    { label: "1 - Poor", value: "1" },
    { label: "2 - Fair", value: "2" },
    { label: "3 - Good", value: "3" },
    { label: "4 - Very Good", value: "4" },
    { label: "5 - Excellent", value: "5" }
  ];

  @wire(getBookById, { bookId: "$bookId" })
  wiredBook({ error, data }) {
    this.isLoadingBook = false;
    if (data) {
      this.book = data;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getReviewsForBook, { bookId: "$bookId" })
  wiredReviews(result) {
    this.wiredReviewsResult = result;
    this.isLoadingReviews = false;
    if (result.data) {
      this.reviews = result.data.map((review) => ({
        ...review,
        stars: this.generateStars(review.Rating__c),
        formattedDate: this.formatDate(review.Review_Date__c)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = result.error;
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

  get isFormValid() {
    return (
      this.reviewerName.trim() !== "" &&
      this.rating !== "" &&
      this.comment.trim() !== ""
    );
  }

  get toggleButtonLabel() {
    return this.showForm ? "Cancel" : "Write a Review";
  }

  get toggleButtonVariant() {
    return this.showForm ? "neutral" : "brand";
  }

  get toggleButtonIcon() {
    return this.showForm ? "utility:close" : "utility:edit";
  }

  get submitButtonLabel() {
    return this.isSubmitting ? "Submitting..." : "Submit Review";
  }

  get reviewCountLabel() {
    const count = this.reviewCount;
    return count + (count === 1 ? " review" : " reviews");
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
      return "Unknown date";
    }
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric"
    });
  }

  handleToggleForm() {
    this.showForm = !this.showForm;
    this.submitError = undefined;
    this.submitSuccess = false;
  }

  handleReviewerNameChange(event) {
    this.reviewerName = event.target.value;
  }

  handleRatingChange(event) {
    this.rating = event.detail.value;
  }

  handleCommentChange(event) {
    this.comment = event.target.value;
  }

  async handleSubmitReview() {
    if (!this.isFormValid) {
      this.submitError = "Please fill in all fields.";
      return;
    }

    this.isSubmitting = true;
    this.submitError = undefined;
    this.submitSuccess = false;

    try {
      await createReview({
        bookId: this.bookId,
        rating: this.rating,
        comment: this.comment,
        reviewerName: this.reviewerName
      });

      this.submitSuccess = true;
      this.reviewerName = "";
      this.rating = "";
      this.comment = "";
      this.showForm = false;

      await refreshApex(this.wiredReviewsResult);
    } catch (error) {
      this.submitError =
        error.body?.message || "An error occurred while submitting the review.";
    } finally {
      this.isSubmitting = false;
    }
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("closereview"));
  }
}
