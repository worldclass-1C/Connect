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
					  |	isnull(ordersStates.state, value(Enum.acquiringOrderStates.emptyRef)) AS state,
					  |	acquiringOrders.registrationDate
					  |FROM
					  |	Catalog.acquiringOrders AS acquiringOrders
					  |		LEFT JOIN InformationRegister.ordersStates AS ordersStates
					  |		ON ordersStates.order = acquiringOrders.Ref
					  |WHERE
					  |	acquiringOrders.Ref = &order
					  |	AND ISNULL(ordersStates.state, VALUE(Enum.acquiringOrderStates.emptyRef)) IN
					  |	(VALUE(Enum.acquiringOrderStates.success), VALUE(Enum.acquiringOrderStates.rejected),
					  |		VALUE(Enum.acquiringOrderStates.emptyRef))");

	query.SetParameter("order", parameters.order);

	result = query.Execute();

	If Not result.IsEmpty() Then
		Acquiring.changeOrderState(parameters.order, Enums.acquiringOrderStates.done);
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure;
		select = result.Select();
		select.Next();
		If select.acquiringRequest = Enums.acquiringRequests.register Or select.acquiringRequest
			= Enums.acquiringRequests.applePay Or select.acquiringRequest = Enums.acquiringRequests.googlePay
			Or select.acquiringRequest = Enums.acquiringRequests.qrRegister Then
			requestStruct.Insert("request", ?(select.state = Enums.acquiringOrderStates.success, "payment", ?(
				select.state = Enums.acquiringOrderStates.rejected, "cancel", ?(select.state.isEmpty()
				And select.registrationDate < (ToUniversalTime(CurrentDate()) - 20 * 60), "cancel", "reserve"))));
			requestStruct.Insert("uid", XMLString(parameters.order));
			requestStruct.Insert("docList", select.orders.Unload().UnloadColumn("uid"));
			paymentList = New Array;
			For Each row In select.payments.Unload() Do
				paymentListStruct = New Structure;
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
		parametersNew.Insert("internalRequestMethod", True);
		//Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);
		//Service.logRequestBackground(parametersNew);
		
		If parametersNew.error <> "" Then
				//Acquiring.addOrderToQueue(parameters.order, select.state);
				parameters.Insert("errorCode", parametersNew.error);
				Texts = String(parametersNew.requestName) + chars.LF + parametersNew.requestBody + chars.LF
					+ parametersNew.statusCode + chars.LF + parametersNew.answerBody;
				parameters.Insert("response", Service.getErrorDescription(additionalParameters.language,
					parametersNew.error, , Texts));
				Acquiring.changeOrderState(parameters.order, select.state);
		EndIf;
		If select.state.isEmpty() And select.registrationDate < (ToUniversalTime(CurrentDate()) - 20 * 60) Then
			Acquiring.changeOrderState(parameters.order, Enums.acquiringOrderStates.rejected);
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
	|	acquiringOrders.creditCard.paymentSystem AS paymentSystem,
	|	acquiringOrders.creditCard.Description AS Description,
	|	acquiringOrders.contract
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|WHERE
	|	acquiringOrders.Ref = &order");
	query.SetParameter("order", parameters.order);

	result = query.Execute();
	If Not result.IsEmpty() Then
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure;
		select = result.Select();
		select.Next();
		requestStruct.Insert("uid", XMLString(select.creditCard));
		requestStruct.Insert("owner", XMLString(select.userId));
		requestStruct.Insert("acquiringBank", select.acquiringBank);
		requestStruct.Insert("description", select.Description);
		requestStruct.Insert("autopayment", select.autopayment);
		requestStruct.Insert("expiryDate", select.expiryDate); 
		requestStruct.Insert("ownerName", select.ownerName);
		requestStruct.Insert("paymentSystem", String(select.paymentSystem));
		if ValueIsFilled(select.contract) then
			requestStruct.Insert("contract", select.contract);
		EndIf;
		
		parametersNew.Insert("internalRequestMethod", True);
		parametersNew.Insert("requestName", "paymentBindCardBack");
		parametersNew.Insert("requestStruct", requestStruct);
		Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);
		Service.logRequestBackground(parametersNew);
		If parametersNew.error <> "" Then
			Acquiring.addOrderToQueue(parameters.order, Enums.acquiringOrderStates.success);
			parameters.Insert("errorCode", parametersNew.error);
			Texts = String(parametersNew.requestName) + chars.LF + parametersNew.requestBody + chars.LF
				+ parametersNew.statusCode + chars.LF + parametersNew.answerBody;
			parameters.Insert("response", Service.getErrorDescription(additionalParameters.language,
				parametersNew.error, , Texts));
		EndIf;
	EndIf;
EndProcedure

Procedure unBindCard(parameters, additionalParameters) Export

	If ValueIsFilled(parameters.order.creditCard) Then
		parametersNew = Service.getStructCopy(additionalParameters);
		requestStruct = New Structure;
		requestStruct.Insert("uid", XMLString(parameters.order.creditCard));
		parametersNew.Insert("requestName", "paymentUnBindCardBack");
		parametersNew.Insert("requestStruct", requestStruct);
		parametersNew.Insert("internalRequestMethod", True);
		Acquiring.delOrderToQueue(parameters.order);
		General.executeRequestMethod(parametersNew);
		Service.logRequestBackground(parametersNew);
		If parametersNew.error <> "" Then
			Acquiring.addOrderToQueue(parameters.order, Enums.acquiringOrderStates.success);
			parameters.Insert("errorCode", parametersNew.error);
			Texts = String(parametersNew.requestName) + chars.LF + parametersNew.requestBody + chars.LF
				+ parametersNew.statusCode + chars.LF + parametersNew.answerBody;
			parameters.Insert("response", Service.getErrorDescription(additionalParameters.language,
				parametersNew.error, , Texts));
		EndIf;
	EndIf;

EndProcedure

