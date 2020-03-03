Function getErrorDescription(language, erroeCode = "",
		description = "") Export

	errorDescription = New Structure("result, description", erroeCode, description);

	If erroeCode <> "" And description = "" Then
		query = New Query("SELECT
		|	errorDescriptionstranslation.description
		|FROM
		|	Catalog.errorDescriptions AS errorDescriptions
		|		LEFT JOIN Catalog.errorDescriptions.translation AS errorDescriptionstranslation
		|		ON errorDescriptions.Ref = errorDescriptionstranslation.Ref
		|		AND errorDescriptionstranslation.language = &language
		|WHERE
		|	errorDescriptions.Code = &erroeCode
		|
		|UNION ALL
		|
		|SELECT
		|	errorDescriptionstranslation.description
		|FROM
		|	Catalog.errorDescriptions AS errorDescriptions
		|		LEFT JOIN Catalog.errorDescriptions.translation AS errorDescriptionstranslation
		|		ON errorDescriptions.Ref = errorDescriptionstranslation.Ref
		|		AND errorDescriptionstranslation.language = &language
		|WHERE
		|	errorDescriptions.Code = ""System""");
		
		query.SetParameter("erroeCode", erroeCode);
		query.SetParameter("language", language);
		select = query.Execute().Select();
		select.Next();
		errorDescription.Insert("description", select.description);		

	EndIf;

	Return errorDescription;

EndFunction

Function getRecorder(day, reportPeriod)

	begOfDay	= BegOfDay(day);

	query	= New Query();
	query.Text	= "Select
	|	RegisterRecorder.ref as Ref
	|from
	|	Document.RegisterRecorder as RegisterRecorder
	|where
	|	RegisterRecorder.date = &day
	|	and RegisterRecorder.ReportPeriod = &reportPeriod";
	
	query.SetParameter("day", begOfDay);
	query.SetParameter("reportPeriod", reportPeriod);
	queryResult	= query.Execute();
		
	If queryResult.IsEmpty() Then
		docObject				= Documents.RegisterRecorder.CreateDocument();
		docObject.Date			= begOfDay;
		docObject.ReportPeriod	= reportPeriod;		
		docObject.Write();
		Return docObject.Ref;
	Else
		selection = queryResult.Select();		
		selection.Next();
		Return selection.Ref;
	EndIf;

EndFunction 

Function canSendSms(language, phone) Export
	
	universalTime		= ToUniversalTime(CurrentDate());
	
	query	= New Query();
	query.Text	= "SELECT
	|	DATEDIFF(serviceMessagesLogs.recordDate, &universalTime, MINUTE) AS minutesPassed,
	|	ISNULL(serviceMessagesLogs.quantity, 0) AS quantity,
	|	ISNULL(serviceMessagesLogs.recordDate, &universalTime) AS recordDate
	|INTO TT
	|FROM
	|	InformationRegister.serviceMessagesLogs AS serviceMessagesLogs
	|WHERE
	|	serviceMessagesLogs.phone = &phone
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TT.minutesPassed) AS minutesPassed,
	|	SUM(TT.quantity) AS quantity
	|FROM
	|	TT AS TT
	|WHERE
	|	TT.recordDate >= &recordDate
	|HAVING
	|	SUM(TT.quantity) > 0";
	
	query.SetParameter("phone", phone);
	query.SetParameter("recordDate", AddMonth(universalTime, - 1));
	query.SetParameter("universalTime", universalTime);
	
	queryResult	= query.Execute();
	
	If Not queryResult.IsEmpty() Then		
		selection = queryResult.Select();
		selection.Next();		
		If selection.quantity > 3 Then
			Return "limitExceeded";
		ElsIf selection.minutesPassed < 15 Then
			Return "messageCanNotSent";
		EndIf;				
	EndIf;
	
	Return "";

EndFunction 

Function runRequest(parameters, body, address = "") Export
	headers = New Map();
	headers.Insert("Content-Type", "application/json");	
	connection = New HTTPConnection(parameters.server, parameters.port, parameters.account, parameters.password, , parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.UseOSAuthentication);
	request = New HTTPRequest(parameters.URL + parameters.requestReceiver
		+ parameters.parametersFromURL, headers);
	If body <> "" Then
		request.SetBodyFromString(body);
	EndIf;
	response	= ?(parameters.HTTPRequestType = Enums.HTTPRequestTypes.GET, connection.Get(request), connection.Post(request));
	If address = "" Then
		Return response;
	Else
		PutToTempStorage(New Structure("statusCode, answerBody", response.statusCode, response.GetBodyAsString()), address);
	EndIf;
EndFunction

Function runRequestBackground(parameters, body) Export
	address	= PutToTempStorage("");
	array = New Array();
	array.Add(parameters);	
	array.Add(body);
	array.Add(address);	
	Return New Structure("address, BJ", address, BackgroundJobs.Execute("Service.runRequest", array, New UUID()));
EndFunction

Function checkBackgroundJobs(array) Export
	answer = New Structure();
	minStatusCode = 600;
	For Each struct In array Do
		If struct.BJ.State = BackgroundJobState.Active Then
			backgroundJob = struct.BJ.WaitForExecutionCompletion(25);
			If backgroundJob.State <> BackgroundJobState.Active Then
				response = GetFromTempStorage(struct.address);
				minStatusCode = Min(minStatusCode, response.statusCode);				
				answer.Insert(struct.attribute, HTTP.decodeJSON(response.answerBody));
			EndIf;
		Else			
			response = GetFromTempStorage(struct.address);
			minStatusCode = Min(minStatusCode, response.statusCode);				
			answer.Insert(struct.attribute, HTTP.decodeJSON(response.answerBody));
		EndIf;	
	EndDo;
	Return New Structure("statusCode, answerBody", minStatusCode, HTTP.encodeJSON(answer));
EndFunction

Function getAmountOfNumbers(number) Export	
	str	= StrReplace(number, Chars.NBSp, "");
	res	= 0;	
	For i = 1 To StrLen(str) Do
		res = res + Number(Mid(str, i, 1));		
	EndDo;
	Return res;
EndFunction

Function getStructCopy(val struct) Export
	structNew	= New Structure();	
	For Each item In struct Do
		If TypeOf(item.value) = Type("Structure") Then
			value = getStructCopy(item.value);
		ElsIf TypeOf(item.value) = Type("FixedStructure") Then
			value = getStructCopy(item.value);	
		Else
			value = item.value;
		EndIf;
		structNew.Insert(item.key, value);	
	EndDo;
	Return structNew;
EndFunction

Procedure logRequestBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);
	BackgroundJobs.Execute("Service.logRequest", array, New UUID());
EndProcedure
	
Procedure logAcquiringBackground(parameters) Export
	array	= New Array();
	array.Add(parameters);
	BackgroundJobs.Execute("Service.logAcquiring", array, New UUID());
EndProcedure
	
Procedure logRequest(parameters) Export
	requestBodyArray = New Array();
	record = Catalogs.logs.CreateItem();
	record.period = ToUniversalTime(CurrentDate());
	If parameters.Property("tokenContext") Then
		record.token = parameters.tokenContext.token;
		record.user = parameters.tokenContext.user;	
	EndIf;
	record.requestName = parameters.requestName;
	record.duration = parameters.duration;
	record.statusCode = parameters.statusCode;
	record.isError = parameters.isError;
	If Not parameters.internalRequestMethod Then
		record.brand = Enums.brandTypes[parameters.brand];
		record.ipAddress = parameters.ipAddress;
		requestBodyArray.Add("""Headers"":");
		requestBodyArray.Add(parameters.headersJSON);
	EndIf;	
	requestBodyArray.Add("""Body"":");
	requestBodyArray.Add(?(parameters.requestName = "imagePOST", "", parameters.requestBody)); 
		
	requestBody = StrConcat(requestBodyArray, Chars.LF);

	record.request = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(requestBody, New Deflation(9)))));
	record.response = New ValueStorage(Base64Value(XDTOSerializer.XMLString(New ValueStorage(parameters.answerBody, New Deflation(9)))));
		
	record.Write();
EndProcedure

Procedure logAcquiring(parameters) Export
	record = Catalogs.acquiringLogs.CreateItem();
	record.period = ToUniversalTime(CurrentDate());
	record.order = parameters.order;		
	record.requestName = parameters.requestName;
	If parameters.Property("errorCode") Then
		record.isError = parameters.errorCode <> "";
	EndIf;
	If parameters.Property("requestBody") Then
		record.requestBody = parameters.requestBody;
	EndIf;	
	If parameters.Property("response") Then			
		If TypeOf(parameters.response) = Type("Structure") Then
			record.responseBody = HTTP.encodeJSON(parameters.response);
		Else
			If record.isError Then
				record.responseBody = parameters.errorCode + " " + parameters.errorDescription;
			Else
				record.responseBody = "" + parameters.response;
			EndIf;		
		EndIf;
	EndIf;
	record.Write();
EndProcedure

Procedure informationSourceAlert() Export
	
	headers	= New Map();
	headers.Insert("Content-Type", "application/json");
		
	query	= New Query("SELECT TOP 100
	|	usersChanges.Ref.holding AS holding,
	|	usersChanges.Ref AS user,
	|	CASE
	|		WHEN tokensEmployee.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS employee,
	|	CASE
	|		WHEN tokensCustomer.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS customer
	|FROM
	|	Catalog.users.Changes AS usersChanges
	|		LEFT JOIN Catalog.tokens AS tokensEmployee
	|		ON (usersChanges.Ref = tokensEmployee.user)
	|			AND (tokensEmployee.appType = VALUE(Enum.appTypes.Employee))
	|			AND (tokensEmployee.lockDate = DATETIME(1, 1, 1))
	|		LEFT JOIN Catalog.tokens AS tokensCustomer
	|		ON (usersChanges.Ref = tokensCustomer.user)
	|			AND (tokensCustomer.appType = VALUE(Enum.appTypes.Customer))
	|			AND (tokensCustomer.lockDate = DATETIME(1, 1, 1))
	|WHERE
	|	usersChanges.Node = &Node
	|TOTALS BY
	|	holding");
	
	node	= GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn);
	query.SetParameter("node", node);
	selectHolding	= query.Execute().Select(QueryResultIteration.ByGroups);
	
	While selectHolding.next() Do		
		queryStruct = HTTP.GetRequestStructure("registerAccount", selectHolding.holding);		
		If queryStruct.count() > 0 Then			
			select = selectHolding.Select();
			While select.next() Do
				structHTTPRequest = New Structure();
				structHTTPRequest.Insert("userId", XMLString(select.user));
				structHTTPRequest.Insert("language", "en");
				structHTTPRequest.Insert("employee", select.employee);
				structHTTPRequest.Insert("customer", select.customer);
				HTTPConnection = New HTTPConnection(queryStruct.server, , queryStruct.user, queryStruct.password, , queryStruct.timeout, ?(queryStruct.secureConnection, New OpenSSLSecureConnection(), Undefined), queryStruct.UseOSAuthentication);
				HTTPRequest = New HTTPRequest(queryStruct.URL
					+ queryStruct.requestReceiver, headers);
				HTTPRequest.SetBodyFromString(HTTP.encodeJSON(structHTTPRequest));
				response = HTTPConnection.Post(HTTPRequest);
				If response.StatusCode = 200 Then
					ExchangePlans.DeleteChangeRecords(node, select.user);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
			
EndProcedure

Procedure CheckTokenValid() Export
	
	query	= New Query();
	query.text	= "SELECT
	|	tokens.Ref AS token,
	|	tokens.deviceToken AS deviceToken,
	|	CASE
	|		WHEN tokens.systemType = VALUE(Enum.systemTypes.Android)
	|			THEN ""GCM""
	|		ELSE ""APNS""
	|	END AS SubscriberType,
	|	tokens.chain AS chain,
	|	tokens.appType AS appType,
	|	tokens.systemType AS systemType
	|INTO ВТ
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.lockDate = DATETIME(1, 1, 1)
	|	AND CASE
	|		WHEN tokens.changeDate = DATETIME(1, 1, 1)
	|			THEN tokens.createDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -7)
	|		ELSE tokens.changeDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -7)
	|	END
	|	AND tokens.appType = VALUE(enum.appTypes.Customer)
	|
	|UNION ALL
	|
	|SELECT
	|	tokens.Ref AS token,
	|	tokens.deviceToken AS deviceToken,
	|	NULL,
	|	NULL,
	|	NULL,
	|	NULL
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	tokens.lockDate = DATETIME(1, 1, 1)
	|	AND CASE
	|		WHEN tokens.changeDate = DATETIME(1, 1, 1)
	|			THEN tokens.createDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -30)
	|		ELSE tokens.changeDate < DATEADD(BEGINOFPERIOD(&currentTime, day), day, -30)
	|	END
	|	AND tokens.appType = VALUE(enum.appTypes.Web)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ВТ.token AS token,
	|	ВТ.deviceToken AS deviceToken,
	|	ВТ.SubscriberType AS SubscriberType,
	|	ВТ.systemType AS systemType,
	|	ISNULL(appCertificates.certificate, appCertificatesCommon.certificate) AS certificate,
	|	ВТ.appType AS appType
	|FROM
	|	ВТ AS ВТ
	|		LEFT JOIN InformationRegister.appCertificates AS appCertificates
	|		ON ВТ.chain = appCertificates.chain
	|		AND ВТ.appType = appCertificates.appType
	|		AND ВТ.systemType = appCertificates.systemType
	|		LEFT JOIN InformationRegister.appCertificates AS appCertificatesCommon
	|		ON appCertificatesCommon.chain = VALUE(Справочник.chains.ПустаяСсылка)
	|		AND ВТ.appType = appCertificatesCommon.appType
	|		AND ВТ.systemType = appCertificatesCommon.systemType";
	
	query.SetParameter("currentTime", ToUniversalTime(CurrentDate()));
		
	select = query.Execute().Select();
		
	While select.Next() Do
		If select.deviceToken <> "" and select.appType = enums.appTypes.Customer Then
			pushStruct = New Structure();
			pushStruct.Insert("title", "");
			pushStruct.Insert("text", "");
			pushStruct.Insert("action", "registerDevice");
			pushStruct.Insert("objectId", "");
			pushStruct.Insert("objectType", "");
			pushStruct.Insert("noteId", "");
			pushStruct.Insert("deviceToken", select.deviceToken);
			pushStruct.Insert("SubscriberType", select.SubscriberType);
			pushStruct.Insert("title", "");
			pushStruct.Insert("Badge", 0);
			pushStruct.Insert("systemType", select.systemType);
			pushStruct.Insert("certificate", select.certificate);
			pushStruct.Insert("token", select.token);
			pushStruct.Insert("informationChannel", "");
		    pushStruct.Insert("message", Catalogs.messages.EmptyRef());
		    pushStatus = Messages.sendPush(pushStruct);
		    If pushStatus <> Enums.messageStatuses.sent Then
		    	Token.block(select.token);
		    EndIf;
		Else
			Token.block(select.token);
		EndIf;
   EndDo;	
	
	//Блокируем Token в МП тренера по уволенным сотрудникам	
	query	= New Query;
	query.text = "select
	|	tokens.ref as token
	|from
	|	Catalog.tokens as tokens
	|where
	|	tokens.appType = value(Enum.appTypes.Employee)
	|	И tokens.lockDate = datetime(1, 1, 1)
	|	И tokens.user.userType <> ""employee""";
	
	select	= query.Execute().Select();
	While select.Next() do
		Token.block(select.token);
	endDo;		
	
EndProcedure

Procedure CalcValues() Export
	
	//Расчет показателей по дням
	Days				= New Array;
	previousDay	= BegOfDay(ToUniversalTime(CurrentDate()) - 86400);
	
	Query	= New query;
	Query.text	= "select TOP 1
	|	RegisterRecorder.Date КАК CalcDay
	|from
	|	Document.RegisterRecorder AS RegisterRecorder
	|where
	|	RegisterRecorder.ReportPeriod = Value(Enum.reportPeriods.day)
	|ORDER BY
	|	CalcDay DESC";
	
	Result	= Query.Execute();
	If Result.IsEmpty() then
		Days.Add(previousDay);
	Else
		Selection	= Result.Select();
		Selection.Next();
		CalcDay	= Selection.CalcDay;
		While CalcDay < previousDay do
			CalcDay	= CalcDay + 86400; 
			Days.Add(CalcDay);
		enddo;		
	EndIf;	
	
	Service.CalcDaysValues(Days);	
	
	//Расчет показателей по месяцам
	Months			= New Array;
	CurrentMonth	= BegOfMonth(ToUniversalTime(CurrentDate()));	
	
	Query	= New query;
	Query.text	= "select top 1
	|	RegisterRecorder.date КАК CalcMonth,
	|	RegisterRecorder.ref КАК ref
	|from
	|	Document.RegisterRecorder КАК RegisterRecorder
	|where
	|	RegisterRecorder.ReportPeriod = Value(Enum.reportPeriods.month)
	|ORDER BY
	|	CalcMonth desc";
	
	Result	= Query.Execute();
	Если Result.IsEmpty() Тогда		
		Months.Add(CurrentMonth);
	Else
		Selection	= Result.Select();
		Selection.Next();
		CalcMonth	= Selection.CalcMonth;		
		Months.Add(CalcMonth);		
		Пока CalcMonth < CurrentMonth Цикл
			CalcMonth	= AddMonth(CalcMonth, 1);
			Months.Add(CalcMonth);
		КонецЦикла;		
	EndIf;	
	
	Service.CalcMonthsValues(Months);
	
EndProcedure	
	
Procedure CalcDaysValues(Days) Export
	For Each  Day in Days do
		CalcDayValue(Day);	
	EndDo;
EndProcedure

Procedure CalcDayValue(Day) Export
	
	RecordSet	= AccumulationRegisters.UsersValues.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(GetRecorder(Day, Enums.reportPeriods.day));
	
	Query	= New query;
	Query.text	= "SELECT
	|	Logs.period AS period,
	|	Logs.requestName AS requestName,
	|	Logs.token AS token,
	|	Logs.token.account AS account,
	|	Logs.token.holding AS holding,
	|	appAnalytics.ref AS appAnalytics,
	|	Logs.brand
	|INTO TemporaryHistory
	|FROM
	|	Catalog.logs AS Logs
	|		LEFT JOIN Catalog.appAnalytics AS appAnalytics
	|		ON Logs.token.appType = appAnalytics.appType
	|		AND Logs.token.systemType = appAnalytics.systemType
	|WHERE
	|	Logs.period BETWEEN &BeginDate AND &EndDate
	|	AND
	|	NOT appAnalytics.ref IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryHistory.period AS period,
	|	DATEDIFF(TemporaryHistory.period, MAX(ISNULL(TemporaryHistory1.period, &tomorrow)), minute) AS delta,
	|	TemporaryHistory.requestName AS requestName,
	|	TemporaryHistory.token AS token,
	|	TemporaryHistory.account AS account,
	|	TemporaryHistory.holding AS holding,
	|	TemporaryHistory.appAnalytics AS appAnalytics,
	|	TemporaryHistory.brand
	|INTO TemporarySessions
	|FROM
	|	TemporaryHistory AS TemporaryHistory
	|		LEFT JOIN TemporaryHistory AS TemporaryHistory1
	|		ON TemporaryHistory.token = TemporaryHistory1.token
	|		AND TemporaryHistory.period < TemporaryHistory1.period
	|WHERE
	|	TemporaryHistory.token <> VALUE(Catalog.tokens.emptyRef)
	|GROUP BY
	|	TemporaryHistory.period,
	|	TemporaryHistory.requestName,
	|	TemporaryHistory.token,
	|	TemporaryHistory.account,
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	TemporaryHistory.brand
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginDate AS period,
	|	TemporarySessions.holding AS holding,
	|	TemporarySessions.appAnalytics AS appAnalytics,
	|	VALUE(Enum.analyticValues.Sessions) AS analyticValue,
	|	&ReportPeriod AS ReportPeriod,
	|	COUNT(DISTINCT TemporarySessions.token) AS count,
	|	TemporarySessions.brand
	|FROM
	|	TemporarySessions AS TemporarySessions
	|WHERE
	|	TemporarySessions.delta > 30
	|GROUP BY
	|	TemporarySessions.holding,
	|	TemporarySessions.appAnalytics,
	|	VALUE(Enum.analyticValues.Sessions),
	|	TemporarySessions.brand
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(Enum.analyticValues.registrations),
	|	&ReportPeriod,
	|	COUNT(DISTINCT TemporaryHistory.account),
	|	TemporaryHistory.brand
	|FROM
	|	TemporaryHistory AS TemporaryHistory
	|WHERE
	|	TemporaryHistory.account.registrationDate BETWEEN &BeginDate AND &EndDate
	|GROUP BY
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(Enum.analyticValues.registrations),
	|	TemporaryHistory.brand
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(enum.analyticValues.activeUsers),
	|	&ReportPeriod,
	|	COUNT(DISTINCT TemporaryHistory.account),
	|	TemporaryHistory.brand
	|FROM
	|	TemporaryHistory AS TemporaryHistory
	|GROUP BY
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(enum.analyticValues.activeUsers),
	|	TemporaryHistory.brand
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(enum.analyticValues.events),
	|	&ReportPeriod,
	|	SUM(CASE
	|		WHEN TemporaryHistory.requestName = ""employeeAddChangeBooking""
	|			THEN 1
	|		ELSE 0
	|	END),
	|	TemporaryHistory.brand
	|FROM
	|	TemporaryHistory AS TemporaryHistory
	|GROUP BY
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(enum.analyticValues.events),
	|	TemporaryHistory.brand
	|HAVING
	|	SUM(CASE
	|		WHEN TemporaryHistory.requestName = ""employeeAddChangeBooking""
	|			THEN 1
	|		ELSE 0
	|	END) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	tokens.holding,
	|	appAnalytics.ref,
	|	VALUE(enum.analyticValues.users),
	|	&ReportPeriod,
	|	COUNT(DISTINCT tokens.account),
	|	tokens.chain.brand
	|FROM
	|	Catalog.tokens AS tokens
	|		LEFT JOIN catalog.appAnalytics AS appAnalytics
	|		ON tokens.appType = appAnalytics.appType
	|		AND tokens.systemType = appAnalytics.systemType
	|WHERE
	|	NOT appAnalytics.ref IS NULL
	|	AND tokens.lockDate = DATETIME(1, 1, 1)
	|	AND tokens.createDate <= &EndDate
	|GROUP BY
	|	tokens.holding,
	|	appAnalytics.ref,
	|	VALUE(enum.analyticValues.users),
	|	tokens.chain.brand";
	
	Query.SetParameter("BeginDate", BegOfDay(Day));
	Query.SetParameter("EndDate", EndOfDay(Day));
	Query.SetParameter("tomorrow", EndOfDay(Day) + 86400);
	Query.SetParameter("ReportPeriod", Enums.reportPeriods.day);
	RecordSet.Load(Query.Execute().Unload());
	RecordSet.Write();
		
EndProcedure

Procedure CalcMonthsValues(Months) Export
	For Each Month in Months do
		CalcMonthValue(Month);	
	EndDo;
EndProcedure

Procedure CalcMonthValue(Month) Export
	
	RecordSet	= AccumulationRegisters.UsersValues.CreateRecordSet();
	RecordSet.Filter.Recorder.Set(GetRecorder(Month, Enums.reportPeriods.month));
	
	Query	= New query;
	Query.text	=  "SELECT
	|	Logs.period AS period,
	|	Logs.requestName AS requestName,
	|	Logs.token AS token,
	|	Logs.token.account AS account,
	|	Logs.token.holding AS holding,
	|	appAnalytics.ref AS appAnalytics,
	|	Logs.brand
	|INTO TemporaryHistory
	|FROM
	|	Catalog.logs AS Logs
	|		LEFT JOIN Catalog.appAnalytics AS appAnalytics
	|		ON Logs.token.appType = appAnalytics.appType
	|		AND Logs.token.systemType = appAnalytics.systemType
	|WHERE
	|	Logs.period BETWEEN &BeginDate AND &EndDate
	|	AND
	|	NOT appAnalytics.ref IS NULL
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&BeginDate AS period,
	|	TemporaryHistory.holding AS holding,
	|	TemporaryHistory.appAnalytics AS appAnalytics,
	|	VALUE(enum.analyticValues.activeUsers) AS analyticValue,
	|	&ReportPeriod AS ReportPeriod,
	|	COUNT(DISTINCT TemporaryHistory.account) AS count,
	|	TemporaryHistory.brand
	|FROM
	|	TemporaryHistory AS TemporaryHistory
	|GROUP BY
	|	TemporaryHistory.holding,
	|	TemporaryHistory.appAnalytics,
	|	VALUE(enum.analyticValues.activeUsers),
	|	TemporaryHistory.brand
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	tokens.holding,
	|	appAnalytics.ref,
	|	VALUE(enum.analyticValues.users),
	|	&ReportPeriod,
	|	COUNT(DISTINCT tokens.account),
	|	tokens.chain.brand
	|FROM
	|	Catalog.tokens AS tokens
	|		LEFT JOIN Catalog.appAnalytics AS appAnalytics
	|		ON tokens.appType = appAnalytics.appType
	|		AND tokens.systemType = appAnalytics.systemType
	|WHERE
	|	NOT appAnalytics.ref IS NULL
	|	AND tokens.lockDate = DATETIME(1, 1, 1)
	|	AND tokens.createDate <= &EndDate
	|GROUP BY
	|	tokens.holding,
	|	appAnalytics.ref,
	|	VALUE(enum.analyticValues.users),
	|	tokens.chain.brand
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginDate,
	|	UsersValues.holding,
	|	UsersValues.appAnalytics,
	|	UsersValues.analytic,
	|	&ReportPeriod,
	|	UsersValues.countTurnover,
	|	UsersValues.brand
	|FROM
	|	AccumulationRegister.UsersValues.Turnovers(&BeginDate, &EndDate,, ReportPeriod = &ReportPeriodDay
	|	AND analyticValue <> VALUE(enum.analyticValues.activeUsers)
	|	AND analyticValue <> VALUE(enum.analyticValues.users)) AS UsersValues";
	
	Query.SetParameter("BeginDate", BegOfMonth(Month));
	Query.SetParameter("EndDate", EndOfMonth(Month));	
	Query.SetParameter("ReportPeriod", Enums.reportPeriods.month);
	Query.SetParameter("ReportPeriodDay", Enums.reportPeriods.day);
	RecordSet.Load(Query.Execute().Unload());
	RecordSet.Write();
		
EndProcedure



