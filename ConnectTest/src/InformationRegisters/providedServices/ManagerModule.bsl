
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "employe", "employe", "ref");
	data.addRowInAttributesTable(attributesTable, "services", "services", "JSON");

	employeStruct = New Structure();
	employeStruct.Insert("employees", "uid");

	mdStruct = New Structure();
	mdStruct.Insert("employe", employeStruct);

	Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "providedServices", "informationRegister", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction