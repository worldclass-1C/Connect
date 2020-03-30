Function sendSMS(parameters, answer) Export
	
	JSONValue = New Structure;
	JSONValue.Insert("from"	, XMLString(parameters.senderName));
	JSONValue.Insert("to"		, Number(parameters.phone));
	JSONValue.Insert("message"	, XMLString(parameters.text));
	
	callback_url = Messages.GetMessageCallbackURL(Enums.SmsProviders.Megalab);
	If  callback_url <> "" Then
		JSONValue.Insert("callback_url"	, XMLString(callback_url));
	EndIf;
	
	JSONWriter	= New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, JSONValue);
	
	JSONString = JSONWriter.Закрыть();
	
	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);
	
	Headers = New Map;
	Headers.insert("Authorization", "Basic " + Crypto.EncryptBase64(parameters.user+":"+parameters.password, "US-ASCII"));
	Headers.insert("Content-Type", "application/json");
	
	requestHTTP = New HTTPRequest("/sms/v1/sms", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, ByteOrderMarkUsage.DontUse);
	
	answerBody = ConnectionHTTP.Post(requestHTTP);
	JSONStructure = "";
	
	If answerBody.КодСостояния = 200 Then 
		JSONReader	= Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure	= ReadJSON(JSONReader);
		JSONReader.Закрыть();
		
		If JSONStructure.result.status.code = 0 Then 
			answer.Insert("id", JSONStructure.result.msg_id);
			answer.Insert("messageStatus", Enums.messageStatuses.sent);
		Else
			answer.Insert("error", JSONStructure.result.status.description);
		EndIf;
	Else
		answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
	Endif;
	
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs = Messages.GetAnswerResponseBodyForLogs(Headers, JSONString, JSONStructure);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	
	Return answer;
	
EndFunction

Function checkSmsStatus (Request) Export

	RequestParameters = HTTP.decodeJSON(request.GetBodyAsString(), Enums.JSONValueTypes.structure, , False);

	If RequestParameters.Property("msg_id") Then
		
		messageParameters = Messages.FindMessageById(RequestParameters.msg_id);
		
		If messageParameters.messageRef <> Catalogs.messages.EmptyRef() Then
			
			parameters = New Structure("message, nodeMessagesToCheckStatus, messageAge", messageParameters.messageRef, GeneralReuse.nodeMessagesToCheckStatus(Enums.informationChannels.sms), messageParameters.messageAge);
			answer = New Structure("messageStatus, error, period", Enums.messageStatuses.notDelivered, "", Undefined);
			
			If RequestParameters.status = "delivered" Then
				answer.messageStatus = Enums.messageStatuses.delivered;
			Else
				answer.messageStatus = Enums.messageStatuses.notDelivered;
			EndIf;
			
			answer.period = ToUniversalTime(CurrentDate());
			
			Messages.checkSmsStatusContinuation(answer, parameters) ; 
			
			Return New HTTPServiceResponse (200);
		Else
			Return New HTTPServiceResponse(500);
		Endif
	Else
		Return New HTTPServiceResponse(500);
	Endif
EndFunction