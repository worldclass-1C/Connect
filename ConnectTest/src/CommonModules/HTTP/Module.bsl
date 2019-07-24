
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
	If appType = Enums.appTypes.Customer Then
		JSONStruct.Insert("appType", "Customer");
	ElsIf appType = Enums.appTypes.Employee Then
		JSONStruct.Insert("appType", "Employee");
	ElsIf appType = Enums.appTypes.Web Then
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
	|	ПодключенияХолдинговКИсточникамИнформации.holding КАК holding,
	|	ПодключенияХолдинговКИсточникамИнформации.informationSource КАК informationSource,
	|	ПодключенияХолдинговКИсточникамИнформации.server КАК server,
	|	ПодключенияХолдинговКИсточникамИнформации.port КАК port,
	|	ПодключенияХолдинговКИсточникамИнформации.user КАК user,
	|	ПодключенияХолдинговКИсточникамИнформации.password КАК password,
	|	ПодключенияХолдинговКИсточникамИнформации.URL КАК URL,
	|	ПодключенияХолдинговКИсточникамИнформации.timeout КАК timeout,
	|	ПодключенияХолдинговКИсточникамИнформации.secureConnection КАК secureConnection,
	|	ПодключенияХолдинговКИсточникамИнформации.UseOSAuthentication КАК UseOSAuthentication
	|ПОМЕСТИТЬ ВТ
	|ИЗ
	|	РегистрСведений.holdingsConnectionsInformationSources КАК ПодключенияХолдинговКИсточникамИнформации
	|ГДЕ
	|	ПодключенияХолдинговКИсточникамИнформации.holding = &holding
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ВТ.server КАК server,
	|	ВТ.port КАК port,
	|	ВТ.user КАК УчетнаяЗапись,
	|	ВТ.password КАК password,
	|	ВТ.timeout КАК timeout,
	|	ВТ.secureConnection КАК secureConnection,
	|	ВТ.UseOSAuthentication КАК UseOSAuthentication,
	|	ВТ.URL КАК URL,
	|	informationSources.requestReceiver КАК Приемник
	|ИЗ
	|	Справочник.matchingRequestsInformationSources.informationSources КАК informationSources
	|		INNER СОЕДИНЕНИЕ ВТ КАК ВТ
	|		ПО informationSources.informationSource = ВТ.informationSource
	|ГДЕ
	|	informationSources.requestSource = &request";

	query.SetParameter("holding", holding);
	query.SetParameter("request", request);

	resultQuery = query.Execute();
	If Not resultQuery.IsEmpty() Then
		selection = resultQuery.Select();
		selection.Next();
		requestStruct.Insert("server", selection.Сервер);
		requestStruct.Insert("port", selection.Порт);
		requestStruct.Insert("УчетнаяЗапись", selection.УчетнаяЗапись);
		requestStruct.Insert("password", selection.Пароль);
		requestStruct.Insert("timeout", selection.Таймаут);
		requestStruct.Insert("secureConnection", selection.ЗащищенноеСоединение);
		requestStruct.Insert("UseOSAuthentication", selection.ИспользоватьАутентификациюОС);
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
	HTTPConnection = New HTTPConnection(selection.server, , selection.УчетнаяЗапись, selection.password, , selection.timeout, ?(selection.ЗащищенноеСоединение, New OpenSSLSecureConnection(), Undefined), selection.UseOSAuthentication);
	HTTPRequest = New HTTPRequest(selection.URL + selection.Приемник
		+ RequestParametersFromURL, headers);
	HTTPRequest.SetBodyFromString(body);
	If selection.HTTPRequestType = Enums.HTTPRequestTypes.GET Then
		HTTPResponse = HTTPConnection.Get(HTTPRequest);
	Else
		HTTPResponse = HTTPConnection.Post(HTTPRequest);
	EndIf;
	PutToTempStorage(HTTPResponse.GetBodyAsString(), link);
EndProcedure