Procedure getQr(parameters,additionalParameters) Export
	
	body = new structure;
	currentDate = XDTOSerializer.XMLString(ToLocalTime(CurrentSessionDate(),additionalParameters.tokenContext.timeZone))+".107227"+?(StandardTimeOffset(additionalParameters.tokenContext.timeZone)>0,"+","-")+format('00010101' + StandardTimeOffset(additionalParameters.tokenContext.timeZone),"DF=HH:mm");
	dateEnd		= XDTOSerializer.XMLString(ToLocalTime(CurrentSessionDate()+20*60,additionalParameters.tokenContext.timeZone))+".107227"+?(StandardTimeOffset(additionalParameters.tokenContext.timeZone)>0,"+","-")+format('00010101' + StandardTimeOffset(additionalParameters.tokenContext.timeZone),"DF=HH:mm");
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
	answerHTTP = ConnectionHTTP.Post(requestHTTP);	
	responseStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);
	parameters.Insert("response", responseStruct);
	If responseStruct.Property("code") and responseStruct.code = "SUCCESS" then
		If responseStruct.Property("qrId") then
			orderIdentifier(parameters.order, responseStruct.qrId);
		EndIf;
		parameters.Insert("orderId", XMLString(parameters.order));
		If additionalParameters.Property("tokenContext") And additionalParameters.tokenContext.Property("systemType") Then
			SystemType = additionalParameters.tokenContext.systemType;
		EndIf;
		if (SystemType.IsEmpty()) or SystemType = Enums.systemTypes.Web then  
			parameters.Insert("formUrl", responseStruct.qrUrl);
		else
			parameters.Insert("formUrl", responseStruct.payload);
		EndIf;
				
		parameters.Insert("errorCode", "");	
	else
		parameters.Insert("errorCode", ?(responseStruct.Property("code"),responseStruct.code,"acquiringConnection"));	
	EndIf;
	
EndProcedure

Procedure checkStatus(parameters) Export
	
	requestURL = New Array();
	requestURL.Add("/api/sbp/v1/qr/"+parameters.orderId.description+"/payment-info");
		
	URL = StrConcat(requestURL, "");
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, ,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	requestHTTP = New HTTPRequest(URL);
	requestHTTP.Headers.Insert("Authorization", "Bearer "+parameters.authorization);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);		
	parameters.Insert("response", answerStruct);
	If answerHTTP.StatusCode = 200 Then
		If answerStruct.Property("paymentStatus") then						
			If answerStruct.paymentStatus = "SUCSESS" Then			
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
				parameters.Insert("errorDescription", answerStruct.actionCodeDescription);
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
		
EndProcedure

Function orderIdentifier(order, orderId)
	orderIdentifier = Catalogs.acquiringOrderIdentifiers.CreateItem();
	orderIdentifier.Description = orderId;
	orderIdentifier.Owner = order;
	orderIdentifier.Write();
	Return orderIdentifier.Ref;	
EndFunction 

Function prepareDetails(parameters, parametersQuery)
	
	details = New Structure();
	
	details.Insert("terminalId", ?(parameters.Property("terminalId"), parameters.terminalId, ""));
	details.Insert("authRefNum", ?(parameters.Property("authRefNum"), parameters.authRefNum, ""));
	dateTime = Date(1,1,1);
	If parameters.Property("transactionDate") then
		try
			dateTime = parameters.transactionDate;
		Except
			dateTime = Date(1,1,1);
		EndTry;
	EndIf;	
	details.Insert("timeZone", ?(parametersQuery.Property("tokenContext"), string(parametersQuery.tokenContext.token.timeZone), ""));
	details.Insert("authDateTime", dateTime);
		
	details.Insert("approvalCode", "");
	details.Insert("maskedPan", "");
	details.Insert("cardholderName", "");
	details.Insert("paymentSystem", "");
	details.Insert("bankName", "");
			
	Return HTTP.encodeJSON(details);
	
EndFunction
