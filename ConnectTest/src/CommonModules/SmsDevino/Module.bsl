Function sendSMS(parameters, answer) Export

	answerGetSessionId = GetSessionId(parameters, new Structure("error, key", "", ""));

	If answerGetSessionId.error = "" Then

		SessionID = answerGetSessionId.key;

		JSONValue = New Structure;
		JSONValue.Insert("SessionID", XMLString(SessionID));
		JSONValue.Insert("DestinationAddress", XMLString(parameters.phone));
		JSONValue.Insert("Data", XMLString(parameters.text));
		JSONValue.Insert("SourceAddress", XMLString(parameters.senderName));

		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, JSONValue);

		JSONString = JSONWriter.Закрыть();

		ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
		ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

		Headers = New Map;
		Headers.insert("Content-Type", "application/json; charset=utf-8");

		requestHTTP = New HTTPRequest("/rest/Sms/Send", Headers);
		requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, ByteOrderMarkUsage.DontUse);

		answerBody = ConnectionHTTP.Post(requestHTTP);

		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();

		If answerBody.КодСостояния = 200 Then
			answer.Insert("id", String(JSONStructure[0]));
			answer.Insert("messageStatus", Enums.messageStatuses.sent);
		Else
			If JSONStructure.Свойство("Code") and JSONStructure.Свойство("Desc") Then
				error = String(JSONStructure.Desc);
			Else
				error = "Сбой при отрправке Messages 500 Internal Error";
			EndIf;
		Endif;
	Else
		error = answerGetSessionId.error;
	EndIf;

	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));

	Return answer;

EndFunction

&НаСервере
Function checkSmsStatus(parameters, answer) Export

	answerGetSessionId = GetSessionId(parameters, new Structure("error, key", "", ""));

	If answerGetSessionId.error = "" Then

		ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);

		URL = "rest/Sms/State?sessionId=" + answerGetSessionId.key + "&messageId="
			+ parameters.id;

		requestHTTP = New HTTPRequest(URL);
		answerBody = ConnectionHTTP.Get(requestHTTP);
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();

		If answerBody.КодСостояния = 200 Then
			status = messageStatus(Upper(JSONStructure.State));
			If TypeOf(status) = Type("EnumRef.messageStatuses") Then
				answer.Insert("messageStatus", status);
			Else
				answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
				answer.Insert("error", "Неизвестный status");
			EndIf;
		Else
			If JSONStructure.Свойство("Code") and JSONStructure.Свойство("Desc") Then
				error = String(JSONStructure.Desc);
			Else
				error = "Сбой при отрправке Messages 500 Internal Error";
			EndIf;
		Endif;
	Else
		error = answerGetSessionId.error;
	EndIf;

	answer.Insert("error", error);
	answer.Insert("period", ToUniversalTime(CurrentDate()));

	Return answer;

EndFunction

Function messageStatus(status)

	If status = "-1" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "-2" Or status = "47" Or status = "-98" Or status = "10"
			Or status = "11" Or status = "41" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "0" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "42" Or status = "46" Or status = "48" Or status = "69"
			Or status = "99" Or status = "255" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "" Then
		Return Enums.messageStatuses.read;
	Else
		Return status;
	EndIf;

EndFunction

Function GetSessionId(parameters, answer)

	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);

	URL = "rest/User/SessionId?login=" + parameters.user + "&password="
		+ parameters.password;

	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());

	If answerHTTP.КодСостояния = 200 Then

		If StrLen(answerBody) = 38 Then
			answer.Вставить("key", Mid(answerBody, 2, 36));
		Else
			answer.Вставить("error", "Ключ не получен");
		EndIf;
	Else
		answer.Вставить("error", answerBody);
	EndIf;

	Возврат answer;

EndFunction