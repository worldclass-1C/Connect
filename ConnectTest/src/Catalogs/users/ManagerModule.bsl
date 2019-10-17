
Function attributesStructure() Export	
	
	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();
	
	data.addRowInAttributesTable(attributesTable, "userCode", "cid", "string");
	data.addRowInAttributesTable(attributesTable, "userType", "userType", "string");
	data.addRowInAttributesTable(attributesTable, "barCode", "barcode", "string");
	data.addRowInAttributesTable(attributesTable, "notSubscriptionEmail", "noSubscriptionEmail", "boolean");
	data.addRowInAttributesTable(attributesTable, "notSubscriptionSms", "noSubscriptionSms", "boolean");
	
	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "users", "catalog", "write", attributesTable, attributesTableForNewItem, New Structure());
		
EndFunction