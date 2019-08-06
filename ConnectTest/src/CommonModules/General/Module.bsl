
Procedure executeRequestMethod(parameters) Export
	
	parameters.Insert("errorDescription", Check.requestParameters(parameters));	
	
	If parameters.errorDescription.result = "" Then
		If parameters.requestName = "chainlist" Then // проверить описание в API
			getChainList(parameters);
		ElsIf parameters.requestName = "countrycodelist" Then // проверить описание в API 
			getCountryCodeList(parameters);
		ElsIf parameters.requestName = "config" Then
			getConfig(parameters);
		ElsIf parameters.requestName = "signin" Then
			userSignIn(parameters);
		ElsIf parameters.requestName = "confirm" Then
			userConfirm(parameters);
		ElsIf parameters.requestName = "addusertotoken" Then
			addUserToToken(parameters);
		ElsIf parameters.requestName = "registerdevice" Then
			registerDevice(parameters);
		ElsIf parameters.requestName = "deluserintoken" Then
			delUserInToken(parameters);
		ElsIf parameters.requestName = "userprofile" Then // проверить описание в API
			ПолучитьПрофильПользователя(parameters);
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
		If selection.lockDate < ToUniversalTime(CurrentDate()) Then
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
			tokenStruct.Insert("userStatus", selection.userStatus);
			struct.Insert("token", tokenStruct);
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
		struct = New Structure();
		struct.Insert("token", XMLString(Accounts.getToken(tokenСontext.token, tokenStruct)));
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	

EndProcedure

Procedure userSignIn(parameters)

	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	errorDescription = parameters.errorDescription;
	
	struct = New Structure();

	retryTime = Service.timeBeforeSendSms(tokenСontext.token);
	If retryTime > 0 Then
		struct.Insert("result", "Fail");
		struct.Insert("retryTime", retryTime);
	Else
		chain = Catalogs.chains.FindByCode(requestStruct.chainCode);
		If ValueIsFilled(chain) Then
			If tokenСontext.chain <> chain Then
				tokenСontext.Insert("chain", chain);
				Accounts.editPropertyInToken(tokenСontext.token, "chain", chain);
			EndIf;
		Else
			errorDescription = Service.getErrorDescription(language, "chainCodeError");
		EndIf;
		If errorDescription.result = "" Then
			tempCode = Accounts.tempPassword();
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
			Service.addUsersAuthCode(tokenСontext.token, requestStruct.phone, tempCode);
			struct.Insert("result", "Ok");
			struct.Insert("retryTime", 60);
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure userConfirm(parameters)

	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	errorDescription = parameters.errorDescription;
	
	struct = New Structure();

	query = New Query();
	query.Text = "SELECT
	|	usersAuthorizationCodes.code,
	|	usersAuthorizationCodes.phone,
	|	usersAuthorizationCodes.quantity,
	|	usersAuthorizationCodes.recordDate
	|FROM
	|	InformationRegister.usersAuthorizationCodes AS usersAuthorizationCodes
	|WHERE
	|	usersAuthorizationCodes.token = &token";

	query.SetParameter("token", tokenСontext.token);
	
	queryResult = query.Execute();
	If queryResult.isEmpty() Then
		errorDescription = Service.getErrorDescription(language, "passwordIsRequired");
	Else
		selection = queryResult.Select();
		selection.Next();
		If selection.code = requestStruct.password Then
			record = InformationRegisters.usersAuthorizationCodes.CreateRecordManager();
			record.token = tokenСontext.token;			
			record.Read();
			If record.Selected() Then
				record.Delete();
			EndIf;
			queryUser = New Query("SELECT
			|	users.Ref AS account,
			|	ISNULL(customers.Ref, VALUE(Catalog.users.EmptyRef)) AS account
			|FROM
			|	Catalog.accounts AS users
			|		LEFT JOIN Catalog.users AS customers
			|		ON customers.Owner = users.Ref
			|		AND customers.holding = &holding
			|WHERE
			|	users.code = &phone");

			queryUser.SetParameter("holding", tokenСontext.holding);
			queryUser.SetParameter("phone", selection.phone);
			queryUserResult = queryUser.Execute();
			If queryUserResult.isEmpty() Then
				parametersNew = Service.getStructCopy(parameters);
				parametersNew.Insert("requestName", "userProfile");
				parametersNew.requestStruct.Insert("phone", selection.phone);
				executeExternalRequest(parametersNew);
				If parametersNew.errorDescription.result = "" Then
					answerStruct = HTTP.decodeJSON(parametersNew.answerBody);
					If answerStruct.Count() = 1 Then
						userArray = Service.createCatalogItems("addChangeUsers", tokenСontext.holding, answerStruct);
						Accounts.editPropertyInToken(tokenСontext.token, "account", userArray[0]);
						customerArray = Service.createCatalogItems("addChangeCustomers", tokenСontext.holding, answerStruct, userArray[0]);
						Accounts.editPropertyInToken(tokenСontext.token, "account", customerArray[0]);
						struct.Insert("result", "Ok");
					ElsIf answerStruct.Count() > 1 Then
						userList = New Array();
						For Each user In answerStruct Do
							userList.Add(New Structure("name, uid", user.lastName + " "
								+ user.firstName + " " + user.secondName, user.uid));
						EndDo;
						struct.Insert("userList", userList);
					Else
						errorDescription = Service.getErrorDescription(language, "passwordIsNotCorrect"); //Хотя такого быть не должно									
					EndIf;
				Else
					errorDescription = parametersNew.errorDescription;
				EndIf;
			Else
				selectionUser = queryUserResult.Select();
				selectionUser.Next();
				Accounts.editPropertyInToken(tokenСontext.token, "account", selectionUser.user);
				struct.Insert("result", "Ok");
			EndIf;
		Else
			errorDescription = Service.getErrorDescription(language, "passwordIsNotCorrect");
		EndIf;
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure addUserToToken(parameters)

	tokenСontext = parameters.tokenСontext;
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	errorDescription = parameters.errorDescription;
		
	struct = New Structure();

	parametersNew = Service.getStructCopy(parameters);
	parametersNew.Insert("requestName", "userProfile");
	parametersNew.requestStruct.Insert("uid", requestStruct.uid);
	executeExternalRequest(parametersNew);
	If parametersNew.errorDescription.result = "" Then
		tempArray = HTTP.decodeJSON(parametersNew.answerBody);
		If tempArray.Count() = 1 Then
			userArray = Service.createCatalogItems("addChangeUsers", tokenСontext.holding, tempArray);
			Accounts.editPropertyInToken(tokenСontext.token, "account", userArray[0]);
			struct.Insert("result", "Ok");
		Else
			errorDescription = Service.getErrorDescription(language, "userNotfound"); //Хотя такого быть не должно									
		EndIf;
	Else
		errorDescription = parametersNew.errorDescription;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure delUserInToken(parameters)
	Accounts.delUserIoToken(parameters.tokenСontext.token);	
	parameters.Insert("answerBody", HTTP.encodeJSON(New Structure("result", "Ok")));	
EndProcedure

Procedure ПолучитьПрофильПользователя(parameters)

//@skip-warning
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	tokenСontext = parameters.tokenСontext;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	Пользователи.Ссылка КАК account,
		|	Пользователи.login КАК login,
		|	Пользователи.birthday КАК birthday,
		|	Пользователи.phone КАК phone,
		|	Пользователи.Email КАК Email,
		|	НЕ Пользователи.notSubscriptionEmail КАК УчаствоватьВРассылкеEmail,
		|	НЕ Пользователи.notSubscriptionSms КАК УчаствоватьВРассылкеСообщений,
		|	Пользователи.sex КАК sex,
		|	Не Пользователи.canUpdatePersonalData КАК РазрешитьОбновлятьПерсональныеДанные,
		|	Пользователи.barCode КАК barCode,
		|	Пользователи.userCode КАК userCode,
		|	Пользователи.lastName КАК lastName,
		|	Пользователи.firstName КАК firstName,
		|	Пользователи.secondName КАК secondName
		|ИЗ
		|	Справочник.accounts КАК Пользователи
		|ГДЕ
		|	Пользователи.Ссылка = &account
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	СостояниеПользователя.cacheValuesType.Наименование КАК cacheValuesType,
		|	СостояниеПользователя.Значение КАК ЗначениеКэша
		|ИЗ
		|	РегистрСведений.usersStates КАК СостояниеПользователя
		|ГДЕ
		|	СостояниеПользователя.account = &account
		|	И СостояниеПользователя.appType = &appType";

	пЗапрос.УстановитьПараметр("account", tokenСontext.Пользователь);
	пЗапрос.УстановитьПараметр("appType", tokenСontext.ВидПриложения);

	РезультатыЗапроса = пЗапрос.ВыполнитьПакет();
	queryResult = РезультатыЗапроса[0];
	queryResult1 = РезультатыЗапроса[1];

	If queryResult.Пустой() Then
		parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "userNotIdentified"));
	Иначе
		selection = queryResult.Выбрать();
		selection.Следующий();
		СтруктураJSON.Вставить("login", selection.Логин);
		СтруктураJSON.Вставить("birthdayDate", selection.ДатаРождения);
		СтруктураJSON.Вставить("phoneNumber", selection.НомерТелефона);
		СтруктураJSON.Вставить("email", selection.Email);
		СтруктураJSON.Вставить("subscriptionEmail", selection.УчаствоватьВРассылкеEmail);
		СтруктураJSON.Вставить("subscriptionSms", selection.УчаствоватьВРассылкеСообщений);
		СтруктураJSON.Вставить("gender", selection.Пол);
		СтруктураJSON.Вставить("canUpdatePersonalData", selection.РазрешитьОбновлятьПерсональныеДанные);
		СтруктураJSON.Вставить("barcode", selection.Штрихкод);
		СтруктураJSON.Вставить("cid", selection.КодПользователя);
		СтруктураJSON.Вставить("uid", XMLСтрока(selection.Пользователь));
		СтруктураJSON.Вставить("lastName", selection.Фамилия);
		СтруктураJSON.Вставить("firstName", selection.Имя);
		СтруктураJSON.Вставить("secondName", selection.Отчество);

		selection = queryResult1.Выбрать();
		Пока selection.Следующий() Цикл
			СтруктураJSON.Вставить(selection.ТипЗначенияКэша, HTTP.decodeJSON(selection.ЗначениеКэша));
		КонецЦикла;
	EndIf;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

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
			|		holidaysTime)
			|FROM
			|	Catalog.gyms AS gyms
			|WHERE
			|	gyms.chain.code = &chainCode
			|	AND
			|	NOT gyms.DeletionMark";

		query.SetParameter("chainCode", requestStruct.chain);
		selection = query.Execute().Select();

		While selection.Next() Do
			gymStruct = New Structure();
			gymStruct.Insert("gymId", XMLString(selection.Ref));
			gymStruct.Insert("name", selection.Description);
			gymStruct.Insert("type", selection.type);
			gymStruct.Insert("cityId", XMLString(selection.city));
			gymStruct.Insert("gymAddress", selection.address);
			gymStruct.Insert("divisionTitle", selection.segment);

			coords = New Structure();
			coords.Insert("latitude", selection.latitude);
			coords.Insert("longitude", selection.longitude);
			gymStruct.Вставить("coords", coords);

			scheduledArray = New Array();
			For Each department In selection.departmentWorkSchedule.Unload() Do
				schedule = New Structure();
				schedule.Insert("name", department.department);
				schedule.Insert("phone", department.phone);
				schedule.Insert("weekdaysTime", department.weekdaysTime);
				schedule.Insert("holidaysTime", department.holidaysTime);
				scheduledArray.add(schedule);
			EndDo;
			gymStruct.Insert("departments", scheduledArray);
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

	If tokenСontext.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf tokenСontext.appType = Enums.appTypes.Customer Then
		informationChannel = Enums.informationChannels.pushCustomer;
	Else
		informationChannel = Enums.informationChannels.EmptyRef()
	EndIf;

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
	|		LEFT JOIN Catalog.messages.channelPriorities AS messageschannelPriorities
	|		ON messageschannelPriorities.Ref = messages.Ref
	|WHERE
	|	messages.account = &account
	|	AND messages.registrationDate < &registrationDate
	|	AND messageschannelPriorities.channel = &informationChannel
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
	query.SetParameter("account", tokenСontext.user);
	query.SetParameter("informationChannel", informationChannel);

	selection = query.Execute().Select();
	While selection.Next() Do
		messageStruct = New Structure();
		messageStruct.Insert("noteId", XMLString(selection.message));
		messageStruct.Insert("date", XMLString(ToLocalTime(selection.registrationDate, tokenСontext.timeZone)));
		messageStruct.Insert("title", selection.title);
		messageStruct.Insert("text", selection.text);
		messageStruct.Insert("read", selection.read);
		messageStruct.Insert("objectId", selection.objectId);
		messageStruct.Insert("objectType", selection.objectType);
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
	|		LEFT JOIN Catalog.messages.channelPriorities AS messagesChannelPriorities
	|		ON messages.Ref = messagesChannelPriorities.Ref
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
	|		ON messages.Ref = messagesLogsSliceLast.message
	|WHERE
	|	messagesChannelPriorities.channel = &informationChannel
	|	И ISNULL(messagesLogsSliceLast.messageStatus,
	|		VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
	|	И Messages.account = &account";

	query.SetParameter("account", tokenСontext.Пользователь);
	query.SetParameter("informationChannel", informationChannel);

	queryResult = query.Execute();
	If Not queryResult.IsEmpty() Then
		selection = queryResult.Select();
		unReadMessagesCount = selection.Count();
		
		If message.IsEmpty() Then
			While selection.Next() Do
				record = InformationRegisters.messagesLogs.CreateRecordManager();
				record.period				= ToUniversalTime(CurrentDate());
				record.message				= selection.message;
				record.token				= tokenСontext.token;
				record.recordDate			= record.period;
				record.messageStatus		= Enums.messageStatuses.read;
				record.informationChannel	= informationChannel;
				record.Write();
			EndDo;;
			unReadMessagesCount = 0;
		Else
			If selection.FindNext(New Structure("message", message)) Then
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

	tokenСontext		= parameters.tokenСontext;

	struct = New Structure();

	If tokenСontext.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf tokenСontext.appType = Enums.appTypes.Customer Then
		informationChannel = Enums.informationChannels.pushCustomer;
	Else
		informationChannel = Enums.informationChannels.EmptyRef();
	EndIf;

	query = New Query();
	query.text = "SELECT
	|	COUNT(messages.Ref) AS count
	|FROM
	|	Catalog.messages AS messages
	|		LEFT JOIN Catalog.messages.channelPriorities AS messagesChannelPriorities
	|		ON messages.Ref = messagesChannelPriorities.Ref
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast КАК messagesLogsSliceLast
	|		ON messages.Ref = messagesLogsSliceLast.message
	|WHERE
	|	messagesChannelPriorities.channel = &informationChannel
	|	И ISNULL(messagesLogsSliceLast.messageStatus,
	|		VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
	|	И Messages.account = &account";

	query.SetParameter("account", tokenСontext.Пользователь);
	query.SetParameter("informationChannel", informationChannel);

	selection = query.Execute().Select();
	selection.Next();
	struct.Insert("quantity", selection.count);

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure executeExternalRequest(parameters)

	requestStruct = parameters.requestStruct;
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
	|	holdingsConnectionsInformationSources.account AS account,
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
	
	requestStruct		= parameters.requestStruct;
	tokenСontext			= parameters.tokenСontext;
	language			= parameters.language;	
	struct				= New Structure();	
	errorDescription	= Service.getErrorDescription();
	
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
				messageStruct.Insert("account", XMLValue(Type("CatalogRef.accounts"), message.uid));
			Else
				messageStruct.Insert("account", Catalogs.accounts.EmptyRef());
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
					And messageStruct.account.GetObject() = Undefined Then
			ElsIf messageStruct.account = messageStruct.token.account Then
			Else
				Messages.НовоеСообщение(messageStruct);
			EndIf;
		EndDo;
	EndIf;

	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure ОбновитьКэшПользователей(parameters, Холдинг,
		МассивПользователей) Экспорт

	СтруктураЗапроса = HTTP.GetRequestStructure("userProfileCache", Холдинг);
	If СтруктураЗапроса.Количество() > 0 Then
		Для Каждого Пользователь Из МассивПользователей Цикл
		КонецЦикла;		
		Заголовки = Новый Соответствие;
		Заголовки.Вставить("Content-Type", "application/json");
		HTTPСоединение = Новый HTTPСоединение(СтруктураЗапроса.server, , СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.password, , СтруктураЗапроса.timeout, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.UseOSAuthentication);
		ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL
			+ СтруктураЗапроса.Приемник, Заголовки);
		ЗапросHTTP.УстановитьТелоИзСтроки(parameters.requestBody);
		ОтветHTTP = HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
	EndIf;
EndProcedure