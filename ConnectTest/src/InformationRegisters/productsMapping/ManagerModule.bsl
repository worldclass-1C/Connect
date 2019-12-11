
Function attributesStructure(requestName) Export
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
		
	DataLoad.addRowInAttributesTable(attributesTable, "product", "product", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "uid", "uid", "string");
	
	mdStruct = New Structure();	
	mdStruct.Insert("product", New Structure("products", "uid"));
	
	actType = ?(requestName = "deleteproductmapping", "delete", "write"); 
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "gymsEmployees", "informationRegister", actType, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction