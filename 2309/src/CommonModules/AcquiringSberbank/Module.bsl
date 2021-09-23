
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

Procedure checkOrderAppleGoogle(parameters) Export
			
	requestBody = New Structure();
	requestBody.Insert("merchant" , 	parameters.merchantID);
	requestBody.Insert("orderNumber" , 	parameters.orderNumber);
	requestBody.Insert("paymentToken" , ?(parameters.Property("paymentData"),parameters.paymentData, ""));
	
	If parameters.order.acquiringRequest = enums.acquiringRequests.googlePay Then
		amount =  parameters.acquiringAmount;	
		requestBody.Insert("amount", amount*100);	
		requestBody.Insert("returnUrl", "https://solutions.worldclass.ru/banking/success.html");
		requestBody.Insert("failUrl", "https://solutions.worldclass.ru/banking/fail.html");
	EndIf;
		
	requestURL = New Array();
	If parameters.acquiringRequest = enums.acquiringRequests.googlePay Then
		Connection = "/payment/google/payment.do";
	ElsIf parameters.acquiringRequest = enums.acquiringRequests.applePay Then
		 Connection ="/payment/applepay/payment.do";
	EndIf;
	Body = HTTP.encodeJSON(requestBody);
	requestURL.Add(Connection);
	requestURL.Add(Body);
	
	URL = StrConcat(requestURL, "");
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/json");
	requestHTTP.SetBodyFromString(Body, TextEncoding.UTF8);
	answerHTTP = ConnectionHTTP.Post(requestHTTP);
	
	answerStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);		
	parameters.Insert("response", answerStruct);
	If answerStruct.success = true Then									
		parameters.Insert("errorCode", "");
	Else
		parameters.Insert("result", "fail");
		parameters.Insert("errorCode", "rejected");		
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
		creditCardStruct.Insert("expiryDate", EndOfMonth(Date(response.expiration + "01")));
		creditCardStruct.Insert("ownerName", ?(response.cardAuthInfo.Property("cardholderName"),response.cardholderName,""));
		creditCardStruct.Insert("description", "**** **** **** "+Right(response.Pan, 4));
		creditCardStruct.Insert("paymentSystemCode", left(response.Pan,2));
		creditCardStruct.Insert("autoPayment",false);
	Else
		creditCardStruct.Insert("bindingId", "");					
	EndIf; 
	Return creditCardStruct;
EndFunction

Function requestExecute(parameters, requestName, requestParametrs, operation = "get")
	requestURL = New Array();
	requestURL.Add("/payment/rest/");
	requestURL.Add(requestName);
	requestURL.Add(".do?");
	requestURL.Add(StrConcat(requestParametrs, "&"));	
	request = New HTTPRequest(StrConcat(requestURL, ""));
	parameters.Insert("requestBody", request.ResourceAddress);	
	connection = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);

	try
		If operation = "get" Then
			result = connection.Get(request);
		Else
			result = connection.Post(request);
		EndIf;
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
		
	If parameters.Property("cardAuthInfo") Then
		cardAuthInfo = parameters.cardAuthInfo;
		details.Insert("approvalCode", ?(cardAuthInfo.Property("approvalCode"), cardAuthInfo.approvalCode, ""));		
		details.Insert("cardholderName", ?(cardAuthInfo.Property("cardholderName"), cardAuthInfo.cardholderName, ""));
		If cardAuthInfo.Property("maskedPan") Then
			details.Insert("maskedPan", cardAuthInfo.maskedPan);
			details.Insert("paymentSystem", TrimAll(Acquiring.paymentSystem(left(cardAuthInfo.maskedPan, 2))));
		EndIf;
	EndIf;
	If parameters.Property("bankInfo") And parameters.bankInfo.Property("bankName") Then
		details.Insert("bankName", parameters.bankInfo.bankName);
	EndIf;
	
	Return HTTP.encodeJSON(details);
	
EndFunction

Procedure autoPayment(parameters) Export
	
	requestParametrs = New Array();
	requestParametrs.Add("userName=" 	+ parameters.user);	
	requestParametrs.Add("password=" 	+ parameters.password);
	requestParametrs.Add("mdOrder=" 	+ XMLString(parameters.orderId));
	requestParametrs.Add("bindingId=" 	+ XMLString(parameters.creditCard));
	requestParametrs.Add("ip=" 			+ parameters.ipAddress);	
	response = requestExecute(parameters, "paymentOrderBinding", requestParametrs, "post");
		
	If response <> Undefined and response.StatusCode = 200 Then
		responseStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", responseStruct);	
		If responseStruct.Property("errorCode") Then
			If responseStruct.errorCode = 0 Then
				parameters.Insert("errorCode", "");
			Else
				parameters.Insert("errorCode", responseStruct.errorCode);
				parameters.Insert("errorDescription", responseStruct.errorMessage);
			EndIf;
		Else
			parameters.Insert("errorCode", responseStruct.errorCode);
			parameters.Insert("errorDescription", responseStruct.errorMessage);	
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
			
	requestURL = New Array();
	requestURL.Add("/payment/rest/getOrderStatusExtended.do?");
	requestURL.Add(StrConcat(requestParametrs, "&"));
	
	
	URL = StrConcat(requestURL, "");
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	answerStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);		
	parameters.Insert("response", answerStruct);
	If answerHTTP.StatusCode = 200 Then
		If answerStruct.Property("actionCode") then						
			If answerStruct.actionCode = 0 Then			
				parameters.Insert("errorCode", "");
				orderObject = parameters.order.GetObject();
				newRow = orderObject.payments.Add();
				newRow.owner = ?(ValueIsFilled(parameters.ownerCreditCard), parameters.ownerCreditCard, parameters.bindingUser);
				newRow.type = "card";
				newRow.amount = parameters.acquiringAmount;			
				newRow.details = prepareDetails(answerStruct, parameters);			
				orderObject.Write();
			ElsIf answerStruct.actionCode = -100 Or answerStruct.actionCode = 151019 then
				parameters.Insert("errorCode", "send");
				parameters.Insert("errorDescription", answerStruct.actionCodeDescription);	
			ElsIf answerStruct.actionCode = -1 Or answerStruct.actionCode = 1001 
			   Or answerStruct.actionCode = 51018 Then
				parameters.Insert("errorCode", "fail");
				parameters.Insert("errorDescription", answerStruct.actionCodeDescription);
			Else
				parameters.Insert("errorCode", "rejected");
				parameters.Insert("errorDescription", answerStruct.actionCodeDescription);
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

