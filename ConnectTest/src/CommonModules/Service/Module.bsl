Function getErrorDescription(language, erroeCode = "",
		description = "") Export

	errorDescription = New Structure("result, description", erroeCode, description);

	If erroeCode <> "" And description = "" Then
		query = New Query("SELECT
		|	errorDescriptionstranslation.description
		|FROM
		|	Catalog.errorDescriptions AS errorDescriptions
		|		LEFT JOIN Catalog.errorDescriptions.translation AS errorDescriptionstranslation
		|		ON errorDescriptions.Ref = errorDescriptionstranslation.Ref
		|		AND errorDescriptionstranslation.language = &language
		|WHERE
		|	errorDescriptions.Code = &erroeCode
		|
		|UNION ALL
		|
		|SELECT
		|	errorDescriptionstranslation.description
		|FROM
		|	Catalog.errorDescriptions AS errorDescriptions
		|		LEFT JOIN Catalog.errorDescriptions.translation AS errorDescriptionstranslation
		|		ON errorDescriptions.Ref = errorDescriptionstranslation.Ref
		|		AND errorDescriptionstranslation.language = &language
		|WHERE
		|	errorDescriptions.Code = ""System""");
		
		query.SetParameter("erroeCode", erroeCode);
		query.SetParameter("language", language);
		select = query.Execute().Select();
		select.Next();
		errorDescription.Insert("description", select.description);		

	EndIf;

	Return errorDescription;

EndFunction

Function getRecorder(day, reportPeriod)

	begOfDay	= BegOfDay(day);

	query	= New Query();
	query.Text	= "ВЫБРАТЬ
	|	РегистраторДвижений.Ссылка КАК Ref
	|ИЗ
	|	Документ.РегистраторДвижений КАК РегистраторДвижений
	|ГДЕ
	|	РегистраторДвижений.Дата = &day
	|	И РегистраторДвижений.ПериодОтчета = &reportPeriod";
	
	query.SetParameter("day", begOfDay);
	query.SetParameter("reportPeriod", reportPeriod);
	queryResult	= query.Execute();
		
	If queryResult.IsEmpty() Then
		docObject				= Documents.РегистраторДвижений.CreateDocument();
		docObject.Date			= begOfDay;
		docObject.ПериодОтчета	= reportPeriod;		
		docObject.Write();
		Return docObject.Ref;
	Else
		selection = queryResult.Select();		
		selection.Next();
		Return selection.Ref;
	EndIf;

EndFunction 

Function canSendSms(language, phone) Export

	errorDescription	= Service.getErrorDescription(language);
	universalTime		= ToUniversalTime(CurrentDate());
	
	query	= New Query();
	query.Text	= "SELECT
	|	DATEDIFF(serviceMessagesLogs.recordDate, &universalTime, MINUTE) AS minutesPassed,
	|	ISNULL(serviceMessagesLogs.quantity, 0) AS quantity,
	|	ISNULL(serviceMessagesLogs.recordDate, &universalTime) AS recordDate
	|INTO TT
	|FROM
	|	InformationRegister.serviceMessagesLogs AS serviceMessagesLogs
	|WHERE
	|	serviceMessagesLogs.phone = &phone
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TT.minutesPassed) AS minutesPassed,
	|	SUM(TT.quantity) AS quantity
	|FROM
	|	TT AS TT
	|WHERE
	|	TT.recordDate >= &recordDate
	|HAVING
	|	SUM(TT.quantity) > 0";
	
	query.SetParameter("phone", phone);
	query.SetParameter("recordDate", AddMonth(universalTime, - 1));
	query.SetParameter("universalTime", universalTime);
	
	queryResult	= query.Execute();
	
	If Not queryResult.IsEmpty() Then		
		selection = queryResult.Select();
		selection.Next();		
		If selection.quantity > 3 Then
			errorDescription	= Service.getErrorDescription(language, "limitExceeded");
		ElsIf selection.minutesPassed < 15 Then
			errorDescription	= Service.getErrorDescription(language, "messageCanNotSent");
		EndIf;				
	EndIf;
	
	Return errorDescription;

EndFunction 

Function runRequest(parameters, body, address = "") Export
	headers = New Map();
	headers.Insert("Content-Type", "application/json");	
	connection = New HTTPConnection(parameters.server, parameters.port, parameters.account, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.UseOSAuthentication);
	request = New HTTPRequest(parameters.URL + parameters.requestReceiver
		+ parameters.parametersFromURL, headers);
	If body <> "" Then
		request.SetBodyFromString(body);
	EndIf;
	response	= ?(parameters.HTTPRequestType = Enums.HTTPRequestTypes.GET, connection.Get(request), connection.Post(request));
	If address = "" Then
		Return response;
	Else
		PutToTempStorage(New Structure("statusCode, answerBody", response.statusCode, response.GetBodyAsString()), address);
	EndIf;
EndFunction

Function runRequestBackground(parameters, body) Export
	address	= PutToTempStorage("");
	array = New Array();
	array.Add(parameters);	
	array.Add(body);
	array.Add(address);	
	Return New Structure("address, BJ", address, BackgroundJobs.Execute("Service.runRequest", array, New UUID()));
EndFunction

Function checkBackgroundJobs(array) Export
	answer = New Structure();
	minStatusCode = 600;
	For Each struct In array Do
		If struct.BJ.State = BackgroundJobState.Active Then
			backgroundJob = struct.BJ.WaitForExecutionCompletion(25);
			If backgroundJob.State <> BackgroundJobState.Active Then
				response = GetFromTempStorage(struct.address);
				minStatusCode = Min(minStatusCode, response.statusCode);				
				answer.Insert(struct.attribute, HTTP.decodeJSON(response.answerBody));
			EndIf;
		Else			
			response = GetFromTempStorage(struct.address);
			minStatusCode = Min(minStatusCode, response.statusCode);				
			answer.Insert(struct.attribute, HTTP.decodeJSON(response.answerBody));
		EndIf;	
	EndDo;
	Return New Structure("statusCode, answerBody", minStatusCode, HTTP.encodeJSON(answer));
EndFunction

Function getAmountOfNumbers(number) Export	
	str	= StrReplace(number, Chars.NBSp, "");
	res	= 0;	
	For i = 1 To StrLen(str) Do
		res = res + Number(Mid(str, i, 1));		
	EndDo;
	Return res;
EndFunction

Function getStructCopy(val struct) Export
	structNew	= New Structure();	
	For Each item In struct Do
		If TypeOf(item.value) = Type("Structure") Then
			value = getStructCopy(item.value);
		ElsIf TypeOf(item.value) = Type("FixedStructure") Then
			value = getStructCopy(item.value);	
		Else
			value = item.value;
		EndIf;
		structNew.Insert(item.key, value);	
	EndDo;
	Return structNew;
EndFunction

Procedure logRequestBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);
	BackgroundJobs.Execute("Service.logRequest", array, New UUID());
EndProcedure
	
Procedure logAcquiringBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);
	BackgroundJobs.Execute("Service.logAcquiring", array, New UUID());
EndProcedure
	
Procedure logRequest(parameters) Export
	record = Catalogs.logs.CreateItem();
	record.period = ToUniversalTime(CurrentDate());
	If parameters.Property("tokenContext") Then
		record.token = parameters.tokenContext.token;
		record.user = parameters.tokenContext.user;	
	EndIf;
	record.requestName = parameters.requestName;
	record.duration = parameters.duration;
	record.isError = parameters.isError;

	requestBody = """Headers"":" + Chars.LF + parameters.headersJSON + Chars.LF
		+ """Body"":" + Chars.LF
		+ ?(parameters.requestName = "imagePOST", "", parameters.requestBody);

	record.request = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(requestBody, New Deflation(9)))));
	record.response = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(parameters.answerBody, New Deflation(9)))));
	
//	If parameters.compressAnswer Then
//		record.request = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(requestBody, New Deflation(9)))));
//	Else
//		record.requestBody = requestBody;
//	EndIf;
//	If Not parameters.notSaveAnswer Or parameters.isError Or parameters.underControl Then
//		If parameters.compressAnswer Then
//			record.response = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(parameters.answerBody, New Deflation(9)))));
//		Else
//			record.responseBody = ?(parameters.isError, parameters.errorDescription.description, parameters.answerBody);
//		EndIf;
//	EndIf;
	record.Write();
EndProcedure

Procedure logAcquiring(parameters) Export
	record = Catalogs.acquiringLogs.CreateItem();
	record.period = ToUniversalTime(CurrentDate());
	record.order = parameters.order;		
	record.requestName = parameters.requestName;
	If parameters.Property("errorCode") Then
		record.isError = parameters.errorCode <> "";
	EndIf;
	If parameters.Property("requestBody") Then
		record.requestBody = parameters.requestBody;
	EndIf;	
	If parameters.Property("response") Then			
		If TypeOf(parameters.response) = Type("Structure") Then
			record.responseBody = HTTP.encodeJSON(parameters.response);
		Else
			If record.isError Then
				record.responseBody = parameters.errorCode + " " + parameters.errorDescription;
			Else
				record.responseBody = "" + parameters.response;
			EndIf;		
		EndIf;
	EndIf;
	record.Write();
EndProcedure

Procedure informationSourceAlert() Export
	
	headers	= New Map();
	headers.Insert("Content-Type", "application/json");
		
	query	= New Query("SELECT TOP 100
	|	usersChanges.Ref.holding AS holding,
	|	usersChanges.Ref AS user,
	|	CASE
	|		WHEN tokensEmployee.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS employee,
	|	CASE
	|		WHEN tokensCustomer.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS customer
	|FROM
	|	Catalog.users.Changes AS usersChanges
	|		LEFT JOIN Catalog.tokens AS tokensEmployee
	|		ON (usersChanges.Ref = tokensEmployee.user)
	|			AND (tokensEmployee.appType = VALUE(Enum.appTypes.Employee))
	|			AND (tokensEmployee.lockDate = DATETIME(1, 1, 1))
	|		LEFT JOIN Catalog.tokens AS tokensCustomer
	|		ON (usersChanges.Ref = tokensCustomer.user)
	|			AND (tokensCustomer.appType = VALUE(Enum.appTypes.Customer))
	|			AND (tokensCustomer.lockDate = DATETIME(1, 1, 1))
	|WHERE
	|	usersChanges.Node = &Node
	|TOTALS BY
	|	holding");
	
	node	= GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn);
	query.SetParameter("node", node);
	selectHolding	= query.Execute().Select(QueryResultIteration.ByGroups);
	
	While selectHolding.next() Do		
		queryStruct = HTTP.GetRequestStructure("registerAccount", selectHolding.holding);		
		If queryStruct.count() > 0 Then			
			select = selectHolding.Select();
			While select.next() Do
				structHTTPRequest = New Structure();
				structHTTPRequest.Insert("userId", XMLString(select.user));
				structHTTPRequest.Insert("language", "en");
				structHTTPRequest.Insert("employee", select.employee);
				structHTTPRequest.Insert("customer", select.customer);
				HTTPConnection = New HTTPConnection(queryStruct.server, , queryStruct.user, queryStruct.password, , queryStruct.timeout, ?(queryStruct.secureConnection, New OpenSSLSecureConnection(), Undefined), queryStruct.UseOSAuthentication);
				HTTPRequest = New HTTPRequest(queryStruct.URL
					+ queryStruct.requestReceiver, headers);
				HTTPRequest.SetBodyFromString(HTTP.encodeJSON(structHTTPRequest));
				response = HTTPConnection.Post(HTTPRequest);
				If response.StatusCode = 200 Then
					ExchangePlans.DeleteChangeRecords(node, select.user);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
			
EndProcedure

Procedure CheckTokenValid() Export
	
	query	= New Query();
	query.text	= "SELECT
	|	tokens.Ref AS token,
	|	tokens.deviceToken AS deviceToken,
	|	CASE
	|		WHEN tokens.systemType = VALUE(Enum.systemTypes.Android)
	|			THEN ""GCM""
	|		ELSE ""APNS""
	|	END AS SubscriberType,
	|	tokens.chain AS chain,
	|	tokens.appType AS appType,
	|	tokens.systemType AS systemType
	|INTO ВТ
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.lockDate = DATETIME(1, 1, 1)
	|	AND CASE
	|		WHEN tokens.changeDate = DATETIME(1, 1, 1)
	|			THEN tokens.createDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -7)
	|		ELSE tokens.changeDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -7)
	|	END
	|	AND tokens.appType = VALUE(enum.appTypes.Customer)
	|
	|UNION ALL
	|
	|SELECT
	|	tokens.Ref AS token,
	|	tokens.deviceToken AS deviceToken,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.lockDate = DATETIME(1, 1, 1)
	|	AND CASE
	|		WHEN tokens.changeDate = DATETIME(1, 1, 1)
	|			THEN tokens.createDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -30)
	|		ELSE tokens.changeDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -30)
	|	END
	|	AND tokens.appType = VALUE(enum.appTypes.Web)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ВТ.token AS token,
	|	ВТ.deviceToken AS deviceToken,
	|	ВТ.SubscriberType AS SubscriberType,
	|	ВТ.systemType AS systemType,
	|	ISNULL(appCertificates.certificate, appCertificatesCommon.certificate) AS certificate,
	|	ВТ.appType AS appType
	|FROM
	|	ВТ AS ВТ
	|		LEFT JOIN InformationRegister.appCertificates AS appCertificates
	|		ON ВТ.chain = appCertificates.chain
	|		AND ВТ.appType = appCertificates.appType
	|		AND ВТ.systemType = appCertificates.systemType
	|		LEFT JOIN InformationRegister.appCertificates AS appCertificatesCommon
	|		ON appCertificatesCommon.chain = VALUE(Справочник.chains.ПустаяСсылка)
	|		AND ВТ.appType = appCertificatesCommon.appType
	|		AND ВТ.systemType = appCertificatesCommon.systemType";
	
	query.SetParameter("currentTime", ToUniversalTime(CurrentDate()));
		
	select = query.Execute().Select();
		
	While select.Next() Do
		If select.deviceToken <> "" and select.appType = enums.appTypes.Customer Then
			pushStruct = New Structure();
			pushStruct.Insert("title", "");
			pushStruct.Insert("text", "");
			pushStruct.Insert("action", "registerDevice");
			pushStruct.Insert("objectId", "");
			pushStruct.Insert("objectType", "");
			pushStruct.Insert("noteId", "");
			pushStruct.Insert("deviceToken", select.deviceToken);
			pushStruct.Insert("SubscriberType", select.SubscriberType);
			pushStruct.Insert("title", "");
			pushStruct.Insert("Badge", 0);
			pushStruct.Insert("systemType", select.systemType);
			pushStruct.Insert("certificate", select.certificate);
			pushStruct.Insert("token", select.token);
			pushStruct.Insert("informationChannel", "");
		    pushStruct.Insert("message", Catalogs.messages.EmptyRef());
		    pushStatus = Messages.sendPush(pushStruct);
		    If pushStatus <> Enums.messageStatuses.sent Then
		    	Token.block(select.token);
		    EndIf;
		Else
			Token.block(select.token);
		EndIf;
   EndDo;	
	
	//Блокируем Token в МП тренера по уволенным сотрудникам	
	query	= New Query;
	query.text = "select
	|	tokens.ref as token
	|from
	|	Catalog.tokens as tokens
	|where
	|	tokens.appType = value(Enum.appTypes.Employee)
	|	И tokens.lockDate = datetime(1, 1, 1)
	|	И tokens.user.userType <> ""employee""";
	
	select	= query.Execute().Select();
	While select.Next() do
		Token.block(select.token);
	endDo;		
	
EndProcedure

Процедура РассчитатьПоказатели() Экспорт
	
	//Расчет показателей по дням
	Дни				= Новый Массив;
	ПредыдущийДень	= НачалоДня(УниверсальноеВремя(ТекущаяДата()) - 86400);
	
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ ПЕРВЫЕ 1
	             	  |	РегистраторДвижений.Дата КАК ДеньРасчетаПоказателей
	             	  |ИЗ
	             	  |	Документ.РегистраторДвижений КАК РегистраторДвижений
	             	  |ГДЕ
	             	  |	РегистраторДвижений.ПериодОтчета = ЗНАЧЕНИЕ(Перечисление.reportPeriods.day)
	             	  |
	             	  |УПОРЯДОЧИТЬ ПО
	             	  |	ДеньРасчетаПоказателей УБЫВ";
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
		Дни.Добавить(ПредыдущийДень);
	Else
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		ДеньРасчетаПоказателей	= Выборка.ДеньРасчетаПоказателей;
		Пока ДеньРасчетаПоказателей < ПредыдущийДень Цикл
			ДеньРасчетаПоказателей	= ДеньРасчетаПоказателей + 86400; 
			Дни.Добавить(ДеньРасчетаПоказателей);
		КонецЦикла;		
	EndIf;	
	
	Service.РассчитатьПоказателиПоДням(Дни);	
	
	//Расчет показателей по месяцам
	Месяцы			= Новый Массив;
	ТекущийМесяц	= НачалоМесяца(УниверсальноеВремя(ТекущаяДата()));	
	
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ ПЕРВЫЕ 1
	             	  |	РегистраторДвижений.Дата КАК МесяцРасчетаПоказателей,
	             	  |	РегистраторДвижений.Ссылка КАК Ссылка
	             	  |ИЗ
	             	  |	Документ.РегистраторДвижений КАК РегистраторДвижений
	             	  |ГДЕ
	             	  |	РегистраторДвижений.ПериодОтчета = ЗНАЧЕНИЕ(Перечисление.reportPeriods.month)
	             	  |
	             	  |УПОРЯДОЧИТЬ ПО
	             	  |	МесяцРасчетаПоказателей УБЫВ";
	
	РезультатЗапроса = пЗапрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда		
		Месяцы.Добавить(ТекущийМесяц);
	Else
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		МесяцРасчетаПоказателей	= Выборка.МесяцРасчетаПоказателей;		
		Месяцы.Добавить(МесяцРасчетаПоказателей);		
		Пока МесяцРасчетаПоказателей < ТекущийМесяц Цикл
			МесяцРасчетаПоказателей	= ДобавитьМесяц(МесяцРасчетаПоказателей, 1);
			Месяцы.Добавить(МесяцРасчетаПоказателей);
		КонецЦикла;		
	EndIf;	
	
	Service.РассчитатьПоказателиПоМесяцам(Месяцы);
	
КонецПроцедуры	
	
Процедура РассчитатьПоказателиПоДням(Дни) Экспорт
	Для Каждого День Из Дни Цикл
		РассчитатьПоказателиЗаДень(День);	
	КонецЦикла;
КонецПроцедуры

Процедура РассчитатьПоказателиЗаДень(День) Экспорт
	
	Набор	= РегистрыНакопления.ПоказателиПользователей.СоздатьНаборЗаписей();
	Набор.Отбор.Регистратор.Установить(GetRecorder(День, Enums.reportPeriods.day));
	
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ
	             	  |	Logs.period КАК period,
	             	  |	Logs.requestName КАК requestName,
	             	  |	Logs.token КАК token,
	             	  |	Logs.token.account КАК account,
	             	  |	Logs.token.holding КАК holding,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.logs КАК Logs
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО Logs.token.appType = АналитикиПриложений.appType
	             	  |			И Logs.token.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	Logs.period МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |	И НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	ВТ_ИсторияЗапросов.period КАК period,
	             	  |	РАЗНОСТЬДАТ(ВТ_ИсторияЗапросов.period, МИНИМУМ(ЕСТЬNULL(ВТ_ИсторияЗапросов1.period, &Завтра)), МИНУТА) КАК Дельта,
	             	  |	ВТ_ИсторияЗапросов.requestName КАК requestName,
	             	  |	ВТ_ИсторияЗапросов.token КАК token,
	             	  |	ВТ_ИсторияЗапросов.account КАК account,
	             	  |	ВТ_ИсторияЗапросов.holding КАК holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_Сеансы
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов1
	             	  |		ПО ВТ_ИсторияЗапросов.token = ВТ_ИсторияЗапросов1.token
	             	  |			И ВТ_ИсторияЗапросов.period < ВТ_ИсторияЗапросов1.period
	             	  |ГДЕ
	             	  |	ВТ_ИсторияЗапросов.token <> ЗНАЧЕНИЕ(Справочник.tokens.ПустаяСсылка)
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.period,
	             	  |	ВТ_ИсторияЗапросов.requestName,
	             	  |	ВТ_ИсторияЗапросов.token,
	             	  |	ВТ_ИсторияЗапросов.account,
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала КАК period,
	             	  |	ВТ_Сеансы.holding КАК holding,
	             	  |	ВТ_Сеансы.АналитикаПриложений КАК АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Сеансов) КАК Показатель,
	             	  |	&ПериодОтчета КАК ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_Сеансы.token) КАК quantity
	             	  |ИЗ
	             	  |	ВТ_Сеансы КАК ВТ_Сеансы
	             	  |ГДЕ
	             	  |	ВТ_Сеансы.Дельта > 30
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_Сеансы.holding,
	             	  |	ВТ_Сеансы.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Регистраций),
	             	  |	&ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.account)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |ГДЕ
	             	  |	ВТ_ИсторияЗапросов.account.registrationDate МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.АктивныхПользователей),
	             	  |	&ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.account)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.ЗаписейНаСобытие),
	             	  |	&ПериодОтчета,
	             	  |	СУММА(ВЫБОР
	             	  |			КОГДА ВТ_ИсторияЗапросов.requestName = ""employeeAddChangeBooking""
	             	  |				ТОГДА 1
	             	  |			Else 0
	             	  |		КОНЕЦ)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ИМЕЮЩИЕ
	             	  |	СУММА(ВЫБОР
	             	  |			КОГДА ВТ_ИсторияЗапросов.requestName = ""employeeAddChangeBooking""
	             	  |				ТОГДА 1
	             	  |			Else 0
	             	  |		КОНЕЦ) > 0
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	Токены.holding,
	             	  |	АналитикиПриложений.Ссылка,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Пользователей),
	             	  |	&ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ Токены.account)
	             	  |ИЗ
	             	  |	Справочник.tokens КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО Токены.appType = АналитикиПриложений.appType
	             	  |			И Токены.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |	И Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.createDate <= &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	Токены.holding,
	             	  |	АналитикиПриложений.Ссылка";
	
	пЗапрос.УстановитьПараметр("ДатаНачала", НачалоДня(День));
	пЗапрос.УстановитьПараметр("ДатаОкончания", КонецДня(День));
	пЗапрос.УстановитьПараметр("Завтра", КонецДня(День) + 86400);
	пЗапрос.УстановитьПараметр("ПериодОтчета", Enums.reportPeriods.day);
	Набор.Загрузить(пЗапрос.Выполнить().Выгрузить());
	Набор.Записать();
		
КонецПроцедуры

Процедура РассчитатьПоказателиПоМесяцам(Месяцы) Экспорт
	Для Каждого Месяц Из Месяцы Цикл
		РассчитатьПоказателиЗаМесяц(Месяц);	
	КонецЦикла;
КонецПроцедуры

Процедура РассчитатьПоказателиЗаМесяц(Месяц) Экспорт
	
	Набор	= РегистрыНакопления.ПоказателиПользователей.СоздатьНаборЗаписей();
	Набор.Отбор.Регистратор.Установить(GetRecorder(Месяц, Enums.reportPeriods.month));
	
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ
	             	  |	Logs.period КАК period,
	             	  |	Logs.requestName КАК requestName,
	             	  |	Logs.token КАК token,
	             	  |	Logs.token.account КАК account,
	             	  |	Logs.token.holding КАК holding,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.logs КАК Logs
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО Logs.token.appType = АналитикиПриложений.appType
	             	  |			И Logs.token.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	Logs.period МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |	И НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала КАК period,
	             	  |	ВТ_ИсторияЗапросов.holding КАК holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений КАК АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.АктивныхПользователей) КАК Показатель,
	             	  |	&ПериодОтчета КАК ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.account) КАК quantity
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.holding,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	Токены.holding,
	             	  |	АналитикиПриложений.Ссылка,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Пользователей),
	             	  |	&ПериодОтчета,
	             	  |	quantity(РАЗЛИЧНЫЕ Токены.account)
	             	  |ИЗ
	             	  |	Справочник.tokens КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО Токены.appType = АналитикиПриложений.appType
	             	  |			И Токены.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |	И Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.createDate <= &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	Токены.holding,
	             	  |	АналитикиПриложений.Ссылка
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ПоказателиПользователейОбороты.holding,
	             	  |	ПоказателиПользователейОбороты.АналитикаПриложений,
	             	  |	ПоказателиПользователейОбороты.Показатель,
	             	  |	&ПериодОтчета,
	             	  |	ПоказателиПользователейОбороты.КоличествоОборот
	             	  |ИЗ
	             	  |	РегистрНакопления.ПоказателиПользователей.Обороты(
	             	  |			&ДатаНачала,
	             	  |			&ДатаОкончания,
	             	  |			,
	             	  |			ПериодОтчета = &ПериодОтчетаДень
	             	  |				И Показатель <> ЗНАЧЕНИЕ(Перечисление.Показатели.АктивныхПользователей)
	             	  |				И Показатель <> ЗНАЧЕНИЕ(Перечисление.Показатели.Пользователей)) КАК ПоказателиПользователейОбороты";
	
	пЗапрос.УстановитьПараметр("ДатаНачала", НачалоМесяца(Месяц));
	пЗапрос.УстановитьПараметр("ДатаОкончания", КонецМесяца(Месяц));	
	пЗапрос.УстановитьПараметр("ПериодОтчета", Enums.reportPeriods.month);
	пЗапрос.УстановитьПараметр("ПериодОтчетаДень", Enums.reportPeriods.day);
	Набор.Загрузить(пЗапрос.Выполнить().Выгрузить());
	Набор.Записать();
		
КонецПроцедуры



