
Function attributesStructure() Export
	
	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();
	
	data.addRowInAttributesTable(attributesTable, "uid", "uid", "string");
	data.addRowInAttributesTable(attributesTable, "class", "class", "ref");

	classStruct = New Structure();
	classStruct.Insert("classesSchedule", "uid");

	mdStruct = New Structure();
	mdStruct.Insert("class", classStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "classMembers", "informationRegister", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction