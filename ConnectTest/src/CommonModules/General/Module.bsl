
Procedure executeRequestMethod(parameters) Export
	
	parameters.Insert("errorDescription", Check.requestParameters(parameters));	
	
	If parameters.errorDescription.result = "" Then
		If parameters.requestName = "chainlist" Then
			chainList(parameters);
		ElsIf parameters.requestName = "countrycodelist" Then 
			countryCodeList(parameters);
		ElsIf parameters.requestName = "config" Then
			config(parameters);
		ElsIf parameters.requestName = "signin" Then
			signIn(parameters);
		ElsIf parameters.requestName = "confirmphone" Then
			confirmPhone(parameters);
		ElsIf parameters.requestName = "addusertotoken" Then 
			addUserToToken(parameters);
		ElsIf parameters.requestName = "registerdevice" Then 
			registerDevice(parameters);
		ElsIf parameters.requestName = "signout" Then 
			signOut(parameters);
		ElsIf parameters.requestName = "accountprofile" Then 
			accountProfile(parameters);	
		ElsIf parameters.requestName = "userprofile" Then 
			userProfile(parameters);
		ElsIf parameters.requestName = "usersummary" Then 
			userSummary(parameters);	
		ElsIf parameters.requestName = "cataloggyms"
				Or parameters.requestName = "gymlist" Then
			gymList(parameters);
		ElsIf parameters.requestName = "gyminfo" Then
			gymInfo(parameters);	
		ElsIf parameters.requestName = "gymschedule" Then
			gymSchedule(parameters);
		ElsIf parameters.requestName = "employeelist" Then
			employeeList(parameters);
		ElsIf parameters.requestName = "employeeinfo" Then
			employeeInfo(parameters);
		ElsIf parameters.requestName = "paymentpreparation" Then
			paymentPreparation(parameters);
		ElsIf parameters.requestName = "payment" Then
			payment(parameters);
		ElsIf parameters.requestName = "paymentstatus" Then
			paymentStatus(parameters);
		ElsIf parameters.requestName = "bindcard" Then
			bindCard(parameters);
		ElsIf parameters.requestName = "catalogcancelcauses"
				Or parameters.requestName = "cancelcauseslist" Then // проверить описание в API
			cancellationReasonsList(parameters);
		ElsIf parameters.requestName = "notificationlist" Then // проверить описание в API
			notificationList(parameters);
		ElsIf parameters.requestName = "readnotification" Then // проверить описание в API
			readNotification(parameters);
		ElsIf parameters.requestName = "unreadnotificationcount" Then // проверить описание в API
			unReadNotificationCount(parameters);
		ElsIf parameters.requestName = "sendMessage" Then 
			sendMessage(parameters);
		ElsIf parameters.requestName = "imagePOST" Then 
			imagePOST(parameters);
		ElsIf parameters.requestName = "imageDELETE" Then 
			imageDELETE(parameters);			
		ElsIf False
				Or parameters.requestName = "addchangeusers"					
				Or parameters.requestName = "addclassmember"
				Or parameters.requestName = "deleteclassmember"
				Or parameters.requestName = "addemployees"
				Or parameters.requestName = "addgymemployees"
				Or parameters.requestName = "deletegymemployees"
				Or parameters.requestName = "addprovidedservices"
				Or parameters.requestName = "addgymsschedule"
				Or parameters.requestName = "addgyms"				
				Or parameters.requestName = "addrequest"
				Or parameters.requestName = "adderrordescription"
				Or parameters.requestName = "addcancelcauses" 
		Then 
			changeCreateItems(parameters);
		Else
			executeExternalRequest(parameters);
		EndIf;
	EndIf;
			
EndProcedure

Procedure config(parameters)

	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;	
	brand = parameters.brand;
	language = parameters.language;
	errorDescription = parameters.ErrorDescription;

	struct = New Structure();

	query = New Query();
	query.Text = "SELECT
	|	currentAppVersions.appVersion AS minVersion
	|FROM
	|	InformationRegister.currentAppVersions AS currentAppVersions
	|WHERE
	|	currentAppVersions.appType = &appType
	|	AND currentAppVersions.systemType = &systemType
	|	AND currentAppVersions.brand = &brand
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	REFPRESENTATION(tokens.appType) AS appType,
	|	tokens.appVersion AS appVersion,
	|	tokens.chain.Code AS chainCode,
	|	tokens.deviceModel AS deviceModel,
	|	tokens.deviceToken AS deviceToken,
	|	REFPRESENTATION(tokens.systemType) AS systemType,
	|	tokens.systemVersion AS systemVersion,
	|	tokens.lockDate,
	|	tokens.chain.cacheValuesTypes.(
	|		cacheValuesType.Code AS section,
	|		isUsed) AS availableSections
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.Ref = &token";

	query.SetParameter("brand", Enums.brandTypes[brand]);
	query.SetParameter("appType", Enums.appTypes[requestStruct.appType]);
	query.SetParameter("systemType", Enums.systemTypes[requestStruct.systemType]);
	query.SetParameter("token", tokenContext.token);

	queryResults = query.ExecuteBatch();
	queryResult = queryResults[0];

	If queryResult.IsEmpty() Then
		struct.Insert("minVersion", 0);
	Else
		selection = queryResult.Select();
		selection.Next();
		struct.Insert("minVersion", selection.minVersion);
	EndIf;

	queryResult = queryResults[1];

	If not queryResult.IsEmpty() Then		
		selection = queryResult.Select();
		selection.Next();
		If ValueIsFilled(selection.lockDate) And selection.lockDate < ToUniversalTime(CurrentDate()) Then
			errorDescription = Service.getErrorDescription(language, "tokenExpired");	
		Else
			tokenStruct = New Structure();
			tokenStruct.Insert("appType", selection.appType);
			tokenStruct.Insert("appVersion", selection.appVersion);
			tokenStruct.Insert("chainCode", selection.chainCode);
			tokenStruct.Insert("deviceModel", selection.deviceModel);
			tokenStruct.Insert("deviceToken", selection.deviceToken);
			tokenStruct.Insert("systemType", selection.systemType);
			tokenStruct.Insert("systemVersion", selection.systemVersion);			
			availableSections = New Array();
			For Each row In selection.availableSections.Unload() Do
				If row.isUsed Then
					availableSections.Add(row.section);
				EndIf;
			EndDo;
			tokenStruct.Insert("availableSections", availableSections);
			struct.Insert("tokenInfo", tokenStruct);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure chainList(parameters)

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
	|	chain.cacheValuesTypes.(
	|		cacheValuesType.Code AS section,
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
	
	If brand = "" or Enums.brandTypes[brand] = Enums.brandTypes.None Then
		query.Text = StrReplace(query.Text, "AND chain.brand = &brand", "");
		nameTogetherChain = True;
	Else
		query.SetParameter("brand", Enums.brandTypes[brand]);
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
			If row.isUsed Then
				availableSections.Add(row.section);	
			EndIf;		
		EndDo;
		chainStruct.Insert("availableSections", availableSections);		
		array.add(chainStruct);
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(array));
	parameters.Insert("notSaveAnswer", True);

EndProcedure

Procedure countryCodeList(parameters)
	
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
	parameters.Insert("notSaveAnswer", True);
	
EndProcedure

Procedure registerDevice(parameters)
	
	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;
	struct = New Structure();
	
	query = New Query("SELECT
	|	chains.Ref AS chain,
	|	chains.holding AS holding,
	|	chains.timeZone AS timeZone
	|FROM
	|	Catalog.chains AS chains
	|WHERE
	|	chains.Code = &chainCode");
	query.SetParameter("chainCode", requestStruct.chainCode);
	
	queryResult = query.Execute();
	If queryResult.IsEmpty() Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noChainCode"));
	Else		
		select = queryResult.Select();
		select.Next();
//		If tokenContext.Property("holding") Then
//			isHoldingChanged = tokenContext.holding <> select.holding;
//		Else
//			isHoldingChanged = False;
//		EndIf;
		tokenStruct = New Structure();
		tokenStruct.Insert("appType", Enums.appTypes[requestStruct.appType]);
		tokenStruct.Insert("appVersion", requestStruct.appVersion);
		tokenStruct.Insert("chain", select.chain);
		tokenStruct.Insert("deviceModel", requestStruct.deviceModel);
		tokenStruct.Insert("deviceToken", requestStruct.deviceToken);
		tokenStruct.Insert("holding", select.holding);
		tokenStruct.Insert("systemType", Enums.systemTypes[requestStruct.systemType]);
		tokenStruct.Insert("systemVersion", requestStruct.systemVersion);
		tokenStruct.Insert("timeZone", select.timeZone);		
		
		strToken = XMLString(Token.get(tokenContext.token, tokenStruct));
		struct.Insert("token",  strToken + Account.tempPassword()); 
//		If isHoldingChanged Then
//			struct.Insert("token",  strToken + requestStruct.chainCode);
//		ElsIf tokenContext.user.IsEmpty() Then
//			 struct.Insert("token",  strToken + Account.tempPassword());
//		Else
//			struct.Insert("token",  strToken + Account.tempPassword());
//		EndIf;
		
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Procedure signIn(parameters)

	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	errorDescription = parameters.errorDescription;

	struct = New Structure();

	retryTime = Check.timeBeforeSendSms(tokenContext.token);
	
	If requestStruct.phone = "+73232323223" Then
		struct.Insert("result", "Ok");
		struct.Insert("retryTime", 0);		
		Account.incPasswordSendCount(tokenContext.token, requestStruct.phone, "3223");	
	ElsIf retryTime > 0 and requestStruct.phone <> "+79154006161"
			and requestStruct.phone <> "+79684007188"
			and requestStruct.phone <> "+79035922412"
			and requestStruct.phone <> "+79037478789" Then
		struct.Insert("result", "Fail");
		struct.Insert("retryTime", retryTime);		
	Else
		chain = Catalogs.chains.FindByCode(requestStruct.chainCode);
		If ValueIsFilled(chain) Then
			If tokenContext.chain <> chain Then				
				changeStruct = New Structure("chain, holding", chain, chain.holding);
				Token.editProperty(tokenContext.token, changeStruct);
			EndIf;
		Else
			errorDescription = Service.getErrorDescription(language, "chainCodeError");
		EndIf;
		If errorDescription.result = "" Then
			tempCode = Account.tempPassword();
			informationChannels = New Array();
			informationChannels.Add(Enums.informationChannels.sms);
			rowsArray = New Array();
			rowsArray.Add(tempCode);
			rowsArray.Add(?(language = "ru", " - ваш код для входа", " - your login code"));
			rowsArray.Add(?(language = "ru", ", действителен в течение 15 минут", ", valid for 15 minutes"));
			messageStruct = New Structure();
			messageStruct.Insert("phone", requestStruct.phone);
			messageStruct.Insert("title", "SMS code");
			messageStruct.Insert("text", StrConcat(rowsArray));
			messageStruct.Insert("holding", tokenContext.holding);
			messageStruct.Insert("informationChannels", informationChannels);
			messageStruct.Insert("priority", 0);
			Messages.newMessage(messageStruct, True);
			Account.incPasswordSendCount(tokenContext.token, requestStruct.phone, tempCode);
			struct.Insert("result", "Ok");
			struct.Insert("retryTime", 60);			
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure confirmPhone(parameters)

	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	
	struct = New Structure();
	
	answer = Check.password(tokenContext.token, requestStruct.password, language);
	errorDescription = answer.errorDescription;

	If errorDescription.result = "" Then
		queryUser = New Query("SELECT
		|	accounts.Ref AS account,
		|	ISNULL(users.Ref, VALUE(Catalog.users.EmptyRef)) AS user
		|FROM
		|	Catalog.accounts AS accounts
		|		LEFT JOIN Catalog.users AS users
		|		ON accounts.Ref = users.Owner
		|		AND users.holding = &holding
		|WHERE
		|	accounts.code = &phone");

		queryUser.SetParameter("holding", tokenContext.holding);
		queryUser.SetParameter("phone", answer.phone);
		queryUserResult = queryUser.Execute();
		If queryUserResult.isEmpty() Then
			answerStruct = Account.getFromExternalSystem(parameters, "phone", answer.phone);
			struct = answerStruct.response;
			errorDescription = answerStruct.errorDescription; 
		Else
			select = queryUserResult.Select();
			select.Next();
			If ValueIsFilled(select.user) Then
				changeStruct = New Structure("account, user", select.account, select.user);
				Token.editProperty(tokenContext.token, changeStruct);
				struct.Insert("userProfile", Account.profile(select.account));
				struct.Insert("userList", New Array());
				struct.Insert("token", XMLString(tokenContext.token) + Account.tempPassword());
				parametersNew = Service.getStructCopy(parameters);
				parametersNew.tokenContext.Insert("user", select.user);
				Users.updateCache(parametersNew);				
			Else	
				answerStruct = Account.getFromExternalSystem(parameters, "phone", answer.phone, select.account);
				struct = answerStruct.response;
				errorDescription = answerStruct.errorDescription;
			EndIf;		
		EndIf;
		If errorDescription.result = "" Then
			Account.delPassword(tokenContext.token);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure addUserToToken(parameters)
	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;
	If tokenContext.user.IsEmpty() Then
		answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid);
	Else
		answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid, tokenContext.user.owner);
	EndIf;
	answerStruct.response.Delete("userList");
	parameters.Insert("answerBody", HTTP.encodeJSON(answerStruct.response));
	parameters.Insert("errorDescription", answerStruct.errorDescription);
EndProcedure

Procedure signOut(parameters)
	tokenContext = parameters.tokenContext;
	changeStruct = New Structure("account, user", Catalogs.accounts.EmptyRef(), Catalogs.users.EmptyRef());
	Token.editProperty(tokenContext.token, changeStruct);
	parameters.Insert("answerBody", HTTP.encodeJSON(New Structure("token", XMLString(tokenContext.token) + Account.tempPassword())));	
EndProcedure

Procedure accountProfile(parameters)
	parameters.Insert("answerBody", HTTP.encodeJSON(Account.profile(parameters.tokenContext.account)));		
EndProcedure

Procedure userProfile(parameters)
	parameters.Insert("answerBody", HTTP.encodeJSON(Users.profile(parameters.tokenContext.user, parameters.tokenContext.appType)));	
EndProcedure

Procedure userSummary(parameters)
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

Procedure gymList(parameters)

	requestStruct = parameters.requestStruct;	
	authorized = ValueIsFilled(parameters.tokenContext.user);
	language = parameters.language;
	gymArray = New Array();
	
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("chain") Then
		errorDescription = Service.getErrorDescription(language, "chainCodeError");
	EndIf;

	If errorDescription.result = "" Then
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
		|	END AS state
		|FROM
		|	Catalog.gyms AS gyms
		|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
		|		ON gymstranslation.Ref = gyms.Ref
		|		AND gymstranslation.language = &language
		|WHERE
		|	NOT gyms.DeletionMark
		|	AND gyms.chain.code = &chainCode
		|	AND gyms.startDate <= &currentTime
		|	AND gyms.endDate >= &currentTime
		|	AND gyms.type <> VALUE(Enum.gymTypes.outdoor)");

		query.SetParameter("chainCode", requestStruct.chain);
		query.SetParameter("language", language);
		query.SetParameter("currentTime", parameters.currentTime);		
		
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
			gymStruct.Insert("hasAccess", ?(authorized, false, Undefined));
			gymStruct.Insert("metro", HTTP.decodeJSON(select.nearestMetro, Enums.JSONValueTypes.array));
			
			coords = New Structure();
			coords.Insert("latitude", select.latitude);
			coords.Insert("longitude", select.longitude);
			gymStruct.Insert("coords", coords);
			
			segment = New Structure();
			segment.Insert("name", select.segment);
			segment.Insert("color", select.segmentColor);
			gymStruct.Insert("segment", segment);			
			
			gymArray.add(gymStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure gymInfo(parameters)

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

Procedure gymSchedule(parameters)

	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	classesScheduleArray = New Array();
	
	errorDescription = Service.getErrorDescription(language);
	
	If Not requestStruct.Property("gymList") Then
		errorDescription = Service.getErrorDescription(language, "gymError");
	ElsIf Not requestStruct.Property("startDate") Then
		errorDescription = Service.getErrorDescription(language, "startDateError");
	ElsIf Not requestStruct.Property("endDate") Then
		errorDescription = Service.getErrorDescription(language, "endDateError");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query();
		querryTextArray = New Array();
		querryTextArray.Add("SELECT
		|	classesSchedule.Ref AS Doc,
		|	classesSchedule.period AS period,
		|	MAX(CASE
		|		WHEN classMembers.user = &user
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS recorded,
		|	MAX(CASE
		|		WHEN &currentTime >= classesSchedule.startRegistration
		|		AND &currentTime <= classesSchedule.endRegistration
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS canRecord,
		|	MAX(CASE
		|		WHEN DATEDIFF(&currentTime, classesSchedule.period, hour) > 8
		|			THEN TRUE
		|		ELSE FALSE
		|	END) AS canCancel,
		|	COUNT(classMembers.user) AS userPlaces,
		|	MAX(classesSchedule.availablePlaces) AS availablePlaces
		|INTO TT
		|FROM
		|	Catalog.classesSchedule AS classesSchedule
		|		LEFT JOIN InformationRegister.classMembers AS classMembers
		|		ON classesSchedule.Ref = classMembers.class
		|WHERE
		|	classesSchedule.gym IN (&gymList)
		|	AND classesSchedule.period BETWEEN &startDate AND &endDate
		|	AND classesSchedule.active
		|GROUP BY
		|	classesSchedule.Ref,
		|	classesSchedule.period
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TT.Doc,
		|	TT.period,
		|	TT.recorded,
		|	TT.canRecord,
		|	TT.canCancel,
		|	CASE
		|		WHEN TT.availablePlaces = 0
		|			THEN -1
		|		ELSE TT.availablePlaces - TT.userPlaces
		|	END AS availablePlaces,
		|	IsNull(classesScheduletranslation.fullDescription, classesSchedule.fullDescription) AS fullDescription
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.classesSchedule AS classesSchedule
		|		ON TT.Doc = classesSchedule.Ref
		|		LEFT JOIN Catalog.classesSchedule.translation AS classesScheduletranslation
		|		ON TT.Doc = classesScheduletranslation.Ref
		|		AND classesScheduletranslation.language = &language");
				
		gymList = New Array();
		For Each gymUid In requestStruct.gymList Do
			gymList.Add(XMLValue(Type("CatalogRef.gyms"), gymUid));	
		EndDo; 
		
		query.SetParameter("gymList", gymList);
		query.SetParameter("user", tokenContext.user);
		query.SetParameter("language", language);
		query.SetParameter("currentTime", parameters.currentTime);
		query.SetParameter("startDate", BegOfDay(XMLValue(Type("Date"), requestStruct.startDate)));
		query.SetParameter("endDate", EndOfDay(XMLValue(Type("Date"), requestStruct.endDate)));				
		
		If requestStruct.Property("employeeId") And ValueIsFilled(requestStruct.employeeId) Then
			querryTextArray.Add("AND classesSchedule.employee = &employee");
			query.SetParameter("employee", XMLValue(Type("CatalogRef.employees"), requestStruct.employeeId));	
		EndIf;		 
		If requestStruct.Property("serviceid") And ValueIsFilled(requestStruct.serviceid) Then
			querryTextArray.Add("AND classesSchedule.serviceid = &serviceid");
			query.SetParameter("serviceid", requestStruct.serviceid);	
		EndIf; 
		query.Text = StrConcat(querryTextArray, " ");
		
		select = query.Execute().Select();

		While select.Next() Do
			classesScheduleStruct = HTTP.decodeJSON(select.fullDescription, Enums.JSONValueTypes.structure);
			If tokenContext.user.IsEmpty() Then
				//@skip-warning
				classesScheduleStruct.Insert("price", Undefined);	
			EndIf;
			//@skip-warning
			classesScheduleStruct.Insert("docId", XMLString(select.doc));
			//@skip-warning
			classesScheduleStruct.Insert("date", XMLString(select.period));
			//@skip-warning
			classesScheduleStruct.Insert("recorded", select.recorded);
			//@skip-warning
			classesScheduleStruct.Insert("canRecord", select.canRecord and Not select.recorded);
			//@skip-warning
			classesScheduleStruct.Insert("canCancel", select.canCancel);
			//@skip-warning
			classesScheduleStruct.Insert("availablePlaces", select.availablePlaces);			
			classesScheduleArray.add(classesScheduleStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(classesScheduleArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure employeeInfo(parameters)

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	employeeArray = New Array();
	
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "stuff");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query("SELECT
		|	employees.Ref AS employee,
		|	ISNULL(employeestranslation.firstName, employees.firstName) AS firstName,
		|	ISNULL(employeestranslation.lastName, employees.lastName) AS lastName,
		|	employees.gender,
		|	ISNULL(employeestranslation.descriptionFull, employees.descriptionFull) AS descriptionFull,
		|	ISNULL(employeestranslation.categoryList, employees.categoryList) AS categoryList,
		|	employees.tagList,
		|	employees.photo AS photo,
		|	employees.photos.(
		|		URL)
		|FROM
		|	Catalog.employees AS employees
		|		LEFT JOIN Catalog.employees.translation AS employeestranslation
		|		ON employees.Ref = employeestranslation.Ref
		|		and employeestranslation.language = &language
		|WHERE
		|	employees.Ref = &employee");

		query.SetParameter("employee", XMLValue(Type("CatalogRef.employees"), requestStruct.uid));
		query.SetParameter("language", language);				
		
		select = query.Execute().Select();

		While select.Next() Do
			employeeStruct = New Structure();
			employeeStruct.Insert("uid", XMLString(select.employee));
			employeeStruct.Insert("firstName", select.firstName);
			employeeStruct.Insert("lastName", select.lastName);
			employeeStruct.Insert("gender", select.gender);			
			employeeStruct.Insert("isMyCoach", False);
			employeeStruct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));
			employeeStruct.Insert("tagList", HTTP.decodeJSON(select.tagList, Enums.JSONValueTypes.array));
			employeeStruct.Insert("presentation", HTTP.decodeJSON(select.descriptionFull, Enums.JSONValueTypes.array));			
			employeeStruct.Insert("photos", select.photos.Unload().UnloadColumn("URL"));						
			employeeArray.add(employeeStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(employeeArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
		
EndProcedure

Procedure employeeList(parameters)

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	employeeArray = New Array();
	
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "gym");
	EndIf;

	If errorDescription.result = "" Then
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
		|	gymsEmployees.gym = &gym
		|	AND gymsEmployees.employee.active");

		query.SetParameter("gym", XMLValue(Type("CatalogRef.gyms"), requestStruct.uid));
		query.SetParameter("language", language);				
		
		select = query.Execute().Select();

		While select.Next() Do
			employeeStruct = New Structure();
			employeeStruct.Insert("uid", XMLString(select.employee));
			employeeStruct.Insert("firstName", select.firstName);
			employeeStruct.Insert("lastName", select.lastName);
			employeeStruct.Insert("gender", select.gender);			
			employeeStruct.Insert("photo", select.photo);
			employeeStruct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));
			employeeStruct.Insert("isMyCoach", False);			
			employeeArray.add(employeeStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(employeeArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure cancellationReasonsList(parameters)

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
	parameters.Insert("notSaveAnswer", True);

EndProcedure

Procedure notificationList(parameters)

	requestStruct	= parameters.requestStruct;
	tokenContext		= parameters.tokenContext;

	array = New Array();

	registrationDate = ToUniversalTime(?(requestStruct.date = "", CurrentDate(), XMLValue(Type("Date"), requestStruct.date)));
	
	query = New Query();
	query.text	= "SELECT TOP 20
	|	messages.Ref AS message,
	|	messages.registrationDate AS registrationDate,
	|	messages.title,
	|	messages.text,
	|	messages.objectId,
	|	messages.objectType
	|INTO TT_messages
	|FROM
	|	Catalog.messages AS messages
	|WHERE
	|	messages.user = &user
	|	AND messages.registrationDate < &registrationDate
	|	AND messages.appType = &appType
	|ORDER BY
	|	registrationDate DESC
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_messages.message,
	|	TT_messages.registrationDate AS registrationDate,
	|	TT_messages.title,
	|	TT_messages.text,
	|	TT_messages.objectId,
	|	TT_messages.objectType,
	|	MAX(CASE
	|		WHEN messagesLogsSliceLast.messageStatus = VALUE(Enum.messageStatuses.read)
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS read
	|FROM
	|	TT_messages AS TT_messages
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast AS messagesLogsSliceLast
	|		ON TT_messages.message = messagesLogsSliceLast.message
	|GROUP BY
	|	TT_messages.message,
	|	TT_messages.registrationDate,
	|	TT_messages.title,
	|	TT_messages.text,
	|	TT_messages.objectId,
	|	TT_messages.objectType
	|ORDER BY
	|	registrationDate DESC";

	query.SetParameter("registrationDate", registrationDate);
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);

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

Procedure readNotification(parameters)

	requestStruct	= parameters.requestStruct;
	tokenContext		= parameters.tokenContext;
	
	struct = New Structure();

	If Not requestStruct.Property("noteId") or requestStruct.noteId = "" Then
		message = Catalogs.messages.EmptyRef();
	Else
		message = XMLValue(Type("CatalogRef.messages"), requestStruct.noteId);
	EndIf;

	If tokenContext.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf tokenContext.appType = Enums.appTypes.Customer Then
		informationChannel = Enums.informationChannels.pushCustomer;
	Else
		informationChannel = Enums.informationChannels.EmptyRef();
	EndIf;

	query = New Query();
	query.text = "SELECT
	|	messages.Ref AS message
	|FROM
	|	Catalog.messages AS messages
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
	|		ON messages.Ref = messagesLogsSliceLast.message
	|WHERE
	|	ISNULL(messagesLogsSliceLast.messageStatus, VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
	|	AND Messages.user = &user
	|	AND Messages.appType = &appType";

	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);

	queryResult = query.Execute();
	If Not queryResult.IsEmpty() Then
		select = queryResult.Select();
		unReadMessagesCount = select.Count();		
		If message.IsEmpty() Then
			While select.Next() Do
				record = InformationRegisters.messagesLogs.CreateRecordManager();
				record.period				= ToUniversalTime(CurrentDate());
				record.message				= select.message;
				record.token				= tokenContext.token;
				record.recordDate			= record.period;
				record.messageStatus		= Enums.messageStatuses.read;
				record.informationChannel	= informationChannel;
				record.Write();
			EndDo;;
			unReadMessagesCount = 0;
		Else
			If select.FindNext(New Structure("message", message)) Then
				record = InformationRegisters.messagesLogs.CreateRecordManager();
				record.period				= ToUniversalTime(CurrentDate());
				record.message 				= message;
				record.token 				= tokenContext.token;
				record.recordDate 			= record.period;
				record.messageStatus 		= Enums.messageStatuses.read;
				record.informationChannel	= informationChannel;
				record.Write();
				unReadMessagesCount 		= unReadMessagesCount - 1;
			EndIf;
		EndIf;
	Else
		unReadMessagesCount = 0;
	EndIf;

	struct.Insert("result", "Ok");
	struct.Insert("quantity", unReadMessagesCount);
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure unReadNotificationCount(parameters)

	tokenContext = parameters.tokenContext;
	struct = New Structure();

	query = New Query();
	query.text = "SELECT
	|	COUNT(messages.Ref) AS count
	|FROM
	|	Catalog.messages AS messages
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
	|		ON messages.Ref = messagesLogsSliceLast.message
	|WHERE
	|	ISNULL(messagesLogsSliceLast.messageStatus, VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
	|	AND Messages.user = &user
	|	AND Messages.appType = &appType";

	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);

	select = query.Execute().Select();
	select.Next();
	struct.Insert("quantity", select.count);

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure executeExternalRequest(parameters)
	
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	errorDescription = Service.getErrorDescription(language);
	answerBody = "";

	query = New Query();
	query.text = "SELECT
	|	matchingRequestsInformationSources.performBackground AS performBackground,
	|	matchingRequestsInformationSources.requestReceiver AS requestReceiver,
	|	matchingRequestsInformationSources.HTTPRequestType AS HTTPRequestType,
	|	matchingRequestsInformationSources.Attribute AS Attribute,
	|	matchingRequestsInformationSources.staffOnly AS staffOnly,
	|	matchingRequestsInformationSources.notSaveAnswer AS notSaveAnswer,
	|	matchingRequestsInformationSources.compressAnswer AS compressAnswer,
	|	matchingRequestsInformationSources.mockServerMode AS mockServerMode,
	|	holdingsConnectionsInformationSources.URL AS URL,
	|	holdingsConnectionsInformationSources.server AS server,
	|	CASE
	|		WHEN holdingsConnectionsInformationSources.port = 0
	|			THEN UNDEFINED
	|		ELSE holdingsConnectionsInformationSources.port
	|	END AS port,
	|	holdingsConnectionsInformationSources.user AS user,
	|	holdingsConnectionsInformationSources.password AS password,
	|	holdingsConnectionsInformationSources.timeout AS timeout,
	|	holdingsConnectionsInformationSources.secureConnection AS secureConnection,
	|	holdingsConnectionsInformationSources.UseOSAuthentication AS UseOSAuthentication,
	|	CASE
	|		WHEN matchingRequestsInformationSources.mockServerMode
	|			THEN matchingRequestsInformationSources.Ref.defaultResponse
	|		ELSE """"
	|	END AS defaultResponse
	|FROM
	|	InformationRegister.holdingsConnectionsInformationSources AS holdingsConnectionsInformationSources
	|		LEFT JOIN Catalog.matchingRequestsInformationSources.informationSources AS matchingRequestsInformationSources
	|		ON holdingsConnectionsInformationSources.informationSource = matchingRequestsInformationSources.informationSource
	|		AND (matchingRequestsInformationSources.requestSource = &requestName)
	|		AND (NOT matchingRequestsInformationSources.notUse)
	|WHERE
	|	holdingsConnectionsInformationSources.holding = &holding
	|	AND
	|	NOT matchingRequestsInformationSources.requestReceiver IS NULL
	|	AND holdingsConnectionsInformationSources.language = &language";

	query.SetParameter("holding", tokenContext.holding);
	query.SetParameter("language", language);
	query.SetParameter("requestName", parameters.requestName);
	queryResult = query.Execute();

	If queryResult.IsEmpty() Then
		errorDescription	= Service.getErrorDescription(language, "noUrl");
	Else		
		select = queryResult.Select();
		select.Next();
		parameters.Insert("notSaveAnswer", select.notSaveAnswer);
		parameters.Insert("compressAnswer", select.compressAnswer);
		If select.staffOnly
				And tokenContext.userType <> "employee" Then
			errorDescription = Service.getErrorDescription(language, "staffOnly");
		Else
			If select.mockServerMode Then
				answerBody = select.defaultResponse;	
			Else
				performBackground = select.performBackground;
				arrayBJ = New Array();
				statusCode = 200;
				If select.HTTPRequestType = Enums.HTTPRequestTypes.GET Then
					requestBody = "";
					parametersFromURL = StrReplace(parameters.URL, GeneralReuse.getBaseURL(), "");
				Else
					requestBody = HTTP.PrepareRequestBody(parameters);
					parametersFromURL = "";
				EndIf;
				select.Reset();
				While select.Next() Do
					connectStruct = New Structure();
					connectStruct.Insert("server", select.server);
					connectStruct.Insert("port", select.port);
					connectStruct.Insert("account", select.user);
					connectStruct.Insert("password", select.password);
					connectStruct.Insert("timeout", select.timeout);
					connectStruct.Insert("secureConnection", select.secureConnection);
					connectStruct.Insert("UseOSAuthentication", select.UseOSAuthentication);
					connectStruct.Insert("URL", select.URL);
					connectStruct.Insert("requestReceiver", select.requestReceiver);
					connectStruct.Insert("HTTPRequestType", select.HTTPRequestType);
					connectStruct.Insert("parametersFromURL", parametersFromURL);
					If performBackground Then
						response = Service.runRequestBackground(connectStruct, requestBody);
						BJStruct = New Structure();
						BJStruct.Insert("address", response.address);
						BJStruct.Insert("BJ", response.BJ);
						BJStruct.Insert("attribute", select.attribute);
						arrayBJ.Add(BJStruct);
					Else
						response = Service.runRequest(connectStruct, requestBody);
						statusCode = response.statusCode;
						answerBody = response.GetBodyAsString();
					EndIf;
				EndDo;
				If performBackground Then
					response = Service.checkBackgroundJobs(arrayBJ);
					statusCode = response.statusCode;
					answerBody = response.answerBody;
				EndIf;
				If statusCode <> 200 Then
					If statusCode = 403 Then
						HTTPResponseStruct = HTTP.decodeJSON(answerBody);
						If HTTPResponseStruct.Property("result") Then
							errorDescription = Service.getErrorDescription(language, HTTPResponseStruct.result, HTTPResponseStruct.description);
						EndIf;
					Else
						errorDescription = Service.getErrorDescription(language, "system", answerBody);
					EndIf;
				EndIf;
			EndIf;
		EndIf;		
	EndIf;

	parameters.Insert("answerBody", answerBody);
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure changeCreateItems(parameters)
	tokenContext = parameters.tokenContext;
	struct	= New Structure();
	struct.Insert("result", "Ok");		
	DataLoad.createItems(parameters.requestName, tokenContext.holding, parameters.requestStruct);	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
EndProcedure

Procedure sendMessage(parameters)
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	struct = New Structure();
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("messages") Then
		errorDescription = Service.getErrorDescription(language, "noMessages");
	Else
		For Each message In requestStruct.messages Do
			messageStruct = New Structure();
			messageStruct.Insert("objectId", ?(message.Property("objectId"), message.objectId, ""));
			messageStruct.Insert("objectType", ?(message.Property("objectType"), message.objectType, ""));
			messageStruct.Insert("phone", ?(message.Property("phone"), message.phone, ""));
			messageStruct.Insert("title", ?(message.Property("title"), message.title, ?(language = "ru", "Уведомление", "Notification")));
			messageStruct.Insert("text", ?(message.Property("text"), message.text, ""));
			messageStruct.Insert("action", ?(message.Property("action"), message.action, "ViewNotification"));
			messageStruct.Insert("priority", ?(message.Property("priority"), message.priority, 5));
			messageStruct.Insert("holding", tokenContext.holding);
			If message.Property("gymId") And message.gymId <> "" Then
				messageStruct.Insert("gym", XMLValue(Type("CatalogRef.gyms"), message.gymId));
			Else
				messageStruct.Insert("gym", Catalogs.gyms.EmptyRef());
			EndIf;
			If message.Property("uid") And message.uid <> "" Then
				messageStruct.Insert("user", XMLValue(Type("CatalogRef.users"), message.uid));
			Else
				messageStruct.Insert("user", Catalogs.users.EmptyRef());
			EndIf;
			If message.Property("token") And message.token <> "" Then
				messageStruct.Insert("token", XMLValue(Type("CatalogRef.tokens"), message.token));
			Else
				messageStruct.Insert("token", Catalogs.tokens.EmptyRef());
			EndIf;
			If message.Property("appType") And message.appType <> "" Then
				messageStruct.Insert("appType", Enums.appTypes[message.appType]);
			Else
				messageStruct.Insert("appType", Enums.appTypes.EmptyRef());
			EndIf;
			channelsArray = New Array();
			If message.Property("routes") Then
				For Each channel In message.routes Do
					channelsArray.Add(Enums.informationChannels[channel]);
				EndDo;
			EndIf;
			messageStruct.Insert("informationChannels", channelsArray);
			If messageStruct.phone = ""
					And messageStruct.user.GetObject() = Undefined Then
			ElsIf messageStruct.user = messageStruct.token.user Then
			Else
				Messages.newMessage(messageStruct);
			EndIf;
		EndDo;
	EndIf;

	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure imagePOST(parameters)
	
	requestBody = parameters.requestBody;
	tokenContext = parameters.tokenContext;
	headers = parameters.headers;
	language = parameters.language;
	
	struct = New Structure();
	errorDescription = Service.getErrorDescription(language);

	If TypeOf(requestBody) <> Type("BinaryData") Then
		errorDescription = Service.getErrorDescription(language, "noBinaryData");
	Else
		pathStruct = Files.getPath(headers["objectName"], tokenContext.holding.code);
		fileName = Files.pathConcat("" + New UUID(), headers["extension"]);
		requestBody.write(Files.pathConcat(pathStruct.location, fileName, "\"));		
		struct.Insert("result", Files.pathConcat(pathStruct.URL, fileName, "/"));
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure imageDELETE(parameters)
	
	requestStruct = parameters.requestStruct;
	struct = New Structure();	

	location = StrReplace(StrReplace(requestStruct.url, Files.getBaseImgURL(), Files.getImgStoragePath()),"/","\");		
	imgFile = New File(location);
	If imgFile.Exist() Then
		DeleteFiles(location);	
	EndIf;
	
	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	
EndProcedure

Procedure paymentPreparation(parameters)
		
	tokenContext = parameters.tokenContext;
		
	parametersNew = Service.getStructCopy(parameters);		
	General.executeRequestMethod(parametersNew);
	If parametersNew.errorDescription.result = "" Then
		struct = HTTP.decodeJSON(parametersNew.answerBody);		
		answer = Acquiring.newHoldingOrder(New Structure("user,holding,amount,orders", tokenContext.user, tokenContext.holding, struct.amount, struct.orders));
		//@skip-warning
		struct.Insert("uid", XMLString(answer.order));
	Else
		struct = New Structure();		
	EndIf;
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	parameters.Insert("errorDescription", parametersNew.errorDescription);
		
EndProcedure

Procedure payment(parameters)
		
	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;	 
	struct = New Structure();	
	
	orderStruct = New Structure();
	orderStruct.Insert("amount", requestStruct.amount);
	orderStruct.Insert("user", tokenContext.user);
	orderStruct.Insert("holding", tokenContext.holding);
	
	orderStruct.Insert("acquiringRequest", ?(requestStruct.Property("acquiringRequest"), Enums.acquiringRequests[requestStruct.acquiringRequest], Enums.acquiringRequests.register));
	orderStruct.Insert("acquiringProvider", ?(requestStruct.Property("acquiringProvider"), Enums.acquiringProviders[requestStruct.acquiringProvider], Enums.acquiringProviders.EmptyRef()));
	orderStruct.Insert("bindingId", ?(requestStruct.Property("bindingId"), requestStruct.bindingId, ""));
	
	Acquiring.newHoldingOrder(orderStruct);	
	
	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	
EndProcedure

Procedure paymentStatus(parameters)
	
	requestStruct = parameters.requestStruct;	
	language = parameters.language;
	struct = New Structure();
	
	query = New Query("SELECT
	|	acquiringOrderIdentifiers.Owner AS order
	|FROM
	|	Catalog.acquiringOrderIdentifiers AS acquiringOrderIdentifiers
	|WHERE
	|	acquiringOrderIdentifiers.Ref = &orderIdentifier");
	
	query.SetParameter("orderIdentifier", Catalogs.acquiringOrderIdentifiers.GetRef(New UUID(requestStruct.orderId)));
	
	result = query.Execute();
	
	If result.IsEmpty() Then
		errorDescription = Service.getErrorDescription(language, "acquiringConnection");
	Else
		select = result.Select();
		select.Next();
		answer = Acquiring.checkHoldingOrder(select.order);	
	EndIf;
	
	
	
//	If answer = Undefined Then
//		errorDescription = Service.getErrorDescription(language, "acquiringConnection");		
//	Else
//		struct.Insert("orderId", answer.orderId);
//		struct.Insert("formUrl", answer.formUrl);
//		struct.Insert("returnUrl", answer.returnUrl);
//		struct.Insert("failUrl", answer.failUrl);
//		errorDescription = Service.getErrorDescription(language, answer.errorCode);;
//	EndIf;
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
			
EndProcedure

Procedure bindCard(parameters)
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	struct = New Structure();
	
	orderStruct = New Structure();
	orderStruct.Insert("acquiringAmount", 1);
	orderStruct.Insert("user", tokenContext.user);
	orderStruct.Insert("holding", tokenContext.holding);	
	
	orderStruct.Insert("acquiringRequest", Enums.acquiringRequests.binding);	
	orderStruct.Insert("acquiringProvider", ?(requestStruct.Property("acquiringProvider"), Enums.acquiringProviders[requestStruct.acquiringProvider], Enums.acquiringProviders.EmptyRef()));
	
	answer = Acquiring.newHoldingOrder(orderStruct, True);
	If answer = Undefined Then
		errorDescription = Service.getErrorDescription(language, "acquiringConnection");		
	Else
		struct.Insert("orderId", answer.orderId);
		struct.Insert("formUrl", answer.formUrl);
		struct.Insert("returnUrl", answer.returnUrl);
		struct.Insert("failUrl", answer.failUrl);
		errorDescription = Service.getErrorDescription(language, answer.errorCode);;
	EndIf;
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
			
EndProcedure
