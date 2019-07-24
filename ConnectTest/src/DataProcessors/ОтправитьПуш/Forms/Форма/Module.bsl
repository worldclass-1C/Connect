
&НаКлиенте
Процедура ОтправитьПуш(Команда)
	ОтправитьПушНаСервере();
КонецПроцедуры

&НаСервере
Процедура ОтправитьПушНаСервере()
	
	//--Подготовка заголовка пуш messages
	МассивСловНовый	= Новый Массив;
	МассивСлов		= СтрРазделить(пЗаголовок, " ");	
	Для Каждого Слово Из МассивСлов Цикл		
		Если Найти(Слово, "#emj") > 0 Тогда			
			Слово	= РаскодироватьСтроку(СтрЗаменить(Слово, "#emj", ""), СпособКодированияСтроки.КодировкаURL);
		КонецЕсли;
		МассивСловНовый.Добавить(Слово);
	КонецЦикла;	
	ЗаголовокПуш	= СтрСоединить(МассивСловНовый, " ");
	
	//--Подготовка текста пуш messages
	//НЕ ЗАБЫТЬ ЧТО СМАЙЛИК ДОЛЖЕН БЫТЬ В ФОРМАТЕ %F0%9F%8F%8B%20
	МассивСловНовый	= Новый Массив;
	МассивСлов		= СтрРазделить(Текст, " ");	
	Для Каждого Слово Из МассивСлов Цикл		
		Если Найти(Слово, "#emj") > 0 Тогда			
			Слово	= РаскодироватьСтроку(СтрЗаменить(Слово, "#emj", ""), СпособКодированияСтроки.КодировкаURL);
		КонецЕсли;
		МассивСловНовый.Добавить(Слово);
	КонецЦикла;	
	ТекстПуш	= СтрСоединить(МассивСловНовый, " ");
		
	ЗаписьJSON		= Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
		
	пЗапрос	= Новый Запрос;
	пЗапрос.text	= "ВЫБРАТЬ
	             	  |	Токены.Ссылка КАК token,
	             	  |	ЕСТЬNULL(ЗарегистрированныеУстройства.recordDate, ДАТАВРЕМЯ(1, 1, 1)) КАК recordDate,
	             	  |	ЕСТЬNULL(ЗарегистрированныеУстройства.deviceToken, """") КАК deviceToken,
	             	  |	ВЫБОР
	             	  |		КОГДА Токены.systemType = ЗНАЧЕНИЕ(Перечисление.systemTypes.Android)
	             	  |			ТОГДА ""GCM""
	             	  |		ИНАЧЕ ""APNS""
	             	  |	КОНЕЦ КАК ТипПодписчика,
	             	  |	Токены.chain КАК chain,
	             	  |	Токены.appType КАК appType,
	             	  |	Токены.systemType КАК systemType
	             	  |ПОМЕСТИТЬ ВТ
	             	  |ИЗ
	             	  |	Справочник.tokens КАК Токены
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.registeredDevices КАК ЗарегистрированныеУстройства
	             	  |		ПО (ЗарегистрированныеУстройства.token = Токены.Ссылка)
	             	  |ГДЕ
	             	  |	Токены.user В(&МассивПользователей)
	             	  |	И Токены.Ссылка В(&МассивТокенов)
	             	  |	И Токены.lockDate = ДАТАВРЕМЯ(1, 1, 1)
	             	  |;
	             	  |
	             	  |////////////////////////////////////////////////////////////////////////////////
	             	  |ВЫБРАТЬ
	             	  |	ВТ.token КАК token,
	             	  |	ВТ.recordDate КАК recordDate,
	             	  |	ВТ.deviceToken КАК deviceToken,
	             	  |	ВТ.ТипПодписчика КАК ТипПодписчика,
	             	  |	ВТ.systemType КАК systemType,
	             	  |	ЕСТЬNULL(СертификатПриложенияДляСети.certificate, СертификатПриложенияОбщий.certificate) КАК certificate
	             	  |ИЗ
	             	  |	ВТ КАК ВТ
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияДляСети
	             	  |		ПО ВТ.chain = СертификатПриложенияДляСети.chain
	             	  |			И ВТ.appType = СертификатПриложенияДляСети.appType
	             	  |			И ВТ.systemType = СертификатПриложенияДляСети.systemType
	             	  |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.applicationsCertificates КАК СертификатПриложенияОбщий
	             	  |		ПО (СертификатПриложенияОбщий.chain = ЗНАЧЕНИЕ(Справочник.chain.ПустаяСсылка))
	             	  |			И ВТ.appType = СертификатПриложенияОбщий.appType
	             	  |			И ВТ.systemType = СертификатПриложенияОбщий.systemType";
	
	пЗапрос.УстановитьПараметр("МассивПользователей", Пользователи.Выгрузить().ВыгрузитьКолонку("user"));
	
	МассивТокенов	= Пользователи.Выгрузить().ВыгрузитьКолонку("token");
	Если МассивТокенов.Количество() = 0 Тогда
		пЗапрос.text	= СтрЗаменить(пЗапрос.Текст, "И Токены.Ссылка В (&МассивТокенов)", "");	
	Иначе
		пЗапрос.УстановитьПараметр("МассивТокенов", МассивТокенов);
	КонецЕсли;
	
	Выборка	= пЗапрос.Выполнить().Выбрать();
		
	Пока Выборка.Следующий() Цикл
		Если Выборка.deviceToken <> "" Тогда
			Уведомление				= Новый ДоставляемоеУведомление;
			Уведомление.title	= ЗаголовокПуш;
			Уведомление.text		= ТекстПуш;
			Уведомление.Данные		= Messages.ДанныеPush(action, objectId, objectType, noteId);			
			Уведомление.Получатели.Добавить(Messages.ПолучательPush(Выборка.ТокенУстройства, Выборка.ТипПодписчика));
			ИсключенныеПолучатели	= Новый Массив;
			ПроблемыОтправкиДоставляемыхУведомлений	 = Новый Массив;
			ОтправкаДоставляемыхУведомлений.Отправить(Уведомление, GeneralReuse.ДанныеАутентификации(Выборка.ОперационнаяСистема, Выборка.Сертификат),ИсключенныеПолучатели,, ПроблемыОтправкиДоставляемыхУведомлений);
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры
