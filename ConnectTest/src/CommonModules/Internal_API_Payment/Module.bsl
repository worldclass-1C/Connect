Procedure processOrder(parameters, additionalParameters) Export
	
	query = New Query("SELECT
	|	acquiringOrders.orders.(
	|		uid AS uid) AS orders,
	|	acquiringOrders.payments.(
	|		owner AS owner,
	|		type AS type,
	|		amount AS amount,
	|		details AS details) AS payments,
	|	acquiringOrders.acquiringRequest AS acquiringRequest,
	|	ordersStates.state
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|		LEFT JOIN InformationRegister.ordersStates AS ordersStates
	|		ON ordersStates.order = acquiringOrders.Ref
	|WHERE
	|	acquiringOrders.Ref = &order
	|	AND ordersStates.state in (VALUE(Enum.acquiringOrderStates.success), VALUE(Enum.acquiringOrderStates.rejected))");
	
	query.SetParameter("order", parameters.order);
	
	result = query.Execute();
	
	If Not result.IsEmpty() Then		
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure();
		select = result.Select();
		select.Next();		
		If select.acquiringRequest = Enums.acquiringRequests.register Then			
			requestStruct.Insert("request", ?(select.state = Enums.acquiringOrderStates.success,"payment","cancel"));
			requestStruct.Insert("uid", XMLString(parameters.order));
			requestStruct.Insert("docList", select.orders.Unload().UnloadColumn("uid"));
			paymentList = New Array();
			For Each row In select.payments.Unload() Do
				paymentListStruct = New Structure();
				paymentListStruct.Insert("owner", XMLString(row.owner));
				paymentListStruct.Insert("type", row.type);
				paymentListStruct.Insert("amount", row.amount);
				paymentListStruct.Insert("details", HTTP.decodeJSON(row.details, Enums.JSONValueTypes.structure));
				paymentList.Add(paymentListStruct);
			EndDo;
			requestStruct.Insert("paymentList", paymentList);
			parametersNew.Insert("requestName", "paymentBack");			
		EndIf;
		parametersNew.Insert("requestStruct", requestStruct);
		Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);		
		If parametersNew.errorDescription.result <> "" Then
			Acquiring.addOrderToQueue(parameters.order, select.state);
			parameters.Insert("errorCode", parametersNew.errorDescription.result);
			parameters.Insert("response", parametersNew.errorDescription.description);	
		EndIf;		
	EndIf;	
	
EndProcedure

Procedure bindCard(parameters, additionalParameters) Export
	query = New Query("SELECT
	|	acquiringOrders.creditCard,
	|	acquiringOrders.creditCard.Owner AS userId,
	|	acquiringOrders.creditCard.acquiringBank AS acquiringBank,
	|	acquiringOrders.creditCard.autopayment AS autopayment,
	|	acquiringOrders.creditCard.expiryDate AS expiryDate,
	|	acquiringOrders.creditCard.ownerName AS ownerName,
	|	acquiringOrders.creditCard.paymentSystem AS paymentSystem
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|WHERE
	|	acquiringOrders.Ref = &order");
	query.SetParameter("order", parameters.order);
	
	result = query.Execute();
	If Not result.IsEmpty() Then		
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure();
		select = result.Select();
		select.Next();				
		requestStruct.Insert("uid", 								XMLString(select.creditCard));
		requestStruct.Insert("userId", 							XMLString(select.userId));
	    requestStruct.Insert("acquiringBank", 			select.acquiringBank);
	    requestStruct.Insert("autopayment", 			select.autopayment);
	    requestStruct.Insert("expiryDate", 					select.expiryDate);
	    requestStruct.Insert("ownerName",				select.ownerName);
	    requestStruct.Insert("paymentSystem",		String(select.paymentSystem));
	    
		Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);		
		If parametersNew.errorDescription.result <> "" Then
			Acquiring.addOrderToQueue(parameters.order, Enums.acquiringOrderStates.success);
			parameters.Insert("errorCode", parametersNew.errorDescription.result);
			parameters.Insert("response", parametersNew.errorDescription.description);	
		EndIf;		
	EndIf;	
EndProcedure

Procedure unBindCard(parameters, additionalParameters) Export
		
	If ValueIsFilled(parameters.order.creditCard) Then
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure();
		requestStruct.Insert("uid", XMLString(parameters.order.creditCard));
		Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);		
		If parametersNew.errorDescription.result <> "" Then
			Acquiring.addOrderToQueue(parameters.order, Enums.acquiringOrderStates.success);
			parameters.Insert("errorCode", parametersNew.errorDescription.result);
			parameters.Insert("response", parametersNew.errorDescription.description);	
		EndIf;	
	EndIf;
	
EndProcedure
