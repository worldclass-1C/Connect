
Function attributesStructure() Export

	attributesTableForNewItem = data.getValueTable();
	
	attributesTable = data.getValueTable();
	data.addRowInAttributesTable(attributesTable, "period", "period", "date");
	data.addRowInAttributesTable(attributesTable, "active", "active", "boolean");
	data.addRowInAttributesTable(attributesTable, "description", "description", "string");
	data.addRowInAttributesTable(attributesTable, "startRegistration", "startRegistration", "date");
	data.addRowInAttributesTable(attributesTable, "endRegistration", "endRegistration", "date");
	data.addRowInAttributesTable(attributesTable, "serviceid", "serviceid", "string");
	data.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	data.addRowInAttributesTable(attributesTable, "employee", "employee", "ref");
	data.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "JSON");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	
	attributesTranslation = data.getValueTable();
	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "fullDescription", "fullDescription", "JSON");
	
	mdStruct = New Structure();
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	mdStruct.Insert("employee", New Structure("employees", "uid"));
	mdStruct.Insert("language", New Structure("languages", "code"));
	mdStruct.Insert("translation", attributesTranslation);
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "classesSchedule", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction