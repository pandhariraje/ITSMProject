import { LightningElement, track } from 'lwc';

export default class CopilotEmployeeAgentAvailability extends LightningElement {
    @track statusMessage = 'Live agents are online and ready';
    @track isOnline = true;

    connectedCallback() {
        // Support is active 24/7
        this.statusMessage = 'Live agents are online and ready';
        this.isOnline = true;
    }

    get statusBadgeClass() {
        return this.isOnline ? 'status-indicator online' : 'status-indicator offline';
    }
}
