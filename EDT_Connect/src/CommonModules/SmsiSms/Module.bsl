Function sendSMS(parameters, answer) Export
		
	ConnectionHTTP = New HTTPConnection(parameters.server,,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	URL	= "/api/sms/send";
	body = new structure;
	body.Insert("from", 				parameters.senderName);
	body.Insert("to", 					parameters.phone);
	body.Insert("text", 				parameters.text);
	//+ "?username="   + parameters.user 
	//+ "&password=" 	 + parameters.password 
	//+ "&recipient="  + parameters.phone
	//+ "&messagetype=SMS:TEXT" 
	//+ "&originator=" + parameters.senderName 
	//+ "&messagedata" + parameters.text;
	
	requestHTTP 	= New HTTPRequest(URL);
	requestHTTP.Headers.insert("authorization", "Basic " + Crypto.EncryptBase64(parameters.user + ":"
	+ parameters.password, "US-ASCII"));
	requestHTTP.Headers.insert("cache-control", "no-cache");
	requestHTTP.Headers.insert("content-type", "application/json");
	requestHTTP.SetBodyFromString(http.encodeJSON(body), TextEncoding.UTF8);
	answerBody 		= ConnectionHTTP.Post(requestHTTP);
	
	//requestHTTP 	= New HTTPRequest(URL);
	//answerBody 		= ConnectionHTTP.Get(requestHTTP);
	
	error = "";
	JSONStructure = "";
		
	If answerBody.StatusCode = 200 Then
		
		JSONReader = New JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Close();
		
		If JSONStructure.Property("id") and JSONStructure.Property("status") Then
			answer.Insert("messageStatus", Enums.messageStatuses.sent);
			answer.Insert("id", String(JSONStructure.id));
		ElsIf JSONStructure.Property("error_message") and JSONStructure.Property("error_code") Then
			error = String(JSONStructure.error_code) + ": " + JSONStructure.error_message;
		Endif;
	Else
		error = "Сбой при отрправке Messages 500 Internal Error";
	Endif;
	
	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs("", URL, JSONStructure);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	
	Return answer;

	
EndFunction

Function checkSmsStatus(parameters, answer) Export
	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	URL	= "/api/sms/report";
	body = new structure;
	body.Insert("id", 				parameters.id);
	requestHTTP 	= New HTTPRequest(URL);
	requestHTTP.Headers.insert("authorization", "Basic " + Crypto.EncryptBase64(parameters.user + ":"
	+ parameters.password, "US-ASCII"));
	requestHTTP.SetBodyFromString(http.encodeJSON(body), TextEncoding.UTF8);
	answerBody 		= ConnectionHTTP.Post(requestHTTP);
	
	error = "";
		
	If answerBody.StatusCode = 200 Then
		
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();
		
		If JSONStructure.Property("status") Then
			status	= messageStatus(Upper(JSONStructure.status));
			If TypeOf(status) = Type("EnumRef.messageStatuses") Then
				answer.Insert("messageStatus", status);
			Else
				answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
				error = "Неизвестный status";
			EndIf;
		ElsIf JSONStructure.Property("error_message") and JSONStructure.Property("error_code") Then
			error = String(JSONStructure.error_code) + ": " + JSONStructure.error_message;
		Endif;
	Else
		error = "Сбой при запросе статуса сообщения";
	Endif;
	
	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
		
	Return answer;
	
EndFunction

Function messageStatus(status)

	If status = "sent" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "sending" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "delivered" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "undelivered" Then
		Return Enums.messageStatuses.notDelivered;
	Else
		Return status;
	EndIf;

EndFunction