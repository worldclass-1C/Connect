
Procedure executeRequestMethod(parameters) Export
	
	If parameters.requestName = "chainlist" Then // проверить описание в API
		getChainList(parameters);
	ElsIf parameters.requestName = "countrycodelist" Then // проверить описание в API 
		getCountryCodeList(parameters);
	ElsIf parameters.requestName = "config" Then 
		getAppConfig(parameters);
	ElsIf parameters.requestName = "auth" Then 
		userAuthorization(parameters);
	ElsIf parameters.requestName = "restore" Then 
		restoreUserPassword(parameters);
	ElsIf parameters.requestName = "newpassword" Then // проверить описание в API
		setUserPassword(parameters);
	ElsIf parameters.requestName = "registerdevice" Then 
		registerDevice(parameters);
	ElsIf parameters.requestName = "unregisterdevice" Then 
		unRegisterDevice(parameters);
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
	ElsIf parameters.requestName = "addusers"
			Or parameters.requestName = "addgyms"
			Or parameters.requestName = "addrequest"
			Or parameters.requestName = "addcancelcauses"
			Or parameters.requestName = "addcities" Then // проверить описание в API
		changeCreateCatalogItems(parameters);
	ElsIf parameters.requestName = "sendmessage" Then // проверить описание в API
		sendMessage(parameters);	
	Else
		executeExternalRequest(parameters);
	EndIf;
		
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
	parameters.Insert("answerBody", HTTP.encodeJSON(GeneralReuse.getCountryCodeList()));
	parameters.Insert("notSaveAnswer", True);
EndProcedure

Procedure getAppConfig(parameters)
	
	requestStruct	= parameters.requestStruct;
	language		= parameters.language;
	brand 			= parameters.brand;
	
	struct			= New Structure();	
	errorDescription = Service.getErrorDescription();

	If Not requestStruct.Property("appType") Then
		errorDescription = Service.getErrorDescription(language, "noAppType");
	ElsIf Not requestStruct.Property("systemType") Then
		errorDescription = Service.getErrorDescription(language, "noSystemType");
	ElsIf Not requestStruct.Property("token") Then
		errorDescription = Service.getErrorDescription(language, "noToken");	
	EndIf;

	If errorDescription.result = "" Then
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
		|	registeredDevices.appVersion AS backendVersion
		|FROM
		|	InformationRegister.registeredDevices AS registeredDevices
		|WHERE
		|	registeredDevices.token = &token";

		query.SetParameter("brand", Enums.brandTypes[brand]);
		query.SetParameter("appType", Enums.appTypes[requestStruct.appType]);
		query.SetParameter("systemType", Enums.systemTypes[requestStruct.systemType]);
		query.SetParameter("token", ?(requestStruct.token = "", Catalogs.tokens.EmptyRef(), XMLValue(Type("CatalogRef.tokens"),requestStruct.token)));		

		queryResults = query.ExecuteBatch();		
		queryResult	= queryResults[0];
		
		If queryResult.IsEmpty() Then
			struct.Insert("minVersion", 0);
		Else
			selection = queryResult.Select();		
			selection.Next();
			struct.Insert("minVersion", selection.minVersion);			
		EndIf;
		
		queryResult	= queryResults[1];
		
		If queryResult.IsEmpty() Then
			struct.Insert("backendVersion", 0);
		Else
			selection = queryResult.Select();		
			selection.Next();
			struct.Insert("backendVersion", selection.backendVersion);			
		EndIf;

	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure userAuthorization(parameters)

	requestStruct	= parameters.requestStruct;
	language		= parameters.language;
	struct			= New Structure();
	currentDate		= ToUniversalTime(CurrentDate());
	errorDescription = Service.getErrorDescription();

	If Not requestStruct.Property("login") Then
		errorDescription = Service.getErrorDescription(language, "noUserLogin");
	ElsIf Not requestStruct.Property("password")
			Or requestStruct.password = "" Then
		errorDescription = Service.getErrorDescription(language, "noUserPassword");
	ElsIf Not requestStruct.Property("chain") Then
		errorDescription = Service.getErrorDescription(language, "noChain");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query();
		query.Text = "SELECT
		|	users.Ref AS user,
		|	users.holding,
		|	users.userType,
		|	usersPasswords.Validity,
		|	chain.Ref AS chain,
		|	chain.timeZone
		|FROM
		|	Catalog.users AS users
		|		LEFT JOIN InformationRegister.usersPasswords AS usersPasswords
		|		ON usersPasswords.User = users.Ref
		|		LEFT JOIN Catalog.chains AS chain
		|		ON users.holding = chain.holding
		|WHERE
		|	usersPasswords.Password = &Password
		|	AND chain.Code = &chainCode
		|	AND users.phone = &login";

		query.SetParameter("login", requestStruct.login);
		query.SetParameter("password", requestStruct.password);
		query.SetParameter("chainCode", requestStruct.chain);		

		queryResult = query.Execute();
		If queryResult.IsEmpty() Then
			errorDescription = Service.getErrorDescription(language, "passwordIsNotCorrect");
		Else
			selection = queryResult.Select();		
			selection.Next();
			If Lower(selection.userType) <> "employee"
					And Lower(requestStruct.appType) = "employee" Then
				errorDescription = Service.getErrorDescription(language, "staffOnly");
			ElsIf selection.validity = Date(1, 1, 1)
					Or selection.validity >= currentDate Then
				struct.Insert("result", ?(selection.validity = Date(1, 1, 1), "Ok", "PasswordHasExpirationDate"));
				tokenObject = Users.getToken(requestStruct, selection.user, selection.chain, selection.holding, selection.timeZone);
				struct.Insert("authToken", New Structure("key,createTime", XMLString(tokenObject.Ref), tokenObject.createDate));
				parameters.Insert("token", tokenObject.Ref);				
			Else
				errorDescription = Service.getErrorDescription(language, "userPasswordExpired");
			EndIf;
		EndIf;

	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure restoreUserPassword(parameters)

	requestStruct = parameters.requestStruct;	
	language = parameters.language;	
	errorDescription = Service.getErrorDescription();
		
	struct = New Structure();
	
	If Not requestStruct.Propery("phone") Then
		errorDescription = Service.getErrorDescription(language, "noUserPhone");
	ElsIf Not requestStruct.Propery("chain") Then
		errorDescription = Service.getErrorDescription(language, "noChain");
	EndIf;

	If errorDescription.result = "" Then
		errorDescription = Service.canSendSms(language, requestStruct.phone);
	EndIf;

	If errorDescription.result = "" Then		
		query = New Query();
		query.text = "SELECT
		|	users.Ref AS user,
		|	users.holding AS holding
		|FROM
		|	Catalog.users AS users
		|		LEFT JOIN Catalog.chains КАК chains
		|		ON users.holding = chains.holding
		|WHERE
		|	chains.code = &chainCode
		|	AND users.phone = &phone";

		query.SetParameter("phone", requestStruct.phone);
		query.SetParameter("chainCode", requestStruct.chain);
		
		queryResult = query.Execute();
		If queryResult.isEmpty() Then
			errorDescription = Service.getErrorDescription(language, "userNotfound");			
		Else
			selection = queryResult.Select();
			selection.Next();			 
						
			informationChannels = New Array();
			informationChannels.Add(Enums.informationChannels.sms);

			rowsArray = New Array();
			rowsArray.Add(?(language = "ru", "login: ", "Login: "));
			rowsArray.Add(requestStruct.phone);
			rowsArray.Add(?(language = "ru", " password: ", " password: "));
			rowsArray.Add(Users.setUserPassword(selection.user));
			rowsArray.Add(?(language = "ru", ", password действителен в течение 15 минут", ", password is valid for 15 minutes"));

			messageStruct = New Структура;
			messageStruct.Insert("phone", requestStruct.phone);
			messageStruct.Insert("user", selection.user);
			messageStruct.Insert("title", "Восстановить доступ");
			messageStruct.Insert("text", StrConcat(rowsArray));
			messageStruct.Insert("holding", selection.holding);
			messageStruct.Insert("informationChannels", informationChannels);
			messageStruct.Insert("priority", 0);
			Messages.НовоеСообщение(messageStruct);
			Service.logServiceMessage(requestStruct.phone);
			
			struct.Insert("result", "Ok");			
		EndIf;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure setUserPassword(parameters)

	requestStruct	= parameters.requestStruct;
	language		= parameters.language;
	checkResult		= parameters.checkResult;	
	struct 			= New Structure();

	errorDescription = Users.checkPassword(language, checkResult.user, requestStruct.password);
	If requestStruct.newPassword = "" Then
		errorDescription = Service.getErrorDescription(language, "passwordIsEmpty");
	EndIf;
	If errorDescription.result = "" Then
		record = InformationRegisters.usersPasswords.CreateRecordManager();
		record.user 	= checkResult.user;
		record.password = requestStruct.newPassword;
		record.validity = Date(1, 1, 1);
		record.Write();
		struct.Insert("result", "Ok");
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure registerDevice(parameters)

	requestStruct		= parameters.requestStruct;
	language			= parameters.language;
	checkResult			= parameters.checkResult;
	errorDescription	= Service.getErrorDescription();
	
	struct = New Structure();

	If Not requestStruct.Property("deviceToken") Then
		errorDescription = Service.getErrorDescription(language, "noDeviceToken");
	ElsIf Not requestStruct.Property("systemVersion") Then
		errorDescription = Service.getErrorDescription(language, "noSystemVersion");		
	ElsIf Not requestStruct.Property("appVersion") Then
		errorDescription = Service.getErrorDescription(language, "noAppVersion");		
	EndIf;

	If errorDescription.result = "" Then
		struct.Insert("result", "Ok");
		record = InformationRegisters.registeredDevices.CreateRecordManager();
		record.token			= checkResult.token;
		record.deviceToken		= requestStruct.deviceToken;
		record.systemVersion	= requestStruct.systemVersion;
		record.appVersion		= Number(StrReplace(requestStruct.appVersion, ".", ""));
		record.deviceModel		= requestStruct.deviceModel;
		record.recordDate		= ToUniversalTime(CurrentDate());
		record.Write();
		
		query = New Query();
		query.text = "SELECT
		|	registeredDevices.token AS token
		|FROM
		|	InformationRegister.registeredDevices AS registeredDevices
		|WHERE
		|	registeredDevices.token <> &token
		|	AND registeredDevices.token.user = &user
		|	AND registeredDevices.systemVersion = &systemVersion
		|	AND registeredDevices.appVersion = &appVersion
		|	AND registeredDevices.deviceModel = &deviceModel
		|	AND registeredDevices.deviceToken = &deviceToken
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VALUE(Catalog.messages.EmptyRef) AS message,
		|	CASE
		|		WHEN &language = ""ru""
		|			THEN ""Уведомление""
		|		ELSE ""Notification""
		|	END AS title,
		|	CASE
		|		WHEN &language = ""ru""
		|			THEN ""Обновите приложение""
		|		ELSE ""Update the application""
		|	END AS text,
		|	""updateApp"" AS action,
		|	"""" AS objectId,
		|	"""" AS objectType,
		|	VALUE(ExchangePlan.messagesToSend.EmptyRef) AS nodeMessagesToSend,
		|	tokens.systemType AS systemType,
		|	CASE
		|		WHEN tokens.systemType = VALUE(Enum.systemTypes.Android)
		|			THEN ""GCM""
		|		ELSE ""APNS""
		|	END AS subscriberType,
		|	&deviceToken AS deviceToken,
		|	tokens.Ref AS token,
		|	CASE
		|		WHEN tokens.appType = VALUE(Enum.appTypes.Customer)
		|			THEN VALUE(Enum.informationChannels.pushCustomer)
		|		ELSE VALUE(Enum.informationChannels.pushEmployee)
		|	END AS informationChannel,
		|	tokens.lockDate КАК lockDate,
		|	ISNULL(appCertificatesForChain.certificate, appCertificatesGeneral.certificate) КАК certificate
		|FROM
		|	Catalog.tokens AS tokens
		|		LEFT JOIN InformationRegister.appCertificates AS appCertificatesForChain
		|		ON tokens.chain = appCertificatesForChain.chain
		|		AND tokens.appType = appCertificatesForChain.appType
		|		AND tokens.systemType = appCertificatesForChain.systemType
		|		LEFT JOIN InformationRegister.appCertificates AS appCertificatesGeneral
		|		ON (appCertificatesGeneral.chain = VALUE(Catalog.chains.EmptyRef))
		|		AND tokens.appType = appCertificatesGeneral.appType
		|		AND tokens.systemType = appCertificatesGeneral.systemType
		|		LEFT JOIN InformationRegister.currentAppVersions AS currentAppVersions
		|		ON tokens.appType = currentAppVersions.appType
		|		AND tokens.systemType = currentAppVersions.systemType
		|WHERE
		|	ISNULL(currentAppVersions.appVersion, 0) > &appVersion
		|	AND tokens.Ref = &token";

		query.SetParameter("token", checkResult.token);
		query.SetParameter("language", language);
		query.SetParameter("user", checkResult.user);
		query.SetParameter("systemVersion", record.systemVersion);
		query.SetParameter("appVersion", record.appVersion);
		query.SetParameter("deviceModel", record.deviceModel);
		query.SetParameter("deviceToken", record.deviceToken);

		queryResults	= query.ExecuteBatch();		 
		selection = queryResults[0].Select();			
		While selection.Next() Do
			Users.blockToken(selection.token);
		EndDo;		
		selection = queryResults[1].Select();			
		While selection.Next() Do
			Messages.ОтправитьPush(selection);
		EndDo;
		
	EndIf;

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure unRegisterDevice(parameters)
	checkResult		= parameters.checkResult;
	struct 			= New Structure();
	Users.blockToken(checkResult.token);
	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
EndProcedure

Procedure ПолучитьПрофильПользователя(parameters)

//@skip-warning
	requestStruct = parameters.requestStruct;
	language = parameters.language;
	checkResult = parameters.checkResult;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	Пользователи.Ссылка КАК user,
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
		|	Справочник.users КАК Пользователи
		|ГДЕ
		|	Пользователи.Ссылка = &user
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	СостояниеПользователя.cacheValuesType.Наименование КАК cacheValuesType,
		|	СостояниеПользователя.Значение КАК ЗначениеКэша
		|ИЗ
		|	РегистрСведений.usersStates КАК СостояниеПользователя
		|ГДЕ
		|	СостояниеПользователя.user = &user
		|	И СостояниеПользователя.appType = &appType";

	пЗапрос.УстановитьПараметр("user", checkResult.Пользователь);
	пЗапрос.УстановитьПараметр("appType", checkResult.ВидПриложения);

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

	checkResult		= parameters.checkResult;
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

	query.SetParameter("holding", checkResult.holding);
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
	checkResult		= parameters.checkResult;

	array = New Array();

	registrationDate = ToUniversalTime(?(requestStruct.date = "", CurrentDate(), XMLValue(Type("Date"), requestStruct.date)));

	If checkResult.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf checkResult.appType = Enums.appTypes.Customer Then
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
	|	messages.user = &user
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
	query.SetParameter("user", checkResult.user);
	query.SetParameter("informationChannel", informationChannel);

	selection = query.Execute().Select();
	While selection.Next() Do
		messageStruct = New Structure();
		messageStruct.Insert("noteId", XMLString(selection.message));
		messageStruct.Insert("date", XMLString(ToLocalTime(selection.registrationDate, checkResult.timeZone)));
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
	checkResult		= parameters.checkResult;
	
	struct = New Structure();

	If Not requestStruct.Property("noteId") or requestStruct.noteId = "" Then
		message = Catalogs.messages.EmptyRef();
	Else
		message = XMLValue(Type("CatalogRef.messages"), requestStruct.noteId);
	EndIf;

	If checkResult.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf checkResult.appType = Enums.appTypes.Customer Then
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
	|	И Messages.user = &user";

	query.SetParameter("user", checkResult.Пользователь);
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
				record.token				= checkResult.token;
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
				record.token 				= checkResult.token;
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

	checkResult		= parameters.checkResult;

	struct = New Structure();

	If checkResult.appType = Enums.appTypes.Employee Then
		informationChannel = Enums.informationChannels.pushEmployee;
	ElsIf checkResult.appType = Enums.appTypes.Customer Then
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
	|	И Messages.user = &user";

	query.SetParameter("user", checkResult.Пользователь);
	query.SetParameter("informationChannel", informationChannel);

	selection = query.Execute().Select();
	selection.Next();
	struct.Insert("quantity", selection.count);

	parameters.Insert("answerBody", HTTP.encodeJSON(struct));

EndProcedure

Procedure executeExternalRequest(parameters)

	requestStruct		= parameters.requestStruct;
	checkResult			= parameters.checkResult;
	language			= parameters.language;
	errorDescription	= Service.getErrorDescription();
	answerBody 			= "";

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

	query.SetParameter("holding", checkResult.holding);
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
				And checkResult.userType <> "employee" Then
			errorDescription = Service.getErrorDescription(language, "staffOnly");
		Else
			performBackground = selection.performBackground;
			arrayBJ = New Array(); 
			statusCode = 200;
			If selection.HTTPRequestType = Enums.HTTPRequestTypes.GET Then
				requestBody = "";
				parametersFromURL = StrReplace(parameters.URL, GeneralReuse.getBaseURL(), "");
			Else
				requestBody = HTTP.PrepareRequestBody(parameters.authKey, requestStruct, checkResult.user, language, checkResult.timeZone, checkResult.appType);
				parametersFromURL = "";
			EndIf;
			selection.Reset();
			While selection.Next() Do
				connectStruct = New Structure();
				connectStruct.Insert("server", selection.server);
				connectStruct.Insert("port", selection.port);
				connectStruct.Insert("user", selection.user);
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
	Service.createCatalogItems(parameters);	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
EndProcedure

Procedure sendMessage(parameters)
	
	requestStruct		= parameters.requestStruct;
	checkResult			= parameters.checkResult;
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
			messageStruct.Insert("holding", checkResult.holding);
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
				Messages.НовоеСообщение(messageStruct);
			EndIf;
		EndDo;
	EndIf;

	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure sendSMSCode(parameters)
	
	requestStruct		= parameters.requestStruct;	
	language			= parameters.language;	
	struct				= New Structure();	
	errorDescription	= Service.getErrorDescription();
	
	informationChannels = New Array();
	informationChannels.Add(Enums.informationChannels.sms);
		
	rowsArray = New Array();
	rowsArray.Add(?(language = "ru", "Пароль: ", "Password: "));
	rowsArray.Add(Users.tempPassword());
	rowsArray.Add(?(language = "ru", ", пароль действителен в течение 15 минут", ", password is valid for 15 minutes"));
	
	messageStruct = New Структура;
	messageStruct.Insert("phone", requestStruct.phone);	
	messageStruct.Insert("title", "SMS code");
	messageStruct.Insert("text", StrConcat(rowsArray));
	messageStruct.Insert("holding", selection.holding);
	messageStruct.Insert("informationChannels", informationChannels);
	messageStruct.Insert("priority", 0);
	Messages.НовоеСообщение(messageStruct);
	Service.logServiceMessage(requestStruct.phone);
	
	
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