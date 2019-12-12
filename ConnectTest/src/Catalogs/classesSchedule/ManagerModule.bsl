
Function attributesStructure() Export

	attributesTableForNewItem = DataLoad.getValueTable();

	attributesTable = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesTable, "period", "period", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "active", "active", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "ageMax", "ageMax", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "ageMin", "ageMin", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "availablePlaces", "totalCount", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "duration", "duration", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "employee", "employee", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "endRegistration", "endRegistration", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "isPreBooked", "isPreBooked", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "isPrePaid", "isPrePaid", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "onlyMembers", "onlyMembers", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "onlyWithParents", "onlyWithParents", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "price", "price", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "product", "product", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "recordCancelInterval", "recordCancelInterval", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "room", "room", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "startRegistration", "startRegistration", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "studentLevel", "studentLevel", "string");			
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	
	mdStruct = New Structure();
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	mdStruct.Insert("room", New Structure("rooms", "uid"));
	mdStruct.Insert("employee", New Structure("employees", "uid"));
	mdStruct.Insert("product", New Structure("products", "uid"));
	mdStruct.Insert("language", New Structure("languages", "code"));	
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "classesSchedule", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction