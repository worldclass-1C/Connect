
Procedure sendSMS() Export
	Messages.sendMessages(Enums.informationChannels.sms);
EndProcedure

Procedure sendPush() Export
	Messages.sendMessages(Enums.informationChannels.pushEmployee);
	Messages.sendMessages(Enums.informationChannels.pushCustomer);
EndProcedure

Procedure checkSmsStatus() Export		
	nodeMessagesToCheckStatus	= GeneralReuse.nodeMessagesToCheckStatus(Enums.informationChannels.sms);
	query	= New Query();
	query.text	= "SELECT DISTINCT
	|	messages.Ref.holding AS holding
	|FROM
	|	Catalog.messages.Changes AS messages
	|WHERE
	|	messages.node = &node";	
	query.SetParameter("node", nodeMessagesToCheckStatus);	
	selection	= query.Execute().Select();	
	While selection.Next() Do
		Messages.checkHoldingSmsStatus(nodeMessagesToCheckStatus, selection.holding);
	EndDo;
EndProcedure 

Procedure CalcValues() Export
	Service.CalcValues();
EndProcedure

Procedure alertSourceInformation() Export
	Service.informationSourceAlert();
EndProcedure

Procedure CheckTokenValid() Export
	Service.CheckTokenValid();
EndProcedure

Procedure CheckAcquiringStatus() Export
	OrdersToCheck = GetOrdersToCheck();
	While OrdersToCheck.Next() Do
		response = Acquiring.executeRequest("check", OrdersToCheck.order);
		If response = Undefined Then
			  Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.rejected);		
		Else
			If response.errorCode = "" Then
				Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.success);
			Else
				Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.rejected);
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Function GetOrdersToCheck()
	Query = New Query();
	Query.Text = "SELECT TOP 100
	|	acquiringOrdersQueue.order
	|FROM
	|	InformationRegister.acquiringOrdersQueue AS acquiringOrdersQueue
	|WHERE
	|	acquiringOrdersQueue.orderState = VALUE(Enum.acquiringOrderStates.send)
	|	AND acquiringOrdersQueue.registrationDate < DATEADD(&CurrentDate, Minute, -20)
	|	AND
	|	NOT acquiringOrdersQueue.order IS NULL
	|ORDER BY
	|	acquiringOrdersQueue.registrationDate";
	Query.Parameters.Insert("CurrentDate", ToUniversalTime(CurrentDate()));
	Return Query.Execute().Select();
EndFunction

Procedure ProcessQueue() Export
	OrdersToProcess = GetOrdersToProcess();
	While OrdersToProcess.Next() Do
		parameters = GetParametersToProcessOrder(OrdersToProcess);
		If OrdersToProcess.acquiringRequest = Enums.acquiringRequests.register Then
			If OrdersToProcess.try < 30 then
				Acquiring.executeRequest("process", OrdersToProcess.order, parameters);
			Else
				Acquiring.delOrderToQueue(OrdersToProcess.order);
			EndIf;
		ElsIf OrdersToProcess.acquiringRequest = Enums.acquiringRequests.binding Then
			If OrdersToProcess.orderState = Enums.acquiringOrderStates.success Then
				Acquiring.executeRequest("bindCardBack", OrdersToProcess.order, parameters);
			Else
				Acquiring.delOrderToQueue(OrdersToProcess.order);
			EndIf;
		ElsIf OrdersToProcess.acquiringRequest = Enums.acquiringRequests.unbinding Then
			Acquiring.executeRequest("unBindCardBack", OrdersToProcess.order, parameters);
		EndIf;
	EndDo;	
EndProcedure

Function GetOrdersToProcess()
	Query = New Query();
	Query.Text = "SELECT TOP 100
	|	acquiringOrdersQueue.order,
	|	ISNULL(acquiringOrdersQueue.order.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)) AS language,
	|	ISNULL(acquiringOrdersQueue.order.holding.languageDefault.Code, """") AS languageCode,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)) AS timeZone,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.user.userCode, """") AS userCode,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.deviceModel, """") AS deviceModel,
	|	acquiringOrdersQueue.order.holding.tokenDefault AS tokenDefault,
	|	acquiringOrdersQueue.order.holding AS holding,
	|	acquiringOrdersQueue.order.acquiringRequest AS acquiringRequest,
	|	acquiringOrdersQueue.orderState,
	|	COUNT(DISTINCT isnull(acquiringLogs.Ref,0)) AS try
	|FROM
	|	InformationRegister.acquiringOrdersQueue AS acquiringOrdersQueue
	|		LEFT JOIN Catalog.acquiringLogs AS acquiringLogs
	|		ON acquiringOrdersQueue.order = acquiringLogs.order
	|		AND acquiringLogs.requestName = ""process""
	|		AND
	|		NOT acquiringLogs.isError
	|WHERE
	|	acquiringOrdersQueue.orderState <> VALUE(Enum.acquiringOrderStates.send)
	|	AND
	|	NOT acquiringOrdersQueue.order IS NULL
	|GROUP BY
	|	acquiringOrdersQueue.order,
	|	acquiringOrdersQueue.order.holding.tokenDefault,
	|	acquiringOrdersQueue.order.holding,
	|	acquiringOrdersQueue.order.acquiringRequest,
	|	acquiringOrdersQueue.orderState,
	|	ISNULL(acquiringOrdersQueue.order.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)),
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef))";
	Return Query.Execute().Select();
EndFunction

Function GetParametersToProcessOrder(DataSelect)
	Parameters = new structure();
	Parameters.Insert("language", DataSelect.language);
	Parameters.Insert("authKey", string(DataSelect.tokenDefault.UUID()));
	Parameters.Insert("requestName", "process");
	Parameters.Insert("languageCode", DataSelect.languageCode);
	TokenContext = New structure();
	TokenContext.Insert("user", DataSelect.userCode);
	TokenContext.Insert("timeZone", DataSelect.timeZone);
	TokenContext.Insert("appType", DataSelect.deviceModel);
	TokenContext.Insert("holding",DataSelect.holding);
	TokenContext.Insert("token",Catalogs.tokens.EmptyRef());
	Parameters.Insert("tokenContext", TokenContext);
	Return Parameters;
EndFunction

Procedure ClearHistory() Export
	query = New Query();
	query.Text = "SELECT TOP 100
	|	logs.Ref
	|FROM
	|	Catalog.logs AS logs
	|WHERE
	|	logs.period < DATEADD(&currentDate, Month, -6)";
	query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));
	selection = query.Execute().Select();
	While selection.Next() Do
		objectLog = selection.ref.GetObject();
		objectLog.Delete();
	EndDo;
EndProcedure
