
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "description", "name", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "address", "gymAddress", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "startDate", "startDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "endDate", "endDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "departmentWorkSchedule", "departments", "JSON");
	DataLoad.addRowInAttributesTable(attributesTable, "nearestMetro", "metro", "JSON");
	DataLoad.addRowInAttributesTable(attributesTable, "additional", "additional", "JSON");
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "segment", "division", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "state", "state", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "type", "type", "enum");
	DataLoad.addRowInAttributesTable(attributesTable, "order", "type", "number");	

	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "address", "gymAddress", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "state", "state", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "departmentWorkSchedule", "departments", "JSON");
	DataLoad.addRowInAttributesTable(attributesTranslation, "nearestMetro", "metro", "JSON");
	DataLoad.addRowInAttributesTable(attributesTranslation, "additional", "additional", "JSON");

	attributesPhotos = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", New Structure("languages", "code"));
	mdStruct.Insert("segment", New Structure("segments", "discription"));
	mdStruct.Insert("type", New Structure("gymTypes", ""));	

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "gyms", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction