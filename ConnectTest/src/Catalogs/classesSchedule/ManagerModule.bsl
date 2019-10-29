
Function attributesStructure() Export

	attributesTableForNewItem = DataLoad.getValueTable();

	attributesTable = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesTable, "period", "period", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "active", "active", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "startRegistration", "startRegistration", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "endRegistration", "endRegistration", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "serviceid", "serviceid", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "availablePlaces", "totalCount", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "recordCancelInterval", "recordCancelInterval", "number");	 
	DataLoad.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "employee", "employee", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "JSON");
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	
	attributesTranslation = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "fullDescription", "fullDescription", "JSON");
	
	mdStruct = New Structure();
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	mdStruct.Insert("employee", New Structure("employees", "uid"));
	mdStruct.Insert("language", New Structure("languages", "code"));
	mdStruct.Insert("translation", attributesTranslation);
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "classesSchedule", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction