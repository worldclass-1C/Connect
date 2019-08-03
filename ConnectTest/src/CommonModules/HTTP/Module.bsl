
Function processRequest(request) Export

	dateInMilliseconds = CurrentUniversalDateInMilliseconds();

	parameters = New Structure();
	parameters.Insert("url", request.BaseURL + request.RelativeURL);
	parameters.Insert("headersJSON", HTTP.encodeJSON(request.Headers));
	parameters.Insert("requestName", HTTP.getRequestHeader(request, "request"));
	parameters.Insert("language", HTTP.getRequestHeader(request, "language"));
	parameters.Insert("brand", HTTP.getRequestHeader(request, "brand"));
	parameters.Insert("notSaveAnswer", False);
	parameters.Insert("compressAnswer", False);
	parameters.Insert("answerBody", "");
	parameters.Insert("errorDescription", Service.getErrorDescription());

	If Not ValueIsFilled(parameters.requestName) Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noRequest"));	
	ElsIf Not ValueIsFilled(parameters.brand) Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noBrand"));
	ElsIf Not ValueIsFilled(parameters.language) Then
		parameters.Insert("language", "en");
	EndIf;
	If parameters.errorDescription.result = ""
			And parameters.requestName <> "chainlist"
			And parameters.requestName <> "countrycodelist" Then
		Check.legality(request, parameters);
	EndIf;
	If parameters.errorDescription.result = "" Then
		parameters.Insert("requestBody", request.GetBodyAsString());
		parameters.Insert("requestStruct", HTTP.decodeJSON(parameters.requestBody));		
		Try
			General.executeRequestMethod(parameters);
		Except
			parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "system", ErrorDescription()));
		EndTry;
	EndIf;	

	parameters.Insert("duration", CurrentUniversalDateInMilliseconds()
		- DateInMilliseconds);
	parameters.Insert("isError", parameters.errorDescription.result <> "");

	Service.logRequestBackground(parameters);

	Return HTTP.prepareResponse(parameters);

EndFunction

Function decodeJSON(body, isArray = False) Export
	body	= TrimAll(body);	
	If StrLen(Body) > 0 Then			
		JSONReader = New JSONReader();
		JSONReader.SetString(body);
		RequestStruct   = ReadJSON(JSONReader);
		JSONReader.Close();
		Return RequestStruct;
	Else
		Return ?(isArray, New Array(), New Structure());
	EndIf;	
EndFunction

Function encodeJSON(data) Export
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, data);
	Return JSONWriter.Close();
EndFunction

Function prepareRequestBody(val token, val requestStruct, val user,
		val language, val timezone, val appType) Export

	If TypeOf(requestStruct) = Type("Structure") Then
		struct = requestStruct;
	Else
		struct = New Structure;
		struct.Insert("array", requestStruct);
	EndIf;

	struct.Insert("token", token);
	struct.Insert("language", language);
	struct.Insert("userId", XMLString(user));
	struct.Insert("currentTime", ToLocalTime(ToUniversalTime(CurrentDate()), timezone));
	If appType = Enums.appTypes.Customer Then
		struct.Insert("appType", "Customer");
	ElsIf appType = Enums.appTypes.Employee Then
		struct.Insert("appType", "Employee");
	ElsIf appType = Enums.appTypes.Web Then
		struct.Insert("appType", "Web");
	Else
		struct.Insert("appType", TrimAll(appType));
	EndIf;

	Return HTTP.encodeJSON(struct);

EndFunction

Function prepareResponse(parameters) Export	
	If parameters.errorDescription.result <> "" Then
		parameters.Insert("answerBody", HTTP.encodeJSON(parameters.errorDescription));
		If parameters.errorDescription.result = "userNotIdentified" Then
			response = New HTTPServiceResponse(401);
		Else
			response = New HTTPServiceResponse(403);
		EndIf;
	Else
		response = New HTTPServiceResponse(200);
	EndIf;
	response.Headers.Insert("Content-type", "application/json;  charset=utf-8");
	response.SetBodyFromString(parameters.answerBody, TextEncoding.UTF8, ByteOrderMarkUsage.Use);
	Return response;		
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
	Return ?(TypeOf(value) = Undefined, Undefined, Lower(value));
EndFunction

