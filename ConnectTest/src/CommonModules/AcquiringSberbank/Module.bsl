
Procedure sendOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" + parameters.user);
	requestParametrs.Add("password=" + parameters.password);
	requestParametrs.Add("orderNumber=" + parameters.orderNumber);
	requestParametrs.Add("amount=" + Format(parameters.acquiringAmount * 100,"NFD=0; NG=0"));
	requestParametrs.Add("returnUrl=" + parameters.returnUrl);
	requestParametrs.Add("failUrl=" + parameters.failUrl);
	requestParametrs.Add("pageView=DESKTOP");
	
	If ValueIsFilled(parameters.bindingId) Then
		requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
		requestParametrs.Add("bindingId=" + parameters.bindingId);
	ElsIf parameters.acquiringRequest = Enums.acquiringRequests.binding Then
		requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
	EndIf;
	
	response = requestExecute(parameters, "register", requestParametrs);		
	If response.StatusCode = 200 Then
		responseStruct = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", responseStruct);
		If responseStruct.Property("orderId") Then
			parameters.Insert("orderId", responseStruct.orderId);
			parameters.Insert("formUrl", responseStruct.formUrl);
			parameters.Insert("errorCode", "");
			orderIdentifier(parameters.order, responseStruct.orderId);
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
	requestParametrs.Add("userName=" + parameters.user);
	requestParametrs.Add("password=" + parameters.password);
	requestParametrs.Add("orderId=" + XMLString(parameters.orderId));
	requestParametrs.Add("orderNumber=" + parameters.orderNumber);
			
	requestURL = New Array();
	requestURL.Add("/payment/rest/getOrderStatusExtended.do?");
	requestURL.Add(StrConcat(requestParametrs, "&"));
	
	URL = StrConcat(requestURL, "");
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	If answerHTTP.StatusCode = 200 Then
		answerStruct = HTTP.decodeJSON(answerHTTP.GetBodyAsString(), Enums.JSONValueTypes.structure);		
		parameters.Insert("response", answerStruct);				
		If answerStruct.actionCode = 0 Then
			parameters.Insert("result", "ok");
			parameters.Insert("errorCode", "");
		Else		
			parameters.Insert("result", "fail");
			parameters.Insert("errorDescription", answerStruct.errorMessage);	
		EndIf;
	Else
		parameters.Insert("result", "fail");
		parameters.Insert("errorCode", "acquirerNotAvailable");
		parameters.Insert("errorDescription", "acquirer not available");
	EndIf;		
		
EndProcedure

Procedure reverseOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" + parameters.user);
	requestParametrs.Add("password=" + parameters.password);
	requestParametrs.Add("orderId=" + XMLString(parameters.orderId));
		
	response = requestExecute(parameters, "reverse", requestParametrs);		
	If response.StatusCode = 200 Then
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
	requestParametrs.Add("userName=" + parameters.user);
	requestParametrs.Add("password=" + parameters.password);
	requestParametrs.Add("bindingId=" + XMLString(parameters.creditCard));	
	
	response = requestExecute(parameters, "unBindCard", requestParametrs);	
	
	If response.StatusCode = 200 Then
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
		creditCardStruct.Insert("acquiringBank", "Sberbank");
		creditCardStruct.Insert("active", True);
		creditCardStruct.Insert("autopayment", False);
		creditCardStruct.Insert("expiryDate", EndOfMonth(Date(response.cardAuthInfo.expiration + "01")));
		creditCardStruct.Insert("ownerName", response.cardAuthInfo.cardholderName);
		creditCardStruct.Insert("description", response.cardAuthInfo.maskedPan);
	Else
		creditCardStruct.Insert("bindingId", "");					
	EndIf; 
	Return creditCardStruct;
EndFunction

Function orderIdentifier(order, orderId)
	orderIdentifierRef = Catalogs.acquiringOrderIdentifiers.GetRef(New UUID(orderId));
	orderIdentifier = Catalogs.acquiringOrderIdentifiers.CreateItem();
	orderIdentifier.SetNewObjectRef(orderIdentifierRef);
	orderIdentifier.Owner = order;
	orderIdentifier.Write();
	Return orderIdentifier.Ref;	
EndFunction 

Function requestExecute(parameters, requestName, requestParametrs)
	requestURL = New Array();
	requestURL.Add("/payment/rest/");
	requestURL.Add(requestName);
	requestURL.Add(".do?");
	requestURL.Add(StrConcat(requestParametrs, "&"));	
	request = New HTTPRequest(StrConcat(requestURL, ""));
	parameters.Insert("requestBody", request.ResourceAddress);	
	connection = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);	
	Return connection.Get(request);
EndFunction

