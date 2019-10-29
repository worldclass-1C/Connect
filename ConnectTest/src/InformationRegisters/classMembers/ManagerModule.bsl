
Function attributesStructure(requestName) Export
	
	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();
	
	DataLoad.addRowInAttributesTable(attributesTable, "user", "user", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "class", "class", "ref");

	mdStruct = New Structure();
	mdStruct.Insert("class", New Structure("classesSchedule", "uid"));
	mdStruct.Insert("user", New Structure("users", "uid"));
	
	actType = ?(requestName = "deleteclassmember", "delete", "write"); 
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "classMembers", "informationRegister", actType, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction