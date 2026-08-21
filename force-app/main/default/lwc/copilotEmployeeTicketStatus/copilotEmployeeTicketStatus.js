import { LightningElement, api } from 'lwc';

export default class CopilotEmployeeTicketStatus extends LightningElement {
    @api ticket = {
        number: 'INC0012903',
        priority: 'High',
        subject: 'VPN Connection Fails regularly',
        status: 'In Progress'
    };
}