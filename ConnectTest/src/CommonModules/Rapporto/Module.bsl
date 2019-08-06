
Function sendSMS(parameters, answer) Export
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.account, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
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
	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.account, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	
	URL	= "world_class/delivery_report?mt_num=" + parameters.id + "&show_date=Y";
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());
	
	rowsArray	= StrSplit(answerBody, " ");	
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	
	If rowsArray.Count() > 0 Then
		status	= getMessageStatus(rowsArray[0]);
		If TypeOf(status) = Type("EnumRef.messageStatuses") Then
			answer.Insert("messageStatus", status);
		Else
			answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
			answer.Insert("error",answerBody);
		EndIf;	
	Else
		answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);		
		answer.Insert("error",answerBody);
	EndIf;	
	
	Return answer;	
	
EndFunction

Function getMessageStatus(status)
	Если status = "-1" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "0" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "1" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "2" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "3" Then
		Return Enums.messageStatuses.delivered;
	Else
		Return status;
	EndIf;
EndFunction