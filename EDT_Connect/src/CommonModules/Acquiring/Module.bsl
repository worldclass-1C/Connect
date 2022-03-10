
Function newOrder(parameters) Export
	orderObject = Catalogs.acquiringOrders.CreateItem();	
	FillPropertyValues(orderObject, parameters);
	If parameters.Property("orders") Then
		For Each element In parameters.orders Do
			newRow = orderObject.orders.Add();
			newRow.uid = element.docId;
			newRow.amount = element.amount;
		EndDo;
	EndIf;
	If parameters.Property("paymentOptions") Then
		For Each paymentOption In parameters.paymentOptions Do
			If paymentOption.Property("owner") Then
				owner = XMLValue(Type("CatalogRef.users"), paymentOption.owner.uid);
			Else
				owner = Catalogs.users.EmptyRef();
			EndIf;
			If paymentOption.Property("cards") Then
				For Each element In paymentOption.cards Do					
					If element.uid <> "" Then
						cardRef = XMLValue(Type("CatalogRef.creditCards"), element.uid);
						If Not cardRef.IsEmpty() Then
							//@skip-warning
							newRow = orderObject.cards.Add();
							newRow.card = cardRef;
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			If paymentOption.Property("deposits") Then
				For Each element In paymentOption.deposits Do
					//@skip-warning
					newRow = orderObject.deposits.Add();
					newRow.owner = owner;
					newRow.type = element.type;
					newRow.balance = element.balance;
					newRow.min = element.min;
					newRow.max = element.max;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	If parameters.Property("gymId") Then
		orderObject.gym = XMLValue(Type("CatalogRef.gyms"), parameters.gymId);		
	EndIf;
	
	If ValueIsFilled(orderObject.gym) then
		orderObject.chain = orderObject.gym.chain;
	EndIf;
	
	orderObject.registrationDate = ToUniversalTime(CurrentDate());
	orderObject.Write();
	Service.logAcquiringBackground(New Structure("order, requestName", orderObject.ref, "write"));
	Return orderObject.ref;
EndFunction

Function orderIdentifier(order, orderNumber = Undefined, orderUid = Undefined, sessionID = Undefined) Export	
	orderIdentifier = Catalogs.acquiringOrderIdentifiers.CreateItem();
	If ValueIsFilled(orderUid) Then
		orderIdentifierRef = Catalogs.acquiringOrderIdentifiers.GetRef(New UUID(orderUid));
		orderIdentifier.SetNewObjectRef(orderIdentifierRef);
	EndIf;
	If ValueIsFilled(orderNumber) Then
		orderIdentifier.Description = orderNumber;
	EndIf;
	If ValueIsFilled(sessionID) Then
		orderIdentifier.sessionId = sessionID;
	EndIf;
	
	orderIdentifier.Owner = order;
	orderIdentifier.Write();
	Return orderIdentifier.Ref;	
EndFunction

Function findOrder(orderId) Export
	
	query = New Query("SELECT
	|	acquiringOrderIdentifiers.Owner AS order,
	|	ISNULL(ordersStates.state, VALUE(Enum.acquiringOrderStates.EmptyRef)) AS state
	|FROM
	|	Catalog.acquiringOrderIdentifiers AS acquiringOrderIdentifiers
	|		LEFT JOIN InformationRegister.ordersStates AS ordersStates
	|		ON acquiringOrderIdentifiers.Owner = ordersStates.order
	|WHERE
	|	acquiringOrderIdentifiers.Ref = &orderIdentifier");
	
	query.SetParameter("orderIdentifier", Catalogs.acquiringOrderIdentifiers.GetRef(New UUID(orderId)));
	
	result = query.Execute();
	If result.IsEmpty() Then
		Return Undefined;
	Else
		select = result.Select();
		select.Next();
		Return New Structure("order, state", select.order, select.state);
	EndIf;
	
EndFunction

Function paymentSystem(val code) Export
	If code = "51" Or code = "52" Or code = "53" Or code = "54"  Or code = "55" Then
		Return Enums.paymentSystem.masterCard;
	ElsIf code = "50" Or code = "56" Or code = "57" Or code = "58" Or code = "63" Or code = "67" Then
		Return Enums.paymentSystem.maestro;
	ElsIf code = "30" Or code = "36" Or code = "38" Then
		Return Enums.paymentSystem.dinersClub;
	ElsIf code = "31" Or code = "35" Then
		Return Enums.paymentSystem.jcb;
	ElsIf code = "34" Or code = "37" Then
		Return Enums.paymentSystem.americanExpress;
	ElsIf code = "60" Then
		Return Enums.paymentSystem.discover;
	ElsIf code = "62" Then
		Return Enums.paymentSystem.chinaUnionPay;							
	Else
		code = Left(code, 1);	
		If code = "4" Then
			Return Enums.paymentSystem.visa;
		ElsIf code = "2" Then
			Return Enums.paymentSystem.mir;
		ElsIf code = "7" Then
			Return Enums.paymentSystem.universalElectronicCard;	
		Else
			Enums.paymentSystem.EmptyRef();
		EndIf;
	EndIf;
EndFunction

Function executeRequest(requestName, order, additionalParameters = Undefined) Export
	parameters = paymentParameters(order, additionalParameters);
	parameters.Insert("requestName", requestName);	
	If parameters.errorCode = "" Then
		If requestName = "send" Then
			sendOrder(parameters);
		ElsIf requestName = "check" Then
			checkOrder(parameters);
		ElsIf requestName = "unBindCard" Then
			unBindCard(parameters);
		ElsIf requestName = "reverse" Then
			reverseOrder(parameters);
		ElsIf requestName = "process" Then
			Internal_API_Payment.processOrder(parameters, additionalParameters);	
		ElsIf requestName = "bindCardBack" Then
			Internal_API_Payment.bindCard(parameters, additionalParameters);	
		ElsIf requestName = "unBindCardBack" Then
			Internal_API_Payment.unBindCard(parameters, additionalParameters);
		ElsIf requestName = "getQr" Then
			getQr(parameters, additionalParameters);	
		ElsIf  requestName = "autoPayment" Then 
			autoPayment(parameters);	
		EndIf;
	EndIf;
	Service.logAcquiringBackground(parameters);
	Return parameters;
EndFunction

Function newCard(parameters)
	If parameters.bindingId = "" Then
		Return Catalogs.creditCards.EmptyRef();
	Else
		creditCardRef = Catalogs.creditCards.GetRef(New UUID(parameters.bindingId));
		creditCard = Catalogs.creditCards.CreateItem();
		creditCard.SetNewObjectRef(creditCardRef);
		creditCard.Owner = Catalogs.users.GetRef(New UUID(parameters.userId));
		creditCard.acquiringBank = parameters.acquiringBank;		
		creditCard.autopayment = parameters.autopayment;
		creditCard.expiryDate = parameters.expiryDate;
		creditCard.ownerName = parameters.ownerName;
		creditCard.Description = parameters.description;
		creditCard.paymentSystem = Acquiring.paymentSystem(parameters.paymentSystemCode);
		creditCard.registrationDate = ToUniversalTime(CurrentDate());
		creditCard.Write();
		Return creditCard.Ref;
	EndIf;
EndFunction

Function paymentParameters(order, parameters)
	
	answer = answerStruct();
	queryConnection = New query;
	queryConnection.Text = ConnectionQueryText();
	queryConnection.SetParameter("order", order);
	result = queryConnection.Execute();
	If result.IsEmpty() Then
		answer.Insert("errorCode", "acquiringConnectionSetup");
	Else	
		select = result.Select();
		select.Next();
		If select.server = "" Then
			answer.Insert("errorCode", "acquiringConnectionSetup");
		Else	
			FillPropertyValues(answer, select);
		EndIf;	 
	EndIf;
	if ValueIsFilled(parameters) Then
		If parameters.Property("customerCode") then
			answer.Insert("customerCode", parameters.customerCode);
		EndIf;
		If parameters.Property("paymentData") then
			answer.Insert("paymentData", parameters.paymentData);
		EndIf;
		If parameters.Property("ipAddress") then
			answer.Insert("ipAddress", parameters.ipAddress);
		EndIf;
				
		If parameters.Property("tokenContext") Then 
			answer.Insert("timeZone", parameters.tokenContext.timeZone);
			If parameters.tokenContext.Property("systemType") Then
				answer.Insert("systemType", parameters.tokenContext.systemType);
			EndIf;
		EndIf;
	EndIf;
	Return answer;		
EndFunction

Function ConnectionQueryText()
	text = "SELECT
	|	SUM(acquiringOrderspayments.amount) AS amount
	|INTO TemporaryDepositAmount
	|FROM
	|	Catalog.acquiringOrders.payments AS acquiringOrderspayments
	|WHERE
	|	acquiringOrderspayments.Ref = &order
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection
	|		WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|			THEN chainAcquiringProviderConnection.connection
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection
	|		WHEN NOT chainConnection.connection IS NULL
	|			THEN chainConnection.connection
	|		ELSE holdingConnection.connection
	|	END AS paymentConnection,
	|	acquiringOrders.Ref AS order,
	|	MAX(acquiringOrderIdentifiers.Ref) AS orderIdentifier
	|INTO Connection
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|		LEFT JOIN Catalog.acquiringOrderIdentifiers AS acquiringOrderIdentifiers
	|		ON (acquiringOrderIdentifiers.Owner = acquiringOrders.Ref)
	|		AND (acquiringOrderIdentifiers.Description <> """")
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymAcquiringProviderConnection
	|		ON acquiringOrders.holding = gymAcquiringProviderConnection.holding
	|		AND acquiringOrders.gym = gymAcquiringProviderConnection.gym
	|		AND acquiringOrders.acquiringProvider = gymAcquiringProviderConnection.acquiringProvider
	|		AND acquiringOrders.connectionType = gymAcquiringProviderConnection.connectionType
	|		AND acquiringOrders.chain = gymAcquiringProviderConnection.chain
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS AcquiringProviderConnection
	|		ON acquiringOrders.holding = AcquiringProviderConnection.holding
	|		AND acquiringOrders.acquiringProvider = AcquiringProviderConnection.acquiringProvider
	|		AND AcquiringProviderConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND AcquiringProviderConnection.chain = VALUE(catalog.chains.emptyref)
	|		AND acquiringOrders.connectionType = AcquiringProviderConnection.connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymConnection
	|		ON acquiringOrders.holding = gymConnection.holding
	|		AND acquiringOrders.gym = gymConnection.gym
	|		AND acquiringOrders.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND acquiringOrders.connectionType = gymConnection.connectionType
	|		AND acquiringOrders.chain = gymConnection.chain
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS holdingConnection
	|		ON acquiringOrders.holding = holdingConnection.holding
	|		AND holdingConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND holdingConnection.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND holdingConnection.chain = VALUE(catalog.chains.emptyref)
	|		AND acquiringOrders.connectionType = holdingConnection.connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainConnection
	|		ON acquiringOrders.holding = chainConnection.holding
	|		AND acquiringOrders.chain = chainConnection.chain
	|		AND chainConnection.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND chainConnection.gym = VALUE(Catalog.gyms.emptyRef)
	|		AND acquiringOrders.connectionType = chainConnection.connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainAcquiringProviderConnection
	|		ON acquiringOrders.holding = chainAcquiringProviderConnection.holding
	|		AND acquiringOrders.chain = chainAcquiringProviderConnection.chain
	|		AND acquiringOrders.acquiringProvider = chainAcquiringProviderConnection.acquiringProvider
	|		AND chainAcquiringProviderConnection.gym = VALUE(Catalog.gyms.emptyRef)
	|		AND acquiringOrders.connectionType = chainAcquiringProviderConnection.connectionType
	|WHERE
	|	acquiringOrders.Ref = &order
	|GROUP BY
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection
	|		WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|			THEN chainAcquiringProviderConnection.connection
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection
	|		WHEN NOT chainConnection.connection IS NULL
	|			THEN chainConnection.connection
	|		ELSE holdingConnection.connection
	|	END,
	|	acquiringOrders.Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Connection.paymentConnection.acquiringProvider AS acquiringProvider,
	|	Connection.paymentConnection.server AS server,
	|	Connection.paymentConnection.port AS port,
	|	Connection.paymentConnection.user AS user,
	|	Connection.paymentConnection.password AS password,
	|	Connection.paymentConnection.timeout AS timeout,
	|	Connection.paymentConnection.secureConnection AS secureConnection,
	|	Connection.paymentConnection.UseOSAuthentication AS UseOSAuthentication,
	|	Connection.paymentConnection.merchantID AS merchantID,
	|	Connection.paymentConnection.key AS key,
	|	Connection.order.connectionType AS connectionType,
	|	Connection.orderIdentifier AS orderId,
	|	CASE
	|		WHEN Connection.order.connectionType = VALUE(Enum.ConnectionTypes.onlineStore)
	|			THEN Connection.orderIdentifier.Description
	|		ELSE Connection.order.Code
	|	END AS orderNumber,
	|	Connection.order.acquiringAmount - ISNULL(TemporaryDepositAmount.amount, 0) AS acquiringAmount,
	|	Connection.order.user AS bindingUser,
	|	Connection.order.creditCard AS creditCard,
	|	Connection.order.creditCard.Owner AS ownerCreditCard,
	|	Connection.order.acquiringRequest AS acquiringRequest,
	|	Connection.order AS order,
	|	Connection.order.user.Owner.Code AS phone,
	|	Connection.orderIdentifier.sessionId AS sessionId
	|FROM
	|	Connection AS Connection,
	|	TemporaryDepositAmount AS TemporaryDepositAmount
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryDepositAmount";
	return text;
EndFunction

Function answerStruct()
	answer = New Structure();
	answer.Insert("order", Catalogs.acquiringOrders.EmptyRef());
	answer.Insert("orderNumber", "");
	answer.Insert("acquiringAmount", 0);
	answer.Insert("orderId", "");	
	answer.Insert("bindingUser", Catalogs.users.EmptyRef());
	answer.Insert("bindingId", "");
	answer.Insert("creditCard", Catalogs.creditCards.EmptyRef());
	answer.Insert("ownerCreditCard", Catalogs.users.EmptyRef());
	answer.Insert("acquiringProvider", Enums.acquiringProviders.EmptyRef());
	answer.Insert("acquiringRequest", Enums.acquiringRequests.EmptyRef());
	answer.Insert("server", "");
	answer.Insert("port", 0);
	answer.Insert("user", "");
	answer.Insert("password", "");
	answer.Insert("timeout", 0);
	answer.Insert("secureConnection", False);
	answer.Insert("UseOSAuthentication", False);
	answer.Insert("errorCode", "");
	answer.Insert("errorDescription", "");
	answer.Insert("requestName", "");
	answer.Insert("requestBody", "");
	answer.Insert("responseBody", "");
	answer.Insert("response", New Structure());
	answer.Insert("key", "");
	answer.Insert("registrationDate", Date(1,1,1));	
	answer.Insert("merchantID", "");
	answer.Insert("authorization", "");
	answer.Insert("phone", "");
	answer.Insert("connectionType", Enums.ConnectionTypes.EmptyRef());
	answer.Insert("sessionId","");
	Return answer;		
EndFunction

Procedure creditCardsPreparation(paymentOption, parameters, order) Export
	orderParams = paymentParameters(order, parameters);
	For Each elementOfArray  in paymentOption do
			If elementOfArray.Property("cards") Then 
				If elementOfArray.cards.Count() > 0 Then
					index = 0;
					amount = 0;
					For Each card In elementOfArray.cards Do
						If card.type = "none" Then					
							amount = card.amount;
							Break;	
						EndIf;
						index = index+1;
					EndDo;
					elementOfArray.cards.Delete(index);
					SystemType = Enums.systemTypes.EmptyRef();
					If parameters.Property("tokenContext") And parameters.tokenContext.Property("systemType") Then
						SystemType = parameters.tokenContext.systemType;
					EndIf;
					If (Not SystemType.IsEmpty()) and ValueIsFilled(orderParams.merchantID) and orderParams.connectionType = enums.ConnectionTypes.main Then
						If SystemType = Enums.systemTypes.iOS Then
							cardStruct = New Structure("type, name, uid, amount", "applePay", "Apple Pay", "applePay", amount);
							elementOfArray.cards.insert(0, cardStruct);
						ElsIf SystemType = Enums.systemTypes.Android Then
							cardStruct = New Structure("type, name, uid, amount", "googlePay", "Google Pay", "googlePay", amount);
							elementOfArray.cards.insert(0, cardStruct);
						EndIf;
					EndIf;
					If hasConnection(order, enums.ConnectionTypes.qr) then
						cardStruct = New Structure("type, name, uid, amount", "qr", NStr("ru='Оплата по QR коду';en='Payment by QR code'", parameters.languageCode), "qr", amount);
						elementOfArray.cards.add(cardStruct);
					EndIf;
					
					PaymentSystemDescription = "Bank card";
					PaymentSystemDescription = NStr("ru='Банковская карта';en='Bank card'", parameters.languageCode);
				
					cardStruct = New Structure("type, name, uid, amount", "bankCard", PaymentSystemDescription, "bankCard", amount);
					elementOfArray.cards.add(cardStruct);			
				Else
					elementOfArray.Delete("cards");
				EndIf;
			EndIf;	
	EndDo;
EndProcedure

Function hasConnection(order, connectionType)
	query = New query;
	query.SetParameter("order", order);
	query.SetParameter("connectionType", connectionType);
	query.Text = "SELECT
	|	SUM(acquiringOrderspayments.amount) AS amount
	|INTO TemporaryDepositAmount
	|FROM
	|	Catalog.acquiringOrders.payments AS acquiringOrderspayments
	|WHERE
	|	acquiringOrderspayments.Ref = &order
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection
	|		WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|			THEN chainAcquiringProviderConnection.connection
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection
	|		WHEN NOT chainConnection.connection IS NULL
	|			THEN chainConnection.connection
	|		ELSE holdingConnection.connection
	|	END AS paymentConnection
	|INTO TemporaryConnection
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymAcquiringProviderConnection
	|		ON acquiringOrders.holding = gymAcquiringProviderConnection.holding
	|		AND acquiringOrders.gym = gymAcquiringProviderConnection.gym
	|		AND acquiringOrders.acquiringProvider = gymAcquiringProviderConnection.acquiringProvider
	|		AND gymAcquiringProviderConnection.connectionType = &connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS AcquiringProviderConnection
	|		ON acquiringOrders.holding = AcquiringProviderConnection.holding
	|		AND acquiringOrders.acquiringProvider = AcquiringProviderConnection.acquiringProvider
	|		AND AcquiringProviderConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND AcquiringProviderConnection.chain = VALUE(catalog.chains.emptyref)
	|		AND AcquiringProviderConnection.connectionType = &connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymConnection
	|		ON acquiringOrders.holding = gymConnection.holding
	|		AND acquiringOrders.gym = gymConnection.gym
	|		AND acquiringOrders.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND gymConnection.connectionType = &connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS holdingConnection
	|		ON acquiringOrders.holding = holdingConnection.holding
	|		AND holdingConnection.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND holdingConnection.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND holdingConnection.chain = VALUE(catalog.chains.emptyref)
	|		AND holdingConnection.connectionType = &connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainConnection
	|		ON acquiringOrders.holding = chainConnection.holding
	|		AND acquiringOrders.gym.chain = chainConnection.chain
	|		AND chainConnection.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		AND chainConnection.gym = VALUE(Catalog.gyms.emptyRef)
	|		AND chainConnection.connectionType = &connectionType
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainAcquiringProviderConnection
	|		ON acquiringOrders.holding = chainAcquiringProviderConnection.holding
	|		AND acquiringOrders.gym.chain = chainAcquiringProviderConnection.chain
	|		AND acquiringOrders.acquiringProvider = chainAcquiringProviderConnection.acquiringProvider
	|		AND chainAcquiringProviderConnection.gym = VALUE(Catalog.gyms.emptyRef)
	|		AND chainAcquiringProviderConnection.connectionType = &connectionType
	|WHERE
	|	acquiringOrders.Ref = &order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryConnection.paymentConnection
	|FROM
	|	TemporaryConnection AS TemporaryConnection
	|WHERE
	|	TemporaryConnection.paymentConnection <> VALUE(Catalog.acquiringConnections.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryDepositAmount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryConnection";
	result = query.Execute();
	If result.IsEmpty() then
		return false;
	EndIf;
	return true;
EndFunction

Procedure addOrderToQueue(order, state) Export
	record = InformationRegisters.acquiringOrdersQueue.CreateRecordManager();
	record.order = order;
	record.orderState = state;
	record.registrationDate = ToUniversalTime(CurrentDate());
	record.Write();	
EndProcedure

Procedure delOrderToQueue(order) Export
	record = InformationRegisters.acquiringOrdersQueue.CreateRecordManager();
	record.order = order;
	record.Read();
	If record.Selected() Then
		record.Delete();
	EndIf;	
EndProcedure

Procedure executeRequestBackground(requestName, order, additionalParameters = Undefined) Export
	array	= New Array();
	array.Add(requestName);
	array.Add(order);
	array.Add(additionalParameters);
	BackgroundJobs.Execute("Acquiring.executeRequest", array, New UUID());
EndProcedure

Procedure sendOrder(parameters)
	parameters.Insert("errorCode", "acquiringOrderSend");
	If parameters.acquiringRequest = Enums.acquiringRequests.binding Then
		parameters.Insert("returnUrl", "https://solutions.worldclass.ru/banking/bindSuccess.html");
		parameters.Insert("failUrl", "https://solutions.worldclass.ru/banking/bindFail.html");
	Else
		parameters.Insert("returnUrl", "https://solutions.worldclass.ru/banking/success.html");
		parameters.Insert("failUrl", "https://solutions.worldclass.ru/banking/fail.html");
	EndIf;
	parameters.Insert("formUrl", "");
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.sendOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then
		If parameters.acquiringRequest <> Enums.acquiringRequests.binding Then
			AcquiringDemirBank.sendOrder(parameters);
		EndIf;
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.alfaBankMinsk Then
		 AcquiringAlfaBankMinsk.sendOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.forteBank Then
		 AcquiringForteBank.sendOrder(parameters);
	EndIf;
	If parameters.errorCode = "" Then
		changeOrderState(parameters.order, Enums.acquiringOrderStates.send);	
	EndIf;
EndProcedure

Procedure checkOrder(parameters) 
	parameters.Insert("errorCode", "acquiringOrderCheck");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		If (parameters.order.acquiringRequest = enums.acquiringRequests.applePay
	    or parameters.order.acquiringRequest = enums.acquiringRequests.googlePay)
	   and parameters.Property("paymentData") Then
	   		parametersNew = Service.getStructCopy(parameters);
			AcquiringSberbank.checkOrderAppleGoogle(parametersNew);
			Service.logAcquiringBackground(parametersNew);
		EndIf;
		AcquiringSberbank.checkOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then 
		AcquiringDemirBank.checkOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.raiffeisen Then 
		AcquiringRaiffeisen.checkStatus(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.alfaBankMinsk Then
		AcquiringAlfaBankMinsk.checkOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.forteBank Then
		AcquiringForteBank.checkOrder(parameters);  
	EndIf;
	If parameters.errorCode = "" Then
		If parameters.acquiringRequest = Enums.acquiringRequests.binding Then
			activateCard(parameters);
			parametersNew = Service.getStructCopy(parameters);
			Acquiring.reverseOrder(parametersNew);
			Service.logAcquiringBackground(parametersNew);
		EndIf;
		If parameters.errorCode = "" Then
			changeOrderState(parameters.order, Enums.acquiringOrderStates.success);
		Else
			changeOrderState(parameters.order, Enums.acquiringOrderStates.rejected);
		EndIf;
	ElsIf parameters.errorCode = "rejected" and parameters.registrationDate < ToUniversalTime(CurrentDate())-20*60 Then
		changeOrderState(parameters.order, Enums.acquiringOrderStates.rejected);
	//ElsIf parameters.errorCode = "send"  Then
	//	changeOrderState(parameters.order, Enums.acquiringOrderStates.send);
	Else
		parameters.errorCode = "send";
		changeOrderState(parameters.order, Enums.acquiringOrderStates.send);
		Acquiring.addOrderToQueue(parameters.order, Enums.acquiringOrderStates.send);
	EndIf;
EndProcedure

Procedure reverseOrder(parameters) Export
	parameters.Insert("errorCode", "acquiringOrderReverse");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.reverseOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.alfaBankMinsk Then
		AcquiringAlfaBankMinsk.reverseOrder(parameters);
	EndIf;
	Service.logAcquiringBackground(parameters);
EndProcedure

Procedure unBindCard(parameters)
	parameters.Insert("errorCode", "acquiringUnBindCard");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.unBindCard(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.alfaBankMinsk Then
		 AcquiringAlfaBankMinsk.unBindCard(parameters);
	EndIf;	
	If parameters.errorCode = "" Then 
		deactivateCard(parameters.creditCard);
	EndIf;
EndProcedure

Procedure addCardToOrder(order, creditCard)
	If Not creditCard.IsEmpty() Then
		orderObject = order.GetObject();		
		orderObject.creditCard = creditCard;
		orderObject.Write();
	EndIf;
EndProcedure

Procedure activateCard(parameters)
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		bindCardParameters = AcquiringSberbank.bindCardParameters(parameters);
	elsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then
		//bindCardParameters = AcquiringDemirBank.bindCardParameters(parameters);
	elsIf parameters.acquiringProvider = Enums.acquiringProviders.alfaBankMinsk Then
		bindCardParameters = AcquiringAlfaBankMinsk.bindCardParameters(parameters);
	EndIf;	
	
	if bindCardParameters.Property("bindingId") and bindCardParameters.bindingId <> "" then
		creditCardObject = Catalogs.creditCards.GetRef(New UUID(bindCardParameters.bindingId)).GetObject();
	else
		creditCardObject = Undefined;
	EndIf;
			
	If creditCardObject = Undefined Then		
		creditCard = newCard(bindCardParameters); 
	Else
		creditCardObject.inactive = False;
		creditCardObject.Write();
		creditCard = creditCardObject.Ref;				
	EndIf;	
	addCardToOrder(parameters.order, creditCard);
	If creditCard.IsEmpty() then
		parameters.errorCode = "rejected";
	EndIf;
	
EndProcedure

Procedure deactivateCard(creditCard)
	creditCardObject = creditCard.GetObject();
	creditCardObject.inactive = True;
	creditCardObject.Write();	
EndProcedure

Procedure changeOrderState(order, state) Export
	record = InformationRegisters.ordersStates.CreateRecordManager();
	record.order = order;
	record.state = state;
	record.Write();
EndProcedure

Procedure getQr(parameters, additionalParameters) Export
	parameters.Insert("returnUrl", "https://solutions.worldclass.ru/banking/bindSuccess.html");
	parameters.Insert("failUrl", "https://solutions.worldclass.ru/banking/bindFail.html");
	If parameters.acquiringProvider = Enums.acquiringProviders.raiffeisen Then
		AcquiringRaiffeisen.getQr(parameters, additionalParameters);
	EndIf;
	If parameters.errorCode = "" Then
		changeOrderState(parameters.order, Enums.acquiringOrderStates.send);
	else
		changeOrderState(parameters.order, Enums.acquiringOrderStates.rejected);	
	EndIf;
EndProcedure

Procedure autoPayment(parameters) Export
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.autoPayment(parameters);
	EndIf;
EndProcedure

