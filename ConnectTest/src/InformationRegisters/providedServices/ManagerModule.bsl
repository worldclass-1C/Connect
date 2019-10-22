
Function attributesStructure() Export

	attributesTable = data.getValueTable();
	attributesTableForNewItem = data.getValueTable();

	data.addRowInAttributesTable(attributesTable, "employe", "employe", "ref");
	data.addRowInAttributesTable(attributesTable, "services", "services", "JSON");

	mdStruct = New Structure();
	mdStruct.Insert("employe", New Structure("employees", "uid"));

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "providedServices", False, "informationRegister", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction