Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "shortDescription", "shortDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "url", "url", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "avaliableForDownload", "avaliableForDownload", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "typeOfFile", "typeOfFile", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "size", "size", "string");
		
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	
	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "shortDescription", "shortDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "fullDescription", "fullDescription", "string");
		
	attributesPhotos = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");
		

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", New Structure("languages", "code"));
		
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "content", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction