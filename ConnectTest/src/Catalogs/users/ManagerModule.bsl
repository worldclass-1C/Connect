
Function attributesStructure() Export	
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "userCode", "cid", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "userType", "userType", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "barcode", "barcode", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "notSubscriptionEmail", "noSubscriptionEmail", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "notSubscriptionSms", "noSubscriptionSms", "boolean");
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "users", "catalog", "write", attributesTable, attributesTableForNewItem, New Structure());
		
EndFunction