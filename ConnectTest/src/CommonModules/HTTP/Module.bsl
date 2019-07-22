
Function getStructureFromRequestBody(body) Export
	body	= TrimAll(body);	
	If StrLen(Body) > 0 Then			
		JSONReader = New JSONReader();
		JSONReader.SetString(body);
		RequestStruct   = ReadJSON(JSONReader);
		JSONReader.Close();
		Return RequestStruct;
	Else
		Return New Structure;
	EndIf;	
EndFunction

Function getStructureFromRequest(request) Export
	requestBody = request.GetBodyAsString();
	requestStruct = HTTP.GetStructureFromRequestBody(requestBody);
	Return New Structure("requestStruct, requestBody", requestStruct, requestBody);
EndFunction

Function getJSONFromStructure(struct) Export
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, struct);
	Return JSONWriter.Close();
EndFunction

Function prepareRequestBody(val token, val requestStruct, val user,
		val language, val timezone, val appType) Export

	If TypeOf(requestStruct) = Type("Structure") Then
		JSONStruct = requestStruct;
	Else
		JSONStruct = New Structure;
		JSONStruct.Insert("array", requestStruct);
	EndIf;

	JSONStruct.Insert("token", token);
	JSONStruct.Insert("language", language);
	JSONStruct.Insert("userId", XMLString(user));
	JSONStruct.Insert("currentTime", ToLocalTime(ToUniversalTime(CurrentDate()), timezone));
	If appType = Enums.ВидыПриложений.Customer Then
		JSONStruct.Insert("appType", "Customer");
	ElsIf appType = Enums.ВидыПриложений.Employee Then
		JSONStruct.Insert("appType", "Employee");
	ElsIf appType = Enums.ВидыПриложений.Web Then
		JSONStruct.Insert("appType", "Web");
	Else
		JSONStruct.Insert("appType", TrimAll(appType));
	EndIf;

	Return HTTP.GetJSONFromStructure(JSONStruct);

EndFunction

Function checkBackgroundJobs(array) Export

	answer = New Structure();	
	
	For Each struct In array Do
		If struct.ФЗ.Состояние = BackgroundJobState.Active Then
			backgroundJob = struct.ФЗ.WaitForExecutionCompletion(25);
			If backgroundJob.State <> BackgroundJobState.Active Then				
				JSONReader = New JSONReader();
				JSONReader.SetString(GetFromTempStorage(struct.Адрес));
				answer.Insert(struct.Атрибут, ReadJSON(JSONReader));
				JSONReader.Close();
			EndIf;
		Else			
			JSONReader = New JSONReader();
			JSONReader.SetString(GetFromTempStorage(struct.Адрес));
			answer.Insert(struct.Атрибут, ReadJSON(JSONReader));
			JSONReader.Close();
		EndIf;	
	EndDo;

	If answer.Count() > 0 Then
		JSONWriter = New JSONWriter();
		JSONWriter.SetString();
		WriteJSON(JSONWriter, answer);
		Return JSONWriter.Close();
	Else
		Return "";	
	EndIf;

EndFunction

Function getRequestStructure(request, holding) Export

	requestStruct = New Structure;
	
	query = New Query();
	query.Text = "ВЫБРАТЬ
	|	ПодключенияХолдинговКИсточникамИнформации.Холдинг КАК Холдинг,
	|	ПодключенияХолдинговКИсточникамИнформации.ИсточникИнформации КАК ИсточникИнформации,
	|	ПодключенияХолдинговКИсточникамИнформации.Сервер КАК Сервер,
	|	ПодключенияХолдинговКИсточникамИнформации.Порт КАК Порт,
	|	ПодключенияХолдинговКИсточникамИнформации.Пользователь КАК Пользователь,
	|	ПодключенияХолдинговКИсточникамИнформации.Пароль КАК Пароль,
	|	ПодключенияХолдинговКИсточникамИнформации.URL КАК URL,
	|	ПодключенияХолдинговКИсточникамИнформации.Таймаут КАК Таймаут,
	|	ПодключенияХолдинговКИсточникамИнформации.ЗащищенноеСоединение КАК ЗащищенноеСоединение,
	|	ПодключенияХолдинговКИсточникамИнформации.ИспользоватьАутентификациюОС КАК ИспользоватьАутентификациюОС
	|ПОМЕСТИТЬ ВТ
	|ИЗ
	|	РегистрСведений.ПодключенияХолдинговКИсточникамИнформации КАК ПодключенияХолдинговКИсточникамИнформации
	|ГДЕ
	|	ПодключенияХолдинговКИсточникамИнформации.Холдинг = &holding
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ.Сервер КАК Сервер,
	|	ВТ.Порт КАК Порт,
	|	ВТ.Пользователь КАК УчетнаяЗапись,
	|	ВТ.Пароль КАК Пароль,
	|	ВТ.Таймаут КАК Таймаут,
	|	ВТ.ЗащищенноеСоединение КАК ЗащищенноеСоединение,
	|	ВТ.ИспользоватьАутентификациюОС КАК ИспользоватьАутентификациюОС,
	|	ВТ.URL КАК URL,
	|	ИсточникиИнформации.ЗапросПриемник КАК Приемник
	|ИЗ
	|	Справочник.СоответствиеЗапросовИсточникамИнформации.ИсточникиИнформации КАК ИсточникиИнформации
	|		INNER СОЕДИНЕНИЕ ВТ КАК ВТ
	|		ПО ИсточникиИнформации.ИсточникИнформации = ВТ.ИсточникИнформации
	|ГДЕ
	|	ИсточникиИнформации.ЗапросИсточник = &request";

	query.SetParameter("holding", holding);
	query.SetParameter("request", request);

	resultQuery = query.Execute();
	If Not resultQuery.IsEmpty() Then
		selection = resultQuery.Select();
		selection.Next();
		requestStruct.Insert("Сервер", selection.Сервер);
		requestStruct.Insert("Порт", selection.Порт);
		requestStruct.Insert("УчетнаяЗапись", selection.УчетнаяЗапись);
		requestStruct.Insert("Пароль", selection.Пароль);
		requestStruct.Insert("Таймаут", selection.Таймаут);
		requestStruct.Insert("ЗащищенноеСоединение", selection.ЗащищенноеСоединение);
		requestStruct.Insert("ИспользоватьАутентификациюОС", selection.ИспользоватьАутентификациюОС);
		requestStruct.Insert("URL", selection.URL);
		requestStruct.Insert("Приемник", selection.Приемник);
	EndIf;

	Return requestStruct;

EndFunction

Function getRequestHeader(request, key) Export
	value	= request.Headers.Получить(Title(key));
	If value = Undefined Then
		value	= request.Headers.Get(Lower(key));
	EndIf;
	If value = Undefined Then
		value	= request.Headers.Get(Upper(key));
	EndIf;
	Return Lower(value);
EndFunction

Procedure runRequestInAccountingSystem(selection, headers, body, link,
		RequestParametersFromURL) Export
	HTTPConnection = New HTTPConnection(selection.Сервер, , selection.УчетнаяЗапись, selection.Пароль, , selection.Таймаут, ?(selection.ЗащищенноеСоединение, New OpenSSLSecureConnection(), Undefined), selection.ИспользоватьАутентификациюОС);
	HTTPRequest = New HTTPRequest(selection.URL + selection.Приемник
		+ RequestParametersFromURL, headers);
	HTTPRequest.SetBodyFromString(body);
	If selection.ТипЗапроса = Enums.ТипыHTTPЗапросов.GET Then
		HTTPResponse = HTTPConnection.Get(HTTPRequest);
	Else
		HTTPResponse = HTTPConnection.Post(HTTPRequest);
	EndIf;
	PutToTempStorage(HTTPResponse.GetBodyAsString(), link);
EndProcedure