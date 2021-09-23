Function sendSMS(parameters, answer) Export
	
	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

	Headers = New Map;
	Headers.insert("authorization", "Bearer " + parameters.password);
	Headers.insert("Content-Type", "application/x-www-form-urlencoded");

	JSONString = 
	"msids=" 	+ parameters.phone + 
	"&message=" + parameters.text +
	"&naming=" 	+ parameters.senderName + 
	"&login=&password=";

	requestHTTP = New HTTPRequest("/M2M/m2m_api.asmx/SendMessages", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());

	answerBody = ConnectionHTTP.Post(requestHTTP);
	answerString = "";

	If answerBody.StatusCode = 200 Then

		answerString = TrimAll(answerBody.GetBodyAsString());

		XMLReader = New XMLReader;
		XMLReader.SetString(answerString);
		CurrentPath = "";

		While XMLReader.Read() Do

			If XMLReader.NodeType = XMLNodeType.StartElement
					And XMLReader.Name = "MessageID" Then
				CurrentPath = "MessageID";
			EndIf;

			If XMLReader.NodeType = XMLNodeType.Text And CurrentPath = "MessageID" Then
				answer.Insert("id", XMLReader.Value);
				answer.Insert("messageStatus", Enums.messageStatuses.sent);
				CurrentPath = "";
			EndIf;

		EndDo;

	Else
		answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
	Endif;

	answer.Insert("period", ToUniversalTime(CurrentDate()));
	AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs(Headers, JSONString, answerString);
	answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);

	Return answer;

EndFunction

Function checkSmsStatus(parameters, answer) Export

	ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

	Headers = New Map;
	Headers.insert("authorization", "Bearer " + parameters.password);
	Headers.insert("Content-Type", "application/x-www-form-urlencoded");

	JSONString = "messageID=" + parameters.id + "&login=&password=";

	requestHTTP = New HTTPRequest("/M2M/m2m_api.asmx/GetMessageStatus", Headers);
	requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());

	answerBody = ConnectionHTTP.Post(requestHTTP);

	If answerBody.StatusCode = 200 Then

		answerString = TrimAll(answerBody.GetBodyAsString());

		XMLReader = New XMLReader;
		XMLReader.SetString(answerString);
		CurrentPath = "";

		While XMLReader.Read() Do
			If XMLReader.NodeType = XMLNodeType.StartElement
					And XMLReader.Name = "DeliveryStatus" Then
				CurrentPath = "DeliveryStatus";
			EndIf;

			If XMLReader.NodeType = XMLNodeType.Text
					And currentPath = "DeliveryStatus" Then
				statusAnswer = XMLReader.Value;
				CurrentPath = "";
			EndIf;
		EndDo;

		status = messageStatus(Upper(statusAnswer));

		If TypeOf(status) = Type("EnumRef.messageStatuses") Then
			answer.Insert("messageStatus", status);
		Else
			answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
			answer.Insert("error", "Неизвестный status");
		EndIf;

	Else
		answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
	Endif;

	answer.Insert("period", ToUniversalTime(CurrentDate()));

	Return answer;

EndFunction

Function messageStatus(status)

	If status = "PENDING" Or status = "SENDING" Or status = "SENT" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "NOTSENT" Or status = "ERROR" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "DELIVERED" Then
		Return Enums.messageStatuses.delivered;
	ElsIf status = "NOTDELIVERED" Or status = "TIMEDOUT" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "" Then
		Return Enums.messageStatuses.read;
	Else
		Return status;
	EndIf;

EndFunction