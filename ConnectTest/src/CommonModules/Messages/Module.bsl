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
		
		data = New Structure();
		data.Insert("action", parameters.action);
		If isNotBackgroundPush Then
			data.Insert("objectId", parameters.objectId);
			data.Insert("objectType", parameters.objectType);
			data.Insert("noteId", XMLString(parameters.message));
		EndIf;
		
		body = New Structure();
		body.Insert("data", data);
		If isNotBackgroundPush Then			
			body.Insert("title", parameters.title);
			body.Insert("sound", "default");
			body.Insert("text", parameters.text);
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
		request.Headers.Insert("Authorization", "key=AAAA7ccmJw0:APA91bHVSb1GF1C9lUqet0gvrbT1fqbPmbU6Vy7VYpwBUBQmEVN8vF2E8WdxFdaKYOBJw5uagvFFGQF-ELc-VtMsr62gK1JiBsEixEQ6PpgLdUznExIJEtonsjSgezqjq4k_xC4UXA1l");
		request.SetBodyFromString(HTTP.encodeJSON(messageParam), TextEncoding.UTF8);

		response = HTTPConnection.Post(request);		
		If response.StatusCode = 200 Then
			answerBody = HTTP.decodeJSON(response.GetBodyAsString(), Enums.JSONValueTypes.structure);
			If answerBody.Property("success") And answerBody.success = 1 Then
				pushStatus = Enums.messageStatuses.sent;
			EndIf;
		EndIf;
				
	EndIf;
				  	
	If Not parameters.message.isEmpty() Then		
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
		logMassage(parameters.message, parameters.informationChannel, pushStatus, "", ToUniversalTime(CurrentDate()), parameters.token);
		If pushStatus = Enums.messageStatuses.notSent Then
			useNextInformationChannel(parameters.message, parameters.informationChannel);
		EndIf;
	EndIf;
	
	Return pushStatus; 
	
EndFunction

Procedure sendSMS(parameters) Export

	answer = New Structure("id, messageStatus, error, period", "", Enums.messageStatuses.notSent, "", Undefined);

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
	ElsIf parameters.SMSProvider = Enums.SmsProviders.MTSComminicator Then
		answer = SmsMtsCommunicator.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Prontosms Then
		answer = SmsPronto.sendSMS(parameters, answer);
	EndIf;

	If answer.messageStatus = Enums.messageStatuses.sent Then
		addMessageId(parameters.message, Enums.informationChannels.sms, answer.id);
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
		ExchangePlans.RecordChanges(parameters.nodeMessagesToCheckStatus, parameters.message);
	ElsIf answer.messageStatus = Enums.messageStatuses.notSent Then
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
		useNextInformationChannel(parameters.message, Enums.informationChannels.sms);
	EndIf;

	logMassage(parameters.message, Enums.informationChannels.sms, answer.messageStatus, answer.error, answer.period);

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
	ElsIf parameters.SMSProvider = Enums.SmsProviders.MTSComminicator Then
		answer = SmsMtsCommunicator.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SmsProviders.Prontosms Then
		answer = SmsPronto.checkSmsStatus(parameters, answer);
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

	If answer.messageStatus = Enums.messageStatuses.delivered
			Or parameters.messageAge > 2 Then
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
		recordDate = Undefined, token = Undefined) Export
//	record = InformationRegisters.messagesLogs.CreateRecordManager();
//	record.period = ToUniversalTime(CurrentDate());
//	record.message = message;
//	record.informationChannel = informationChannel;
//	record.messageStatus = messageStatus;
//	record.error = error;
//	record.recordDate = ?(recordDate = Undefined, Date(1, 1, 1), recordDate);
//	record.token = token;
//	record.Write();
	record = Documents.messageLogs.CreateDocument();
	record.date								= ToUniversalTime(CurrentDate());
	record.message							= message;
	record.token								= token;
	record.messageStatus				= messageStatus;
	record.error 								= error;
	record.informationChannel	= informationChannel;
	record.recordDate 					= ?(recordDate = Undefined, Date(1, 1, 1), recordDate);
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
	query.text = "SELECT
	|	DATEDIFF(messages.Ref.registrationDate, &currentDate, Day) AS messageAge,
	|	&currentDate AS currentDate,
	|	messages.Ref AS message,
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
	|		LEFT JOIN InformationRegister.messagesId AS messagesId
	|		ON messages.Ref = messagesId.message
	|		AND (messagesId.informationChannel = VALUE(Enum.informationChannels.sms))
	|WHERE
	|	messages.Node = &nodeMessagesToCheckStatus
	|	И messages.Ref.holding = &holding";

	query.SetParameter("nodeMessagesToCheckStatus", nodeMessagesToCheckStatus);
	query.SetParameter("holding", holding);
	query.SetParameter("currentDate", ToUniversalTime(CurrentDate()));

	selection = query.Execute().Select();

	While selection.Next() Do
		Messages.checkSmsStatus(selection);
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
	|	&nodeMessagesToSend AS nodeMessagesToSend,
	|	ISNULL(tokens.Ref, VALUE(Catalog.tokens.EmptyRef)) AS token,
	|	ISNULL(tokens.deviceToken, """") AS deviceToken,
	|	ISNULL(tokens.systemType, VALUE(Enum.systemTypes.EmptyRef)) AS systemType,
	|	messages.Ref.user AS user
	|INTO TT
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN Catalog.tokens AS tokens
	|		ON messages.Ref.user = tokens.user
	|		AND messages.Ref.token <> tokens.Ref
	|		AND tokens.lockDate = DATETIME(1, 1, 1)
	|WHERE
	|	messages.Node = &nodeMessagesToSend
	|	AND messages.Ref.appType = &appType
	|ORDER BY
	|	messages.Ref.priority
	|;
	|
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
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.message AS message,
	|	TT.title AS title,
	|	TT.text AS text,
	|	TT.action AS action,
	|	TT.objectId AS objectId,
	|	TT.objectType AS objectType,
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
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTunread";

	query.SetParameter("nodeMessagesToSend", nodeMessagesToSend);
	query.SetParameter("holding", holding);
	query.SetParameter("informationChannel", informationChannel);

	If informationChannel = Enums.informationChannels.pushEmployee Then
		query.SetParameter("appType", Enums.appTypes.Employee);
	ElsIf informationChannel = Enums.informationChannels.pushCustomer Then
		query.SetParameter("appType", Enums.appTypes.Customer);
	EndIf;

	selection = query.Execute().Select();

	While selection.Next() Do
		If selection.deviceToken = "" Then
			ExchangePlans.DeleteChangeRecords(selection.nodeMessagesToSend, selection.message);
			useNextInformationChannel(selection.message, selection.informationChannel);
			logMassage(selection.message, selection.informationChannel, Enums.messageStatuses.notSent, "", ToUniversalTime(CurrentDate()), selection.token);
		Else
			Messages.sendPush(selection);
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