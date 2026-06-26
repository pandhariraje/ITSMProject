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
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldMetadata> getIncidentFieldsMetadata() {
        List<FieldMetadata> fieldMetadatas = new List<FieldMetadata>();
        List<String> fieldsToDescribe = new List<String>{
            'Subject', 'Description', 'Urgency', 'Impact', 'Priority', 'Status'
        };

        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Incident.fields.getMap();

        for (String fieldName : fieldsToDescribe) {
            if (fieldMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                FieldMetadata fm = new FieldMetadata();
                fm.fieldName = fieldName;
                fm.label = dfr.getLabel();
                fm.type = String.valueOf(dfr.getType()).toLowerCase();
                
                // Subject and Description are required standard fields but might show isNillable = true or false. 
                // We make them required in the UI, or use describe's nillable info.
                fm.isRequired = !dfr.isNillable() || fieldName == 'Subject' || fieldName == 'Description';
                
                if (dfr.getType() == Schema.DisplayType.PICKLIST) {
                    List<PicklistOption> options = new List<PicklistOption>();
                    for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                        if (entry.isActive()) {
                            options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
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
