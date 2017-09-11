public with sharing class PaginationController {
	public boolean next{get;set;}
	public boolean previous{get;set;}
	public Contact[] contacts{get;set;}
	Integer contactsOffset;
	Integer contactsLimit;
	Integer contactsCount;
	ID currentAccountId ;

	public PaginationController() {
		contactsOffset = 0;
		contactsLimit = 10;
		previous = false;		
		currentAccountId = apexpages.currentpage().getparameters().get('id');
		contactsCount = [SELECT Count() FROM Contact WHERE AccountId = :currentAccountId];
		if(contactsCount > 10){
			next = true;
		}
		else{
			next = false;
		}
		contacts = [SELECT Id, FirstName, LastName, Description, Birthdate, OwnerId FROM Contact WHERE AccountId = :currentAccountId LIMIT :contactsLimit];
		contactsOffset += contactsLimit;
	}

	public Contact[] Next(){
		contacts = [SELECT Id, FirstName, LastName, Description, Birthdate, OwnerId FROM Contact WHERE AccountId = :currentAccountId LIMIT :contactsLimit OFFSET :contactsOffset];
		contactsOffset +=  contactsLimit;
		previous = true;
		if(contactsOffset + contactsLimit > contactsCount){
			next = false;
		}
		return contacts;
	}

	public Contact[] Previous(){
		contactsOffset -=  contactsLimit * 2;
		contacts = [SELECT Id, FirstName, LastName, Description, Birthdate, OwnerId FROM Contact WHERE AccountId = :currentAccountId LIMIT :contactsLimit OFFSET :contactsOffset];
		contactsOffset +=  contactsLimit;
		next = true;
		if(contactsOffset == 0){
			previous = false;
		}
		return contacts;
	}
}