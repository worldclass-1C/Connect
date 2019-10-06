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

Procedure sendPush(parameters) Export

	If parameters.deviceToken <> "" Then
		notification = New DeliverableNotification;
		notification.Title = parameters.title;
		notification.Text = parameters.text;
		notification.Badge = parameters.badge;
		notification.Recipients.Add(pushSubscriber(parameters.deviceToken, parameters.subscriberType));
		notification.Data = pushData(parameters.action, parameters.objectId, parameters.objectType, parameters.message);		

		DeliverableNotificationSend.Send(notification, GeneralReuse.getAuthorizationKey(parameters.systemType, parameters.certificate));
		If Not parameters.message.isEmpty() Then
			logMassage(parameters.message, parameters.informationChannel, Enums.messageStatuses.sent, "", ToUniversalTime(CurrentDate()), parameters.token);
		EndIf;
	EndIf;

	If Not parameters.message.isEmpty() Then
		ExchangePlans.DeleteChangeRecords(parameters.nodeMessagesToSend, parameters.message);
	EndIf;

EndProcedure

Procedure sendSMS(parameters) Export

	answer = New Structure("id, messageStatus, error, period", "", Enums.messageStatuses.notSent, "", Undefined);

	If parameters.SMSProvider = Enums.SMSProviders.Rapporto Then
		answer = Rapporto.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.Smstraffic Then
		answer = SMSTraffic.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.IDMkg Then
		answer = СIDMkg.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.Stramedia Then
		answer = Stramedia.sendSMS(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.SmsGold Then
		answer = SmsGold.sendSMS(parameters, answer);
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
			sendParameters.Добавить(nodeMessagesToSend);
			sendParameters.Добавить(nodeMessagesToCheckStatus);
			sendParameters.Добавить(selection.holding);
			sendParameters.Добавить(informationChannel);
			BackgroundJobs.Execute(procedureName, sendParameters, New UUID, "sendMessages");
		EndDo;
	EndIf;

EndProcedure

Procedure checkSmsStatus(parameters) Export

	answer = New Structure("messageStatus, error, period", Enums.messageStatuses.notDelivered, "", Undefined);

	If parameters.SMSProvider = Enums.SMSProviders.Rapporto Then
		answer = Rapporto.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.Smstraffic Then
		answer = SMSTraffic.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.IDMkg Then
		answer = СIDMkg.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.Stramedia Then
		answer = Stramedia.checkSmsStatus(parameters, answer);
	ElsIf parameters.SMSProvider = Enums.SMSProviders.SmsGold Then
		answer = SmsGold.checkSmsStatus(parameters, answer);
	EndIf;

	Если answer.messageStatus = Enums.messageStatuses.delivered
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
	record = InformationRegisters.messagesLogs.CreateRecordManager();
	record.period = ToUniversalTime(CurrentDate());
	record.message = message;
	record.informationChannel = informationChannel;
	record.messageStatus = messageStatus;
	record.error = error;
	record.recordDate = ?(recordDate = Undefined, Date(1, 1, 1), recordDate);
	record.token = token;
	record.Write();
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
	|	ISNULL(gymSMSProviders.SMSProvider, SMSProviders.SMSProvider) AS SMSProvider,
	|	ISNULL(gymSMSProviders.server, SMSProviders.server) AS server,
	|	ISNULL(gymSMSProviders.port, SMSProviders.port) AS port,
	|	ISNULL(gymSMSProviders.user, SMSProviders.user) AS user,
	|	ISNULL(gymSMSProviders.password, SMSProviders.password) AS password,
	|	ISNULL(gymSMSProviders.timeout, SMSProviders.timeout) AS timeout,
	|	ISNULL(gymSMSProviders.secureConnection, SMSProviders.secureConnection) AS secureConnection,
	|	ISNULL(gymSMSProviders.useOSAuthentication, SMSProviders.useOSAuthentication) AS useOSAuthentication,
	|	ISNULL(gymSMSProviders.senderName, SMSProviders.senderName) AS senderName
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
	|		ON (&holding = gymSMSProviders.holding)
	|		AND (gymSMSProviders.gym = messages.Ref.gym)
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
	|		ON (&holding = SMSProviders.holding)
	|		AND (SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
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
	|	ISNULL(gymSMSProviders.SMSProvider, SMSProviders.SMSProvider) AS SMSProvider,
	|	ISNULL(gymSMSProviders.server, SMSProviders.server) AS server,
	|	ISNULL(gymSMSProviders.port, SMSProviders.port) AS port,
	|	ISNULL(gymSMSProviders.user, SMSProviders.user) AS user,
	|	ISNULL(gymSMSProviders.password, SMSProviders.password) AS password,
	|	ISNULL(gymSMSProviders.timeout, SMSProviders.timeout) AS timeout,
	|	ISNULL(gymSMSProviders.secureConnection, SMSProviders.secureConnection) AS secureConnection,
	|	ISNULL(gymSMSProviders.useOSAuthentication, SMSProviders.useOSAuthentication) AS useOSAuthentication,
	|	ISNULL(gymSMSProviders.senderName, SMSProviders.senderName) AS senderName
	|FROM
	|	Catalog.messages AS messages
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
	|		ON (messages.holding = gymSMSProviders.holding)
	|		AND (gymSMSProviders.gym = messages.Ref.gym)
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
	|		ON (messages.holding = SMSProviders.holding)
	|		AND (SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
	|WHERE
	|	messages.ref = &message
	|ORDER BY
	|	messages.priority";

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
	|	ISNULL(gymSMSProviders.SMSProvider, SMSProviders.SMSProvider) AS SMSProvider,
	|	ISNULL(gymSMSProviders.server, SMSProviders.server) AS server,
	|	ISNULL(gymSMSProviders.port, SMSProviders.port) AS port,
	|	ISNULL(gymSMSProviders.user, SMSProviders.user) AS user,
	|	ISNULL(gymSMSProviders.password, SMSProviders.password) AS password,
	|	ISNULL(gymSMSProviders.timeout, SMSProviders.timeout) AS timeout,
	|	ISNULL(gymSMSProviders.secureConnection, SMSProviders.secureConnection) AS secureConnection,
	|	ISNULL(gymSMSProviders.useOSAuthentication, SMSProviders.useOSAuthentication) AS useOSAuthentication
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS gymSMSProviders
	|		ON (&holding = gymSMSProviders.holding)
	|		AND (gymSMSProviders.gym = messages.Ref.gym)
	|		LEFT JOIN InformationRegister.holdingsConnectionsSMSProviders AS SMSProviders
	|		ON (&holding = SMSProviders.holding)
	|		AND (SMSProviders.gym = VALUE(Catalog.gyms.EmptyRef))
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
	|	tokens.chain AS chain,
	|	tokens.appType AS appType,
	|	tokens.systemType AS systemType,
	|	messages.Ref.user AS user,
	|	CASE
	|		WHEN tokens.systemType = VALUE(Enum.systemTypes.Android)
	|			THEN ""GCM""
	|		WHEN tokens.systemType = VALUE(Enum.systemTypes.iOS)
	|			THEN ""APNS""
	|		ELSE """"
	|	END AS subscriberType
	|INTO TT
	|FROM
	|	Catalog.messages.Changes AS messages
	|		LEFT JOIN Catalog.tokens AS tokens
	|		ON messages.Ref.user = tokens.user
	|		AND messages.Ref.token <> tokens.Ref
	|		AND tokens.lockDate = DATETIME(1, 1, 1)
	|WHERE
	|	messages.Node = &nodeMessagesToSend
	|ORDER BY
	|	messages.Ref.priority
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.user AS user,
	|	COUNT(DISTINCT messages.Ref) AS count
	|INTO TT_unreadMessages
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.messages AS messages
	|		ON TT.user = Messages.user
	|		LEFT JOIN Catalog.messages.channelPriorities AS messagesChannelPriorities
	|		ON Messages.Ref = messagesChannelPriorities.Ref
	|		LEFT JOIN InformationRegister.messagesLogs.SliceLast AS messagesLogs
	|		ON Messages.Ref = messagesLogs.message
	|WHERE
	|	messagesChannelPriorities.channel = &informationChannel
	|	AND ISNULL(messagesLogs.messageStatus, VALUE(Enum.messageStatuses.EmptyRef)) <> VALUE(Enum.messageStatuses.read)
	|GROUP BY
	|	TT.user
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.message AS message,
	|	TT.title AS title,
	|	TT.text AS text,
	|	TT.action AS action,
	|	TT.objectId AS objectId,
	|	TT.objectType AS objectType,
	|	TT.nodeMessagesToSend AS nodeMessagesToSend,
	|	TT.systemType AS systemType,
	|	TT.subscriberType AS subscriberType,
	|	TT.deviceToken AS deviceToken,
	|	TT.token AS token,
	|	&informationChannel AS informationChannel,
	|	ISNULL(chainAppCertificates.certificate, appCertificates.certificate) AS certificate,
	|	ISNULL(unreadMessages.count, 0) AS badge
	|FROM
	|	TT AS TT
	|		LEFT JOIN InformationRegister.appCertificates AS chainAppCertificates
	|		ON TT.chain = chainAppCertificates.chain
	|		AND TT.appType = chainAppCertificates.appType
	|		AND TT.systemType = chainAppCertificates.systemType
	|		LEFT JOIN InformationRegister.appCertificates AS appCertificates
	|		ON appCertificates.chain = VALUE(Catalog.chains.EmptyRef)
	|		AND TT.appType = appCertificates.appType
	|		AND TT.systemType = appCertificates.systemType
	|		LEFT JOIN TT_unreadMessages AS unreadMessages
	|		ON TT.user = unreadMessages.user";

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