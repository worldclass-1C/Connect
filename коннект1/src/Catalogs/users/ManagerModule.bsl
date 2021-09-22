
Function attributesStructure() Export	
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "userCode", "cid", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "userType", "userType", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "barcode", "barcode", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "notSubscriptionEmail", "noSubscriptionEmail", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "notSubscriptionSms", "noSubscriptionSms", "boolean");	
	DataLoad.addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "secondName", "secondName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "birthday", "birthday", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "gender", "gender", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "email", "email", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "rating", "rating", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "canUpdatePersonalData", "canUpdatePersonalData", "boolean");	
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct, fillOwnersAttribute", True, "users", "catalog", "write", attributesTable, attributesTableForNewItem, New Structure(), true);
		
EndFunction


Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("lastName");
	array.Add("firstName");
	array.Add("secondName");	
	array.Add("holding");	
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;	
	presentation = "" + data.lastName + " " + data.firstName + " " + data.secondName + " (" + data.holding + ")";		
EndProcedure