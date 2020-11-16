
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
	Service.logRequestBackground(parametersNew);
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
		orderStruct.Insert("gymId", struct.gymId);
		orderStruct.Insert("paymentOptions", struct.paymentOptions);
		orderStruct.Insert("autoPayment", ?(struct.Property("autoPayment"),struct.autoPayment, False));
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
	|	InformationRegister.ordersStates AS ordersStates
	|		RIGHT JOIN Catalog.acquiringOrders AS acquiringOrders
	|		ON ordersStates.order = acquiringOrders.Ref
	|WHERE
	|	acquiringOrders.Ref = &order
	|	AND ISNULL(ordersStates.state, VALUE(enum.acquiringOrderStates.send)) = VALUE(enum.acquiringOrderStates.send)
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
	|	NOT &cardIsFilled
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	acquiringOrdersdeposits.owner,
	|	acquiringOrdersdeposits.type,
	|	acquiringOrdersdeposits.min,
	|	acquiringOrdersdeposits.max
	|FROM
	|	Catalog.acquiringOrders.deposits AS acquiringOrdersdeposits
	|WHERE
	|	acquiringOrdersdeposits.Ref = &order");

	order = XMLValue(Type("catalogRef.acquiringOrders"), requestStruct.uid);
	card = Catalogs.creditCards.EmptyRef();
	isApplePay = false;
	isGooglePay = false;
	isQr = false;
	If requestStruct.Property("card") and not requestStruct.card = Undefined Then
		If requestStruct.card = "applePay" Then
			isApplePay = true;
		ElsIf requestStruct.card = "googlePay" Then
			isGooglePay = true;
		ElsIf requestStruct.card = "qr" Then 
			isQr = true;
		ElsIf requestStruct.card <> "bankCard" Then
			card = XMLValue(Type("CatalogRef.creditCards"), requestStruct.card);
		EndIf;
	EndIf;
	owner = ?(requestStruct.Property("owner") and not requestStruct.owner = Undefined, XMLValue(Type("CatalogRef.users"), requestStruct.owner), ?(valueIsFilled(order),order.user,catalogs.users.EmptyRef()));
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
		ElsIf isQr Then
			 orderObject.acquiringRequest = enums.acquiringRequests.qrRegister; 
		EndIf;
	EndIf;

	//Проверяем есть ли оплата авансами
	If error = "" Then
		If requestStruct.Property("deposits") And Service.isArray(requestStruct.deposits)
			And requestStruct.deposits.Count() > 0 And orderObject <> Undefined Then
			orderObject.payments.Clear();
			limits = results[2].Unload();
			For Each deposit In requestStruct.deposits Do
				limit = limits.FindRows(New Structure("type, owner", deposit.type, owner));
				If limit.Count() > 0 then
					If Round(deposit.paymentAmount,2) > limit[0].min and Round(deposit.paymentAmount,2) <= limit[0].max then
						newRow = orderObject.payments.Add();
						newRow.owner = owner;
						newRow.type = deposit.type;
						newRow.amount = Round(deposit.paymentAmount,2);
						newRow.details = HTTP.encodeJSON(deposit);
					Else
						error = "deposits";
					EndIf;
				Else
					error = "deposits";
				EndIf;
			EndDo;			
			orderObject.Write();						
		EndIf;
		If error = "" Then
			answer = Acquiring.executeRequest("process", order, parameters);
			error = answer.errorCode;
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
			Acquiring.changeOrderState(order, ?(aquiringAmount = 0, Enums.acquiringOrderStates.success, Enums.acquiringOrderStates.send));
			if aquiringAmount = 0 then
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.success); 
			Else
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send); 
			endif;
		Else
			 if isQr Then
			 	answer = Acquiring.executeRequest("getQr", order, parameters);
			 else
			 	answer = Acquiring.executeRequest("send", order);
			 EndIf;
			 
			If answer.errorCode = "" Then
				struct.Insert("orderId", 	answer.orderId);
				struct.Insert("formUrl", 	answer.formUrl);
				struct.Insert("returnUrl", 	answer.returnUrl);
				struct.Insert("failUrl", 	answer.failUrl);
				Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);	
			Else
				error = answer.errorCode;
			EndIf;	
		EndIf;
	EndIf;

    If not orderResult.IsEmpty() and error <> "" Then
   		Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);
    EndIf;
     
//	struct.Insert("result", "Ok");
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("error", error);
	
EndProcedure

Procedure paymentStatus(parameters) Export
	
	requestStruct = parameters.requestStruct;	
	struct = New Structure();
	order 		= XMLValue(Type("catalogRef.acquiringOrders"), 				requestStruct.uid);
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.acquiringOrdersQueue");
	DataLockItem.SetValue("order", order);
	DataLockItem = DataLock.Add("Catalog.acquiringOrders");
	DataLockItem.SetValue("ref", order);
	DataLockItem = DataLock.Add("InformationRegister.ordersStates");
	DataLockItem.SetValue("order", order);
	BeginTransaction();
	DataLock.Lock();
	try
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
					If answerKPO.errorCode = "" Then
						Acquiring.delOrderToQueue(order);
					EndIf;
					//If answerKPO = Undefined or not answerKPO.errorCode = "" Then						
					//	parameters.Insert("error", "system");					
					//EndIf;
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
		If ValueIsFilled(response) and response.errorCode = "send"  Then
			Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.send);
		else
			Acquiring.addOrderToQueue(order, Enums.acquiringOrderStates.rejected);
		EndIf;
	EndIf;
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
					
EndProcedure

Procedure bindCard(parameters) Export
	
	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;	
	struct = New Structure();
	struct.Insert("result", "ok");
	customer = Catalogs.users.EmptyRef();
	if not ValueIsFilled(tokenContext.user) and requestStruct.Property("customerId") then
		customer = XMLValue(Type("CatalogRef.users"), requestStruct.customerId);
	EndIf;	
	orderStruct = New Structure();
	orderStruct.Insert("acquiringAmount", 1);
	orderStruct.Insert("user", ?(requestStruct.Property("customerId"), customer, tokenContext.user));
	orderStruct.Insert("holding", tokenContext.holding);	
	orderStruct.Insert("acquiringRequest", Enums.acquiringRequests.binding);	
	orderStruct.Insert("acquiringProvider", ?(requestStruct.Property("acquiringProvider"), Enums.acquiringProviders[requestStruct.acquiringProvider], Enums.acquiringProviders.EmptyRef()));
	orderStruct.Insert("contract", ?(requestStruct.Property("contract"), requestStruct.contract, ""));
	order = Acquiring.newOrder(orderStruct);
	answer = Acquiring.executeRequest("send", order);	
	If answer.errorCode = "" Then		
		struct.Insert("uid", XMLString(order));
		struct.Insert("orderId", XMLString(order));
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
	if requestStruct.Property("owner") and ValueIsFilled(requestStruct.owner) then
		owner = XMLValue(Type("CatalogRef.users"), requestStruct.owner);
	else
		owner = tokenContext.user;
	endif;
	query = New Query("SELECT
	|	creditCards.Ref AS creditCard,
	|	NOT creditCards.inactive AS active
	|FROM
	|	Catalog.creditCards AS creditCards
	|WHERE
	|	creditCards.Ref = &creditCard
	|	AND creditCards.Owner = &owner");
	
	query.SetParameter("creditCard", XMLValue(Type("CatalogRef.creditCards"), requestStruct.uid));
	query.SetParameter("owner", owner);
	
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

Procedure autoPayment(parameters) Export
	//создать ордер
	orderStruct = New Structure();
	customerCode = "";
	parameters.requestStruct.Property("customerCode", customerCode);

	If parameters.requestStruct.Property("customerId") And parameters.requestStruct.customerId <> "" Then
		orderStruct.Insert("user", XMLValue(Type("CatalogRef.users"), parameters.requestStruct.customerId));
	Else	
		orderStruct.Insert("user", parameters.tokenContext.user);		
	EndIf;
	requestStruct = parameters.requestStruct;
	orderStruct.Insert("acquiringRequest", 	Enums.acquiringRequests.autoPayment);
	orderStruct.Insert("holding", 			parameters.tokenContext.holding);
	orderStruct.Insert("amount", 			requestStruct.amount);
	orderStruct.Insert("acquiringAmount", 	requestStruct.amount);
	orderStruct.Insert("orders", 			requestStruct.docList);
	orderStruct.Insert("gymId", 			requestStruct.gymId);
	orderStruct.Insert("creditCard", 		XMLValue(Type("CatalogRef.creditCards"),requestStruct.card));
	order = Acquiring.newOrder(orderStruct);
	//отправить его send
	answer = Acquiring.executeRequest("send", order);
	If answer.errorCode <> "" and ValueIsFilled(customerCode) Then
		parameters.Insert("customerCode", customerCode);
		answer = Acquiring.executeRequest("send", order, parameters);
	EndIf;
	
	answerKPO = New Structure();
	result = "error";
	If answer.errorCode = "" Then
	//провести автоплатеж autoPayment
		answerPayment = Acquiring.executeRequest("autoPayment", order,parameters);
		If answerPayment.errorCode = "" Then
			//проверить статус оплаты
			answerCheck = Acquiring.executeRequest("check", order);
			If answerCheck.errorCode = "" Then
				result = "ok";
				answerKPO.Insert("details", HTTP.decodeJSON(order.payments[0].details, Enums.JSONValueTypes.structure));
				answerKPO.details.Insert("uid", XMLString(order));
			EndIf;			
		EndIf;
	EndIf;
	//Вернуть ответ
	answerKPO.Insert("result", 		result);
	parameters.Insert("answerBody", HTTP.encodeJSON(answerKPO));
EndProcedure

Procedure changeCardAutoPayment(parameters) Export
	
	requestStruct = parameters.requestStruct;
	struct = New Structure();
	struct.Insert("result", "fail");
	If requestStruct.Property("uid") Then
		creditCard = XMLValue(Type("CatalogRef.creditCards"),requestStruct.uid);
		if requestStruct.Property("autoPayment") then
			creditCardObject = creditCard.GetObject();
			creditCardObject.autopayment = requestStruct.autoPayment;
			creditCardObject.write();
			parametersNew = Service.getStructCopy(parameters);
			parametersNew.requestName = "changeBankCard";
			General.executeRequestMethod(parametersNew);
			If parametersNew.error = "" Then
				struct.Insert("result", "ok");
			EndIf;
		EndIf;	
	EndIf;
	
EndProcedure