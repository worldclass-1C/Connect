
Function attributesStructure() Export

	attributesTableForNewItem = data.getValueTable();
	
	attributesTable = data.getValueTable();
	data.addRowInAttributesTable(attributesTable, "period", "period", "date");
	data.addRowInAttributesTable(attributesTable, "active", "active", "boolean");
	data.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	data.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "JSON");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	
	attributesTranslation = data.getValueTable();
	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "fullDescription", "fullDescription", "JSON");
	
	gymStruct = New Structure();
	gymStruct.Insert("gyms", "uid");

	mdStruct = New Structure();
	mdStruct.Insert("gym", gymStruct);
	mdStruct.Insert("translation", attributesTranslation);
	
	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "classesSchedule", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction