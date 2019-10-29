
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "code", "code", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "parent", "parent", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");

	parentStruct = New Structure();
	parentStruct.Insert("errorDescriptions", "uid");

	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
		
	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("parent", parentStruct);
	mdStruct.Insert("language", New Structure("languages", "code"));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "errorDescriptions", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction