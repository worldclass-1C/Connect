
Function createItems(requestName, holding, requestStruct, owner = Undefined, brand) Export

	items = New Array();
	If requestName = "synchronization" Then
		For Each itemObject In requestStruct Do
			itemObject.write();
			items.Add(itemObject.ref);	
		EndDo;
	Else
		attributesStruct = attributesStructure(requestName);
		If TypeOf(requestStruct) = Type("Array") Then
			For Each requestParameter In requestStruct Do
				object = initObjectItem(attributesStruct, requestParameter);
				If object <> Undefined Then
					For Each attribute In attributesStruct.attributesTable Do
						fillField(object, attribute, attributesStruct, requestParameter);
					EndDo;					
					fillPredefinedField(object, attributesStruct, holding, owner, brand);
					If attributesStruct.actType = "write" Then
						try
							object.Write();
						Except
						EndTry;							
					ElsIf attributesStruct.actType = "delete" Then
						object.Read();
						If object.Selected() Then
							object.Delete();
						EndIf;
					EndIf;
					If attributesStruct.mdType <> "informationRegister" Then
						items.Add(object.Ref);
					EndIf;
					If attributesStruct.Property("fillOwnersAttribute") and attributesStruct.fillOwnersAttribute Then
						fillOwnersAttributes(object, attributesStruct, requestParameter);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	Return items;

EndFunction

Procedure fillOwnersAttributes(object, attributesStruct, parameters)
	If attributesStruct.mdObjectName = "users" Then
		If parameters.Property("phoneNumber") and ValueIsFilled(parameters.phoneNumber)Then
			owner = object.ref.owner;
			if not owner.code = parameters.phoneNumber then
				newAccount = findAccount(parameters.phoneNumber, owner);
				if newAccount = Undefined then
					ownerObject = owner.GetObject();
					ownerObject.code = parameters.phoneNumber;
					ownerObject.Write();
				else
					object.owner = newAccount;
					object.write();
					unableTokens(object.Ref);
					rebindUser(newAccount);
				EndIf;	
			EndIf;
		EndIf;
	EndIf;
endprocedure

Procedure unableTokens(user)
	
	query = new query;
	query.Text = "SELECT
	|	tokens.Ref
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.user = &user";
	query.SetParameter("user", user);
	selection = query.Execute().select();
	while selection.Next() do
		token.block(selection.ref);
	EndDo;
	
EndProcedure

Procedure rebindUser(account)
	
	query = new query;
	query.Text = "SELECT
	|	users.Ref
	|FROM
	|	Catalog.users AS users
	|WHERE
	|	users.Owner = &Owner";
	query.SetParameter("Owner", account);
	selection = query.Execute().Select();
	while selection.Next() do
		userObj = selection.Ref.GetObject();
		userObj.owner = Catalogs.accounts.NotPhone;
		userObj.write();
	EndDo;
	
EndProcedure

Function findAccount(phoneNumber, owner)
	query = new query;
	query.Text = "SELECT
	|	accounts.Ref
	|FROM
	|	Catalog.accounts AS accounts
	|WHERE
	|	accounts.Code = &Code
	|	AND accounts.Ref <> &Ref";
	query.SetParameter("Code", phoneNumber);
	query.SetParameter("Ref", owner);
	selection = query.Execute().Select();
	accountRef = Undefined;
	if selection.Next() Then
		accountRef = selection.Ref;
	EndIf;
	return accountRef;
EndFunction	

Function getValueTable() Export
	ValueTable = New ValueTable();
	valueTable.Columns.Add("key");
	valueTable.Columns.Add("value");
	valueTable.Columns.Add("type");
	Return ValueTable;	
EndFunction

Function isUploadRequest(requestName) Export
	If False
		Or requestName = "addchangeusers"					
		Or requestName = "addclassmember" Or requestName = "deleteclassmember"
		Or requestName = "addgymemployees" Or requestName = "deletegymemployees"
		Or requestName = "addgymproducts" Or requestName = "deletegymproducts"
		Or requestName = "addproductmapping" Or requestName = "deleteproductmapping"
		Or requestName = "addprovidedservices"
		Or requestName = "addgymsschedule"
		Or requestName = "addgyms"
		Or requestName = "addrooms"
		Or requestName = "addemployees"				
		Or requestName = "addproducts"
		Or requestName = "addcontent"
		Or requestName = "addtags"
		Or requestName = "addcancelcauses"
		Or requestName = "synchronization"
		Or requestName = "addcache"
		Or requestName = "addusers"
		Or requestName = "addcreditcards"
	Then
		Return True;	
	Else
		Return False;
	EndIf; 
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
	ElsIf requestName = "addgymemployees" or requestName = "deletegymemployees" Then
		Return InformationRegisters.gymsEmployees.attributesStructure(requestName);
	ElsIf requestName = "addgymproducts" or requestName = "deletegymproducts" Then
		Return InformationRegisters.gymsProducts.attributesStructure(requestName);
	ElsIf requestName = "addproductmapping" or requestName = "deleteproductmapping" Then
		Return InformationRegisters.productsMapping.attributesStructure(requestName);			
	ElsIf requestName = "addcancelcauses" Then
		Return Catalogs.cancellationReasons.attributesStructure();
	ElsIf requestName = "addrequest" Then
		Return Catalogs.matchingRequestsInformationSources.attributesStructure();
	ElsIf requestName = "adderrordescription" Then
		Return Catalogs.errorDescriptions.attributesStructure();
	ElsIf requestName = "addtags" Then
		Return Catalogs.tags.attributesStructure();
	ElsIf requestName = "addproducts" Then
		Return Catalogs.products.attributesStructure();
	ElsIf requestName = "addcontent" Then
		Return Catalogs.content.attributesStructure();
	ElsIf requestName = "addrooms" Then
		Return Catalogs.rooms.attributesStructure();
	ElsIf requestName = "addcache" Then
		Return Catalogs.cacheInformations.attributesStructure();
	ElsIf requestName = "addusers" Then
		Return Catalogs.users.attributesStructure();
	ElsIf requestName = "addcreditcards" Then
		Return Catalogs.creditCards.attributesStructure();
	Else
		Return New Structure("mdObjectName, mdType, actType, attributesTable, attributesTableForNewItem, mdStruct", "", "", "", getValueTable(), getValueTable(), New Structure());
	EndIf;	 

EndFunction

Function initObjectItem(attributesStruct, requestParameter)
	
	If attributesStruct.mdType = "catalog" Then
		If attributesStruct.mdObjectName = "accounts" Then
			catalogRef = Catalogs[attributesStruct.mdObjectName].FindByCode(requestParameter.phoneNumber)
		ElsIf attributesStruct.mdObjectName = "languages" Then
			catalogRef = Catalogs[attributesStruct.mdObjectName].FindByCode(requestParameter.code)		
		Else
			catalogRef = Catalogs[attributesStruct.mdObjectName].GetRef(New UUID(requestParameter.uid));
		EndIf;
		If catalogRef = Undefined Or catalogRef.IsEmpty() Then
			object = Undefined;
		Else
			object = catalogRef.GetObject();
		EndIf;		
		
		If object = Undefined Then
			If requestParameter.Property("notCreate") And requestParameter.notCreate Then
				requestParameter.Delete("notCreate");
			Else	
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
	ElsIf attribute.type = "enum" Then
		fillEnum(object, attribute, attributesStruct, requestParameter);	
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
		ElsIf refProperty.key = "segments" Then
			object[attribute.key] = Catalogs[refProperty.key].FindByDescription(requestParameter[attribute.value][refProperty.value]);				
		ElsIf refProperty.key = "_complex" Then
			object[attribute.key] = Catalogs[requestParameter[attribute.value].type].GetRef(New UUID(requestParameter[attribute.value].uid));
		Else
			object[attribute.key] = Catalogs[refProperty.key].GetRef(New UUID(requestParameter[attribute.value][refProperty.value]));
		EndIf;
	EndDo;	
EndProcedure

Procedure fillEnum(object, attribute, attributesStruct, requestParameter)
	For Each refProperty In attributesStruct.mdStruct[attribute.key] Do
		If ValueIsFilled(requestParameter[attribute.value]) Then
			object[attribute.key] = Enums[refProperty.key][requestParameter[attribute.value]];
		Else
			object[attribute.key] = Enums[refProperty.key].EmptyRef();			
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

Procedure fillPredefinedField(object, attributesStruct, holding, owner, brand)
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
			If attributesStruct.mdObjectName = "gyms" Then
				object.brand = brand;
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
