Function sendSMS(parameters, answer) Export

	JSONSecurity = New Structure;
	JSONSecurity.Insert("login", XMLString(parameters.user));
	JSONSecurity.Insert("password", XMLString(parameters.password));

	MessageArray = New Array;
	AbonentArray = New Array;
	JSONMessage = New Structure;
	JSONAbonent = New Structure;

	JSONAbonent.Insert("phone", XMLString(parameters.phone));
	JSONAbonent.Insert("number_sms", XMLString("1"));
	AbonentArray.Add(JSONAbonent);

	JSONMessage.Insert("type", XMLString("sms"));
	JSONMessage.Insert("sender", XMLString(parameters.senderName));
	JSONMessage.Insert("text", XMLString(parameters.text));
	JSONMessage.Insert("name_delivery", XMLString("Шлюз"));
	JSONMessage.Insert("abonent", AbonentArray);
	MessageArray.Add(JSONMessage);

	JSONValue = New Structure;
	JSONValue.Insert("security", JSONSecurity);
	JSONValue.Insert("type", XMLString("sms"));
	JSONValue.Insert("message", MessageArray);

	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, JSONValue);

	JSONString = JSONWriter.Закрыть();

	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

	Headers = New Map;
	Headers.insert("Content-Type", "application/json; charset=utf-8");

	requestHTTP = New HTTPRequest("/sendsmsjson.php", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());

	answerBody = ConnectionHTTP.Post(requestHTTP);
	JSONStructure = "";

	If answerBody.КодСостояния = 200 Then
		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();

		If JSONStructure.Свойство("sms") Then
			AnswerStructure = JSONStructure.sms[0];
			If AnswerStructure.Свойство("error") Then
				answer.Insert("error", AnswerStructure.error);
			ElsIf AnswerStructure.Свойство("id_sms") Then
				answer.Insert("id", String(Format(AnswerStructure.id_sms, "NG=")));
				answer.Insert("messageStatus", Enums.messageStatuses.sent);
			EndIf;
		ElsIf JSONStructure.Свойство("error") Then
			answer.Insert("error", JSONStructure.error);
		EndIf;
	Else
		answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
	Endif;

	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs(Headers, JSONString, JSONStructure);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);

	Return answer;
EndFunction

Function checkSmsStatus(parameters, answer) Export

	JSONSecurity = New Structure;
	JSONSecurity.Insert("login", XMLString(parameters.user));
	JSONSecurity.Insert("password", XMLString(parameters.password));

	MessageIdArray = New Array;
	MessageIdArray.Add(parameters.id);

	JSONValue = New Structure;
	JSONValue.Insert("security", JSONSecurity);
	JSONValue.Insert("type", XMLString("state"));
	JSONValue.Insert("get_state", MessageIdArray);

	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, JSONValue);

	JSONString = JSONWriter.Закрыть();

	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

	Headers = New Map;
	Headers.insert("Content-Type", "application/json; charset=utf-8");

	requestHTTP = New HTTPRequest("/sendsmsjson.php", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());

	answerBody = ConnectionHTTP.Post(requestHTTP);

	If answerBody.StatusCode = 200 Then

		JSONReader = Новый JSONReader;
		JSONReader.SetString(answerBody.GetBodyAsString());
		JSONStructure = ReadJSON(JSONReader);
		JSONReader.Закрыть();

		If JSONStructure.Свойство("state") Then
			AnswerStructure = JSONStructure.state[0];

			If AnswerStructure.state = "deliver" Then
				answer.Insert("messageStatus", Enums.messageStatuses.delivered);
			Else
				answer.Insert("error", AnswerStructure.state);
			EndIf;

		ElsIf JSONStructure.Свойство("error") Then
			answer.Insert("error", JSONStructure.error);
		EndIf;

	Else
		answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
	Endif;

	answer.Insert("period", ToUniversalTime(CurrentDate()));

	Return answer;
EndFunction