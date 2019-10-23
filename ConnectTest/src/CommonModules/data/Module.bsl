
Function createCatalogItems(requestName, holding, requestStruct, owner = Undefined) Export

	attributesStruct = attributesStructure(requestName);
	requestStruct = requestStruct;
	items = New Array();
		
	If TypeOf(requestStruct) = Type("Array") Then
		For Each requestParameter In requestStruct Do
			object = initObjectItem(attributesStruct, requestParameter);
			For Each attribute In attributesStruct.attributesTable Do
				fillField(object, attribute, attributesStruct, requestParameter);
			EndDo;
			fillPredefinedField(object, attributesStruct, holding, owner);
			If attributesStruct.actType = "write" Then
				object.Write();
			ElsIf attributesStruct.actType = "delete" Then
				object.Read();
				If object.Selected() Then
					object.Delete();
				EndIf;				
			EndIf;
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
	ElsIf requestName = "addclassmember" or requestName = "deleteclassmember" Then
		Return InformationRegisters.classMembers.attributesStructure(requestName);
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
			If requestParameter.Property("isfolder") And requestParameter.isfolder Then
				object = Catalogs[attributesStruct.mdObjectName].CreateFolder();
			Else
				object = Catalogs[attributesStruct.mdObjectName].CreateItem();
			EndIf;
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

Procedure fillField(object, attribute, attributesStruct, requestParameter)
	If attribute.type = "valueTable" Then
		fillValueTable(object, attribute, attributesStruct, requestParameter);
	ElsIf attribute.type = "ref" Then
		fillRef(object, attribute, attributesStruct, requestParameter);
	Else
		fillValue(object, attribute, attributesStruct, requestParameter)
	EndIf;
EndProcedure

Procedure fillValueTable(object, attribute, attributesStruct, requestParameter)
	object[attribute.key].Clear();
	For Each item In requestParameter[attribute.value] Do
		newRow = object[attribute.key].Add();
		For Each tableProperty In attributesStruct.mdStruct[attribute.key] Do
			fillField(newRow, tableProperty, attributesStruct, item);			
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

Procedure fillValue(object, attribute, attributesStruct, requestParameter)
	If attribute.type = "JSON" Then
		object[attribute.key] = HTTP.encodeJSON(requestParameter[attribute.value]);
	ElsIf attribute.type = "boolean" Then
		object[attribute.key] = requestParameter[attribute.value];
	ElsIf attribute.type = "number" Then
		object[attribute.key] = requestParameter[attribute.value];	
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
			If attributesStruct.fillHolding Then
				object.holding = holding;
			EndIf;
			If attributesStruct.mdObjectName = "users" Then
				object.description = "" + owner + " (" + holding + ")";
			EndIf;
		EndIf;
	EndIf;
	object.registrationDate = ToUniversalTime(CurrentDate());			
EndProcedure

Procedure addRowInAttributesTable(attributesTable, key, value,
		type) Export
	newRow			= attributesTable.Add();
	newRow.key		= key;
	newRow.value	= value;
	newRow.type		= type;
EndProcedure
