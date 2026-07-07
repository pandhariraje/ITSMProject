import { LightningElement, track } from 'lwc';

export default class CopilotEmployeeOpenTickets extends LightningElement {
    @track columns = [
        { label: 'Ticket Number', fieldName: 'number', type: 'text' },
        { label: 'Subject', fieldName: 'subject', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Priority', fieldName: 'priority', type: 'text' }
    ];

    @track tickets = [
        { id: '1', number: 'INC0012903', subject: 'VPN Connection Fails regularly', status: 'In Progress', priority: 'High' },
        { id: '2', number: 'SR-000452', subject: 'Outlook Install Request', status: 'New', priority: 'Medium' }
    ];
}
