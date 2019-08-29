Function getErrorDescription(language = "", result = "",
		description = "") Export

	errorDescription = New Structure("result, description", result, description);

	If description = "" Then
		If result = "requestError" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Не определен запрос");
			Else
				errorDescription.Insert("description", "No request");
			EndIf;
		ElsIf result = "brandError" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Не определен бренд");
			Else
				errorDescription.Insert("description", "No brand");
			EndIf;	
		ElsIf result = "userNotIdentified" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Пользователь не идентифицирован");
			Else
				errorDescription.Insert("description", "account is not identified");
			EndIf;
		ElsIf result = "userNotfound" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Пользователь не найден");
			Else
				errorDescription.Insert("description", "account is not found");
			EndIf;
		ElsIf result = "tokenExpired" Then
			If language = "ru" Then
				errorDescription.Insert("description", "токен просрочен");
			Else
				errorDescription.Insert("description", "Token expired");
			EndIf;
		ElsIf result = "passwordError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан пароль");
			Else
				errorDescription.Insert("description", "No account password");
			EndIf;
		ElsIf result = "passwordNotCorrect" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Неверный пароль");
			Else
				errorDescription.Insert("description", "Password is not correct");
			EndIf;		
		ElsIf result = "passwordExpired" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Пароль просрочен");
			Else
				errorDescription.Insert("description", "Password expired");
			EndIf;
		ElsIf result = "passwordRequired" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Необходимо получить пароль");
			Else
				errorDescription.Insert("description", "Password is required");
			EndIf;	
		ElsIf result = "appTokenExpired" Then
			If language = "ru" Then
				errorDescription.Insert("description", "срок действия токена приложения истек");
			Else
				errorDescription.Insert("description", "application token expired");
			EndIf;
		ElsIf result = "chainCodeError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан код сети");
			Else
				errorDescription.Insert("description", "No chain code");
			EndIf;
		ElsIf result = "authkeyError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан код авторизации");
			Else
				errorDescription.Insert("description", "No auth-key");
			EndIf;
		ElsIf result = "appTypeError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан тип приложения");
			Else
				errorDescription.Insert("description", "No app type");
			EndIf;
		ElsIf result = "deviceTokenError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан токен устройства");
			Else
				errorDescription.Insert("description", "No device token");
			EndIf;
		ElsIf result = "deviceModelError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указана модель устройства");
			Else
				errorDescription.Insert("description", "No device model");
			EndIf;	
		ElsIf result = "tokenError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан токен");
			Else
				errorDescription.Insert("description", "No token");
			EndIf;
		ElsIf result = "systemTypeError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан тип ОС");
			Else
				errorDescription.Insert("description", "No system type");
			EndIf;
		ElsIf result = "systemVersionError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указана версия ОС");
			Else
				errorDescription.Insert("description", "No system version");
			EndIf;
		ElsIf result = "appVersionError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указана версия приложения");
			Else
				errorDescription.Insert("description", "No app version");
			EndIf;
		ElsIf result = "causesError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не заполнены причины отмены");
			Else
				errorDescription.Insert("description", "No causes");
			EndIf;
		ElsIf result = "staffOnly" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Только для сотрудников");
			Else
				errorDescription.Insert("description", "staff only");
			EndIf;
		ElsIf result = "urlError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан url");
			Else
				errorDescription.Insert("description", "No url");
			EndIf;
		ElsIf result = "routesError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указаны каналы информирования");
			Else
				errorDescription.Insert("description", "No information routes");
			EndIf;
		ElsIf result = "messagesError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Нет сообщений");
			Else
				errorDescription.Insert("description", "No messages");
			EndIf;
		ElsIf result = "phoneError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан телефон");
			Else
				errorDescription.Insert("description", "no account phone");
			EndIf;
		ElsIf result = "noteIdError" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указано уведомление");
			Else
				errorDescription.Insert("description", "no notification");
			EndIf;
		ElsIf result = "limitExceeded" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Превышен лимит сообщений");
			Else
				errorDescription.Insert("description", "Message limit exceeded");
			EndIf;
		ElsIf result = "noValidRequest" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "недействительный запрос");
			Else
				errorDescription.Insert("description", "not valid request");
			EndIf;
		ElsIf result = "messageCanNotSent" Then
			Если language = "ru" Then
				errorDescription.Insert("description", "Повторное сообщение можно отправить через 15 минут");
			Else
				errorDescription.Insert("description", "Message can be sent in 15 minutes");
			EndIf;
		EndIf;
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

	errorDescription	= Service.getErrorDescription();
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

Function createCatalogItems(requestName, holding, requestStruct, owner = Undefined) Export

	attributesStruct	= Service.attributesStructure(requestName);
	requestStruct		= requestStruct;
	items 				= New Array();
		
	If TypeOf(requestStruct) = Type("Array") Then
		For Each requestParameter In requestStruct Do		
			catalogRef		= Catalogs[attributesStruct.mdObjectName].GetRef(New UUID(requestParameter.uid));
			catalogObject	= catalogRef.GetObject();			
			If catalogObject = Undefined Then
				catalogObject = Catalogs[attributesStruct.mdObjectName].CreateItem();
				catalogObject.SetNewObjectRef(catalogRef);
				catalogObject.SetNewCode();
				For Each attribute In attributesStruct.attributesTableForNewItem Do
					catalogObject[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);					
				EndDo;
			EndIf;
			For Each attribute In attributesStruct.attributesTable Do			
				If attribute.type = "valueTable" Then
					catalogObject[attribute.key].Clear();
					For Each item In requestParameter[attribute.value] Do
						newRow = catalogObject[attribute.key].Add();
						For Each tableProperty In attributesStruct.mdStruct[attribute.key] Do
							If tableProperty.type = "ref" Then
								For Each refProperty In attributesStruct.mdStruct[tableProperty.key] Do
									newRow[tableProperty.key] = Catalogs[refProperty.key].GetRef(New UUID(item[tableProperty.Значение][refProperty.value]));
								EndDo;
							Else
								newRow[tableProperty.key] = item[tableProperty.value];
							EndIf;
						EndDo;
					EndDo;
				ElsIf attribute.type = "ref" Then
					For Each refProperty In attributesStruct.mdStruct[attribute.key] Do
						catalogObject[attribute.key] = Catalogs[refProperty.key].GetRef(New UUID(requestParameter[attribute.value][refProperty.value]));
					EndDo;
				Else
					catalogObject[attribute.key] = XMLValue(Type(attribute.type), requestParameter[attribute.value]);
				EndIf;
			EndDo;
			If attributesStruct.mdObjectName <> "matchingRequestsInformationSources" Then
				If owner <> Undefined Then
					catalogObject.owner = owner;
				EndIf;
				If attributesStruct.mdObjectName <> "accounts" Then
					catalogObject.holding = holding;
				EndIf;
				If attributesStruct.mdObjectName = "users" Then
					catalogObject.description = "" + owner + " (" + holding + ")";	
				EndIf;	
				catalogObject.registrationDate = ToUniversalTime(CurrentDate());
			EndIf;
			catalogObject.Write();
			items.Add(catalogObject.Ref);			
		EndDo;
	EndIf;

	Return items;

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

Function attributesStructure(requestName) Export

	attributesTable = New ValueTable;
	attributesTable.Columns.Add("key");
	attributesTable.Columns.Add("value");
	attributesTable.Columns.Add("type");

	attributesTableForNewItem = New ValueTable;
	attributesTableForNewItem.Columns.Add("key");
	attributesTableForNewItem.Columns.Add("value");
	attributesTableForNewItem.Columns.Add("type");

	mdStruct = New Structure();
	mdObjectName = "";

	If requestName = "addChangeAccounts" Then

		mdObjectName = "accounts";
		addRowInAttributesTable(attributesTable, "code", "phoneNumber", "string");
		addRowInAttributesTable(attributesTable, "firstName", "firstName", "string");
		addRowInAttributesTable(attributesTable, "secondName", "secondName", "string");
		addRowInAttributesTable(attributesTable, "lastName", "lastName", "string");
		addRowInAttributesTable(attributesTable, "birthday", "birthdayDate", "date");
		addRowInAttributesTable(attributesTable, "gender", "gender", "string");		
		addRowInAttributesTable(attributesTable, "email", "email", "string");
		
	elsIf requestName = "addChangeUsers" Then

		mdObjectName = "users";		
		addRowInAttributesTable(attributesTable, "userCode", "cid", "string");		
		addRowInAttributesTable(attributesTable, "userType", "userType", "string");
		addRowInAttributesTable(attributesTable, "barCode", "barcode", "string");
		addRowInAttributesTable(attributesTable, "notSubscriptionEmail", "noSubscriptionEmail", "boolean");
		addRowInAttributesTable(attributesTable, "notSubscriptionSms", "noSubscriptionSms", "boolean");
				
	ElsIf requestName = "addGyms" Then

		mdObjectName = "gyms";
		addRowInAttributesTable(attributesTable, "Наименование", "name", "string");
		addRowInAttributesTable(attributesTable, "address", "gymAddress", "string");
		addRowInAttributesTable(attributesTable, "segment", "division", "string");
		addRowInAttributesTable(attributesTable, "latitude", "latitude", "number");
		addRowInAttributesTable(attributesTable, "longitude", "longitude", "number");
		addRowInAttributesTable(attributesTable, "type", "type", "string");
		addRowInAttributesTable(attributesTable, "departmentWorkSchedule", "departments", "valueTable");
		addRowInAttributesTable(attributesTable, "city", "city", "ref");

		attributesTableDepartmentWorkSchedule = New ValueTable();;
		attributesTableDepartmentWorkSchedule.Columns.Add("key");
		attributesTableDepartmentWorkSchedule.Columns.Add("value");
		attributesTableDepartmentWorkSchedule.Columns.Add("type");

		addRowInAttributesTable(attributesTableDepartmentWorkSchedule, "department", "name", "string");
		addRowInAttributesTable(attributesTableDepartmentWorkSchedule, "phone", "phone", "string");
		addRowInAttributesTable(attributesTableDepartmentWorkSchedule, "weekdaysTime", "weekdaysTime", "string");
		addRowInAttributesTable(attributesTableDepartmentWorkSchedule, "holidaysTime", "holidaysTime", "string");

		cityStruct = New Structure();
		cityStruct.Insert("cities", "id");

		mdStruct.Insert("departmentWorkSchedule", attributesTableDepartmentWorkSchedule);
		mdStruct.Insert("city", cityStruct);

	ElsIf requestName = "addCities" Then

		mdObjectName = "cities";
		addRowInAttributesTable(attributesTable, "description", "name", "string");

	ElsIf requestName = "addCancelcauses" Then

		mdObjectName = "cancellationReasons";
		addRowInAttributesTable(attributesTable, "description", "name", "string");

	ElsIf requestName = "addRequest" Then

		mdObjectName = "matchingRequestsInformationSources";
		addRowInAttributesTable(attributesTable, "code", "code", "string");
		addRowInAttributesTable(attributesTable, "performBackground", "performBackground", "boolean");
		addRowInAttributesTable(attributesTable, "notSaveAnswer", "notSaveAnswer", "boolean");
		addRowInAttributesTable(attributesTable, "compressAnswer", "compressAnswer", "boolean");
		addRowInAttributesTable(attributesTable, "staffOnly", "staffOnly", "boolean");

		addRowInAttributesTable(attributesTable, "informationSources", "informationSources", "valueTable");

		attributesTableInformationSources = New ТаблицаЗначений;
		attributesTableInformationSources.Columns.Add("key");
		attributesTableInformationSources.Columns.Add("value");
		attributesTableInformationSources.Columns.Add("type");

		addRowInAttributesTable(attributesTableInformationSources, "atribute", "atribute", "string");
		addRowInAttributesTable(attributesTableInformationSources, "performBackground", "performBackground", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "notSaveAnswer", "notSaveAnswer", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "compressAnswer", "compressAnswer", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "staffOnly", "staffOnly", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "notUse", "notUse", "boolean");
		addRowInAttributesTable(attributesTableInformationSources, "requestSource", "requestSource", "string");
		addRowInAttributesTable(attributesTableInformationSources, "requestReceiver", "requestReceiver", "string");
		addRowInAttributesTable(attributesTableInformationSources, "informationSource", "informationSource", "ref");

		informationSourceStruct = New Structure();
		informationSourceStruct.Insert("informationSources", "uid");

		mdStruct.Insert("informationSources", attributesTableInformationSources);
		mdStruct.Insert("informationSource", informationSourceStruct);

	EndIf;

	Return New Structure("mdObjectName, attributesTable, attributesTableForNewItem, mdStruct", mdObjectName, attributesTable, attributesTableForNewItem, mdStruct);

EndFunction

Function getAmountOfNumbers(number) Export	
	str	= StrReplace(number, Chars.NBSp, "");
	res	= 0;	
	For i = 1 To StrLen(str) Do
		res = res + Number(Mid(str, i, 1));		
	EndDo;
	Return res;
EndFunction

Function getStructCopy(struct) Export
	structNew	= New Structure();	
	For Each element In struct Do
		structNew.Insert(element.key, element.value);	
	EndDo;
	Return structNew;
EndFunction

Procedure logRequestBackground(parameters) Export //duration, requestName, request, response, isError, token, account)Экспорт
	array	= New Array();
	array.Add(Parameters);
	BackgroundJobs.Execute("Service.logRequest", array, New UUID());
EndProcedure
	
Procedure logRequest(parameters) Export
	record = Catalogs.logs.CreateItem();
	record.period = ToUniversalTime(CurrentDate());
	record.token = parameters.tokenСontext.token;
	record.account = parameters.tokenСontext.account;
	record.requestName = parameters.requestName;
	record.duration = parameters.duration;
	record.isError = parameters.isError;

	requestBody = """Headers"":" + Chars.LF + parameters.headersJSON + Chars.LF
		+ """Body"":" + Chars.LF + parameters.requestBody;
	If parameters.compressAnswer Then
		record.request = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(requestBody, New Deflation(9)))));
	Else
		record.requestBody = requestBody;
	EndIf;
	If Not parameters.notSaveAnswer Or parameters.isError Then
		If parameters.compressAnswer Then
			record.response = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(parameters.answerBody, New Deflation(9)))));
		Else
			record.responseBody = parameters.answerBody;
		EndIf;
	EndIf;
	record.Write();
EndProcedure

Procedure addRowInAttributesTable(attributesTable, key, value,
		type)
	newRow			= attributesTable.Add();
	newRow.key		= key;
	newRow.value	= value;
	newRow.type		= type;
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

Процедура ОповеститьИсточникИнформации() Экспорт
	
	Заголовки	= Новый Соответствие;
	Заголовки.Вставить("Content-Type", "application/json");
		
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ ПЕРВЫЕ 100
	             	  |	ПользователиИзменения.Ссылка КАК account,
	             	  |	Токены.appType КАК appType,
	             	  |	МИНИМУМ(Токены.lockDate) КАК lockDate,
	             	  |	Токены.holding КАК holding
	             	  |ИЗ
	             	  |	Справочник.accounts.Изменения КАК ПользователиИзменения
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.tokens КАК Токены
	             	  |		ПО ПользователиИзменения.Ссылка = Токены.account
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ПользователиИзменения.Ссылка,
	             	  |	Токены.chain,
	             	  |	Токены.appType,
	             	  |	Токены.holding";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	
	Узел	= GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn);
	
	Пока Выборка.Следующий() Цикл	
		СтруктураЗапроса = HTTP.GetRequestStructure(?(Выборка.lockDate = Дата(1,1,1), "registerAccount", "unregisterAccount"), Выборка.Холдинг);
		Если СтруктураЗапроса.Количество() > 0 Тогда			
			СтруктураHTTPЗапроса	= Новый Структура;
			СтруктураHTTPЗапроса.Вставить("userId", XMLСтрока(Выборка.Пользователь));
			СтруктураHTTPЗапроса.Вставить("language", "en");
			СтруктураHTTPЗапроса.Вставить("appType", XMLСтрока(Выборка.ВидПриложения));			
			HTTPСоединение	= Новый HTTPСоединение(СтруктураЗапроса.server,, СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.password,, СтруктураЗапроса.timeout, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.UseOSAuthentication);
			ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL + СтруктураЗапроса.Приемник, Заголовки);
			ЗапросHTTP.УстановитьТелоИзСтроки(HTTP.encodeJSON(СтруктураHTTPЗапроса));			
			ОтветHTTP	= HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
			Если ОтветHTTP.КодСостояния = 200 Тогда
				ПланыОбмена.УдалитьРегистрациюИзменений(Узел, Выборка.Пользователь);
			EndIf;
		Else
			ПланыОбмена.УдалитьРегистрациюИзменений(Узел, Выборка.Пользователь);
		EndIf;	
	КонецЦикла;
	
КонецПроцедуры

Процедура ПроверитьАктуальностьТокенов() Экспорт
	
	//Проверка актуальности токенов для ОС Android	
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ 
	             	  |	Токены.Ссылка КАК token,
	             	  |	РАЗНОСТЬДАТ(ЕСТЬNULL(ЗарегистрированныеУстройства.recordDate, ДАТАВРЕМЯ(1, 1, 1)), &ТекущаяДата, ДЕНЬ) КАК АктуальностьЗаписи,
	             	  |	ЕСТЬNULL(ЗарегистрированныеУстройства.deviceToken, """") КАК deviceToken,
	             	  |	""GCM"" КАК ТипПодписчика,
	             	  |	Токены.chain КАК chain,
	             	  |	Токены.appType КАК appType,
	             	  |	Токены.systemType КАК systemType
	             	  |ПОМЕСТИТЬ ВТ
	             	  |ИЗ
	             	  |	Справочник.tokens КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.registeredDevices КАК ЗарегистрированныеУстройства
	             	  |		ПО (ЗарегистрированныеУстройства.token = Токены.Ссылка)
	             	  |ГДЕ
	             	  |	Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.systemType = ЗНАЧЕНИЕ(Перечисление.systemTypes.Android)
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ ПЕРВЫЕ 100
	             	  |	ЕСТЬNULL(СертификатПриложенияДляСети.certificate, СертификатПриложенияОбщий.certificate) КАК certificate,
	             	  |	ВТ.token КАК token,
	             	  |	ВТ.deviceToken КАК deviceToken,
	             	  |	ВТ.ТипПодписчика КАК ТипПодписчика,
	             	  |	ВТ.systemType КАК systemType
	             	  |ИЗ
	             	  |	ВТ КАК ВТ
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.appCertificates КАК СертификатПриложенияДляСети
	             	  |		ПО ВТ.chain = СертификатПриложенияДляСети.chain
	             	  |			И ВТ.appType = СертификатПриложенияДляСети.appType
	             	  |			И ВТ.systemType = СертификатПриложенияДляСети.systemType
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.appCertificates КАК СертификатПриложенияОбщий
	             	  |		ПО (СертификатПриложенияОбщий.chain = ЗНАЧЕНИЕ(Справочник.chains.ПустаяСсылка))
	             	  |			И ВТ.appType = СертификатПриложенияОбщий.appType
	             	  |			И ВТ.systemType = СертификатПриложенияОбщий.systemType
	             	  |ГДЕ
	             	  |	ВТ.АктуальностьЗаписи > 7";
	
	пЗапрос.УстановитьПараметр("ТекущаяДата", УниверсальноеВремя(ТекущаяДата()));
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	ТаблицаПоиска		= РезультатЗапроса.Выгрузить();
	Выборка				= РезультатЗапроса.Выбрать();	
	
	Уведомление	= Неопределено;
	Сч			= 0;
	
	Пока Выборка.Следующий() Цикл
		
		If Выборка.deviceToken = "" Then
			Token.block(Выборка.Токен);			
		ElsIf Выборка.deviceToken <> "" Then
			If Уведомление = Неопределено Then
				Уведомление	= Новый ДоставляемоеУведомление;	
			EndIf;						
			Уведомление.Получатели.Добавить(Messages.ПолучательPush(Выборка.ТокенУстройства, Выборка.ТипПодписчика));			
			Сч	= Сч + 1;
		EndIf;
		
		Если Сч = 10 Тогда 
			Сч = 0;
			Уведомление.Данные				= Messages.pushData("registerDevice");
			Уведомление.title			= "";
			Уведомление.text				= "registerDevice";
					
			ИсключенныеПолучатели	= Новый Массив;			
			ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, GeneralReuse.getAuthorizationKey(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
						
			Если ИсключенныеПолучатели.Количество() > 0 Тогда				
				Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
					НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "deviceToken");					
					Если НайденаяСтрока <> Неопределено Тогда						
						Token.block(НайденаяСтрока.Токен);
						ТаблицаПоиска.Удалить(НайденаяСтрока);
					EndIf;					
				КонецЦикла;				
			EndIf;			
			Уведомление	= Неопределено;			
		EndIf;
		
	КонецЦикла;			
			
	Если Уведомление <> Неопределено Тогда
		Уведомление.Данные				= Messages.pushData("registerDevice");
		Уведомление.title			= "";
		Уведомление.text				= "registerDevice";
		//Уведомление.ЗвуковоеОповещение	= ЗвуковоеОповещение.ПоУмолчанию;
		
		ИсключенныеПолучатели	= Новый Массив;			
		ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, GeneralReuse.getAuthorizationKey(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
		
		Если ИсключенныеПолучатели.Количество() > 0 Тогда				
			Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
				НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "deviceToken");					
				Если НайденаяСтрока <> Неопределено Тогда					
					Token.block(НайденаяСтрока.Токен);
					ТаблицаПоиска.Удалить(НайденаяСтрока);
				EndIf;					
			КонецЦикла;				
		EndIf;			
		Уведомление	= Неопределено;
	EndIf;
	
	
	//Проверка актуальности токенов для ОС iOS	
	
	
	
	//Блокируем Token в МП тренера по уволенным сотрудникам	
	пЗапрос	= Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
	                |	Токены.Ссылка КАК token
	                |ИЗ
	                |	Справочник.tokens КАК Токены
	                |ГДЕ
	                |	Токены.appType = ЗНАЧЕНИЕ(Перечисление.appTypes.Employee)
	                |	И Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	                |	И Токены.account.userType <> ""employee""";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		Token.block(Выборка.Токен);
	КонецЦикла;		
	
КонецПроцедуры


