Procedure sendOrder(parameters) Export
	
	body = "<?xml version=""1.0"" encoding=""UTF-8""?>
			|<TKKPG>
			|<Request>
			|<Operation>CreateOrder</Operation>
			|<Language>RU</Language>
			|<Order>
			|<OrderType>Purchase</OrderType>
			|<Merchant>"+parameters.user+"</Merchant>
			|<Amount>"+Format(parameters.acquiringAmount * 100,"NFD=0; NG=0")+"</Amount>
			|<Currency>398</Currency>
			|<Description>World Class</Description>
			|<ApproveURL>"+parameters.returnUrl+"</ApproveURL>
			|<CancelURL>"+parameters.failUrl+"</CancelURL>
			|<DeclineURL>"+parameters.failUrl+"</DeclineURL>
			|<AddParams>
			|<FA-DATA>Phone="+parameters.phone+"</FA-DATA>
			|<OrderExpirationPeriod>20</OrderExpirationPeriod>
			|</AddParams>
			|</Order>
			|</Request>
			|</TKKPG>";
	
	Connection ="/Exec";
	parameters.Insert("requestBody", 	body);	
	ConnectionHTTP = New HTTPConnection(parameters.server,,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/xml_request");
	requestHTTP.SetBodyFromString(body, TextEncoding.UTF8);
	try
		response = ConnectionHTTP.Post(requestHTTP);
	Except
		response = Undefined;
	EndTry;		
	
	If response <> Undefined Then
		responseStruct = HTTP.decodeXML(response.GetBodyAsString());		
		parameters.Insert("response", responseStruct);		
		If responseStruct.TKKPG.Response.Status = "00" Then
			If responseStruct.TKKPG.Response.Property("order") and responseStruct.TKKPG.Response.Order.Property("orderID") Then
				orderId 	= responseStruct.TKKPG.Response.Order.orderId;
				SessionID 	= responseStruct.TKKPG.Response.Order.SessionID;
				parameters.Insert("orderId", responseStruct.TKKPG.Response.Order.orderId);
				parameters.Insert("formUrl", responseStruct.TKKPG.Response.Order.Url+"?OrderID="+orderId+"&SessionID="+SessionID);
				parameters.Insert("errorCode", "");
				Acquiring.orderIdentifier(parameters.order,orderId,,SessionID);
			Else
				parameters.Insert("errorCode", "bankError");
				parameters.Insert("errorDescription", "Bank error");	
			EndIf;
		Else
			parameters.Insert("errorCode", "acquiringConnection");		
		EndIf;
	Else
		parameters.Insert("errorCode", "acquiringConnection");				
	EndIf;	
EndProcedure

Function prepareDetails(parametersDecode, parametersQuery)
	
	parameters = New Structure();
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
	details.Insert("bankName", "ForteBank");
		
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

Procedure checkOrder(parameters) Export
	
	body = "<?xml version=""1.0"" encoding=""UTF-8""?>
			|<TKKPG>
			|<Request>
			|<Operation>GetOrderStatus</Operation>
			|<Language>RU</Language>
			|<Order>
			|<Merchant>"+parameters.user+"</Merchant>
			|<OrderID>"+parameters.orderId.Description+"</OrderID>
			|</Order>
			|<SessionID>"+parameters.sessionId+"</SessionID>
			|</Request>
			|</TKKPG>";
	
	Connection ="/Exec";
	parameters.Insert("requestBody", 	http.encodeJSON(body));	
	ConnectionHTTP = New HTTPConnection(parameters.server,,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/xml_request");
	requestHTTP.SetBodyFromString(body, TextEncoding.UTF8);
	try
		response = ConnectionHTTP.Post(requestHTTP);
	Except
		response = Undefined;
	EndTry;		
	
	If response <> Undefined Then
		responseStruct = HTTP.decodeXML(response.GetBodyAsString());		
		parameters.Insert("response", responseStruct);		
		If responseStruct.TKKPG.Response.Status = "00" Then
			If responseStruct.TKKPG.Response.Property("order") and responseStruct.TKKPG.Response.Order.Property("orderID") Then
				If responseStruct.TKKPG.Response.Order.OrderStatus = "APPROVED" Then		
					parameters.Insert("errorCode", "");
					orderObject 	= parameters.order.GetObject();
					newRow 			= orderObject.payments.Add();
					newRow.owner 	= ?(ValueIsFilled(parameters.ownerCreditCard), parameters.ownerCreditCard, parameters.bindingUser);
					newRow.type 	= "card";
					newRow.amount 	= parameters.acquiringAmount;			
					newRow.details 	= prepareDetails("", parameters);			
					orderObject.Write();
				ElsIf responseStruct.TKKPG.Response.Order.OrderStatus = "ON-PAYMENT" or responseStruct.TKKPG.Response.Order.OrderStatus = "CREATED" Then
					parameters.Insert("errorCode", "send");
					parameters.Insert("errorDescription", "ON-PAYMENT");
				Else  
					parameters.Insert("errorCode", "rejected");
					parameters.Insert("errorDescription", "Rejected");
				EndIf;	
			Else
				parameters.Insert("errorCode", "fail");
				parameters.Insert("errorDescription", "Bank error");	
			EndIf;
		Else
			parameters.Insert("errorCode", "acquiringConnection");		
		EndIf;
	Else
		parameters.Insert("errorCode", "acquiringConnection");				
	EndIf;	
	
EndProcedure

