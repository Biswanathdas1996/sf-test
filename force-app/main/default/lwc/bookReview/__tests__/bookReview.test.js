import { createElement } from "lwc";
import BookReview from "c/bookReview";
import getReviewsForBook from "@salesforce/apex/BookController.getReviewsForBook";
import getBookById from "@salesforce/apex/BookController.getBookById";
import createReview from "@salesforce/apex/BookController.createReview";

// eslint-disable-next-line no-unused-vars
const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");

jest.mock(
  "@salesforce/apex/BookController.getReviewsForBook",
  () => {
    const {
      createApexTestWireAdapter: createAdapter
    } = require("@salesforce/sfdx-lwc-jest");
    return { default: createAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/BookController.getBookById",
  () => {
    const {
      createApexTestWireAdapter: createAdapter
    } = require("@salesforce/sfdx-lwc-jest");
    return { default: createAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/BookController.createReview",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex",
  () => ({ refreshApex: jest.fn().mockResolvedValue(undefined) }),
  { virtual: true }
);

const MOCK_BOOK = {
  Id: "a00000000000001AAA",
  Name: "Test Book",
  Author__c: "Test Author",
  Description__c: "A test book",
  Price__c: 19.99
};

const MOCK_REVIEWS = [
  {
    Id: "a01000000000001AAA",
    Book__c: "a00000000000001AAA",
    Reviewer_Name__c: "Alice",
    Rating__c: "5",
    Comment__c: "Excellent book!",
    Review_Date__c: "2026-01-15"
  },
  {
    Id: "a01000000000002AAA",
    Book__c: "a00000000000001AAA",
    Reviewer_Name__c: "Bob",
    Rating__c: "3",
    Comment__c: "Average read.",
    Review_Date__c: "2026-02-10"
  }
];

// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-book-review", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent(bookId = "a00000000000001AAA") {
    const element = createElement("c-book-review", { is: BookReview });
    element.bookId = bookId;
    document.body.appendChild(element);
    return element;
  }

  it("displays modal with book name in header", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const heading = element.shadowRoot.querySelector(".modal-title");
    expect(heading).not.toBeNull();
    expect(heading.textContent).toContain("Test Book");
  });

  it("displays reviews when data is available", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const reviewItems = element.shadowRoot.querySelectorAll(".review-item");
    expect(reviewItems.length).toBe(2);
  });

  it("displays reviewer names and comments", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const reviewerNames = element.shadowRoot.querySelectorAll(".reviewer-name");
    expect(reviewerNames.length).toBe(2);
    expect(reviewerNames[0].textContent.trim()).toBe("Alice");
    expect(reviewerNames[1].textContent.trim()).toBe("Bob");

    const comments = element.shadowRoot.querySelectorAll(".review-comment");
    expect(comments[0].textContent).toBe("Excellent book!");
  });

  it("calculates and displays average rating", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const avgRating = element.shadowRoot.querySelector(".average-rating");
    expect(avgRating).not.toBeNull();
    expect(avgRating.textContent).toBe("4.0");
  });

  it("shows no reviews message when there are no reviews", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit([]);

    await flushPromises();

    const noReviewsText = element.shadowRoot.querySelector(".no-reviews-text");
    expect(noReviewsText).not.toBeNull();
    expect(noReviewsText.textContent).toContain("No reviews yet");
  });

  it("shows review form when Write a Review button is clicked", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const writeBtn = element.shadowRoot.querySelector(".write-review-btn");
    expect(writeBtn).not.toBeNull();

    writeBtn.click();
    await flushPromises();

    const reviewForm = element.shadowRoot.querySelector(".review-form");
    expect(reviewForm).not.toBeNull();
  });

  it("dispatches closereview event when close button is clicked", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const handler = jest.fn();
    element.addEventListener("closereview", handler);

    const closeBtn = element.shadowRoot.querySelector(
      ".modal-footer lightning-button"
    );
    closeBtn.click();

    expect(handler).toHaveBeenCalled();
  });

  it("displays rating text for each review", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const ratingTexts = element.shadowRoot.querySelectorAll(".rating-text");
    expect(ratingTexts.length).toBe(2);
    expect(ratingTexts[0].textContent).toBe("5/5");
    expect(ratingTexts[1].textContent).toBe("3/5");
  });

  it("displays review count", async () => {
    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    const countText = element.shadowRoot.querySelector(".review-count-text");
    expect(countText).not.toBeNull();
    expect(countText.textContent).toContain("2");
    expect(countText.textContent).toContain("reviews");
  });

  it("calls createReview apex when form is submitted", async () => {
    createReview.mockResolvedValue({
      Id: "a01000000000003AAA",
      Rating__c: "4",
      Comment__c: "Nice!",
      Reviewer_Name__c: "Charlie"
    });

    const element = await createComponent();

    getBookById.emit(MOCK_BOOK);
    getReviewsForBook.emit(MOCK_REVIEWS);

    await flushPromises();

    // Open the form
    const writeBtn = element.shadowRoot.querySelector(".write-review-btn");
    writeBtn.click();
    await flushPromises();

    // Fill in the form fields
    const nameInput = element.shadowRoot.querySelector("lightning-input");
    nameInput.value = "Charlie";
    nameInput.dispatchEvent(
      new CustomEvent("change", { target: { value: "Charlie" } })
    );

    const ratingCombo = element.shadowRoot.querySelector("lightning-combobox");
    ratingCombo.value = "4";
    ratingCombo.dispatchEvent(
      new CustomEvent("change", { detail: { value: "4" } })
    );

    const commentTextarea =
      element.shadowRoot.querySelector("lightning-textarea");
    commentTextarea.value = "Nice!";
    commentTextarea.dispatchEvent(
      new CustomEvent("change", { target: { value: "Nice!" } })
    );

    await flushPromises();

    // Submit the form
    const submitBtn = element.shadowRoot.querySelector(".submit-btn");
    submitBtn.click();
    await flushPromises();

    expect(createReview).toHaveBeenCalledWith({
      bookId: "a00000000000001AAA",
      rating: "4",
      comment: "Nice!",
      reviewerName: "Charlie"
    });
  });
});
