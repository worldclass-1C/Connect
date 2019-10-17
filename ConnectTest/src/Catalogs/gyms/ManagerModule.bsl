
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "description", "name", "string");
	data.addRowInAttributesTable(attributesTable, "address", "gymAddress", "string");
	data.addRowInAttributesTable(attributesTable, "segment", "division", "string");
	data.addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
	data.addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
	data.addRowInAttributesTable(attributesTable, "type", "type", "string");
	data.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	data.addRowInAttributesTable(attributesTable, "departmentWorkSchedule", "departments", "JSON");
	data.addRowInAttributesTable(attributesTable, "nearestMetro", "metro", "JSON");
	data.addRowInAttributesTable(attributesTable, "additional", "additional", "JSON");
	data.addRowInAttributesTable(attributesTable, "city", "city", "ref");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	data.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");

	attributesTranslation = data.getValueTable();

	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	data.addRowInAttributesTable(attributesTranslation, "address", "gymAddress", "string");
	data.addRowInAttributesTable(attributesTranslation, "departmentWorkSchedule", "departments", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "nearestMetro", "metro", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "additional", "additional", "JSON");

	attributesPhotos = data.getValueTable();
	data.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");

	cityStruct = New Structure();
	cityStruct.Insert("cities", "uid");

	languageStruct = New Structure();
	languageStruct.Insert("languages", "code");
	
	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", languageStruct);
	mdStruct.Insert("city", cityStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "gyms", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction