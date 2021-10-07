 
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
	stucParams = New Structure("gym,byArray,Array,language,short",
											Catalogs.gyms.EmptyRef(),
											True,
											New Array(),
											Catalogs.languages.EmptyRef(),
											False);
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
		If Not stucParams.short Then
			employeeStruct.Insert("gender", select.gender);
			employeeStruct.Insert("photo", select.photo);
			employeeStruct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));
			employeeStruct.Insert("isMyCoach", False);
		EndIf;
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
	stucParams = New Structure("gym,byArray,Array,language,type,short",
											Undefined,
											True,
											New Array(),
											Catalogs.languages.EmptyRef(),
											Undefined,
											False);
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
			If Not stucParams.short Then
				roomStruct.Insert("type", XMLString(select.type));
			EndIf;
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
		gymArray = getArrGyms(New Structure("chainCode,byArray,language,currentTime,appType,authorized,brand, holding, type, myGyms",
											requestStruct.chain,
											False,
											 parameters.language,
											parameters.currentTime,
											tokenContext.appType,
											ValueIsFilled(tokenContext.user),
											parameters.brand,
											tokenContext.holding,
											?(requestStruct.Property("type"), requestStruct.type, Undefined),
											Cache.getMyClubs(new Structure("user,chain,holding,language,languageCode",
																			tokenContext.user,
																			tokenContext.chain, 
																			tokenContext.holding,
																			parameters.language,
																			parameters.languageCode),parameters)));
		
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymArray));	
	
EndProcedure

Function  getArrGyms(params) Export
	stucParams = New Structure("chainCode,byArray,Array,language,currentTime,appType,authorized, brand, holding, short, type, myGyms",
											"",
											True,
											New Array(),
											Catalogs.languages.EmptyRef(),
											CurrentUniversalDate(),
											,
											False,
											Enums.brandTypes.None,
											Catalogs.holdings.EmptyRef(),
											False,
											Undefined,
											Cache.tabGyms());
	FillPropertyValues(stucParams, params);
	if stucParams.brand = Enums.brandTypes.None then
		stucParams.brand = Enums.brandTypes.WorldClass;
	EndIf;
	
	Res = ?(stucParams.byArray, New Map, New Array);
	query = New Query("SELECT
	|	T.base AS base,
	|	T.ref AS ref
	|INTO TmyGyms
	|FROM
	|	&myGyms AS T;
	|////////////////////////////////////////////////////////////////////////////////
	|Select
	|	*,
	|	Case
	|		when data.base
	|			then 1000000
	|		else 0
	|	end + Case
	|		when data.hasAccess
	|			then 1000
	|		else 0
	|	end as order
	|from
	|	(SELECT
	|		gyms.Ref AS Ref,
	|		gyms.latitude AS latitude,
	|		gyms.longitude AS longitude,
	|		ISNULL(gyms.segment.Description, """") AS segment,
	|		ISNULL(gyms.segment.color, """") AS segmentColor,
	|		gyms.phone AS phone,
	|		gyms.photo AS photo,
	|		gyms.weekdaysTime AS weekdaysTime,
	|		gyms.holidaysTime AS holidaysTime,
	|		CASE
	|			WHEN gymstranslation.description IS NULL
	|				THEN gyms.Description
	|			WHEN gymstranslation.description = """"
	|				THEN gyms.Description
	|			ELSE gymstranslation.description
	|		END AS Description,
	|		CASE
	|			WHEN gymstranslation.address IS NULL
	|				THEN gyms.address
	|			WHEN gymstranslation.address = """"
	|				THEN gyms.address
	|			ELSE gymstranslation.address
	|		END AS address,
	|		CASE
	|			WHEN gymstranslation.nearestMetro IS NULL
	|				THEN gyms.nearestMetro
	|			WHEN gymstranslation.nearestMetro = ""[]""
	|				THEN gyms.nearestMetro
	|			ELSE gymstranslation.nearestMetro
	|		END AS nearestMetro,
	|		CASE
	|			WHEN gymstranslation.state IS NULL
	|				THEN gyms.state
	|			WHEN gymstranslation.state = """"
	|				THEN gyms.state
	|			ELSE gymstranslation.state
	|		END AS state,
	|		NOT TmyGyms.ref IS NULL AS hasAccess,
	|		ISNULL(TmyGyms.base, FALSE) AS base
	|	FROM
	|		Catalog.gyms AS gyms
	|			LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|			ON (gymstranslation.Ref = gyms.Ref)
	|			AND (gymstranslation.language = &language)
	|			LEFT JOIN TmyGyms AS TmyGyms
	|			ON gyms.Ref = TmyGyms.ref
	|	WHERE
	|		NOT &byArray
	|		AND
	|		NOT gyms.DeletionMark
	|		AND gyms.chain.Code = &chainCode
	|		AND gyms.startDate <= &currentTime
	|		AND gyms.endDate >= &currentTime
	|		AND gyms.type <> VALUE(Enum.gymTypes.online)
	|		AND CASE
	|			WHEN &FilterType
	|				THEN gyms.type = &type
	|			ELSE TRUE
	|		END
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		gyms.Ref,
	|		gyms.latitude,
	|		gyms.longitude,
	|		ISNULL(gyms.segment.Description, """"),
	|		ISNULL(gyms.segment.color, """"),
	|		gyms.phone,
	|		gyms.photo,
	|		gyms.weekdaysTime,
	|		gyms.holidaysTime,
	|		CASE
	|			WHEN gymstranslation.description IS NULL
	|				THEN gyms.Description
	|			WHEN gymstranslation.description = """"
	|				THEN gyms.Description
	|			ELSE gymstranslation.description
	|		END,
	|		CASE
	|			WHEN gymstranslation.address IS NULL
	|				THEN gyms.address
	|			WHEN gymstranslation.address = """"
	|				THEN gyms.address
	|			ELSE gymstranslation.address
	|		END,
	|		CASE
	|			WHEN gymstranslation.nearestMetro IS NULL
	|				THEN gyms.nearestMetro
	|			WHEN gymstranslation.nearestMetro = ""[]""
	|				THEN gyms.nearestMetro
	|			ELSE gymstranslation.nearestMetro
	|		END,
	|		CASE
	|			WHEN gymstranslation.state IS NULL
	|				THEN gyms.state
	|			WHEN gymstranslation.state = """"
	|				THEN gyms.state
	|			ELSE gymstranslation.state
	|		END,
	|		NOT TmyGyms.ref IS NULL,
	|		ISNULL(TmyGyms.base, FALSE)
	|	FROM
	|		Catalog.gyms AS gyms
	|			LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|			ON (gymstranslation.Ref = gyms.Ref)
	|			AND (gymstranslation.language = &language)
	|			LEFT JOIN Catalog.chains AS chains
	|			ON (chains.brand = gyms.brand)
	|			AND (chains.holding = gyms.holding)
	|			LEFT JOIN TmyGyms AS TmyGyms
	|			ON gyms.Ref = TmyGyms.ref
	|	WHERE
	|		NOT &byArray
	|		AND
	|		NOT gyms.DeletionMark
	|		AND gyms.startDate <= &currentTime
	|		AND gyms.endDate >= &currentTime
	|		AND gyms.type = VALUE(Enum.gymTypes.online)
	|		AND gyms.brand = &brand
	|		AND gyms.holding = &holding
	|		AND CASE
	|			WHEN &FilterType
	|				THEN gyms.type = &type
	|			ELSE TRUE
	|		END
	|
	|	UNION ALL
	|
	|	SELECT
	|		gyms.Ref,
	|		gyms.latitude,
	|		gyms.longitude,
	|		ISNULL(gyms.segment.Description, """"),
	|		ISNULL(gyms.segment.color, """"),
	|		gyms.phone,
	|		gyms.photo,
	|		gyms.weekdaysTime,
	|		gyms.holidaysTime,
	|		CASE
	|			WHEN gymstranslation.description IS NULL
	|				THEN gyms.Description
	|			WHEN gymstranslation.description = """"
	|				THEN gyms.Description
	|			ELSE gymstranslation.description
	|		END,
	|		CASE
	|			WHEN gymstranslation.address IS NULL
	|				THEN gyms.address
	|			WHEN gymstranslation.address = """"
	|				THEN gyms.address
	|			ELSE gymstranslation.address
	|		END,
	|		CASE
	|			WHEN gymstranslation.nearestMetro IS NULL
	|				THEN gyms.nearestMetro
	|			WHEN gymstranslation.nearestMetro = ""[]""
	|				THEN gyms.nearestMetro
	|			ELSE gymstranslation.nearestMetro
	|		END,
	|		CASE
	|			WHEN gymstranslation.state IS NULL
	|				THEN gyms.state
	|			WHEN gymstranslation.state = """"
	|				THEN gyms.state
	|			ELSE gymstranslation.state
	|		END,
	|		NOT TmyGyms.ref IS NULL,
	|		ISNULL(TmyGyms.base, FALSE)
	|	FROM
	|		Catalog.gyms AS gyms
	|			LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|			ON (gymstranslation.Ref = gyms.Ref)
	|			AND (gymstranslation.language = &language)
	|			LEFT JOIN TmyGyms AS TmyGyms
	|			ON gyms.Ref = TmyGyms.ref
	|	WHERE
	|		&byArray
	|		AND gyms.Ref IN (&Array)
	|		AND
	|		NOT gyms.DeletionMark
	|		AND CASE
	|			WHEN &FilterType
	|				THEN gyms.type = &type
	|			ELSE TRUE
	|		END) as Data
	|ORDER BY
	|	order DESC,
	|	data.description");
		
		query.SetParameter("chainCode", stucParams.chainCode);
		query.SetParameter("byArray", stucParams.byArray);
		query.SetParameter("Array", stucParams.Array);
		query.SetParameter("language", stucParams.language);
		query.SetParameter("currentTime", stucParams.currentTime);
		query.SetParameter("brand", stucParams.brand);
		query.SetParameter("holding", stucParams.holding);
		query.SetParameter("myGyms", stucParams.myGyms);
		
//		query.SetParameter("IsAppEmployee", stucParams.appType = Enums.appTypes.Employee);		
		if stucParams.type = Undefined then
			filterType = false;
			gymtype = enums.gymTypes.EmptyRef();
		else
			filterType = true;
			gymtype = service.getRef(stucParams.type,Type("EnumRef.gymTypes"), GetgymTypesArray());
		EndIf;
		query.SetParameter("FilterType", filterType);
		query.SetParameter("type", gymtype);
		
		select = query.Execute().Select();
		count=0;
		While select.Next() Do
			gymStruct = New Structure();
			gymStruct.Insert("uid", XMLString(select.Ref));
			gymStruct.Insert("name", select.description);
			If Not stucParams.short Then
				count=count+1;
				gymStruct.Insert("gymId", gymStruct.uid);
				gymStruct.Insert("type", "Club");
				gymStruct.Insert("state", select.state);			
				gymStruct.Insert("address", select.address);
				gymStruct.Insert("photo", select.photo);
				gymStruct.Insert("phone", select.phone);
				gymStruct.Insert("weekdaysTime", select.weekdaysTime);
				gymStruct.Insert("holidaysTime", select.holidaysTime);
				gymStruct.Insert("hasAccess", ?(stucParams.authorized, select.hasAccess, false));
				gymStruct.Insert("base", ?(stucParams.authorized, select.base, false));
				gymStruct.Insert("order", count);	
				gymStruct.Insert("metro", HTTP.decodeJSON(select.nearestMetro, Enums.JSONValueTypes.array));
			
				coords = New Structure();
				coords.Insert("latitude", select.latitude);
				coords.Insert("longitude", select.longitude);
				gymStruct.Insert("coords", coords);
			
				segment = New Structure();
				segment.Insert("name", select.segment);
				segment.Insert("color", select.segmentColor);
				gymStruct.Insert("segment", segment);			
			EndIf;
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
													?(requestStruct.Property("gymId"), XMLValue(Type("CatalogRef.gyms"), requestStruct.gymId), General.getOnlineGym(parameters)),
													?(requestStruct.Property("entryType"),requestStruct.entryType,New Array())));
		
	parameters.Insert("answerBody", HTTP.encodeJSON(productArray));		

EndProcedure

Function  getArrProduct(params) Export
	stucParams = New Structure("byArray,Array, productDirection,language,gym,entryType,short",
											True,
											New Array(),
											Undefined,
											Catalogs.languages.EmptyRef(),
											Undefined,
											New Array(),
											False);
	FillPropertyValues(stucParams, params);
	If stucParams.productDirection = Undefined then
   	   		stucParams.productDirection = enums.productDirections.fitness;
	EndIf;
	
	entryType = stucParams.entryType;
		
	if entryType.Count() = 0 then
		entryType.Add("personal");
		entryType.Add("group");	
	EndIf;
	
	baseImgURL = GeneralReuse.getBaseImgURL();
	
	Res = ?(stucParams.byArray, New Map, New Array);
	
	query = New Query("SELECT
	|	gymsProducts.product,
	|	gymsProducts.productDirection,
	|	CASE
	|		WHEN VALUETYPE(gymsProducts.price) = TYPE(STRING)
	|			THEN UNDEFINED
	|		ELSE gymsProducts.price
	|	END AS price
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
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
	|WHERE
	|	TT.product.endDate > &CurrentDate
	|ORDER BY
	|	TT.product.order
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
	|where
	|	Not &short
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product AS product,
	|	ISNULL(productsMapping.uid, """") AS uid,
	|	ISNULL(productsMapping.entryType, """") AS entryType
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.productsMapping AS productsMapping
	|		ON TT.product = productsMapping.product
	|where
	|	Not &short
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.product,
	|	productsauthors.author,
	|	ISNULL(employeestranslation.firstName, employeestranslation.Ref.firstName) AS firstName,
	|	ISNULL(employeestranslation.lastName, employeestranslation.Ref.lastName) AS lastName
	|FROM
	|	TT AS TT
	|		INNER JOIN Catalog.products.authors AS productsauthors
	|			LEFT JOIN Catalog.employees.translation AS employeestranslation
	|			ON productsauthors.author = employeestranslation.Ref
	|			AND employeestranslation.language = &language
	|		ON TT.product = productsauthors.Ref
	|where
	|	Not &short
	|	AND
	|	NOT productsauthors.author.Ref IS NULL");
	

	query.SetParameter("productDirection", stucParams.productDirection);
	query.SetParameter("gym", stucParams.gym);	
	query.SetParameter("byArray", stucParams.byArray);
	query.SetParameter("Array", stucParams.Array);
	query.SetParameter("language", stucParams.language);
	query.SetParameter("CurrentDate", ToUniversalTime(CurrentDate()));
	query.SetParameter("entryType",entryType);
	query.SetParameter("short",stucParams.short);
	
	results = query.ExecuteBatch();
	select = results[1].Select();
	selectTags = results[2].Select();
	selectMapping = results[3].Select();
	selectAuthor = results[4].Select();
	
	While select.Next() Do
		productStruct = New Structure();
		productStruct.Insert("uid", XMLString(select.product));		
		productStruct.Insert("name", select.description);		
		productStruct.Insert("shortDescription", select.shortDescription);
		
		If select.photo = "" And select.productDirection = Enums.productDirections.fitness Then
			productStruct.Insert("photo", baseImgURL + "/service/fitness.jpg");
		ElsIf select.photo = "" And select.productDirection = Enums.productDirections.spa Then
			productStruct.Insert("photo", baseImgURL + "/service/spa.jpg");
		Else			 	 
			productStruct.Insert("photo", select.photo);
		EndIf;
			
		If Not stucParams.short Then
			if select.price <> Undefined and select.price <> "" then
				productStruct.Insert("price", select.price);
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
		
			authorArray = New Array();
			While selectAuthor.FindNext(New Structure("product", select.product)) Do
				authorStruct = New Structure();
				authorStruct.Insert("uid", XMLString(selectAuthor.author));
				authorStruct.Insert("firstName", selectAuthor.firstName);
				authorStruct.Insert("lastName", selectAuthor.lastName);			
				authorArray.Add(authorStruct);
			EndDo;
			productStruct.Insert("author", authorArray);
		
			selectMapping.Reset();
		EndIf;
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
	|		isUsed) AS availableSections,
	|	chain.rulesRef AS rules,
	|	chain.pdnRef AS pdn
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
		chainStruct.Insert("rules", select.rules);
		chainStruct.Insert("pdn", select.pdn);		
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
		messageStruct.Insert("noteId", 		XMLString(select.message));
		messageStruct.Insert("date", 		XMLString(ToLocalTime(select.registrationDate, tokenContext.timeZone)));
		messageStruct.Insert("title", 		select.title);
		messageStruct.Insert("text", 		select.text);
		messageStruct.Insert("read", 		select.read);
		messageStruct.Insert("objectId", 	select.objectId);
		if tokenContext.appType = Enums.appTypes.Employee then
			messageStruct.Insert("objectType", "PersonalService");
		Else
			messageStruct.Insert("objectType", select.objectType);
		endif;
		
		array.add(messageStruct);
	EndDo;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(array));

EndProcedure

Function GetgymTypesArray()
	gymTypes = "gym studio outdoor online";
	Return StrSplit(gymTypes, " ");
EndFunction

// SC-099054
Procedure chainListEdna(parameters) Export

	language = parameters.language;
	brand = parameters.brand; // Это строковое значение
	
	array = New array;
	
	if brand = Enums.brandTypes.None then
		brand = Enums.brandTypes.WorldClass; 
	EndIf;

	query = New Query();
	query.text = "SELECT
	|	ISNULL(chaininterfaceText.description, chain.Description) AS Description,
	|	chain.Code AS code,
	|	chain.Ref AS chain
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
	query.SetParameter("brand", brand);
	
	select = query.Execute().Select();
	
	RecordCount = select.Count();
	
	HeadrStruct = New Structure();
	HeadrStruct.Insert("RecordCount", RecordCount);
	array.add(HeadrStruct);

	While select.Next() Do
		chainStruct = New Structure();
		chainStruct.Insert("description", select.Description);
		chainStruct.Insert("id", select.code);
		//chainStruct.Insert("chain", select.chain);
	
		array.add(chainStruct);
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(array));

EndProcedure

Procedure gymListEdna(parameters) Export

	requestStruct = parameters.requestStruct;
	gymArray = New Array();	

	If Not requestStruct.Property("chain") Then		
		parameters.Insert("error", "chainCodeError");
	Else	 

	query = New Query();
	query.text = "SELECT
	|	gyms.Ref AS Ref,
	|	gyms.Description AS Description
	|FROM
	|	Catalog.gyms AS gyms
	|WHERE
	|	NOT gyms.DeletionMark
	|	AND gyms.chain.Code = &chaincode
	|	AND
	|	NOT gyms.chain = VALUE(Справочник.chains.ПустаяСсылка)
	|ORDER BY
	|	gyms.Code";
	
	query.SetParameter("chaincode", requestStruct.chain); 
	
	select = query.Execute().Select();
	
	RecordCount = select.Count();
	
	HeaderStruct = New Structure();
	HeaderStruct.Insert("RecordCount", RecordCount);
	gymArray.add(HeaderStruct);
	
	While select.Next() Do
		chainStruct = New Structure();
		chainStruct.Insert("description", select.Description);
		chainStruct.Insert("uid", XMLString(select.Ref));
	
		gymArray.add(chainStruct);
	EndDo;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(gymArray));	
	
EndProcedure
//

// SC-099055
Procedure incomingThread(parameters) Export
	
	JSONReader = New JSONReader;
	JSONReader.SetString(parameters.requestBody); 
	RequestParameters = ReadJSON(JSONReader,,Undefined);
	JSONReader.Close();
	
	struct = New Structure;
	struct.Insert("success", True);
	
	If Not RequestParameters.Property("client") Then	
		parameters.Insert("error", "ThreadClientError");
		struct.Insert("success", False);	
	EndIf;
	
	If Not RequestParameters.Property("thread") Then	
		parameters.Insert("error", "threadError");
		struct.Insert("success", False);
	EndIf;
	
	If Not RequestParameters.Property("operator") Then	
		parameters.Insert("error", "ThreadOperatorError");
		struct.Insert("success", False);
	EndIf;
	
	If struct.success Then 
	threadid = RequestParameters.thread.id;
	//StartTime = RequestParameters.thread.startTime; 
	ChannelType = RequestParameters.thread.channelType;
	ArrayMessages = RequestParameters.thread.messages;
	ArrayTags = RequestParameters.thread.Tags;
	
	NewObject  = Catalogs.Thread.CreateItem();
	NewObject.Description  = threadid;
	NewObject.IncomingData = parameters.requestBody; 
	//NewObject.StartTime = StartTime;  
	NewObject.ChannelType = ChannelType; 
	NewObject.login = RequestParameters.operator.login;
	NewObject.phone = RequestParameters.client.phone;  
	
	For Each StrMessage In ArrayMessages Do
		NewSrt = NewObject.ThreadMessages.Add();
		NewSrt.Message = StrMessage.text;
		//NewSrt.ResponseTime = StrMessage.receivedAt; 
	EndDo;
	
	For Each StrTags In ArrayTags Do
		NewSrt = NewObject.ThreadTags.Add();
		NewSrt.tag = StrTags.tag;
	EndDo;
	
	NewObject.Write();
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure
//

// SC-099057 
Procedure OutMessageMatchers(parameters) Export
	
	requestStruct = parameters.requestStruct;		
	tokenContext  = parameters.tokenContext;
	
	If Not requestStruct.Property("imType") Then	
		parameters.Insert("error", "imTypeError");	
	Else	
		
		body = new structure;
		body.Insert("imType", requestStruct.imType); 
		body.Insert("subject", requestStruct.subject);
		
		Connection ="/api/getOutMessageMatchers"; 
		parametersConn = ConnStruct(tokenContext.holding); 
		
		ConnectionHTTP = New HTTPConnection(parametersConn.server, parametersConn.port,,,, parametersConn.timeout, ?(parametersConn.secureConnection, New OpenSSLSecureConnection(), Undefined), parametersConn.useOSAuthentication);
		
		requestHTTP = New HTTPRequest(Connection);
		requestHTTP.Headers.Insert("Content-Type", "application/json");
		requestHTTP.Headers.Insert("X-API-KEY", parametersConn.key); 
		requestHTTP.SetBodyFromString(http.encodeJSON(body), TextEncoding.UTF8);
		try
			answerHTTP = ConnectionHTTP.Post(requestHTTP);
		Except
			answerHTTP = Undefined;
		EndTry;
		
		responseStruct = New Structure();
		
		If answerHTTP <> Undefined Then		
			responseStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);
		Else
			responseStruct.Insert("error","answerHTTP = Undefined");
		EndIf;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(responseStruct));
	
EndProcedure

Procedure imOutHSM(parameters) Export

	requestStruct = parameters.requestStruct;
	tokenContext  = parameters.tokenContext;
	
	If Not requestStruct.Property("body") Then	
		parameters.Insert("error", "BodyError");	
	Else
	
	body = requestStruct.body; // заполненое тело запроса	
		
	Connection ="/api/imOutHSM"; 
	parametersConn = ConnStruct(tokenContext.holding);
	
	ConnectionHTTP = New HTTPConnection(parametersConn.server, parametersConn.port,,,, parametersConn.timeout, ?(parametersConn.secureConnection, New OpenSSLSecureConnection(), Undefined), parametersConn.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/json");
	requestHTTP.Headers.Insert("X-API-KEY", parametersConn.key); 
	requestHTTP.SetBodyFromString(http.encodeJSON(body), TextEncoding.UTF8);
		try
			answerHTTP = ConnectionHTTP.Post(requestHTTP);
		Except
			answerHTTP = Undefined;
		EndTry;
		
		responseStruct = New Structure();
		
		If answerHTTP <> Undefined Then		
			responseStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);
		Else
			responseStruct.Insert("error","answerHTTP = Undefined");
		EndIf;
	EndIf;	
	
	parameters.Insert("answerBody", HTTP.encodeJSON(responseStruct));
	
EndProcedure

Function ConnStruct(holding , gym = Undefined, chain = Undefined)
			
	queryConnection = New query;
	queryConnection.Text = 
	"SELECT
	|	CASE
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection
	|		WHEN NOT chainConnection.connection IS NULL
	|			THEN chainConnection.connection
	|		ELSE holdingConnection.connection
	|	END AS Connection
	|FROM
	|	(SELECT
	|		holdingConnection.connection AS connection,
	|		1 AS Link
	|	FROM
	|		InformationRegister.holdingsConnectionsThread AS holdingConnection
	|	WHERE
	|		holdingConnection.holding = &holding
	|		AND holdingConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND holdingConnection.chain = VALUE(catalog.chains.emptyref)) AS holdingConnection
	|		LEFT JOIN (SELECT
	|			gymConnection.connection AS connection,
	|			1 AS Link
	|		FROM
	|			InformationRegister.holdingsConnectionsThread AS gymConnection
	|		WHERE
	|			gymConnection.holding = &holding
	|			AND gymConnection.gym = &gym
	|			AND gymConnection.chain = VALUE(catalog.chains.emptyref)
	|			AND &chain = VALUE(catalog.chains.emptyref)) AS gymConnection
	|		ON holdingConnection.Link = gymConnection.Link
	|		LEFT JOIN (SELECT
	|			chainConnection.connection AS connection,
	|			1 AS Link
	|		FROM
	|			InformationRegister.holdingsConnectionsThread AS chainConnection
	|		WHERE
	|			chainConnection.holding = &holding
	|			AND chainConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|			AND &gym = VALUE(Catalog.gyms.EmptyRef)
	|			AND chainConnection.chain = &chain) AS chainConnection
	|		ON holdingConnection.Link = chainConnection.Link";
	
	queryConnection.SetParameter("holding", holding );
	queryConnection.SetParameter("gym",   ?(gym   = Undefined,Catalogs.gyms.EmptyRef(),gym)); 
	queryConnection.SetParameter("chain", ?(chain = Undefined,Catalogs.chains.EmptyRef(),chain));
	
	result = queryConnection.Execute();
	answer = New Structure();
	If result.IsEmpty() then
		Return answer;
	EndIf;	
	
	select = result.Select();
	select.Next();
	Conn = select.connection; 	

	
//	answer.Insert("server","im.edna.ru");
//	answer.Insert("port",443);
//	answer.Insert("timeout",30);
//	answer.Insert("secureConnection", True);
//	answer.Insert("useOSAuthentication", False); 
//	answer.Insert("key", "2996db9c-ac8c-4d20-87ab-414da58291e6"); 
	answer.Insert("server",Conn.server);
	answer.Insert("port",Conn.port);
	answer.Insert("timeout",Conn.timeout);
	answer.Insert("secureConnection", Conn.secureConnection);
	answer.Insert("useOSAuthentication", Conn.UseOSAuthentication); 
	answer.Insert("key", Conn.key); 
	Return answer;	
		
EndFunction
//
