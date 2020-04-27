
Procedure employeeList(parameters) Export

	requestStruct = parameters.requestStruct;
	employeeArray = New Array();
	
	If Not requestStruct.Property("uid") Then		
		parameters.Insert("error", "gymError");
	Else
		employeeArray = getArrEmployees(New Structure("gym,byArray,language",
											XMLValue(Type("CatalogRef.gyms"), requestStruct.uid),
											False,
											parameters.language));
		
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(employeeArray));	
	
EndProcedure

Function getArrEmployees(params) Export
	stucParams = New Structure("gym,byArray,Array,language",
											Catalogs.gyms.EmptyRef(),
											True,
											New Array(),
											Catalogs.languages.EmptyRef());
	FillPropertyValues(stucParams, params);
	Res = ?(stucParams.byArray, New Map, New Array);
	query = New Query("SELECT
	|	gymsEmployees.employee,
	|	ISNULL(employeestranslation.firstName, gymsEmployees.employee.firstName) AS firstName,
	|	ISNULL(employeestranslation.lastName, gymsEmployees.employee.lastName) AS lastName,
	|	ISNULL(employeestranslation.categoryList, gymsEmployees.employee.categoryList) AS categoryList,
	|	gymsEmployees.employee.photo AS photo,
	|	gymsEmployees.employee.gender AS gender
	|FROM
	|	InformationRegister.gymsEmployees AS gymsEmployees
	|		LEFT JOIN Catalog.employees.translation AS employeestranslation
	|		ON gymsEmployees.employee = employeestranslation.Ref
	|		AND employeestranslation.language = &language
	|WHERE
	|	NOT &byArray
	|	AND gymsEmployees.gym = &gym
	|	AND gymsEmployees.employee.active
	|
	|Union all
	|
	|SELECT
	|	employees.Ref AS employee,
	|	ISNULL(employeestranslation.firstName, employees.firstName) AS firstName,
	|	ISNULL(employeestranslation.lastName, employees.lastName) AS lastName,
	|	ISNULL(employeestranslation.categoryList, employees.categoryList) AS categoryList,
	|	employees.photo AS photo,
	|	employees.gender AS gender
	|FROM
	|	Catalog.employees AS employees
	|		LEFT JOIN Catalog.employees.translation AS employeestranslation
	|		ON employees.Ref = employeestranslation.Ref
	|		AND employeestranslation.language = &language
	|WHERE
	|	 &byArray
	|	AND employees.Ref IN (&Array)
	|	AND employees.active");

	query.SetParameter("gym", stucParams.gym);
	query.SetParameter("byArray", stucParams.byArray);
	query.SetParameter("Array", stucParams.Array);
	query.SetParameter("language", stucParams.language);

	select = query.Execute().Select();

	While select.Next() Do
		employeeStruct = New Structure;
		employeeStruct.Insert("uid", XMLString(select.employee));
		employeeStruct.Insert("firstName", select.firstName);
		employeeStruct.Insert("lastName", select.lastName);
		employeeStruct.Insert("gender", select.gender);
		employeeStruct.Insert("photo", select.photo);
		employeeStruct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));
		employeeStruct.Insert("isMyCoach", False);
		If stucParams.byArray Then
			Res.Insert(select.employee,  HTTP.encodeJSON(employeeStruct))
		Else
			Res.add(employeeStruct);
		EndIf
	EndDo;
		
	Return 		Res
EndFunction

Procedure roomList(parameters) Export

	requestStruct = parameters.requestStruct;
	//tokenContext = parameters.tokenContext;	
	roomArray = New Array();	

	If Not requestStruct.Property("uid") Then		
		parameters.Insert("error", "gymError");
	Else
		type = Enums.roomTypes.EmptyRef();
		If requestStruct.Property("type") Then
			type=XMLValue(Type("EnumRef.roomTypes"), requestStruct.type)
		EndIf;
		roomArray = getArrRooms(New Structure("gym,byArray,language,type",
																XMLValue(Type("CatalogRef.gyms"), requestStruct.uid),
																False,
																parameters.language,
																type));
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(roomArray));
EndProcedure

Function  getArrRooms(params) Export
	stucParams = New Structure("gym,byArray,Array,language,type",
											Undefined,
											True,
											New Array(),
											Catalogs.languages.EmptyRef(),
											Undefined);
	FillPropertyValues(stucParams, params);
	Res = ?(stucParams.byArray, New Map, New Array);
	
	query = New Query("SELECT
		|	rooms.Ref,
		|	rooms.type,
		|	case
		|		WHEN ISNULL(roomstranslation.description, """") = """"
		|			THEN rooms.description
		|		ELSE roomstranslation.description
		|	END as Description
		|FROM
		|	Catalog.rooms AS rooms
		|		LEFT JOIN Catalog.rooms.translation AS roomstranslation
		|		ON roomstranslation.Ref = rooms.Ref
		|		AND roomstranslation.language = &language
		|WHERE
		|	case
		|		when &byArray
		|			then rooms.Ref in (&Array)
		|		else rooms.gym = &gym AND rooms.type = &type
		|	End");
		
		query.SetParameter("gym", stucParams.gym);
		query.SetParameter("type", stucParams.type);
		query.SetParameter("byArray", stucParams.byArray);
		query.SetParameter("Array", stucParams.Array);
		query.SetParameter("language", stucParams.language);
		
		select = query.Execute().Select();

		While select.Next() Do
			roomStruct = New Structure();
			roomStruct.Insert("uid", XMLString(select.Ref));
			roomStruct.Insert("name", select.description);
			roomStruct.Insert("type", XMLString(select.type));
			
			If stucParams.byArray Then
				Res.Insert(select.Ref,  HTTP.encodeJSON(roomStruct))
			Else
				Res.add(roomStruct);
			EndIf
		EndDo;
	
	Return Res
EndFunction

Procedure gymList(parameters) Export

	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;	
	gymArray = New Array();	

	If Not requestStruct.Property("chain") Then		
		parameters.Insert("error", "chainCodeError");
	Else	 
		gymArray = getArrGyms(New Structure("chainCode,byArray,language,currentTime,appType,authorized",
											requestStruct.chain,
											False,
											 parameters.language,
											parameters.currentTime,
											tokenContext.appType,
											ValueIsFilled(tokenContext.user)));
		
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymArray));	
	
EndProcedure

Function  getArrGyms(params) Export
	stucParams = New Structure("chainCode,byArray,Array,language,currentTime,appType,authorized",
											"",
											True,
											New Array(),
											Catalogs.languages.EmptyRef(),
											CurrentUniversalDate(),
											,
											False);
	FillPropertyValues(stucParams, params);
	
	Res = ?(stucParams.byArray, New Map, New Array);
	query = New Query("SELECT
	|	gyms.Ref,
	|	gyms.latitude,
	|	gyms.longitude,
	|	ISNULL(gyms.segment.Description, """") AS segment,
	|	ISNULL(gyms.segment.color, """") AS segmentColor,
	|	gyms.phone,
	|	gyms.photo,
	|	gyms.weekdaysTime,
	|	gyms.holidaysTime,
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
	|		WHEN gymstranslation.nearestMetro IS NULL
	|			THEN gyms.nearestMetro
	|		WHEN gymstranslation.nearestMetro = ""[]""
	|			THEN gyms.nearestMetro
	|		ELSE gymstranslation.nearestMetro
	|	END AS nearestMetro,
	|	CASE
	|		WHEN gymstranslation.state IS NULL
	|			THEN gyms.state
	|		WHEN gymstranslation.state = """"
	|			THEN gyms.state
	|		ELSE gymstranslation.state
	|	END AS state,
	|	gyms.order AS order
	|FROM
	|	Catalog.gyms AS gyms
	|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|		ON gymstranslation.Ref = gyms.Ref
	|		AND gymstranslation.language = &language
	|WHERE
	|	NOT &byArray
	|	AND
	|	NOT gyms.DeletionMark
	|	AND gyms.chain.code = &chainCode
	|	AND gyms.startDate <= &currentTime
	|	AND gyms.endDate >= &currentTime
	|	AND gyms.type <> VALUE(Enum.gymTypes.online)
	|
	|UNION ALL
	|
	|SELECT
	|	gyms.Ref,
	|	gyms.latitude,
	|	gyms.longitude,
	|	ISNULL(gyms.segment.Description, """"),
	|	ISNULL(gyms.segment.color, """"),
	|	gyms.phone,
	|	gyms.photo,
	|	gyms.weekdaysTime,
	|	gyms.holidaysTime,
	|	CASE
	|		WHEN gymstranslation.description IS NULL
	|			THEN gyms.Description
	|		WHEN gymstranslation.description = """"
	|			THEN gyms.Description
	|		ELSE gymstranslation.description
	|	END,
	|	CASE
	|		WHEN gymstranslation.address IS NULL
	|			THEN gyms.address
	|		WHEN gymstranslation.address = """"
	|			THEN gyms.address
	|		ELSE gymstranslation.address
	|	END,
	|	CASE
	|		WHEN gymstranslation.nearestMetro IS NULL
	|			THEN gyms.nearestMetro
	|		WHEN gymstranslation.nearestMetro = ""[]""
	|			THEN gyms.nearestMetro
	|		ELSE gymstranslation.nearestMetro
	|	END,
	|	CASE
	|		WHEN gymstranslation.state IS NULL
	|			THEN gyms.state
	|		WHEN gymstranslation.state = """"
	|			THEN gyms.state
	|		ELSE gymstranslation.state
	|	END,
	|	gyms.order
	|FROM
	|	Catalog.gyms AS gyms
	|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|		ON gymstranslation.Ref = gyms.Ref
	|		AND gymstranslation.language = &language
	|		LEFT JOIN Catalog.chains AS chains
	|		ON chains.brand = gyms.brand
	|		AND chains.holding = gyms.holding
	|WHERE
	|	NOT &byArray
	|	AND
	|	NOT gyms.DeletionMark
	|	AND gyms.chain.Code = &chainCode
	|	AND gyms.startDate <= &currentTime
	|	AND gyms.endDate >= &currentTime
	|	AND gyms.type = VALUE(Enum.gymTypes.online)
	|	AND chains.Code = &chainCode
	|
	|UNION ALL
	|
	|SELECT
	|	gyms.Ref,
	|	gyms.latitude,
	|	gyms.longitude,
	|	ISNULL(gyms.segment.Description, """") AS segment,
	|	ISNULL(gyms.segment.color, """") AS segmentColor,
	|	gyms.phone,
	|	gyms.photo,
	|	gyms.weekdaysTime,
	|	gyms.holidaysTime,
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
	|		WHEN gymstranslation.nearestMetro IS NULL
	|			THEN gyms.nearestMetro
	|		WHEN gymstranslation.nearestMetro = ""[]""
	|			THEN gyms.nearestMetro
	|		ELSE gymstranslation.nearestMetro
	|	END AS nearestMetro,
	|	CASE
	|		WHEN gymstranslation.state IS NULL
	|			THEN gyms.state
	|		WHEN gymstranslation.state = """"
	|			THEN gyms.state
	|		ELSE gymstranslation.state
	|	END AS state,
	|	gyms.order
	|FROM
	|	Catalog.gyms AS gyms
	|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|		ON gymstranslation.Ref = gyms.Ref
	|		AND gymstranslation.language = &language
	|WHERE
	|	&byArray
	|	AND gyms.ref IN (&Array)
	|	AND
	|	NOT gyms.DeletionMark
	|ORDER BY
	|	order");
		
		query.SetParameter("chainCode", stucParams.chainCode);
		query.SetParameter("byArray", stucParams.byArray);
		query.SetParameter("Array", stucParams.Array);
		query.SetParameter("language", stucParams.language);
		query.SetParameter("currentTime", stucParams.currentTime);
//		query.SetParameter("IsAppEmployee", stucParams.appType = Enums.appTypes.Employee);		
		
		select = query.Execute().Select();

		While select.Next() Do
			gymStruct = New Structure();
			gymStruct.Insert("uid", XMLString(select.Ref));
			gymStruct.Insert("gymId", gymStruct.uid);
			gymStruct.Insert("name", select.description);
			gymStruct.Insert("type", "Club");
			gymStruct.Insert("state", select.state);			
			gymStruct.Insert("address", select.address);
			gymStruct.Insert("photo", select.photo);
			gymStruct.Insert("phone", select.phone);
			gymStruct.Insert("weekdaysTime", select.weekdaysTime);
			gymStruct.Insert("holidaysTime", select.holidaysTime);
			gymStruct.Insert("hasAccess", ?(stucParams.authorized, false, Undefined));
			gymStruct.Insert("metro", HTTP.decodeJSON(select.nearestMetro, Enums.JSONValueTypes.array));
			
			coords = New Structure();
			coords.Insert("latitude", select.latitude);
			coords.Insert("longitude", select.longitude);
			gymStruct.Insert("coords", coords);
			
			segment = New Structure();
			segment.Insert("name", select.segment);
			segment.Insert("color", select.segmentColor);
			gymStruct.Insert("segment", segment);			
			
			If stucParams.byArray Then
				Res.Insert(select.Ref,  HTTP.encodeJSON(gymStruct))
			Else
				Res.add(gymStruct);
			EndIf
		EndDo;
	
	Return Res
EndFunction
Procedure productList(parameters) Export

	requestStruct = parameters.requestStruct;
	
	productDirection = Undefined;
	If requestStruct.Property("direction") Then
		productDirection =service.getRef(requestStruct.direction,Type("EnumRef.productDirections"), GetProductDirectionsArray());
	EndIf;
	 
	productArray = New Array();
	
	productArray = getArrProduct(New Structure("byArray,arrProduct, productDirection,language,gym,entryType",
													False,
													New Array(),
													productDirection,
													parameters.language,
													 XMLValue(Type("CatalogRef.gyms"), requestStruct.gymId),
													?(parameters.Property("entryType"),parameters.entryType,New Array())));
		
	parameters.Insert("answerBody", HTTP.encodeJSON(productArray));		

EndProcedure

Function  getArrProduct(params) Export
	stucParams = New Structure("byArray,Array, productDirection,language,gym,entryType",
											True,
											New Array(),
											Undefined,
											Catalogs.languages.EmptyRef(),
											Undefined,
											New Array());
	FillPropertyValues(stucParams, params);
	If stucParams.productDirection = Undefined then
   	   		stucParams.productDirection = enums.productDirections.fitness;
	EndIf;
	
	entryType = new Array();
	For Each entry in stucParams.entryType do
		if entry.Property("entryType") then
			entryType.Add(entry.entryType);
		EndIf;
	EndDo;
	
	if entryType.Count() = 0 then
		entryType.Add("personal");
		entryType.Add("group");	
	EndIf;
	
	baseImgURL = GeneralReuse.getBaseImgURL();
	
	Res = ?(stucParams.byArray, New Map, New Array);
	
	query = New Query("SELECT
	|	gymsProducts.product,
	|	gymsProducts.productDirection,
	|	gymsProducts.price
	|INTO TT
	|FROM
	|	InformationRegister.gymsProducts AS gymsProducts
	|		INNER JOIN InformationRegister.productsMapping AS productsMapping
	|		ON productsMapping.product = gymsProducts.product
	|		AND productsMapping.entryType IN (&entryType)
	|WHERE
	|	NOT &byArray
	|	AND gymsProducts.productDirection = &productDirection
	|	AND gymsProducts.gym = &gym
	|
	|UNION ALL
	|
	|SELECT
	|	products.Ref,
	|	&productDirection,
	|	NULL
	|FROM
	|	Catalog.products AS products
	|WHERE
	|	&byArray
	|	AND products.Ref IN (&Array)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.productDirection,
	|	TT.product,
	|	ISNULL(productstranslation.description, TT.product.Description) AS description,
	|	ISNULL(productstranslation.shortDescription, TT.product.shortDescription) AS shortDescription,
	|	TT.product.photo AS photo,
	|	TT.product.order,
	|	TT.price
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.translation AS productstranslation
	|		ON TT.product = productstranslation.Ref
	|		AND productstranslation.language = &language
	|ORDER BY
	|	TT.product.order
	|;
	|
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
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product AS product,
	|	ISNULL(productsMapping.uid, """") AS uid,
	|	ISNULL(productsMapping.entryType, """") AS entryType
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.productsMapping AS productsMapping
	|		ON TT.product = productsMapping.product");
	

	query.SetParameter("productDirection", stucParams.productDirection);
	query.SetParameter("gym", stucParams.gym);	
	query.SetParameter("byArray", stucParams.byArray);
	query.SetParameter("Array", stucParams.Array);
	query.SetParameter("language", stucParams.language);
	query.SetParameter("CurrentDate", ToUniversalTime(CurrentDate()));
	query.SetParameter("entryType",entryType);
	results = query.ExecuteBatch();
	select = results[1].Select();
	selectTags = results[2].Select();
	selectMapping = results[3].Select();
	
	While select.Next() Do
		productStruct = New Structure();
		productStruct.Insert("uid", XMLString(select.product));		
		productStruct.Insert("name", select.description);		
		productStruct.Insert("shortDescription", select.shortDescription);
		if select.price <> Undefined then
			productStruct.Insert("price", select.price);
		EndIf;
		If select.photo = "" And select.productDirection = Enums.productDirections.fitness Then
			productStruct.Insert("photo", baseImgURL + "/service/fitness.jpg");
		ElsIf select.photo = "" And select.productDirection = Enums.productDirections.spa Then
			productStruct.Insert("photo", baseImgURL + "/service/spa.jpg");
		Else			 	 
			productStruct.Insert("photo", select.photo);
		EndIf;				
		
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
		If stucParams.byArray Then
			Res.Insert(select.product,  HTTP.encodeJSON(productStruct))
		Else
			Res.add(productStruct);
		EndIf
	EndDo;
	
	Return Res
EndFunction

Function GetProductDirectionsArray()
	ProductDirections = "fitness spa";
	Return StrSplit(ProductDirections, " ");
EndFunction

Procedure chainList(parameters) Export

	language = parameters.language;
	brand = parameters.brand;
	array = New array;

	query = New Query();
	query.text = "SELECT
	|	ISNULL(chaininterfaceText.description, chain.Description) AS Description,
	|	chain.code AS code,
	|	REFPRESENTATION(chain.loyaltyProgram) AS loyaltyProgram,
	|	chain.phoneMask AS phoneMask,
	|	chain.currencySymbol AS currencySymbol,
	|	REFPRESENTATION(chain.brand) AS brand,
	|	chain.phoneMask.CountryCode AS phoneMaskCountryCode,
	|	chain.phoneMask.Description AS phoneMaskDescription,
	|	chain.holding.Code AS holdingCode,
	|	chain.cacheTypes.(
	|		cacheType.PredefinedDataName AS section,
	|		isUsed) AS availableSections
	|FROM
	|	Catalog.chains AS chain
	|		LEFT JOIN Catalog.chains.translation AS chaininterfaceText
	|		ON chaininterfaceText.Ref = chain.Ref
	|		AND chaininterfaceText.language = &language
	|WHERE
	|	NOT chain.DeletionMark
	|	AND chain.brand = &brand
	|ORDER BY
	|	code";

	query.SetParameter("language", language);
	
	If brand = Undefined or brand = Enums.brandTypes.None Then
		query.Text = StrReplace(query.Text, "AND chain.brand = &brand", "");
		nameTogetherChain = True;
	Else
		query.SetParameter("brand", brand);
		nameTogetherChain = False;
	EndIf;

	select = query.Execute().Select();

	While select.Next() Do
		chainStruct = New Structure();
		chainStruct.Insert("brand", select.brand);
		chainStruct.Insert("code", select.code);
		chainStruct.Insert("holdingCode", select.holdingCode);
		chainStruct.Insert("loyaltyProgram", select.loyaltyProgram);
		chainStruct.Insert("currencySymbol", select.currencySymbol);
		chainName = ?(nameTogetherChain, select.brand + " "
			+ select.description, select.description);
		chainStruct.Insert("name", chainName);
		chainStruct.Insert("countryCode", New Structure("code, mask", select.phoneMaskCountryCode, select.phoneMaskDescription));		
		availableSections = New Array();
		For Each row In select.availableSections.Unload() Do
			If row.isUsed And ValueIsFilled(row.section)  Then
				availableSections.Add(row.section);	
			EndIf;		
		EndDo;
		chainStruct.Insert("availableSections", availableSections);		
		array.add(chainStruct);
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(array));

EndProcedure

Procedure countryCodeList(parameters) Export
	
	array	= New Array();		
	query	= New Query();
	
	query.Text	= "SELECT
	|	CountryCodes.CountryCode,
	|	CountryCodes.Description
	|FROM
	|	Catalog.CountryCodes AS CountryCodes
	|WHERE
	|	NOT CountryCodes.DeletionMark";
	
	selection	= query.Execute().Select();
	
	While selection.Next() Do
		answer	= New Structure();
		answer.Insert("code", selection.CountryCode);
		answer.Insert("mask", selection.Description);		
		array.add(answer);
	EndDo;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(array));	
	
EndProcedure

Procedure cancellationReasonsList(parameters) Export

	tokenContext		= parameters.tokenContext;
	array 			= New Array();

	query = New Query();
	query.text = "SELECT
	|	cancellationReasons.Ref AS ref,
	|	cancellationReasons.Description AS description
	|FROM
	|	Catalog.cancellationReasons AS cancellationReasons
	|WHERE
	|	NOT cancellationReasons.DeletionMark
	|	AND cancellationReasons.holding = &holding";

	query.SetParameter("holding", tokenContext.holding);
	selection = query.Execute().Select();
	While selection.Next() Do
		struct = New Structure("uid,name", XMLString(selection.ref), selection.description);
		array.add(struct);
	EndDo;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(array));	

EndProcedure

Procedure notificationList(parameters) Export

	requestStruct	= parameters.requestStruct;
	tokenContext		= parameters.tokenContext;

	array = New Array();

	If requestStruct.Property("date") And requestStruct.date <> "" Then
		registrationDate = ToUniversalTime(XMLValue(Type("Date"), requestStruct.date));
	Else
		registrationDate = ToUniversalTime(CurrentDate());
	EndIf;
	
	query = New Query();
	query.text	= "SELECT TOP 50
	|	pushStatusBalanceAndTurnovers.message AS message,
	|	pushStatusBalanceAndTurnovers.message.objectId AS objectId,
	|	pushStatusBalanceAndTurnovers.message.objectType AS objectType,
	|	pushStatusBalanceAndTurnovers.message.registrationDate AS registrationDate,
	|	pushStatusBalanceAndTurnovers.message.text AS text,
	|	pushStatusBalanceAndTurnovers.message.title AS title,
	|	SUM(pushStatusBalanceAndTurnovers.amountReceipt) AS amountReceipt
	|INTO TT
	|FROM
	|	AccumulationRegister.pushStatus.BalanceAndTurnovers(, &eOfPeriod, Record,, user = &user
	|	AND informationChannel = &informationChannel) AS pushStatusBalanceAndTurnovers
	|GROUP BY
	|	pushStatusBalanceAndTurnovers.message,
	|	pushStatusBalanceAndTurnovers.message.objectId,
	|	pushStatusBalanceAndTurnovers.message.objectType,
	|	pushStatusBalanceAndTurnovers.message.registrationDate,
	|	pushStatusBalanceAndTurnovers.message.text,
	|	pushStatusBalanceAndTurnovers.message.title,
	|	pushStatusBalanceAndTurnovers.Period
	|ORDER BY
	|	pushStatusBalanceAndTurnovers.Period DESC
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.message AS message,
	|	TT.objectId AS objectId,
	|	TT.objectType AS objectType,
	|	TT.registrationDate AS registrationDate,
	|	TT.text AS text,
	|	TT.title AS title,
	|	CASE
	|		WHEN pushStatusBalance.amountBalance IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS read
	|FROM
	|	TT AS TT
	|		LEFT JOIN AccumulationRegister.pushStatus.Balance AS pushStatusBalance
	|		ON (pushStatusBalance.user = &user)
	|		AND (TT.message = pushStatusBalance.message)
	|		AND (pushStatusBalance.informationChannel = &informationChannel)";
	
	query.SetParameter("eOfPeriod", registrationDate);
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("informationChannel", ?(tokenContext.appType = enums.appTypes.Customer, 
   																					enums.informationChannels.pushCustomer,
   																						?(tokenContext.appType = enums.appTypes.Employee, 
   																							enums.informationChannels.pushEmployee, 
   																								enums.informationChannels.EmptyRef())));

	select = query.Execute().Select();
	While select.Next() Do
		messageStruct = New Structure();
		messageStruct.Insert("noteId", XMLString(select.message));
		messageStruct.Insert("date", XMLString(ToLocalTime(select.registrationDate, tokenContext.timeZone)));
		messageStruct.Insert("title", select.title);
		messageStruct.Insert("text", select.text);
		messageStruct.Insert("read", select.read);
		messageStruct.Insert("objectId", select.objectId);
		messageStruct.Insert("objectType", select.objectType);
		array.add(messageStruct);
	EndDo;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(array));

EndProcedure
