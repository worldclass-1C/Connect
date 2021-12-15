Procedure getQr(parameters, additionalParameters) Export
	
	body = new structure;
	currentDate = XDTOSerializer.XMLString(ToLocalTime(parameters.order.registrationDate,parameters.timeZone))+".107227"+?(StandardTimeOffset(parameters.timeZone)>0,"+","-")+format('00010101' + StandardTimeOffset(parameters.timeZone),"DF=HH:mm");
	dateEnd		= XDTOSerializer.XMLString(ToLocalTime(parameters.order.registrationDate+20*60,parameters.timeZone))+".107227"+?(StandardTimeOffset(parameters.timeZone)>0,"+","-")+format('00010101' + StandardTimeOffset(parameters.timeZone),"DF=HH:mm");
	body.Insert("account", 				parameters.user);
	body.Insert("amount", 				parameters.acquiringAmount);
	body.Insert("createDate", 			currentDate);
	body.Insert("currency",				"RUB");
	body.Insert("order",				XMLString(parameters.order));
	body.Insert("paymentDetails",		"");
	body.Insert("qrType",				"QRDynamic");
	body.Insert("qrExpirationDate",		dateEnd);
	body.Insert("sbpMerchantId",		parameters.merchantID);
	Connection ="/api/sbp/v1/qr/register";
	parameters.Insert("requestBody", 	http.encodeJSON(body));	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/json");
	requestHTTP.SetBodyFromString(http.encodeJSON(body), TextEncoding.UTF8);
	try
		answerHTTP = ConnectionHTTP.Post(requestHTTP);
	Except
		answerHTTP = Undefined;
	EndTry;
	If answerHTTP <> Undefined Then		
		responseStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);
		parameters.Insert("response", responseStruct);
		If responseStruct.Property("code") and responseStruct.code = "SUCCESS" then
			If responseStruct.Property("qrId") then
				Acquiring.orderIdentifier(parameters.order, responseStruct.qrId);
			EndIf;
			parameters.Insert("orderId", XMLString(parameters.order));
			If parameters.Property("systemType") Then
				SystemType = parameters.systemType;
			EndIf;
			if (SystemType.IsEmpty()) or SystemType = Enums.systemTypes.Web then  
				parameters.Insert("formUrl", responseStruct.qrUrl);
				parameters.Insert("payload", responseStruct.payload);
				sendPush(parameters, additionalParameters, responseStruct.payload);
			else
				parameters.Insert("formUrl", responseStruct.payload);
			EndIf;
					
			parameters.Insert("errorCode", "");	
		else
			parameters.Insert("errorCode", ?(responseStruct.Property("code"),responseStruct.code,"acquiringConnection"));	
		EndIf;
	else
		parameters.Insert("errorCode", "acquiringConnection");
	EndIf;
EndProcedure

Procedure sendPush(parameters, additionalParameters, qrLink)
	
	query = new query;
	query.Text = "SELECT
	|	""Customer"" AS appType,
	|	acquiringOrders.user,
	|	acquiringOrders.gym
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|WHERE
	|	acquiringOrders.Ref = &Ref";
	query.Parameters.Insert("Ref", parameters.order);
	selection = query.Execute().Select();
	If selection.next() Then
		parametersNew = Service.getStructCopy(additionalParameters);
		parametersNew.Insert("requestName", "sendMessage");
		routs = new array;
		routs.Add("pushCustomer");
		TextPush = NStr("ru='Для оплаты счета на сумму ';en='To pay an invoice for '", additionalParameters.languageCode)+parameters.acquiringAmount+NStr("ru=' перейдите по ссылке ';en=' follow the link '", additionalParameters.languageCode)+qrLink;
		requestStruct = new Structure("action, appType, uid, title, text, routes, gymId",
										"Payload", 
										selection.appType, 
										XmlString(selection.user), 
										NStr("ru='Ссылка на оплату';en='Payment link'", additionalParameters.languageCode),
										TextPush,
										routs,
										XmlString(selection.gym));
		requestArray = New array;
		requestArray.Add(requestStruct);
		parametersNew.Insert("requestStruct", new structure("messages",requestArray));
		parametersNew.Insert("internalRequestMethod", True);
		General.executeRequestMethod(parametersNew);
	EndIf;
	
EndProcedure

Procedure checkStatus(parameters) Export
	If ValueIsFilled(parameters.orderId) Then
		requestURL = New Array();
		requestURL.Add("/api/sbp/v1/qr/"+?(ValueIsFilled(parameters.orderId), parameters.orderId.description, "")+"/payment-info");
			
		URL = StrConcat(requestURL, "");
		parameters.Insert("requestBody", URL);	
		ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, ,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
		requestHTTP = New HTTPRequest(URL);
		requestHTTP.Headers.Insert("Authorization", "Bearer "+parameters.key);
		Try
			answerHTTP = ConnectionHTTP.Get(requestHTTP);
		Except
			answerHTTP = Undefined;
		EndTry;
		If answerHTTP <> Undefined Then	
			answerStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);		
			parameters.Insert("response", answerStruct);
			If answerHTTP.StatusCode = 200 Then
				If answerStruct.Property("paymentStatus") then						
					If answerStruct.paymentStatus = "SUCCESS" Then			
						parameters.Insert("errorCode", "");
						orderObject = parameters.order.GetObject();
						newRow = orderObject.payments.Add();
						newRow.owner = ?(ValueIsFilled(parameters.ownerCreditCard), parameters.ownerCreditCard, parameters.bindingUser);
						newRow.type = "card";
						newRow.details = prepareDetails(answerStruct, parameters);
						newRow.amount = parameters.acquiringAmount;						
						orderObject.Write();
					ElsIf answerStruct.paymentStatus = "DECLINED" Then
						parameters.Insert("errorCode", "rejected");
						parameters.Insert("errorDescription", 400);
					ElsIf parameters.order.registrationDate < ToUniversalTime(CurrentDate())-25*60 Then
						parameters.Insert("errorCode", "rejected");
						parameters.Insert("errorDescription", "Истек срок ожидания ввода данных."); 
					Else
						parameters.Insert("errorCode", "send");
						parameters.Insert("errorDescription", "");
					EndIf;
				Else
					parameters.Insert("errorCode", "rejected");
					If answerStruct.Property("errorMessage") then
						parameters.Insert("errorDescription", answerStruct.errorMessage);
					EndIf;
				EndIf;
			Else
				parameters.Insert("result", "fail");
				parameters.Insert("errorCode", "acquiringConnection");		
			EndIf;
		else
			parameters.Insert("errorCode", "acquiringConnection");
		EndIf;
	else
		parameters.Insert("errorCode", "rejected");
		parameters.Insert("errorDescription", "Истек срок ожидания ввода данных."); 
	EndIf;
	
EndProcedure

Function prepareDetails(parameters, parametersQuery)
	
	details = New Structure();
	
	details.Insert("terminalId", ?(parameters.Property("terminalId"), parameters.terminalId, ""));
	details.Insert("authRefNum", ?(parameters.Property("authRefNum"), parameters.authRefNum, ""));
	details.Insert("timeZone", ?(parametersQuery.Property("tokenContext"), string(parametersQuery.tokenContext.token.timeZone), ""));
	
	If parameters.Property("transactionDate") then
		details.Insert("authDateTime", parameters.transactionDate);
	Else	
		details.Insert("authDateTime", XMLString(Date(1, 1, 1)));
	EndIf;	
	
	details.Insert("approvalCode", "");
	details.Insert("maskedPan", "");
	details.Insert("cardholderName", "");
	details.Insert("paymentSystem", "");
	details.Insert("bankName", "");
			
	Return HTTP.encodeJSON(details);
	
EndFunction
