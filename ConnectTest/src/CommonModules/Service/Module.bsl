
Function getErrorDescription(language = "", error = "", description = "") Export
	
	errorDescription	= New Structure("error, description", error, description);
	
	If description = "" Then
		If error = "noRequest" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Не определен запрос");
			Else
				errorDescription.Insert("description", "no request");
			EndIf;
		ElsIf error = "userNotIdentified" Then
			If language = "ru" Then
				errorDescription.Insert("description", "user не идентифицирован");
			Else
				errorDescription.Insert("description", "User not identified");
			EndIf;
		ElsIf error = "userPasswordExpired" Then
			If language = "ru" Then
				errorDescription.Insert("description", "password просрочен");
			Else
				errorDescription.Insert("description", "Password expired");
			EndIf;	
		ElsIf error = "noUserLogin" Then
			If language = "ru" Then
				errorDescription.Insert("description", "Не указан login");
			Else
				errorDescription.Insert("description", "No user login");
			EndIf;
		ElsIf error = "noUserPassword" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан password");
			Else
				errorDescription.Insert("description", "No user password");
			EndIf;
		ElsIf error = "PasswordIsNotCorrect" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Неверный password");
			Else
				errorDescription.Insert("description", "Password is not correct");
			EndIf;
		ElsIf error = "passwordIsEmpty" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "password не может быть пустым");
			Else
				errorDescription.Insert("description", "Password can not be empty");
			EndIf;	
		ElsIf error = "noChain" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан код сети");
			Else
				errorDescription.Insert("description", "No chain code");
			EndIf;
		ElsIf error = "noAuthKey" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан код авторизации");
			Else
				errorDescription.Insert("description", "No auth-key");
			EndIf;
		ElsIf error = "noAppType" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан тип приложения");
			Else
				errorDescription.Insert("description", "No app type");
			EndIf;
		ElsIf error = "noDeviceToken" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан token устройства");
			Else
				errorDescription.Insert("description", "No device token");
			EndIf;
		ElsIf error = "noSystemType" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан тип ОС");
			Else
				errorDescription.Insert("description", "No system type");
			EndIf;
		ElsIf error = "noSystemVersion" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указана версия ОС");
			Else
				errorDescription.Insert("description", "No system version");
			EndIf;
		ElsIf error = "noAppVersion" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указана версия приложения");
			Else
				errorDescription.Insert("description", "No app version");
			EndIf;
		ElsIf error = "noCauses" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не заполнены причины отмены");
			Else
				errorDescription.Insert("description", "No causes");
			EndIf;
		ElsIf error = "staffOnly" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Только для сотрудников");
			Else
				errorDescription.Insert("description", "staff only");
			EndIf;	
		ElsIf error = "noUrl" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан url");
			Else
				errorDescription.Insert("description", "No url");
			EndIf;
		ElsIf error = "noRoutes" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указаны каналы информирования");
			Else
				errorDescription.Insert("description", "No information routes");
			EndIf;
		ElsIf error = "noMessages" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Нет сообщений");
			Else
				errorDescription.Insert("description", "No messages");
			EndIf;
		ElsIf error = "noUserPhone" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указан телефон");
			Else
				errorDescription.Insert("description", "no user phone");
			EndIf;
		ElsIf error = "noNoteId" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Не указано уведомление");
			Else
				errorDescription.Insert("description", "no notification");
			EndIf;
		ElsIf error = "limitExceeded" Then	
			Если language = "ru" Then
				errorDescription.Insert("description", "Превышен лимит сообщений");
			Else
				errorDescription.Insert("description", "Message limit exceeded");
			EndIf;	
		ElsIf error = "messageCanNotSent" Then	
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
	query.Text	= "ВЫБРАТЬ
	|	РАЗНОСТЬДАТ(ИсторияСлужебныхСообщений.registrationDate, &universalTime, МИНУТА) КАК minutesPassed,
	|	ЕСТЬNULL(ИсторияСлужебныхСообщений.quantity, 0) КАК quantity,
	|	ЕСТЬNULL(ИсторияСлужебныхСообщений.registrationDate, &universalTime) КАК registrationDate
	|ПОМЕСТИТЬ ВТ
	|ИЗ
	|	РегистрСведений.serviceMessagesLogs КАК ИсторияСлужебныхСообщений
	|ГДЕ
	|	ИсторияСлужебныхСообщений.phone = &phone
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	СУММА(ВТ.minutesPassed) КАК minutesPassed,
	|	СУММА(ВТ.quantity) КАК quantity
	|ИЗ
	|	ВТ КАК ВТ
	|ГДЕ
	|	ВТ.registrationDate >= &registrationDate
	|ИМЕЮЩИЕ
	|	СУММА(ВТ.quantity) > 0";
	
	query.SetParameter("phone", phone);
	query.SetParameter("registrationDate", AddMonth(universalTime, - 1));
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

Procedure FixSandingMessage(phone) Export
	
	universalTime		= ToUniversalTime(CurrentDate());
	
	record	= InformationRegisters.serviceMessagesLogs.CreateRecordManager();
	record.phone	= phone;
	record.Read();
	If record.Selected() Then		
		If record.registrationDate < AddMonth(universalTime, - 1) Then
			record.quantity = 1;
		Else
			record.quantity = record.quantity + 1;
		EndIf;
		record.registrationDate	= universalTime;
	Else
		record.phone	= phone;
		record.registrationDate	= universalTime;
		record.quantity		= 1;
	EndIf;
	
	record.Write();
	
EndProcedure

Procedure logRequestBackground(parameters) Export //duration, requestName, request, response, isError, token, user)Экспорт
	array	= New Array();
	array.Add(Parameters);
	BackgroundJobs.Execute("Service.logRequest", array, New UUID());
EndProcedure
	
Procedure logRequest(parameters) Export
		
	record	= Catalogs.logs.CreateItem();
	record.period			= ToUniversalTime(CurrentDate());
	record.token			= parameters.token;	
	record.requestName		= parameters.requestName;
	record.duration		= parameters.duration;
	record.isError			= parameters.isError;	
	
	requestBody	= """Headers"":" + Chars.LF + parameters.headers + Chars.LF + """Body"":" + Chars.LF + parameters.requestBody;
	If parameters.compressAnswer Then
		record.request			= New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(requestBody, New Deflation(9)))));	
	Else                   	
		record.requestBody		= requestBody;
	EndIf;
	
	If Not parameters.notSaveAnswer Or parameters.isError Then
		If parameters.compressAnswer Then
			record.response		= New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(parameters.answerBody, New Deflation(9)))));
		Else
			record.responseBody	= parameters.answerBody;
		EndIf;
	EndIf;
	
	record.Write();		
		
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
	             	  |	ИсторияЗапросов.period КАК period,
	             	  |	ИсторияЗапросов.requestName КАК requestName,
	             	  |	ИсторияЗапросов.token КАК token,
	             	  |	ИсторияЗапросов.token.user КАК user,
	             	  |	ИсторияЗапросов.token.holding КАК holding,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.logs КАК ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО ИсторияЗапросов.token.appType = АналитикиПриложений.appType
	             	  |			И ИсторияЗапросов.token.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	ИсторияЗапросов.period МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |	И НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	ВТ_ИсторияЗапросов.period КАК period,
	             	  |	РАЗНОСТЬДАТ(ВТ_ИсторияЗапросов.period, МИНИМУМ(ЕСТЬNULL(ВТ_ИсторияЗапросов1.period, &Завтра)), МИНУТА) КАК Дельта,
	             	  |	ВТ_ИсторияЗапросов.requestName КАК requestName,
	             	  |	ВТ_ИсторияЗапросов.token КАК token,
	             	  |	ВТ_ИсторияЗапросов.user КАК user,
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
	             	  |	ВТ_ИсторияЗапросов.user,
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
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.user)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |ГДЕ
	             	  |	ВТ_ИсторияЗапросов.user.registrationDate МЕЖДУ &ДатаНачала И &ДатаОкончания
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
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.user)
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
	             	  |	quantity(РАЗЛИЧНЫЕ Токены.user)
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
	             	  |	ИсторияЗапросов.period КАК period,
	             	  |	ИсторияЗапросов.requestName КАК requestName,
	             	  |	ИсторияЗапросов.token КАК token,
	             	  |	ИсторияЗапросов.token.user КАК user,
	             	  |	ИсторияЗапросов.token.holding КАК holding,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.logs КАК ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.appAnalytics КАК АналитикиПриложений
	             	  |		ПО ИсторияЗапросов.token.appType = АналитикиПриложений.appType
	             	  |			И ИсторияЗапросов.token.systemType = АналитикиПриложений.systemType
	             	  |ГДЕ
	             	  |	ИсторияЗапросов.period МЕЖДУ &ДатаНачала И &ДатаОкончания
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
	             	  |	quantity(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.user) КАК quantity
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
	             	  |	quantity(РАЗЛИЧНЫЕ Токены.user)
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
	             	  |	ПользователиИзменения.Ссылка КАК user,
	             	  |	Токены.appType КАК appType,
	             	  |	МИНИМУМ(Токены.lockDate) КАК lockDate,
	             	  |	Токены.holding КАК holding
	             	  |ИЗ
	             	  |	Справочник.users.Изменения КАК ПользователиИзменения
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.tokens КАК Токены
	             	  |		ПО ПользователиИзменения.Ссылка = Токены.user
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ПользователиИзменения.Ссылка,
	             	  |	Токены.chain,
	             	  |	Токены.appType,
	             	  |	Токены.holding";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	
	Узел	= GeneralReuse.УзелРегистрацияПользователя(Enums.registrationTypes.checkIn);
	
	Пока Выборка.Следующий() Цикл	
		СтруктураЗапроса = HTTP.GetRequestStructure(?(Выборка.lockDate = Дата(1,1,1), "registerAccount", "unregisterAccount"), Выборка.Холдинг);
		Если СтруктураЗапроса.Количество() > 0 Тогда			
			СтруктураHTTPЗапроса	= Новый Структура;
			СтруктураHTTPЗапроса.Вставить("userId", XMLСтрока(Выборка.Пользователь));
			СтруктураHTTPЗапроса.Вставить("language", "en");
			СтруктураHTTPЗапроса.Вставить("appType", XMLСтрока(Выборка.ВидПриложения));			
			HTTPСоединение	= Новый HTTPСоединение(СтруктураЗапроса.server,, СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.password,, СтруктураЗапроса.timeout, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.UseOSAuthentication);
			ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL + СтруктураЗапроса.Приемник, Заголовки);
			ЗапросHTTP.УстановитьТелоИзСтроки(HTTP.GetJSONFromStructure(СтруктураHTTPЗапроса));			
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
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияДляСети
	             	  |		ПО ВТ.chain = СертификатПриложенияДляСети.chain
	             	  |			И ВТ.appType = СертификатПриложенияДляСети.appType
	             	  |			И ВТ.systemType = СертификатПриложенияДляСети.systemType
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияОбщий
	             	  |		ПО (СертификатПриложенияОбщий.chain = ЗНАЧЕНИЕ(Справочник.chain.ПустаяСсылка))
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
			Users.blockToken(Выборка.Токен);			
		ElsIf Выборка.deviceToken <> "" Then
			If Уведомление = Неопределено Then
				Уведомление	= Новый ДоставляемоеУведомление;	
			EndIf;						
			Уведомление.Получатели.Добавить(Messages.ПолучательPush(Выборка.ТокенУстройства, Выборка.ТипПодписчика));			
			Сч	= Сч + 1;
		EndIf;
		
		Если Сч = 10 Тогда 
			Сч = 0;
			Уведомление.Данные				= Messages.ДанныеPush("registerDevice");
			Уведомление.title			= "";
			Уведомление.text				= "registerDevice";
					
			ИсключенныеПолучатели	= Новый Массив;			
			ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, GeneralReuse.ДанныеАутентификации(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
						
			Если ИсключенныеПолучатели.Количество() > 0 Тогда				
				Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
					НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "deviceToken");					
					Если НайденаяСтрока <> Неопределено Тогда						
						Users.blockToken(НайденаяСтрока.Токен);
						ТаблицаПоиска.Удалить(НайденаяСтрока);
					EndIf;					
				КонецЦикла;				
			EndIf;			
			Уведомление	= Неопределено;			
		EndIf;
		
	КонецЦикла;			
			
	Если Уведомление <> Неопределено Тогда
		Уведомление.Данные				= Messages.ДанныеPush("registerDevice");
		Уведомление.title			= "";
		Уведомление.text				= "registerDevice";
		//Уведомление.ЗвуковоеОповещение	= ЗвуковоеОповещение.ПоУмолчанию;
		
		ИсключенныеПолучатели	= Новый Массив;			
		ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, GeneralReuse.ДанныеАутентификации(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
		
		Если ИсключенныеПолучатели.Количество() > 0 Тогда				
			Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
				НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "deviceToken");					
				Если НайденаяСтрока <> Неопределено Тогда					
					Users.blockToken(НайденаяСтрока.Токен);
					ТаблицаПоиска.Удалить(НайденаяСтрока);
				EndIf;					
			КонецЦикла;				
		EndIf;			
		Уведомление	= Неопределено;
	EndIf;
	
	
	//Проверка актуальности токенов для ОС iOS	
	
	
	
	//Блокируем tokens в МП тренера по уволенным сотрудникам	
	пЗапрос	= Новый Запрос;
	пЗапрос.text = "ВЫБРАТЬ
	                |	Токены.Ссылка КАК token
	                |ИЗ
	                |	Справочник.tokens КАК Токены
	                |ГДЕ
	                |	Токены.appType = ЗНАЧЕНИЕ(Перечисление.appTypes.Employee)
	                |	И Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	                |	И Токены.user.userType <> ""employee""";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		Users.blockToken(Выборка.Токен);
	КонецЦикла;		
	
КонецПроцедуры

Function RunBackground(selection, headers, body, link,
		RequestParametersFromURL) Export
	Parameters = New Array();
	Parameters.Add(selection);
	Parameters.Add(headers);
	Parameters.Add(body);
	Parameters.Add(link);
	Parameters.Add(RequestParametersFromURL);
	Return BackgroundJobs.Execute("HTTP.RunRequestInAccountingSystem", Parameters, New UUID());
EndFunction

Function СтруктураАтрибутовВнешнегоЗапроса(ИмяЗапроса) Export

	ТаблицаАтрибутов = New ТаблицаЗначений;
	ТаблицаАтрибутов.Колонки.Добавить("Ключ");
	ТаблицаАтрибутов.Колонки.Добавить("Значение");
	ТаблицаАтрибутов.Колонки.Добавить("Тип");

	ТаблицаАтрибутовДляНовогоЭлемента = New ТаблицаЗначений;
	ТаблицаАтрибутовДляНовогоЭлемента.Колонки.Добавить("Ключ");
	ТаблицаАтрибутовДляНовогоЭлемента.Колонки.Добавить("Значение");
	ТаблицаАтрибутовДляНовогоЭлемента.Колонки.Добавить("Тип");

	СтруктураМД = New Структура;
	ИмяОбъектаМетаданных = "";

	Если ИмяЗапроса = "users" Тогда

		ИмяОбъектаМетаданных = "Пользователи";

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Email", "email", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "birthday", "birthdayDate", "Дата");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "lastName", "lastName", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "firstName", "firstName", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "secondName", "secondName", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "userCode", "cid", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "phone", "phoneNumber", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "sex", "gender", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "userType", "userType", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "barCode", "barcode", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "notSubscriptionEmail", "noSubscriptionEmail", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "notSubscriptionSms", "noSubscriptionSms", "Булево");

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовДляНовогоЭлемента, "login", "cid", "Строка");
		//ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовДляНовогоЭлемента, "password", "password", "Строка");

	ElsIf ИмяЗапроса = "gyms" Тогда

		ИмяОбъектаМетаданных = "Клубы";

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Наименование", "name", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Адрес", "gymAddress", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Сегмент", "division", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Широта", "latitude", "Число");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Долгота", "longitude", "Число");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Тип", "type", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "departmentWorkSchedule", "departments", "ТабличнаяЧасть");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Город", "city", "Ссылка");

		ТаблицаАтрибутовТЧГрафикРаботыОтделов = New ТаблицаЗначений;
		ТаблицаАтрибутовТЧГрафикРаботыОтделов.Колонки.Добавить("Ключ");
		ТаблицаАтрибутовТЧГрафикРаботыОтделов.Колонки.Добавить("Значение");
		ТаблицаАтрибутовТЧГрафикРаботыОтделов.Колонки.Добавить("Тип");

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧГрафикРаботыОтделов, "department", "name", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧГрафикРаботыОтделов, "phone", "phone", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧГрафикРаботыОтделов, "weekdaysTime", "weekdaysTime", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧГрафикРаботыОтделов, "holidaysTime", "holidaysTime", "Строка");

		СтруктураГород = New Структура;
		СтруктураГород.Вставить("Города", "id");

		СтруктураМД.Вставить("departmentWorkSchedule", ТаблицаАтрибутовТЧГрафикРаботыОтделов);
		СтруктураМД.Вставить("Город", СтруктураГород);

	ElsIf ИмяЗапроса = "cities" Тогда

		ИмяОбъектаМетаданных = "Города";
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Наименование", "name", "Строка");

	ElsIf ИмяЗапроса = "cancelcauses" Тогда

		ИмяОбъектаМетаданных = "ПричиныОтменыЗаписи";
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Наименование", "name", "Строка");

	ElsIf ИмяЗапроса = "request" Тогда

		ИмяОбъектаМетаданных = "СоответствиеЗапросовИсточникамИнформации";

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "Код", "code", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "performBackground", "background", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "notSaveAnswer", "notSaveLogs", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "compressAnswer", "compressLogs", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "staffOnly", "staffOnly", "Булево");

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, "informationSources", "informationSources", "ТабличнаяЧасть");

		ТаблицаАтрибутовТЧИсточникиИнформации = New ТаблицаЗначений;
		ТаблицаАтрибутовТЧИсточникиИнформации.Колонки.Добавить("Ключ");
		ТаблицаАтрибутовТЧИсточникиИнформации.Колонки.Добавить("Значение");
		ТаблицаАтрибутовТЧИсточникиИнформации.Колонки.Добавить("Тип");

		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "Attribute", "atribute", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "performBackground", "background", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "notSaveAnswer", "notSaveLogs", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "compressAnswer", "compressLogs", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "staffOnly", "staffOnly", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "notUse", "notUse", "Булево");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "requestSource", "requestSource", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "requestReceiver", "requestReceiver", "Строка");
		ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутовТЧИсточникиИнформации, "informationSource", "informationSource", "Ссылка");

		СтруктураИсточникИнформации = New Структура;
		СтруктураИсточникИнформации.Вставить("informationSources", "uid");

		СтруктураМД.Вставить("informationSources", ТаблицаАтрибутовТЧИсточникиИнформации);
		СтруктураМД.Вставить("informationSource", СтруктураИсточникИнформации);

	EndIf;

	Return New Структура("ИмяОбъектаМетаданных, ТаблицаАтрибутов, ТаблицаАтрибутовДляНовогоЭлемента, СтруктураМД", ИмяОбъектаМетаданных, ТаблицаАтрибутов, ТаблицаАтрибутовДляНовогоЭлемента, СтруктураМД);

EndFunction

Procedure ДобавитьСтрокуВТаблицуАтрибутов(ТаблицаАтрибутов, Ключ, Значение,
		Тип)
	НоваяСтрока = ТаблицаАтрибутов.Добавить();
	НоваяСтрока.Ключ = Ключ;
	НоваяСтрока.Значение = Значение;
	НоваяСтрока.Тип = Тип;
EndProcedure

