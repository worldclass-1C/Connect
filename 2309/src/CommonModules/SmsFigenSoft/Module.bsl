#Region SendSMS
Function sendSMS(parameters, answer) Export
		
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	URL	= "/api_http/sendsms.asp"
	+ "?user="		+ parameters.user 
	+ "&password="	+ parameters.password 
	+ "&gsm="		+ parameters.phone 
	+ "&text="		+ parameters.text;
	
	requestHTTP 	= New HTTPRequest(URL);
	answerBody 		= ConnectionHTTP.Get(requestHTTP);
	
	error = "";
	responseParameters = "";
	
	If answerBody.КодСостояния = 200 Then
		
		responseParameters = GetresponseParameters(answerBody);
		If responseParameters.Property("errno") and responseParameters.Property("errtext")
			and responseParameters.Property("message_id") Then
			If responseParameters.errno = "0" Then
				answer.Insert("messageStatus", Enums.messageStatuses.sent);
				answer.Insert("id", responseParameters.message_id);
			Else
				error = DecryptionErrorCode(responseParameters.errno) + ": " + responseParameters.errtext;
			Endif;
		Else
			error = "Неизвестная ошибка при отправке сообщения";
		Endif;
	Else
		error = "Сбой при отрправке Messages 500 Internal Error";
	Endif;
	
	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs("", URL, responseParameters);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	
	Return answer;
	
EndFunction

Function DecryptionErrorCode(ErrorCode)

	ErrorDescription = "";

	If ErrorCode = -1001 Then
		ErrorDescription = "Invalid username";
	ElsIf ErrorCode = -1002 Then
		ErrorDescription = "Invalid password";
	ElsIf ErrorCode = -1003 Then
		ErrorDescription = "Invalid GSM no.";
	ElsIf ErrorCode = -2001 Then
		ErrorDescription = "API internal error";
	ElsIf ErrorCode = -2002 Then
		ErrorDescription = "Database internal error";
	ElsIf ErrorCode = 10 Then
		ErrorDescription = "Invalid username or password";
	ElsIf ErrorCode = 20 Then
		ErrorDescription = "Insufficient quota";
	Endif; 
	Return ErrorDescription;
EndFunction
#EndRegion

#Region checkSmsStatus
Function checkSmsStatus(parameters, answer) Export
	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	URL	= "/api_http/querysms.asp"
	+ "?user="			+ parameters.user 
	+ "&password="		+ parameters.password 
	+ "&message_id="	+ parameters.id ;
	
	requestHTTP 	= New HTTPRequest(URL);
	answerBody 		= ConnectionHTTP.Get(requestHTTP);
	
	error = "";
		
	If answerBody.КодСостояния = 200 Then

		responseParameters = GetresponseParameters(answerBody);

		If responseParameters.Property("errno") and responseParameters.Property("errtext")
				and responseParameters.Property("status") Then
			If responseParameters.errno = "0" Then
				status = messageStatus(responseParameters.status);
				If TypeOf(status) = Type("EnumRef.messageStatuses") Then
					answer.Insert("messageStatus", status);
				Else
					answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
					error = "Неизвестный status";
				EndIf;
			Else
				error = DecryptionErrorCode(responseParameters.errno) + ": " + String(responseParameters.errtext);
			Endif;
		Endif;
	Else
		error = "Сбой при запросе статуса сообщения";
	Endif;
	
	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
		
	Return answer;
	
EndFunction

Function messageStatus(status)

	If status = "110" Or status = "120" Or status = "200" Or status = "300" Or status = "401" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "-201" Or status = "-202" Or status = "-207" Or status = "-222" Or status = "-250" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "400" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "402" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "410" Or status = "420" Or status = "-20" Then
		Return Enums.messageStatuses.undefined;
	Else
		Return status;
	EndIf;

EndFunction
#EndRegion

Function GetresponseParameters(answerBody)
	body = answerBody.GetBodyAsString();
	responseParameters = new Structure();
	If ValueIsFilled(body) then
		arrayParams = StrSplit(body, "&");
		For Each element In arrayParams Do
			param = StrSplit(element, "=");
			responseParameters.Insert(param[0],param[1]);
		EndDo;
	Endif;
	Return responseParameters;
EndFunction
