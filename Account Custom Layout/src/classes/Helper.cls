public with sharing class Helper {
	public Helper() {
		
	}

	public static Map<String,Schema.SObjectField> getFields(string api_name){
		Schema.DescribeSObjectResult[] sobjects = Schema.describeSobjects(new String[]{api_name});
		return 	sobjects[0].fields.getMap();
	}
}