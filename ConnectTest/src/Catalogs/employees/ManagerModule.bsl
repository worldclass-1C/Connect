
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "photo", "photo", "string");
	data.addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
	data.addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
	data.addRowInAttributesTable(attributesTable, "education", "education", "JSON");
	data.addRowInAttributesTable(attributesTable, "progress", "progress", "JSON");
	data.addRowInAttributesTable(attributesTable, "tagList", "tagList", "JSON");
	data.addRowInAttributesTable(attributesTable, "categoryList", "categoryList", "JSON");
	data.addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
	data.addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");

	attributesTranslation = data.getValueTable();

	data.addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
	data.addRowInAttributesTable(attributesTranslation, "firstName", "firstName", "string");
	data.addRowInAttributesTable(attributesTranslation, "lastName", "lastName", "string");
	data.addRowInAttributesTable(attributesTranslation, "education", "education", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "progress", "progress", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "tagList", "tagList", "JSON");
	data.addRowInAttributesTable(attributesTranslation, "categoryList", "categoryList", "JSON");

	attributesPhotos = data.getValueTable();
	data.addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");

	languageStruct = New Structure();
	languageStruct.Insert("languages", "code");

	mdStruct = New Structure();
	mdStruct.Insert("translation", attributesTranslation);
	mdStruct.Insert("photos", attributesPhotos);
	mdStruct.Insert("language", languageStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "employees", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

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