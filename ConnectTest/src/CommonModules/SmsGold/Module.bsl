
Function sendSMS(parameters, answer) Export	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	URL = "http2" + "?user=" + parameters.user + "&pass=" + parameters.password
		+ "&number=" + parameters.phone + "&sender=" + parameters.senderName
		+ "&text=" + parameters.text;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	Try
		answer.Insert("id", answerBody);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);
	Except
		answer.Insert("error", answerBody);
	EndTry;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs("", URL, answerBody);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	Return answer;
EndFunction

Function checkSmsStatus(parameters, answer) Export	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	URL = "http2" + "?user=" + parameters.user + "&pass=" + parameters.password
		+ "&smsid=" + parameters.id;
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	status = getMessageStatus(answerBody);
	If TypeOf(status) = Type("EnumRef.messageStatuses") Then
		answer.Insert("messageStatus", status);
	Else
		answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
		answer.Insert("error", "Неизвестный статус");
	EndIf;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	Return answer;	
EndFunction

Function getMessageStatus(status)
	If status = "ENROUTE" Or status = "ACCEPTD" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "DELETED" Or status = "REJECTD" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "DELIVRD" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "EXPIRED" Or status = "UNDELIV" Or status = "UNKNOWN" Then
		Return Enums.messageStatuses.notDelivered;
	Else
		Return status;
	EndIf;
EndFunction