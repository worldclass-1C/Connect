
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "gender", "gender", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "active", "active", "boolean");	
	DataLoad.addRowInAttributesTable(attributesTable, "descriptionFull", "descriptionFull", "JSON");
	DataLoad.addRowInAttributesTable(attributesTable, "categoryList", "categoryList", "JSON");
	
	DataLoad.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
	DataLoad.addRowInAttributesTable(attributesTable, "tags", "tags", "valueTable");

	attributesTranslation = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	DataLoad.addRowInAttributesTable(attributesTranslation, "firstName", "firstName", "string");
	DataLoad.addRowInAttributesTable(attributesTranslation, "lastName", "lastName", "string");	
	DataLoad.addRowInAttributesTable(attributesTranslation, "descriptionFull", "descriptionFull", "JSON");	
	//DataLoad.addRowInAttributesTable(attributesTranslation, "categoryList", "categoryList", "JSON");
	
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

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "employees", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction

Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;
	array = New Array();
	array.Add("firstName");
	array.Add("lastName");
	array.Add("holding");
	fields = array;
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation = "" + data.firstName + " " + data.lastName + " ("
		+ data.holding + ")";
EndProcedure