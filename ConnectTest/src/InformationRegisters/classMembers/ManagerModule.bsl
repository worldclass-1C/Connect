
Function attributesStructure(requestName) Export
	
	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();
	
	data.addRowInAttributesTable(attributesTable, "user", "user", "ref");
	data.addRowInAttributesTable(attributesTable, "class", "class", "ref");

	mdStruct = New Structure();
	mdStruct.Insert("class", New Structure("classesSchedule", "uid"));
	mdStruct.Insert("user", New Structure("users", "uid"));
	
	actType = ?(requestName = "deleteclassmember", "delete", "write"); 
	
	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "classMembers", "informationRegister", actType, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction