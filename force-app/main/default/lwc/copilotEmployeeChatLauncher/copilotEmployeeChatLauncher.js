import { LightningElement } from 'lwc';

export default class CopilotEmployeeChatLauncher extends LightningElement {
    handleLaunch() {
        console.log('Launching Embedded Messaging Chat Session...');
        // Dispatch Custom Event to notify experience site layout
        this.dispatchEvent(new CustomEvent('launchchat', { bubbles: true, composed: true }));
    }
}
