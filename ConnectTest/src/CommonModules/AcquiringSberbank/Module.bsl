
Procedure sendOrder(parameters) Export
			
	requestParametrs = New Array();
	requestParametrs.Add("userName=" + parameters.user);
	requestParametrs.Add("password=" + parameters.password);
	requestParametrs.Add("orderNumber=" + parameters.orderNumber);
	requestParametrs.Add("amount=" + (parameters.acquiringAmount * 100));
	requestParametrs.Add("returnUrl=" + parameters.returnUrl);
	requestParametrs.Add("failUrl=" + parameters.failUrl);
	requestParametrs.Add("pageView=" + parameters.pageView);
	
	If ValueIsFilled(parameters.bindingId) Then
		requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
		requestParametrs.Add("bindingId=" + parameters.bindingId);
	ElsIf parameters.acquiringRequest = Enums.acquiringRequests.binding Then
		requestParametrs.Add("clientId=" + XMLString(parameters.bindingUser));
	EndIf;
		
	requestURL = New Array();
	requestURL.Add("/payment/rest/register.do?");
	requestURL.Add(StrConcat(requestParametrs, "&"));
	
	URL = StrConcat(requestURL, "");
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port, parameters.user, parameters.password,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(URL);
	answerHTTP = ConnectionHTTP.Get(requestHTTP);
	If answerHTTP.StatusCode = 200 Then
		parameters.Insert("responseBody", answerHTTP.GetBodyAsString());
		answerStruct = HTTP.decodeJSON(parameters.responseBody, Enums.JSONValueTypes.structure);
		If answerStruct.Property("orderId") Then
			parameters.Insert("orderId", answerStruct.orderId);
			parameters.Insert("formUrl", answerStruct.formUrl);
			parameters.Insert("errorCode", "");
			orderIdentifier(parameters.order, answerStruct.orderId);
		Else
			parameters.Insert("errorDescription", answerStruct.errorMessage);	
		EndIf;
	EndIf;		
		
EndProcedure

Function orderIdentifier(order, orderId)
	orderIdentifierRef = Catalogs.acquiringOrderIdentifiers.GetRef(New UUID(orderId));
	orderIdentifier = Catalogs.acquiringOrderIdentifiers.CreateItem();
	orderIdentifier.SetNewObjectRef(orderIdentifierRef);
	orderIdentifier.Owner = order;
	orderIdentifier.Write();
	Return orderIdentifier.Ref;	
EndFunction 