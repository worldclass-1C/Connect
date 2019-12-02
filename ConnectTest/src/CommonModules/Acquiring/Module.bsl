
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
				owner = XMLValue(TypeOf("CatalogRef.users"), paymentOption.owner.uid);
			Else
				owner = Catalogs.users.EmptyRef();
			EndIf;
			If paymentOption.Property("cards") Then
				For Each element In paymentOption.cards Do
					newRow = orderObject.cards.Add();
					newRow.card = XMLValue(TypeOf("CatalogRef.creditCards"), element.uid);					
				EndDo;
			EndIf;
			If paymentOption.Property("deposits") Then
				For Each element In paymentOption.deposits Do
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
	orderObject.registrationDate = ToUniversalTime(CurrentDate());
	orderObject.Write();
	Service.logAcquiringBackground(New Structure("order, requestName", orderObject.ref, "write"));
	Return orderObject.ref;
EndFunction

Function executeRequest(requestName, order) Export
	parameters = orderDetails(order);
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
		EndIf;
	EndIf;
	Service.logAcquiringBackground(parameters);
	Return parameters;
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

Procedure executeRequestBackground(requestName, order) Export
	array	= New Array();
	array.Add(requestName);
	array.Add(order);
	BackgroundJobs.Execute("Acquiring.executeRequest", array, New UUID());
EndProcedure

Procedure sendOrder(parameters)
	parameters.Insert("errorCode", "acquiringOrderSend");
	parameters.Insert("returnUrl", "https://solutions.worldclass.ru/banking/success.html");
	parameters.Insert("failUrl", "https://solutions.worldclass.ru/banking/fail.html");
	parameters.Insert("formUrl", "");
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.sendOrder(parameters);
	EndIf;	
EndProcedure

Procedure checkOrder(parameters)
	parameters.Insert("errorCode", "acquiringOrderCheck");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.checkOrder(parameters);
	EndIf;		
	If parameters.errorCode = "" And parameters.acquiringRequest = Enums.acquiringRequests.binding Then
		activateCard(parameters);		
	EndIf;
EndProcedure

Procedure reverseOrder(parameters)
	parameters.Insert("errorCode", "acquiringOrderReverse");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.reverseOrder(parameters);
	EndIf;	
EndProcedure

Procedure unBindCard(parameters)
	parameters.Insert("errorCode", "acquiringUnBindCard");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.unBindCard(parameters);
	EndIf;	
	If parameters.errorCode = "" Then 
		deactivateCard(parameters.creditCard);
	EndIf;
EndProcedure

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
		creditCard.paymentSystem = Acquiring.paymentSystem(left(creditCard.Description, 2));
		creditCard.registrationDate = ToUniversalTime(CurrentDate());
		creditCard.Write();
		Return creditCard.Ref;
	EndIf;
EndFunction

Procedure addCardToQueue(creditCard)
	If Not creditCard.IsEmpty() Then
		record = InformationRegisters.queueCreditCardToSend.CreateRecordManager();
		record.Period = ToUniversalTime(CurrentDate());
		record.creditCard = creditCard;
		record.Write();
	EndIf;
EndProcedure

Procedure activateCard(parameters)
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		bindCardParameters = AcquiringSberbank.bindCardParameters(parameters);
	EndIf;	
	creditCardObject = Catalogs.creditCards.GetRef(New UUID(bindCardParameters.bindingId)).GetObject();
	If creditCardObject = Undefined Then		
		creditCard = newCard(bindCardParameters); 
	Else
		creditCardObject.inactive = False;
		creditCardObject.Write();
		creditCard = creditCardObject.Ref;				
	EndIf;	
	addCardToQueue(creditCard);
EndProcedure

Procedure deactivateCard(creditCard)
	creditCardObject = creditCard.GetObject();
	creditCardObject.inactive = True;
	creditCardObject.Write();
	addCardToQueue(creditCard);
EndProcedure

Function orderDetails(order)
	
	answer = answerStruct();
			
	query = New Query();
	query.text = "SELECT
	|	acquiringOrders.Ref AS order,
	|	acquiringOrderIdentifiers.Ref AS orderId,
	|	acquiringOrders.Code AS orderNumber,
	|	acquiringOrders.acquiringAmount AS acquiringAmount,
	|	acquiringOrders.user AS bindingUser,
	|	acquiringOrders.creditCard,
	|	acquiringOrders.acquiringRequest AS acquiringRequest,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.acquiringProvider
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.acquiringProvider
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.acquiringProvider
	|		ELSE holdingConnection.connection.acquiringProvider
	|	END AS acquiringProvider,
	|	ISNULL(CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.server
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.server
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.server
	|		ELSE holdingConnection.connection.server
	|	END, """") AS server,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.port
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.port
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.port
	|		ELSE holdingConnection.connection.port
	|	END AS port,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.user
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.user
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.user
	|		ELSE holdingConnection.connection.user
	|	END AS user,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.password
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.password
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.password
	|		ELSE holdingConnection.connection.password
	|	END AS password,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.timeout
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.timeout
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.timeout
	|		ELSE holdingConnection.connection.timeout
	|	END AS timeout,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.secureConnection
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.secureConnection
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.secureConnection
	|		ELSE holdingConnection.connection.secureConnection
	|	END AS secureConnection,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.UseOSAuthentication
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.UseOSAuthentication
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.UseOSAuthentication
	|		ELSE holdingConnection.connection.UseOSAuthentication
	|	END AS UseOSAuthentication,
	|	"""" AS errorDescription
	|FROM
	|	Catalog.acquiringOrders AS acquiringOrders
	|		LEFT JOIN Catalog.acquiringOrderIdentifiers AS acquiringOrderIdentifiers
	|		ON acquiringOrderIdentifiers.Owner = acquiringOrders.Ref
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymAcquiringProviderConnection
	|		ON acquiringOrders.holding = gymAcquiringProviderConnection.holding
	|		AND acquiringOrders.gym = gymAcquiringProviderConnection.gym
	|		AND acquiringOrders.acquiringProvider = gymAcquiringProviderConnection.acquiringProvider
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS AcquiringProviderConnection
	|		ON acquiringOrders.holding = AcquiringProviderConnection.holding
	|		AND acquiringOrders.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND acquiringOrders.acquiringProvider = AcquiringProviderConnection.acquiringProvider
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS gymConnection
	|		ON acquiringOrders.holding = gymConnection.holding
	|		AND acquiringOrders.gym = gymConnection.gym
	|		AND acquiringOrders.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS holdingConnection
	|		ON acquiringOrders.holding = holdingConnection.holding
	|		AND acquiringOrders.gym = VALUE(Catalog.gyms.EmptyRef)
	|		AND acquiringOrders.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|WHERE
	|	acquiringOrders.ref = &order";

	query.SetParameter("order", order);	
	result = query.Execute();
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
	
	Return answer;
	
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
	Return answer;		
EndFunction
