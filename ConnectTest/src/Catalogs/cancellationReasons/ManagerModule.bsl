
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "description", "name", "string");
		
	mdStruct = New Structure();
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", True, "cancellationReasons", "catalog", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction