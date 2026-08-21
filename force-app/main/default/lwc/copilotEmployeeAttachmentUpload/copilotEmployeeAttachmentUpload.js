import { LightningElement, api } from 'lwc';

export default class CopilotEmployeeAttachmentUpload extends LightningElement {
    @api recordId;

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.txt', '.log'];
    }

    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        console.log('No. of files uploaded : ' + uploadedFiles.length);
    }
}