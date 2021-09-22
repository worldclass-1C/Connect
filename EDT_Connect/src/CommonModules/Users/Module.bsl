
Function profile(user, appType) Export
	
	struct = initProfileStruct();
	
	query	= New Query();
	query.Text	= "SELECT
	|	CASE
	|		WHEN users.owner.birthday = DATETIME(1, 1, 1)
	|			THEN UNDEFINED
	|		ELSE users.owner.birthday
	|	END AS birthday,
	|	users.canUpdatePersonalData AS canUpdatePersonalData,
	|	users.email AS email,
	|	users.firstName AS firstName,
	|	users.lastName AS lastName,
	|	users.secondName AS secondName,
	|	users.owner.code AS phone,
	|	CASE
	|		WHEN users.gender = """"
	|			THEN ""none""
	|		ELSE users.gender
	|	END AS gender,
	|	CASE
	|		WHEN users.owner.status IS NULL
	|			THEN ""unauthorized""
	|		ELSE REFPRESENTATION(users.owner.status)
	|	END AS status,
	|	users.userCode AS userCode,
	|	users.barcode AS barcode,
	|	not users.notSubscriptionEmail AS subscriptionEmail,
	|	not users.notSubscriptionSms AS subscriptionSms,
	|	users.registrationDate AS registrationDate,
	|	"""" AS rating,
	|	users.photo AS photo,
	|	users.ref AS owner
	|FROM
	|	Catalog.users AS users
	|WHERE
	|	users.Ref = &user";
	
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
		struct.uid = XMLString(select.owner);
//		cacheSelect = queryResults[2].Select();
//		While cacheSelect.Next() Do
//			struct.Insert(cacheSelect.cacheCode, HTTP.decodeJSON(cacheSelect.cacheValue));
//		EndDo;		
	EndIf;
		
	Return struct;
	
EndFunction

Function initProfileStruct() Export
	Return New Structure("uid, phone, birthday, canUpdatePersonalData, email, firstName, lastName, registrationDate, secondName, gender, status, photo, userCode, barcode, subscriptionEmail, subscriptionSms, rating", "", "", Undefined, False, "", "", "", Undefined, "", "none", "unauthorized", "", "", "", False, False, "");
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