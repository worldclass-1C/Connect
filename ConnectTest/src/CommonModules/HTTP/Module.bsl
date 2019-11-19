
Function processRequest(request, requestName = "") Export

	dateInMilliseconds = CurrentUniversalDateInMilliseconds();

	parameters = New Structure();
	parameters.Insert("url", request.BaseURL + request.RelativeURL);
	parameters.Insert("headersJSON", HTTP.encodeJSON(request.Headers));
	parameters.Insert("requestName", ?(requestName = "", HTTP.getRequestHeader(request, "request"), requestName));	
	parameters.Insert("languageCode", HTTP.getRequestHeader(request, "language"));
	parameters.Insert("language", GeneralReuse.getLanguage(parameters.languageCode));
	parameters.Insert("brand", HTTP.getRequestHeader(request, "brand"));
	parameters.Insert("authKey", HTTP.getRequestHeader(request, "auth-key"));	
	parameters.Insert("notSaveAnswer", False);
	parameters.Insert("compressAnswer", False);
	parameters.Insert("underControl", False);
	parameters.Insert("answerBody", "");	
	
	If Not ValueIsFilled(parameters.language) Then
		parameters.Insert("languageCode", "en");
		parameters.Insert("language", GeneralReuse.getLanguage(parameters.languageCode));
	EndIf;
	parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language));

	If Not ValueIsFilled(parameters.requestName) Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "requestError"));	
	ElsIf Not ValueIsFilled(parameters.brand) Then
		parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "brandError"));
	EndIf;
	If parameters.errorDescription.result = "" Then		
		Check.legality(request, parameters);
	EndIf;			
	If requestName = "imagePOST" Then
		parameters.Insert("requestBody", request.GetBodyAsBinaryData());
		parameters.Insert("headers", request.Headers);
	Else
		parameters.Insert("requestBody", request.GetBodyAsString());
		parameters.Insert("requestStruct", HTTP.decodeJSON(parameters.requestBody, Enums.JSONValueTypes.structure));
	EndIf;
	If parameters.errorDescription.result = "" Then	
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

Function decodeJSON(val body, val JSONValueType = "") Export	
	body = TrimAll(body);
	If JSONValueType = "" Then
		JSONValueType = Enums.JSONValueTypes.string;
	EndIf;
	If StrLen(Body) > 0 Then			
		JSONReader = New JSONReader();
		JSONReader.SetString(body);
		RequestStruct   = ReadJSON(JSONReader);
		JSONReader.Close();
		Return RequestStruct;
	Else
		If JSONValueType = Enums.JSONValueTypes.structure Then
			Return New Structure();	
		ElsIf JSONValueType = Enums.JSONValueTypes.array Then
			Return New Array();
		ElsIf JSONValueType = Enums.JSONValueTypes.string Then
			Return "";
		ElsIf JSONValueType = Enums.JSONValueTypes.number Then
			Return 0;
		ElsIf JSONValueType = Enums.JSONValueTypes.date Then
			Return Date(1,1,1);
		ElsIf JSONValueType = Enums.JSONValueTypes.boolean Then
			Return False;					
		Else
			Return body;
		EndIf;
	EndIf;	
EndFunction

Function encodeJSON(data) Export
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	WriteJSON(JSONWriter, data);
	Return JSONWriter.Close();
EndFunction

Function prepareRequestBody(parameters) Export
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	
	If TypeOf(requestStruct) = Type("Structure") Then
		struct = requestStruct;
	Else
		struct = New Structure;
		struct.Insert("array", requestStruct);
	EndIf;

	struct.Insert("token", parameters.authKey);
	struct.Insert("language", parameters.languageCode);
	struct.Insert("userId", XMLString(tokenContext.user));
	struct.Insert("currentTime", ToLocalTime(ToUniversalTime(CurrentDate()), tokenContext.timezone));
	If tokenContext.appType = Enums.appTypes.Customer Then
		struct.Insert("appType", "Customer");
	ElsIf tokenContext.appType = Enums.appTypes.Employee Then
		struct.Insert("appType", "Employee");
	ElsIf tokenContext.appType = Enums.appTypes.Web Then
		struct.Insert("appType", "Web");
	Else
		struct.Insert("appType", TrimAll(tokenContext.appType));
	EndIf;

	Return HTTP.encodeJSON(struct);

EndFunction

Function prepareResponse(parameters) Export
	If parameters.errorDescription.result <> "" Then
		parameters.Insert("answerBody", HTTP.encodeJSON(parameters.errorDescription));
		If parameters.errorDescription.result = "noValidRequest"
				or parameters.errorDescription.result = "tokenExpired" Then
			response = New HTTPServiceResponse(401);
		Else
			response = New HTTPServiceResponse(403);
		EndIf;
	Else
		response = New HTTPServiceResponse(200);
	EndIf;
	response.Headers.Insert("Content-type", "application/json;  charset=utf-8");
	If parameters.answerBody <> "" Then
		response.SetBodyFromString(parameters.answerBody, TextEncoding.UTF8, ByteOrderMarkUsage.Use);
	EndIf;
	Return response;
EndFunction

Function getRequestStructure(request, holding) Export

	requestStruct = New Structure;
	
	query = New Query();
	query.Text = "SELECT
	|	holdingsConnectionsInformationSources.holding AS holding,
	|	holdingsConnectionsInformationSources.informationSource AS informationSource,
	|	holdingsConnectionsInformationSources.server AS server,
	|	holdingsConnectionsInformationSources.port AS port,
	|	holdingsConnectionsInformationSources.user AS user,
	|	holdingsConnectionsInformationSources.password AS password,
	|	holdingsConnectionsInformationSources.URL AS URL,
	|	holdingsConnectionsInformationSources.timeout AS timeout,
	|	holdingsConnectionsInformationSources.secureConnection AS secureConnection,
	|	holdingsConnectionsInformationSources.UseOSAuthentication AS UseOSAuthentication
	|INTO TT
	|FROM
	|	InformationRegister.holdingsConnectionsInformationSources AS holdingsConnectionsInformationSources
	|WHERE
	|	holdingsConnectionsInformationSources.holding = &holding
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.server AS server,
	|	TT.port AS port,
	|	TT.user AS user,
	|	TT.password AS password,
	|	TT.timeout AS timeout,
	|	TT.secureConnection AS secureConnection,
	|	TT.UseOSAuthentication AS UseOSAuthentication,
	|	TT.URL AS URL,
	|	informationSources.requestReceiver AS requestReceiver
	|FROM
	|	Catalog.matchingRequestsInformationSources.informationSources AS informationSources
	|		INNER JOIN TT AS TT
	|		ON informationSources.informationSource = TT.informationSource
	|WHERE
	|	informationSources.requestSource = &request";

	query.SetParameter("holding", holding);
	query.SetParameter("request", request);

	resultQuery = query.Execute();
	If Not resultQuery.IsEmpty() Then
		selection = resultQuery.Select();
		selection.Next();
		requestStruct.Insert("server", selection.server);
		requestStruct.Insert("port", selection.port);
		requestStruct.Insert("user", selection.user);
		requestStruct.Insert("password", selection.password);
		requestStruct.Insert("timeout", selection.timeout);
		requestStruct.Insert("secureConnection", selection.secureConnection);
		requestStruct.Insert("UseOSAuthentication", selection.UseOSAuthentication);
		requestStruct.Insert("URL", selection.URL);
		requestStruct.Insert("requestReceiver", selection.requestReceiver);
	EndIf;

	Return requestStruct;

EndFunction

Function getRequestHeader(request, key) Export
	value	= request.Headers.Get(Title(key));
	If value = Undefined Then
		value	= request.Headers.Get(Lower(key));
	EndIf;
	If value = Undefined Then
		value	= request.Headers.Get(Upper(key));
	EndIf;	 
	Return ?(TypeOf(value) = Undefined, Undefined, Lower(value));
EndFunction

