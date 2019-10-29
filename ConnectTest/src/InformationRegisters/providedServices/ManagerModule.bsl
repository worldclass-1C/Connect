
Function attributesStructure() Export

	attributesTable = DataLoad.getValueTable();
	attributesTableForNewItem = DataLoad.getValueTable();

	DataLoad.addRowInAttributesTable(attributesTable, "employe", "employe", "ref");
	DataLoad.addRowInAttributesTable(attributesTable, "services", "services", "JSON");

	mdStruct = New Structure();
	mdStruct.Insert("employe", New Structure("employees", "uid"));

	Return New Structure("fillHolding, mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", False, "providedServices", "informationRegister", "write", attributesTable, attributesTableForNewItem, mdStruct);

EndFunction