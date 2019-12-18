
Procedure gymInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	gymStruct = New Structure();
	
	errorDescription = Service.getErrorDescription(language);
	
	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "gymError");
	EndIf;

	If errorDescription.result = "" Then
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
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure employeeInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	struct = New Structure();
	
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "stuff");
	EndIf;

	If errorDescription.result = "" Then
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
			struct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));			
			struct.Insert("presentation", HTTP.decodeJSON(select.descriptionFull, Enums.JSONValueTypes.array));			
			
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
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
		
EndProcedure

Procedure productInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;	
	productStruct = New Structure();

	query = New Query();
	query.Text = "SELECT
	|	products.Ref AS product,
	|	products.Description,
	|	products.shortDescription,
	|	products.fullDescription,
	|	products.addDescription
	|INTO TT
	|FROM
	|	Catalog.products AS products
	|WHERE
	|	products.Ref = &product
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product,
	|	ISNULL(productstranslation.description, TT.Description) AS description,
	|	ISNULL(productstranslation.shortDescription, TT.shortDescription) AS shortDescription,
	|	ISNULL(productstranslation.fullDescription, TT.fullDescription) AS fullDescription,
	|	ISNULL(productstranslation.addDescription, TT.addDescription) AS addDescription
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
	|	productsMapping.uid,
	|	productsMapping.entryType
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.productsMapping AS productsMapping
	|		ON TT.product = productsMapping.product
	|WHERE
	|	NOT productsMapping.uid IS NULL
	|	AND productsMapping.uid in (&entryList)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product,
	|	productsphotos.URL
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.photos AS productsphotos
	|		ON TT.product = productsphotos.Ref
	|WHERE
	|	NOT productsphotos.URL IS NULL";

	If requestStruct.Property("entryList") And requestStruct.entryList.count() > 0 Then		
		entryListArray = New Array();
		For Each entryType In requestStruct.entryList Do
			entryListArray.Add(entryType.uid);				
		EndDo;		 
		query.SetParameter("entryList", entryListArray);
	Else
		query.Text = StrReplace(query.Text, "AND productsMapping.entryType in (&entryList)", "");		
	EndIf;	
	query.SetParameter("product", XMLValue(Type("CatalogRef.products"), requestStruct.uid));
	query.SetParameter("language", language);
	
	results = query.ExecuteBatch();
	select = results[1].Select();
	selectTags = results[2].Select();
	selectMapping = results[3].Select();
	selectPhotos = results[4].Select();
	
	While select.Next() Do		
		productStruct.Insert("uid", XMLString(select.product));		
		productStruct.Insert("name", select.description);		
		productStruct.Insert("shortDescription", select.shortDescription);
		productStruct.Insert("fullDescription", select.fullDescription);
		productStruct.Insert("addDescription", select.addDescription);		
		
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
		
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(productStruct));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);	

EndProcedure

Procedure accountProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Account.profile(parameters.tokenContext.account)));		
EndProcedure

Procedure userProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Users.profile(parameters.tokenContext.user, parameters.tokenContext.appType)));	
EndProcedure

Procedure userSummary(parameters) Export
	tokenContext = parameters.tokenContext;
	
	query = New Query("SELECT
	|	chainscacheValues.cacheValuesType.Code AS cacheCode,
	|	usersStates.stateValue AS cacheValue,
	|	chainscacheValues.cacheValuesType.defaultValueType AS defaultValueType
	|FROM
	|	Catalog.chains.cacheValuesTypes AS chainscacheValues
	|		LEFT JOIN InformationRegister.usersStates AS usersStates
	|		ON chainscacheValues.cacheValuesType = usersStates.cacheValuesType
	|		AND usersStates.user = &user
	|		AND usersStates.appType = &appType
	|WHERE
	|	chainscacheValues.Ref = &chain
	|	AND chainscacheValues.isUsed");
	
	query.SetParameter("chain", tokenContext.chain);
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);
	
	struct = New Structure();
	select = query.Execute().Select();
	While select.Next() Do
		struct.Insert(select.cacheCode, HTTP.decodeJSON(?(select.cacheValue = null, "", select.cacheValue), select.defaultValueType));
	EndDo;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure

