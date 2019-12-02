
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "code", "code", "string");
	DataLoad.addRowInAttributesTable(attributesTable, "parent", "parent", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "performBackground", "performBackground", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "notSaveAnswer", "notSaveAnswer", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "compressAnswer", "compressAnswer", "boolean");
	DataLoad.addRowInAttributesTable(attributesTable, "staffOnly", "staffOnly", "boolean");

	parentStruct = New Structure();
	parentStruct.Insert("matchingRequestsInformationSources", "uid");

	DataLoad.addRowInAttributesTable(attributesTable, "informationSources", "informationSources", "valueTable");

	attributesTableInformationSources = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "attribute", "attribute", "string");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "performBackground", "performBackground", "boolean");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "notSaveAnswer", "notSaveAnswer", "boolean");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "compressAnswer", "compressAnswer", "boolean");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "staffOnly", "staffOnly", "boolean");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "notUse", "notUse", "boolean");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "requestSource", "requestSource", "string");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "requestReceiver", "requestReceiver", "string");
	DataLoad.addRowInAttributesTable(attributesTableInformationSources, "informationSource", "informationSource", "ref");
	
	mdStruct = New Structure();
	mdStruct.Insert("informationSources", attributesTableInformationSources);
	mdStruct.Insert("informationSource", New Structure("informationSources", "uid"));
	mdStruct.Insert("parent", parentStruct);

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "matchingRequestsInformationSources", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction