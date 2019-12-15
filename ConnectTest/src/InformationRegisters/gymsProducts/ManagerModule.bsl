
Function attributesStructure(requestName) Export
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "productDirection", "productDirection", "enum");
	DataLoad.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "product", "product", "ref");

	mdStruct = New Structure();
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	mdStruct.Insert("product", New Structure("products", "uid"));
	
	actType = ?(requestName = "deletegymproducts", "delete", "write"); 
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "gymsProducts", "informationRegister", actType, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction