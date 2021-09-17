Function pushSubscriber(DeviceID, subscriberType) Export
	xdtoSubscriber = XDTOFactory.Create(XDTOFactory.Type("http://v8.1c.ru/8.3/data/ext", "DeliverableNotificationSubscriberID"));
	xdtoSubscriber.DeviceID = DeviceID;
	xdtoSubscriber.SubscriberType = XDTOFactory.Create(XDTOFactory.Type("http://v8.1c.ru/8.3/data/ext", "DeliverableNotificationSubscriberType"), subscriberType);
	newXDTOSerializer = New XDTOSerializer(XDTOFactory);
	Return newXDTOSerializer.ReadXDTO(xdtoSubscriber);
EndFunction

Function newMessage(messageData, sendImmediately = False) Export

	messageObject = Catalogs.messages.CreateItem();

	messageObject.objectId = ?(messageData.Property("objectId"), messageData.objectId, "");
	messageObject.objectType = ?(messageData.Property("objectType"), messageData.objectType, "");
	messageObject.action = ?(messageData.Property("action"), messageData.action, "");
	messageObject.registrationDate = ToUniversalTime(CurrentDate());
	messageObject.title = ?(messageData.Property("title"), messageData.title, "");
	messageObject.gym = ?(messageData.Property("gym"), messageData.gym, Catalogs.gyms.EmptyRef());
	messageObject.phone = StrReplace(?(messageData.Property("phone"), messageData.phone, ""), "+", "");
	messageObject.user = ?(messageData.Property("user"), messageData.user, Catalogs.users.EmptyRef());
	messageObject.priority = ?(messageData.Property("priority"), messageData.priority, 10000);
	messageObject.text = ?(messageData.Property("text"), messageData.text, "");
	messageObject.appType = ?(messageData.Property("appType"), messageData.appType, Enums.appTypes.EmptyRef());
	messageObject.holding = messageData.holding;
	messageObject.chain = ?(messageData.Property("chain"), messageData.chain, Catalogs.chains.EmptyRef());
	if ValueIsFilled(messageObject.gym) then
		messageObject.chain = messageObject.gym.chain;
	EndIf;

	For Each informationChannel In messageData.informationChannels Do
		newRow = messageObject.channelPriorities.Add();
		newRow.channel = informationChannel;
	EndDo;
	messageObject.Write();

	If messageObject.channelPriorities.Count() > 0 Then
		If sendImmediately then
			Messages.sendSmsImmediately(GeneralReuse.nodeMessagesToSend(informationChannel), GeneralReuse.nodeMessagesToCheckStatus(informationChannel), messageObject.Ref);
		Else
			ExchangePlans.RecordChanges(GeneralReuse.nodeMessagesToSend(messageObject.channelPriorities[0].channel), messageObject);
		EndIf;
	EndIf;

	Return messageObject.ref;

EndFunction

Function pushData(action = "", objectId = "", objectType = "",
		message = "") Export
	struct = New Structure();
	struct.Insert("action", action);
	struct.Insert("objectId", objectId);
	struct.Insert("objectType", objectType);
	struct.Insert("noteId", XMLString(message));
	Return HTTP.encodeJSON(struct);
EndFunction

Function sendPush(parameters) Export
	
	pushStatus = Enums.messageStatuses.notSent;
	
	If parameters.deviceToken <> "" Then
		
		If parameters.action <> "" And parameters.title = "" And parameters.text = "" Then
			isNotBackgroundPush = False;
		Else
			isNotBackgroundPush = True;
		EndIf;
		
		HTTPConnection = New HTTPConnection("fcm.googleapis.com/fcm/send", , , , , , New OpenSSLSecureConnection());
		body = New Structure();
		
		data = New Structure();
		data.Insert("action", parameters.action);
		If isNotBackgroundPush Then
			data.Insert("objectId", parameters.objectId);
			data.Insert("objectType", parameters.objectType);
			data.Insert("noteId", XMLString(parameters.message));
			
			If parameters.action = "updateSchedule" Then
				linkData = New Structure();
				linkData.Insert("docId", parameters.objectId);
				linkData.Insert("docType", parameters.objectType);
				linkData.Insert("gym", XMLString(parameters.gym));

				link = New Structure();
				link.Insert("route", "activityDetails");
				link.Insert("data", HTTP.encodeJSON(linkData));				
				body.Insert("link_data", link);				
			EndIf;
		EndIf;		
		
		body.Insert("data", data);
		body.Insert("action", parameters.action);
		If isNotBackgroundPush Then			
			body.Insert("title", parameters.title);
			body.Insert("sound", "default");			
			If parameters.systemType = Enums.systemTypes.iOS Then
				body.Insert("body", parameters.text);
			else
				body.Insert("text", parameters.text);
			EndIf;	
			body.Insert("badge", parameters.badge);
		EndIf;		

		messageParam = New Structure();
		messageParam.Insert("to", parameters.deviceToken);
		If parameters.systemType = Enums.systemTypes.iOS Then			
			If isNotBackgroundPush Then
				messageParam.Insert("notification", body);
			Else				
				messageParam.Insert("data", data);
				messageParam.Insert("priority", "high");
				messageParam.Insert("content_available", True);
			EndIf;
		Else
			messageParam.Insert("data", body);
		EndIf;

		request = New HTTPRequest();
		request.Headers.Insert("Content-Type", "application/json");
		request.Headers.Insert("authorization", "key=AAAA7ccmJw0:APA91bHVSb1GF1C9lUqet0gvrbT1fqbPmbU6Vy7VYpwBUBQmEVN8vF2E8WdxFdaKYOBJw5uagvFFGQF-ELc-VtMsr62gK1JiBsEixEQ6PpgLdUznExIJEtonsjSgezqjq4k_xC4UXA1l");
		request.SetBodyFromString(HTTP.encodeJSON(messageParam), TextEncoding.UTF8);

		response = HTTPConnection.Post(request);		
		If response.StatusCode = 200 Then
			answerBody = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);
			If answerBody.Property("success") And answerBody.success = 1 Then
				pushStatus = Enums.messageStatuses.sent;
			EndIf;
		EndIf;
				
	EndIf;
		
	Return pushStatus; 
	
EndFunction

Procedure sendSMS(parameters) Export

	answer = New Structure("id, messageStatus, error, period, AnswerResponseBodyForLogs", "", Enums.messageStatuses.notSent, "", Undefined, Undefined);

	If parameters.SMSProvider = Enums.SmsProviders.Rapporto Then
		answer = SmsRapporto.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Smstraffic Then
		answer = SmsTraffic.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.IDMkg Then
		answer = SmsCIDMkg.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Stramedia Then
		answer = SmsStramedia.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.SmsGold Then
		answer = SmsGold.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Megalab Then
		answer = SmsMegalab.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.IDigital Then
		answer = SmsIDigital.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.MTSCommunicator Then
		answer = SmsMtsCommunicator.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Prontosms Then
		answer = SmsPronto.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Devino Then
		answer = SmsDevino.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Smsc Then
		answer = SmsSmsc.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.P1sms Then
		answer = SmsP1sms.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.FigenSoft Then
		answer = SmsFigenSoft.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.iSms Then
		answer = SmsiSms.sendSMS(parameters, answer); 
	EndIf;

	If answer.messageStatus = Enums.messageStatuses.sent Then
		addMessageId(parameters.message, Enums.informationChannels.sms, answer.id);
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
		ExchangePlans.RecordChanges(parameters.nodeMessagesToCheckStatus, parameters.message);
	ElsIf answer.messageStatus = Enums.messageStatuses.notSent Then
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
		useNextInformationChannel(parameters.message, Enums.informationChannels.sms);
	EndIf;

	logMassage(parameters.message, Enums.informationChannels.sms, answer.messageStatus, answer.error, answer.period,,answer.AnswerResponseBodyForLogs);

EndProcedure

Procedure sendMessages(informationChannel) Export

	nodeMessagesToSend = GeneralReuse.nodeMessagesToSend(informationChannel);
	nodeMessagesToCheckStatus = GeneralReuse.nodeMessagesToCheckStatus(informationChannel);

	If informationChannel = Enums.informationChannels.sms Then
		procedureName = "Messages.sendHoldingSms";
	ElsIf informationChannel = Enums.informationChannels.pushEmployee Then
		procedureName = "Messages.sendHoldingPush";
	ElsIf informationChannel = Enums.informationChannels.pushCustomer Then
		procedureName = "Messages.sendHoldingPush";
	Else
		procedureName = "";
	EndIf;

	If procedureName <> "" Then
		query = New Query();
		query.text = "SELECT DISTINCT
		|	messagesChanges.Ref.holding AS holding
		|FROM
		|	Catalog.messages.Changes AS messagesChanges
		|WHERE
		|	messagesChanges.Node = &node";

		query.SetParameter("node", nodeMessagesToSend);
		selection = query.Execute().Select();

		While selection.Next() Do
			sendParameters = New Array();
			sendParameters.Add(nodeMessagesToSend);
			sendParameters.Add(nodeMessagesToCheckStatus);
			sendParameters.Add(selection.holding);			
			sendParameters.Add(informationChannel);
			BackgroundJobs.Execute(procedureName, sendParameters, New UUID, "sendMessages");
		EndDo;
	EndIf;

EndProcedure

Procedure checkSmsStatus(parameters) Export

	answer = New Structure("messageStatus, error, period", Enums.messageStatuses.notDelivered, "", Undefined);

	If parameters.SMSProvider = Enums.SmsProviders.Rapporto Then
		answer = SmsRapporto.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Smstraffic Then
		answer = SmsTraffic.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.IDMkg Then
		answer = SmsCIDMkg.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Stramedia Then
		answer = SmsStramedia.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.SmsGold Then
		answer = SmsGold.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.MTSCommunicator Then
		answer = SmsMtsCommunicator.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Prontosms Then
		answer = SmsPronto.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Devino Then
		answer = SmsDevino.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Smsc Then
		answer = SmsSmsc.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.P1sms Then
		answer = SmsP1sms.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.FigenSoft Then
		answer = SmsFigenSoft.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.iSms Then 
		answer = SmsiSms.checkSmsStatus(parameters, answer);
	EndIf;

	checkSmsStatusContinuation(answer, parameters) ;

EndProcedure

Function FindMessageById(msg_id) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	DATEDIFF(messagesId.message.registrationDate, &currentDate, Day) AS messageAge,
		|	messagesId.message.Ref AS messageRef
		|FROM
		|	InformationRegister.messagesId AS messagesId
		|WHERE
		|	messagesId.id = &id";
	
	Query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));
	Query.SetParameter("id", msg_id);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	Answer = new Structure("messageRef, messageAge", Catalogs.messages.EmptyRef(), 0);
	
	While SelectionDetailRecords.Next() Do
		Answer.Insert("messageRef", SelectionDetailRecords.messageRef);
		Answer.Insert("messageAge", SelectionDetailRecords.messageAge);
	EndDo;
	
Return  Answer;
EndFunction

Procedure checkSmsStatusContinuation(answer, parameters) Export

	If answer.messageStatus = Enums.messageStatuses.delivered Then
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToCheckStatus, parameters.message);
	ElsIf answer.messageStatus = Enums.messageStatuses.notDelivered Then
		useNextInformationChannel(parameters.message, Enums.informationChannels.sms);
	EndIf;

	logMassage(parameters.message, Enums.informationChannels.sms, answer.messageStatus, answer.error, answer.period);

EndProcedure

Procedure useNextInformationChannel(message, channel)
	currentChannel = message.channelPriorities.Find(channel, "channel");
	If currentChannel <> Undefined Then
		count = message.channelPriorities.Count();
		currentChannelIndex = currentChannel.LineNumber - 1;
		If currentChannelIndex < count - 1 Then
			ExchangePlans.RecordChanges(GeneralReuse.nodeMessagesToSend(message.channelPriorities[currentChannelIndex
				+ 1].channel), message);
		EndIf;
	EndIf;
EndProcedure

Procedure logMassage(message, informationChannel, messageStatus, error,
		recordDate = Undefined, token = Undefined, AnswerResponseBodyForLogs = Undefined) Export
	
	record = Documents.messageLogs.CreateDocument();
	record.date					= ToUniversalTime(CurrentDate());
	record.message				= message;
	record.token				= token;
	record.messageStatus		= messageStatus;
	record.error 				= error;
	record.informationChannel	= informationChannel;
	record.recordDate 			= ?(recordDate = Undefined, Date(1, 1, 1), recordDate);
	If AnswerResponseBodyForLogs <> Undefined Then
		record.request 	= New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(AnswerResponseBodyForLogs.requestBody, New Deflation(9)))));
		record.response = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(AnswerResponseBodyForLogs.answerBody, 	New Deflation(9)))));
	EndIf;
	record.Write(DocumentWriteMode.Posting);
	
EndProcedure

Procedure addMessageId(message, informationChannel, id) Export
	record = InformationRegisters.messagesId.CreateRecordManager();
	record.message = message;
	record.informationChannel = informationChannel;
	record.id = id;
	record.Write();
EndProcedure

Procedure sendHoldingSms(nodeMessagesToSend,
		nodeMessagesToCheckStatus, holding, informationChannel) Export
		
	query = New Query();
	query.text = "SELECT TOP 100
	|	messages.Ref AS message,
	|	messages.Ref.phone AS phone,
	|	messages.Ref.text AS text,
	|	&nodeMessagesToSend AS nodeMessagesToSend,
	|	&nodeMessagesToCheckStatus AS nodeMessagesToCheckStatus,
	|	ISNULL(gymSMSProviders.SMSProvider, ISNULL(chainSMSProviders.SMSProvider, SMSProviders.SMSProvider)) AS SMSProvider,
	|	ISNULL(gymSMSProviders.server, ISNULL(chainSMSProviders.server, SMSProviders.server)) AS server,
	|	ISNULL(gymSMSProviders.port, ISNULL(chainSMSProviders.port, SMSProviders.port)) AS port,
	|	ISNULL(gymSMSProviders.user, ISNULL(chainSMSProviders.user, SMSProviders.user)) AS user,
	|	ISNULL(gymSMSProviders.password, ISNULL(chainSMSProviders.password, SMSProviders.password)) AS password,
	|	ISNULL(gymSMSProviders.timeout, ISNULL(chainSMSProviders.timeout, SMSProviders.timeout)) AS timeout,
	|	ISNULL(gymSMSProviders.secureConnection, ISNULL(chainSMSProviders.secureConnection,
	|		SMSProviders.secureConnection)) AS secureConnection,
	|	ISNULL(gymSMSProviders.useOSAuthentication, ISNULL(chainSMSProviders.useOSAuthentication,
	|		SMSProviders.useOSAuthentication)) AS useOSAuthentication,
	|	ISNULL(gymSMSProviders.senderName, ISNULL(chainSMSProviders.senderName, SMSProviders.senderName)) AS senderName
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
	|		ON (gymSMSProviders.holding = &holding)
	|		AND (gymSMSProviders.gym = messages.Ref.gym)
	|		AND (gymSMSProviders.gym <> VALUE(Catalog.gyms.EmptyRef))
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS chainSMSProviders
	|		ON (chainSMSProviders.holding = &holding)
	|		AND (chainSMSProviders.chain = messages.Ref.chain)
	|		AND (chainSMSProviders.chain <> VALUE(Catalog.chains.EmptyRef))
	|		AND (chainSMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
	|		ON (SMSProviders.holding = &holding)
	|		AND (SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
	|		AND (SMSProviders.chain = VALUE(Catalog.chains.EmptyRef))
	|WHERE
	|	messages.Node = &nodeMessagesToSend
	|	AND messages.Ref.holding = &holding
	|ORDER BY
	|	messages.Ref.priority";

	query.SetParameter("nodeMessagesToSend", nodeMessagesToSend);
	query.SetParameter("nodeMessagesToCheckStatus", nodeMessagesToCheckStatus);
	query.SetParameter("holding", holding);	

	selection = query.Execute().Select();

	While selection.Next() Do
		Messages.sendSMS(selection);
	EndDo;

EndProcedure

Procedure sendSmsImmediately(nodeMessagesToSend,
		nodeMessagesToCheckStatus, message) Export
		
	query = New Query();
	query.text = "SELECT
	|	messages.Ref AS message,
	|	messages.phone AS phone,
	|	messages.text AS text,
	|	&nodeMessagesToSend AS nodeMessagesToSend,
	|	&nodeMessagesToCheckStatus AS nodeMessagesToCheckStatus,
	|	ISNULL(gymSMSProviders.SMSProvider, ISNULL(chainSMSProviders.SMSProvider, SMSProviders.SMSProvider)) AS SMSProvider,
	|	ISNULL(gymSMSProviders.server, ISNULL(chainSMSProviders.server, SMSProviders.server)) AS server,
	|	ISNULL(gymSMSProviders.port, ISNULL(chainSMSProviders.port, SMSProviders.port)) AS port,
	|	ISNULL(gymSMSProviders.user, ISNULL(chainSMSProviders.user, SMSProviders.user)) AS user,
	|	ISNULL(gymSMSProviders.password, ISNULL(chainSMSProviders.password, SMSProviders.password)) AS password,
	|	ISNULL(gymSMSProviders.timeout, ISNULL(chainSMSProviders.timeout, SMSProviders.timeout)) AS timeout,
	|	ISNULL(gymSMSProviders.secureConnection, ISNULL(chainSMSProviders.secureConnection,
	|		SMSProviders.secureConnection)) AS secureConnection,
	|	ISNULL(gymSMSProviders.useOSAuthentication, ISNULL(chainSMSProviders.useOSAuthentication,
	|		SMSProviders.useOSAuthentication)) AS useOSAuthentication,
	|	ISNULL(gymSMSProviders.senderName, ISNULL(chainSMSProviders.senderName, SMSProviders.senderName)) AS senderName
	|FROM
	|	Catalog.messages AS messages
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
	|		ON (messages.holding = gymSMSProviders.holding)
	|		AND (gymSMSProviders.gym = messages.gym)
	|		AND (gymSMSProviders.gym <> VALUE(Catalog.gyms.EmptyRef))
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS chainSMSProviders
	|		ON (chainSMSProviders.holding = messages.holding)
	|		AND (chainSMSProviders.chain = messages.chain)
	|		AND (chainSMSProviders.chain <> VALUE(Catalog.chains.EmptyRef))
	|		AND (chainSMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
	|		ON (messages.holding = SMSProviders.holding)
	|		AND (SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
	|		AND (SMSProviders.chain = VALUE(Catalog.chains.EmptyRef))
	|WHERE
	|	messages.ref = &message";

	query.SetParameter("nodeMessagesToSend", nodeMessagesToSend);
	query.SetParameter("nodeMessagesToCheckStatus", nodeMessagesToCheckStatus);
	query.SetParameter("message", message);	
	selection = query.Execute().Select();
	While selection.Next() Do
		Messages.sendSMS(selection);
	EndDo;

EndProcedure

Procedure checkHoldingSmsStatus(nodeMessagesToCheckStatus,
		holding) Export

	query = New Query();
		query.text = 
		"SELECT
		|	&currentDate AS currentDate,
		|	messages.Ref AS message,
		|	messages.Ref.phone AS phone,
		|	messagesId.id AS id,
		|	&nodeMessagesToCheckStatus AS nodeMessagesToCheckStatus,
		|	ISNULL(gymSMSProviders.SMSProvider, ISNULL(chainSMSProviders.SMSProvider, SMSProviders.SMSProvider)) AS SMSProvider,
		|	ISNULL(gymSMSProviders.server, ISNULL(chainSMSProviders.server, SMSProviders.server)) AS server,
		|	ISNULL(gymSMSProviders.port, ISNULL(chainSMSProviders.port, SMSProviders.port)) AS port,
		|	ISNULL(gymSMSProviders.user, ISNULL(chainSMSProviders.user, SMSProviders.user)) AS user,
		|	ISNULL(gymSMSProviders.password, ISNULL(chainSMSProviders.password, SMSProviders.password)) AS password,
		|	ISNULL(gymSMSProviders.timeout, ISNULL(chainSMSProviders.timeout, SMSProviders.timeout)) AS timeout,
		|	ISNULL(gymSMSProviders.secureConnection, ISNULL(chainSMSProviders.secureConnection,
		|		SMSProviders.secureConnection)) AS secureConnection,
		|	ISNULL(gymSMSProviders.UseOSAuthentication, ISNULL(chainSMSProviders.UseOSAuthentication,
		|		SMSProviders.UseOSAuthentication)) AS useOSAuthentication,
		|	ISNULL(gymSMSProviders.senderName, ISNULL(chainSMSProviders.senderName, SMSProviders.senderName)) AS senderName
		|INTO TemporaryTable
		|FROM
		|	Catalog.messages.Changes AS messages
		|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
		|		ON gymSMSProviders.holding = &holding
		|		AND gymSMSProviders.gym = messages.Ref.gym
		|		AND gymSMSProviders.gym <> VALUE(Catalog.gyms.EmptyRef)
		|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS chainSMSProviders
		|		ON chainSMSProviders.holding = &holding
		|		AND chainSMSProviders.chain = messages.Ref.chain
		|		AND chainSMSProviders.chain <> VALUE(Catalog.chains.EmptyRef)
		|		AND chainSMSProviders.gym = VALUE(Catalog.gyms.EmptyRef)
		|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
		|		ON SMSProviders.holding = &holding
		|		AND SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef)
		|		AND SMSProviders.chain = VALUE(Catalog.chains.EmptyRef)
		|		LEFT JOIN InformationRegister.messagesId AS messagesId
		|		ON messages.Ref = messagesId.message
		|		AND messagesId.informationChannel = VALUE(Enum.informationChannels.sms)
		|WHERE
		|	messages.Node = &nodeMessagesToCheckStatus
		|	AND messages.Ref.holding = &holding
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemporaryTable.currentDate AS currentDate,
		|	TemporaryTable.message AS message,
		|	COUNT(messageLogs.messageStatus) - 1 AS AttemptCount,
		|	MAX(messageLogs.Date) AS LastAttemptDate,
		|	TemporaryTable.id AS id,
		|	TemporaryTable.nodeMessagesToCheckStatus AS nodeMessagesToCheckStatus,
		|	TemporaryTable.SMSProvider AS SMSProvider,
		|	TemporaryTable.server AS server,
		|	TemporaryTable.port AS port,
		|	TemporaryTable.user AS user,
		|	TemporaryTable.password AS password,
		|	TemporaryTable.timeout AS timeout,
		|	TemporaryTable.secureConnection AS secureConnection,
		|	TemporaryTable.useOSAuthentication AS useOSAuthentication,
		|	TemporaryTable.senderName AS senderName,
		|	TemporaryTable.phone
		|INTO TemporaryTable1
		|FROM
		|	TemporaryTable AS TemporaryTable
		|		LEFT JOIN Document.messageLogs AS messageLogs
		|		ON TemporaryTable.message = messageLogs.message
		|WHERE
		|	messageLogs.messageStatus <> VALUE(перечисление.messageStatuses.delivered)
		|GROUP BY
		|	TemporaryTable.currentDate,
		|	TemporaryTable.message,
		|	TemporaryTable.id,
		|	TemporaryTable.nodeMessagesToCheckStatus,
		|	TemporaryTable.SMSProvider,
		|	TemporaryTable.server,
		|	TemporaryTable.port,
		|	TemporaryTable.user,
		|	TemporaryTable.password,
		|	TemporaryTable.timeout,
		|	TemporaryTable.secureConnection,
		|	TemporaryTable.useOSAuthentication,
		|	TemporaryTable.senderName,
		|	TemporaryTable.phone
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemporaryTable1.currentDate AS currentDate,
		|	TemporaryTable1.message AS message,
		|	TemporaryTable1.phone,
		|	TemporaryTable1.AttemptCount AS AttemptCount,
		|	DATEDIFF(TemporaryTable1.LastAttemptDate, &currentDate, HOUR) AS HoursFromLastCheck,
		|	TemporaryTable1.id AS id,
		|	TemporaryTable1.nodeMessagesToCheckStatus AS nodeMessagesToCheckStatus,
		|	TemporaryTable1.SMSProvider AS SMSProvider,
		|	TemporaryTable1.server AS server,
		|	TemporaryTable1.port AS port,
		|	TemporaryTable1.user AS user,
		|	TemporaryTable1.password AS password,
		|	TemporaryTable1.timeout AS timeout,
		|	TemporaryTable1.secureConnection AS secureConnection,
		|	TemporaryTable1.useOSAuthentication AS useOSAuthentication,
		|	TemporaryTable1.senderName AS senderName
		|FROM
		|	TemporaryTable1 AS TemporaryTable1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TemporaryTable1";

	query.SetParameter("nodeMessagesToCheckStatus", nodeMessagesToCheckStatus);
	query.SetParameter("holding", holding);
	query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));

	selection = query.Execute().Select();

	While selection.Next() Do
		
		CheckStatusCount = Constants.CheckStatusCount.Get(); 
		
		If 0<=selection.AttemptCount<=?(CheckStatusCount = 0, 5, CheckStatusCount) Тогда
			If selection.AttemptCount <= selection.HoursFromLastCheck Тогда
				Messages.checkSmsStatus(selection);
			EndIf
		Else
			ExchangePlans.DeleteChangeRecords(nodeMessagesToCheckStatus, selection.message);	
		EndIf
		
	EndDo;

EndProcedure

Procedure sendHoldingPush(nodeMessagesToSend,
		nodeMessagesToCheckStatus, holding, informationChannel) Export

	query = New Query();
	query.text = "SELECT TOP 100
	|	messages.Ref AS message,
	|	messages.Ref.title AS title,
	|	messages.Ref.text AS text,
	|	messages.Ref.action AS action,
	|	messages.Ref.objectId AS objectId,
	|	messages.Ref.objectType AS objectType,
	|	messages.Ref.gym AS gym,
	|	&nodeMessagesToSend AS nodeMessagesToSend,
	|	MAX(ISNULL(tokens.Ref, VALUE(Catalog.tokens.EmptyRef))) AS token,
	|	ISNULL(tokens.deviceToken, """") AS deviceToken,
	|	ISNULL(tokens.systemType, VALUE(Enum.systemTypes.EmptyRef)) AS systemType,
	|	messages.Ref.user AS user
	|INTO TT
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN Catalog.tokens AS tokens
	|		ON messages.Ref.user = tokens.user
	|		AND messages.Ref.token <> tokens.Ref
	|		AND tokens.appType = &appType
	|		AND tokens.lockDate = DATETIME(1, 1, 1)
	|		AND tokens.systemType <> VALUE(Enum.systemTypes.web)
	|		AND messages.Ref.gym.brand = tokens.chain.brand
	|		AND messages.Ref.holding = tokens.holding
	|WHERE
	|	messages.Node = &nodeMessagesToSend
	|	AND messages.Ref.appType = &appType
	|	AND messages.Ref.holding = &holding
	|GROUP BY
	|	messages.Ref,
	|	messages.Ref.title,
	|	messages.Ref.text,
	|	messages.Ref.action,
	|	messages.Ref.objectId,
	|	messages.Ref.objectType,
	|	messages.Ref.user,
	|	ISNULL(tokens.deviceToken, """"),
	|	ISNULL(tokens.systemType, VALUE(Enum.systemTypes.EmptyRef))
	|ORDER BY
	|	messages.Ref.priority
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	pushStatusBalance.user,
	|	pushStatusBalance.amountBalance
	|INTO TTunread
	|FROM
	|	AccumulationRegister.pushStatus.Balance(, informationChannel = &informationChannel
	|	AND user IN
	|		(SELECT
	|			TT.user
	|		FROM
	|			TT AS TT)) AS pushStatusBalance
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.message AS message,
	|	TT.title AS title,
	|	TT.text AS text,
	|	TT.action AS action,
	|	TT.objectId AS objectId,
	|	TT.objectType AS objectType,
	|	TT.gym AS gym,
	|	TT.nodeMessagesToSend AS nodeMessagesToSend,
	|	TT.deviceToken AS deviceToken,
	|	TT.token AS token,
	|	TT.systemType AS systemType,
	|	&informationChannel AS informationChannel,
	|	ISNULL(TTunread.amountBalance, 0) AS badge
	|FROM
	|	TT AS TT
	|		LEFT JOIN TTunread AS TTunread
	|		ON TTunread.user = TT.user
	|TOTALS
	|BY
	|	message
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTunread";

	query.SetParameter("nodeMessagesToSend", nodeMessagesToSend);	
	query.SetParameter("informationChannel", informationChannel);
	query.SetParameter("holding", holding);

	If informationChannel = Enums.informationChannels.pushEmployee Then
		query.SetParameter("appType", Enums.appTypes.Employee);
	ElsIf informationChannel = Enums.informationChannels.pushCustomer Then
		query.SetParameter("appType", Enums.appTypes.Customer);
	EndIf;

	selectMessage = query.Execute().Select(QueryResultIteration.ByGroups);

	While selectMessage.Next() Do		
		pushStatus = enums.messageStatuses.notSent;
		selectDevice = selectMessage.Select();
		While selectDevice.Next() Do
			If selectDevice.deviceToken <> "" And Messages.sendPush(selectDevice) = enums.messageStatuses.sent Then
				pushStatus = enums.messageStatuses.sent;
			EndIf;
		EndDo;		
		ExchangePlans.DeleteChangeRecords(nodeMessagesToSend, selectMessage.message);
		logMassage(selectMessage.message, informationChannel, pushStatus, "", ToUniversalTime(CurrentDate()));		
		If pushStatus = enums.messageStatuses.notSent Then			
			useNextInformationChannel(selectMessage.message, informationChannel);
		EndIf;
	EndDo;

EndProcedure

Function GetMessageCallbackURL(SmsProvider) Export
	MessageCallbackURL = "";
	BaseMessageCallbackURL = Constants.BaseMessageCallbackURL.Get();
	If BaseMessageCallbackURL = "" Then
		Return MessageCallbackURL;
	Else
		Return BaseMessageCallbackURL + "/" + SmsProvider;
	EndIf
EndFunction

Function GetAnswerResponseBodyForLogs (Headers, JSONStringRequest, JSONStructureResponse) Export
	
	Parameters = New Structure();
	
	JSONWriter	= New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Headers);
	
	JSONStringHeaders = JSONWriter.Закрыть();
	
	requestBodyArray = New Array();
	requestBodyArray.Add("""Headers"":");
	requestBodyArray.Add(JSONStringHeaders);
	requestBodyArray.Add("""Body"":");
	requestBodyArray.Add(JSONStringRequest); 
	requestBody = StrConcat(requestBodyArray, Chars.LF);
	
	Parameters.Insert("requestBody", requestBody);
	
	If JSONStructureResponse <> "" Then
		JSONWriter	= New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, JSONStructureResponse);
		
		JSONStringresponse = JSONWriter.Закрыть();
		Parameters.Insert("answerBody", JSONStringresponse);
	Else
		Parameters.Insert("answerBody", "");
	Endif;
	
	Return Parameters;

EndFunction