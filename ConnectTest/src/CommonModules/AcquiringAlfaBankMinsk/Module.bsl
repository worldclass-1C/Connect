Procedure sendOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" 		+ parameters.user);
	requestParametrs.Add("password=" 		+ parameters.password);
	requestParametrs.Add("orderNumber=" 	+ parameters.orderNumber);
	requestParametrs.Add("amount=" 			+ Format(parameters.acquiringAmount * 100,"NFD=0; NG=0"));
	requestParametrs.Add("returnUrl=" 		+ parameters.returnUrl);
	requestParametrs.Add("failUrl=" 		+ parameters.failUrl);
	requestParametrs.Add("pageView=DESKTOP");
	
	If ValueIsFilled(parameters.creditCard) Then
		If parameters.Property("customerCode") then
			requestParametrs.Add("clientId=" + parameters.customerCode);
		else
			requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
		EndIf;
		requestParametrs.Add("bindingId=" + XMLString(parameters.creditCard));
	ElsIf parameters.acquiringRequest = Enums.acquiringRequests.binding Then
		requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
	EndIf;
	If parameters.connectionType = Enums.ConnectionTypes.autoPayment Then
		requestParametrs.Add("features=AUTO_PAYMENT");
	EndIf;
	response = requestExecute(parameters, "register", requestParametrs);
	If response <> Undefined Then
		responseStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", responseStruct);		
		If response.StatusCode = 200 Then
			If responseStruct.Property("orderId") Then
				parameters.Insert("orderId", responseStruct.orderId);
				parameters.Insert("formUrl", responseStruct.formUrl);
				parameters.Insert("errorCode", "");
				Acquiring.orderIdentifier(parameters.order,, responseStruct.orderId);
			Else
				parameters.Insert("errorCode", responseStruct.errorCode);
				parameters.Insert("errorDescription", responseStruct.errorMessage);	
			EndIf;
		Else
			parameters.Insert("errorCode", "acquiringConnection");		
		EndIf;
	Else
		parameters.Insert("errorCode", "acquiringConnection");				
	EndIf;	
EndProcedure

Procedure checkOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" 	+ parameters.user);
	requestParametrs.Add("password=" 	+ parameters.password);
	If parameters.connectionType <> Enums.ConnectionTypes.onlineStore then
		requestParametrs.Add("orderId=" 	+ XMLString(parameters.orderId));
	EndIf;

	requestParametrs.Add("orderNumber=" + parameters.orderNumber);
	response = requestExecute(parameters, "getOrderStatus", requestParametrs);
	If response <> Undefined Then		
		answerStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", answerStruct);
		If response.StatusCode = 200 Then
			If answerStruct.Property("OrderStatus") then						
				If answerStruct.OrderStatus = 2 Then			
					parameters.Insert("errorCode", "");
					orderObject = parameters.order.GetObject();
					newRow = orderObject.payments.Add();
					newRow.owner = ?(ValueIsFilled(parameters.ownerCreditCard), parameters.ownerCreditCard, parameters.bindingUser);
					newRow.type = "card";
					newRow.amount = parameters.acquiringAmount;			
					newRow.details = prepareDetails(answerStruct, parameters);			
					orderObject.Write();
				ElsIf answerStruct.OrderStatus = 0 then
					parameters.Insert("errorCode", "send");
					parameters.Insert("errorDescription", answerStruct.errorMessage);	
				Else
					parameters.Insert("errorCode", "rejected");
					parameters.Insert("errorDescription", answerStruct.errorMessage);
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
	Else
		parameters.Insert("errorCode", "acquiringConnection");	
	EndIf;	
EndProcedure

Procedure reverseOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName="	+ parameters.user);
	requestParametrs.Add("password=" 	+ parameters.password);
	requestParametrs.Add("orderId=" 	+ XMLString(parameters.orderId));
		
	response = requestExecute(parameters, "reverse", requestParametrs);		
	If response <> Undefined and response.StatusCode = 200 Then
		responseStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", responseStruct);
		If responseStruct.Property("errorCode") And responseStruct.errorCode <> "0" Then
			parameters.Insert("result", "fail");
			parameters.Insert("errorCode", responseStruct.errorCode);
			parameters.Insert("errorDescription", responseStruct.errorMessage);
		Else
			parameters.Insert("result", "ok");
			parameters.Insert("errorCode", "");
		EndIf;
	Else
		parameters.Insert("errorCode", "acquiringConnection");		
	EndIf;		
		
EndProcedure

Procedure unBindCard(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" 	+ parameters.user);
	requestParametrs.Add("password=" 	+ parameters.password);
	requestParametrs.Add("bindingId=" 	+ XMLString(parameters.creditCard));	
	
	response = requestExecute(parameters, "unBindCard", requestParametrs);	
	
	If response <> Undefined and response.StatusCode = 200 Then
		responseStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", responseStruct);				
		If responseStruct.Property("errorCode") And responseStruct.errorCode <> "0" Then
			parameters.Insert("result", "fail");
			parameters.Insert("errorCode", responseStruct.errorCode);
			parameters.Insert("errorDescription", responseStruct.errorMessage);
		Else
			parameters.Insert("result", "ok");
			parameters.Insert("errorCode", "");
		EndIf;
	Else
		parameters.Insert("result", "fail");
		parameters.Insert("errorCode", "acquiringConnection");		
	EndIf;		
		
EndProcedure

Function bindCardParameters(parameters) Export
	response = parameters.response;
	creditCardStruct = New Structure();
	If response.Property("bindingInfo") Then		
		creditCardStruct.Insert("bindingId", response.bindingInfo.bindingId);
		creditCardStruct.Insert("userId", response.bindingInfo.clientId);
		creditCardStruct.Insert("acquiringBank", parameters.acquiringProvider);
		creditCardStruct.Insert("active", True);
		creditCardStruct.Insert("autopayment", False);
		creditCardStruct.Insert("expiryDate", EndOfMonth(Date(response.cardAuthInfo.expiration + "01")));
		creditCardStruct.Insert("ownerName", ?(response.cardAuthInfo.Property("cardholderName"),response.cardAuthInfo.cardholderName,""));
		creditCardStruct.Insert("description", "**** **** **** "+Right(response.cardAuthInfo.maskedPan, 4));
		creditCardStruct.Insert("paymentSystemCode", left(response.cardAuthInfo.maskedPan,2));
		creditCardStruct.Insert("autoPayment",false);
	Else
		creditCardStruct.Insert("bindingId", "");					
	EndIf; 
	Return creditCardStruct;
EndFunction

Function requestExecute(parameters, requestName, requestParametrs)
	requestURL = New Array();
	requestURL.Add("payment/rest");
	requestURL.Add(requestName);
	requestURL.Add(".do");
	Body = StrConcat(requestParametrs, "&");	
	request = New HTTPRequest(StrConcat(requestURL, ""));
	request.Headers.Insert("Content-Type", "application/x-www-form-urlencoded; charset=utf-8");
	request.SetBodyFromString(body,TextEncoding.UTF8,ByteOrderMarkUsage.DontUse);
	
	parameters.Insert("requestBody", Body);	
	connection = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);

	try
		result = connection.Post(request);
	Except
		result = Undefined;
	EndTry;
			
	Return result;

EndFunction

Function prepareDetails(parameters, parametersQuery)
	
	details = New Structure();
	
	details.Insert("terminalId", ?(parameters.Property("terminalId"), parameters.terminalId, ""));
	details.Insert("authRefNum", ?(parameters.Property("authRefNum"), parameters.authRefNum, ""));
	dateTime = Date(1,1,1);
	If parameters.Property("authDateTime") then
		try
			dateTime = '19700101' + Number(parameters.authDateTime)/1000;
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
				
	details.Insert("approvalCode", ?(parameters.Property("approvalCode"), parameters.approvalCode, ""));		
	details.Insert("cardholderName", ?(parameters.Property("cardholderName"), parameters.cardholderName, ""));
	If parameters.Property("Pan") Then
		details.Insert("maskedPan", parameters.Pan);
		details.Insert("paymentSystem", TrimAll(Acquiring.paymentSystem(left(parameters.Pan, 2))));
	EndIf;
	
	
	details.Insert("bankName", "alfaBank");
	
	
	Return HTTP.encodeJSON(details);
	
EndFunction
