
Function profile(user, appType) Export
	
	struct = initProfileStruct();
	
	query	= New Query();
	query.Text	= "SELECT
	|	CASE
	|		WHEN users.owner.birthday = DATETIME(1, 1, 1)
	|			THEN UNDEFINED
	|		ELSE users.owner.birthday
	|	END AS birthday,
	|	users.owner.canUpdatePersonalData AS canUpdatePersonalData,
	|	users.owner.email AS email,
	|	users.owner.firstName AS firstName,
	|	users.owner.lastName AS lastName,
	|	users.owner.secondName AS secondName,
	|	users.owner.code AS phone,
	|	CASE
	|		WHEN users.owner.gender = """"
	|			THEN ""none""
	|		ELSE users.owner.gender
	|	END AS gender,
	|	REFPRESENTATION(users.owner.status) AS status,
	|	users.barcode AS barcode,
	|	not users.notSubscriptionEmail AS subscriptionEmail,
	|	not users.notSubscriptionSms AS subscriptionSms,
	|	users.registrationDate AS registrationDate,
	|	"""" AS rating,
	|	users.owner.photo AS photo
	|FROM
	|	Catalog.users AS users
	|WHERE
	|	users.Ref = &user
//	|;
//	|////////////////////////////////////////////////////////////////////////////////
//	|SELECT
//	|	cacheTypes.Code AS cacheCode,
//	|	cacheTypes.Ref AS cacheType,
//	|	&user AS user,
//	|	&appType AS appType
//	|INTO TT
//	|FROM
//	|	Catalog.cacheTypes AS cacheTypes
//	|WHERE
//	|	cacheTypes.request = &requestName
//	|;
//	|////////////////////////////////////////////////////////////////////////////////
//	|SELECT
//	|	TT.cacheCode AS cacheCode,
//	|	usersStates.stateValue AS cacheValue
//	|FROM
//	|	TT AS TT
//	|		LEFT JOIN InformationRegister.usersStates AS usersStates
//	|		ON TT.cacheType = usersStates.cacheValuesType
//	|		AND TT.user = usersStates.user
//	|		AND TT.appType = usersStates.appType
//	|WHERE
//	|	NOT usersStates.stateValue IS NULL
|";
	
	query.SetParameter("user", user);
//	query.SetParameter("appType", appType);
//	query.SetParameter("requestName", "getUserProfile");
	
//	queryResults = query.ExecuteBatch();
//	queryResult = queryResults[0];
	queryResult = query.Execute();
	
	If Not queryResult.IsEmpty() Then
		select = queryResult.Select();
		select.Next();
		FillPropertyValues(struct, select);
//		cacheSelect = queryResults[2].Select();
//		While cacheSelect.Next() Do
//			struct.Insert(cacheSelect.cacheCode, HTTP.decodeJSON(cacheSelect.cacheValue));
//		EndDo;		
	EndIf;
		
	Return struct;
	
EndFunction

Function initProfileStruct() Export
	Return New Structure("phone, birthday, canUpdatePersonalData, email, firstName, lastName, registrationDate, secondName, gender, status, photo, barcode, subscriptionEmail, subscriptionSms, rating", "", Undefined, False, "", "", "", Undefined, "", "none", "unauthorized", "", "", False, False, "");
EndFunction

Procedure updateCache(val parameters) Export
		
//	tokenContext = parameters.tokenContext;
//		
//	query = New Query("SELECT
//	|	chainscacheTypes.cacheType As cacheType,
//	|	chainscacheTypes.cacheType.code AS cacheValuesTypeCode,
//	|	chainscacheTypes.cacheType.defaultValueType AS cacheDefaultValueType,
//	|	ISNULL(usersStates.outdated, TRUE) AS outdated
//	|FROM
//	|	Catalog.chains.cacheTypes AS chainscacheTypes
//	|		LEFT JOIN InformationRegister.usersStates AS usersStates
//	|		ON chainscacheTypes.cacheType = usersStates.cacheValuesType
//	|		AND usersStates.user = &user
//	|		AND usersStates.appType = &appType
//	|WHERE
//	|	chainscacheTypes.Ref = &chain
//	|	and ISNULL(usersStates.outdated, TRUE) = TRUE
//	|	AND chainscacheTypes.isUsed
//	|	AND chainscacheTypes.isUpdated");
//	
//	query.SetParameter("user", tokenContext.user);
//	query.SetParameter("appType", tokenContext.appType);
//	query.SetParameter("chain", tokenContext.chain);
//
//	result = query.Execute();
//
//	If Not result.IsEmpty() Then
//		select = result.Select();		
//		While select.Next() Do
//			parameters.Insert("requestName", "update" + select.cacheValuesTypeCode);
//			General.executeRequestMethod(parameters);
//			record = InformationRegisters.usersStates.CreateRecordManager();
//			record.user = tokenContext.user;
//			record.appType = tokenContext.appType;
//			record.cacheValuesType = select.cacheType;
//			If parameters.error = "" Then
//				record.stateValue = StrReplace(parameters.answerBody, Chars.NBSp, "");
//			Else				
//				record.stateValue = HTTP.encodeJSON(HTTP.decodeJSON("", select.cacheDefaultValueType))
//			EndIf;
//			record.Write();
//		EndDo;		
//	EndIf;
	
EndProcedure

//Комент 1