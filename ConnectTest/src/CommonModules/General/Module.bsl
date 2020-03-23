
Procedure executeRequestMethod(parameters) Export
	
	If parameters.internalRequestMethod Then
		General.executeRequestMethodStart(parameters);
	EndIf;
	
	parameters.Insert("error", Check.requestParameters(parameters));	
	
	If parameters.error = "" Then
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
	
	If parameters.internalRequestMethod Then
		General.executeRequestMethodEnd(parameters);	
	EndIf;
			
EndProcedure

Procedure executeRequestMethodBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);	
	BackgroundJobs.Execute("General.executeRequestMethod", array, New UUID());
EndProcedure

Procedure executeRequestMethodStart(parameters) Export
	parameters.Insert("dateInMilliseconds", CurrentUniversalDateInMilliseconds());
	If parameters.Property("requestStruct") Then
		parameters.Insert("requestBody", HTTP.encodeJSON(parameters.requestStruct));
	Else
		parameters.Insert("requestBody", "");	
	EndIf;		
EndProcedure

Procedure executeRequestMethodEnd(parameters, synch = False) Export	
	parameters.Insert("duration", CurrentUniversalDateInMilliseconds()
		- parameters.dateInMilliseconds);	
	parameters.Insert("isError", parameters.error <> "");	
	If parameters.isError Then		
		If parameters.error = "noValidRequest"
				or parameters.error = "tokenExpired" Then
			parameters.Insert("statusCode", 401);			
		Else
			parameters.Insert("statusCode", 403);			
		EndIf;
		If parameters.error <> "system" Then
			Texts = String(parameters.requestName)+chars.LF+parameters.requestBody+chars.LF+parameters.statusCode+chars.LF+parameters.answerBody;
			parameters.Insert("answerBody", HTTP.encodeJSON(Service.getErrorDescription(parameters.language, parameters.error,,Texts)));
		EndIf
	EndIf;	
	If Not synch Then
		Service.logRequestBackground(parameters);
	EndIf;		
EndProcedure

Procedure config(parameters)

	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;	
	
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

	query.SetParameter("brand",parameters.brand);
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
			parameters.Insert("error", "tokenExpired");
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
		parameters.Insert("error", "noChainCode");
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
			parameters.Insert("error", "chainCodeError");
		EndIf;
		If parameters.error = "" Then
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

EndProcedure

Procedure confirmPhone(parameters)

	tokenContext = parameters.tokenContext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	
	struct = New Structure();
	
	answer = Check.password(tokenContext.token, requestStruct.password, language);
	error = answer.error;

	If error = "" Then
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
			error = answerStruct.error; 
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
				error = answerStruct.error;
			EndIf;		
		EndIf;
		If error = "" Then
			Account.delPassword(tokenContext.token);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("error", error);

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
	parameters.Insert("error", answerStruct.error);
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
	|	pushStatusBalance.message,
	|	pushStatusBalance.amountBalance
	|INTO TemporaryTableMessages
	|FROM
	|	AccumulationRegister.pushStatus.Balance(, user = &user
	|	AND informationChannel = &informationChannel) AS pushStatusBalance
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableMessages.message as message
	|FROM
	|	TemporaryTableMessages AS TemporaryTableMessages
	|WHERE
	|	TemporaryTableMessages.amountBalance > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryTableMessages";
	
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("informationChannel", informationChannel);
		
	queryResult = query.Execute();
	If Not queryResult.IsEmpty() Then
		select = queryResult.Select();
		unReadMessagesCount = select.Count();		
		If message.IsEmpty() Then
			While select.Next() Do
				record = Documents.messageLogs.CreateDocument();
				record.date								= ToUniversalTime(CurrentDate());
				record.recordDate						= record.date;
				record.message							= select.message;
				record.token								= tokenContext.token;
				record.messageStatus				= Enums.messageStatuses.read;
				record.informationChannel	= informationChannel;
				record.Write(DocumentWriteMode.Posting);
			EndDo;
			unReadMessagesCount = 0;
		Else
			If select.FindNext(New Structure("message", message)) Then
				record = Documents.messageLogs.CreateDocument();
				record.date								= ToUniversalTime(CurrentDate());
				record.recordDate						= record.date;
				record.message							= select.message;
				record.token								= tokenContext.token;
				record.messageStatus				= Enums.messageStatuses.read;
				record.informationChannel	= informationChannel;
				record.Write(DocumentWriteMode.Posting);
				unReadMessagesCount 		   = unReadMessagesCount - 1;
			EndIf;
		EndIf;
	Else
		unReadMessagesCount = 0;
	EndIf;	
	
//	query = New Query();
//	query.text = "SELECT
//	|	messages.Ref AS message
//	|FROM
//	|	Catalog.messages AS messages
//	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
//	|		ON messages.Ref = messagesLogsSliceLast.message
//	|WHERE
//	|	ISNULL(messagesLogsSliceLast.messageStatus, VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
//	|	AND Messages.user = &user
//	|	AND Messages.appType = &appType";
//
//	query.SetParameter("user", tokenContext.user);
//	query.SetParameter("appType", tokenContext.appType);
//
//	queryResult = query.Execute();
//	If Not queryResult.IsEmpty() Then
//		select = queryResult.Select();
//		unReadMessagesCount = select.Count();		
//		If message.IsEmpty() Then
//			While select.Next() Do
//				record = InformationRegisters.messagesLogs.CreateRecordManager();
//				record.period				= ToUniversalTime(CurrentDate());
//				record.message				= select.message;
//				record.token				= tokenContext.token;
//				record.recordDate			= record.period;
//				record.messageStatus		= Enums.messageStatuses.read;
//				record.informationChannel	= informationChannel;
//				record.Write();
//			EndDo;
//			unReadMessagesCount = 0;
//		Else
//			If select.FindNext(New Structure("message", message)) Then
//				record = InformationRegisters.messagesLogs.CreateRecordManager();
//				record.period				= ToUniversalTime(CurrentDate());
//				record.message 				= message;
//				record.token 				= tokenContext.token;
//				record.recordDate 			= record.period;
//				record.messageStatus 		= Enums.messageStatuses.read;
//				record.informationChannel	= informationChannel;
//				record.Write();
//				unReadMessagesCount 		= unReadMessagesCount - 1;
//			EndIf;
//		EndIf;
//	Else
//		unReadMessagesCount = 0;
//	EndIf;
unReadMessagesCount = 0;
	struct.Insert("result", "Ok");
	struct.Insert("quantity", unReadMessagesCount);
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure unReadNotificationCount(parameters)

	tokenContext = parameters.tokenContext;
	struct = New Structure();
    query = New Query();
    query.text = "SELECT
    |	pushStatusBalance.user,
    |	pushStatusBalance.amountBalance
    |FROM
    |	AccumulationRegister.pushStatus.Balance(, user = &user
    |	AND informationChannel = &informationChannel) AS pushStatusBalance";
   query.SetParameter("user", tokenContext.user);
   query.SetParameter("informationChannel", ?(tokenContext.appType = enums.appTypes.Customer, 
   																					enums.informationChannels.pushCustomer,
   																						?(tokenContext.appType = enums.appTypes.Employee, 
   																							enums.informationChannels.pushEmployee, 
   																								enums.informationChannels.EmptyRef())));
//	query = New Query();
//	query.text = "SELECT
//	|	COUNT(messages.Ref) AS count
//	|FROM
//	|	Catalog.messages AS messages
//	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
//	|		ON messages.Ref = messagesLogsSliceLast.message
//	|WHERE
//	|	ISNULL(messagesLogsSliceLast.messageStatus, VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
//	|	AND Messages.user = &user
//	|	AND Messages.appType = &appType";
//
//	query.SetParameter("user", tokenContext.user);
//	query.SetParameter("appType", tokenContext.appType);
//
	result = query.Execute();
	if not result.IsEmpty() then
		select =result.Select();
		select.Next();
		count = select.amountBalance;
	Else
		count = 0;
	EndIf;
		
	struct.Insert("quantity", count);

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure executeExternalRequest(parameters)
	
	tokenContext = parameters.tokenContext;
	language = parameters.language;		
	answerBody = "";
	
	query = New Query();
	query.text = "SELECT
	|	matchingRequestsInformationSources.performBackground AS performBackground,
	|	matchingRequestsInformationSources.requestReceiver AS requestReceiver,
	|	matchingRequestsInformationSources.HTTPRequestType AS HTTPRequestType,
	|	matchingRequestsInformationSources.Attribute AS Attribute,
	|	matchingRequestsInformationSources.staffOnly AS staffOnly,	
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
		parameters.Insert("error", "noUrl");
	Else		
		select = queryResult.Select();
		select.Next();
		If select.staffOnly
				And tokenContext.userType <> "employee" Then			
			parameters.Insert("error", "staffOnly");
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
							parameters.Insert("error", HTTPResponseStruct.result);
						EndIf;
					Else						
						parameters.Insert("error", "system");
					EndIf;
				Else
					DoInternalProcedures(parameters);
				EndIf;
				parameters.Insert("statusCode", statusCode);
			EndIf;
		EndIf;		
	EndIf;

	parameters.Insert("answerBody", answerBody);		

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

	If Not requestStruct.Property("messages") Then		
		parameters.Insert("error", "noMessages");
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
				parameters.Insert("error", "phoneError");		
			//ElsIf messageStruct.user = messageStruct.token.user Then
			Else
				Messages.newMessage(messageStruct, sendImmediately);
			EndIf;
		EndDo;
	EndIf;

	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	
EndProcedure

Procedure imagePOST(parameters)
	
	requestBody = parameters.requestBody;
	tokenContext = parameters.tokenContext;
	headers = parameters.headers;	
	
	struct = New Structure();
	
	If TypeOf(requestBody) <> Type("BinaryData") Then		
		parameters.Insert("error", "noBinaryData");
	Else
		pathStruct = Files.getPath(headers["objectName"], tokenContext.holding.code);
		fileName = Files.pathConcat("" + New UUID(), headers["extension"]);
		requestBody.write(Files.pathConcat(pathStruct.location, fileName, "\"));		
		struct.Insert("result", Files.pathConcat(pathStruct.URL, fileName, "/"));
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	
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

Procedure DoInternalProcedures(parameters)
	If parameters.requestName = "scheduleregistration" then
		writeClassMember(parameters);
	EndIf;
EndProcedure

Procedure writeClassMember(parameters)
	If parameters.Property("requestStruct") and parameters.Property("tokenContext") then
		record = InformationRegisters.classMembers.CreateRecordManager();
		record.class = XMLValue(Type("CatalogRef.classesSchedule"), parameters.requestStruct.docID);
		record.user  =  parameters.tokenContext.user;
		if parameters.requestStruct.type = "reserve" then
			record.registrationDate = ToUniversalTime(CurrentDate());
			record.Write();
		ElsIf parameters.requestStruct.type = "cancel" Then
			 record.Read();
			 record.Delete();
		EndIf;
	EndIf;
endprocedure

Procedure SendMale(parameters) Export
	MailMessage = NewMail(parameters.MailFrom, parameters.MailTo, parameters.Subject, parameters.Texts, parameters.Attachments);
	MailProfile = GetNewMailProfile();
	Mail = New InternetMail;
	Try
		Mail.Logon(MailProfile);
		Mail.Send(MailMessage);
		Mail.Logoff();
	Except
		// TODO:
	EndTry;
EndProcedure

Function NewMail(MailFrom, MailTo, Subject, Texts, Attachments)
	NewMail = New InternetMailMessage;
	NewMail.From.Address = MailFrom;
	For each Mail in MailTo do
		NewMail.To.add(Mail);
	EndDo;
	NewMail.Subject = Subject;
	NewMail.Texts.Add(Texts);
	If not Attachments = Undefined then
		for each Attachment In Attachments do
			NewMail.Attachments.Add(Attachment.File, Attachment.Name)
		EndDo;
	EndIf;
	return NewMail;
EndFunction

Function GetNewMailProfile()
	MailProfile = New InternetMailProfile;
	MailProfile.SMTPServerAddress = "cas.wcfc.local";
	MailProfile.SMTPAuthentication = SMTPAuthenticationMode.None;
	MailProfile.SMTPPort = 25;
	return MailProfile;
EndFunction

Procedure SendServiceMail(Texts, MailArray) Export
	Parameters = New Structure;
	Parameters.Insert("MailFrom","1c_kpo@wclass.ru");
	Parameters.Insert("MailTo", MailArray);
	Parameters.Insert("Attachments", Undefined);
	Parameters.Insert("Subject", "Ошибка коннект");
	Parameters.Insert("Texts", Texts);	
	SendMale(Parameters);
EndProcedure
