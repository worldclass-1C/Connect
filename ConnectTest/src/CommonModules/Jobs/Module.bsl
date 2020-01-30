
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

Procedure РассчитатьПоказатели() Export
	Service.РассчитатьПоказатели();
EndProcedure

Procedure alertSourceInformation() Export
	Service.informationSourceAlert();
EndProcedure

Procedure ПроверитьАктуальностьТокенов() Export
	Service.ПроверитьАктуальностьТокенов();
EndProcedure

Procedure CheckAcquiringStatus() Export
	OrdersToCheck = GetOrdersToCheck();
	While OrdersToCheck.Next() Do
		response = Acquiring.executeRequest("check", OrdersToCheck.order);
		If response = Undefined Then
			  Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.send);		
		Else
			If response.errorCode = "" Then
				Acquiring.addOrderToQueue(OrdersToCheck.order, Enums.acquiringOrderStates.success);
				Acquiring.executeRequestBackground("process", OrdersToCheck.order);
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
	|ORDER BY
	|	acquiringOrdersQueue.registrationDate";
	Query.Parameters.Insert("CurrentDate", ToUniversalTime(CurrentDate()));
	Return Query.Execute().Select();
EndFunction
