
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "code", "code", "string");
	data.addRowInAttributesTable(attributesTable, "performBackground", "performBackground", "boolean");
	data.addRowInAttributesTable(attributesTable, "notSaveAnswer", "notSaveAnswer", "boolean");
	data.addRowInAttributesTable(attributesTable, "compressAnswer", "compressAnswer", "boolean");
	data.addRowInAttributesTable(attributesTable, "staffOnly", "staffOnly", "boolean");

	data.addRowInAttributesTable(attributesTable, "informationSources", "informationSources", "valueTable");

	attributesTableInformationSources = data.getValueTable();

	data.addRowInAttributesTable(attributesTableInformationSources, "atribute", "atribute", "string");
	data.addRowInAttributesTable(attributesTableInformationSources, "performBackground", "performBackground", "boolean");
	data.addRowInAttributesTable(attributesTableInformationSources, "notSaveAnswer", "notSaveAnswer", "boolean");
	data.addRowInAttributesTable(attributesTableInformationSources, "compressAnswer", "compressAnswer", "boolean");
	data.addRowInAttributesTable(attributesTableInformationSources, "staffOnly", "staffOnly", "boolean");
	data.addRowInAttributesTable(attributesTableInformationSources, "notUse", "notUse", "boolean");
	data.addRowInAttributesTable(attributesTableInformationSources, "requestSource", "requestSource", "string");
	data.addRowInAttributesTable(attributesTableInformationSources, "requestReceiver", "requestReceiver", "string");
	data.addRowInAttributesTable(attributesTableInformationSources, "informationSource", "informationSource", "ref");
	
	mdStruct = New Structure();
	mdStruct.Insert("informationSources", attributesTableInformationSources);
	mdStruct.Insert("informationSource", New Structure("informationSources", "uid"));

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "matchingRequestsInformationSources", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction