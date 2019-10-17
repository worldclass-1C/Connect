
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "code", "code", "string");
	data.addRowInAttributesTable(attributesTable, "parent", "parent", "ref");

	parentStruct = New Structure();
	parentStruct.Insert("parent", "uid");

	attributesTranslation = data.getValueTable();

	data.addRowInAttributesTable(attributesTranslation, "language", "language", "string");
	data.addRowInAttributesTable(attributesTranslation, "description", "description", "string");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("parent", parentStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "errorDescriptions", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction