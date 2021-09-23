
Function sendSMS(parameters, answer) Export
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	URL	= "SmsService.svc/SendSms?login=" + parameters.user + "&password=" + parameters.password + "&phone=" + parameters.phone + "&body=" + parameters.text + "&senderName=" + parameters.senderName;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	XMLReader = New XMLReader();
	XMLReader.SetString(answerBody);
	currentPath = "";
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Name = "string" Then
				currentPath = "string";
			EndIf;
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			If currentPath = "string" Then
				sms_id = XMLReader.Value;
				currentPath = "";
			EndIf;
		EndIf;
	EndDo;
	If sms_id <> "" Then
		answer.Insert("id", sms_id);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);
	Else
		answer.Insert("error", "Сбой при отрправке Messages");
	EndIf;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs("", URL, answerBody);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	Return answer;
EndFunction

Function checkSmsStatus(parameters, answer) Export	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	URL	= "SmsService.svc/GetMessageState?login=" + parameters.user + "&password=" + parameters.password + "&messageid=" + parameters.id;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	XMLReader = New XMLReader();
	XMLReader.SetString(answerBody);
	currentPath = "";	
	While XMLReader.Read() Do
		If XMLReader.NodeType = XMLNodeType.StartElement Then
			If XMLReader.Name = "Comment" Then
				currentPath = "Comment";
			EndIf;
		ElsIf XMLReader.NodeType = XMLNodeType.Text Then
			If currentPath = "Comment" Then
				answerstatus = XMLReader.Value;
				currentPath = "";
			EndIf;
		EndIf;
	EndDo;
	status	= messageStatus(answerstatus);
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
	If status = "В очереди" Or status = "sent" Or status = "Подготовлено" Or status = "Создано" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "Отклонено" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "delivered" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "Не delivered" Or status = "Просрочено" Then
		Return Enums.messageStatuses.notDelivered;
	Else
		Return status;
	EndIf;	
EndFunction

