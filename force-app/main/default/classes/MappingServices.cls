public with sharing class MappingServices 
{
    public class Field
	{
		@AuraEnabled public String label {get; set;}
		@AuraEnabled public String type {get; set;}
		@AuraEnabled public Boolean ignoreDupes {get; set;}

		public Field(String label, String type)
		{
			this.label = label;
			this.type = type;
			ignoreDupes = false;
		}

		public Field(String label, String type, Boolean ignoreDupes)
		{
			this.label = label;
			this.type = type;
			this.ignoreDupes = ignoreDupes;
		}
	}

    @AuraEnabled
    public static Map<String, List<SelectOption>> getFieldValueMap(String sObjectType)
    {
        MappingSetupController msc = new MappingSetupController();
        msc.sobjectName = sObjectType;
        msc.loadFields();
        return msc.allFields;
    }

    @AuraEnabled
    public static Map<String, Map<String, Field>> getMappingFields()
    {
        return  new Map<String, Map<String, Field>>
        {
            'client' => new Map<String, Field>
            {
                'Client_Email__c' => new Field('Email', 'text'),
                'Client_First_Name__c' => new Field('First Name', 'text'),
                'Client_Last_Name__c' => new Field('Last Name', 'text'),
                'Client_Address_City__c' => new Field('Address City', 'text'),
                'Client_Address_Country__c' => new Field('Address Country', 'text'),
                'Client_Address_Postcode__c' => new Field('Address Postcode', 'text'),
                'Client_Alternate_Email__c' => new Field('Alternate Email', 'text'),
                'Client_Phone__c' => new Field('Phone', 'text'),
                'Client_Profile_Image__c' => new Field('Profile Image', 'text')
            },

            'event' => new Map<String, Field>
            {
                'Event_Type__c' => new Field('Event Type', 'text'),
                'Event_Subject__c' => new Field('Subject', 'text'),
                'Event_Attended__c' => new Field('Attended', 'boolean'),
                'Event_Start_Date_Time__c' => new Field('Start Date Time', 'datetime'),
                'Event_End_Date_Time__c' => new Field('End Date Time', 'datetime'),
                'Event_Client__c' => new Field('Event Client', 'lookup'),
                'Event_Created_By__c' => new Field('Event Created By', 'lookup'),
                'Event_Owner__c' => new Field('Event Owner', 'lookup')
            }
        };
    }
}
