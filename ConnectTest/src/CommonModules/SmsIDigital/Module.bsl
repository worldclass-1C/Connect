Function sendSMS(parameters, answer) Export
	
JSONValue = New Structure;
JSONValue.Insert("type", XMLString("outbound"));
JSONValue.Insert("addresses", New Structure("source, destination", XMLString(parameters.senderName), Number(parameters.phone)));
JSONValue.Insert("body", New Structure("bodyType, content", XMLString("text"), XMLString(parameters.text)));
JSONValue.Insert("nodeId", XMLString(parameters.user));
//JSONValue.Insert("requestDelivery"	, Истина);
JSONWriter = New JSONWriter;
JSONWriter.SetString();
WriteJSON(JSONWriter, JSONValue);

JSONString = JSONWriter.Закрыть();

JSONString = StrReplace(JSONString, "type", "@type");

ssl = ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined);
ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, , , , 60, ssl);

Headers = New Map;
Headers.insert("Authorization", "Basic " + Crypto.EncryptBase64(parameters.user + ":"
	+ parameters.password, "US-ASCII"));
Headers.insert("Content-Type", "application/json");

requestHTTP = New HTTPRequest("/message", Headers);
requestHTTP.SetBodyFromString(JSONString, TextEncoding.UTF8, ByteOrderMarkUsage.DontUse);

answerBody = ConnectionHTTP.Post(requestHTTP);

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

Return answer;

EndFunction

Function checkSmsStatus(Request) Export
//test
	Return New HTTPServiceResponse(500);

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