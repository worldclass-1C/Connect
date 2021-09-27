
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
			Acquiring.changeOrderState(OrdersToCheck.order, Enums.acquiringOrderStates.rejected);		
		Else
			If response.errorCode = "" Then
				Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.success);
			Else
				If response.errorCode = "send"  Then
					Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.send);
				else
					Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.rejected);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Function GetOrdersToCheck()
	Query = New Query();
	Query.Text = "SELECT TOP 100 ALLOWED
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
		parameters = GetParametersToSend(OrdersToProcess, "process");
		If OrdersToProcess.acquiringRequest = Enums.acquiringRequests.binding Then
			If OrdersToProcess.orderState = Enums.acquiringOrderStates.success Then
				Acquiring.executeRequest("bindCardBack", OrdersToProcess.order, parameters);
			Else
				Acquiring.delOrderToQueue(OrdersToProcess.order);
			EndIf;
		ElsIf OrdersToProcess.acquiringRequest = Enums.acquiringRequests.unbinding Then
			Acquiring.executeRequest("unBindCardBack", OrdersToProcess.order, parameters);
		else
			If OrdersToProcess.try < 30 then
				If not ValueIsFilled(OrdersToProcess.newOrder) then
					answerKPO = Acquiring.executeRequest("process", OrdersToProcess.order, parameters);
					If answerKPO.errorCode = "" Then
						Acquiring.delOrderToQueue(OrdersToProcess.order);
					Else
						If OrdersToProcess.orderState = Null Then
							Acquiring.addOrderToQueue(OrdersToProcess.order, Enums.acquiringOrderStates.rejected);
						EndIf;
					EndIf;
				EndIf;
			Else
				Acquiring.delOrderToQueue(OrdersToProcess.order);
			EndIf;
		EndIf;
		
		If OrdersToProcess.orderState = Null Then
			Acquiring.changeOrderState(OrdersToProcess.order, Enums.acquiringOrderStates.rejected);
		EndIf; 
		
	EndDo;	
EndProcedure

Function GetOrdersToProcess()
	Query = New Query();
	Query.Text = "SELECT
	|	acquiringOrders.Ref AS Ref,
	|	ordersStates.state AS state,
	|	acquiringOrdersorders.uid AS uid,
	|	acquiringOrders.registrationDate AS registrationDate
	|INTO tempNoStatus
	|FROM
	|	Catalog.acquiringOrders.orders AS acquiringOrdersorders
	|		LEFT JOIN Catalog.acquiringOrders AS acquiringOrders
	|			LEFT JOIN InformationRegister.ordersStates AS ordersStates
	|			ON ordersStates.order = acquiringOrders.Ref
	|		ON acquiringOrdersorders.Ref = acquiringOrders.Ref
	|WHERE
	|	ordersStates.state IS NULL
	|	AND acquiringOrders.registrationDate < DATEADD(&CurrentDate, Minute, -20)
	|	AND acquiringOrders.acquiringRequest <> VALUE(enum.acquiringRequests.autoPayment)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 100
	|	acquiringOrdersQueue.order AS order,
	|	ISNULL(acquiringOrdersQueue.order.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)) AS language,
	|	ISNULL(acquiringOrdersQueue.order.holding.languageDefault.Code, """") AS languageCode,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)) AS timeZone,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.user.userCode, """") AS userCode,
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.deviceModel, """") AS deviceModel,
	|	acquiringOrdersQueue.order.holding.tokenDefault AS tokenDefault,
	|	acquiringOrdersQueue.order.holding AS holding,
	|	acquiringOrdersQueue.order.acquiringRequest AS acquiringRequest,
	|	acquiringOrdersQueue.orderState,
	|	COUNT(DISTINCT ISNULL(acquiringLogs.Ref, 0)) AS try,
	|	acquiringOrdersQueue.order.holding.tokenDefault.appVersion AS appVersion,
	|	acquiringOrdersQueue.order.holding.tokenDefault.systemType AS systemType,
	|	NULL AS newOrder,
	|	acquiringOrdersQueue.order.holding.tokenDefault.chain.brand AS brand
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
	|	ISNULL(acquiringOrdersQueue.order.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)),
	|	acquiringOrdersQueue.order.holding.tokenDefault.appVersion,
	|	acquiringOrdersQueue.order.holding.tokenDefault.systemType,
	|	acquiringOrdersQueue.order.holding.tokenDefault.chain.brand
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	tempNoStatus.Ref,
	|	ISNULL(tempNoStatus.Ref.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)),
	|	ISNULL(tempNoStatus.Ref.holding.languageDefault.code, """"),
	|	ISNULL(tempNoStatus.Ref.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)),
	|	ISNULL(tempNoStatus.Ref.holding.tokenDefault.user.userCode, """"),
	|	ISNULL(tempNoStatus.Ref.holding.tokenDefault.deviceModel, """"),
	|	tempNoStatus.Ref.holding.tokenDefault,
	|	tempNoStatus.Ref.holding,
	|	tempNoStatus.Ref.acquiringRequest,
	|	tempNoStatus.state,
	|	0,
	|	tempNoStatus.Ref.holding.tokenDefault.appVersion,
	|	tempNoStatus.Ref.holding.tokenDefault.systemType,
	|	acquiringOrdersorders.Ref,
	|	acquiringOrdersorders.Ref.holding.tokenDefault.chain.brand
	|FROM
	|	tempNoStatus AS tempNoStatus
	|		LEFT JOIN Catalog.acquiringOrders.orders AS acquiringOrdersorders
	|		ON acquiringOrdersorders.uid = tempNoStatus.uid
	|		AND acquiringOrdersorders.Ref.registrationDate > tempNoStatus.registrationDate
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP tempNoStatus";
	Query.SetParameter("CurrentDate", ToUniversalTime(CurrentDate()));
	Return Query.Execute().Select();
EndFunction

Function GetParametersToSend(DataSelect, requestName)
	Parameters = new structure();
	Parameters.Insert("language", DataSelect.language);
	Parameters.Insert("authKey", string(DataSelect.tokenDefault.UUID()));
	Parameters.Insert("requestName", requestName);
	Parameters.Insert("brand", DataSelect.brand);
	Parameters.Insert("languageCode", DataSelect.languageCode);
	TokenContext = New structure();
	TokenContext.Insert("user", DataSelect.userCode);
	TokenContext.Insert("timeZone", DataSelect.timeZone);
	TokenContext.Insert("appType", DataSelect.deviceModel);
	TokenContext.Insert("appVersion", DataSelect.appVersion);
	TokenContext.Insert("systemType", DataSelect.systemType);
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
	|	logs.period < DATEADD(&currentDate, Month, -6)
	|
	|UNION ALL
	|
	|SELECT
	|	classesSchedule.Ref
	|FROM
	|	Catalog.classesSchedule AS classesSchedule
	|WHERE
	|	classesSchedule.period < DATEADD(&currentDate, Day, -30)";
	query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));
	selection = query.Execute().Select();
	While selection.Next() Do
		objectLog = selection.ref.GetObject();
		objectLog.Delete();
	EndDo;
EndProcedure

Procedure sendGetRestriction() Export
	getUsersRestrictions();
	sendRestrictions();
EndProcedure

Procedure getUsersRestrictions() Export
	query = New Query();
	query.Text = "SELECT DISTINCT
	|	restrictions.chain AS chain,
	|	ISNULL(restrictions.chain.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)) AS language,
	|	ISNULL(restrictions.chain.holding.languageDefault.Code, """") AS languageCode,
	|	ISNULL(restrictions.chain.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)) AS timeZone,
	|	ISNULL(restrictions.chain.holding.tokenDefault.user.userCode, """") AS userCode,
	|	ISNULL(restrictions.chain.holding.tokenDefault.deviceModel, """") AS deviceModel,
	|	restrictions.chain.holding.tokenDefault AS tokenDefault,
	|	restrictions.chain.holding AS holding,
	|	restrictions.chain.holding.tokenDefault.appVersion AS appVersion,
	|	restrictions.chain.holding.tokenDefault.systemType AS systemType
	|FROM
	|	Catalog.restrictions AS restrictions";
	selectionChain = query.Execute().Select();
	while selectionChain.Next() do
		requestStruct = new Structure();
		requestStruct.Insert("chainId", XMLString(selectionChain.chain));
		parameters = GetParametersToSend(selectionChain, "getRestrictions");
		parameters.Insert("internalRequestMethod", 	True);
	    parameters.Insert("requestStruct", 			requestStruct);
	    General.executeRequestMethod(parameters);
	    Service.logRequestBackground(parameters);
	    if parameters.error = "" then
	    	struct = HTTP.decodeJSON(parameters.answerBody, Enums.JSONValueTypes.structure);
	    	tableValues = getTableValuesUsersRestrictions(struct, selectionChain.chain);
	    	loadTableValuesToRestrictionUsers(tableValues, selectionChain.chain);
	    EndIf;
	EndDo;
EndProcedure

Procedure sendRestrictions()
	
	query = New Query();
	query.Text = "SELECT
	|	restrictionsChanges.Ref,
	|	restrictionsChanges.Ref.chain AS chain,
	|	restrictionsChanges.Ref.Presentation AS name,
	|	ISNULL(restrictionsChanges.Ref.chain.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)) AS language,
	|	ISNULL(restrictionsChanges.Ref.chain.holding.languageDefault.Code, """") AS languageCode,
	|	ISNULL(restrictionsChanges.Ref.chain.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)) AS timeZone,
	|	ISNULL(restrictionsChanges.Ref.chain.holding.tokenDefault.user.userCode, """") AS userCode,
	|	ISNULL(restrictionsChanges.Ref.chain.holding.tokenDefault.deviceModel, """") AS deviceModel,
	|	restrictionsChanges.Ref.chain.holding.tokenDefault AS tokenDefault,
	|	restrictionsChanges.Ref.chain.holding AS holding,
	|	restrictionsChanges.Ref.chain.holding.tokenDefault.appVersion AS appVersion,
	|	restrictionsChanges.Ref.chain.holding.tokenDefault.systemType AS systemType
	|FROM
	|	Catalog.restrictions.Changes AS restrictionsChanges
	|TOTALS
	|	MAX(language) AS language,
	|	MAX(languageCode) AS languageCode,
	|	MAX(timeZone) AS timeZone,
	|	MAX(userCode) AS userCode,
	|	MAX(deviceModel) AS deviceModel,
	|	MAX(tokenDefault) AS tokenDefault,
	|	MAX(holding) AS holding,
	|	MAX(appVersion) AS appVersion,
	|	MAX(systemType) AS systemType
	|BY
	|	chain";
	selectionChain = query.Execute().Select(QueryResultIteration.ByGroups);
	unit = ExchangePlans.restrictionChanges.FindByCode("RC");
	while selectionChain.Next() do
		array = new array();
		selection = selectionChain.Select();
		while selection.Next() do
			restrictionStructure = new structure();
			restrictionStructure.Insert("uid", 		XMLString(selection.ref));
			restrictionStructure.Insert("chainId", 	XMLString(selection.chain));
			restrictionStructure.Insert("name", 	selection.name);
			array.Add(restrictionStructure);
		EndDo;
		requestStruct = new Structure();
		requestStruct.Insert("restrictionsList", array);
		parameters = GetParametersToSend(selectionChain, "sendRestrictions");
		parameters.Insert("internalRequestMethod", 	True);
	    parameters.Insert("requestStruct", 			requestStruct);
	    General.executeRequestMethod(parameters);
	    Service.logRequestBackground(parameters);
	    if parameters.error = "" then
	    	selection.Reset();
	    	while selection.Next() do
	    		ExchangePlans.DeleteChangeRecords(unit, selection.ref);
	    	EndDo;
	    EndIf;
	EndDo;
	 
EndProcedure

Function getTableValuesUsersRestrictions(struct, chain)
	TableValues = getValueTableStruct();
	for each value in struct do
		newString = TableValues.Add();
		newString.restriction = Service.getRef(value.restrictionsId, Type("CatalogRef.restrictions"));
		newString.user = Service.getRef(value.userId, Type("CatalogRef.users"));
		newString.chain = chain;
	EndDo;
	Return TableValues;
EndFunction
 
Function getValueTableStruct()
	table = New ValueTable();
	table.Columns.Add("user", New TypeDescription("CatalogRef.users"));
	table.Columns.Add("restriction", New TypeDescription("CatalogRef.restrictions"));
	table.Columns.Add("chain", New TypeDescription("CatalogRef.chains"));
	Return table;
EndFunction

Procedure loadTableValuesToRestrictionUsers(tableValues, chain)
	recordSet = informationRegisters.usersRestriction.CreateRecordSet();
	recordSet.Filter.chain.Set(chain, true);
	if tableValues.Count()>0 then
		recordSet.Load(tableValues);
	EndIf;
	recordSet.Write();
EndProcedure

Procedure loadPolls() export
	
	query = New Query;
	query.Text = "SELECT
	             |	НазначениеОпросов.Ref AS Poll,
	             |	НазначениеОпросов.chain.holding AS holding,
	             |	НазначениеОпросов.ДатаНачала AS startDate,
	             |	НазначениеОпросов.ДатаОкончания AS endDate
	             |FROM
	             |	Document.НазначениеОпросов AS НазначениеОпросов
	             |WHERE
	             |	&startDate BETWEEN НазначениеОпросов.ДатаНачала AND НазначениеОпросов.ДатаОкончания
	             |TOTALS BY
	             |	holding";
	query.SetParameter("startDate", ToUniversalTime(BegOfDay(CurrentDate()-86400)));
	query.SetParameter("endDate", ToUniversalTime(EndOfDay(CurrentDate()-86400)));
	selectionHolding = query.Execute().Select(QueryResultIteration.ByGroups);
	
	While selectionHolding.Next() do
		selection = selectionHolding.Select();
		while selection.Next() do
			pollStructure = New Structure;
			pollStructure.Insert("uid",			XMLString(selection.Poll));
			pollStructure.Insert("startDate", 	XMLString(selection.startDate));
			pollStructure.Insert("endDate",		XMLString(selection.endDate));
			GetKPOData(selectionHolding.holding, pollStructure, "addPoll");
		EndDo;
	EndDo;
	
	query.Text = "SELECT
	|	Анкета.Респондент AS Client,
	|	Анкета.Date AS Date,
	|	Анкета.Опрос AS Poll,
	|	Анкета.Опрос.chain.holding AS holding
	|FROM
	|	Document.Анкета AS Анкета
	|WHERE
	|	Анкета.Date BETWEEN &startDate AND &endDate
	|TOTALS
	|BY
	|	holding";
	
	selectionHolding = query.Execute().Select(QueryResultIteration.ByGroups);
	
	While selectionHolding.Next() do
		selection = selectionHolding.Select();
		mas = new Array;
		while selection.Next() do
			pollStructure = New Structure;
			pollStructure.Insert("customerId",	XMLString(selection.Client));
			pollStructure.Insert("pollId", 		XMLString(selection.Poll));
			pollStructure.Insert("date",		XMLString(selection.Date));
			mas.Add(pollStructure);
		EndDo;
		structure = new Structure;
		GetKPOData(selectionHolding.holding, mas,"pollResult");
	EndDo;
	
EndProcedure

function GetKPOData(holding, requestStruct, requestName)
	Query = New Query();
	Query.Text = "SELECT
	|	holding.languageDefault AS language,
	|	holding.languageDefault.Code AS languageCode,
	|	holding.tokenDefault.timeZone AS timeZone,
	|	holding.tokenDefault.user.userCode AS userCode,
	|	holding.tokenDefault.deviceModel AS deviceModel,
	|	holding.tokenDefault AS tokenDefault,
	|	holding.ref AS holding,
	|	holding.tokenDefault.appVersion AS appVersion,
	|	holding.tokenDefault.systemType AS systemType,
	|	holding.tokenDefault.chain.brand AS brand
	|FROM
	|	Catalog.holdings AS holding
	|WHERE
	|	holding.Ref = &holding";
	Query.SetParameter("holding", holding);
	selection = Query.Execute().Select();
	If selection.Next() Then
		requestParameters = GetParametersToSend(selection, requestName);
		requestParameters.Insert("requestStruct", requestStruct);
		requestParameters.Insert("internalRequestMethod", True);
		GeneralCallServer.executeRequestMethod(requestParameters);		
	EndIf;	
EndFunction

// SC-098870 
Procedure sendThread() export
  
  query = New Query(); 
  query.Text = "SELECT DISTINCT
  |	ThreadChanges.Ref AS Ref,
  |	restrictions.chain AS chain,
  |	ISNULL(restrictions.chain.holding.languageDefault, VALUE(Catalog.languages.EmptyRef)) AS language,
  |	ISNULL(restrictions.chain.holding.languageDefault.Code, """") AS languageCode,
  |	ISNULL(restrictions.chain.holding.tokenDefault.timeZone, VALUE(catalog.timeZones.EmptyRef)) AS timeZone,
  |	ISNULL(restrictions.chain.holding.tokenDefault.user.userCode, """") AS userCode,
  |	ISNULL(restrictions.chain.holding.tokenDefault.deviceModel, """") AS deviceModel,
  |	restrictions.chain.holding.tokenDefault AS tokenDefault,
  |	restrictions.chain.holding AS holding,
  |	restrictions.chain.holding.tokenDefault.appVersion AS appVersion,
  |	restrictions.chain.holding.tokenDefault.systemType AS systemType,
  |	"""""""" as brand
  |FROM
  |	Catalog.restrictions AS restrictions,
  |	Catalog.Thread.Changes AS ThreadChanges
  |WHERE
  |	ThreadChanges.Node = &Node";
  
  unit = ExchangePlans.threadsToSend.FindByCode("TH"); /// С кодом нужно определиться ????????????? 
  query.SetParameter("Node", unit); 
  
  selection = query.Execute().Select();
  requestStruct = New Structure();
  array = new array();
  
  While selection.Next() Do
  		HeaderStruct  = New Structure();
  		TableStruct   = New Structure();
   		OutputStruct  = New Structure("Header,Tables");
   		
   		HeaderStruct.Insert("phone", selection.Ref.phone);
		HeaderStruct.Insert("login", selection.Ref.login); 
		
		TableStruct.Insert("Tags", selection.Ref.ThreadTags.UnloadColumn("Tag"));
		
		ArrayMessages = New Array();
		TM = selection.Ref.ThreadMessages;
		For Each StrMessage In TM Do
			SrtStruct = New Structure("Message,ResponseTime",StrMessage.Message,"");
			ArrayMessages.Add(SrtStruct);		
		EndDo;
		TableStruct.Insert("Messages", ArrayMessages);
		
		OutputStruct.Insert("Header", HeaderStruct);
		OutputStruct.Insert("Tables", TableStruct);
		array.Add(OutputStruct);
		
		requestStruct.Insert("array", array);
    		
		parameters = GetParametersToSend(selection, "managerCorrespondence");
		parameters.Insert("internalRequestMethod", 	True);
		parameters.Insert("requestStruct", 			requestStruct);
		General.executeRequestMethod(parameters);
		Service.logRequestBackground(parameters);

		if parameters.error = "" then
			ExchangePlans.DeleteChangeRecords(unit, selection.ref);
		EndIf;
  EndDo;
  
EndProcedure
//