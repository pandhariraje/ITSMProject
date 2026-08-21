import { LightningElement, wire, track } from 'lwc';
import getOpenTickets from '@salesforce/apex/CopilotPortalController.getOpenTickets';

const COLUMNS = [
    { label: 'Ticket Number', fieldName: 'ticketNumber', type: 'text' },
    { label: 'Subject', fieldName: 'subject', type: 'text' },
    { label: 'Type', fieldName: 'ticketType', type: 'text' },
    { label: 'Priority', fieldName: 'priority', type: 'text' },
    { label: 'Status', fieldName: 'status', type: 'text' },
    { label: 'Created Date', fieldName: 'createdDate', type: 'date', typeAttributes: { year: 'numeric', month: 'short', day: '2-digit' } }
];

export default class MyOpenTickets extends LightningElement {
    @track tickets;
    @track error;
    columns = COLUMNS;

    @wire(getOpenTickets)
    wiredTickets({ error, data }) {
        if (data) {
            this.tickets = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.tickets = undefined;
        }
    }

    get hasTickets() {
        return this.tickets && this.tickets.length > 0;
    }
}