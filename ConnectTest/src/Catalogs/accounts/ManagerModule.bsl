
Function attributesStructure() Export	
	
	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();
	
	data.addRowInAttributesTable(attributesTable, "code", "phoneNumber", "string");
	data.addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
	data.addRowInAttributesTable(attributesTable, "secondName", "secondName", "string");
	data.addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
	data.addRowInAttributesTable(attributesTable, "birthday", "birthdayDate", "date");
	data.addRowInAttributesTable(attributesTable, "gender", "gender", "string");
	data.addRowInAttributesTable(attributesTable, "email", "email", "string");
	
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

