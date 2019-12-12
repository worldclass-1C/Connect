
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "shortDescription", "shortDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "fullDescription", "fullDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "addDescription", "addDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "startDate", "startDate", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "endDate", "endDate", "date");
	
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "tags", "tags", "valueTable");
	
	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "description", "description", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "shortDescription", "shortDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "fullDescription", "fullDescription", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "addDescription", "addDescription", "string");
	
	attributesPhotos = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");
	
	attributesTags = DataLoad.getValueTable();
	DataLoad.addRowInAttributesTable(attributesTags, "tag", "tag", "ref");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("tags", attributesTags);
	mdStruct.Insert("language", New Structure("languages", "code"));
	mdStruct.Insert("tag", New Structure("tags", "uid"));
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "products", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction