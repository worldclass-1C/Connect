
Function okURLPOST(Request)
	body = Request.getBodyAsString();
	if ValueIsFilled(body) then
		arrayParams = StrSplit(body, "&");
		responseParameters = new Structure();
	
		for each element in arrayParams do
			param = StrSplit(element, "=");
			responseParameters.Insert(StrReplace(StrReplace(param[0],"""",""),".",""), ?(param.Count()>=2,param[1],""));
		enddo;
		
		order = Undefined;
		if responseParameters.Property("ReturnOid") then
			order = service.getRef(left(responseParameters.ReturnOid,36), type("CatalogRef.acquiringOrders"));
		EndIf;
		newacquiringLog 				= Catalogs.acquiringLogs.CreateItem();
		newacquiringLog.order 			= order;
		newacquiringLog.period 			= ToUniversalTime(CurrentDate());
		newacquiringLog.isError 		= ?(responseParameters.Property("Response"), ?(responseParameters.Response = "Approved", false, true),true);
		newacquiringLog.responseBody 	= body;
		newacquiringLog.requestName 	= "check";
		newacquiringLog.Write();
		if ValueIsFilled(order) then
			orderObj = order.getObject();
			if orderObj <> Undefined then
				newRow = orderObj.payments.Add();
				newRow.owner = orderObj.user;
				newRow.type = "card";
				newRow.amount = ?(responseParameters.Property("amount"), Number(strReplace(responseParameters.amount,"%2C",".")),0);			
				newRow.details = prepareDetails(responseParameters);			
				orderObj.Write();
			EndIf;
		EndIf;
		if responseParameters.Property("Response") then
			if responseParameters.Response = "Approved" and ValueIsFilled(order) and orderObj <> Undefined then
				Acquiring.changeOrderState(order, Enums.acquiringOrderStates.success);
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.success);
			else
				Acquiring.changeOrderState(order, Enums.acquiringOrderStates.rejected);
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.rejected);
			EndIf;
		EndIf;
	EndIf;
	Response	= new HTTPServiceResponse(200);
	Response.Headers.Insert("Content-type", "application/json; charset=utf-8");
	Response.SetBodyFromString("ok");	
	return Response;
	
EndFunction

Function failURLPOST(Request)
	
	body = Request.getBodyAsString();
	if ValueIsFilled(body) then
		arrayParams = StrSplit(body, "&");
		responseParameters = new Structure();
	
		for each element in arrayParams do
			param = StrSplit(element, "=");
			responseParameters.Insert(StrReplace(StrReplace(param[0],"""",""),".",""), ?(param.Count()>=2,param[1],""));
		enddo;
		
		order = Undefined;
		if responseParameters.Property("ReturnOid") then
			order = service.getRef(left(responseParameters.ReturnOid,36), type("CatalogRef.acquiringOrders"));
		EndIf;
		newacquiringLog = Catalogs.acquiringLogs.CreateItem();
		newacquiringLog.order = order;
		newacquiringLog.period = ToUniversalTime(CurrentDate());
		newacquiringLog.isError = true;
		newacquiringLog.responseBody = body;
		newacquiringLog.requestName = "check";
		newacquiringLog.Write();
		orderObj = Undefined;
		if ValueIsFilled(order) then
			orderObj = order.getObject();
		EndIf;
		
		if ValueIsFilled(order) and orderObj <> Undefined then
			Acquiring.changeOrderState(order, Enums.acquiringOrderStates.rejected);
			Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.rejected);
		EndIf;
	EndIf;
	Response	= new HTTPServiceResponse(200);
	Response.Headers.Insert("Content-type", "application/json; charset=utf-8");
		
	return Response;
	
EndFunction

function prepareDetails(parameters)
	
	details = New Structure();
	
	details.Insert("terminalId", ?(parameters.Property("TransId"), parameters.TransId, ""));
	details.Insert("authRefNum", ?(parameters.Property("AuthCode"),parameters.AuthCode,""));
	dateTime = Date(1,1,1);
	If parameters.Property("EXTRATRXDATE") then
		try
			dateTime = Date(StrReplace(StrReplace(parameters.EXTRATRXDATE,"%3A",""),"+",""));
		Except
			dateTime = Date(1,1,1);
		EndTry;
	EndIf;	
	details.Insert("timeZone", "");
	details.Insert("authDateTime", dateTime);
		
	details.Insert("approvalCode", "");
	details.Insert("maskedPan", ?(parameters.Property("MaskedPan"),parameters.MaskedPan,""));
	details.Insert("cardholderName", "");
	details.Insert("paymentSystem", ?(parameters.Property("CARD_TYPE"),parameters.CARD_TYPE,""));
	details.Insert("bankName", "");
			
	Return HTTP.encodeJSON(details);
	
EndFunction

Function echoRaiffeisenPOST(Request)
	
	body = Request.getBodyAsString();
	if ValueIsFilled(body) then
		answerStruct = HTTP.decodeJSON(body, Enums.JSONValueTypes.structure);
		If answerStruct.Property("qrId") then
			acquiringOrderIdentifier = catalogs.acquiringOrderIdentifiers.FindByDescription(answerStruct.qrId);
			if ValueIsFilled(acquiringOrderIdentifier) then
				Acquiring.executeRequest("check", acquiringOrderIdentifier.Owner);
			EndIf;
		EndIf;
	EndIf;
	Response	= new HTTPServiceResponse(200);
	Response.Headers.Insert("Content-type", "application/json; charset=utf-8");
	Response.SetBodyFromString("ok");	
	return Response;
EndFunction
