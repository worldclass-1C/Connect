
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");	
	DataLoad.addRowInAttributesTable(attributesTable, "level", "level", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "weight", "weight", "number");
	DataLoad.addRowInAttributesTable(attributesTable, "startDate", "startDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "endDate", "endDate", "date");
	
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	
	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");	

	attributesPhotos = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", New Structure("languages", "code"));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "gyms", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction
