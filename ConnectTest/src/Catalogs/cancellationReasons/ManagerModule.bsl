
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();
	
	data.addRowInAttributesTable(attributesTable, "description", "name", "string");
		
	mdStruct = New Structure();
	
	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "cancellationReasons", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction