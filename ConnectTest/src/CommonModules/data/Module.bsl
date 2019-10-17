
Function createCatalogItems(requestName, holding, requestStruct, owner = Undefined) Export

	attributesStruct = attributesStructure(requestName);
	requestStruct = requestStruct;
	items = New Array();
		
	If TypeOf(requestStruct) = Type("Array") Then
		For Each requestParameter In requestStruct Do
			object = initObjectItem(attributesStruct, requestParameter);
			For Each attribute In attributesStruct.attributesTable Do
				If attribute.type = "valueTable" Then
					fillValueTable(object, attribute, attributesStruct, requestParameter);
				ElsIf attribute.type = "ref" Then
					fillRef(object, attribute, attributesStruct, requestParameter);
				Else
					fillField(object, attribute, attributesStruct, requestParameter)
				EndIf;
			EndDo;
			fillPredefinedField(object, attributesStruct, holding, owner);
			object.Write();
			If attributesStruct.mdType <> "informationRegister" Then
				items.Add(object.Ref);
			EndIf;
		EndDo;
	EndIf;

	Return items;

EndFunction

//service
Function getValueTable() Export
	ValueTable = New ValueTable;
	valueTable.Columns.Add("key");
	valueTable.Columns.Add("value");
	valueTable.Columns.Add("type");
	Return ValueTable;	
EndFunction

Function attributesStructure(val requestName)

	If requestName = "addChangeAccounts" Then
		Return Catalogs.accounts.attributesStructure();
	ElsIf requestName = "addChangeUsers" Then
		Return Catalogs.users.attributesStructure();
	ElsIf requestName = "addgyms" Then
		Return Catalogs.gyms.attributesStructure();
	ElsIf requestName = "addemployees" Then
		Return Catalogs.employees.attributesStructure();
	ElsIf requestName = "addprovidedservices" Then
		Return InformationRegisters.providedServices.attributesStructure();
	ElsIf requestName = "addgymsschedule" Then
		Return Catalogs.classesSchedule.attributesStructure();
	ElsIf requestName = "addclassmember" Then
		Return InformationRegisters.classMembers.attributesStructure();
	ElsIf requestName = "addcancelcauses" Then
		Return Catalogs.cancellationReasons.attributesStructure();
	ElsIf requestName = "addrequest" Then
		Return Catalogs.matchingRequestsInformationSources.attributesStructure();
	ElsIf requestName = "adderrordescription" Then
		Return Catalogs.errorDescriptions.attributesStructure();
	Else
		Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "", "", "", getValueTable(), getValueTable(), New Structure());
	EndIf;	 

EndFunction

Function initObjectItem(attributesStruct, requestParameter)
	
	If attributesStruct.mdType = "catalog" Then
		If attributesStruct.mdObjectName = "languages" Then
			catalogRef = Catalogs[attributesStruct.mdObjectName].FindByCode(requestParameter.code)
		Else
			catalogRef = Catalogs[attributesStruct.mdObjectName].GetRef(New UUID(requestParameter.uid));
		EndIf;
		object = catalogRef.GetObject();
		If object = Undefined Then
			object = Catalogs[attributesStruct.mdObjectName].CreateItem();
			object.SetNewObjectRef(catalogRef);
			object.SetNewCode();
			For Each attribute In attributesStruct.attributesTableForNewItem Do
				object[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);
			EndDo;
		EndIf;
	ElsIf attributesStruct.mdType = "informationRegister" Then
		object = InformationRegisters[attributesStruct.mdObjectName].CreateRecordManager();	
	EndIf;
	
	Return object;
	
EndFunction

Procedure fillValueTable(object, attribute, attributesStruct, requestParameter)
	object[attribute.key].Clear();
	For Each item In requestParameter[attribute.value] Do
		newRow = object[attribute.key].Add();
		For Each tableProperty In attributesStruct.mdStruct[attribute.key] Do
			If tableProperty.type = "ref" Then
				For Each refProperty In attributesStruct.mdStruct[tableProperty.key] Do
					If refProperty.key = "languages" Then
						newRow[tableProperty.key] = Catalogs[refProperty.key].FindByCode(item[tableProperty.value][refProperty.value]);
					Else
						newRow[tableProperty.key] = Catalogs[refProperty.key].GetRef(New UUID(item[tableProperty.value][refProperty.value]));
					EndIf;
				EndDo;
			ElsIf tableProperty.type = "JSON" Then
				newRow[tableProperty.key] = HTTP.encodeJSON(item[tableProperty.value]);	
			Else
				newRow[tableProperty.key] = item[tableProperty.value];
			EndIf;
		EndDo;
	EndDo;	
EndProcedure

Procedure fillRef(object, attribute, attributesStruct, requestParameter)
	For Each refProperty In attributesStruct.mdStruct[attribute.key] Do
		If refProperty.key = "languages" Then
			object[attribute.key] = Catalogs[refProperty.key].FindByCode(requestParameter[attribute.value][refProperty.value]);
		Else
			object[attribute.key] = Catalogs[refProperty.key].GetRef(New UUID(requestParameter[attribute.value][refProperty.value]));
		EndIf;
	EndDo;	
EndProcedure

Procedure fillField(object, attribute, attributesStruct, requestParameter)
	If attribute.type = "JSON" Then
		object[attribute.key] = HTTP.encodeJSON(requestParameter[attribute.value]);
	Else
		object[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);
	EndIf;		
EndProcedure

Procedure fillPredefinedField(object, attributesStruct, holding, owner)
	If attributesStruct.mdObjectName <> "matchingRequestsInformationSources" Then
		If attributesStruct.mdType = "catalog" Then
			If owner <> Undefined Then
				object.owner = owner;
			EndIf;
			If attributesStruct.mdObjectName <> "accounts" Then
				object.holding = holding;
			EndIf;
			If attributesStruct.mdObjectName = "users" Then
				object.description = "" + owner + " (" + holding + ")";
			EndIf;
		EndIf;
		object.registrationDate = ToUniversalTime(CurrentDate());
	EndIf;		
EndProcedure

Procedure addRowInAttributesTable(attributesTable, key, value,
		type) Export
	newRow			= attributesTable.Add();
	newRow.key		= key;
	newRow.value	= value;
	newRow.type		= type;
EndProcedure
