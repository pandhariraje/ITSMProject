import { LightningElement, track } from 'lwc';
import searchArticles from '@salesforce/apex/CopilotPortalController.searchArticles';

export default class KnowledgeSearchCard extends LightningElement {
    @track searchKey = '';
    @track articles;
    @track error;
    @track loading = false;

    handleSearchChange(event) {
        this.searchKey = event.target.value;
    }

    handleSearch() {
        if (!this.searchKey) {
            this.articles = [];
            return;
        }
        this.loading = true;
        searchArticles({ queryTerm: this.searchKey })
            .then(result => {
                this.articles = result;
                this.error = undefined;
                this.loading = false;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : error.message;
                this.articles = undefined;
                this.loading = false;
            });
    }

    get hasArticles() {
        return this.articles && this.articles.length > 0;
    }
}