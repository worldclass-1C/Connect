Function ProcessRequest(request) Export

	dateInMilliseconds = CurrentUniversalDateInMilliseconds();

	parameters = New Structure();
	parameters.Insert("url", request.BaseURL + request.RelativeURL);
	parameters.Insert("headers", HTTP.getJSONFromStructure(request.Headers));
	parameters.Insert("requestName", HTTP.getRequestHeader(request, "request"));
	parameters.Insert("language", HTTP.getRequestHeader(request, "language"));
	parameters.Insert("brand", HTTP.getRequestHeader(request, "brand"));
	parameters.Insert("notSaveAnswer", False);
	parameters.Insert("compressAnswer", False);

	If parameters.requestName = Undefined Or parameters.requestName = "" Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noRequest"));
	Else

		If parameters.requestName <> "chainlist" And parameters.requestName <> "auth"
				And parameters.requestName <> "phonemasklist"
				And parameters.requestName <> "gymlist"
				And parameters.requestName <> "restore" Then
			parameters.Insert("token", HTTP.GetRequestHeader(request, "auth-key"));
			checkResult = GeneralReuse.checkToken(parameters.language, parameters.token);
			parameters.Insert("checkResult", checkResult);
			parameters.Insert("token", checkResult.token);
			parameters.Insert("errorDescription", checkResult.errorDescription);
		Else
			parameters.Insert("token", Catalogs.tokens.EmptyRef());
			parameters.Insert("errorDescription", Service.getErrorDescription());
		EndIf;

		requestParameters = HTTP.GetStructureFromRequest(request);
		parameters.Insert("requestStruct", requestParameters.requestStruct);
		parameters.Insert("requestBody", requestParameters.requestBody);
		parameters.Insert("answerBody", "");

		If parameters.errorDescription.error = "" Then
			Try
				If parameters.requestName = "chainlist" Then
					getChainList(parameters);
				ElsIf parameters.requestName = "phonemasklist" Then
					getPhoneMaskList(parameters);
				ElsIf parameters.requestName = "auth" Then
					userAuthorization(parameters);
				ElsIf parameters.requestName = "restore" Then
					ВосстановитьПарольПользователя(parameters);
				ElsIf parameters.requestName = "newpassword" Then
					УстановитьПарольПользователя(parameters);
				ElsIf parameters.requestName = "registerdevice" Then
					ЗарегистрироватьУстройство(parameters);
				ElsIf parameters.requestName = "unregisterdevice" Then
					УдалитьУстройство(parameters);
				ElsIf parameters.requestName = "userprofile" Then
					ПолучитьПрофильПользователя(parameters);
				ElsIf parameters.requestName = "cataloggyms"
						Or parameters.requestName = "gymlist" Then
					getGymList(parameters);
				ElsIf parameters.requestName = "catalogcancelcauses" Then
					ПолучитьСписокПричинОтменыЗаписи(parameters);
				ElsIf parameters.requestName = "notificationlist" Then
					ПолучитьСписокСообщений(parameters);
				ElsIf parameters.requestName = "readnotification" Then
					ПрочитатьСообщение(parameters);
				ElsIf parameters.requestName = "unreadnotificationcount" Then
					КоличествоНеПрочитанныхСообщений(parameters);
				Else
					ВыполнитьВнешнийЗапрос(parameters);
				EndIf;
			Except
				parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "system", ErrorDescription()));
			EndTry;
		EndIf;
	EndIf;

	If parameters.errorDescription.error <> "" Then
		JSONWriter = New JSONWriter();
		JSONWriter.SetString();
		answerStruct = New Structure();
		answerStruct.Insert("result", parameters.errorDescription.error);
		answerStruct.Insert("description", parameters.errorDescription.description);
		WriteJSON(JSONWriter, answerStruct);
		parameters.Insert("answerBody", JSONWriter.Close());
		If parameters.errorDescription.error = "userNotIdentified" Then
			answer = New HTTPServiceResponse(401);
		Else
			answer = New HTTPServiceResponse(403);
		EndIf;
	Else
		answer = New HTTPServiceResponse(200);
	EndIf;

	answer.Headers.Insert("Content-type", "application/json;  charset=utf-8");
	answer.SetBodyFromString(parameters.answerBody, TextEncoding.UTF8, ByteOrderMarkUsage.Use);

	parameters.Insert("duration", CurrentUniversalDateInMilliseconds()
		- DateInMilliseconds);
	parameters.Insert("isError", parameters.errorDescription.error <> "");

	Service.logRequestBackground(parameters);

	Return answer;

EndFunction

Функция ИзмененитьДанные(Запрос) Экспорт

	ИмяЗапроса = НРег(HTTP.GetRequestHeader(Запрос, "request"));
	language = НРег(HTTP.GetRequestHeader(Запрос, "language"));
	ОписаниеОшибки = Service.getErrorDescription();

	Если ИмяЗапроса = Неопределено Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "noRequest");
	Иначе
		JSONСтрока = ИзменитьСоздатьЭлементыСправочника(ИмяЗапроса, Запрос, language);
	КонецЕсли;

	Если ОписаниеОшибки.Служебное <> "" Тогда
		ЗаписьJSON = Новый ЗаписьJSON;
		ЗаписьJSON.УстановитьСтроку();
		СтруктураJSON = Новый Структура;
		СтруктураJSON.Вставить("result", ОписаниеОшибки.Служебное);
		СтруктураJSON.Вставить("description", ОписаниеОшибки.Пользовательское);
		ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);
		JSONСтрока = ЗаписьJSON.Закрыть();
	КонецЕсли;

	Ответ = Новый HTTPСервисОтвет(200);
	Ответ.Заголовки.Вставить("Content-type", "application/json;  charset=utf-8");
	Ответ.УстановитьТелоИзСтроки(JSONСтрока, КодировкаТекста.UTF8, ИспользованиеByteOrderMark.Использовать);

	Возврат Ответ;

КонецФункции

Функция ОтправитьСообщение(Запрос) Экспорт

	language = НРег(HTTP.GetRequestHeader(Запрос, "language"));
	ОписаниеОшибки = Service.getErrorDescription();
	ТокенХолдинга = HTTP.GetRequestHeader(Запрос, "auth-key");

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	Если ТокенХолдинга = Неопределено Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
	Иначе
		Холдинг = Catalogs.holdings.НайтиПоРеквизиту("token", ТокенХолдинга);
		Если Холдинг.Пустая() Тогда
			ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
		КонецЕсли;
	КонецЕсли;

	Если ОписаниеОшибки.Служебное = "" Тогда
		ДанныеЗапроса = HTTP.GetStructureFromRequest(Запрос).RequestStruct;
		Если ОписаниеОшибки.Служебное = "" Тогда
			Если Не ДанныеЗапроса.Свойство("messages") Тогда
				ОписаниеОшибки = Service.getErrorDescription(language, "noMessages");
			Иначе
				Для Каждого Сообщение Из ДанныеЗапроса.messages Цикл
					ДанныеСообщения = Новый Структура;
					ДанныеСообщения.Вставить("objectId", ?(Сообщение.Свойство("objectId"), Сообщение.objectId, ""));
					ДанныеСообщения.Вставить("objectType", ?(Сообщение.Свойство("objectType"), Сообщение.objectType, ""));
					ДанныеСообщения.Вставить("phone", ?(Сообщение.Свойство("phone"), Сообщение.phone, ""));
					ДанныеСообщения.Вставить("title", ?(Сообщение.Свойство("title"), Сообщение.title, ?(language = "ru", "Уведомление", "Notification")));
					ДанныеСообщения.Вставить("text", ?(Сообщение.Свойство("text"), Сообщение.text, ""));
					ДанныеСообщения.Вставить("action", ?(Сообщение.Свойство("action"), Сообщение.action, "ViewNotification"));
					ДанныеСообщения.Вставить("priority", ?(Сообщение.Свойство("priority"), Сообщение.priority, 5));
					ДанныеСообщения.Вставить("holding", Холдинг);
					Если Сообщение.Свойство("gymId") И Сообщение.gymId <> "" Тогда
						ДанныеСообщения.Вставить("gym", XMLЗначение(Тип("СправочникСсылка.gyms"), Сообщение.gymId));
					Иначе
						ДанныеСообщения.Вставить("gym", Catalogs.gyms.ПустаяСсылка());
					КонецЕсли;
					Если Сообщение.Свойство("uid") И Сообщение.uid <> "" Тогда
						ДанныеСообщения.Вставить("user", XMLЗначение(Тип("СправочникСсылка.users"), Сообщение.uid));
					Иначе
						ДанныеСообщения.Вставить("user", Catalogs.users.ПустаяСсылка());
					КонецЕсли;
					Если Сообщение.Свойство("token") И Сообщение.token <> "" Тогда
						ДанныеСообщения.Вставить("token", XMLЗначение(Тип("СправочникСсылка.tokens"), Сообщение.token));
					Иначе
						ДанныеСообщения.Вставить("token", Catalogs.tokens.ПустаяСсылка());
					КонецЕсли;
					МассивКаналов = Новый Массив;
					Если Сообщение.Свойство("routes") Тогда
						Для Каждого Канал Из Сообщение.routes Цикл
							МассивКаналов.Добавить(Enums.informationChannels[Канал]);
						КонецЦикла;
					КонецЕсли;
					ДанныеСообщения.Вставить("КаналыИнформирования", МассивКаналов);
					Если ДанныеСообщения.phone = ""
							И ДанныеСообщения.user.ПолучитьОбъект() = Неопределено Тогда
					ИначеЕсли ДанныеСообщения.user = ДанныеСообщения.token.user Тогда
					Иначе
						Messages.НовоеСообщение(ДанныеСообщения);
					КонецЕсли;
				КонецЦикла;
			КонецЕсли;
		КонецЕсли;
		СтруктураJSON.Вставить("result", "Ok");
	КонецЕсли;

	Если ОписаниеОшибки.Служебное <> "" Тогда
		СтруктураJSON.Вставить("result", ОписаниеОшибки.Служебное);
		СтруктураJSON.Вставить("description", ОписаниеОшибки.Пользовательское);
	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);
	ОтветJSON = ЗаписьJSON.Закрыть();

	Ответ = Новый HTTPСервисОтвет(200);
	Ответ.Заголовки.Вставить("Content-type", "application/json;  charset=utf-8");
	Ответ.УстановитьТелоИзСтроки(ОтветJSON, КодировкаТекста.UTF8, ИспользованиеByteOrderMark.Использовать);

	Возврат Ответ;

КонецФункции

//------------------------------------------------------------
//Обработчики внешних запросов
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
	|	Catalog.chain AS chain
	|		LEFT JOIN Catalog.chain.translation AS chaininterfaceText
	|		ON chaininterfaceText.Ref = chain.Ref
	|		AND chaininterfaceText.language = &language
	|WHERE
	|	NOT chain.DeletionMark
	|	AND chain.brand = &brand
	|ORDER BY
	|	code";

	query.SetParameter("language", language);
	
	If brand = "" Then
		query.Text = StrReplace(query.Text, "И Сети.brand = &brand", "");
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
		chainStruct.Insert("phoneMask", New Structure("code, mask", selection.phoneMaskCountryCode, selection.phoneMaskDescription));

		array.add(chainStruct);
	EndDo;

	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, array);

	Parameters.Insert("answerBody", JSONWriter.Close());
	Parameters.Insert("notSaveAnswer", True);

EndProcedure

Procedure getPhoneMaskList(Parameters)
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, GeneralReuse.phoneMasksList());
	Parameters.Insert("answerBody", JSONWriter.Close());
	Parameters.Insert("notSaveAnswer", True);
EndProcedure

Procedure userAuthorization(Parameters)

	requestStruct	= Parameters.requestStruct;
	language		= Parameters.language;
	struct			= New Structure();
	currentDate		= ToUniversalTime(CurrentDate());
	errorDescription = Service.getErrorDescription();

	If Not requestStruct.Property("login") Then
		errorDescription = Service.getErrorDescription(language, "noUserLogin");
	ElsIf Not requestStruct.Property("password")
			Or requestStruct.password = "" Then
		errorDescription = Service.getErrorDescription(language, "noUserPassword");
	ElsIf Not requestStruct.Property("chain") Then
		errorDescription = Service.getErrorDescription(language, "noKpoCode");
	EndIf;

	If errorDescription.error = "" Then
		query = New Query();
		query.Text = "ВЫБРАТЬ
		|	Пользователи.Ref КАК ref,
		|	Пользователи.holding КАК holding,
		|	Пользователи.userType КАК userType,
		|	UserPasswords.Validity КАК validity,
		|	Сети.timeZone КАК timezone,
		|	Сети.Ссылка КАК chain
		|FROM
		|	Справочник.users КАК Пользователи
		|		LEFT JOIN InformationRegister.usersPasswords AS UserPasswords
		|		ON UserPasswords.user = Пользователи.Ref
		|		LEFT СОЕДИНЕНИЕ Справочник.chain КАК Сети
		|		ПО Пользователи.holding = Сети.holding
		|ГДЕ
		|	Пользователи.login = &login
		|	AND UserPasswords.password = &password
		|	AND Сети.Code = &chainCode";

		query.SetParameter("login", requestStruct.login);
		query.SetParameter("password", requestStruct.password);
		query.SetParameter("chainCode", requestStruct.chain);		

		queryResult = query.Execute();
		If queryResult.IsEmpty() Then
			errorDescription = Service.getErrorDescription(language, "PasswordIsNotCorrect");
		Else
			selection = queryResult.Select();		
			selection.Next();
			If Lower(selection.userType) <> "employee"
					And Lower(requestStruct.appType) = "employee" Then
				errorDescription = Service.getErrorDescription(language, "staffOnly");
			ElsIf selection.validity = Date(1, 1, 1)
					Or selection.validity >= currentDate Then
				struct.Insert("result", ?(selection.validity = Date(1, 1, 1), "Ok", "PasswordHasExpirationDate"));
				If requestStruct.Property("remember")
						And requestStruct.remember = True Then
					tokenObject = Users.getToken(requestStruct, selection.user, selection.chain, selection.holding, selection.timezone);
					struct.Insert("authToken", New Structure("key,createTime", XMLString(tokenObject.Ref), tokenObject.createDate));
					parameters.Insert("token", tokenObject.Ref);
				EndIf;
			Else
				errorDescription = Service.getErrorDescription(language, "userPasswordExpired");
			EndIf;
		EndIf;

	EndIf;
	
	JSONWriter = New JSONWriter();;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Struct);		
	Parameters.Insert("answerBody", JSONWriter.Close());
	Parameters.Insert("errorDescription", errorDescription);

EndProcedure

Procedure ВосстановитьПарольПользователя(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	language = Parameters.language;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;
	ОписаниеОшибки = Service.getErrorDescription();

	МассивПользователей = Новый Массив;

	Если Не ДанныеЗапроса.Свойство("phone") Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "noUserPhone");
	ИначеЕсли Не ДанныеЗапроса.Свойство("chain") Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "noChain");
	КонецЕсли;

	Если ОписаниеОшибки.Служебное = "" Тогда
		ОписаниеОшибки = Service.canSendSms(language, ДанныеЗапроса.phone);
	КонецЕсли;

	Если ОписаниеОшибки.Служебное = "" Тогда
		ТекстыЗапроса = Новый Массив;
		пЗапрос = Новый Запрос;
		ТекстЗапроса = "ВЫБРАТЬ
			|	Пользователи.Ссылка КАК Ссылка,
			|	Сети.Ссылка КАК chain,
			|	Пользователи.holding КАК holding,
			|	Пользователи.userCode КАК userCode
			|ИЗ
			|	Справочник.users КАК Пользователи
			|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.chain КАК Сети
			|		ПО Пользователи.holding = Сети.holding
			|ГДЕ
			|	Сети.Код = &КодСети";

		Если ДанныеЗапроса.Свойство("uid") И ДанныеЗапроса.uid <> "" Тогда
			ДопУсловие = "И Пользователи.Ссылка = &user";
			пЗапрос.УстановитьПараметр("user", Catalogs.users.ПолучитьСсылку(Новый УникальныйИдентификатор(ДанныеЗапроса.uid)));
		Иначе
			ДопУсловие = "И Пользователи.phone = &phone";
			пЗапрос.УстановитьПараметр("phone", ДанныеЗапроса.phone);
		КонецЕсли;

		пЗапрос.УстановитьПараметр("КодСети", ДанныеЗапроса.kpoCode);
		ТекстыЗапроса.Добавить(ТекстЗапроса);
		ТекстыЗапроса.Добавить(ДопУсловие);
		пЗапрос.text = СтрСоединить(ТекстыЗапроса, Символы.ПС);

		РезультатЗапроса = пЗапрос.Выполнить();
		Если РезультатЗапроса.Пустой() Тогда
			Холдинг = Catalogs.chain.НайтиПоКоду(ДанныеЗапроса.kpoCode).holding;
			СтруктураЗапроса = HTTP.GetRequestStructure("userProfile", Холдинг);
			Если СтруктураЗапроса.Количество() > 0 Тогда
				Заголовки = Новый Соответствие;
				Заголовки.Вставить("Content-Type", "application/json");
				HTTPСоединение = Новый HTTPСоединение(СтруктураЗапроса.server, , СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.password, , СтруктураЗапроса.timeout, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.UseOSAuthentication);
				ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL
					+ СтруктураЗапроса.Приемник, Заголовки);
				ЗапросHTTP.УстановитьТелоИзСтроки(Parameters.ТелоЗапроса);
				ОтветHTTP = HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
				СтруктураАтрибутов = Service.СтруктураАтрибутовВнешнегоЗапроса("users");
				МассивПользователей = СоздатьЭлементыСправочника(СтруктураАтрибутов, HTTP.GetStructureFromRequest(ОтветHTTP).RequestStruct, Холдинг);
			Иначе
				ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
			КонецЕсли;
		Иначе
			Выборка = РезультатЗапроса.Выбрать();
			Пока Выборка.Следующий() Цикл
				МассивПользователей.Добавить(Выборка.Ссылка);
			КонецЦикла;
		КонецЕсли;

		Если МассивПользователей.Количество() = 0 Тогда
			ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
		ИначеЕсли МассивПользователей.Количество() > 1 Тогда
			МассивJSON = Новый Массив;
			Для Каждого Пользователь Из МассивПользователей Цикл
				СтруктураПользователя = Новый Структура;
				СтруктураПользователя.Вставить("uid", XMLСтрока(Пользователь));
				СтруктураПользователя.Вставить("name", Пользователь.firstName + " "
					+ Пользователь.secondName + " " + Лев(Пользователь.Фамилия, 1));
				МассивJSON.Добавить(СтруктураПользователя);
			КонецЦикла;
			СтруктураJSON.Вставить("result", "Ok");
			СтруктураJSON.Вставить("users", МассивJSON);
		Иначе

			Пароль = Users.setUserPassword(МассивПользователей[0]);
			МассивКаналов = Новый Массив;
			МассивКаналов.Добавить(Enums.informationChannels.sms);

			МассивСтрок = Новый Массив;
			МассивСтрок.Добавить(?(language = "ru", "login: ", "Login: "));
			МассивСтрок.Добавить(МассивПользователей[0].КодПользователя);
			МассивСтрок.Добавить(?(language = "ru", " password: ", " password: "));
			МассивСтрок.Добавить(Пароль);
			МассивСтрок.Добавить(?(language = "ru", ", password действителен в течение 15 минут", ", password is valid for 15 minutes"));

			ДанныеСообщения = Новый Структура;
			ДанныеСообщения.Вставить("phone", ДанныеЗапроса.phone);
			ДанныеСообщения.Вставить("user", МассивПользователей[0]);
			ДанныеСообщения.Вставить("title", "Восстановить доступ");
			ДанныеСообщения.Вставить("text", СтрСоединить(МассивСтрок));
			ДанныеСообщения.Вставить("holding", МассивПользователей[0].Холдинг);
			ДанныеСообщения.Вставить("КаналыИнформирования", МассивКаналов);
			ДанныеСообщения.Вставить("priority", 0);
			Messages.НовоеСообщение(ДанныеСообщения);
			СтруктураJSON.Вставить("result", "Ok");
			Service.FixSandingMessage(ДанныеЗапроса.phone);
		КонецЕсли;

	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());
	Parameters.Insert("ОписаниеОшибки", ОписаниеОшибки);

EndProcedure

Procedure УстановитьПарольПользователя(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	ОписаниеОшибки = Users.checkPassword(language, РезультатПроверки.Пользователь, ДанныеЗапроса.Password);
	Если ДанныеЗапроса.newPassword = "" Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "passwordIsEmpty");
	КонецЕсли;
	Если ОписаниеОшибки.Служебное = "" Тогда
		record = InformationRegisters.usersPasswords.CreateRecordManager();
		record.User 	= РезультатПроверки.user;
		record.Password = ДанныеЗапроса.newPassword;
		record.Validity = Дата(1, 1, 1);
		record.Write();
		СтруктураJSON.Вставить("result", "Ok");
	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());
	Parameters.Insert("ОписаниеОшибки", ОписаниеОшибки);

EndProcedure

Procedure ЗарегистрироватьУстройство(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	Если Не ДанныеЗапроса.Свойство("deviceToken") Тогда
		Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "noDeviceToken"));
	ИначеЕсли Не ДанныеЗапроса.Свойство("systemVersion") Тогда
		Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "noSystemVersion"));
	ИначеЕсли Не ДанныеЗапроса.Свойство("appVersion") Тогда
		Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "noAppVersion"));
	КонецЕсли;

	Если Parameters.ОписаниеОшибки.Служебное = "" Тогда
		СтруктураJSON.Вставить("result", "Ok");
		Запись = РегистрыСведений.registeredDevices.СоздатьМенеджерЗаписи();
		Запись.token = РезультатПроверки.token;
		Запись.deviceToken = ДанныеЗапроса.deviceToken;
		Запись.systemVersion = ДанныеЗапроса.systemVersion;
		//Попытка
		//	Запись.appVersion		= ДанныеЗапроса.appVersion;
		//Исключение
		Запись.appVersion = Число(СтрЗаменить(ДанныеЗапроса.appVersion, ".", ""));
		//КонецПопытки;
		Запись.deviceModel = ДанныеЗапроса.deviceModel;
		Запись.recordDate = УниверсальноеВремя(ТекущаяДата());
		Запись.Записать();

		пЗапрос = Новый Запрос;
		пЗапрос.text = "ВЫБРАТЬ
			|	ЗарегистрированныеУстройства.token КАК token
			|ИЗ
			|	РегистрСведений.registeredDevices КАК ЗарегистрированныеУстройства
			|ГДЕ
			|	ЗарегистрированныеУстройства.token <> &token
			|	И ЗарегистрированныеУстройства.token.user = &user
			|	И ЗарегистрированныеУстройства.systemVersion = &systemVersion
			|	И ЗарегистрированныеУстройства.appVersion = &appVersion
			|	И ЗарегистрированныеУстройства.deviceModel = &deviceModel
			|	И ЗарегистрированныеУстройства.deviceToken = &deviceToken
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|ВЫБРАТЬ
			|	ЗНАЧЕНИЕ(Справочник.messages.ПустаяСсылка) КАК message,
			|	ВЫБОР
			|		КОГДА &language = ""ru""
			|			ТОГДА ""Уведомление""
			|		ИНАЧЕ ""Notification""
			|	КОНЕЦ КАК title,
			|	ВЫБОР
			|		КОГДА &language = ""ru""
			|			ТОГДА ""Обновите приложение""
			|		ИНАЧЕ ""Update the application""
			|	КОНЕЦ КАК text,
			|	""updateApp"" КАК action,
			|	"""" КАК objectId,
			|	"""" КАК objectType,
			|	ЗНАЧЕНИЕ(ПланОбмена.messagesToSend.ПустаяСсылка) КАК УзелСообщенияКОтправке,
			|	Токены.systemType КАК systemType,
			|	ВЫБОР
			|		КОГДА Токены.systemType = ЗНАЧЕНИЕ(Перечисление.systemTypes.Android)
			|			ТОГДА ""GCM""
			|		ИНАЧЕ ""APNS""
			|	КОНЕЦ КАК ТипПодписчика,
			|	&deviceToken КАК deviceToken,
			|	Токены.Ссылка КАК token,
			|	ВЫБОР
			|		КОГДА Токены.appType = ЗНАЧЕНИЕ(Перечисление.appTypes.Customer)
			|			ТОГДА ЗНАЧЕНИЕ(Перечисление.informationChannels.pushCustomer)
			|		ИНАЧЕ ЗНАЧЕНИЕ(Перечисление.informationChannels.pushEmployee)
			|	КОНЕЦ КАК informationChannel,
			|	Токены.lockDate КАК lockDate,
			|	ЕСТЬNULL(СертификатПриложенияДляСети.certificate, СертификатПриложенияОбщий.certificate) КАК certificate
			|ИЗ
			|	Справочник.tokens КАК Токены
			|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияДляСети
			|		ПО Токены.chain = СертификатПриложенияДляСети.chain
			|			И Токены.appType = СертификатПриложенияДляСети.appType
			|			И Токены.systemType = СертификатПриложенияДляСети.systemType
			|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияОбщий
			|		ПО (СертификатПриложенияОбщий.chain = ЗНАЧЕНИЕ(Справочник.chain.ПустаяСсылка))
			|			И Токены.appType = СертификатПриложенияОбщий.appType
			|			И Токены.systemType = СертификатПриложенияОбщий.systemType
			|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.currentAppVersions КАК АктуальныеВерсииПриложений
			|		ПО Токены.appType = АктуальныеВерсииПриложений.appType
			|			И Токены.systemType = АктуальныеВерсииПриложений.systemType
			|ГДЕ
			|	ЕСТЬNULL(АктуальныеВерсииПриложений.appVersion, 0) > &appVersion
			|	И Токены.Ссылка = &token";

		пЗапрос.УстановитьПараметр("token", РезультатПроверки.Токен);
		пЗапрос.УстановитьПараметр("language", language);
		пЗапрос.УстановитьПараметр("user", РезультатПроверки.Пользователь);
		пЗапрос.УстановитьПараметр("systemVersion", Запись.systemVersion);
		пЗапрос.УстановитьПараметр("appVersion", Запись.appVersion);
		пЗапрос.УстановитьПараметр("deviceModel", Запись.deviceModel);
		пЗапрос.УстановитьПараметр("deviceToken", Запись.deviceToken);

		РезультатыЗапроса = пЗапрос.ВыполнитьПакет();
		Выборка = РезультатыЗапроса[0].Выбрать();
		Пока Выборка.Следующий() Цикл
			Users.blockToken(Выборка.Токен);
		КонецЦикла;

		Выборка = РезультатыЗапроса[1].Выбрать();
		Пока Выборка.Следующий() Цикл
			Messages.ОтправитьPush(Выборка);
		КонецЦикла;

	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure УдалитьУстройство(Parameters)

//@skip-warning
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	Users.blockToken(РезультатПроверки.Токен);
	СтруктураJSON.Вставить("result", "Ok");

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure ПолучитьПрофильПользователя(Parameters)

//@skip-warning
	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

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

	пЗапрос.УстановитьПараметр("user", РезультатПроверки.Пользователь);
	пЗапрос.УстановитьПараметр("appType", РезультатПроверки.ВидПриложения);

	РезультатыЗапроса = пЗапрос.ВыполнитьПакет();
	РезультатЗапроса = РезультатыЗапроса[0];
	РезультатЗапроса1 = РезультатыЗапроса[1];

	Если РезультатЗапроса.Пустой() Тогда
		Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "userNotIdentified"));
	Иначе
		Выборка = РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		СтруктураJSON.Вставить("login", Выборка.Логин);
		СтруктураJSON.Вставить("birthdayDate", Выборка.ДатаРождения);
		СтруктураJSON.Вставить("phoneNumber", Выборка.НомерТелефона);
		СтруктураJSON.Вставить("email", Выборка.Email);
		СтруктураJSON.Вставить("subscriptionEmail", Выборка.УчаствоватьВРассылкеEmail);
		СтруктураJSON.Вставить("subscriptionSms", Выборка.УчаствоватьВРассылкеСообщений);
		СтруктураJSON.Вставить("gender", Выборка.Пол);
		СтруктураJSON.Вставить("canUpdatePersonalData", Выборка.РазрешитьОбновлятьПерсональныеДанные);
		СтруктураJSON.Вставить("barcode", Выборка.Штрихкод);
		СтруктураJSON.Вставить("cid", Выборка.КодПользователя);
		СтруктураJSON.Вставить("uid", XMLСтрока(Выборка.Пользователь));
		СтруктураJSON.Вставить("lastName", Выборка.Фамилия);
		СтруктураJSON.Вставить("firstName", Выборка.Имя);
		СтруктураJSON.Вставить("secondName", Выборка.Отчество);

		Выборка = РезультатЗапроса1.Выбрать();
		Пока Выборка.Следующий() Цикл
			СтруктураJSON.Вставить(Выборка.ТипЗначенияКэша, HTTP.GetStructureFromRequestBody(Выборка.ЗначениеКэша));
		КонецЦикла;
	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure getGymList(Parameters)

	requestStruct	= Parameters.requestStruct;
	language		= Parameters.language;
	gymArray 		= New Array();
	
	errorDescription = Service.getErrorDescription();
	
	If Not requestStruct.Property("chain") Then
		errorDescription = Service.getErrorDescription(language, "noChain");
	EndIf;

	If errorDescription.error = "" Then
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
		Selection = query.Execute().Select();

		While Selection.Next() Do
			gymStruct = New Structure();
			gymStruct.Insert("gymId", XMLString(Selection.Ref));
			gymStruct.Insert("name", Selection.Description);
			gymStruct.Insert("type", Selection.type);
			gymStruct.Insert("cityId", XMLString(Selection.city));
			gymStruct.Insert("gymAddress", Selection.address);
			gymStruct.Insert("divisionTitle", Selection.segment);

			coords = New Structure();
			coords.Insert("latitude", Selection.latitude);
			coords.Insert("longitude", Selection.longitude);
			gymStruct.Вставить("coords", coords);

			scheduledArray = New Array();
			For Each department In Selection.departmentWorkSchedule.Unload() Do
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
		
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, gymArray);
	
	Parameters.Insert("answerBody", JSONWriter.Close());
	Parameters.Insert("notSaveAnswer", True);
	Parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure ПолучитьСписокПричинОтменыЗаписи(Parameters)

//@skip-warning
	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	//@skip-warning
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	МассивПричинОтмены = Новый Массив;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	ПричиныОтменыЗаписи.Ссылка КАК Ссылка,
		|	ПричиныОтменыЗаписи.Наименование КАК Наименование
		|ИЗ
		|	Справочник.cancellationReasons КАК ПричиныОтменыЗаписи
		|ГДЕ
		|	ПричиныОтменыЗаписи.holding = &holding
		|	И НЕ ПричиныОтменыЗаписи.ПометкаУдаления";

	пЗапрос.УстановитьПараметр("holding", РезультатПроверки.Холдинг);
	Выборка = пЗапрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		СтруктураПричиныОтмены = Новый Структура("uid,name", XMLСтрока(Выборка.Ссылка), Выборка.Наименование);
		МассивПричинОтмены.Добавить(СтруктураПричиныОтмены);
	КонецЦикла;

	ЗаписатьJSON(ЗаписьJSON, МассивПричинОтмены);
	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());
	Parameters.Insert("notSaveAnswer", Истина);

EndProcedure

Procedure ПолучитьСписокСообщений(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	//@skip-warning
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	МассивСообщений = Новый Массив;

	ДатаРегистрации = УниверсальноеВремя(?(ДанныеЗапроса.date = "", ТекущаяДата(), XMLЗначение(Тип("Дата"), ДанныеЗапроса.date)));

	Если РезультатПроверки.appType = Enums.appTypes.Employee Тогда
		КаналИнформирования = Enums.informationChannels.pushEmployee;
	ИначеЕсли РезультатПроверки.appType = Enums.appTypes.Customer Тогда
		КаналИнформирования = Enums.informationChannels.pushCustomer;
	Иначе
		КаналИнформирования = Enums.informationChannels.ПустаяСсылка();
	КонецЕсли;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ ПЕРВЫЕ 20
		|	Messages.Ссылка КАК message,
		|	Messages.registrationDate КАК registrationDate,
		|	Messages.title КАК title,
		|	Messages.text КАК text,
		|	Messages.objectId КАК objectId,
		|	Messages.objectType КАК objectType
		|ПОМЕСТИТЬ ВТ
		|ИЗ
		|	Справочник.messages КАК Messages
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.messages.channelPriorities КАК СообщенияПриоритетыКаналовИнформирования
		|		ПО Messages.Ссылка = СообщенияПриоритетыКаналовИнформирования.Ссылка
		|ГДЕ
		|	СообщенияПриоритетыКаналовИнформирования.channel = &informationChannel
		|	И Messages.user = &user
		|	И Messages.registrationDate < &registrationDate
		|
		|УПОРЯДОЧИТЬ ПО
		|	registrationDate УБЫВ
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ВТ.message КАК message,
		|	ВТ.registrationDate КАК registrationDate,
		|	ВТ.title КАК title,
		|	ВТ.text КАК text,
		|	ВТ.objectId КАК objectId,
		|	ВТ.objectType КАК objectType,
		|	МАКСИМУМ(ВЫБОР
		|			КОГДА ИсторияСообщенийСрезПоследних.messageStatus = ЗНАЧЕНИЕ(Перечисление.messageStatuses.read)
		|				ТОГДА ИСТИНА
		|			ИНАЧЕ ЛОЖЬ
		|		КОНЕЦ) КАК read
		|ИЗ
		|	ВТ КАК ВТ
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.messagesLogs.СрезПоследних КАК ИсторияСообщенийСрезПоследних
		|		ПО ВТ.message = ИсторияСообщенийСрезПоследних.message
		|
		|СГРУППИРОВАТЬ ПО
		|	ВТ.message,
		|	ВТ.registrationDate,
		|	ВТ.title,
		|	ВТ.text,
		|	ВТ.objectId,
		|	ВТ.objectType
		|
		|УПОРЯДОЧИТЬ ПО
		|	registrationDate УБЫВ";

	пЗапрос.УстановитьПараметр("registrationDate", ДатаРегистрации);
	пЗапрос.УстановитьПараметр("user", РезультатПроверки.Пользователь);
	пЗапрос.УстановитьПараметр("informationChannel", КаналИнформирования);

	Выборка = пЗапрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		СтруктураСообщения = Новый Структура;
		СтруктураСообщения.Вставить("noteId", XMLСтрока(Выборка.Сообщение));
		СтруктураСообщения.Вставить("date", XMLСтрока(МестноеВремя(Выборка.ДатаРегистрации, РезультатПроверки.ЧасовойПояс)));
		СтруктураСообщения.Вставить("title", Выборка.Заголовок);
		СтруктураСообщения.Вставить("text", Выборка.Текст);
		СтруктураСообщения.Вставить("read", Выборка.Прочитано);
		СтруктураСообщения.Вставить("objectId", Выборка.ОбъектИД);
		СтруктураСообщения.Вставить("objectType", Выборка.ОбъектТип);
		МассивСообщений.Добавить(СтруктураСообщения);
	КонецЦикла;

	ЗаписатьJSON(ЗаписьJSON, МассивСообщений);
	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure ПрочитатьСообщение(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	//@skip-warning
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	Если Не ДанныеЗапроса.Свойство("noteId") Или ДанныеЗапроса.noteId = "" Тогда
		Сообщение = Catalogs.messages.ПустаяСсылка();
	Иначе
		Сообщение = XMLЗначение(Тип("СправочникСсылка.messages"), ДанныеЗапроса.noteId);
	КонецЕсли;

	Если РезультатПроверки.appType = Enums.appTypes.Employee Тогда
		КаналИнформирования = Enums.informationChannels.pushEmployee;
	ИначеЕсли РезультатПроверки.appType = Enums.appTypes.Customer Тогда
		КаналИнформирования = Enums.informationChannels.pushCustomer;
	Иначе
		КаналИнформирования = Enums.informationChannels.ПустаяСсылка();
	КонецЕсли;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	Messages.Ссылка КАК message
		|ИЗ
		|	Справочник.messages КАК Messages
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.messages.channelPriorities КАК СообщенияПриоритетыКаналовИнформирования
		|		ПО Messages.Ссылка = СообщенияПриоритетыКаналовИнформирования.Ссылка
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.messagesLogs.СрезПоследних КАК ИсторияСообщенийСрезПоследних
		|		ПО Messages.Ссылка = ИсторияСообщенийСрезПоследних.message
		|ГДЕ
		|	СообщенияПриоритетыКаналовИнформирования.channel = &informationChannel
		|	И ЕСТЬNULL(ИсторияСообщенийСрезПоследних.messageStatus, ЗНАЧЕНИЕ(Перечисление.messageStatuses.ПустаяСсылка)) <> ЗНАЧЕНИЕ(Перечисление.messageStatuses.read)
		|	И Messages.user = &user";

	пЗапрос.УстановитьПараметр("user", РезультатПроверки.Пользователь);
	пЗапрос.УстановитьПараметр("informationChannel", КаналИнформирования);

	РезультатЗапроса = пЗапрос.Выполнить();
	Если Не РезультатЗапроса.Пустой() Тогда
		Выборка = РезультатЗапроса.Выбрать();
		КоличествоНеПрочитанныхСообщений = Выборка.Количество();

		Если Сообщение.Пустая() Тогда
			Пока Выборка.Следующий() Цикл
				Запись = РегистрыСведений.messagesLogs.СоздатьМенеджерЗаписи();
				Запись.period = УниверсальноеВремя(ТекущаяДата());
				Запись.message = Выборка.message;
				Запись.token = РезультатПроверки.token;
				Запись.recordDate = Запись.period;
				Запись.messageStatus = Enums.messageStatuses.read;
				Запись.informationChannel = КаналИнформирования;
				Запись.Записать();
			КонецЦикла;
			КоличествоНеПрочитанныхСообщений = 0;
		Иначе
			Если Выборка.НайтиСледующий(Новый Структура("message", Сообщение)) Тогда
				Запись = РегистрыСведений.messagesLogs.СоздатьМенеджерЗаписи();
				Запись.period = УниверсальноеВремя(ТекущаяДата());
				Запись.message = Сообщение;
				Запись.token = РезультатПроверки.token;
				Запись.recordDate = Запись.period;
				Запись.messageStatus = Enums.messageStatuses.read;
				Запись.informationChannel = КаналИнформирования;
				Запись.Записать();
				КоличествоНеПрочитанныхСообщений = КоличествоНеПрочитанныхСообщений - 1;
			КонецЕсли;
		КонецЕсли;
	Иначе
		КоличествоНеПрочитанныхСообщений = 0;
	КонецЕсли;

	СтруктураJSON.Вставить("result", "Ok");
	СтруктураJSON.Вставить("quantity", КоличествоНеПрочитанныхСообщений);

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);
	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure КоличествоНеПрочитанныхСообщений(Parameters)

//@skip-warning
	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	//@skip-warning
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;

	Если РезультатПроверки.appType = Enums.appTypes.Employee Тогда
		КаналИнформирования = Enums.informationChannels.pushEmployee;
	ИначеЕсли РезультатПроверки.appType = Enums.appTypes.Customer Тогда
		КаналИнформирования = Enums.informationChannels.pushCustomer;
	Иначе
		КаналИнформирования = Enums.informationChannels.ПустаяСсылка();
	КонецЕсли;

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ Messages.Ссылка) КАК Количество
		|ИЗ
		|	Справочник.messages КАК Messages
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.messages.channelPriorities КАК СообщенияПриоритетыКаналовИнформирования
		|		ПО Messages.Ссылка = СообщенияПриоритетыКаналовИнформирования.Ссылка
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.messagesLogs.СрезПоследних КАК ИсторияСообщенийСрезПоследних
		|		ПО Messages.Ссылка = ИсторияСообщенийСрезПоследних.message
		|ГДЕ
		|	СообщенияПриоритетыКаналовИнформирования.channel = &informationChannel
		|	И ЕСТЬNULL(ИсторияСообщенийСрезПоследних.messageStatus, ЗНАЧЕНИЕ(Перечисление.messageStatuses.ПустаяСсылка)) <> ЗНАЧЕНИЕ(Перечисление.messageStatuses.read)
		|	И Messages.user = &user";

	пЗапрос.УстановитьПараметр("user", РезультатПроверки.Пользователь);
	пЗапрос.УстановитьПараметр("informationChannel", КаналИнформирования);

	Выборка = пЗапрос.Выполнить().Выбрать();
	Выборка.Следующий();
	СтруктураJSON.Вставить("quantity", Выборка.Количество);

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);
	Parameters.Insert("ТелоОтвета", ЗаписьJSON.Закрыть());

EndProcedure

Procedure ВыполнитьВнешнийЗапрос(Parameters)

	ДанныеЗапроса = Parameters.ДанныеЗапроса;
	language = Parameters.language;
	РезультатПроверки = Parameters.РезультатПроверки;
	ТелоОтвета = "";

	пЗапрос = Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
		|	СоответствиеЗапросовИсточникамИнформации.performBackground КАК performBackground,
		|	СоответствиеЗапросовИсточникамИнформации.requestReceiver КАК Приемник,
		|	СоответствиеЗапросовИсточникамИнформации.HTTPRequestType КАК HTTPRequestType,
		|	СоответствиеЗапросовИсточникамИнформации.Attribute КАК Attribute,
		|	СоответствиеЗапросовИсточникамИнформации.staffOnly КАК staffOnly,
		|	СоответствиеЗапросовИсточникамИнформации.notSaveAnswer КАК notSaveAnswer,
		|	СоответствиеЗапросовИсточникамИнформации.compressAnswer КАК compressAnswer,
		|	ПодключенияХолдинговКИсточникамИнформации.URL КАК URL,
		|	ПодключенияХолдинговКИсточникамИнформации.server КАК server,
		|	ПодключенияХолдинговКИсточникамИнформации.port КАК port,
		|	ПодключенияХолдинговКИсточникамИнформации.user КАК УчетнаяЗапись,
		|	ПодключенияХолдинговКИсточникамИнформации.password КАК password,
		|	ПодключенияХолдинговКИсточникамИнформации.timeout КАК timeout,
		|	ПодключенияХолдинговКИсточникамИнформации.secureConnection КАК secureConnection,
		|	ПодключенияХолдинговКИсточникамИнформации.UseOSAuthentication КАК UseOSAuthentication
		|ИЗ
		|	РегистрСведений.holdingsConnectionsInformationSources КАК ПодключенияХолдинговКИсточникамИнформации
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.matchingRequestsInformationSources.informationSources КАК СоответствиеЗапросовИсточникамИнформации
		|		ПО ПодключенияХолдинговКИсточникамИнформации.informationSource = СоответствиеЗапросовИсточникамИнформации.informationSource
		|			И (СоответствиеЗапросовИсточникамИнформации.requestSource = &requestName)
		|			И (НЕ СоответствиеЗапросовИсточникамИнформации.notUse)
		|ГДЕ
		|	ПодключенияХолдинговКИсточникамИнформации.holding = &holding
		|	И НЕ СоответствиеЗапросовИсточникамИнформации.requestReceiver ЕСТЬ NULL";

	пЗапрос.УстановитьПараметр("holding", РезультатПроверки.Холдинг);
	пЗапрос.УстановитьПараметр("requestName", Parameters.requestName);
	РезультатЗапроса = пЗапрос.Выполнить();

	Если РезультатЗапроса.Пустой() Тогда
		Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "noUrl"));
	Иначе
		Заголовки = Новый Соответствие;
		Заголовки.Вставить("Content-Type", "application/json");

		Выборка = РезультатЗапроса.Выбрать();
		Выборка.Следующий();

		Parameters.Insert("notSaveAnswer", Выборка.НеСохранятьОтветВЛогах);
		Parameters.Insert("compressAnswer", Выборка.СжиматьЛоги);

		Если Выборка.staffOnly
				И РезультатПроверки.userType <> "employee" Тогда
			Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "staffOnly"));
		Иначе

			ВыполнятьВФоне = Выборка.performBackground;
			МассивФЗ = Новый Массив;
			КодСостояния = 200;
			Если Выборка.HTTPRequestType = Enums.HTTPRequestTypes.GET Тогда
				ТелоЗапроса = "";
				ParametersИзURL = СтрЗаменить(Parameters.URL, GeneralReuse.ПолучитьБазовыйURL(), "");
			Иначе
				ТелоЗапроса = HTTP.PrepareRequestBody(Parameters.КлючАвторизации, ДанныеЗапроса, РезультатПроверки.Пользователь, language, РезультатПроверки.ЧасовойПояс, РезультатПроверки.ВидПриложения);
				ParametersИзURL = "";
			КонецЕсли;

			Выборка.Сбросить();
			Пока Выборка.Следующий() Цикл

				Если ВыполнятьВФоне Тогда
					Адрес = ПоместитьВоВременноеХранилище("");

					СтруктураПодключения = Новый Структура;
					СтруктураПодключения.Вставить("server", Выборка.Сервер);
					СтруктураПодключения.Вставить("УчетнаяЗапись", Выборка.УчетнаяЗапись);
					СтруктураПодключения.Вставить("password", Выборка.Пароль);
					СтруктураПодключения.Вставить("timeout", Выборка.Таймаут);
					СтруктураПодключения.Вставить("secureConnection", Выборка.ЗащищенноеСоединение);
					СтруктураПодключения.Вставить("UseOSAuthentication", Выборка.ИспользоватьАутентификациюОС);
					СтруктураПодключения.Вставить("URL", Выборка.URL);
					СтруктураПодключения.Вставить("Приемник", Выборка.Приемник);
					ФЗ = Service.RunBackground(СтруктураПодключения, Заголовки, ТелоЗапроса, Адрес, ParametersИзURL);

					СтруктураФЗ = Новый Структура();
					СтруктураФЗ.Вставить("Адрес", Адрес);
					СтруктураФЗ.Вставить("ФЗ", ФЗ);
					СтруктураФЗ.Вставить("Attribute", Выборка.Атрибут);
					МассивФЗ.Добавить(СтруктураФЗ);
				Иначе
					HTTPСоединение = Новый HTTPСоединение(Выборка.server, , Выборка.УчетнаяЗапись, Выборка.password, , Выборка.timeout, ?(Выборка.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), Выборка.UseOSAuthentication);
					ЗапросHTTP = Новый HTTPЗапрос(Выборка.URL + Выборка.Приемник
						+ ParametersИзURL, Заголовки);
					ЗапросHTTP.УстановитьТелоИзСтроки(ТелоЗапроса);

					Если Выборка.HTTPRequestType = Enums.HTTPRequestTypes.GET Тогда
						ОтветHTTP = HTTPСоединение.Получить(ЗапросHTTP);
					Иначе
						ОтветHTTP = HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
					КонецЕсли;
					КодСостояния = ОтветHTTP.КодСостояния;
					ТелоОтвета = ОтветHTTP.ПолучитьТелоКакСтроку();
				КонецЕсли;

			КонецЦикла;

			Если ВыполнятьВФоне Тогда
				ТелоОтвета = HTTP.CheckBackgroundJobs(МассивФЗ);
			КонецЕсли;

			Если КодСостояния <> 200 Тогда
				Если КодСостояния = 403 Тогда
					СтруктураHTTPЗапроса = HTTP.GetStructureFromRequestBody(ТелоОтвета);
					Если СтруктураHTTPЗапроса.Свойство("result") Тогда
						Parameters.Insert("ОписаниеОшибки", Новый Структура("Служебное, Пользовательское", СтруктураHTTPЗапроса.result, СтруктураHTTPЗапроса.description));
					КонецЕсли;
				Иначе
					Parameters.Insert("ОписаниеОшибки", Service.getErrorDescription(language, "system", ТелоОтвета));
				КонецЕсли;
			КонецЕсли;

		КонецЕсли;

	КонецЕсли;

	Parameters.Insert("ТелоОтвета", ТелоОтвета);

EndProcedure

//------------------------------------------------------------
//Обработчики внутренних запросов
Функция СоздатьЭлементыСправочника(СтруктураАтрибутов, ДанныеЗапроса, Холдинг)

	МассивЭлементов = Новый Массив;

	Если ТипЗнч(ДанныеЗапроса) = Тип("Массив") Тогда
		Для Каждого ПараметрЗапроса Из ДанныеЗапроса Цикл
			СправочникСсылка = Catalogs[СтруктураАтрибутов.ИмяОбъектаМетаданных].ПолучитьСсылку(Новый УникальныйИдентификатор(ПараметрЗапроса.uid));
			СправочникОбъект = СправочникСсылка.ПолучитьОбъект();
			УстановитьПароль = Ложь;
			Если СправочникОбъект = Неопределено Тогда
				СправочникОбъект = Catalogs[СтруктураАтрибутов.ИмяОбъектаМетаданных].СоздатьЭлемент();
				СправочникОбъект.УстановитьСсылкуНового(СправочникСсылка);
				Для Каждого Атрибут Из СтруктураАтрибутов.ТаблицаАтрибутовДляНовогоЭлемента Цикл
					Если Атрибут.Ключ = "password"
							И ПараметрЗапроса.Свойство(Атрибут.Значение) Тогда
						УстановитьПароль = Истина;
						Пароль = XMLЗначение(Тип(Атрибут.Тип), ПараметрЗапроса[Атрибут.Значение])
					Иначе
						СправочникОбъект[Атрибут.Ключ] = XMLЗначение(Тип(Атрибут.Тип), ПараметрЗапроса[Атрибут.Значение]);
					КонецЕсли;
				КонецЦикла;
			КонецЕсли;
			Для Каждого Атрибут Из СтруктураАтрибутов.ТаблицаАтрибутов Цикл
				Если Атрибут.Тип = "ТабличнаяЧасть" Тогда
					СправочникОбъект[Атрибут.Ключ].Очистить();
					Для Каждого ЭлементМассива Из ПараметрЗапроса[Атрибут.Значение] Цикл
						НоваяСтрока = СправочникОбъект[Атрибут.Ключ].Добавить();
						Для Каждого РеквизитТЧ Из СтруктураАтрибутов.СтруктураМД[Атрибут.Ключ] Цикл
							Если РеквизитТЧ.Тип = "Ссылка" Тогда
								Для Каждого РеквизитСсылки Из СтруктураАтрибутов.СтруктураМД[РеквизитТЧ.Ключ] Цикл
									НоваяСтрока[РеквизитТЧ.Ключ] = Catalogs[РеквизитСсылки.Ключ].ПолучитьСсылку(Новый УникальныйИдентификатор(ЭлементМассива[РеквизитТЧ.Значение][РеквизитСсылки.Значение]));
								КонецЦикла;
							Иначе
								НоваяСтрока[РеквизитТЧ.Ключ] = ЭлементМассива[РеквизитТЧ.Значение];
							КонецЕсли;
						КонецЦикла;
					КонецЦикла;
				ИначеЕсли Атрибут.Тип = "Ссылка" Тогда
					Для Каждого РеквизитСсылки Из СтруктураАтрибутов.СтруктураМД[Атрибут.Ключ] Цикл
						СправочникОбъект[Атрибут.Ключ] = Catalogs[РеквизитСсылки.Ключ].ПолучитьСсылку(Новый УникальныйИдентификатор(ПараметрЗапроса[Атрибут.Значение][РеквизитСсылки.Значение]));
					КонецЦикла;
				Иначе
					СправочникОбъект[Атрибут.Ключ] = XMLЗначение(Тип(Атрибут.Тип), ПараметрЗапроса[Атрибут.Значение]);
				КонецЕсли;
			КонецЦикла;
			Если СтруктураАтрибутов.ИмяОбъектаМетаданных <> "СоответствиеЗапросовИсточникамИнформации" Тогда
				СправочникОбъект.holding = Холдинг;
				СправочникОбъект.registrationDate = УниверсальноеВремя(ТекущаяДата());
			КонецЕсли;
			СправочникОбъект.Записать();
			МассивЭлементов.Добавить(СправочникОбъект.Ссылка);
			Если УстановитьПароль Тогда
				Users.setUserPassword(СправочникОбъект.Ссылка, Пароль);
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;

	Возврат МассивЭлементов;

КонецФункции

Функция ИзменитьСоздатьЭлементыСправочника(ИмяЗапроса, Запрос, language)

	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	СтруктураJSON = Новый Структура;
	ОписаниеОшибки = Service.getErrorDescription();

	СтруктураАтрибутов = Service.СтруктураАтрибутовВнешнегоЗапроса(ИмяЗапроса);

	Если СтруктураАтрибутов.ИмяОбъектаМетаданных = "" Тогда
		Ошибка = "no request name";
	КонецЕсли;

	ТокенХолдинга = HTTP.GetRequestHeader(Запрос, "auth-key");
	Если ТокенХолдинга = Неопределено Тогда
		ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
	Иначе
		Холдинг = Catalogs.holdings.НайтиПоРеквизиту("token", ТокенХолдинга);
		Если Холдинг.Пустая() Тогда
			ОписаниеОшибки = Service.getErrorDescription(language, "userNotIdentified");
		КонецЕсли;
	КонецЕсли;

	Если ОписаниеОшибки.Служебное = "" Тогда
		ДанныеЗапроса = HTTP.GetStructureFromRequest(Запрос).RequestStruct;
		СтруктураJSON.Вставить("result", "Ok");
		СоздатьЭлементыСправочника(СтруктураАтрибутов, ДанныеЗапроса, Холдинг);
	КонецЕсли;

	Если ОписаниеОшибки.Служебное <> "" Тогда
		ЗаписьJSON = Новый ЗаписьJSON;
		ЗаписьJSON.УстановитьСтроку();
		СтруктураJSON = Новый Структура;
		СтруктураJSON.Вставить("result", "error");
		СтруктураJSON.Вставить("description", Ошибка);
		ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);
	КонецЕсли;

	ЗаписатьJSON(ЗаписьJSON, СтруктураJSON);

	Возврат ЗаписьJSON.Закрыть();

КонецФункции

Procedure ОбновитьКэшПользователей(Parameters, Холдинг,
		МассивПользователей) Экспорт

	СтруктураЗапроса = HTTP.GetRequestStructure("userProfileCache", Холдинг);
	Если СтруктураЗапроса.Количество() > 0 Тогда
		Для Каждого Пользователь Из МассивПользователей Цикл
		КонецЦикла;		
		Заголовки = Новый Соответствие;
		Заголовки.Вставить("Content-Type", "application/json");
		HTTPСоединение = Новый HTTPСоединение(СтруктураЗапроса.server, , СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.password, , СтруктураЗапроса.timeout, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.UseOSAuthentication);
		ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL
			+ СтруктураЗапроса.Приемник, Заголовки);
		ЗапросHTTP.УстановитьТелоИзСтроки(Parameters.ТелоЗапроса);
		ОтветHTTP = HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
	КонецЕсли;
EndProcedure