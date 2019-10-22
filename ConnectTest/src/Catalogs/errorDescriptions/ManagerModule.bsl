
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "code", "code", "string");
	data.addRowInAttributesTable(attributesTable, "parent", "parent", "ref");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");

	parentStruct = New Structure();
	parentStruct.Insert("errorDescriptions", "uid");

	attributesTranslation = data.getValueTable();

	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
		
	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("parent", parentStruct);
	mdStruct.Insert("language", New Structure("languages", "code"));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "errorDescriptions", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction