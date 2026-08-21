import { LightningElement } from 'lwc';

export default class AiChatLauncher extends LightningElement {
    handleChatClick() {
        const embeddedService = window.embedded_svc;
        if (embeddedService) {
            embeddedService.bootstrapChat();
        } else {
            console.warn('Embedded Messaging Service is not initialized.');
        }
    }
}