Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;
	array = New Array();
	array.Add("cacheType");
	array.Add("user");	
	array.Add("startRotation");
	array.Add("endRotation");
	fields = array;
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation = "" + data.cacheType + " / " + data.user + " / "
		+ Format(data.startRotation, "DF='dd.MM.yyyy'") + " - " + Format(data.endRotation, "DF='dd.MM.yyyy'");
EndProcedure


Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "data", "data", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "user", "user", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "chain", "chain", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "cacheType", "cacheType", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "endRotation", "endRotation", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "startRotation", "startRotation", "date");
	DataLoad.addRowInAttributesTable(attributesTable, "Descriptions", "Descriptions", "valueTable");
	
	attributesDescriptions = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesDescriptions, "Description", "Description", "ref");
	
	mdStruct = New Structure();
	mdStruct.Insert("Descriptions", attributesDescriptions);
	//mdStruct.Insert("Description", New Structure("gyms,products,employees,cacheInformations,rooms"));
	mdStruct.Insert("Description", New Structure("_complex"));
	mdStruct.Insert("user", New Structure("users", "uid"));
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	mdStruct.Insert("products", New Structure("products", "uid"));
	mdStruct.Insert("employees", New Structure("employees", "uid"));
	mdStruct.Insert("cacheInformations", New Structure("cacheInformations", "uid"));
	mdStruct.Insert("rooms", New Structure("rooms", "uid"));
	mdStruct.Insert("cacheType", New Structure("cacheTypes", "uid"));
	mdStruct.Insert("chain", New Structure("chains", "uid"));
	
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct",
		True, "cacheInformations", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction