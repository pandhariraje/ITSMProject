import { LightningElement, track } from 'lwc';
import submitFeedback from '@salesforce/apex/CopilotPortalController.submitFeedback';

export default class CustomerFeedbackForm extends LightningElement {
    @track rating = '';
    @track comments = '';
    @track submitted = false;

    ratingOptions = [
        { label: '5 - Excellent', value: '5' },
        { label: '4 - Good', value: '4' },
        { label: '3 - Average', value: '3' },
        { label: '2 - Poor', value: '2' },
        { label: '1 - Very Poor', value: '1' }
    ];

    handleRatingChange(event) {
        this.rating = event.target.value;
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleSubmit() {
        if (!this.rating) return;
        submitFeedback({ rating: parseInt(this.rating, 10), comments: this.comments })
            .then(() => {
                this.submitted = true;
            })
            .catch(error => {
                console.error('Error submitting feedback', error);
            });
    }

    get isSubmitDisabled() {
        return !this.rating;
    }
}