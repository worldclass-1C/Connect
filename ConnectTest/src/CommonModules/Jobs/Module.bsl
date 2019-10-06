
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
	Service.alertSourceInformation();
EndProcedure

Procedure ПроверитьАктуальностьТокенов() Export
	Service.ПроверитьАктуальностьТокенов();
EndProcedure


