
&AtServer
Procedure fillAtServer()
	// Insert handler content.
EndProcedure

&AtServer
Procedure unloadAtServer()
	
	requestName = "";
	
	If Items.GroupPages.CurrentPage = Items.Page1 Then
		requestName = "addrequest";
		requestBody	= getRequestBody_Requests(requests.Unload().UnloadColumn("request"));	
	ElsIf Items.GroupPages.CurrentPage = Items.Page2 Then
		requestName = "adderrordescription";
		requestBody	= getRequestBody_Errors(Errors.Unload().UnloadColumn("Error"));
	EndIf;
	
	If requestName <> "" Then
		server = "solutions.worldclass.ru";
		user = "";
		password = "";
		timeout = 30;	
		URL = "API/hs/internal/edit";
		
		headers	= New Map;
		headers.Insert("Content-Type", "application/json");
		headers.Insert("request", requestName);
		headers.Insert("auth-key", "76a5daac-e434-11e9-bba9-005056b11c47");
		headers.Insert("brand", "WorldClass");
		
		HTTPConnection	= New HTTPConnection(server,, user, password,, timeout, New OpenSSLSecureConnection(), False);	
		HTTPRequest = New HTTPRequest(URL, headers);			
		HTTPRequest.SetBodyFromString(requestBody);			
		HTTPResponse = HTTPConnection.Post(HTTPRequest);		
		Message(HTTPResponse.GetBodyAsString());
	Else
		Message("reuest name is empty");
	EndIf;
EndProcedure

&AtServer
Function getRequestBody_Requests(МассивЗапросов)
	
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
	
EndFunction 

&AtServer
Function getRequestBody_Errors(errorsList)
	
	arrayJSON		= New Array();	
	recordJSON		= New JSONWriter();
	recordJSON.УстановитьСтроку(); 		
		
	query	= New Query();
	query.Text	= "SELECT
	          	  |	errorDescriptions.Ref AS Ref,
	          	  |	errorDescriptions.Code AS Code,
	          	  |	errorDescriptions.Parent AS Parent,
	          	  |	errorDescriptions.translation.(
	          	  |		language.Code AS language,
	          	  |		description AS description
	          	  |	) AS translation,
	          	  |	errorDescriptions.IsFolder AS IsFolder
	          	  |FROM
	          	  |	Catalog.errorDescriptions AS errorDescriptions
	          	  |WHERE
	          	  |	errorDescriptions.Ref IN(&errorsList)";
	
	query.SetParameter("errorsList", errorsList);
	select	= query.Execute().Select(QueryResultIteration.ByGroups);	
	
	While select.Next() Do
		requestStruct	= New Structure();
		requestStruct.Insert("uid", XMLString(select.Ref));
		requestStruct.Insert("isfolder", select.IsFolder);
		requestStruct.Insert("code", XMLString(select.code));				
		requestStruct.Insert("parent", New Structure("uid", XMLString(select.Parent)));
		
		arrayInfoSource	= New Array;
		detail = select.translation.Unload();
		For Each record In detail Do
			infoSource	= New Structure();
			infoSource.Insert("language", New Structure("code", record.language));
			infoSource.Insert("description", record.description);			
			arrayInfoSource.add(infoSource);			
		EndDo;
		requestStruct.Insert("translation", arrayInfoSource);
		
		arrayJSON.add(requestStruct);
	EndDo;		
	
	WriteJSON(recordJSON, arrayJSON);
	
	Return recordJSON.Закрыть();
	
EndFunction 

&AtClient
Procedure fill(Command)
	fillAtServer();
EndProcedure

&AtClient
Procedure unload(Command)
	unloadAtServer();	
EndProcedure
