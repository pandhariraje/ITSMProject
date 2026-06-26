public with sharing class IncidentMetadataController {

    public class FieldMetadata {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public List<PicklistOption> picklistOptions;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public Boolean isDefault;
        
        public PicklistOption(String label, String value, Boolean isDefault) {
            this.label = label;
            this.value = value;
            this.isDefault = isDefault;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getIncidentFieldsMetadata() {
        List<FieldMetadata> fieldMetadatas = new List<FieldMetadata>();
        List<String> fieldsToDescribe = new List<String>{
            'Subject', 'Description', 'Category', 'Status', 'Urgency', 'Impact', 'Priority'
        };

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Incident.fields.getMap();

        Set<String> requiredFields = new Set<String>{ 'Subject', 'Status', 'Urgency', 'Impact', 'Priority' };

        for (String fieldName : fieldsToDescribe) {
            if (fieldMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                FieldMetadata fm = new FieldMetadata();
                fm.fieldName = fieldName;
                fm.label = dfr.getLabel();
                fm.type = String.valueOf(dfr.getType()).toLowerCase();
                
                fm.isRequired = requiredFields.contains(fieldName);
                
                if (dfr.getType() == Schema.DisplayType.PICKLIST) {
                    List<PicklistOption> options = new List<PicklistOption>();
                    for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                        if (entry.isActive()) {
                            options.add(new PicklistOption(entry.getLabel(), entry.getValue(), entry.isDefaultValue()));
                        }
                    }
                    fm.picklistOptions = options;
                } else {
                    fm.picklistOptions = new List<PicklistOption>();
                }
                fieldMetadatas.add(fm);
            }
        }
        return fieldMetadatas;
    }
}
