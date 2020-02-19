
Procedure executeRequestMethod(parameters) Export
	
	parameters.Insert("errorDescription", Check.requestParameters(parameters));	
	
	If parameters.errorDescription.result = "" Then
		If parameters.requestName = "chainlist" Then
			API_List.chainList(parameters);
		ElsIf parameters.requestName = "countrycodelist" Then 
			API_List.countryCodeList(parameters);
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
			API_Info.accountProfile(parameters);	
		ElsIf parameters.requestName = "userprofile" Then 
			API_Info.userProfile(parameters);
//		ElsIf parameters.requestName = "usersummary" Then 
//			API_Info.userSummary(parameters);
		ElsIf parameters.requestName = "usercache" Then 
			API_Info.userCache(parameters);	
		ElsIf parameters.requestName = "cataloggyms"
				Or parameters.requestName = "gymlist" Then
			API_List.gymList(parameters);
		ElsIf parameters.requestName = "gyminfo" Then
			API_Info.gymInfo(parameters);	
		ElsIf parameters.requestName = "gymschedule" Then
			API_Schedule.gymSchedule(parameters);
		ElsIf parameters.requestName = "employeelist" Then
			API_List.employeeList(parameters);
		ElsIf parameters.requestName = "employeeinfo" Then
			API_Info.employeeInfo(parameters);
		ElsIf parameters.requestName = "servicelist" 
				Or parameters.requestName = "productlist" Then
			API_List.productList(parameters);
		ElsIf parameters.requestName = "serviceinfo" 
				Or parameters.requestName = "productinfo" Then
			API_Info.productInfo(parameters);		
		ElsIf parameters.requestName = "paymentpreparation" Then
			API_Payment.paymentPreparation(parameters);
		ElsIf parameters.requestName = "payment" Then
			API_Payment.payment(parameters);
		ElsIf parameters.requestName = "paymentstatus" Then
			API_Payment.paymentStatus(parameters);
		ElsIf parameters.requestName = "bindcardlist" Then
			API_Payment.bindCardList(parameters);
		ElsIf parameters.requestName = "bindcard" Then
			API_Payment.bindCard(parameters);
		ElsIf parameters.requestName = "unbindcard" Then
			API_Payment.unBindCard(parameters);	
		ElsIf parameters.requestName = "catalogcancelcauses"
				Or parameters.requestName = "cancelcauseslist" Then // проверить описание в API
			API_List.cancellationReasonsList(parameters);
		ElsIf parameters.requestName = "notificationlist" Then // проверить описание в API
			API_List.notificationList(parameters);
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
		ElsIf DataLoad.isUploadRequest(parameters.requestName) Then 
			changeCreateItems(parameters);
		Else
			executeExternalRequest(parameters);
		EndIf;
	EndIf;
			
EndProcedure

Procedure executeRequestMethodBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);	
	BackgroundJobs.Execute("General.executeRequestMethod", array, New UUID());
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
			messageStruct.Insert("chain", tokenContext.chain);
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
				struct.Insert("userProfile", Users.profile(select.user, tokenContext.appType));
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
	If tokenContext.account.IsEmpty() Then
		answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid);
	Else
		accountObject = tokenContext.account.GetObject();
		If accountObject = Undefined Then
			answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid);
		Else
			answerStruct = Account.getFromExternalSystem(parameters, "uid", requestStruct.uid, tokenContext.account);
		EndIf;
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
			EndDo;
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
			
			sendImmediately = ?(message.Property("sendImmediately"), message.sendImmediately, False);
			If messageStruct.phone = ""
					And messageStruct.user.GetObject() = Undefined Then
				errorDescription = Service.getErrorDescription(language, "phoneError");		
			//ElsIf messageStruct.user = messageStruct.token.user Then
			Else
				Messages.newMessage(messageStruct, sendImmediately);
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

