
Function newOrder(parameters, sendOrderImmediately = False) Export	
	orderObject = Catalogs.acquiringOrders.CreateItem();
	FillPropertyValues(orderObject, parameters);
	If parameters.Property("orders") Then
		For Each element In parameters.orders Do
			newRow = orderObject.orders.Add();
			newRow.uid = element.docId;				
		EndDo;	
	EndIf;	
	orderObject.Write();
	answer = orderDetails(orderObject.ref);
	answer.Insert("requestName", "write");	
	Service.logAcquiringBackground(answer);
	If sendOrderImmediately Then		
		sendOrder(answer);		
	EndIf;
	Return answer;
EndFunction

Function checkOrder(parameters) Export
	answer = orderDetails(parameters.order);
	answer.Insert("requestName", "write");	
	Return answer;
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

Function orderDetails(order)
	
	answer = answerStruct();
		
	query = New Query();
	query.text = "SELECT
	|	acquiringOrders.Ref AS order,
	|	acquiringOrders.Code AS orderNumber,
	|	acquiringOrders.acquiringAmount AS acquiringAmount,
	|	""https://solutions.worldclass.ru/payment/success"" AS returnUrl,
	|	""https://solutions.worldclass.ru/payment/fail"" AS failUrl,
	|	""DESKTOP"" AS pageView,
	|	acquiringOrders.user AS bindingUser,
	|	acquiringOrders.bindingId AS bindingId,
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
	|	CASE
	|		WHEN NOT gymAcquiringProviderConnection.connection IS NULL
	|			THEN gymAcquiringProviderConnection.connection.server
	|		WHEN NOT AcquiringProviderConnection.connection IS NULL
	|			THEN AcquiringProviderConnection.connection.server
	|		WHEN NOT gymConnection.connection IS NULL
	|			THEN gymConnection.connection.server
	|		ELSE holdingConnection.connection.server
	|	END AS server,
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
	If Not result.IsEmpty() Then
		select = result.Select();
		select.Next();
		FillPropertyValues(answer, select);		
//		sendOrder(parameters);	 
	EndIf;	
	
	Return answer;
	
EndFunction

Procedure sendOrder(parameters)
	parameters.Insert("requestName", "send");
	parameters.Insert("errorCode", "acquiringOrderSend");
	If parameters.acquiringProvider = Enums.acquiringProviders.sberbank Then
		AcquiringSberbank.sendOrder(parameters);
	EndIf;
	Service.logAcquiringBackground(parameters);		
EndProcedure

Function answerStruct()
	answer = New Structure();
	answer.Insert("order", Catalogs.acquiringOrders.EmptyRef());
	answer.Insert("orderNumber", "");
	answer.Insert("acquiringAmount", 0);
	answer.Insert("orderId", "");
	answer.Insert("formUrl", "");
	answer.Insert("returnUrl", "");
	answer.Insert("failUrl" "");
	answer.Insert("pageView", "");
	answer.Insert("bindingUser", Catalogs.users.EmptyRef());
	answer.Insert("bindingId", "");
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
	Return answer;		
EndFunction

