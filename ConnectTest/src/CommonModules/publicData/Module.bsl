
Function createCatalogItems(requestName, holding, requestStruct, owner = Undefined) Export

	attributesStruct = attributesStructure(requestName);
	requestStruct = requestStruct;
	items = New Array();
		
	If TypeOf(requestStruct) = Type("Array") Then
		For Each requestParameter In requestStruct Do		
			catalogObject = initCatalogItem(attributesStruct, requestParameter);			
			For Each attribute In attributesStruct.attributesTable Do			
				If attribute.type = "valueTable" Then
					fillValueTable(catalogObject, attribute, attributesStruct, requestParameter);					
				ElsIf attribute.type = "ref" Then
					fillRef(catalogObject, attribute, attributesStruct, requestParameter);					
				Else
					fillField(catalogObject, attribute, attributesStruct, requestParameter)	
				EndIf;
			EndDo;
			fillPredefinedField(catalogObject, attributesStruct, holding, owner);
			catalogObject.Write();
			items.Add(catalogObject.Ref);			
		EndDo;
	EndIf;

	Return items;

EndFunction

Function attributesStructure(requestName)

	attributesTable = getValueTable();

	attributesTableForNewItem = getValueTable();

	mdStruct = New Structure();
	mdObjectName = "";

	If requestName = "addChangeAccounts" Then

		mdObjectName = "accounts";
		addRowInAttributesTable(attributesTable, "code", "phoneNumber", "string");
		addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
		addRowInAttributesTable(attributesTable, "secondName", "secondName", "string");
		addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
		addRowInAttributesTable(attributesTable, "birthday", "birthdayDate", "date");
		addRowInAttributesTable(attributesTable, "gender", "gender", "string");		
		addRowInAttributesTable(attributesTable, "email", "email", "string");
		
	elsIf requestName = "addChangeUsers" Then

		mdObjectName = "users";		
		addRowInAttributesTable(attributesTable, "userCode", "cid", "string");		
		addRowInAttributesTable(attributesTable, "userType", "userType", "string");
		addRowInAttributesTable(attributesTable, "barCode", "barcode", "string");
		addRowInAttributesTable(attributesTable, "notSubscriptionEmail", "noSubscriptionEmail", "boolean");
		addRowInAttributesTable(attributesTable, "notSubscriptionSms", "noSubscriptionSms", "boolean");
				
	ElsIf requestName = "addgyms" Then

		mdObjectName = "gyms";
		addRowInAttributesTable(attributesTable, "description", "name", "string");
		addRowInAttributesTable(attributesTable, "address", "gymAddress", "string");
		addRowInAttributesTable(attributesTable, "segment", "division", "string");
		addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
		addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
		addRowInAttributesTable(attributesTable, "type", "type", "string");
		addRowInAttributesTable(attributesTable, "photo", "photo", "string");		
		addRowInAttributesTable(attributesTable, "departmentWorkSchedule", "departments", "JSON");
		addRowInAttributesTable(attributesTable, "nearestMetro", "metro", "JSON");
		addRowInAttributesTable(attributesTable, "city", "city", "ref");
		addRowInAttributesTable(attributesTable, "translation", "translation", "valueTable");
		addRowInAttributesTable(attributesTable, "photos", "photos", "valueTable");
		
		attributesTranslation = getValueTable();
		
		addRowInAttributesTable(attributesTranslation, "language", "language", "ref");
		addRowInAttributesTable(attributesTranslation, "description", "description", "string");
		addRowInAttributesTable(attributesTranslation, "address", "gymAddress", "string");		
		addRowInAttributesTable(attributesTranslation, "departmentWorkSchedule", "departments", "JSON");
		addRowInAttributesTable(attributesTranslation, "nearestMetro", "metro", "JSON");

		attributesPhotos = getValueTable();
		addRowInAttributesTable(attributesPhotos, "URL", "URL", "string");
		
		cityStruct = New Structure();
		cityStruct.Insert("cities", "uid");
		
		languageStruct = New Structure();
		languageStruct.Insert("languages", "code");

		mdStruct.Insert("translation", attributesTranslation);
		mdStruct.Insert("photos", attributesPhotos);
		mdStruct.Insert("city", cityStruct);
		mdStruct.Insert("language", languageStruct);

	ElsIf requestName = "addcities" Then

		mdObjectName = "cities";
		addRowInAttributesTable(attributesTable, "description", "name", "string");

	ElsIf requestName = "addcancelcauses" Then

		mdObjectName = "cancellationReasons";
		addRowInAttributesTable(attributesTable, "description", "name", "string");

	ElsIf requestName = "addrequest" Then

		mdObjectName = "matchingRequestsInformationSources";
		addRowInAttributesTable(attributesTable, "code", "code", "string");
		addRowInAttributesTable(attributesTable, "performBackground", "performBackground", "boolean");
		addRowInAttributesTable(attributesTable, "notSaveAnswer", "notSaveAnswer", "boolean");
		addRowInAttributesTable(attributesTable, "compressAnswer", "compressAnswer", "boolean");
		addRowInAttributesTable(attributesTable, "staffOnly", "staffOnly", "boolean");

		addRowInAttributesTable(attributesTable, "informationSources", "informationSources", "valueTable");

		attributesTableInformationSources = getValueTable();

		addRowInAttributesTable(attributesTableInformationSources, "atribute", "atribute", "string");
		addRowInAttributesTable(attributesTableInformationSources, "performBackground", "performBackground", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "notSaveAnswer", "notSaveAnswer", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "compressAnswer", "compressAnswer", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "staffOnly", "staffOnly", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "notUse", "notUse", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "requestSource", "requestSource", "string");
		addRowInAttributesTable(attributesTableInformationSources, "requestReceiver", "requestReceiver", "string");
		addRowInAttributesTable(attributesTableInformationSources, "informationSource", "informationSource", "ref");

		informationSourceStruct = New Structure();
		informationSourceStruct.Insert("informationSources", "uid");

		mdStruct.Insert("informationSources", attributesTableInformationSources);
		mdStruct.Insert("informationSource", informationSourceStruct);
	
	ElsIf requestName = "adderrordescription" Then

		mdObjectName = "errorDescriptions";
		addRowInAttributesTable(attributesTable, "code", "code", "string");
		addRowInAttributesTable(attributesTable, "parent", "parent", "ref");

		parentStruct = New Structure();
		parentStruct.Insert("parent", "uid");

		attributesTranslation = getValueTable();
		
		addRowInAttributesTable(attributesTranslation, "language", "language", "string");
		addRowInAttributesTable(attributesTranslation, "description", "description", "string");
		
		mdStruct.Insert("translation", attributesTranslation);		
		mdStruct.Insert("parent", parentStruct);
		
	EndIf;

	Return New Structure("mdObjectName, attributesTable, attributesTableForNewItem, mdStruct", mdObjectName, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction

Function getValueTable()
	ValueTable = New ValueTable;
	valueTable.Columns.Add("key");
	valueTable.Columns.Add("value");
	valueTable.Columns.Add("type");
	Return ValueTable;	
EndFunction

Function initCatalogItem(attributesStruct, requestParameter)
	If attributesStruct.mdObjectName = "languages" Then
		catalogRef = Catalogs[attributesStruct.mdObjectName].FindByCode(requestParameter.code)
	Else
		catalogRef = Catalogs[attributesStruct.mdObjectName].GetRef(New UUID(requestParameter.uid));
	EndIf;
	catalogObject = catalogRef.GetObject();
	If catalogObject = Undefined Then
		catalogObject = Catalogs[attributesStruct.mdObjectName].CreateItem();
		catalogObject.SetNewObjectRef(catalogRef);
		catalogObject.SetNewCode();
		For Each attribute In attributesStruct.attributesTableForNewItem Do
			catalogObject[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);
		EndDo;
	EndIf;
	Return catalogObject;
EndFunction

Procedure fillValueTable(catalogObject, attribute, attributesStruct, requestParameter)
	catalogObject[attribute.key].Clear();
	For Each item In requestParameter[attribute.value] Do
		newRow = catalogObject[attribute.key].Add();
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

Procedure fillRef(catalogObject, attribute, attributesStruct, requestParameter)
	For Each refProperty In attributesStruct.mdStruct[attribute.key] Do
		If refProperty.key = "languages" Then
			catalogObject[attribute.key] = Catalogs[refProperty.key].FindByCode(requestParameter[attribute.value][refProperty.value]);
		Else
			catalogObject[attribute.key] = Catalogs[refProperty.key].GetRef(New UUID(requestParameter[attribute.value][refProperty.value]));
		EndIf;
	EndDo;	
EndProcedure

Procedure fillField(catalogObject, attribute, attributesStruct, requestParameter)
	If attribute.type = "JSON" Then
		catalogObject[attribute.key] = HTTP.encodeJSON(requestParameter[attribute.value]);
	Else
		catalogObject[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);
	EndIf;		
EndProcedure

Procedure fillPredefinedField(catalogObject, attributesStruct, holding, owner)
	If attributesStruct.mdObjectName <> "matchingRequestsInformationSources" Then
		If owner <> Undefined Then
			catalogObject.owner = owner;
		EndIf;
		If attributesStruct.mdObjectName <> "accounts" Then
			catalogObject.holding = holding;
		EndIf;
		If attributesStruct.mdObjectName = "users" Then
			catalogObject.description = "" + owner + " (" + holding + ")";
		EndIf;
		catalogObject.registrationDate = ToUniversalTime(CurrentDate());
	EndIf;		
EndProcedure

Procedure addRowInAttributesTable(attributesTable, key, value,
		type)
	newRow			= attributesTable.Add();
	newRow.key		= key;
	newRow.value	= value;
	newRow.type		= type;
EndProcedure
