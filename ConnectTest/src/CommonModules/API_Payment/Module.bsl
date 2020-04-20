
Procedure bindCardList(parameters) Export
			
	array = New Array();
	query = New Query("SELECT
	|	creditCards.Ref AS creditCard,
	|	creditCards.Description AS name,
	|	PRESENTATION(creditCards.paymentSystem) AS paymentSystem
	|FROM
	|	Catalog.creditCards AS creditCards
	|WHERE
	|	creditCards.Owner = &owner
	|	AND
	|	NOT creditCards.inactive");
	
	query.SetParameter("owner", parameters.tokenContext.user);	
	select = query.Execute().Select();	
	While select.Next() Do
		cardStruct = New Structure();
		cardStruct.Insert("uid", XMLString(select.creditCard));
		cardStruct.Insert("name", select.name);
		cardStruct.Insert("paymentSystem", select.paymentSystem);
		array.Add(cardStruct);
	EndDo;		
	parameters.Insert("answerBody", HTTP.encodeJSON(array));	
			
EndProcedure

Procedure paymentPreparation(parameters) Export
		
	tokenContext = parameters.tokenContext;
	requestStruct	= parameters.requestStruct;
			
	parametersNew = Service.getStructCopy(parameters);
	parametersNew.Insert("requestName", "paymentPreparationBack");		
	General.executeRequestMethod(parametersNew);
	If parametersNew.error = "" Then
		struct = HTTP.decodeJSON(parametersNew.answerBody, Enums.JSONValueTypes.structure);
		orderStruct = New Structure();
		If requestStruct.Property("customerId") And requestStruct.customerId <> "" Then
			orderStruct.Insert("user", XMLValue(Type("CatalogRef.users"), requestStruct.customerId));
		Else	
			orderStruct.Insert("user", tokenContext.user);		
		EndIf;		
		If requestStruct.Property("acquiringRequest") And requestStruct.acquiringRequest <> "" Then
			orderStruct.Insert("acquiringRequest", Enums.acquiringRequests[requestStruct.acquiringRequest]);
		Else
			orderStruct.Insert("acquiringRequest", Enums.acquiringRequests.register);
		EndIf;
		orderStruct.Insert("holding", tokenContext.holding);
		orderStruct.Insert("amount", struct.paymentAmount);
		orderStruct.Insert("acquiringAmount", struct.paymentAmount);
		orderStruct.Insert("orders", struct.docList);
		orderStruct.Insert("paymentOptions", struct.paymentOptions);
		order = Acquiring.newOrder(orderStruct);
		//@skip-warning
		struct.Insert("uid", XMLString(order));		
		//@skip-warning
		struct.Delete("docList");
		Acquiring.creditCardsPreparation(struct.paymentOptions, parameters,order);
	Else
		struct = New Structure();				
	EndIf;
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
	parameters.Insert("error", parametersNew.error);
		
EndProcedure

Procedure payment(parameters) Export

	requestStruct = parameters.requestStruct;	
	error = "";
	struct = New Structure();

	query = New Query("SELECT
		|	acquiringOrders.Ref AS order,
		|	acquiringOrders.amount
		|FROM
		|	Catalog.acquiringOrders AS acquiringOrders
		|WHERE
		|	acquiringOrders.Ref = &order
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	acquiringOrderscards.card
		|FROM
		|	Catalog.acquiringOrders.cards AS acquiringOrderscards
		|WHERE
		|	acquiringOrderscards.Ref = &order
		|	AND acquiringOrderscards.card = &card
		|	AND &cardIsFilled
		|	AND
		|	NOT acquiringOrderscards.card.inactive
		|
		|UNION ALL
		|
		|SELECT
		|	&card
		|WHERE
		|	NOT &cardIsFilled");

	order = XMLValue(Type("catalogRef.acquiringOrders"), requestStruct.uid);
	card = Catalogs.creditCards.EmptyRef();
	isApplePay = false;
	isGooglePay = false;
	If requestStruct.Property("card") and not requestStruct.card = Undefined Then
		If requestStruct.card = "applePay" Then
			isApplePay = true;
		ElsIf requestStruct.card = "googlePay" Then
			isGooglePay = true;
		ElsIf requestStruct.card <> "bankCard" Then
			card = XMLValue(Type("CatalogRef.creditCards"), requestStruct.card);
		EndIf;
	EndIf;
	owner = ?(requestStruct.Property("owner") and not requestStruct.owner = Undefined, XMLValue(Type("CatalogRef.users"), requestStruct.owner), Catalogs.users.EmptyRef());
	query.SetParameter("order", order);
	query.SetParameter("card", card);
	query.SetParameter("cardIsFilled", ValueIsFilled(card));

	results = query.ExecuteBatch();

	orderObject = Undefined;
	orderResult = results[0];

	If orderResult.IsEmpty() Then
		error = "acquiringOrderFind";
	ElsIf owner.IsEmpty() Then
		error = "userNotfound";
	EndIf;
	
	orderObject = order.GetObject();
	
	If isApplePay or isGooglePay  Then
		If parameters.Property("tokenContext") And parameters.tokenContext.Property("systemType") Then
				SystemType = parameters.tokenContext.systemType;
		EndIf;
	EndIf;
	
	//Проверяем есть ли указанная карта, в списке доступных карт
	If error = "" Then
		If results[1].IsEmpty() Then
			error = "acquiringCard";
		ElsIf ValueIsFilled(card) Then
			orderObject.creditCard = card;
		ElsIf isApplePay Then 
			If SystemType = Enums.systemTypes.iOS Then
				orderObject.acquiringRequest = enums.acquiringRequests.applePay;
			Else
				error = "acquiringCard";
			EndIf;
		ElsIf isGooglePay Then
			 If SystemType = Enums.systemTypes.Android Then
			 	orderObject.acquiringRequest = enums.acquiringRequests.googlePay;
			 Else
			 	error = "acquiringCard";
			 EndIf;
		EndIf;
	EndIf;

	//Проверяем есть ли оплата авансами
	If error = "" Then
		If requestStruct.Property("deposits") and not requestStruct.deposits = Undefined Then
			For Each deposit In requestStruct.deposits Do
				newRow = orderObject.payments.Add();
				newRow.owner = owner;
				newRow.type = deposit.type;
				newRow.amount = deposit.paymentAmount;			
				newRow.details = HTTP.encodeJSON(deposit);	
			EndDo;
		EndIf;
		If orderObject <> Undefined Then
			orderObject.Write();
		EndIf;
		answer = Acquiring.executeRequest("process", order, parameters);
		If not answer.errorCode = "" Then 
			error = answer.errorCode;
			orderObject.payments.Clear();				
		EndIf;
	EndIf;
	
	//Отправляем в запрос в банк на оставшуюся сумму
	If error = "" Then
		If orderObject <> Undefined Then
			orderObject.Write();
		EndIf;
		struct.Insert("uid", XMLString(order));
		aquiringAmount = order.acquiringAmount - order.payments.Total("amount");
		If aquiringAmount = 0 
		    Or isApplePay 
		    Or isGooglePay Then
			struct.Insert("amount", aquiringAmount);
			Acquiring.changeOrderState(order, Enums.acquiringOrderStates.send);
		Else 
			answer = Acquiring.executeRequest("send", order);
			If answer.errorCode = "" Then
				struct.Insert("orderId", answer.orderId);
				struct.Insert("formUrl", answer.formUrl);
				struct.Insert("returnUrl", answer.returnUrl);
				struct.Insert("failUrl", answer.failUrl);
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);	
			Else
				error = answer.errorCode;
			EndIf;	
		EndIf;
	EndIf;

    If error <> "" Then
    	Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.rejected);
    EndIf;
     
//	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("error", error);
	
EndProcedure

Procedure paymentStatus(parameters) Export
	
	requestStruct = parameters.requestStruct;	
	struct = New Structure();
	query = New Query("SELECT
	|	acquiringOrders.Ref AS order,
	|	acquiringOrders.acquiringRequest,
	|	ISNULL(ordersStates.state, VALUE(enum.acquiringOrderStates.EmptyRef)) AS state,
	|	ISNULL(acquiringOrderIdentifiers.Presentation, """") AS orderId
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|		LEFT JOIN InformationRegister.ordersStates AS ordersStates
	|		ON acquiringOrders.Ref = ordersStates.order
	|		LEFT JOIN Catalog.acquiringOrderIdentifiers AS acquiringOrderIdentifiers
	|		ON acquiringOrders.Ref = acquiringOrderIdentifiers.Owner
	|WHERE
	|	acquiringOrders.Ref = &order");

	order = XMLValue(Type("catalogRef.acquiringOrders"), requestStruct.uid);
	query.SetParameter("order", order);
	result = query.Execute();
	struct.Insert("result", "fail");
	If result.IsEmpty() Then
		parameters.Insert("error", "acquiringConnection");
	Else
		selection = result.Select();
	    selection.Next();
		If selection.state = Enums.acquiringOrderStates.send Then
			response = Acquiring.executeRequest("check", order, requestStruct);
			If response = Undefined Then
				parameters.Insert("error", "acquiringOrderCheck");
			Else				
				//parameters.Insert("error", response.errorCode);
				If response.errorCode = "" Then
					struct.Insert("result", "ok");
					Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.success);
					If order.acquiringRequest = Enums.acquiringRequests.unbinding then
						answerKPO = Acquiring.executeRequest("unBindCardBack", order, parameters);
					ElsIf order.acquiringRequest = Enums.acquiringRequests.binding Then 
						answerKPO = Acquiring.executeRequest("bindCardBack", order, parameters);					
					else
						answerKPO = Acquiring.executeRequest("process", order, parameters);
					EndIf;
					If answerKPO = Undefined or not answerKPO.errorCode = "" Then						
						parameters.Insert("error", "system");					
					EndIf;
				EndIf;
			EndIf;
		ElsIf selection.state = Enums.acquiringOrderStates.rejected Then		
			//parameters.Insert("error", "acquiringOrderRejected");			
		ElsIf selection.state = Enums.acquiringOrderStates.EmptyRef() Then
			parameters.Insert("error", "acquiringOrderFind");
		Else
			struct.Insert("result", "ok");
		EndIf;
	EndIf;
	If struct.result = "fail" Then
		If response.errorCode = "send"  Then
			Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);
		else
			Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.rejected);
		EndIf;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
				
EndProcedure

Procedure bindCard(parameters) Export
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;	
	struct = New Structure();
	struct.Insert("result", "ok");
	
	orderStruct = New Structure();
	orderStruct.Insert("acquiringAmount", 1);
	orderStruct.Insert("user", tokenContext.user);
	orderStruct.Insert("holding", tokenContext.holding);	
	orderStruct.Insert("acquiringRequest", Enums.acquiringRequests.binding);	
	orderStruct.Insert("acquiringProvider", ?(requestStruct.Property("acquiringProvider"), Enums.acquiringProviders[requestStruct.acquiringProvider], Enums.acquiringProviders.EmptyRef()));
	order = Acquiring.newOrder(orderStruct);
	answer = Acquiring.executeRequest("send", order);	
	If answer.errorCode = "" Then		
		struct.Insert("uid", XMLString(order));
		struct.Insert("formUrl", answer.formUrl);
		struct.Insert("returnUrl", answer.returnUrl);
		struct.Insert("failUrl", answer.failUrl);	
		Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);				
	EndIf;	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("error", answer.errorCode);
			
EndProcedure

Procedure unBindCard(parameters) Export
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;	
	struct = New Structure();
	struct.Insert("result", "ok");
	
	query = New Query("SELECT
	|	creditCards.Ref AS creditCard,
	|	NOT creditCards.inactive AS active
	|FROM
	|	Catalog.creditCards AS creditCards
	|WHERE
	|	creditCards.Ref = &creditCard
	|	AND creditCards.Owner = &owner");
	
	query.SetParameter("creditCard", XMLValue(Type("CatalogRef.creditCards"), requestStruct.uid));
	query.SetParameter("owner", tokenContext.user);
	
	result = query.Execute();
	
	If result.IsEmpty() Then		
		parameters.Insert("error", "acquiringCreditCard");
	Else
		select = result.Select();
		select.Next();
		If select.active Then
			orderStruct = New Structure();
			orderStruct.Insert("user", tokenContext.user);
			orderStruct.Insert("holding", tokenContext.holding);			
			orderStruct.Insert("creditCard", select.creditCard);
			orderStruct.Insert("acquiringRequest", Enums.acquiringRequests.unbinding);
			orderStruct.Insert("acquiringProvider", ?(requestStruct.Property("acquiringProvider"), Enums.acquiringProviders[requestStruct.acquiringProvider], Enums.acquiringProviders.EmptyRef()));
			order = Acquiring.newOrder(orderStruct);
			answer = Acquiring.executeRequest("unBindCard", order);
			If answer.errorCode = "" Then		
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.success);				
			EndIf;			
			parameters.Insert("error", answer.errorCode);
		EndIf;
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
			
EndProcedure
