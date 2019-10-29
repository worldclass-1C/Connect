
Function sendSMS(parameters, answer) Export
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	URL = "" + parameters.user + "?serviceId=" + parameters.user + "&pass="
		+ parameters.password + "&clientId=" + parameters.phone + "&message="
		+ parameters.text + "&source=" + parameters.senderName;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	answerArray = StrSplit(answerBody, Chars.LF);
	try			
		If answerArray.Count() > 0 And answerArray[0] = "OK" Then
			answer.Insert("id", answerArray[2]);
			answer.Insert("messageStatus", Enums.messageStatuses.sent);
		Else
			answer.Insert("error", answerBody);								
		EndIf;
	Except
		answer.Insert("error", answerBody);
	EndTry;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	Return answer;
EndFunction

Function _sendSMS(parameters, answer) Export
	ConnectionHTTP = New HTTPConnection(parameters.server,,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	URL = "world_class?msisdn=" + parameters.phone + "&message="
		+ parameters.text;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	try
	//@skip-warning
		test = Number(answerBody);
		answer.Insert("id", answerBody);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);
	Except
		answer.Insert("error", answerBody);
	EndTry;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	Return answer;
EndFunction

Function checkSmsStatus(parameters, answer) Export

	ConnectionHTTP = New HTTPConnection(parameters.server,, , , , parameters.timeout, ?(True, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	URL = "dlr?id=" + parameters.id + "&serviceId=" + parameters.user + "&pass="
		+ parameters.password;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	status = "";
	If answerHTTP.StatusCode = 200 Then
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
					status = getMessageStatus(XMLReader.Value);
					currentPath = "";
				EndIf;
			EndIf;
		EndDo;		
		If TypeOf(status) = Type("EnumRef.messageStatuses") Then
			answer.Insert("messageStatus", status);
		Else
			answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
			answer.Insert("error", answerBody);
		EndIf;		
	Else
		answer.Insert("messageStatus", Enums.messageStatuses.undefined);		
	EndIf;

	Return answer;

EndFunction

Function getMessageStatus(status)
	Если status = "-1" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "0" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "2" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "5" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "9" Then
		Return Enums.messageStatuses.read;		
	Else
		Return status;
	EndIf;
EndFunction