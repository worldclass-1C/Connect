
Procedure executeRequestMethod(parameters) Export
	
	parameters.Insert("errorDescription", Check.requestParameters(parameters));	
	
	If parameters.errorDescription.result = "" Then
		If parameters.requestName = "chainlist" Then
			getChainList(parameters);
		ElsIf parameters.requestName = "countrycodelist" Then 
			getCountryCodeList(parameters);
		ElsIf parameters.requestName = "config" Then
			getConfig(parameters);
		ElsIf parameters.requestName = "signin" Then
			accountSignIn(parameters);
		ElsIf parameters.requestName = "confirmphone" Then
			accountConfirmPhone(parameters);
		ElsIf parameters.requestName = "addusertotoken" Then 
			addUserToToken(parameters);
		ElsIf parameters.requestName = "registerdevice" Then 
			registerDevice(parameters);
		ElsIf parameters.requestName = "signout" Then 
			signOut(parameters);
		ElsIf parameters.requestName = "accountprofile" Then 
			getAccountProfile(parameters);	
		ElsIf parameters.requestName = "userprofile" Then 
			getUserProfile(parameters);
		ElsIf parameters.requestName = "cataloggyms"
				Or parameters.requestName = "gymlist" Then // проверить описание в API
			getGymList(parameters);
		ElsIf parameters.requestName = "catalogcancelcauses"
				Or parameters.requestName = "cancelcauseslist" Then // проверить описание в API
			getCancellationReasonsList(parameters);
		ElsIf parameters.requestName = "notificationlist" Then // проверить описание в API
			getNotificationList(parameters);
		ElsIf parameters.requestName = "readnotification" Then // проверить описание в API
			readNotification(parameters);
		ElsIf parameters.requestName = "unreadnotificationcount" Then // проверить описание в API
			unReadNotificationCount(parameters);
		ElsIf parameters.requestName = "sendMessage" Then 
			sendMessage(parameters);	
		ElsIf parameters.requestName = "addchangeusers"
				Or parameters.requestName = "addgyms"
				Or parameters.requestName = "addrequest"
				Or parameters.requestName = "addcancelcauses"
				Or parameters.requestName = "addcities" Then // проверить описание в API
			changeCreateCatalogItems(parameters);
		Else
			executeExternalRequest(parameters);
		EndIf;
	EndIf;
			
EndProcedure

Procedure getConfig(parameters)

	tokenСontext = parameters.tokenСontext;
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
	|	tokens.lockDate
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.Ref = &token";

	query.SetParameter("brand", Enums.brandTypes[brand]);
	query.SetParameter("appType", Enums.appTypes[requestStruct.appType]);
	query.SetParameter("systemType", Enums.systemTypes[requestStruct.systemType]);
	query.SetParameter("token", tokenСontext.token);

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
			//tokenStruct.Insert("userStatus", selection.userStatus);
			struct.Insert("tokenInfo", tokenStruct);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure getChainList(parameters)

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
	|	chain.phoneMask.Description AS phoneMaskDescription
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

	selection = query.Execute().Select();

	While selection.Next() Do
		chainStruct = New Structure();
		chainStruct.Insert("brand", selection.brand);
		chainStruct.Insert("code", selection.code);
		chainStruct.Insert("loyaltyProgram", selection.loyaltyProgram);
		chainStruct.Insert("currencySymbol", selection.currencySymbol);
		chainName = ?(nameTogetherChain, selection.brand + " "
			+ selection.description, selection.description);
		chainStruct.Insert("name", chainName);
		chainStruct.Insert("countryCode", New Structure("code, mask", selection.phoneMaskCountryCode, selection.phoneMaskDescription));

		array.add(chainStruct);
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(array));
	parameters.Insert("notSaveAnswer", True);

EndProcedure

Procedure getCountryCodeList(parameters)
	
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
	
	tokenСontext = parameters.tokenСontext;
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
		struct.Insert("token", XMLString(Token.get(tokenСontext.token, tokenStruct)) + "0");
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Procedure accountSignIn(parameters)

	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	errorDescription = parameters.errorDescription;

	struct = New Structure();

	retryTime = Check.timeBeforeSendSms(tokenСontext.token);
	If retryTime > 0 and requestStruct.phone <> "+79154006161"
			and requestStruct.phone <> "+79684007188"
			and requestStruct.phone <> "+79035922412"
			and requestStruct.phone <> "+79037478789" Then
		struct.Insert("result", "Fail");
		struct.Insert("retryTime", retryTime);
	Else
		chain = Catalogs.chains.FindByCode(requestStruct.chainCode);
		If ValueIsFilled(chain) Then
			If tokenСontext.chain <> chain Then				
				changeStruct = New Structure("chain", chain);
				Token.editProperty(tokenСontext.token, changeStruct);
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
			messageStruct = New Структура;
			messageStruct.Insert("phone", requestStruct.phone);
			messageStruct.Insert("title", "SMS code");
			messageStruct.Insert("text", StrConcat(rowsArray));
			messageStruct.Insert("holding", tokenСontext.holding);
			messageStruct.Insert("informationChannels", informationChannels);
			messageStruct.Insert("priority", 0);
			Messages.newMessage(messageStruct, True);
			Account.incPasswordSendCount(tokenСontext.token, requestStruct.phone, tempCode);
			struct.Insert("result", "Ok");
			struct.Insert("retryTime", 60);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure accountConfirmPhone(parameters)

	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	
	struct = New Structure();
	
	answer = Check.password(tokenСontext.token, requestStruct.password, language);
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

		queryUser.SetParameter("holding", tokenСontext.holding);
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
				Token.editProperty(tokenСontext.token, changeStruct);
				struct.Insert("userProfile", Account.profile(select.account));
				struct.Insert("userList", New Array());
				struct.Insert("token", XMLString(tokenСontext.token));				
			Else	
				answerStruct = Account.getFromExternalSystem(parameters, "phone", answer.phone, select.account);
				struct = answerStruct.response;
				errorDescription = answerStruct.errorDescription;
			EndIf;		
		EndIf;
		If errorDescription.result = "" Then
			Account.delPassword(tokenСontext.token);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure addUserToToken(parameters)
	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	If tokenСontext.account.IsEmpty() Then
		answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid);
	Else
		answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid, tokenСontext.account);
	EndIf;
	answerStruct.response.Delete("userList");
	parameters.Insert("answerBody", HTTP.encodeJSON(answerStruct.response.userProfile));
	parameters.Insert("errorDescription", answerStruct.errorDescription);
EndProcedure

Procedure signOut(parameters)
	tokenСontext = parameters.tokenСontext;
	changeStruct = New Structure("account, user", Catalogs.accounts.EmptyRef(), Catalogs.users.EmptyRef());
	Token.editProperty(tokenСontext.token, changeStruct);
	parameters.Insert("answerBody", HTTP.encodeJSON(New Structure("token", XMLString(tokenСontext.token) + "0")));	
EndProcedure

Procedure getAccountProfile(parameters)
	parameters.Insert("answerBody", HTTP.encodeJSON(Account.profile(parameters.tokenСontext.account)));		
EndProcedure

Procedure getUserProfile(parameters)
	parameters.Insert("answerBody", HTTP.encodeJSON(Users.profile(parameters.tokenСontext.user, parameters.tokenСontext.appType)));	
EndProcedure

Procedure getGymList(parameters)

	requestStruct	= parameters.requestStruct;
	language		= parameters.language;
	gymArray 		= New Array();
	
	errorDescription = Service.getErrorDescription();
	
	If Not requestStruct.Property("chain") Then
		errorDescription = Service.getErrorDescription(language, "noChain");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query();
		query.Text = "SELECT
		|	gyms.Ref,
		|	gyms.Description,
		|	gyms.address,
		|	gyms.city,
		|	gyms.latitude,
		|	gyms.longitude,
		|	gyms.registrationDate,
		|	gyms.segment,
		|	gyms.chain,
		|	gyms.type,
		|	gyms.holding,
		|	gyms.departmentWorkSchedule.(
		|		department,
		|		phone,
		|		weekdaysTime,
		|		holidaysTime),
		|	gyms.nearestMetro.(
		|		metro.description AS description,
		|		metro.lineColor AS lineColor,
		|		metro.lineName AS lineName,
		|		metro.lineNumber AS lineNumber)
		|FROM
		|	Catalog.gyms AS gyms
		|WHERE
		|	gyms.chain.code = &chainCode
		|	AND
		|	NOT gyms.DeletionMark";

		query.SetParameter("chainCode", requestStruct.chain);
		select = query.Execute().Select();

		While select.Next() Do
			gymStruct = New Structure();
			gymStruct.Insert("gymId", XMLString(select.Ref));
			gymStruct.Insert("name", select.Description);
			gymStruct.Insert("type", select.type);
			gymStruct.Insert("cityId", XMLString(select.city));
			gymStruct.Insert("gymAddress", select.address);
			gymStruct.Insert("divisionTitle", select.segment);

			coords = New Structure();
			coords.Insert("latitude", select.latitude);
			coords.Insert("longitude", select.longitude);
			gymStruct.Вставить("coords", coords);

			scheduledArray = New Array();
			For Each department In select.departmentWorkSchedule.Unload() Do
				schedule = New Structure();
				schedule.Insert("name", department.department);
				schedule.Insert("phone", department.phone);
				schedule.Insert("weekdaysTime", department.weekdaysTime);
				schedule.Insert("holidaysTime", department.holidaysTime);
				scheduledArray.add(schedule);
			EndDo;
			
			metroArray = New Array();
			For Each metro In select.nearestMetro.Unload() Do
				station = New Structure();
				station.Insert("name", metro.description);
				station.Insert("lineColor", metro.lineColor);
				station.Insert("lineName", metro.lineName);
				station.Insert("lineNumber", metro.lineNumber);
				metroArray.add(station);
			EndDo;
			
			gymStruct.Insert("departments", scheduledArray);
			gymStruct.Insert("metro", metroArray);
			gymArray.add(gymStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure getCancellationReasonsList(parameters)

	tokenСontext		= parameters.tokenСontext;
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

	query.SetParameter("holding", tokenСontext.holding);
	selection = query.Execute().Select();
	While selection.Next() Do
		struct = New Structure("uid,name", XMLString(selection.ref), selection.description);
		array.add(struct);
	EndDo;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(array));
	parameters.Insert("notSaveAnswer", True);

EndProcedure

Procedure getNotificationList(parameters)

	requestStruct	= parameters.requestStruct;
	tokenСontext		= parameters.tokenСontext;

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
	query.SetParameter("user", tokenСontext.user);
	query.SetParameter("appType", tokenСontext.appType);

	select = query.Execute().Select();
	While select.Next() Do
		messageStruct = New Structure();
		messageStruct.Insert("noteId", XMLString(select.message));
		messageStruct.Insert("date", XMLString(ToLocalTime(select.registrationDate, tokenСontext.timeZone)));
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
	tokenСontext		= parameters.tokenСontext;
	
	struct = New Structure();

	If Not requestStruct.Property("noteId") or requestStruct.noteId = "" Then
		message = Catalogs.messages.EmptyRef();
	Else
		message = XMLValue(Type("CatalogRef.messages"), requestStruct.noteId);
	EndIf;

	If tokenСontext.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf tokenСontext.appType = Enums.appTypes.Customer Then
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

	query.SetParameter("user", tokenСontext.user);
	query.SetParameter("appType", tokenСontext.appType);

	queryResult = query.Execute();
	If Not queryResult.IsEmpty() Then
		select = queryResult.Select();
		unReadMessagesCount = select.Count();		
		If message.IsEmpty() Then
			While select.Next() Do
				record = InformationRegisters.messagesLogs.CreateRecordManager();
				record.period				= ToUniversalTime(CurrentDate());
				record.message				= select.message;
				record.token				= tokenСontext.token;
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
				record.token 				= tokenСontext.token;
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

	struct.Вставить("result", "Ok");
	struct.Вставить("quantity", unReadMessagesCount);
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure unReadNotificationCount(parameters)

	tokenСontext = parameters.tokenСontext;
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

	query.SetParameter("user", tokenСontext.user);
	query.SetParameter("appType", tokenСontext.appType);

	select = query.Execute().Select();
	select.Next();
	struct.Insert("quantity", select.count);

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure executeExternalRequest(parameters)
	
	tokenСontext = parameters.tokenСontext;
	language = parameters.language;
	errorDescription = Service.getErrorDescription();
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
	|	holdingsConnectionsInformationSources.UseOSAuthentication AS UseOSAuthentication
	|FROM
	|	InformationRegister.holdingsConnectionsInformationSources AS holdingsConnectionsInformationSources
	|		LEFT JOIN Catalog.matchingRequestsInformationSources.informationSources AS matchingRequestsInformationSources
	|		ON holdingsConnectionsInformationSources.informationSource = matchingRequestsInformationSources.informationSource
	|		AND (matchingRequestsInformationSources.requestSource = &requestName)
	|		AND (NOT matchingRequestsInformationSources.notUse)
	|WHERE
	|	holdingsConnectionsInformationSources.holding = &holding
	|	AND
	|	NOT matchingRequestsInformationSources.requestReceiver IS NULL";

	query.SetParameter("holding", tokenСontext.holding);
	query.SetParameter("requestName", parameters.requestName);
	queryResult = query.Execute();

	If queryResult.IsEmpty() Then
		errorDescription	= Service.getErrorDescription(language, "noUrl");
	Else		
		selection = queryResult.Select();
		selection.Next();
		parameters.Insert("notSaveAnswer", selection.notSaveAnswer);
		parameters.Insert("compressAnswer", selection.compressAnswer);
		If selection.staffOnly
				And tokenСontext.userType <> "employee" Then
			errorDescription = Service.getErrorDescription(language, "staffOnly");
		Else
			performBackground = selection.performBackground;
			arrayBJ = New Array(); 
			statusCode = 200;
			If selection.HTTPRequestType = Enums.HTTPRequestTypes.GET Then
				requestBody = "";
				parametersFromURL = StrReplace(parameters.URL, GeneralReuse.getBaseURL(), "");
			Else
				requestBody = HTTP.PrepareRequestBody(parameters);
				parametersFromURL = "";
			EndIf;
			selection.Reset();
			While selection.Next() Do
				connectStruct = New Structure();
				connectStruct.Insert("server", selection.server);
				connectStruct.Insert("port", selection.port);
				connectStruct.Insert("account", selection.user);
				connectStruct.Insert("password", selection.password);
				connectStruct.Insert("timeout", selection.timeout);
				connectStruct.Insert("secureConnection", selection.secureConnection);
				connectStruct.Insert("UseOSAuthentication", selection.UseOSAuthentication);
				connectStruct.Insert("URL", selection.URL);
				connectStruct.Insert("requestReceiver", selection.requestReceiver);
				connectStruct.Insert("HTTPRequestType", selection.HTTPRequestType);
				connectStruct.Insert("parametersFromURL", parametersFromURL);		
				If performBackground Then
					response = Service.runRequestBackground(connectStruct, requestBody);
					BJStruct = New Structure();
					BJStruct.Insert("address", response.address);
					BJStruct.Insert("BJ", response.BJ);
					BJStruct.Insert("attribute", selection.attribute);
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

	parameters.Insert("answerBody", answerBody);
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure changeCreateCatalogItems(parameters)
	struct	= New Structure();
	struct.Insert("result", "Ok");		
//	Service.createCatalogItems(parameters);	
//	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
EndProcedure

Procedure sendMessage(parameters)
	
	requestStruct = parameters.requestStruct;
	tokenСontext = parameters.tokenСontext;
	language = parameters.language;
	struct = New Structure();
	errorDescription = Service.getErrorDescription();

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
			messageStruct.Insert("holding", tokenСontext.holding);
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

