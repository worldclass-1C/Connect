Function sendSMS(parameters, answer) Export
		
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	URL	= "/sys/send.php"
	+ "?login="  + parameters.user 
	+ "&psw=" 	 + parameters.password 
	+ "&phones=" + parameters.phone 
	+ "&mes="	 + parameters.text 
	+ "&sender=" + parameters.senderName 
	+ "&cost=0" 
	+ "&fmt=3";
	requestHTTP 	= New HTTPRequest(URL);
	answerBody 		= ConnectionHTTP.Get(requestHTTP);
	
	error = "";
	JSONStructure = "";
	
	If answerBody.КодСостояния = 200 Then
		
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();
		
		If JSONStructure.Property("id") and JSONStructure.Property("cnt") Then
			answer.Insert("messageStatus", Enums.messageStatuses.sent);
			answer.Insert("id", String(JSONStructure.id));
		ElsIf JSONStructure.Property("error") and JSONStructure.Property("error_code") Then
			error = String(JSONStructure.error_code) + ": " + JSONStructure.error;
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
	
	URL	= "/sys/status.php"
	+ "?login=" + parameters.user 
	+ "&psw=" 	+ parameters.password 
	+ "&phone=" + parameters.phone 
	+ "&id=" 	+ parameters.id 
	+ "&all=0" 
	+ "&fmt=3";
	requestHTTP 	= New HTTPRequest(URL);
	answerBody 		= ConnectionHTTP.Get(requestHTTP);
	
	error = "";
		
	If answerBody.КодСостояния = 200 Then
		
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
		ElsIf JSONStructure.Property("error") and JSONStructure.Property("error_code") Then
			error = String(JSONStructure.error_code) + ": " + JSONStructure.error;
		Endif;
	Else
		error = "Сбой при запросе статуса сообщения";
	Endif;
	
	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
		
	Return answer;
	
EndFunction

Function messageStatus(status)

	If status = "-2" Or status = "-1" Or status = "0" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "22" Or status = "23" Or status = "24" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "1" Or status = "4" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "3" Or status = "20" Or status = "25" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "2" Then
		Return Enums.messageStatuses.read;
	Else
		Return status;
	EndIf;

EndFunction