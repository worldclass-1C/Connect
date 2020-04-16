
Function sendSMS(parameters, answer) Export
		
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	
	URL	= "smartdelivery-in/multi.php/?login=" + parameters.user + "&password=" + parameters.password + "&phones=" + parameters.phone + "&message=" + parameters.text + "&originator=" + parameters.senderName + "&rus=1" + "&want_sms_ids=1";
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	
	XMLReader = Новый XMLReader();
	XMLReader.SetString(answerBody);
	currentPath = "";
	code = "";
	result = "";
	description = "";
	
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Name = "code" Then
				currentPath = "code";
			ElsIf XMLReader.Name = "description" Then
				currentPath = "description";
			ElsIf XMLReader.Name = "result" Then
				currentPath = "result";
			ElsIf XMLReader.Name = "sms_id" Then
				currentPath = "sms_id";
			EndIf;
		EndIf;
		
		If XMLReader.NodeType = XMLNodeType.Text Then
			If currentPath = "code" Then
				code = XMLReader.Value;
			ElsIf currentPath = "description" Then
				description = XMLReader.Value;
			ElsIf currentPath = "result" Then
				result = XMLReader.Value;
			ElsIf currentPath = "sms_id" Then
				sms_id = XMLReader.Value;
			EndIf;
		EndIf;
	EndDo;
	
	If code = "0" And result = "OK" Then
		answer.Insert("id", sms_id);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);		
	Else
		answer.Insert("error", description);		
	EndIf;
	
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs("", URL, answerBody);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	
	Return answer;	
	
EndFunction

Function checkSmsStatus(parameters, answer) Export
	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	
	URL	= "smartdelivery-in/multi.php/?login=" + parameters.user + "&password=" + parameters.password + "&operation=status&sd=false" + "&sms_id=" + parameters.id;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	
	XMLReader = New XMLReader;
	XMLReader.SetString(answerBody);
	currentPath = "";
	
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Name = "status" Then
				currentPath = "status";
			EndIf;
		EndIf;
		
		If XMLReader.NodeType = XMLNodeType.Text Then
			If currentPath = "status" Then
				statusAnswer = XMLReader.Value;
				currentPath = "";
			EndIf;
		EndIf;
	EndDo;
	
	status	= messageStatus(Upper(statusAnswer));
	If TypeOf(status) = Type("EnumRef.messageStatuses") Then
		answer.Insert("messageStatus", status);
	Else
		answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
		answer.Insert("error","Неизвестный status");
	EndIf;
	
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	
	Return answer;
	
EndFunction

Function messageStatus(status)
	
	If status = "SENT" Or status = "NOT_ROUTED" Or status = "ACCEPTD" Or status = "UNDELIVERED" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "DOUBLED" Or status = "error" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "DELIVERED" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "TIMEOUT" Or status = "EXPIRED" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "READ" Then
		Return Enums.messageStatuses.read;
	Else
		Return status;
	EndIf;
	
EndFunction
