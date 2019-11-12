
Function sendSMS(parameters, answer) Export	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	headers = New Map;
	headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	URL = "/modules/send_sms.php";
	requestHTTP = New HTTPRequest(URL, headers);	
	parametersStr = "username=" + parameters.user +	"&password=" + parameters.password + "&to=" + parameters.phone + "&from=" + parameters.senderName + "&coding=2" + "&text=" + parameters.text;	
	requestHTTP.SetBodyFromString(parametersStr,,ByteOrderMarkUsage.DontUse);
	answerHTTP = ConnectionHTTP.Post(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());	
	ReaderHTML = New HTMLReader;
	ReaderHTML.SetString(answerBody);	
	DOMBuilder = New DOMBuilder;
	docHTML = DOMBuilder.Read(ReaderHTML);	
	decodeStruct = decodeNodes(docHTML.GetElementByTagName("body")[0].ChildNodes);
	If decodeStruct.Property("error") Then 
		descriptionError = descriptionError(decodeStruct.Error);
		answer.Insert("error", descriptionError);
	ElsIf  decodeStruct.Property("Success") Then
		answer.Insert("id", decodeStruct.ID);
		answer.Insert("messageStatus", Enums.messageStatuses.sent);
	EndIf;	
	answer.Insert("period", ToUniversalTime(CurrentDate()));	
	Return answer;	
EndFunction

Function checkSmsStatus(parameters, answer) Export
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	headers = New Map;
	headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	URL = "/modules/sms_status.php";	
	requestHTTP = New HTTPRequest(URL, headers);	
	parametersStr = "username=" + parameters.user +	"&password=" + parameters.password + "&id=" + parameters.id;	
	requestHTTP.SetBodyFromString(parametersStr,,ByteOrderMarkUsage.DontUse);
	answerHTTP = ConnectionHTTP.Post(requestHTTP);
	answerBody = TrimAll(answerHTTP.GetBodyAsString());	
	ReaderHTML = New HTMLReader;
	ReaderHTML.SetString(answerBody);	
	DOMBuilder = New DOMBuilder;
	docHTML = DOMBuilder.Read(ReaderHTML);	
	decodeStruct = decodeNodes(docHTML.GetElementByTagName("body")[0].ChildNodes);		
	If decodeStruct.Property("error") Then 
		descriptionError = descriptionError(decodeStruct.Error);
		answer.Insert("error", descriptionError);
		answer.Insert("messageStatus", Enums.messageStatuses.notDelivered);
	ElsIf  decodeStruct.Property("Status") Then
		Статус = getMessageStatus(decodeStruct.Status);
		answer.Insert("messageStatus", Статус);
	EndIf;
	answer.Insert("period", ToUniversalTime(CurrentDate()));
	Return answer;
EndFunction

Function descriptionError(error)	
	description = "";
	If error = "Invalid request" Then 
		description = "проверьте наличие всех неоходимых параметров в запросе";
	ElsIf error = "Invalid username username or password password or user is blocked" Then 
		description = "Проверьте login и password и то, что ваш аккаунт не заблокирован";
	ElsIf error = "Invalid or missing 'from' address" Then 
		description = "Проверьте наличие и формат номера получателя";
	ElsIf error = "Invalid or missing 'to' address" Then 
		description = "Проверьте наличие и длину адреса отправителя";
	ElsIf error = "Invalid or missing coding" Then 
		description = "Проверьте наличие и значение параметра coding";
	ElsIf error = "Missing text" Then 
		description = "Проверьте наличие параметра text";
	ElsIf error = "Text too long" Then 
		description = "Проверьте длину параметра text";
	ElsIf error = "Invalid or missing mclass" Then 
		description = "Проверьте наличие и значение параметра mclass";
	ElsIf error = "Invalid or missing priority" Then 
		description = "Проверьте наличие и значение параметра priority";
	ElsIf error = "Invalid or missing dlrmask" Then 
		description = "Проверьте наличие и значение параметра dlrmask";
	ElsIf error = "IP not allowed" Then 
		description = "Ваш IP заблокирован";
	ElsIf error = "Max limit exceeded" Then 
		description = "Вы достили максимального количества СМС";
	ElsIf error = "Insufficient balance" Then 
		description = "У вас недостаточно средств на балансе";
	ElsIf error = "Invalid or missing missing message message ID" Then 
		description = "Проверьте наличие идентификатора Messages";
	ElsIf error = "Unknown message ID" Then 
		description = "Проверьте идентификатор Messages";
	EndIf;	
	Return description;	
EndFunction

Function getMessageStatus(status)	
	If status = "16" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "32" Then
		Return Enums.messageStatuses.notSent;
	ElsIf status = "2" Then
		Return Enums.messageStatuses.notDelivered;
	ElsIf status = "0" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "4" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "8" Then
		Return Enums.messageStatuses.sent;
	ElsIf status = "1" Then
		Return Enums.messageStatuses.delivered;
	Иначе
		Return status;
	EndIf;	
EndFunction

Function decodeNodes(nodes)	
	Struct = New Structure();	
	For Each node Из nodes Do
		If node.NodeType = DOMNodeType.Text Then 
			If StrFind(node.TextContent, "ID:") > 0 Then
				Struct.Insert("ID",TrimAll(StrReplace(node.TextContent,"ID:","")));
			ElsIf StrFind(node.TextContent, "Status:") > 0 Then
				Struct.Insert("Status",TrimAll(StrReplace(node.TextContent,"Status:","")));
			ElsIf StrFind(node.TextContent, "Status update time:") > 0 Then
				Struct.Insert("StatusUpdateTime",TrimAll(StrReplace(node.TextContent,"Status update time:","")));
			ElsIf StrFind(node.TextContent, "error:") > 0 Then
				Struct.Insert("error",TrimAll(StrReplace(node.TextContent,"error:","")));
			ElsIf StrFind(node.TextContent, "Success") > 0 Then
				Struct.Insert("Success",TrimAll(StrReplace(node.TextContent,"Success:","")));
			EndIf;
		EndIf;
	EndDo;
	Return Struct;	
EndFunction


