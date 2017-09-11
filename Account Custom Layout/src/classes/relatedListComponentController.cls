public with sharing class relatedListComponentController {

	public String ApiName{get;set;}

    public boolean Next{get;set;}
    public boolean Previous{get;set;}
    public List<SObject> RelatedSObjects{get;set;}
    public Integer CurrentPageNumber{get; set;}
    public String LimitString{get; set{
            RelatedSObjectsLimit = Integer.valueOf(value);
            LimitString = value;
        }
    }
    public Integer RelatedSObjectsLimit{get;set;}
    public Integer RelatedSObjectsCount{get; set;}

    public List<SelectOption> Items;
    public List<SelectOption> AvailableFieldsOptions{get;set;}
    public List<SelectOption> SelectedFieldsOptions{get;set;}

    public String SortKey{get;set;}
    public Boolean ShowPopup{get;set;}
    
    private Integer RelatedSObjectsOffset;
    private Integer lastSelected_count;

    private Set<String> ChosenFields;
    private Set<String> CopyChosenFields;
    private Set<String> AvailableFields;
    private Set<String> CopyAvailableFields;
    private Fields__c SelectedFieldsString;

    private sObject CurrentSObject;
    private Id CurrentSObjectId;

    public relatedListComponentController() {
        Initialize();
        String sobject_name = getSObjectName();
        CurrentSObject = createObject(sobject_name);

        RelatedSObjects = new List<SObject>();      
        if(CurrentSObjectId != NULL){
            String query = 'SELECT Count() FROM ' + ApiName + ' WHERE ' + sobject_name + 'Id = ' + '\'' + CurrentSObjectId + '\'';
            RelatedSObjectsCount = database.countQuery(query);
            Next = RelatedSObjectsCount > 10;
            RelatedSObjects = retrieveSObjects();
        }  
    }

    private void initialize(){
        system.debug('Initializing...');
        ShowPopup = false;
        CurrentSObjectId = getId();
        system.debug('ID: ' + CurrentSObjectId);
        initializeSelectedFields();
        system.debug('SelectedFields initialized : ' + ChosenFields);
        initializeAvailableFields();
        system.debug('Available initialized : ' + AvailableFields);
        SortKey = 'FirstName';
        system.debug('SortKey: ' + SortKey);
        RelatedSObjectsOffset = 0;
        CurrentPageNumber = 1;
        RelatedSObjectsLimit = 10;
        Previous = false;   
        SelectedFieldsOptions = getSelectedFieldsOptions();
        AvailableFieldsOptions = getAvailableFieldsOptions();
        system.debug('Initializing finished!');
    }

    private Id getId(){
        CurrentSObjectId = Id.valueOf(ApexPages.currentPage().getParameters().get('id'));
            //CurrentSObjectId = ((String)CurrentSObjectId).substring(0, 15);
        system.debug('--in getId. ID: ' + CurrentSObjectId);
        return CurrentSObjectId; //.substring(0, id_param.length() - 3);
    }

    public static sObject createObject(String typeName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(typeName);
        if (targetType == null) {
            return null;
        }
        return targetType.newSObject();
    }


    private String getSObjectName(){
        if(CurrentSObjectId != null && CurrentSObjectId != '')
            return CurrentSObjectId.getSObjectType().getDescribe().getName();
        else return '';
    }

    private sObject getSObject(){
        String sobject_name = getSObjectName();
        return sobject_name != ''? createObject(sobject_name) : null;
    }

    public void initializeAvailableFields(){
        String sobject_name = getSObjectName();
        AvailableFields = getFields(sobject_name).keySet();
        AvailableFields.removeAll(ChosenFields);
        system.debug('--Init-- AvailableFields: ' + AvailableFields);
    }

    public void initializeSelectedFields(){  
        system.debug('Initializing selected fields...');   
        String sobject_name = getSObjectName();
        system.debug('sobject_name: ' + sobject_name);
        if([SELECT Count() FROM Fields__c WHERE Name = :sobject_name] == 0){
            SelectedFieldsString = new Fields__c();
            SelectedFieldsString.Name = sobject_name;
            SelectedFieldsString.Selected_Fields__c = ('Id,Name').toLowerCase();         
            ChosenFields = new Set<String>(SelectedFieldsString.Selected_Fields__c.split(','));
        }
        else{
            SelectedFieldsString = [SELECT Selected_Fields__c FROM Fields__c WHERE Name = :sobject_name LIMIT 1];
            ChosenFields = new Set<String>(SelectedFieldsString.Selected_Fields__c.toLowerCase().split(','));
        }    
        system.debug('--Init-- ChosenFields ' + ChosenFields);          
    }

    public void getNext(){
        RelatedSObjectsOffset +=  RelatedSObjectsLimit;
        RelatedSObjects = retrieveSObjects();
        lastSelected_count = RelatedSObjects.Size();
        CurrentPageNumber++;
        Previous = true;
        if(RelatedSObjectsOffset + RelatedSObjectsLimit >= RelatedSObjectsCount){
            Next = false;
        }
    }

    public void getPrevious(){
        RelatedSObjectsOffset -=  RelatedSObjectsLimit;
        if(RelatedSObjectsOffset < 0) RelatedSObjectsOffset = 0;
        RelatedSObjects = retrieveSObjects();
        CurrentPageNumber--;
        Next = true;
        Previous = RelatedSObjectsOffset != 0;
    }

    public void getFirst(){
        RelatedSObjectsOffset = RelatedSObjectsLimit;
        getPrevious();
        CurrentPageNumber = 1;
    }

    public void getLast(){
        RelatedSObjectsOffset = (Integer)(RelatedSObjectsLimit * (Math.floor(RelatedSObjectsCount / RelatedSObjectsLimit) - 1));
        getNext();
        CurrentPageNumber = (Integer)Math.ceil(RelatedSObjectsCount / RelatedSObjectsLimit) + 1;
    }

    public List<SelectOption> getItems() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('10','10'));
            options.add(new SelectOption('20','20'));
            options.add(new SelectOption('30','30'));
            options.add(new SelectOption('50','50'));
            options.add(new SelectOption('100','100'));
            return options;
        }

    public List<SelectOption> getAvailableFieldsOptions(){
        String sobject_name = getSObjectName();
        Map<String,Schema.sobjectField> fieldsMap = getFields(sobject_name);
        List<SelectOption> options = new List<SelectOption>();
        system.debug('--- getting Items-- AvailableFields: ' + AvailableFields);
        for(String field: fieldsMap.keySet()){
            if(AvailableFields.contains(field))
            options.add(new SelectOption(field, fieldsMap.get(field).getDescribe().getLabel()));
        }
        return options;
    }

    public List<SelectOption> getSelectedFieldsOptions(){
        String sobject_name = getSObjectName();
        Map<String,Schema.sobjectField> fieldsMap = getFields(sobject_name);
        system.debug('--- getting Items-- ChosenFields: ' + ChosenFields);
        List<SelectOption> options = new List<SelectOption>();
        for(String field: fieldsMap.keySet())
        {
            if(ChosenFields.contains(field))
            options.add(new SelectOption(field, fieldsMap.get(field).getDescribe().getLabel()));
        }
        system.debug('--- getting Items-- SelectedFieldsOptions: ' + options);
        return options;
    }

    public void changeQueryLimit(){
        RelatedSObjectsOffset = 0;
        RelatedSObjects = retrieveSObjects();
        CurrentPageNumber = 1;
        Previous = false; 
        Next = RelatedSObjectsLimit < RelatedSObjectsCount;
    }

    public SObject[] retrieveSObjects(){
        String sobject_name = getSObjectName();
        String query = 'SELECT ' + SelectedFieldsString.Selected_Fields__c + ' ' +
        + 'FROM ' + ApiName + ' WHERE ' + sobject_name + 'Id = \'' + CurrentSObjectId + '\'' +
        + ' ORDER BY ' + SortKey + ' ASC NULLS LAST LIMIT ' + RelatedSObjectsLimit + ' OFFSET ' + RelatedSObjectsOffset;
        return database.query(query); 
    }

    public void customEdit(){
        system.debug('Upserted. ' + RelatedSObjects);
        upsert RelatedSObjects;
    }

    public void customCancel(){

    }

    public void flipSortKey(){
        getFirst();
    }

    public void displayPopup(){    
        SelectedFieldsOptions = getSelectedFieldsOptions();
        AvailableFieldsOptions = getAvailableFieldsOptions();
        CopyChosenFields = ChosenFields;
        CopyAvailableFields = AvailableFields; 
        ShowPopup = true;
    }

    public void cancelPopup(){
        ShowPopup = false;
    }

    public void savePopupChanges(){
        ShowPopup = false;
        system.debug('----savePopupChanges-- Selected fields in SelectedFieldsOptions: ' + SelectedFieldsOptions);
        ChosenFields = getSelectOptionsIntoList(SelectedFieldsOptions);
        AvailableFields = getSelectOptionsIntoList(AvailableFieldsOptions);
        system.debug('----savePopupChanges-- Selected fields in ChosenFields: ' + ChosenFields);
        if(ChosenFields.size() > 0){
            SelectedFieldsString.Selected_Fields__c = String.join(new List<String>(ChosenFields), ',');
            upsert SelectedFieldsString;
            system.debug('----savePopupChanges-- Selected fields: ' + SelectedFieldsString.Selected_Fields__c);
            RelatedSObjects = retrieveSObjects();
        }
    }

    private Set<String> getSelectOptionsIntoList(List<SelectOption> options){
        if(options != NULL){
            if(options.Size() > 0){
                Set<String> values = new Set<String>();
                for(SelectOption option: options){
                    values.add(option.getValue()); 
                }
                return values;
            }
            else return new Set<String>();
        }
        else return new Set<String>();
    }

    private Map<String,Schema.SObjectField> getFields(string api_name){
        Schema.DescribeSObjectResult[] sobjects = Schema.describeSobjects(new String[]{api_name});
        system.debug('Fields: ' + sobjects[0].fields.getMap()); 
        return  sobjects[0].fields.getMap();
    }
}