
Procedure OnComposeResult(DocRes, DetailsData, standardProcessing)
	
	standardProcessing = false;	
	settings = SettingsComposer.GetSettings();
	holding = settings.DataParameters.Items.Find("holding").Value;
	period = settings.DataParameters.Items.Find("period").Value;
	startDate = period.StartDate;
	endDate = EndOfDay(period.EndDate);
	if not ValueIsFilled(holding) then
		Return;
	EndIf;
	KPOData = GetKPOData(holding,startDate, endDate);
	
	ExternalDataComposition = new Structure;
	ExternalDataComposition.Insert("KPOData", KPOData[0]);
	
	TemplateComposer = new DataCompositionTemplateComposer;
	
	CompositionSchema = TemplateComposer.Execute(DataCompositionSchema, Settings);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionSchema, ExternalDataComposition);
	
	OutputProcessor = new DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(DocRes);
	OutputProcessor.Output(DataCompositionProcessor);
		
EndProcedure


function GetKPOData(holding,startDate, endDate)
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
		queryText = GetQueryText();
		queryParams = GetQueryParams(startDate, endDate);
		requestParameters = GetParametersToSend(selection);
		requestStruct = New Structure();
		requestStruct.Insert("Command",			queryText);
		requestStruct.Insert("TakeStructure",	false);
		requestStruct.Insert("Parameters",		queryParams);
		requestStruct.Insert("TakeUIDs", 		True);
		requestParameters.Insert("requestStruct", requestStruct);
		requestParameters.Insert("internalRequestMethod", True);
		requestParameters.Insert("isXDTOSerializer", true);
		GeneralCallServer.executeRequestMethod(requestParameters);
		If requestParameters.error = "" Then
			JSONReader = New JSONReader();
			JSONReader.SetString(requestParameters.answerBody);
			data = XDTOSerializer.ReadJSON(JSONReader);
			If data.Error = "" then
				return data.Data;
			else 
				return getEmptyTable();
			EndIf;
				
		else
			return getEmptyTable();
		EndIf;
		
	EndIf;	
EndFunction

function getEmptyTable()
	query = new query();
	query.text = "SELECT
	|	"""" AS UID,
	|	"""" AS Name,
	|	"""" AS State,
	|	"""" AS Number,
	|	"""" AS Operation,
	|	"""" As Club,
	|	0	 As AmountKPO";
	return query.Execute().Unload();
EndFunction

function GetQueryText()
	return "Выбрать
	|	ЗаявкаНаОплату.Ссылка AS UID,
	|	PRESENTATION(ЗаявкаНаОплату.Ссылка) AS Name,
	|	PRESENTATION(ЗаявкаНаОплату.СтатусДокумента) AS StateKPO,
	|	ЗаявкаНаОплату.Номер AS Number,
	|	PRESENTATION(ЗаявкаНаОплату.ВидОперации) AS Operation,
	|	PRESENTATION(ЗаявкаНаОплату.Клуб) AS Club,
	|	ЗаявкаНаОплату.Сумма AS AmountKPO
	|FROM
	|	Документ.ЗаявкаНаОплату AS ЗаявкаНаОплату
	|WHERE
	|	ЗаявкаНаОплату.Дата BETWEEN &startDate AND &endDate
	|
	|UNION ALL
	|
	|Выбрать Первые 0
	|	""00000000-0000-0000-0000-000000000000"",
	|	"""",
	|	"""",
	|	"""",
	|	"""",
	|	"""",
	|	0";
EndFunction

function GetQueryParams(startDate, endDate)
	queryParams = new Structure;
	queryParams.Insert("startDate", startDate);
	queryParams.Insert("endDate", endDate);
	return queryParams;
EndFunction

Function GetParametersToSend(DataSelect)
	Parameters = new structure();
	Parameters.Insert("language", DataSelect.language);
	Parameters.Insert("authKey", string(DataSelect.tokenDefault.UUID()));
	Parameters.Insert("requestName", "request");
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
