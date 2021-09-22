
Function attributesStructure(requestName) Export
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "gym", "gym", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "employee", "employee", "ref");

	mdStruct = New Structure();
	mdStruct.Insert("employee", New Structure("employees", "uid"));
	mdStruct.Insert("gym", New Structure("gyms", "uid"));
	
	actType = ?(requestName = "deletegymemployees", "delete", "write"); 
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "gymsEmployees", "informationRegister", actType, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction