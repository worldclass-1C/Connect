
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
	orderObject.registrationDate = ToUniversalTime(CurrentDate());
	orderObject.Write();
	Service.logAcquiringBackground(New Structure("order, requestName", orderObject.ref, "write"));
	Return orderObject.ref;
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
	parameters = orderDetails(order);
	parameters.Insert("requestName", requestName);	
	If parameters.errorCode = "" Then
		If requestName = "send" Then
			sendOrder(parameters);
		ElsIf requestName = "check" Then
			checkOrder(parameters, additionalParameters);
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
			getQr(parameters,additionalParameters);				
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

Function orderDetails(order)
	
	answer = answerStruct();
			
	query = New Query();
	query.text = "SELECT
	|	SUM(acquiringOrderspayments.amount) AS amount
	|INTO TemporaryDepositAmount
	|FROM
	|	Catalog.acquiringOrders.payments AS acquiringOrderspayments
	|WHERE
	|	acquiringOrderspayments.Ref = &order
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	acquiringOrders.Ref AS order,
	|	acquiringOrderIdentifiers.Ref AS orderId,
	|	acquiringOrders.Code AS orderNumber,
	|	acquiringOrders.acquiringAmount - ISNULL(TemporaryDepositAmount.amount, 0) AS acquiringAmount,
	|	acquiringOrders.user AS bindingUser,
	|	acquiringOrders.creditCard,
	|	ISNULL(acquiringOrders.creditCard.owner, VALUE(Catalog.users.EmptyRef)) AS ownerCreditCard,
	|	acquiringOrders.acquiringRequest AS acquiringRequest,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(Enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.acquiringProvider
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.acquiringProvider
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.acquiringProvider
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.acquiringProvider
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.acquiringProvider
	|				ELSE holdingConnection.qrConnection.acquiringProvider
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.acquiringProvider
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.acquiringProvider
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.acquiringProvider
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.acquiringProvider
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.acquiringProvider
	|			ELSE holdingConnection.connection.acquiringProvider
	|		END
	|	END AS acquiringProvider,
	|	ISNULL(CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(Enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.server
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.server
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.server
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.server
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.server
	|				ELSE holdingConnection.qrConnection.server
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.server
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.server
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.server
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.server
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.server
	|			ELSE holdingConnection.connection.server
	|		END
	|	END, """") AS server,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(Enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.port
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.port
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.port
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.port
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.port
	|				ELSE holdingConnection.qrConnection.port
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.port
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.port
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.port
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.port
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.port
	|			ELSE holdingConnection.connection.port
	|		END
	|	END AS port,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.user
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.user
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.user
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.user
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.user
	|				ELSE holdingConnection.qrConnection.user
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.user
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.user
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.user
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.user
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.user
	|			ELSE holdingConnection.connection.user
	|		END
	|	END AS user,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.password
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.password
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.password
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.password
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.password
	|				ELSE holdingConnection.qrConnection.password
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.password
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.password
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.password
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.password
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.password
	|			ELSE holdingConnection.connection.password
	|		END
	|	END AS password,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.timeout
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.timeout
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.timeout
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.timeout
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.timeout
	|				ELSE holdingConnection.qrConnection.timeout
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.timeout
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.timeout
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.timeout
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.timeout
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.timeout
	|			ELSE holdingConnection.connection.timeout
	|		END
	|	END AS timeout,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.secureConnection
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.secureConnection
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.secureConnection
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.secureConnection
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.secureConnection
	|				ELSE holdingConnection.qrConnection.secureConnection
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.secureConnection
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.secureConnection
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.secureConnection
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.secureConnection
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.secureConnection
	|			ELSE holdingConnection.connection.secureConnection
	|		END
	|	END AS secureConnection,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN CASE
	|				WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|					THEN gymAcquiringProviderConnection.qrConnection.UseOSAuthentication
	|				WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|					THEN chainAcquiringProviderConnection.qrConnection.UseOSAuthentication
	|				WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|					THEN AcquiringProviderConnection.qrConnection.UseOSAuthentication
	|				WHEN NOT gymConnection.qrConnection IS NULL
	|					THEN gymConnection.qrConnection.UseOSAuthentication
	|				WHEN NOT chainConnection.qrConnection IS NULL
	|					THEN chainConnection.qrConnection.UseOSAuthentication
	|				ELSE holdingConnection.qrConnection.UseOSAuthentication
	|			END
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.UseOSAuthentication
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.UseOSAuthentication
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.UseOSAuthentication
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.UseOSAuthentication
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.UseOSAuthentication
	|			ELSE holdingConnection.connection.UseOSAuthentication
	|		END
	|	END AS UseOSAuthentication,
	|	"""" AS errorDescription,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN """"
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.merchantPay
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.merchantPay
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.merchantPay
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.merchantPay
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.merchantPay
	|			ELSE holdingConnection.connection.merchantPay
	|		END
	|	END AS merchantPay,
	|	CASE
	|		WHEN acquiringOrders.acquiringRequest = VALUE(enum.acquiringRequests.qrRegister)
	|			THEN """"
	|		ELSE CASE
	|			WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|				THEN gymAcquiringProviderConnection.connection.key
	|			WHEN NOT chainAcquiringProviderConnection.connection IS NULL
	|				THEN chainAcquiringProviderConnection.connection.key
	|			WHEN NOT AcquiringProviderConnection.connection IS NULL
	|				THEN AcquiringProviderConnection.connection.key
	|			WHEN NOT gymConnection.connection IS NULL
	|				THEN gymConnection.connection.key
	|			WHEN NOT chainConnection.connection IS NULL
	|				THEN chainConnection.connection.key
	|			ELSE holdingConnection.connection.key
	|		END
	|	END AS key,
	|	acquiringOrders.registrationDate,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|			THEN gymAcquiringProviderConnection.qrConnection.merchantID
	|		WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|			THEN chainAcquiringProviderConnection.qrConnection.merchantID
	|		WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|			THEN AcquiringProviderConnection.qrConnection.merchantID
	|		WHEN NOT gymConnection.qrConnection IS NULL
	|			THEN gymConnection.qrConnection.merchantID
	|		WHEN NOT chainConnection.qrConnection IS NULL
	|			THEN chainConnection.qrConnection.merchantID
	|		ELSE holdingConnection.qrConnection.merchantID
	|	END AS merchantID,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|			THEN gymAcquiringProviderConnection.qrConnection.authorization
	|		WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|			THEN chainAcquiringProviderConnection.qrConnection.authorization
	|		WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|			THEN AcquiringProviderConnection.qrConnection.authorization
	|		WHEN NOT gymConnection.qrConnection IS NULL
	|			THEN gymConnection.qrConnection.authorization
	|		WHEN NOT chainConnection.qrConnection IS NULL
	|			THEN chainConnection.qrConnection.authorization
	|		ELSE holdingConnection.qrConnection.authorization
	|	END AS authorization,
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.qrConnection IS NULL
	|			THEN gymAcquiringProviderConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|		WHEN NOT chainAcquiringProviderConnection.qrConnection IS NULL
	|			THEN chainAcquiringProviderConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|		WHEN NOT AcquiringProviderConnection.qrConnection IS NULL
	|			THEN AcquiringProviderConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|		WHEN NOT gymConnection.qrConnection IS NULL
	|			THEN gymConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|		WHEN NOT chainConnection.qrConnection IS NULL
	|			THEN chainConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|		ELSE holdingConnection.qrConnection <> Value(Catalog.qrAcquiringConnections.EmptyRef)
	|	END AS hasQR
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
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainConnection
	|		ON acquiringOrders.holding = gymConnection.holding
	|		AND acquiringOrders.gym.chain = gymConnection.chain
	|		AND acquiringOrders.acquiringProvider = VALUE(Enum.acquiringProviders.EmptyRef)
	|		LEFT JOIN InformationRegister.holdingsConnectionsAcquiringBank AS chainAcquiringProviderConnection
	|		ON acquiringOrders.holding = gymAcquiringProviderConnection.holding
	|		AND acquiringOrders.gym.chain = gymAcquiringProviderConnection.chain
	|		AND acquiringOrders.acquiringProvider = gymAcquiringProviderConnection.acquiringProvider,
	|	TemporaryDepositAmount AS TemporaryDepositAmount
	|WHERE
	|	acquiringOrders.ref = &order
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryDepositAmount";

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
	answer.Insert("ownerCreditCard", Catalogs.users.EmptyRef());
	answer.Insert("acquiringProvider", Enums.acquiringProviders.EmptyRef());
	answer.Insert("acquiringRequest", Enums.acquiringRequests.EmptyRef());
	answer.Insert("server", "");
	answer.Insert("port", 0);
	answer.Insert("user", "");
	answer.Insert("password", "");
	answer.Insert("merchantPay", "");
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
	answer.Insert("hasQR",false);	
	Return answer;		
EndFunction

Procedure creditCardsPreparation(paymentOption, parameters, order) Export
	orderParams = orderDetails(order);
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
					If (Not SystemType.IsEmpty()) and ValueIsFilled(orderParams.merchantPay) Then
						If SystemType = Enums.systemTypes.iOS Then
							cardStruct = New Structure("type, name, uid, amount", "applePay", "Apple Pay", "applePay", amount);
							elementOfArray.cards.insert(0, cardStruct);
						ElsIf SystemType = Enums.systemTypes.Android Then
							cardStruct = New Structure("type, name, uid, amount", "googlePay", "Google Pay", "googlePay", amount);
							elementOfArray.cards.insert(0, cardStruct);
						EndIf;
					EndIf;
					If ValueIsFilled(orderParams.hasQR) then
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
	EndIf;
	If parameters.errorCode = "" Then
		changeOrderState(parameters.order, Enums.acquiringOrderStates.send);	
	EndIf;
EndProcedure

Procedure checkOrder(parameters, additionalParameters) 
	parameters.Insert("errorCode", "acquiringOrderCheck");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		If (parameters.order.acquiringRequest = enums.acquiringRequests.applePay
	   or parameters.order.acquiringRequest = enums.acquiringRequests.googlePay) and additionalParameters<>Undefined
	   and additionalParameters.Property("paymentData") Then
	   		parametersNew = Service.getStructCopy(parameters);
			AcquiringSberbank.checkOrderAppleGoogle(parametersNew, additionalParameters);
			Service.logAcquiringBackground(parametersNew);
		EndIf;
		AcquiringSberbank.checkOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then 
		AcquiringDemirBank.checkOrder(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.raiffeisen Then 
		AcquiringRaiffeisen.checkStatus(parameters);		
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
	EndIf;
	Service.logAcquiringBackground(parameters);
EndProcedure

Procedure unBindCard(parameters)
	parameters.Insert("errorCode", "acquiringUnBindCard");	
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.unBindCard(parameters);
	ElsIf parameters.acquiringProvider = Enums.acquiringProviders.demirBank Then
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

Procedure getQr(parameters,additionalParameters) Export
	parameters.Insert("returnUrl", "https://solutions.worldclass.ru/banking/bindSuccess.html");
	parameters.Insert("failUrl", "https://solutions.worldclass.ru/banking/bindFail.html");
	If parameters.acquiringProvider = Enums.acquiringProviders.raiffeisen Then
		AcquiringRaiffeisen.getQr(parameters,additionalParameters);
	EndIf;
EndProcedure

