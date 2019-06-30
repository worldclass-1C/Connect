
Функция ПолучитьОписаниеОшибки(ЯзыкОписания = "", СлужебноеОписание = "", ПользовательскоеОписание = "") Экспорт
	
	ОписаниеОшибки	= Новый Структура("Служебное, Пользовательское", СлужебноеОписание, ПользовательскоеОписание);
	
	Если ПользовательскоеОписание = "" Тогда
		Если СлужебноеОписание = "noRequest" Тогда
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не определен запрос");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "no request");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "userNotIdentified" Тогда
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Пользователь не идентифицирован");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "User not identified");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "userPasswordExpired" Тогда
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Пароль просрочен");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "Password expired");
			КонецЕсли;	
		ИначеЕсли СлужебноеОписание = "noUserLogin" Тогда
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан логин");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No user login");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noUserPassword" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан пароль");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No user password");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "PasswordIsNotCorrect" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Неверный пароль");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "Password is not correct");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "passwordIsEmpty" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Пароль не может быть пустым");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "Password can not be empty");
			КонецЕсли;	
		ИначеЕсли СлужебноеОписание = "noKpoCode" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан код сети");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No net code");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noAuthKey" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан код авторизации");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No auth-key");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noAppType" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан тип приложения");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No app type");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noDeviceToken" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан токен устройства");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No device token");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noSystemType" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан тип ОС");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No system type");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noSystemVersion" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указана версия ОС");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No system version");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noAppVersion" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указана версия приложения");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No app version");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noCauses" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не заполнены причины отмены");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No causes");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "staffOnly" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Только для сотрудников");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "staff only");
			КонецЕсли;	
		ИначеЕсли СлужебноеОписание = "noUrl" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан url");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No url");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noRoutes" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указаны каналы информирования");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No information routes");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noMessages" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Нет сообщений");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "No messages");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noUserPhone" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указан телефон");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "no user phone");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "noNoteId" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Не указано уведомление");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "no notification");
			КонецЕсли;
		ИначеЕсли СлужебноеОписание = "limitExceeded" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Превышен лимит сообщений");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "Message limit exceeded");
			КонецЕсли;	
		ИначеЕсли СлужебноеОписание = "messageCanNotSent" Тогда	
			Если ЯзыкОписания = "ru" Тогда
				ОписаниеОшибки.Вставить("Пользовательское", "Повторное сообщение можно отправить через 15 минут");
			Иначе
				ОписаниеОшибки.Вставить("Пользовательское", "Message can be sent in 15 minutes");
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;
	
	Возврат ОписаниеОшибки;
	
КонецФункции

Функция ПолучитьСоздатьРегистраторДвижений(День, ПериодОтчета)

	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ
	             	  |	РегистраторДвижений.Ссылка КАК Ссылка
	             	  |ИЗ
	             	  |	Документ.РегистраторДвижений КАК РегистраторДвижений
	             	  |ГДЕ
	             	  |	РегистраторДвижений.Дата = &Дата
	             	  |	И РегистраторДвижений.ПериодОтчета = &ПериодОтчета";
	
	пЗапрос.УстановитьПараметр("Дата", НачалоДня(День));
	пЗапрос.УстановитьПараметр("ПериодОтчета", ПериодОтчета);
	РезультатЗапроса	= пЗапрос.Выполнить();
	
	Если РезультатЗапроса.Пустой() Тогда
		ДокументОбъект	= Документы.РегистраторДвижений.СоздатьДокумент();
		ДокументОбъект.Дата	= НачалоДня(День);
		ДокументОбъект.ПериодОтчета	= ПериодОтчета;
		ДокументОбъект.Записать();
		Возврат ДокументОбъект.Ссылка;
	Иначе
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		Возврат Выборка.Ссылка;
	КонецЕсли;

КонецФункции 

Функция ПроверитьНомерТелефона(ЯзыкПриложения, НомерТелефона) Экспорт

	ОписаниеОшибки	= Служебный.ПолучитьОписаниеОшибки();
	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ
	             	  |	РАЗНОСТЬДАТ(ИсторияСлужебныхСообщений.ДатаРегистрации, &ТекущаяУниверсальнаяДата, МИНУТА) КАК МинутСПоследнейОтправки,
	             	  |	ЕСТЬNULL(ИсторияСлужебныхСообщений.Количество, 0) КАК КоличествоСообщений,
	             	  |	ЕСТЬNULL(ИсторияСлужебныхСообщений.ДатаРегистрации, &ТекущаяУниверсальнаяДата) КАК ДатаРегистрации
	             	  |ПОМЕСТИТЬ ВТ
	             	  |ИЗ
	             	  |	РегистрСведений.ИсторияСлужебныхСообщений КАК ИсторияСлужебныхСообщений
	             	  |ГДЕ
	             	  |	ИсторияСлужебныхСообщений.НомерТелефона = &НомерТелефона
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	СУММА(ВТ.МинутСПоследнейОтправки) КАК МинутСПоследнейОтправки,
	             	  |	СУММА(ВТ.КоличествоСообщений) КАК КоличествоСообщений
	             	  |ИЗ
	             	  |	ВТ КАК ВТ
	             	  |ГДЕ
	             	  |	ВТ.ДатаРегистрации >= &ДатаРегистрации
	             	  |
	             	  |ИМЕЮЩИЕ
	             	  |	СУММА(ВТ.КоличествоСообщений) > 0";
	
	пЗапрос.УстановитьПараметр("НомерТелефона", НомерТелефона);
	пЗапрос.УстановитьПараметр("ДатаРегистрации", ДобавитьМесяц(УниверсальноеВремя(ТекущаяДата()), - 1));
	пЗапрос.УстановитьПараметр("ТекущаяУниверсальнаяДата", УниверсальноеВремя(ТекущаяДата()));
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	
	Если Не РезультатЗапроса.Пустой() Тогда
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		Если Выборка.КоличествоСообщений > 3 Тогда
			ОписаниеОшибки	= Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, "limitExceeded");
		ИначеЕсли Выборка.МинутСПоследнейОтправки < 15 Тогда
			ОписаниеОшибки	= Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, "messageCanNotSent");
		КонецЕсли;				
	КонецЕсли;
	
	Возврат ОписаниеОшибки;

КонецФункции 

Процедура ЗафиксироватьОтправкуСообщения(НомерТелефона) Экспорт
	
	УниверсальноеВремя	= УниверсальноеВремя(ТекущаяДата());
	
	Запись	= РегистрыСведений.ИсторияСлужебныхСообщений.СоздатьМенеджерЗаписи();
	Запись.НомерТелефона	= НомерТелефона;
	Запись.Прочитать();
	Если Запись.Выбран() Тогда		
		Если Запись.ДатаРегистрации < ДобавитьМесяц(УниверсальноеВремя, - 1) Тогда
			Запись.Количество = 1;
		Иначе
			Запись.Количество = Запись.Количество + 1;
		КонецЕсли;
		Запись.ДатаРегистрации	= УниверсальноеВремя;
	Иначе
		Запись.НомерТелефона	= НомерТелефона;
		Запись.ДатаРегистрации	= УниверсальноеВремя;
		Запись.Количество		= 1;
	КонецЕсли;
	
	Запись.Записать();
	
КонецПроцедуры

Процедура ЗафиксироватьЗапросВИсторииВФоне(Параметры) Экспорт //Длительность, ИмяЗапроса, Запрос, Ответ, Ошибка, Токен, Пользователь)Экспорт
	ПередаваемыеПараметры	= Новый Массив;
	ПередаваемыеПараметры.Добавить(Параметры);
	ФоновыеЗадания.Выполнить("Служебный.ЗафиксироватьЗапросВИстории", ПередаваемыеПараметры, Новый УникальныйИдентификатор);
КонецПроцедуры
	
Процедура ЗафиксироватьЗапросВИстории(Параметры) Экспорт
		
	Запись	= Справочники.ИсторииЗапросов.СоздатьЭлемент();
	Запись.Период				= УниверсальноеВремя(ТекущаяДата());
	Запись.Токен				= Параметры.Токен;	
	Запись.ИмяЗапроса			= Параметры.ИмяЗапроса;
	Запись.Длительность			= Параметры.Длительность;
	Запись.Ошибка				= Параметры.Ошибка;	
	
	ТелоЗапроса					= """Headers"":" + Символы.ПС + Параметры.Заголовки + Символы.ПС + """Body"":" + Символы.ПС + Параметры.ТелоЗапроса;
	Если Параметры.СжиматьЛоги Тогда
		Запись.Запрос			= Новый ХранилищеЗначения(Base64Значение(СериализаторXDTO.XMLСтрока(Новый ХранилищеЗначения(ТелоЗапроса, Новый СжатиеДанных(9)))));	
	Иначе                   	
		Запись.ЗапросТело		= ТелоЗапроса;
	КонецЕсли;
	
	Если Не Параметры.НеСохранятьОтветВЛогах Или Параметры.Ошибка Тогда
		Если Параметры.СжиматьЛоги Тогда
			Запись.Ответ		= Новый ХранилищеЗначения(Base64Значение(СериализаторXDTO.XMLСтрока(Новый ХранилищеЗначения(Параметры.ТелоОтвета, Новый СжатиеДанных(9)))));
		Иначе
			Запись.ОтветТело	= Параметры.ТелоОтвета;
		КонецЕсли;
	КонецЕсли;
	
	Запись.Записать();		
		
КонецПроцедуры

Процедура РассчитатьПоказатели() Экспорт
	
	//Расчет показателей по дням
	Дни				= Новый Массив;
	ПредыдущийДень	= НачалоДня(УниверсальноеВремя(ТекущаяДата()) - 86400);
	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ ПЕРВЫЕ 1
	             	  |	РегистраторДвижений.Дата КАК ДеньРасчетаПоказателей
	             	  |ИЗ
	             	  |	Документ.РегистраторДвижений КАК РегистраторДвижений
	             	  |ГДЕ
	             	  |	РегистраторДвижений.ПериодОтчета = ЗНАЧЕНИЕ(Перечисление.ПериодыОтчета.День)
	             	  |
	             	  |УПОРЯДОЧИТЬ ПО
	             	  |	ДеньРасчетаПоказателей УБЫВ";
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда
		Дни.Добавить(ПредыдущийДень);
	Иначе
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		ДеньРасчетаПоказателей	= Выборка.ДеньРасчетаПоказателей;
		Пока ДеньРасчетаПоказателей < ПредыдущийДень Цикл
			ДеньРасчетаПоказателей	= ДеньРасчетаПоказателей + 86400; 
			Дни.Добавить(ДеньРасчетаПоказателей);
		КонецЦикла;		
	КонецЕсли;	
	
	Служебный.РассчитатьПоказателиПоДням(Дни);	
	
	//Расчет показателей по месяцам
	Месяцы			= Новый Массив;
	ТекущийМесяц	= НачалоМесяца(УниверсальноеВремя(ТекущаяДата()));
	ПредыдущийМесяц	= НачалоМесяца(ТекущийМесяц - 86400);
	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ ПЕРВЫЕ 1
	             	  |	РегистраторДвижений.Дата КАК МесяцРасчетаПоказателей,
	             	  |	РегистраторДвижений.Ссылка КАК Ссылка
	             	  |ИЗ
	             	  |	Документ.РегистраторДвижений КАК РегистраторДвижений
	             	  |ГДЕ
	             	  |	РегистраторДвижений.ПериодОтчета = ЗНАЧЕНИЕ(Перечисление.ПериодыОтчета.Месяц)
	             	  |
	             	  |УПОРЯДОЧИТЬ ПО
	             	  |	МесяцРасчетаПоказателей УБЫВ";
	
	РезультатЗапроса = пЗапрос.Выполнить();
	Если РезультатЗапроса.Пустой() Тогда		
		Месяцы.Добавить(ТекущийМесяц);
	Иначе
		Выборка	= РезультатЗапроса.Выбрать();
		Выборка.Следующий();
		МесяцРасчетаПоказателей	= Выборка.МесяцРасчетаПоказателей;		
		Месяцы.Добавить(МесяцРасчетаПоказателей);		
		Пока МесяцРасчетаПоказателей < ТекущийМесяц Цикл
			МесяцРасчетаПоказателей	= ДобавитьМесяц(МесяцРасчетаПоказателей, 1);
			Месяцы.Добавить(МесяцРасчетаПоказателей);
		КонецЦикла;		
	КонецЕсли;	
	
	Служебный.РассчитатьПоказателиПоМесяцам(Месяцы);
	
КонецПроцедуры	
	
Процедура РассчитатьПоказателиПоДням(Дни) Экспорт
	Для Каждого День Из Дни Цикл
		РассчитатьПоказателиЗаДень(День);	
	КонецЦикла;
КонецПроцедуры

Процедура РассчитатьПоказателиЗаДень(День) Экспорт
	
	Набор	= РегистрыНакопления.ПоказателиПользователей.СоздатьНаборЗаписей();
	Набор.Отбор.Регистратор.Установить(ПолучитьСоздатьРегистраторДвижений(День, Перечисления.ПериодыОтчета.День));
	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ
	             	  |	ИсторияЗапросов.Период КАК Период,
	             	  |	ИсторияЗапросов.ИмяЗапроса КАК ИмяЗапроса,
	             	  |	ИсторияЗапросов.Токен КАК Токен,
	             	  |	ИсторияЗапросов.Токен.Пользователь КАК Пользователь,
	             	  |	ИсторияЗапросов.Токен.Холдинг КАК Холдинг,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.ИсторииЗапросов КАК ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.АналитикиПриложений КАК АналитикиПриложений
	             	  |		ПО ИсторияЗапросов.Токен.ВидПриложения = АналитикиПриложений.ВидПриложения
	             	  |			И ИсторияЗапросов.Токен.ОперационнаяСистема = АналитикиПриложений.ОперационнаяСистема
	             	  |ГДЕ
	             	  |	ИсторияЗапросов.Период МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |	И НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	ВТ_ИсторияЗапросов.Период КАК Период,
	             	  |	РАЗНОСТЬДАТ(ВТ_ИсторияЗапросов.Период, МИНИМУМ(ЕСТЬNULL(ВТ_ИсторияЗапросов1.Период, &Завтра)), МИНУТА) КАК Дельта,
	             	  |	ВТ_ИсторияЗапросов.ИмяЗапроса КАК ИмяЗапроса,
	             	  |	ВТ_ИсторияЗапросов.Токен КАК Токен,
	             	  |	ВТ_ИсторияЗапросов.Пользователь КАК Пользователь,
	             	  |	ВТ_ИсторияЗапросов.Холдинг КАК Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_Сеансы
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов1
	             	  |		ПО ВТ_ИсторияЗапросов.Токен = ВТ_ИсторияЗапросов1.Токен
	             	  |			И ВТ_ИсторияЗапросов.Период < ВТ_ИсторияЗапросов1.Период
	             	  |ГДЕ
	             	  |	ВТ_ИсторияЗапросов.Токен <> ЗНАЧЕНИЕ(Справочник.Токены.ПустаяСсылка)
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.Период,
	             	  |	ВТ_ИсторияЗапросов.ИмяЗапроса,
	             	  |	ВТ_ИсторияЗапросов.Токен,
	             	  |	ВТ_ИсторияЗапросов.Пользователь,
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала КАК Период,
	             	  |	ВТ_Сеансы.Холдинг КАК Холдинг,
	             	  |	ВТ_Сеансы.АналитикаПриложений КАК АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Сеансов) КАК Показатель,
	             	  |	&ПериодОтчета КАК ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ВТ_Сеансы.Токен) КАК Количество
	             	  |ИЗ
	             	  |	ВТ_Сеансы КАК ВТ_Сеансы
	             	  |ГДЕ
	             	  |	ВТ_Сеансы.Дельта > 30
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_Сеансы.Холдинг,
	             	  |	ВТ_Сеансы.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Регистраций),
	             	  |	&ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.Пользователь)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |ГДЕ
	             	  |	ВТ_ИсторияЗапросов.Пользователь.ДатаРегистрации МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.АктивныхПользователей),
	             	  |	&ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.Пользователь)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.ЗаписейНаСобытие),
	             	  |	&ПериодОтчета,
	             	  |	СУММА(ВЫБОР
	             	  |			КОГДА ВТ_ИсторияЗапросов.ИмяЗапроса = ""employeeAddChangeBooking""
	             	  |				ТОГДА 1
	             	  |			ИНАЧЕ 0
	             	  |		КОНЕЦ)
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ИМЕЮЩИЕ
	             	  |	СУММА(ВЫБОР
	             	  |			КОГДА ВТ_ИсторияЗапросов.ИмяЗапроса = ""employeeAddChangeBooking""
	             	  |				ТОГДА 1
	             	  |			ИНАЧЕ 0
	             	  |		КОНЕЦ) > 0
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	Токены.Холдинг,
	             	  |	АналитикиПриложений.Ссылка,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Пользователей),
	             	  |	&ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ Токены.Пользователь)
	             	  |ИЗ
	             	  |	Справочник.Токены КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.АналитикиПриложений КАК АналитикиПриложений
	             	  |		ПО Токены.ВидПриложения = АналитикиПриложений.ВидПриложения
	             	  |			И Токены.ОперационнаяСистема = АналитикиПриложений.ОперационнаяСистема
	             	  |ГДЕ
	             	  |	НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |	И Токены.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.ДатаСоздания <= &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	Токены.Холдинг,
	             	  |	АналитикиПриложений.Ссылка";
	
	пЗапрос.УстановитьПараметр("ДатаНачала", НачалоДня(День));
	пЗапрос.УстановитьПараметр("ДатаОкончания", КонецДня(День));
	пЗапрос.УстановитьПараметр("Завтра", КонецДня(День) + 86400);
	пЗапрос.УстановитьПараметр("ПериодОтчета", Перечисления.ПериодыОтчета.День);
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
	Набор.Отбор.Регистратор.Установить(ПолучитьСоздатьРегистраторДвижений(Месяц, Перечисления.ПериодыОтчета.Месяц));
	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ
	             	  |	ИсторияЗапросов.Период КАК Период,
	             	  |	ИсторияЗапросов.ИмяЗапроса КАК ИмяЗапроса,
	             	  |	ИсторияЗапросов.Токен КАК Токен,
	             	  |	ИсторияЗапросов.Токен.Пользователь КАК Пользователь,
	             	  |	ИсторияЗапросов.Токен.Холдинг КАК Холдинг,
	             	  |	АналитикиПриложений.Ссылка КАК АналитикаПриложений
	             	  |ПОМЕСТИТЬ ВТ_ИсторияЗапросов
	             	  |ИЗ
	             	  |	Справочник.ИсторииЗапросов КАК ИсторияЗапросов
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.АналитикиПриложений КАК АналитикиПриложений
	             	  |		ПО ИсторияЗапросов.Токен.ВидПриложения = АналитикиПриложений.ВидПриложения
	             	  |			И ИсторияЗапросов.Токен.ОперационнаяСистема = АналитикиПриложений.ОперационнаяСистема
	             	  |ГДЕ
	             	  |	ИсторияЗапросов.Период МЕЖДУ &ДатаНачала И &ДатаОкончания
	             	  |	И НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала КАК Период,
	             	  |	ВТ_ИсторияЗапросов.Холдинг КАК Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений КАК АналитикаПриложений,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.АктивныхПользователей) КАК Показатель,
	             	  |	&ПериодОтчета КАК ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ ВТ_ИсторияЗапросов.Пользователь) КАК Количество
	             	  |ИЗ
	             	  |	ВТ_ИсторияЗапросов КАК ВТ_ИсторияЗапросов
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ВТ_ИсторияЗапросов.Холдинг,
	             	  |	ВТ_ИсторияЗапросов.АналитикаПриложений
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	Токены.Холдинг,
	             	  |	АналитикиПриложений.Ссылка,
	             	  |	ЗНАЧЕНИЕ(Перечисление.Показатели.Пользователей),
	             	  |	&ПериодОтчета,
	             	  |	КОЛИЧЕСТВО(РАЗЛИЧНЫЕ Токены.Пользователь)
	             	  |ИЗ
	             	  |	Справочник.Токены КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.АналитикиПриложений КАК АналитикиПриложений
	             	  |		ПО Токены.ВидПриложения = АналитикиПриложений.ВидПриложения
	             	  |			И Токены.ОперационнаяСистема = АналитикиПриложений.ОперационнаяСистема
	             	  |ГДЕ
	             	  |	НЕ АналитикиПриложений.Ссылка ЕСТЬ NULL
	             	  |	И Токены.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.ДатаСоздания <= &ДатаОкончания
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	Токены.Холдинг,
	             	  |	АналитикиПриложений.Ссылка
	             	  |
	             	  |ОБЪЕДИНИТЬ ВСЕ
	             	  |
	             	  |ВЫБРАТЬ
	             	  |	&ДатаНачала,
	             	  |	ПоказателиПользователейОбороты.Холдинг,
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
	пЗапрос.УстановитьПараметр("ПериодОтчета", Перечисления.ПериодыОтчета.Месяц);
	пЗапрос.УстановитьПараметр("ПериодОтчетаДень", Перечисления.ПериодыОтчета.День);
	Набор.Загрузить(пЗапрос.Выполнить().Выгрузить());
	Набор.Записать();
		
КонецПроцедуры

Процедура ОповеститьИсточникИнформации() Экспорт
	
	Заголовки	= Новый Соответствие;
	Заголовки.Вставить("Content-Type", "application/json");
		
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ ПЕРВЫЕ 100
	             	  |	ПользователиИзменения.Ссылка КАК Пользователь,
	             	  |	Токены.ВидПриложения КАК ВидПриложения,
	             	  |	МИНИМУМ(Токены.ДатаБлокировки) КАК ДатаБлокировки,
	             	  |	Токены.Холдинг КАК Холдинг
	             	  |ИЗ
	             	  |	Справочник.Пользователи.Изменения КАК ПользователиИзменения
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Токены КАК Токены
	             	  |		ПО ПользователиИзменения.Ссылка = Токены.Пользователь
	             	  |
	             	  |СГРУППИРОВАТЬ ПО
	             	  |	ПользователиИзменения.Ссылка,
	             	  |	Токены.Сеть,
	             	  |	Токены.ВидПриложения,
	             	  |	Токены.Холдинг";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	
	Узел	= ОбщегоНазначенияПовторноеИспользование.УзелРегистрацияПользователя(Перечисления.ТипыРегистрации.Регистрация);
	
	Пока Выборка.Следующий() Цикл	
		СтруктураЗапроса = РаботаСHTTP.СтруктураВнешнегоHTTPЗапроса(?(Выборка.ДатаБлокировки = Дата(1,1,1), "registerAccount", "unregisterAccount"), Выборка.Холдинг);
		Если СтруктураЗапроса.Количество() > 0 Тогда			
			СтруктураHTTPЗапроса	= Новый Структура;
			СтруктураHTTPЗапроса.Вставить("userId", XMLСтрока(Выборка.Пользователь));
			СтруктураHTTPЗапроса.Вставить("language", "en");
			СтруктураHTTPЗапроса.Вставить("appType", XMLСтрока(Выборка.ВидПриложения));			
			HTTPСоединение	= Новый HTTPСоединение(СтруктураЗапроса.Сервер,, СтруктураЗапроса.УчетнаяЗапись, СтруктураЗапроса.Пароль,, СтруктураЗапроса.Таймаут, ?(СтруктураЗапроса.ЗащищенноеСоединение, Новый ЗащищенноеСоединениеOpenSSL(), Неопределено), СтруктураЗапроса.ИспользоватьАутентификациюОС);
			ЗапросHTTP = Новый HTTPЗапрос(СтруктураЗапроса.URL + СтруктураЗапроса.Приемник, Заголовки);
			ЗапросHTTP.УстановитьТелоИзСтроки(РаботаСHTTP.СтруктуруВПараметрыHTTPЗапроса(СтруктураHTTPЗапроса));			
			ОтветHTTP	= HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);
			Если ОтветHTTP.КодСостояния = 200 Тогда
				ПланыОбмена.УдалитьРегистрациюИзменений(Узел, Выборка.Пользователь);
			КонецЕсли;
		Иначе
			ПланыОбмена.УдалитьРегистрациюИзменений(Узел, Выборка.Пользователь);
		КонецЕсли;	
	КонецЦикла;
	
КонецПроцедуры

Процедура ПроверитьАктуальностьТокенов() Экспорт
	
	//Проверка актуальности токенов для ОС Android	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ 
	             	  |	Токены.Ссылка КАК Токен,
	             	  |	РАЗНОСТЬДАТ(ЕСТЬNULL(ЗарегистрированныеУстройства.ДатаЗаписи, ДАТАВРЕМЯ(1, 1, 1)), &ТекущаяДата, ДЕНЬ) КАК АктуальностьЗаписи,
	             	  |	ЕСТЬNULL(ЗарегистрированныеУстройства.ТокенУстройства, """") КАК ТокенУстройства,
	             	  |	""GCM"" КАК ТипПодписчика,
	             	  |	Токены.Сеть КАК Сеть,
	             	  |	Токены.ВидПриложения КАК ВидПриложения,
	             	  |	Токены.ОперационнаяСистема КАК ОперационнаяСистема
	             	  |ПОМЕСТИТЬ ВТ
	             	  |ИЗ
	             	  |	Справочник.Токены КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЗарегистрированныеУстройства КАК ЗарегистрированныеУстройства
	             	  |		ПО (ЗарегистрированныеУстройства.Токен = Токены.Ссылка)
	             	  |ГДЕ
	             	  |	Токены.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)
	             	  |	И Токены.ОперационнаяСистема = ЗНАЧЕНИЕ(Перечисление.ОперационныеСистемы.Android)
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ ПЕРВЫЕ 100
	             	  |	ЕСТЬNULL(СертификатПриложенияДляСети.Сертификат, СертификатПриложенияОбщий.Сертификат) КАК Сертификат,
	             	  |	ВТ.Токен КАК Токен,
	             	  |	ВТ.ТокенУстройства КАК ТокенУстройства,
	             	  |	ВТ.ТипПодписчика КАК ТипПодписчика,
	             	  |	ВТ.ОперационнаяСистема КАК ОперационнаяСистема
	             	  |ИЗ
	             	  |	ВТ КАК ВТ
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.СертификатыПриложений КАК СертификатПриложенияДляСети
	             	  |		ПО ВТ.Сеть = СертификатПриложенияДляСети.Сеть
	             	  |			И ВТ.ВидПриложения = СертификатПриложенияДляСети.ВидПриложения
	             	  |			И ВТ.ОперационнаяСистема = СертификатПриложенияДляСети.ОперационнаяСистема
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.СертификатыПриложений КАК СертификатПриложенияОбщий
	             	  |		ПО (СертификатПриложенияОбщий.Сеть = ЗНАЧЕНИЕ(Справочник.Сети.ПустаяСсылка))
	             	  |			И ВТ.ВидПриложения = СертификатПриложенияОбщий.ВидПриложения
	             	  |			И ВТ.ОперационнаяСистема = СертификатПриложенияОбщий.ОперационнаяСистема
	             	  |ГДЕ
	             	  |	ВТ.АктуальностьЗаписи > 7";
	
	пЗапрос.УстановитьПараметр("ТекущаяДата", УниверсальноеВремя(ТекущаяДата()));
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	ТаблицаПоиска		= РезультатЗапроса.Выгрузить();
	Выборка				= РезультатЗапроса.Выбрать();	
	
	Уведомление	= Неопределено;
	Сч			= 0;
	
	Пока Выборка.Следующий() Цикл
		
		Если Выборка.ТокенУстройства = "" Тогда
			Справочники.Токены.ЗаблокироватьТокенПользователя(Выборка.Токен);			
		ИначеЕсли Выборка.ТокенУстройства <> "" Тогда
			Если Уведомление = Неопределено Тогда
				Уведомление	= Новый ДоставляемоеУведомление;	
			КонецЕсли;						
			Уведомление.Получатели.Добавить(РаботаССообщениями.ПолучательPush(Выборка.ТокенУстройства, Выборка.ТипПодписчика));			
			Сч	= Сч + 1;
		КонецЕсли;
		
		Если Сч = 10 Тогда 
			Сч = 0;
			Уведомление.Данные				= РаботаССообщениями.ДанныеPush("registerDevice");
			Уведомление.Заголовок			= "";
			Уведомление.Текст				= "registerDevice";
			Уведомление.ЗвуковоеОповещение	= ЗвуковоеОповещение.ПоУмолчанию;
			
			ИсключенныеПолучатели	= Новый Массив;			
			ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, ОбщегоНазначенияПовторноеИспользование.ДанныеАутентификации(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
						
			Если ИсключенныеПолучатели.Количество() > 0 Тогда				
				Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
					НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "ТокенУстройства");					
					Если НайденаяСтрока <> Неопределено Тогда						
						Справочники.Токены.ЗаблокироватьТокенПользователя(НайденаяСтрока.Токен);
						ТаблицаПоиска.Удалить(НайденаяСтрока);
					КонецЕсли;					
				КонецЦикла;				
			КонецЕсли;			
			Уведомление	= Неопределено;			
		КонецЕсли;
		
	КонецЦикла;			
			
	Если Уведомление <> Неопределено Тогда
		Уведомление.Данные				= РаботаССообщениями.ДанныеPush("registerDevice");
		Уведомление.Заголовок			= "";
		Уведомление.Текст				= "registerDevice";
		Уведомление.ЗвуковоеОповещение	= ЗвуковоеОповещение.ПоУмолчанию;
		
		ИсключенныеПолучатели	= Новый Массив;			
		ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, ОбщегоНазначенияПовторноеИспользование.ДанныеАутентификации(Выборка.ОперационнаяСистема, Выборка.Сертификат), ИсключенныеПолучатели);
		
		Если ИсключенныеПолучатели.Количество() > 0 Тогда				
			Для Каждого ИсключаемыйПолучатель Из ИсключенныеПолучатели Цикл
				НайденаяСтрока	= ТаблицаПоиска.Найти(ИсключаемыйПолучатель, "ТокенУстройства");					
				Если НайденаяСтрока <> Неопределено Тогда					
					Справочники.Токены.ЗаблокироватьТокенПользователя(НайденаяСтрока.Токен);
					ТаблицаПоиска.Удалить(НайденаяСтрока);
				КонецЕсли;					
			КонецЦикла;				
		КонецЕсли;			
		Уведомление	= Неопределено;
	КонецЕсли;
	
	
	//Проверка актуальности токенов для ОС iOS	
	
	
	
	//Блокируем токены в МП тренера по уволенным сотрудникам	
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст = "ВЫБРАТЬ
	                |	Токены.Ссылка КАК Токен
	                |ИЗ
	                |	Справочник.Токены КАК Токены
	                |ГДЕ
	                |	Токены.ВидПриложения = ЗНАЧЕНИЕ(Перечисление.ВидыПриложений.Employee)
	                |	И Токены.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)
	                |	И Токены.Пользователь.ТипПользователя <> ""employee""";
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		Справочники.Токены.ЗаблокироватьТокенПользователя(Выборка.Токен);
	КонецЦикла;		
	
КонецПроцедуры