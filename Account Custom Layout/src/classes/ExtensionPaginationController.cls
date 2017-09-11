public with sharing class ExtensionPaginationController {
    private final Account currentAccount;
    public boolean Next{get;set;}
    public boolean Previous{get;set;}
    public List<Contact> Contacts{get;set;}
    public Integer CurrentPageNumber{get; set;}
    public String LimitString{get; set{
            ContactsLimit = Integer.valueOf(value);
            LimitString = value;
        }
    }
    public Integer ContactsLimit{get;set;}
    public Integer ContactsCount{get; set;}

    public List<SelectOption> Items;
    public List<SelectOption> AvailableFieldsOptions{get;set;}
    public List<SelectOption> SelectedFieldsOptions{get;set;}

    public String SortKey{get;set;}
    public Boolean ShowPopup{get;set;}
    
    private Integer contacts_offset;
    private Integer lastSelected_count;
    private List<Contact> contacts_to_update;
    private Contact_Fields__c contact_fields;

    private Set<String> ChosenFields;
    private Set<String> CopyChosenFields;
    private Set<String> AvailableFields;
    private Set<String> CopyAvailableFields;
    private Fields__c SelectedFieldsString;


    //ID current_account_id ;

    public ExtensionPaginationController(ApexPages.StandardController stdController) {
        Initialize();
        this.currentAccount = (Account)stdController.getRecord();         
        if(currentAccount.Id != NULL){
            ContactsCount = [SELECT Count() FROM Contact WHERE AccountId = :currentAccount.Id];
            Next = ContactsCount > 10;
            Contacts = retrieveContacts();
        }  
    }

    private void initialize(){
        ShowPopup = false;
        initializeSelectedFields();
        initializeAvailableFields();
        contacts_to_update = new List<Contact>();
        SortKey = 'FirstName';
        contacts_offset = 0;
        CurrentPageNumber = 1;
        ContactsLimit = 10;
        Previous = false;   
        SelectedFieldsOptions = getSelectedFieldsOptions();
        AvailableFieldsOptions = getAvailableFieldsOptions();

    }

    public void initializeAvailableFields(){
        AvailableFields = Helper.getFields('Contact').keySet();
        AvailableFields.removeAll(ChosenFields);
    }

    public void initializeSelectedFields(){     
   
        if([SELECT Count() FROM Fields__c WHERE Name = 'Contact'] == 0){
            SelectedFieldsString = new Fields__c();
            SelectedFieldsString.Name = 'Contact';
            SelectedFieldsString.Selected_Fields__c = ('Id,Name,FirstName,LastName,Description,Birthdate,OwnerId').toLowerCase();         
            ChosenFields = new Set<String>(SelectedFieldsString.Selected_Fields__c.split(','));
        }
        else{
            SelectedFieldsString = [SELECT Selected_Fields__c FROM Fields__c WHERE Name = 'Contact' LIMIT 1];
            List<String> fields = SelectedFieldsString.Selected_Fields__c.toLowerCase().split(',');
            ChosenFields = new Set<String>(fields);
        }            
    }

    public void getNext(){
        contacts_offset +=  ContactsLimit;
        Contacts = retrieveContacts();
        lastSelected_count = Contacts.Size();
        CurrentPageNumber++;
        Previous = true;
        if(contacts_offset + ContactsLimit >= ContactsCount){
            Next = false;
        }
    }

    public void getPrevious(){
        contacts_offset -=  ContactsLimit;
        if(contacts_offset < 0) contacts_offset = 0;
        Contacts = retrieveContacts();
        CurrentPageNumber--;
        Next = true;
        Previous = contacts_offset != 0;
    }

    public void getFirst(){
        contacts_offset = ContactsLimit;
        getPrevious();
        CurrentPageNumber = 1;
    }

    public void getLast(){
        contacts_offset = (Integer)(ContactsLimit * (Math.floor(ContactsCount / ContactsLimit) - 1));
        getNext();
        CurrentPageNumber = (Integer)Math.ceil(ContactsCount / ContactsLimit) + 1;
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
        Map<String,Schema.sobjectField> fieldsMap = Helper.getFields('Contact');
        List<SelectOption> options = new List<SelectOption>();
        for(String field: fieldsMap.keySet()){
            if(AvailableFields.contains(field))
            options.add(new SelectOption(field, fieldsMap.get(field).getDescribe().getLabel()));
        }
        return options;
    }

    public List<SelectOption> getSelectedFieldsOptions(){
        Map<String,Schema.sobjectField> fieldsMap = Helper.getFields('Contact');
        List<SelectOption> options = new List<SelectOption>();
        for(String field: fieldsMap.keySet())
        {
            if(ChosenFields.contains(field))
            options.add(new SelectOption(field, fieldsMap.get(field).getDescribe().getLabel()));
        }
        return options;
    }

    public void changeQueryLimit(){
        contacts_offset = 0;
        Contacts = retrieveContacts();
        CurrentPageNumber = 1;
        Previous = false; 
        Next = ContactsLimit < ContactsCount;
    }

    public Contact[] retrieveContacts(){
        String query = 'SELECT ' + SelectedFieldsString.Selected_Fields__c + ' ' +
        + 'FROM Contact WHERE AccountId = \'' + currentAccount.Id + '\'' +
        + ' ORDER BY ' + SortKey + ' ASC NULLS LAST LIMIT ' + ContactsLimit + ' OFFSET ' + contacts_offset;
        return database.query(query); 
    }

    public void customEdit(){
        system.debug('Upserted. ' + Contacts);
        upsert Contacts;
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
        ChosenFields = getSelectOptionsIntoList(SelectedFieldsOptions);
        AvailableFields = getSelectOptionsIntoList(AvailableFieldsOptions);
        if(ChosenFields.size() > 0){
            SelectedFieldsString.Selected_Fields__c = String.join(new List<String>(ChosenFields), ',');
            upsert SelectedFieldsString;
            Contacts = retrieveContacts();
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
}