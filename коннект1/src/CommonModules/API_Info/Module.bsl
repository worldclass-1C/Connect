
Procedure gymInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	gymStruct = New Structure();
		
	If Not requestStruct.Property("uid") Then	
		parameters.Insert("error", "gymError");
	Else
		query = New Query();
		query.Text = "SELECT TOP 1
		|	gyms.Ref,
		|	gyms.latitude,
		|	gyms.longitude,
		|	ISNULL(gyms.segment.Description, """") AS segment,
		|	ISNULL(gyms.segment.color, """") AS segmentColor,
		|	CASE
		|		WHEN gymstranslation.description IS NULL
		|			THEN gyms.Description
		|		WHEN gymstranslation.description = """"
		|			THEN gyms.Description
		|		ELSE gymstranslation.description
		|	END AS Description,
		|	CASE
		|		WHEN gymstranslation.address IS NULL
		|			THEN gyms.address
		|		WHEN gymstranslation.address = """"
		|			THEN gyms.address
		|		ELSE gymstranslation.address
		|	END AS address,
		|	CASE
		|		WHEN gymstranslation.departmentWorkSchedule IS NULL
		|			THEN gyms.departmentWorkSchedule
		|		WHEN gymstranslation.departmentWorkSchedule = ""[]""
		|			THEN gyms.departmentWorkSchedule
		|		ELSE gymstranslation.departmentWorkSchedule
		|	END AS departments,
		|	CASE
		|		WHEN gymstranslation.nearestMetro IS NULL
		|			THEN gyms.nearestMetro
		|		WHEN gymstranslation.nearestMetro = ""[]""
		|			THEN gyms.nearestMetro
		|		ELSE gymstranslation.nearestMetro
		|	END AS nearestMetro,
		|	CASE
		|		WHEN gymstranslation.additional IS NULL
		|			THEN gyms.additional
		|		ELSE gymstranslation.additional
		|	END AS additional,
		|	CASE
		|		WHEN gymstranslation.state IS NULL
		|			THEN gyms.state
		|		WHEN gymstranslation.state = """"
		|			THEN gyms.state
		|		ELSE gymstranslation.state
		|	END AS state,
		|	gyms.photos.(
		|		URL)
		|FROM
		|	Catalog.gyms AS gyms
		|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
		|		ON gymstranslation.Ref = gyms.Ref
		|		AND gymstranslation.language = &language
		|WHERE
		|	NOT gyms.DeletionMark
		|	AND gyms.Ref = &gym
		|	AND gyms.startDate <= &currentTime
		|	AND gyms.endDate >= &currentTime";

		query.SetParameter("gym", XMLValue(Type("CatalogRef.gyms"), requestStruct.uid));
		query.SetParameter("language", language);
		query.SetParameter("currentTime", parameters.currentTime);		

		select = query.Execute().Select();

		If select.Next() Then
			
			gymStruct.Insert("uid", XMLString(select.Ref));
			gymStruct.Insert("gymId", gymStruct.uid);
			gymStruct.Insert("name", select.Description);
			gymStruct.Insert("type", "");
			gymStruct.Insert("state", select.state);			
			gymStruct.Insert("address", select.address);
			
			coords = New Structure();
			coords.Insert("latitude", select.latitude);
			coords.Insert("longitude", select.longitude);
			gymStruct.Insert("coords", coords);
			
			segment = New Structure();
			segment.Insert("name", select.segment);
			segment.Insert("color", select.segmentColor);
			gymStruct.Insert("segment", segment);			
			
			gymStruct.Insert("departments", HTTP.decodeJSON(select.departments, Enums.JSONValueTypes.array));
			gymStruct.Insert("metro", HTTP.decodeJSON(select.nearestMetro, Enums.JSONValueTypes.array));
			gymStruct.Insert("additional", HTTP.decodeJSON(select.additional, Enums.JSONValueTypes.array));
						 
			gymStruct.Insert("photos", select.photos.Unload().UnloadColumn("URL"));
						
		EndIf;
		
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymStruct));		
	
EndProcedure

Procedure employeeInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	struct = New Structure();
	
	If Not requestStruct.Property("uid") Then		
		parameters.Insert("error", "stuff");
	Else
		query = New Query("SELECT
		|	employees.Ref AS employee,
		|	employees.firstName,
		|	employees.lastName,
		|	employees.gender,
		|	employees.descriptionFull,
		|	employees.categoryList,
		|	employees.photo AS photo
		|INTO TT
		|FROM
		|	Catalog.employees AS employees
		|WHERE
		|	employees.Ref = &employee
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.employee,
		|	ISNULL(employeestranslation.firstName, TT.firstName) AS firstName,
		|	ISNULL(employeestranslation.lastName, TT.lastName) AS lastName,
		|	TT.gender,
		|	ISNULL(employeestranslation.descriptionFull, TT.descriptionFull) AS descriptionFull,
		|	ISNULL(employeestranslation.categoryList, TT.categoryList) AS categoryList,
		|	TT.photo AS photo
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.employees.translation AS employeestranslation
		|		ON TT.employee = employeestranslation.Ref
		|		AND employeestranslation.language = &language
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.employee AS employee,
		|	ISNULL(tagstranslation.description, ISNULL(employeestags.tag.Description, """")) AS tag,
		|	ISNULL(employeestags.tag.level, 0) AS level,
		|	ISNULL(employeestags.tag.weight, 0) AS weight
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.employees.tags AS employeestags
		|			LEFT JOIN Catalog.tags.translation AS tagstranslation
		|			ON employeestags.tag = tagstranslation.Ref
		|			AND tagstranslation.language = &language
		|		ON TT.employee = employeestags.Ref
		|WHERE
		|	NOT employeestags.Ref IS NULL
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.employee,
		|	employeeshotos.URL
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.employees.photos AS employeeshotos
		|		ON TT.employee = employeeshotos.Ref
		|WHERE
		|	NOT employeeshotos.URL IS NULL");

		query.SetParameter("employee", XMLValue(Type("CatalogRef.employees"), requestStruct.uid));
		query.SetParameter("language", language);				
		
		results = query.ExecuteBatch();
		select = results[1].Select();
		selectTags = results[2].Select();
		selectPhotos = results[3].Select();

		If select.Next() Then			
			struct.Insert("uid", requestStruct.uid);
			struct.Insert("firstName", select.firstName);
			struct.Insert("lastName", select.lastName);
			struct.Insert("gender", select.gender);			
			struct.Insert("isMyCoach", False);
			struct.Insert("categoryList", new Array());			
			
			presentationArray = HTTP.decodeJSON(select.descriptionFull, Enums.JSONValueTypes.array);
			presentationArrayFinal = New Array();
			For Each presentation In presentationArray Do
				If presentation.Property("description")
						And TypeOf(presentation.description) = Type("Array")
						And presentation.description.count() > 0 Then
					presentationArrayFinal.Add(presentation);	
				EndIf;
			EndDo; 
			struct.Insert("presentation", presentationArrayFinal);			
			
			tagArray = New Array();
			While selectTags.FindNext(New Structure("employee", select.employee)) Do
				tagStruct = New Structure();
				tagStruct.Insert("tag", XMLString(selectTags.tag));
				tagStruct.Insert("level", selectTags.level);
				tagStruct.Insert("weight", selectTags.weight);
				tagArray.Add(tagStruct);
			EndDo;
			struct.Insert("tagList", tagArray);
			selectTags.Reset();
			
			photoArray = New Array();
			While selectPhotos.FindNext(New Structure("employee", select.employee)) Do
				photoArray.Add(selectPhotos.url);
			EndDo;			
			struct.Insert("photos", photoArray);
			selectPhotos.Reset();
		EndIf;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
		
EndProcedure

Procedure productInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;	
	productStruct = New Structure();

	query = New Query();
	query.Text = "SELECT
	|	&product AS product
	|INTO TT1
	|WHERE
	|	&selectByProduct
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	productsMapping.product
	|FROM
	|	InformationRegister.productsMapping AS productsMapping
	|WHERE
	|	productsMapping.uid = &entryListUid
	|	AND
	|	NOT &selectByProduct
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	products.Ref AS product,
	|	products.Description AS Description,
	|	products.shortDescription AS shortDescription,
	|	products.fullDescription AS fullDescription,
	|	products.addDescription AS addDescription,
	|	products.composition AS composition,
	|	products.attribute AS attribute
	|INTO TT
	|FROM
	|	TT1 AS TT1
	|		LEFT JOIN Catalog.products AS products
	|		ON TT1.product = products.Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product AS product,
	|	ISNULL(productstranslation.description, TT.Description) AS description,
	|	ISNULL(productstranslation.shortDescription, TT.shortDescription) AS shortDescription,
	|	ISNULL(productstranslation.fullDescription, TT.fullDescription) AS fullDescription,
	|	ISNULL(productstranslation.addDescription, TT.addDescription) AS addDescription,
	|	TT.composition,
	|	TT.attribute
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.translation AS productstranslation
	|		ON TT.product = productstranslation.Ref
	|		AND productstranslation.language = &language
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.product AS product,
	|	ISNULL(tagstranslation.description, ISNULL(productstags.tag.Description, """")) AS tag,
	|	ISNULL(productstags.tag.level, 0) AS level,
	|	ISNULL(productstags.tag.weight, 0) AS weight
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.tags AS productstags
	|			LEFT JOIN Catalog.tags.translation AS tagstranslation
	|			ON productstags.tag = tagstranslation.Ref
	|			AND tagstranslation.language = &language
	|		ON TT.product = productstags.Ref
	|WHERE
	|	NOT productstags.Ref IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product AS product,
	|	productsMapping.uid AS uid,
	|	productsMapping.entryType AS entryType
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.productsMapping AS productsMapping
	|		ON TT.product = productsMapping.product
	|WHERE
	|	NOT productsMapping.uid IS NULL
	|	AND productsMapping.uid IN (&entryList)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product AS product,
	|	productsphotos.URL AS URL
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.photos AS productsphotos
	|		ON TT.product = productsphotos.Ref
	|WHERE
	|	NOT productsphotos.URL IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT1.product AS product,
	|	contentTab.url AS url,
	|	contentTab.typeOfFile AS typeOfFile,
	|	ISNULL(contenttranslation.description, contentTab.Description) AS description,
	|	contentTab.Ref AS content
	|FROM
	|	TT1 AS TT1
	|		LEFT JOIN Catalog.products.content AS productscontentTab
	|			LEFT JOIN Catalog.content AS contentTab
	|				LEFT JOIN Catalog.content.translation AS contenttranslation
	|				ON contenttranslation.Ref = contentTab.Ref
	|			ON productscontentTab.contentRef = contentTab.Ref
	|		ON TT1.product = productscontentTab.Ref
	|WHERE
	|	NOT contentTab.Ref IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT1.product,
	|	productsauthors.author,
	|	ISNULL(employeestranslation.firstName, employees.firstName) AS firstName,
	|	ISNULL(employeestranslation.lastName, employees.lastName) AS lastName
	|FROM
	|	TT1 AS TT1
	|		LEFT JOIN Catalog.products.authors AS productsauthors
	|			LEFT JOIN Catalog.employees AS employees
	|				LEFT JOIN Catalog.employees.translation AS employeestranslation
	|				ON employees.Ref = employeestranslation.Ref
	|				AND employeestranslation.language = &language
	|			ON productsauthors.author = employees.Ref
	|		ON TT1.product = productsauthors.Ref
	|WHERE
	|	NOT productsauthors.author.ref IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 1
	|	TT1.product,
	|	ISNULL(gymsProducts.price, UNDEFINED) AS price
	|FROM
	|	TT1 AS TT1
	|		LEFT JOIN InformationRegister.gymsProducts AS gymsProducts
	|		ON gymsProducts.product = TT1.product
	|		AND gymsProducts.gym = &gym";
	
	entryListUid = "";
	If requestStruct.Property("entryList") And requestStruct.entryList.count() > 0 Then		
		entryListArray = New Array();
		For Each entryType In requestStruct.entryList Do
			entryListArray.Add(entryType.uid);
			entryListUid = entryType.uid;				
		EndDo;		 
		query.SetParameter("entryList", entryListArray);
	Else
		query.Text = StrReplace(query.Text, "AND productsMapping.uid IN (&entryList)", "");		
	EndIf;	
	If requestStruct.Property("uid") And StrLen(requestStruct.uid) = 36 Then
		query.SetParameter("product", XMLValue(Type("CatalogRef.products"), requestStruct.uid));
		query.SetParameter("selectByProduct", True);
	Else
		query.SetParameter("product", Catalogs.products.EmptyRef());
		query.SetParameter("selectByProduct", False);	
	EndIf;	
	query.SetParameter("language", 		language);
	query.SetParameter("gym", 			General.getOnlineGym(parameters));
	query.SetParameter("holding",  		tokenContext.holding);
	query.SetParameter("brand",  		parameters.brand);
	query.SetParameter("entryListUid", 	entryListUid);
		
	results = query.ExecuteBatch();
	select = results[2].Select();
	selectTags = results[3].Select();
	selectMapping = results[4].Select();
	selectPhotos = results[5].Select();
	selectFiles = results[6].Select();
	selectAuthor = results[7].Select();
	selectPrice = results[8].Select();
	
	While select.Next() Do		
		productStruct.Insert("uid", XMLString(select.product));		
		productStruct.Insert("name", select.description);		
		productStruct.Insert("shortDescription", select.shortDescription);
		productStruct.Insert("fullDescription", select.fullDescription);
		productStruct.Insert("addDescription", select.addDescription);
				
		productStruct.Insert("composition", HTTP.decodeJSON(select.composition, Enums.JSONValueTypes.array));
		productStruct.Insert("attribute", HTTP.decodeJSON(select.attribute, Enums.JSONValueTypes.array));
		
		photoArray = New Array();
		While selectPhotos.FindNext(New Structure("product", select.product)) Do
			photoArray.Add(selectPhotos.url);
		EndDo;
		If photoArray.Count() = 0 Then
			photoArray.Add("" + GeneralReuse.getBaseImgURL() + "/service/fitness.jpg");
		EndIf;	
		productStruct.Insert("photoList", photoArray);
		selectPhotos.Reset();		
		
		tagArray = New Array();
		While selectTags.FindNext(New Structure("product", select.product)) Do
			tagStruct = New Structure();
			tagStruct.Insert("tag", XMLString(selectTags.tag));
			tagStruct.Insert("level", selectTags.level);
			tagStruct.Insert("weight", selectTags.weight);
			tagArray.Add(tagStruct);
		EndDo;
		productStruct.Insert("tagList", tagArray);
		selectTags.Reset();
		
		entryArray = New Array();
		While selectMapping.FindNext(New Structure("product", select.product)) Do
			entryStruct = New Structure();
			entryStruct.Insert("uid", selectMapping.uid);
			entryStruct.Insert("entryType", selectMapping.entryType);			
			entryArray.Add(entryStruct);
		EndDo;
		productStruct.Insert("entryList", entryArray);
		selectMapping.Reset();
		
		filesArray = New Array();
		While selectFiles.FindNext(New Structure("product", select.product)) Do
			fileStruct = New Structure();
			fileStruct.Insert("uid", XMLString(selectFiles.content));
			fileStruct.Insert("name", selectFiles.description);
			fileStruct.Insert("url", selectFiles.url);
			fileStruct.Insert("type", selectFiles.typeOfFile);			
			filesArray.Add(fileStruct);
		EndDo;
		if filesArray.Count()>0 then
			productStruct.Insert("content", filesArray);
		else
			productStruct.Insert("content", Undefined);
		EndIf;
		selectFiles.Reset();
		
		authorArray = New Array();
		While selectAuthor.FindNext(New Structure("product", select.product)) Do
			authorStruct = New Structure();
			authorStruct.Insert("uid", XMLString(selectAuthor.author));
			authorStruct.Insert("firstName", selectAuthor.firstName);
			authorStruct.Insert("lastName", selectAuthor.lastName);			
			authorArray.Add(authorStruct);
		EndDo;
		if authorArray.Count()>0 then
			productStruct.Insert("author", authorArray);
		else
			productStruct.Insert("author", Undefined);
		EndIf;
		
		selectAuthor.Reset();	
		
		Price = Undefined;
		While selectPrice.FindNext(New Structure("product", select.product)) Do
			productStruct.Insert("price", selectPrice.price);
			Price = selectPrice.price;
		EndDo;
		selectPrice.Reset();
		
		if Price <> Undefined and Price <> "" then
			parametersNew = Service.getStructCopy(parameters);
			parametersNew.requestName = "isMyCourse";
			parametersNew.Insert("requestStruct",new Structure("uid", XMLString(select.product)));
			general.executeRequestMethod(parametersNew);
			Service.logRequestBackground(parametersNew);
			isMyCourse = false;
			error = parametersNew.error;
			If error = "" Then
				answerStruct = HTTP.decodeJSON(parametersNew.answerBody);
				If answerStruct.Count() > 0 Then
					isMyCourse = true;	
				EndIf;
			EndIf;
			productStruct.Insert("isMyCourse", isMyCourse);
		EndIf;
		
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(productStruct));
	
EndProcedure

Procedure accountProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Account.profile(parameters.tokenContext.account)));		
EndProcedure

Procedure userProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Users.profile(parameters.tokenContext.user, parameters.tokenContext.appType,parameters.tokenContext.chain)));	
EndProcedure

Procedure userSummary(parameters) Export
	parameters.Insert("answerBody", "metod not used");
//	tokenContext = parameters.tokenContext;
//	
//	query = New Query("SELECT
//	|	chainscacheValues.cacheType.Code AS cacheCode,
//	|	usersStates.stateValue AS cacheValue,
//	|	chainscacheValues.cacheType.defaultValueType AS defaultValueType
//	|FROM
//	|	Catalog.chains.cacheTypes AS chainscacheValues
//	|		LEFT JOIN InformationRegister.usersStates AS usersStates
//	|		ON chainscacheValues.cacheType = usersStates.cacheType
//	|		AND usersStates.user = &user
//	|		AND usersStates.appType = &appType
//	|WHERE
//	|	chainscacheValues.Ref = &chain
//	|	AND chainscacheValues.isUsed");
//	
//	query.SetParameter("chain", tokenContext.chain);
//	query.SetParameter("user", tokenContext.user);
//	query.SetParameter("appType", tokenContext.appType);
//	
//	struct = New Structure();
//	select = query.Execute().Select();
//	While select.Next() Do
//		struct.Insert(select.cacheCode, HTTP.decodeJSON(?(select.cacheValue = null, "", select.cacheValue), select.defaultValueType));
//	EndDo;
//		
//	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure

Procedure generalcache(parameters) Export
	
	If Not requestIsStructure(parameters) Then
		Return
	EndIf;
	
	types = Undefined;
	If Not parameters.requestStruct.Property("types",types) or Not  Type("Array") = TypeOf(types)  Then
		noValidRequest(parameters);
		Return
	EndIf;
	
	struct = Cache.GetCache(parameters,New Structure("user,holding,chain,languageCode,language,cacheTypes",
												parameters.tokenContext.user,
												parameters.tokenContext.holding,
												parameters.tokenContext.chain,
												parameters.languageCode,
												parameters.language,
												getCorrectTypes(types)));
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Function requestIsStructure(parameters)
	Res = true;
	If Not Type("Structure") = TypeOf(parameters.requestStruct) Then
		noValidRequest(parameters);
		Res = False
	EndIf;
	
	Return Res;
EndFunction

Procedure noValidRequest(parameters)
	parameters.Insert("error","noValidRequest");
EndProcedure

Procedure clearcache(parameters) Export
	
	If Not requestIsStructure(parameters) Then
		Return
	EndIf;
	
	types = Undefined; date= Undefined;
	If Not parameters.requestStruct.Property("types",types) or Not  Type("Array") = TypeOf(types)  Then
		noValidRequest(parameters);
		Return
	EndIf;
	If Not parameters.requestStruct.Property("date",date) Then
		noValidRequest(parameters);
		Return
	EndIf;
	
	Try
		date = XMLValue(type("Date"),date)
	Except
		noValidRequest(parameters);
		Return
	EndTry;
	
	struct = Cache.ClearCache(parameters,New Structure("user,holding,chain,languageCode,language,cacheTypes,date",
												parameters.tokenContext.user,
												parameters.tokenContext.holding,
												parameters.tokenContext.chain,
												parameters.languageCode,
												parameters.language,
												getCorrectTypes(types),
												date));
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Function getCorrectTypes(types)
	arrTypes = New Array();
	Predef = Metadata.Catalogs.cacheTypes.GetPredefinedNames();
	For Each El In types Do
		If Not Predef.Find(El)=Undefined Then
			arrTypes.Add(Catalogs.cacheTypes[El])
		EndIf; 	
	EndDo; 
	
	return arrTypes;
	
EndFunction

Procedure userCache(parameters) Export
	
//	tokenContext = parameters.tokenContext;
//	requestStruct = parameters.requestStruct;
//	
//	cacheTypesDescriptions = New Array();
//	
//	If requestStruct.page = "homePage" Then
//		cacheTypesDescriptions.Add("banners");	
//	ElsIf requestStruct.page = "personalPage" Then
//		cacheTypesDescriptions.Add("");
//	EndIf;	
//	
//	query = New Query("SELECT
//	|	cacheTypes.Ref AS cacheType
//	|INTO TT_cacheType
//	|FROM
//	|	Catalog.cacheTypes AS cacheTypes
//	|WHERE
//	|	cacheTypes.Description IN(&Descriptions)
//	|;
//	|
//	|////////////////////////////////////////////////////////////////////////////////
//	|SELECT
//	|	cacheIndex.cacheType.Description AS cacheType,
//	|	cacheIndex.cacheInformation AS cacheInformation,
//	|	cacheIndex.cacheInformation.startRotation AS startRotation,
//	|	cacheIndex.cacheInformation.endRotation AS endRotation
//	|INTO TT_CacheInformation
//	|FROM
//	|	TT_cacheType AS TT_cacheType
//	|		LEFT JOIN InformationRegister.cacheIndex AS cacheIndex
//	|		ON TT_cacheType.cacheType = cacheIndex.cacheType
//	|			AND (cacheIndex.user = &user)
//	|			AND (cacheIndex.chain = &chain)
//	|;
//	|
//	|////////////////////////////////////////////////////////////////////////////////
//	|SELECT
//	|	TT_CacheInformation.cacheType AS cacheType,
//	|	TT_CacheInformation.cacheInformation.data AS data
//	|FROM
//	|	TT_CacheInformation AS TT_CacheInformation
//	|WHERE
//	|	TT_CacheInformation.startRotation <= &CurrentTime
//	|	AND TT_CacheInformation.endRotation >= &CurrentTime
//	|TOTALS BY
//	|	cacheType");
//	
//	query.SetParameter("chain", tokenContext.chain);
//	query.SetParameter("user", Catalogs.users.EmptyRef());
//	query.SetParameter("currentTime", ToUniversalTime(CurrentDate()));
//	query.SetParameter("descriptions", cacheTypesDescriptions);
//	
//	struct = New Structure();
//	selectCacheType = query.Execute().Select(QueryResultIteration.ByGroups);
//	While selectCacheType.Next() Do
//		cacheArray	= new Array();
//		select = selectCacheType.Select();
//		While select.Next() Do
//			cacheArray.Add(HTTP.decodeJSON(select.data));
//		EndDo;
//		struct.Insert(selectCacheType.cacheType, cacheArray);
//	EndDo;
//		
//	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure

Procedure fileInfo(parameters) Export
	
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	struct = New Structure();
	content = ?(requestStruct.Property("uid"),Service.getRef(requestStruct.uid, Type("CatalogRef.content")),Undefined);
	If ValueIsFilled(content) then
		query = New Query("SELECT
		|	contentTable.url,
		|	contentTable.typeOfFile,
		|	ISNULL(contenttranslation.description, contentTable.Description) AS Description,
		|	ISNULL(contenttranslation.fullDescription, contentTable.fullDescription) AS fullDescription,
		|	contentTable.avaliableForDownload
		|FROM
		|	Catalog.content.translation AS contenttranslation
		|		RIGHT JOIN Catalog.content AS contentTable
		|		ON contenttranslation.Ref = contentTable.Ref
		|		AND contenttranslation.language = &language
		|WHERE
		|	contentTable.Ref = &Ref");
		query.SetParameter("Ref", content);
		query.SetParameter("language", language);
		select = query.Execute().Select();
		If select.Count() = 0 then
			struct.Insert("error", "noFile");
		EndIf;
		While select.Next() do
			struct.Insert("name", select.Description);
			struct.Insert("url", select.url);
			struct.Insert("type", xmlString(select.typeOfFile));
			struct.Insert("description", select.fullDescription);
			struct.Insert("availableForDownload", select.avaliableForDownload);
		EndDo;
	else
		struct.Insert("error", "noFile");
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure

Procedure polllist(parameters) Export
	parameters.Insert("answerBody", 
				HTTP.encodeJSON(
						Polls.list(
								New Structure("user,chain",
											parameters.tokenContext.user,
											parameters.tokenContext.chain))));
EndProcedure

Procedure pollInfo(parameters) Export
	
	If Not requestIsStructure(parameters) Then
		Return
	EndIf;
	
	pollId = Undefined;
	If Not parameters.requestStruct.Property("pollId",pollId)   Then
		noValidRequest(parameters);
		Return
	EndIf;
	struct = Polls.poll(New Structure("user,poll", 
							parameters.tokenContext.user,
							XMLValue(Type("DocumentRef.НазначениеОпросов"), pollId) ));
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Procedure pollanswer(parameters) Export
	
	If Not requestIsStructure(parameters) Then
		Return
	EndIf;
	
	pollId = Undefined; questionId = Undefined;
	//answer = Undefined; comment = Undefined;
	variantsInput = Undefined;
	If Not parameters.requestStruct.Property("pollId",pollId)   Then
		noValidRequest(parameters);
		Return
	EndIf;
	If Not parameters.requestStruct.Property("questionId",questionId)   Then
		noValidRequest(parameters);
		Return
	EndIf;	
	
	parameters.requestStruct.Property("answerList",variantsInput);

	variants = New Array;
	If  TypeOf(variantsInput)=Type("Array") Then
		For Each el in variantsInput  Do
			strucVariant = New Structure("comment,answer,variantId");
			FillPropertyValues(strucVariant,el);
			If ValueIsFilled(strucVariant.variantId) Then
				strucVariant.Insert("variant", XMLValue(Type("CatalogRef.ВариантыОтветовАнкет"), strucVariant.variantId));
			EndIf;
			variants.Add(strucVariant);
		EndDo
	EndIf;	
	
	struct = Polls.pollanswer(New Structure("user,poll,question,variants",
													parameters.tokenContext.user,
													XMLValue(Type("DocumentRef.НазначениеОпросов"), pollId),
													XMLValue(Type("CatalogRef.ВопросыШаблонаАнкеты"), questionId),
													variants));
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Procedure pollComplete(parameters) Export
	
	If Not requestIsStructure(parameters) Then
		Return
	EndIf;
	
	pollId = Undefined; 

	If Not parameters.requestStruct.Property("pollId",pollId)   Then
		noValidRequest(parameters);
		Return
	ElsIf Not ValueIsFilled(pollId) Then
		Return
	EndIf;

	struct = Polls.pollComplete(New Structure("user, poll",
													parameters.tokenContext.user,
													XMLValue(Type("DocumentRef.НазначениеОпросов"), pollId)));
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure