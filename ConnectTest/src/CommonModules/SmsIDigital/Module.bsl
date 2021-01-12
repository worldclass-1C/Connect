Function sendSMS(parameters, answer) Export
	
JSONValue = New Structure;
JSONValue.Insert("type", XMLString("outbound"));
JSONValue.Insert("addresses", New Structure("source, destination", XMLString(parameters.senderName), Number(parameters.phone)));
JSONValue.Insert("body", New Structure("bodyType, content", XMLString("text"), XMLString(parameters.text)));
JSONValue.Insert("nodeId", XMLString(parameters.user));
JSONValue.Insert("requestDelivery"	, True);
JSONWriter = New JSONWriter;
JSONWriter.SetString();
WriteJSON(JSONWriter, JSONValue);

JSONString = JSONWriter.Закрыть();

JSONString = StrReplace(JSONString, "type", "@type");

ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

Headers = New Map;
Headers.insert("authorization", "Basic " + Crypto.EncryptBase64(parameters.user + ":"
	+ parameters.password, "US-ASCII"));
Headers.insert("Content-Type", "application/json");

requestHTTP = New HTTPRequest("/message", Headers);
requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, GeneralReuse.getByteOrderMarkUse());

answerBody = ConnectionHTTP.Post(requestHTTP);
JSONStructure = "";

If answerBody.КодСостояния = 200 Then
	JSONReader = Новый JSONReader;
	JSONReader.SetString(answerBody.GetBodyAsString());
	JSONStructure = ReadJSON(JSONReader);
	JSONReader.Закрыть();

	If JSONStructure.code = 200 Then
		answer.Insert("id", JSONStructure.id);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);
	Else
		answer.Insert("error", GetErrorDescription(JSONStructure.code));
	EndIf;
Else
	answer.Insert("error", "Сбой при отрправке Messages 500 Internal Error");
Endif;

answer.Insert("period", ToUniversalTime(CurrentDate()));
AnswerResponseBodyForLogs =  Messages.GetAnswerResponseBodyForLogs(Headers, JSONString, JSONStructure);
answer.Insert("AnswerResponseBodyForLogs", AnswerResponseBodyForLogs);

Return answer;

EndFunction

Function checkSmsStatus(Request) Export

	requestBody = request.GetBodyAsString();
	requestBody = StrReplace(requestBody, "@type", "type");
	
	RequestParameters = HTTP.decodeJSON(requestBody, Enums.JSONValueTypes.structure, , False);

	If RequestParameters.code = 200 Then

		MessageArray = RequestParameters.states;
		
		VT_msid = New ValueTable();
		VT_msid.Columns.Add("msid", 		New TypeDescription("String",,New StringQualifiers(50)));
		VT_msid.Columns.Add("status", 		New TypeDescription("String"));
		VT_msid.Columns.Add("errorCode", 	New TypeDescription("Number"));
		VT_msid.Columns.Add("message", 		New TypeDescription("CatalogRef.messages"));
		VT_msid.Columns.Add("messageAge", 	New TypeDescription("Number"));
		
		For Each Message in MessageArray Do
			VT_msid_newString = VT_msid.Add();
			VT_msid_newString.msid 			= Message.msid;
			VT_msid_newString.status 		= Message.status;
			VT_msid_newString.errorCode 	= ?(Message.Property("errorCode"), Message.errorCode, "");
			VT_msid_newString.message 		= Catalogs.messages.EmptyRef();
			VT_msid_newString.messageAge	= 0;
		EndDo;

		Query = New Query;
		Query.Text =
			"SELECT
			|	VT_msid.msid AS msid
			|INTO Tab_msid
			|FROM
			|	&VT_msid AS VT_msid
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	DATEDIFF(messagesId.message.registrationDate, &currentDate, Day) AS messageAge,
			|	messagesId.message.Ref AS messageRef,
			|	messagesId.id
			|FROM
			|	Tab_msid AS Tab_msid
			|		LEFT JOIN InformationRegister.messagesId AS messagesId
			|		ON Tab_msid.msid = messagesId.id";
		
		Query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));
		Query.SetParameter("VT_msid", VT_msid);
		
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			VT_msid_String = VT_msid.Найти(SelectionDetailRecords.id, "msid");
			If VT_msid_String <> Undefined Then
				VT_msid_String.message = SelectionDetailRecords.messageRef;
				VT_msid_String.messageAge = SelectionDetailRecords.messageAge;
			EndIf;
		EndDo;
		
		For Each Message in VT_msid Do

			If Message.message <> Catalogs.messages.EmptyRef() Then

				MessageParameters = New Structure("message, nodeMessagesToCheckStatus, messageAge", Message.message, GeneralReuse.nodeMessagesToCheckStatus(Enums.informationChannels.sms), Message.messageAge);
				answer = New Structure("messageStatus, error, period", Enums.messageStatuses.notDelivered, "", Undefined);

				If Message.status = "DELIVERED" Or Message.status = "EXPIRED_READ" Then
					answer.messageStatus = Enums.messageStatuses.delivered;
				ElsIf Message.status = "UNDELIVERED" Or Message.status = "EXPIRED" Then
					answer.messageStatus = Enums.messageStatuses.notDelivered;
				ElsIf Message.status = "READ" Then
					answer.messageStatus = Enums.messageStatuses.read;
				EndIf;
				
				If Message.errorCode <> 0 Then
					MessageErrorDescription = GetMessageErrorDescription(Message.errorCode);
					answer.error = MessageErrorDescription;
				EndIf;

				answer.period = ToUniversalTime(CurrentDate());

				Messages.checkSmsStatusContinuation(answer, MessageParameters);

			Endif
		EndDo;
		Return New HTTPServiceResponse(200);
	Else
		Return New HTTPServiceResponse(500);
	Endif

EndFunction

Function GetErrorDescription(ErrorCode)
	
	ErrorDescription = "";
	
	If ErrorCode 		 = 400 Then
		ErrorDescription = "Неверный синтаксис запроса"
	ElsIf ErrorCode 	= 401 Then
		ErrorDescription = "Ошибка авторизации"
	ElsIf	ErrorCode 	= 403 Then
		ErrorDescription = "Доступ запрещён"
	ElsIf	ErrorCode 	= 405 Then
		ErrorDescription = "Метод запроса отключён и не может быть использован"
	ElsIf	ErrorCode 	= 415 Then
		ErrorDescription = "Некорректное значение заголовка Content-Type"
	ElsIf	ErrorCode 	= 415 Then
		ErrorDescription = "В запросе содержатся запрещённые к использованию слова"
	EndIf;
	
	Return ErrorDescription;
EndFunction

Function GetMessageErrorDescription(ErrorCode)
	
	ErrorDescription = "";

	If ErrorCode = 11 Then
		ErrorDescription = "Номер получателя указан некорректно или не существует"
	ElsIf ErrorCode = 127 Then
		ErrorDescription = "Истекло время ожидания статуса сообщения"
	ElsIf ErrorCode = 6969 Then
		ErrorDescription = "Неизвестная ошибка"
	ElsIf ErrorCode = 501 Then
		ErrorDescription = "Номер получателя указан некорректно или не существует"
	ElsIf ErrorCode = 502 Then
		ErrorDescription = "Ошибка центра передачи сообщений (SMSC) на стороне конечного оператора."
	ElsIf ErrorCode = 504 Then
		ErrorDescription = "Устройство абонента выключено или находится вне зоны действия сети"
	ElsIf ErrorCode = 505 Then
		ErrorDescription = "У абонента включен запрет на прием сообщений или абонента заблокировал оператор (возможно, в связи с отрицательным балансом)."
	ElsIf ErrorCode = 508 Then
		ErrorDescription = "Сервис коротких сообщений не предоставляется"
	ElsIf ErrorCode = 509 Then
		ErrorDescription = "Абонент находится в роуминге"
	ElsIf ErrorCode = 510 Then
		ErrorDescription = "SIM-карта абонента заменена менее суток назад"
	ElsIf ErrorCode = 511 Then
		ErrorDescription = "Очередь сообщений со стороны оператора переполнена"
	ElsIf ErrorCode = 515 Then
		ErrorDescription = "Аппаратная ошибка телефона абонента"
	ElsIf ErrorCode = 517 Then
		ErrorDescription = "Память телефона абонента переполнена"
	ElsIf ErrorCode = 518 Then
		ErrorDescription = "Ошибка центра передачи сообщений (SMSC) на стороне конечного оператора."
	ElsIf ErrorCode = 523 Then
		ErrorDescription = "Устройство абонента занято операцией, препятствующей получению короткого сообщения"
	ElsIf ErrorCode = 525 Then
		ErrorDescription = "Ошибка на стороне оператора при запросе IMSI"
	ElsIf ErrorCode = 557 Then
		ErrorDescription = "Внутренняя ошибка системы на стороне конечного оператора"
	ElsIf ErrorCode = 647 Then
		ErrorDescription = "Абонент не зарегистрирован или заблокирован оператором"
	Else
		ErrorDescription = "Неизвестная ошибка"
	EndIf;

	Return ErrorDescription;
EndFunction	