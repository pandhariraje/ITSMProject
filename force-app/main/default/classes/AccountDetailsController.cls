/**
 * @description Controller class used to fetch Opportunity details along with
 * related Account information and the primary Decision Maker Contact.
 * This method is designed to be used by LWC components.
 * Enforces sharing rules and user-level CRUD/FLS using USER_MODE.
 */
public with sharing class AccountDetailsController {

    /**
     * @description Retrieves an Opportunity record with related Account fields
     * and the primary Contact from Opportunity Contact Roles.
     *
     * @param opportunityId The Id of the Opportunity record to retrieve.
     * @return Opportunity record including Account details and primary Contact.
     */
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityWithAccount(Id opportunityId) {

        Map<String, Schema.SObjectField> accountFields = Schema.SObjectType.Account.fields.getMap();

        List<String> accountFieldList = new List<String>{
            'Account.Id',
            'Account.Name'
        };

        if (accountFields.containsKey('MSA_Signed__c')) {
            accountFieldList.add('Account.MSA_Signed__c');
        }
        if (accountFields.containsKey('MSA_Signed_Date__c')) {
            accountFieldList.add('Account.MSA_Signed_Date__c');
        }
        if (accountFields.containsKey('MSA_Expiration_Date__c')) {
            accountFieldList.add('Account.MSA_Expiration_Date__c');
        }
        if (accountFields.containsKey('Client_Company_Name__c')) {
            accountFieldList.add('Account.Client_Company_Name__c');
        }
        if (accountFields.containsKey('Client_Point_of_Contact__c')) {
            accountFieldList.add('Account.Client_Point_of_Contact__c');
        }

        String accountFieldClause = String.join(accountFieldList, ', ');

        String soql =
            'SELECT Id, Name, ' + accountFieldClause +
            ' (SELECT ContactId, Contact.Name, Contact.FirstName, Contact.LastName ' +
            'FROM OpportunityContactRoles ' +
            'WHERE IsPrimary = true) ' +
            'FROM Opportunity ' +
            'WHERE Id = :opportunityId ' +
            'WITH USER_MODE ' +
            'LIMIT 1';

        Opportunity opp = Database.query(soql);

        return opp;
    }
}