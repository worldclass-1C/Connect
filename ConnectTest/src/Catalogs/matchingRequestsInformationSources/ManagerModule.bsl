
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

	informationSourceStruct = New Structure();
	informationSourceStruct.Insert("informationSources", "uid");

	mdStruct = New Structure();
	mdStruct.Insert("informationSources", attributesTableInformationSources);
	mdStruct.Insert("informationSource", informationSourceStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "matchingRequestsInformationSources", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction