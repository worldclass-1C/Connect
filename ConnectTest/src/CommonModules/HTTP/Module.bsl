
Function processRequest(request, requestName = "", synch = False) Export

	parameters = New Structure();
	parameters.Insert("internalRequestMethod", False);
	General.executeRequestMethodStart(parameters);
	parameters.Insert("url", request.BaseURL + request.RelativeURL);		
	parameters.Insert("headersJSON", HTTP.encodeJSON(request.Headers));
	parameters.Insert("requestName", ?(requestName = "", HTTP.getRequestHeader(request, "request"), requestName));	
	parameters.Insert("languageCode", HTTP.getRequestHeader(request, "language"));
	parameters.Insert("language", GeneralReuse.getLanguage(parameters.languageCode));
	parameters.Insert("brand", Service.getRef(HTTP.getRequestHeader(request, "brand"),Type("EnumRef.brandTypes"), GetBrandArray()));
	parameters.Insert("ipAddress", HTTP.getRequestHeader(request, "ClientIP"));
	parameters.Insert("authKey", HTTP.getRequestHeader(request, "auth-key"));
	parameters.Insert("origin", HTTP.getRequestHeader(request, "origin"));	
	parameters.Insert("answerBody", "");
	parameters.Insert("statusCode", 200);		
	parameters.Insert("error", "");
			
	If Not ValueIsFilled(parameters.language) Then
		parameters.Insert("languageCode", "en");
		parameters.Insert("language", GeneralReuse.getLanguage(parameters.languageCode));
	EndIf;	

	If Not ValueIsFilled(parameters.requestName) Then
		parameters.Insert("error", "requestError");	
	ElsIf Not ValueIsFilled(parameters.brand) Then
		parameters.Insert("error", "brandError");
	EndIf;
	If parameters.error = "" Then		
		Check.legality(request, parameters);
	EndIf;			
	If requestName = "imagePOST" or requestName = "filePOST" Then
		parameters.Insert("requestBody", request.GetBodyAsBinaryData());
		parameters.Insert("headers", request.Headers);				
	Else
		parameters.Insert("requestBody", request.GetBodyAsString());
		parameters.Insert("requestStruct", HTTP.decodeJSON(parameters.requestBody, Enums.JSONValueTypes.structure,,synch));
	EndIf;
	If parameters.error = "" Then	
		Try
			General.executeRequestMethod(parameters);
		Except
			parameters.Insert("error", "system");
			parameters.Insert("answerBody", ErrorDescription());
		EndTry;
	EndIf;	

	General.executeRequestMethodEnd(parameters, synch);
//	parameters.Insert("duration", CurrentUniversalDateInMilliseconds()
//		- parameters.dateInMilliseconds);	
//	parameters.Insert("isError", parameters.error <> "");	
//	If parameters.isError Then		
//		If parameters.error = "noValidRequest"
//				or parameters.error = "tokenExpired" Then
//			parameters.Insert("statusCode", 401);			
//		Else
//			parameters.Insert("statusCode", 403);			
//		EndIf;
//		If parameters.error <> "system" Then
//			parameters.Insert("answerBody", HTTP.encodeJSON(Service.getErrorDescription(parameters.language, parameters.error)));
//		EndIf
//	EndIf;
//	
//	If Not synch Then
//		Service.logRequestBackground(parameters);
//	EndIf;

	Return HTTP.prepareResponse(parameters);

EndFunction

Function GetBrandArray()
	brandsStr = "worldclass fizkult ufc none";
	Return StrSplit(brandsStr, " ");
EndFunction

Function decodeJSON(val body, val JSONValueType = "", ReadToMap = False, isXDTOSerializer = False) Export	
	body = TrimAll(body);
	If JSONValueType = "" Then
		JSONValueType = Enums.JSONValueTypes.string;
	EndIf;
	If StrLen(Body) > 0 Then			
		JSONReader = New JSONReader();
		JSONReader.SetString(body);
		If isXDTOSerializer Then
			RequestStruct = XDTOSerializer.ReadJSON(JSONReader)	
		Else		
       		RequestStruct = ReadJSON(JSONReader, ReadToMap);
		EndIf;
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

Function encodeJSON(data, isXDTOSerializer = False) Export
	JSONWriter = New JSONWriter();
	JSONWriter.SetString();
	if isXDTOSerializer then
		XDTOSerializer.WriteJSON(JSONWriter, data, XMLTypeAssignment.Explicit);
	else
		WriteJSON(JSONWriter, data);
	EndIf;
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
	
	struct.Insert("appVersion", tokenContext.appVersion);
	struct.Insert("systemType", TrimAll(tokenContext.systemType));
	struct.Insert("brand", TrimAll(parameters.brand));
	
	Return HTTP.encodeJSON(struct, ?(parameters.Property("isXDTOSerializer"),parameters.isXDTOSerializer,false));

EndFunction

Function prepareResponse(parameters) Export
	response = New HTTPServiceResponse(parameters.statusCode);
	If parameters.error = "system" Then	
		Texts = String(parameters.requestName)+chars.LF+parameters.requestBody+chars.LF+parameters.statusCode+chars.LF+parameters.answerBody;	
		parameters.Insert("answerBody", HTTP.encodeJSON(Service.getErrorDescription(parameters.language, parameters.error,,Texts)));		
	EndIf;
	response.Headers.Insert("Content-type", "application/json;  charset=utf-8");
	response.Headers.Insert("Access-Control-Allow-Headers", "content-type, server, date, content-length, Access-Control-Allow-Headers, authorization, X-Requested-With, auth-key,brand,content-type,kpo-code,language,request");
//	response.Headers.Insert("Access-Control-Allow-Headers", "*");
	If HTTP.inTheWhiteList(parameters.origin) Then		
		//	response.Headers.Insert("Access-Control-Allow-Credentials", "true");
		response.Headers.Insert("Access-Control-Allow-Methods", "POST,GET,OPTIONS");
		response.Headers.Insert("Access-Control-Allow-Origin", parameters.origin);
	EndIf;
	If parameters.answerBody <> "" Then
		response.SetBodyFromString(parameters.answerBody, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());
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
	value	= request.Headers.Get(key);
	If value = Undefined Then
		value	= request.Headers.Get(Title(key));
	EndIf;
	If value = Undefined Then
		value	= request.Headers.Get(Lower(key));
	EndIf;
	If value = Undefined Then
		value	= request.Headers.Get(Upper(key));
	EndIf;	 
	Return ?(TypeOf(value) = Undefined, Undefined, Lower(value));
EndFunction

Function inTheWhiteList(origin) Export
	If False 
		Or origin = "https://stoplight.io" 
		Or origin = "https://tilda.cc"
		Or origin = "https://ufcgymrussia.ru"
		Or origin = "https://www.ufcgymrussia.ru"
		Or origin = "https://worldclass.ru"
		Or origin = "https://online.worldclass.ru"
		Or origin = "https://online.fizkult-nn.ru"
		Or origin = "https://project1205002.tilda.ws"
		Or origin = "https://localhost:55555"
		Or origin = "http://localhost:55555"
		Or origin = "https://localhost"
		Or origin = "https://solutions.worldclass.ru" 
		Or origin = "https://spa.worldclass.ru"
		Or origin = "https://spb.ufcgymrussia.ru"
		Or origin = "https://corp.worldclass.ru"
		Or origin = "https://promo.worldclass.ru"
	Then
		Return True;
	Else
		Return False;
	EndIf;	
EndFunction