
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "description", "name", "string");
	data.addRowInAttributesTable(attributesTable, "address", "gymAddress", "string");
	data.addRowInAttributesTable(attributesTable, "startDate", "startDate", "date");
	data.addRowInAttributesTable(attributesTable, "endDate", "endDate", "date");
	data.addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
	data.addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
	data.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	data.addRowInAttributesTable(attributesTable, "departmentWorkSchedule", "departments", "JSON");
	data.addRowInAttributesTable(attributesTable, "nearestMetro", "metro", "JSON");
	data.addRowInAttributesTable(attributesTable, "additional", "additional", "JSON");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	data.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	data.addRowInAttributesTable(attributesTable, "segment", "division", "string");
	data.addRowInAttributesTable(attributesTable, "type", "type", "enum");	
//	data.addRowInAttributesTable(attributesTable, "segment", "division", "string");
	

	attributesTranslation = data.getValueTable();

	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	data.addRowInAttributesTable(attributesTranslation, "address", "gymAddress", "string");
	data.addRowInAttributesTable(attributesTranslation, "departmentWorkSchedule", "departments", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "nearestMetro", "metro", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "additional", "additional", "JSON");

	attributesPhotos = data.getValueTable();
	data.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", New Structure("languages", "code"));
	mdStruct.Insert("type", New Structure("gymTypes", ""));	

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "gyms", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction