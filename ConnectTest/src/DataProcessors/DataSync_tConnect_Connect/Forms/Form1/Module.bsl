
&НаСервере
Процедура ВыгрузитьНаСервере()
	
	Сервер			= "solutions.worldclass.ru";
	Пользователь	= "";
	Пароль			= "";
	Таймаут			= 30;	
	URL				= "API/hs/internal/edit";
	
	Заголовки	= Новый Соответствие;
	Заголовки.Вставить("Content-Type", "application/json");
	Заголовки.Вставить("request", "request");
	Заголовки.Вставить("auth-key", "76a5daac-e434-11e9-bba9-005056b11c47");
	
	HTTPСоединение	= Новый HTTPСоединение(Сервер,, Пользователь, Пароль,, Таймаут, Новый ЗащищенноеСоединениеOpenSSL(), Ложь);	
	ЗапросHTTP = Новый HTTPЗапрос(URL, Заголовки);		
	ТелоЗапроса	= ПолучитьТелоЗапроса(Запросы.Выгрузить().ВыгрузитьКолонку("Запрос"));		
	ЗапросHTTP.УстановитьТелоИзСтроки(ТелоЗапроса);			
	ОтветHTTP	= HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);		
	JSONСтрока	= ОтветHTTP.ПолучитьТелоКакСтроку();
	Сообщить(JSONСтрока);

КонецПроцедуры

&НаСервере
Функция ПолучитьТелоЗапроса(МассивЗапросов)
	
	МассивJSON		= Новый Массив;	
	ЗаписьJSON		= Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку(); 		
		
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.Ссылка КАК Ссылка,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.Ссылка.Код КАК Код,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.Атрибут КАК Атрибут,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.ВыполнятьВФоне КАК ВыполнятьВФоне,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.ЗапросИсточник КАК ЗапросИсточник,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.ЗапросПриемник КАК ЗапросПриемник,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.ИсточникИнформации КАК ИсточникИнформации,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.НеИспользовать КАК НеИспользовать,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.НеСохранятьОтветВЛогах КАК НеСохранятьОтветВЛогах,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.СжиматьЛоги КАК СжиматьЛоги,
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.ТолькоДляСотрудников КАК ТолькоДляСотрудников
	             	  |ИЗ
	             	  |	Справочник.СоответствиеЗапросовИсточникамИнформации.ИсточникиИнформации КАК СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации
	             	  |ГДЕ
	             	  |	СоответствиеЗапросовИсточникамИнформацииИсточникиИнформации.Ссылка В(&МассивЗапросов)
	             	  |ИТОГИ
	             	  |	МАКСИМУМ(Код),
	             	  |	МАКСИМУМ(ВыполнятьВФоне),
	             	  |	МАКСИМУМ(НеСохранятьОтветВЛогах),
	             	  |	МАКСИМУМ(СжиматьЛоги),
	             	  |	МАКСИМУМ(ТолькоДляСотрудников)
	             	  |ПО
	             	  |	Ссылка";
	
	пЗапрос.УстановитьПараметр("МассивЗапросов", МассивЗапросов);
	Выборка	= пЗапрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);	
	
	Пока Выборка.Следующий() Цикл
		СтруктураЗапроса	= Новый Структура;
		СтруктураЗапроса.Вставить("uid", XMLСтрока(Выборка.Ссылка));
		СтруктураЗапроса.Вставить("code", Выборка.Код);
		СтруктураЗапроса.Вставить("background", XMLСтрока(Выборка.ВыполнятьВФоне));
		СтруктураЗапроса.Вставить("notSaveLogs", XMLСтрока(Выборка.НеСохранятьОтветВЛогах));
		СтруктураЗапроса.Вставить("compressLogs", XMLСтрока(Выборка.СжиматьЛоги));
		СтруктураЗапроса.Вставить("staffOnly", XMLСтрока(Выборка.ТолькоДляСотрудников));
		
		ВыборкаДеталей	= Выборка.Выбрать();
		МассивИсточниковИнформации	= Новый Массив;
		Пока ВыборкаДеталей.Следующий() Цикл			
			ИсточникИнформации	= Новый Структура;
			ИсточникИнформации.Вставить("atribute", ВыборкаДеталей.Атрибут);		
			ИсточникИнформации.Вставить("background", XMLСтрока(ВыборкаДеталей.ВыполнятьВФоне));
			ИсточникИнформации.Вставить("requestSource", ВыборкаДеталей.ЗапросИсточник);
			ИсточникИнформации.Вставить("requestReceiver", ВыборкаДеталей.ЗапросПриемник);
			ИсточникИнформации.Вставить("notUse", XMLСтрока(ВыборкаДеталей.НеИспользовать));
			ИсточникИнформации.Вставить("notSaveLogs", XMLСтрока(ВыборкаДеталей.НеСохранятьОтветВЛогах));
			ИсточникИнформации.Вставить("compressLogs", XMLСтрока(ВыборкаДеталей.СжиматьЛоги));
			ИсточникИнформации.Вставить("staffOnly", XMLСтрока(ВыборкаДеталей.ТолькоДляСотрудников));
			
			СтруктураИсточникаИнформации	= Новый Структура;
			СтруктураИсточникаИнформации.Вставить("uid", XMLСтрока(ВыборкаДеталей.ИсточникИнформации));
			ИсточникИнформации.Вставить("informationSource", СтруктураИсточникаИнформации);
			
			МассивИсточниковИнформации.Добавить(ИсточникИнформации);
		КонецЦикла;
		
		СтруктураЗапроса.Вставить("informationSources", МассивИсточниковИнформации);
		
		МассивJSON.Добавить(СтруктураЗапроса);
	КонецЦикла;		
	
	ЗаписатьJSON(ЗаписьJSON, МассивJSON);
	
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции 

&НаСервере
Функция ПолучитьТелоЗапроса2(МассивОшибок)
	
	МассивJSON		= Новый Массив;	
	ЗаписьJSON		= Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку(); 		
		
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "SELECT
	             	  |	errorDescriptionstranslation.language AS language,
	             	  |	errorDescriptionstranslation.description AS description,
	             	  |	errorDescriptionstranslation.Ref AS Ref,
	             	  |	errorDescriptionstranslation.Ref.Parent AS Parent
	             	  |FROM
	             	  |	Catalog.errorDescriptions.translation AS errorDescriptionstranslation
	             	  |WHERE
	             	  |	errorDescriptionstranslation.Ref IN(&МассивОшибок)
	             	  |TOTALS
	             	  |	MAX(Parent)
	             	  |BY
	             	  |	Ref";
	
	пЗапрос.УстановитьПараметр("МассивОшибок", МассивОшибок);
	Выборка	= пЗапрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);	
	
	Пока Выборка.Следующий() Цикл
		СтруктураЗапроса	= Новый Структура;
		СтруктураЗапроса.Вставить("uid", XMLСтрока(Выборка.Ref));		
		СтруктураИсточникаИнформации	= Новый Структура;
		СтруктураИсточникаИнформации.Вставить("uid", XMLСтрока(Выборка.Parent));
		СтруктураЗапроса.Вставить("parent", СтруктураИсточникаИнформации);
		
		ВыборкаДеталей	= Выборка.Выбрать();
		МассивИсточниковИнформации	= Новый Массив;
		Пока ВыборкаДеталей.Следующий() Цикл			
			ИсточникИнформации	= Новый Структура;
			ИсточникИнформации.Вставить("language", ВыборкаДеталей.language);					
			ИсточникИнформации.Вставить("description", ВыборкаДеталей.description);			
			МассивИсточниковИнформации.Добавить(ИсточникИнформации);
		КонецЦикла;
		
		СтруктураЗапроса.Вставить("translation", МассивИсточниковИнформации);
		
		МассивJSON.Добавить(СтруктураЗапроса);
	КонецЦикла;		
	
	ЗаписатьJSON(ЗаписьJSON, МассивJSON);
	
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции 

&НаКлиенте
Процедура Выгрузить(Команда)
	ВыгрузитьНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура ЗаполнитьВсе(Команда)
	ЗаполнитьВсеНаСервере();
КонецПроцедуры

&НаСервере
Процедура ЗаполнитьВсеНаСервере()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"SELECT
		|	matchingRequestsInformationSources.Ref AS Ref
		|FROM
		|	Catalog.matchingRequestsInformationSources AS matchingRequestsInformationSources";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Пока Выборка.Следующий() Цикл
		НоваяСтрока	= Запросы.Добавить();
		НоваяСтрока.Запрос = Выборка.Ref;
	КонецЦикла;
	
	
КонецПроцедуры

&AtServer
Procedure ЗаполнитьAtServer()
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"SELECT
		|	errorDescriptions.Ref AS Ref
		|FROM
		|	Catalog.errorDescriptions AS errorDescriptions";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Пока Выборка.Следующий() Цикл
		НоваяСтрока	= Errors.Add();
		НоваяСтрока.Error = Выборка.Ref;
	КонецЦикла;
	
EndProcedure

&AtClient
Procedure Заполнить(Command)
	ЗаполнитьAtServer();
EndProcedure

&AtClient
Procedure Выгрузить2(Command)
	Выгрузить2AtServer();
EndProcedure

&AtServer
Procedure Выгрузить2AtServer()
	
	Сервер			= "solutions.worldclass.ru";
	Пользователь	= "";
	Пароль			= "";
	Таймаут			= 30;	
	URL				= "API/hs/internal/edit";
	
	Заголовки	= Новый Соответствие;
	Заголовки.Вставить("Content-Type", "application/json");
	Заголовки.Вставить("request", "adderrordescription");
	Заголовки.Вставить("auth-key", "76a5daac-e434-11e9-bba9-005056b11c47");
	
	HTTPСоединение	= Новый HTTPСоединение(Сервер,, Пользователь, Пароль,, Таймаут, Новый ЗащищенноеСоединениеOpenSSL(), Ложь);	
	ЗапросHTTP = Новый HTTPЗапрос(URL, Заголовки);		
	ТелоЗапроса	= ПолучитьТелоЗапроса2(Errors.Выгрузить().ВыгрузитьКолонку("Error"));		
	ЗапросHTTP.УстановитьТелоИзСтроки(ТелоЗапроса);			
	//ОтветHTTP	= HTTPСоединение.ОтправитьДляОбработки(ЗапросHTTP);		
	//JSONСтрока	= ОтветHTTP.ПолучитьТелоКакСтроку();
	//Сообщить(JSONСтрока);

EndProcedure
