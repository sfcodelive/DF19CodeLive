public with sharing class MappingSetupController
{
	public class field
	{
		public String label {get; set;}
		public String type {get; set;}
		public Boolean ignoreDupes {get; set;}

		public field(String label, String type)
		{
			this.label = label;
			this.type = type;
			ignoreDupes = false;
		}

		public field(String label, String type, Boolean ignoreDupes)
		{
			this.label = label;
			this.type = type;
			this.ignoreDupes = ignoreDupes;
		}
	}

	public Objects__c objSettings {get; set;}

	public List<SelectOption> objects {get; set;}
	public Map<String, List<Integer>> keyIndexMap {get; set;}
	public String currentObject {get; set;}
	public String sobjectName {get; set;}
	public String profileId {get; set;}

	public List<SelectOption> availableDateFields {get; set;}
	public List<SelectOption> availableDatetimeFields {get; set;}
	public List<SelectOption> availableTextFields {get; set;}
	public List<SelectOption> availableLookupFields {get; set;}
	public List<SelectOption> availableBooleanFields {get; set;}

	public Map<String, List<SelectOption>> allFields {get; set;}

	public List<SelectOption> profiles {get; set;}

	public Boolean showFields {get; set;}
	public Boolean showSOQL {get; set;}

	public String SOQL {get; set;}
	public String exceptionMessage {get; set;}
	public List<String> errors {public get; set;}

	public Map<String,List<String>> errorMap {public get; set;}


	public MappingSetupController()
	{
		showSOQL = false;
		profileId = UserInfo.getOrganizationId();
		objSettings = Objects__c.getInstance(profileId);

		errors = new List<String>();
		errorMap = new Map<String,List<String>>();

		currentObject = 'client';

		if(objSettings.Name == null)
		{
			setDefaults();
		}

		loadProfiles();

		objects = new List<SelectOption>
		{
			new SelectOption('client', 'Client'),
			new SelectOption('event', 'Event')
		};
	}

	public PageReference init()
	{
		switchObject();

		keyIndexMap = new Map<String, List<Integer>>();

		for(String key : orderedKeys.keySet())
		{
			List<String> fields = orderedKeys.get(key);
			List<Integer> indices = new List<Integer>();

			for(Integer i = 0; i < fields.size(); i += 2)
			{
				indices.add(i);
			}

			keyIndexMap.put(key, indices);
		}

		return null;
	}

	public PageReference toggleSOQL()
	{
		showSOQL = !showSOQL;
		return null;
	}

	private void setDefaults()
	{
		objSettings.Client_Object__c = 'Contact';
		objSettings.Event_Object__c = 'Event';
		sobjectName = 'Contact';
	}

	private void loadProfiles()
	{
		profiles = new List<SelectOption>
		{
			new SelectOption(UserInfo.getOrganizationId(), 'Organisation Default')
		};

		for(Profile p : [SELECT Id, Name FROM Profile ORDER BY Name])
		{
			profiles.add(new SelectOption(p.Id, p.Name));
		}

	}

	public PageReference switchObject()
	{
		System.Debug('switchObject()');

		save();
		objSettings = Objects__c.getInstance(profileId);
		sobjectName = (String)objSettings.get(currentObject + '_object__c');

		if(sobjectName == 'null')
			sobjectName = '';

		loadFields();

		return null;
	}

	public void loadFields()
	{
		System.Debug('loadFields()');

		Schema.SObjectType objType = Schema.getGlobalDescribe().get(sobjectName);
		showFields = false;

		if(objType == null)
		{
			if(sobjectName == '')
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Fields will be displayed once an object API name has been set.'));
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, sobjectName + ' does not appear to be a valid SObject type.'));
			}
			return;
		}

		if(currentObject != 'user')
		{
			objSettings.put(currentObject + '_object__c', sobjectName);
		}

		showFields = (orderedKeys.keySet().contains(currentObject));

		availableDateFields = new List<SelectOption>();
		availableDatetimeFields = new List<SelectOption>();
		availableTextFields = new List<SelectOption>();
		availableLookupFields = new List<SelectOption>();
		availableBooleanFields = new List<SelectOption>();

		allFields = new Map<String, List<SelectOption>>
		{
			'date' => new List<SelectOption>{new SelectOption('', '--None--')},
			'datetime' => new List<SelectOption>{new SelectOption('', '--None--')},
			'lookup' => new List<SelectOption>{new SelectOption('', '--None--')},
			'boolean' => new List<SelectOption>{new SelectOption('', '--None--')},
			'text' => new List<SelectOption>{new SelectOption('', '--None--')},
			'picklist' => new List<SelectOption>{new SelectOption('', '--None--')},
			'number' => new List<SelectOption>{new SelectOption('', '--None--')},
			'child' => new List<SelectOption>{new SelectOption('', '--None--')},
			'any' => new List<SelectOption>{new SelectOption('', '--None--')},
			'filter-op' => new List<SelectOption>
				{
					new SelectOption('', '--None--'),
					new SelectOption('in', 'in'),
					new SelectOption('includes', 'includes'),
					new SelectOption('like', 'like')
				}
		};

		Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

		List<String> fieldKeys = new List<String>(fieldMap.keySet());

		fieldKeys.sort();

		for(String field : fieldKeys)
		{
			SChema.DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
			SelectOption so = new SelectOption(dfr.getName(), dfr.getLabel());

			allFields.get('any').add(so);

			if(dfr.type == Schema.DisplayType.Date)
				allFields.get('date').add(so);
			else if(dfr.type == Schema.DisplayType.Datetime)
				allFields.get('datetime').add(so);
			else if(dfr.type == Schema.DisplayType.Boolean)
				allFields.get('boolean').add(so);
			else if(dfr.type == Schema.DisplayType.Reference)
				allFields.get('lookup').add(so);
			else if(dfr.type == Schema.DisplayType.Percent
					|| dfr.type == Schema.DisplayType.Currency
					|| dfr.type == Schema.DisplayType.Integer
					|| dfr.type == Schema.DisplayType.Double)
				allFields.get('number').add(so);
			else if(dfr.type == Schema.DisplayType.Picklist)
			{
				allFields.get('picklist').add(so);
				allFields.get('text').add(so);
			}
			else
				allFields.get('text').add(so);
		}

		for(Schema.ChildRelationship cr : objType.getDescribe().getChildRelationships())
		{
			if(cr.getRelationshipName() != null)
				allFields.get('child').add(new SelectOption(cr.getRelationshipName(), cr.getRelationshipName()  + ' (' + cr.getChildSObject() + ')'));
		}
	}

	public PageReference Save()
	{
		upsert objSettings;
		return null;
	}

	public Map<String, List<String>> orderedKeys = new Map<String, List<String>>
	{
		'client' => new List<String>
		{
			'Client_First_Name__c',
			'Client_Last_Name__c',
			'Client_Email__c',
			'Client_Alternate_Email__c',
			'Client_Address_City__c',
			'Client_Address_Country__c',
			'Client_Address_Postcode__c',
			'Client_Phone__c',
			'Client_Profile_Image__c'
		},

		'event' => new List<String>
		{
			'Event_Type__c',
			'Event_Subject__c',
			'Event_Attended__c',
			'spacer',
			'Event_Start_Date_Time__c',
			'Event_End_Date_Time__c',
			'Event_Client__c',
			'Event_Created_By__c',
			'Event_Owner__c'
		}
	};

	public Map<String, List<String>> getOrderedKeys()
	{
		return orderedKeys;
	}

	public Map<String, Map<String, Field>> mappingFields = new Map<String, Map<String, Field>>
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

	public Map<String, Map<String, Field>> getMappingFields()
	{
		return mappingFields;
	}
}
