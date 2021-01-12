Function sendSMS(parameters, answer) Export
	
	MessageArray = New Array;
	JSONMessage = New Structure;
	
	JSONMessage.Insert("channel"	,XMLString("char"));
	JSONMessage.Insert("sender"		,XMLString(parameters.senderName));
	JSONMessage.Insert("text"		,XMLString(parameters.text));
	JSONMessage.Insert("phone"		,XMLString(parameters.phone));
	MessageArray.Add(JSONMessage);
	
	JSONValue = New Structure;
	JSONValue.Insert("apiKey"	,XMLString(parameters.password));
	JSONValue.Insert("sms"		,MessageArray);
	
	JSONWriter	= New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, JSONValue);
	
	JSONString = JSONWriter.Закрыть();
	
	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);
	
	Headers = New Map;
	Headers.insert("Content-Type", "application/json; charset=utf-8");
	
	requestHTTP = New HTTPRequest("/apiSms/create", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());
	
	answerBody = ConnectionHTTP.Post(requestHTTP);
	error = "";
	
	If answerBody.StatusCode = 200 Or answerBody.StatusCode = 400 Then
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();
	Else
		JSONStructure = "";
	EndIf;
	
	If answerBody.StatusCode = 200 Then
		
		If  JSONStructure.status = "success" Then
			AnswerStructure = JSONStructure.data[0];
			If AnswerStructure.status  = "error" Then
				answer.Insert("error", AnswerStructure.errorDescription);
			ElsIf AnswerStructure.Свойство("id") Then
				answer.Insert("id", String(Format(AnswerStructure.id, "NG=")));
				answer.Insert("messageStatus", Enums.messageStatuses.sent);
			EndIf
		Else
			error = "Сбой при отрправке: неизвестный статус";
		EndIf
		
	ElsIf answerBody.StatusCode = 400 Then
		
		If  JSONStructure.status = "error" Then
			AnswerStructure = JSONStructure.data;
			error = AnswerStructure.message;
		Else
			error = "Сбой при отправке: неизвестный статус";
		EndIf
	Else
		error = "Сбой при отправке сообщения. Ошибка: " + answerBody.StatusCode;
	Endif;
	
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs(Headers, JSONString, JSONStructure);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	answer.Insert("error", error);
		
	Return answer;
	
EndFunction

Function checkSmsStatus(parameters, answer) Export
	
	idArray = New Array;
	idArray.Add(parameters.id);
	
	JSONValue = New Structure;
	JSONValue.Insert("apiKey"		,XMLString(parameters.password));
	JSONValue.Insert("apiSmsIdList"	,idArray);
	
	JSONWriter	= New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, JSONValue);
	
	JSONString = JSONWriter.Закрыть();
	
	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);
	
	Headers = New Map;
	Headers.insert("Content-Type", "application/json; charset=utf-8");
	
	requestHTTP = New HTTPRequest("/apiSms/get", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());
	
	answerBody = ConnectionHTTP.Post(requestHTTP);
	error = "";
	
	If answerBody.StatusCode = 200 Or answerBody.StatusCode = 400 Then
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();
	EndIf;
	
	If answerBody.StatusCode = 200 Then
		
		If  JSONStructure.status = "success" Then
			AnswerStructure = JSONStructure.data[0];
			If AnswerStructure.status  = "error" Then
				error = AnswerStructure.errorDescription;
			Else
				status	= messageStatus(Upper(AnswerStructure.status));
				If TypeOf(status) = Type("EnumRef.messageStatuses") Then
					answer.Insert("messageStatus", status);
				Else
					answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
					error = "Неизвестный status";
				EndIf;
			EndIf
		Else
			error = "Сбой при отрправке: неизвестный статус";
		EndIf
		
	ElsIf answerBody.StatusCode = 400 Then
		
		If  JSONStructure.status = "error" Then
			AnswerStructure = JSONStructure.data;
			error = AnswerStructure.message;
		Else
			error = "Сбой при отправке: неизвестный статус";
		EndIf
	Else
		error = "Сбой при отправке сообщения. Ошибка: " + answerBody.StatusCode;
	Endif;
	
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	answer.Insert("error", error);
	
	Return answer;
	
EndFunction

Function messageStatus(status)
	
	If status = "CREATED" Or status = "MODERATION" Or status = "SENT" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "LOW_BALANCE" Or status = "LOW_PARTNER_BALANCE" Or status = "REJECTED" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "DELIVERED" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "NOT_DELIVERED" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "READ" Then
		Return Enums.messageStatuses.read;
	Else
		Return status;
	EndIf;
	
EndFunction
