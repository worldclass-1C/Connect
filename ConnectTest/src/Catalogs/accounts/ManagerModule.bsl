
Function attributesStructure() Export	
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "code", "phoneNumber", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "secondName", "secondName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "birthday", "birthdayDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "gender", "gender", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "email", "email", "string");
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "accounts", "catalog", "write", attributesTable, attributesTableForNewItem, New Structure());
		
EndFunction

Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("lastName");
	array.Add("firstName");	
	array.Add("code");	
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation	= "" + data.lastName + " " + data.firstName + " (" + data.code + ")";		
EndProcedure

