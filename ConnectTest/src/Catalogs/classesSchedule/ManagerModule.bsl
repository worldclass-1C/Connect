
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "period", "period", "date");
	data.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	data.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "string");

	gymStruct = New Structure();
	gymStruct.Insert("gyms", "uid");

	mdStruct = New Structure();
	mdStruct.Insert("gym", gymStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "classesSchedule", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction