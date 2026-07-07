import { LightningElement, track } from 'lwc';

export default class CopilotEmployeeKnowledgeSearch extends LightningElement {
    @track articles = [];

    handleSearchChange(event) {
        const query = event.target.value;
        if (query.length > 2) {
            // Mock matching articles
            this.articles = [
                { id: '1', title: 'How to Reset Your VPN Connection', summary: 'Follow these steps to clear VPN cache and re-authenticate.', url: '/customer/s/article/Reset-VPN' },
                { id: '2', title: 'Outlook Configuration Guide', summary: 'Detailed setup instructions for Outlook on Windows and macOS.', url: '/customer/s/article/Outlook-Guide' }
            ];
        } else {
            this.articles = [];
        }
    }
}
