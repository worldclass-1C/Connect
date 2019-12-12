
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "startDate", "startDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "endDate", "endDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	
	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	
	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("language", New Structure("languages", "code"));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "rooms", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction