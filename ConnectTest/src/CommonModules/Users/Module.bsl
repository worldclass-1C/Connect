
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
	|	"""" AS photo
	|FROM
	|	Catalog.users AS users
	|WHERE
	|	users.Ref = &user
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	cacheValuesTypes.Code AS cacheCode,
	|	cacheValuesTypes.Ref AS cacheValuesType,
	|	&user AS user,
	|	&appType AS appType
	|INTO TT
	|FROM
	|	Catalog.cacheValuesTypes AS cacheValuesTypes
	|WHERE
	|	cacheValuesTypes.request = &requestName
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.cacheCode AS cacheCode,
	|	usersStates.stateValue AS cacheValue
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.usersStates AS usersStates
	|		ON TT.cacheValuesType = usersStates.cacheValuesType
	|		AND TT.user = usersStates.user
	|		AND TT.appType = usersStates.appType
	|WHERE
	|	NOT usersStates.stateValue IS NULL";
	
	query.SetParameter("user", user);
	query.SetParameter("appType", appType);
	query.SetParameter("requestName", "getUserProfile");
	
	queryResults = query.ExecuteBatch();
	queryResult = queryResults[0];
		
	If Not queryResult.IsEmpty() Then
		select = queryResult.Select();
		select.Next();
		FillPropertyValues(struct, select);
		cacheSelect = queryResults[2].Select();
		While cacheSelect.Next() Do
			struct.Insert(cacheSelect.cacheCode, HTTP.decodeJSON(cacheSelect.cacheValue));
		EndDo;		
	EndIf;
		
	Return struct;
	
EndFunction

Function initProfileStruct() Export
	Return New Structure("phone, birthday, canUpdatePersonalData, email, firstName, lastName, registrationDate, secondName, gender, status, photo, barcode, subscriptionEmail, subscriptionSms, rating", "", Undefined, False, "", "", "", Undefined, "", "none", "unauthorized", "", "", False, False, "");
EndFunction

Procedure updateCache(val parameters) Export	
		
	tokenContext = parameters.tokenContext;
		
	query = New Query("SELECT
	|	chainscacheValuesTypes.cacheValuesType As cacheValuesType,
	|	chainscacheValuesTypes.cacheValuesType.code AS cacheValuesTypeCode,
	|	chainscacheValuesTypes.cacheValuesType.defaultValueType AS cacheDefaultValueType,
	|	ISNULL(usersStates.outdated, TRUE) AS outdated
	|FROM
	|	Catalog.chains.cacheValuesTypes AS chainscacheValuesTypes
	|		LEFT JOIN InformationRegister.usersStates AS usersStates
	|		ON chainscacheValuesTypes.cacheValuesType = usersStates.cacheValuesType
	|		AND usersStates.user = &user
	|		AND usersStates.appType = &appType
	|WHERE
	|	chainscacheValuesTypes.Ref = &chain
	|	and ISNULL(usersStates.outdated, TRUE) = TRUE
	|	AND chainscacheValuesTypes.isUsed
	|	AND chainscacheValuesTypes.isUpdated");
	
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);
	query.SetParameter("chain", tokenContext.chain);

	result = query.Execute();

	If Not result.IsEmpty() Then
		select = result.Select();		
		While select.Next() Do
			parameters.Insert("requestName", "update" + select.cacheValuesTypeCode);
			General.executeRequestMethod(parameters);
			record = InformationRegisters.usersStates.CreateRecordManager();
			record.user = tokenContext.user;
			record.appType = tokenContext.appType;
			record.cacheValuesType = select.cacheValuesType;
			If parameters.errorDescription.result = "" Then
				record.stateValue = StrReplace(parameters.answerBody, Chars.NBSp, "");
			Else				
				record.stateValue = HTTP.encodeJSON(HTTP.decodeJSON("", select.cacheDefaultValueType))
			EndIf;
			record.Write();
		EndDo;		
	EndIf;
	
EndProcedure