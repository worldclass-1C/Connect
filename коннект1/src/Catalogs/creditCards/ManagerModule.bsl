Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "acquiringBank", "acquiringBank", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "autopayment", "autopayment", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "owner", "owner", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "inactive", "inactive", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "expiryDate", "expiryDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "ownerName", "ownerName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "paymentSystem", "paymentSystem", "enum");
	DataLoad.addRowInAttributesTable(attributesTable, "registrationDate", "registrationDate", "date");
			
	mdStruct = New Structure();
	mdStruct.Insert("owner", New Structure("users", "uid"));
	mdStruct.Insert("paymentSystem", New Structure("paymentSystem", ""));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", false, "creditCards", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction