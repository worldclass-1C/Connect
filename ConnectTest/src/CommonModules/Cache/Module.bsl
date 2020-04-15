//Params - Структура, с ключами
//			user 
//			chain
//			cacheTypes - массив cacheTypes

Function GetCache(parameters, struсRequest) Export
	
	strucSeek = New Structure("user,chain,holding,date,languageCode,language,cacheTypes", 
								Catalogs.users.EmptyRef(), 
								Catalogs.chains.EmptyRef(),
								Catalogs.holdings.EmptyRef(),
								CurrentUniversalDate(), 
								"",
								Catalogs.languages.EmptyRef(),
								New Array);

	FillPropertyValues(strucSeek, struсRequest);
	Result ="";
	
	If strucSeek.cacheTypes.Count()>0 Then
		Query = New Query(TextQuery());
		For Each KeyVal In strucSeek Do
			Query.SetParameter(KeyVal.Key, KeyVal.Value);
		EndDo;
		resQuery = Query.ExecuteBatch();
		common = resQuery[1].Unload();
		tabDescriptions = resQuery[3].Unload();

		//emptyTypes = New Array;
		strucRes = New Structure;
		
		mapReplace = DescriptionProcessing(tabDescriptions,strucSeek.languageCode,strucSeek.language);
		
		For Each cachetype In strucSeek.cacheTypes Do
			FoundRows = common.FindRows(New Structure("cacheType", cachetype));
			//пустых строк в запросе быть не может
			//могут быть неиспользуемые, и без данных
			//FoundRow = FoundRows[0];
			arrData = New Array;  
			For Each FoundRow In FoundRows Do
				If Not FoundRow.Used Then
					Continue
				EndIf;
				If FoundRow.NoData Then
					//TODO нужно решить, сразу посылать в фоне при нахождении
					//или собрать и синхронно запросить данные
					//возможно в зависимости от типа cachetype
					//	пока сделал в фоне
					//emptyTypes.Add(XMLString(cachetype));
					arrParams = New Array();
					arrParams.Add(parameters);
					arrParams.Add(New Structure("user,chain,cacheType", strucSeek.user, strucSeek.chain, cachetype));
					BackgroundJobs.Execute("Cache.AskCache",arrParams )
				ElsIf Not FoundRow.Pass Then
					data = FoundRow.data;
					For Each KeyVal In mapReplace Do
						data = StrReplace(data, KeyVal.Key, KeyVal.Value)
					EndDo;
					arrData.Add(HTTP.decodeJSON(data));
				EndIf
			EndDo; 
			If arrData.Count()=1 Then
				strucRes.Insert(FoundRow.PredefinedDataName,arrData[0]);
			ElsIf arrData.Count()>1 Then
				strucRes.Insert(FoundRow.PredefinedDataName,arrData);
			EndIf; 
		EndDo;
		If strucRes.Count()=1 Then
			For Each KeyVal In strucRes Do
				Result = KeyVal.Value
			EndDo;
		Else 
			Result = strucRes
		EndIf;
	EndIf;

	Return Result;

EndFunction

Function DescriptionProcessing(arrDescr,languageCode,language)
	res =  New Map;

	mapData = New Map;
	mapData.Insert(Type("CatalogRef.rooms"),New Structure("Handler,Array","getArrRooms",New Array));
	mapData.Insert(Type("CatalogRef.gyms"),New Structure("Handler,Array","getArrGyms",New Array));
	mapData.Insert(Type("CatalogRef.products"),New Structure("Handler,Array","getArrProduct",New Array));
	mapData.Insert(Type("CatalogRef.employees"),New Structure("Handler,Array","getArrEmployees",New Array));
	
	If Not ValueIsFilled(languageCode) Then
		languageCode = "ru"
	EndIf;
	For Each found In arrDescr Do
		typeDescr = TypeOf(found.Description);
		If typeDescr = Type("CatalogRef.cacheInformations") Then
			//для описаний кэша отдельная ветка
			
			//если в кэше есть локализация, то нужно это учесть
			strucData = HTTP.decodeJSON(Found.data);
			For Each KeyVal In strucData Do
				If KeyVal.Value.Count()=1 Then
					For Each lKeyVal In KeyVal.Value Do
						strucData.Insert(KeyVal.Key,lKeyVal.Value)
					EndDo;
				ElsIf KeyVal.Value.Count()>1 Then
					If KeyVal.Value.Property(languageCode) Then
						strucData.Insert(KeyVal.Key,KeyVal.Value[languageCode])
					Else
						strucData.Insert(KeyVal.Key,KeyVal.Value.ru) 
					EndIf; 
				EndIf;
			EndDo; 
			res.Insert(StrTemplate("""%1""",String(found.Description.UUID())),HTTP.encodeJSON(strucData))
		Else
			//сбор значений
			strucData = mapData.Get(typeDescr);
			If Not strucData=Undefined Then
				strucData.Array.Add(found.Description)
			EndIf; 
		EndIf
	EndDo;
	
	//замена значений
	For Each KeyVal In mapData Do
		If KeyVal.Value.Array.Count()>0 Then
			mapDescr = 
			Eval(StrTemplate("API_List.%1(New Structure(""byArray,Array,language"",True,KeyVal.Value.Array,language))",KeyVal.Value.Handler));
			For Each lDecr In KeyVal.Value.Array Do
				ValRepl = mapDescr.Get(lDecr);
				If ValRepl=Undefined Then
					ValRepl=""
				EndIf; 
				res.Insert(StrTemplate("""%1""",StrTemplate("""%1""",String(lDecr.UUID())),ValRepl))
			EndDo;
		EndIf; 
	EndDo; 
	
	Return res
EndFunction

Procedure AskCache(parameters, struсRequest) Export
	For Each KeyVal In struсRequest Do
		struсRequest[KeyVal.Key] = XMLString(KeyVal.Value)
	EndDo;
	
	General.executeRequestMethod(
		New Structure("requestName,requestStruct,internalRequestMethod,tokenContext,language,authKey,languageCode",
				"AskCache",
				struсRequest,
				True,
				//New Structure("holding,appType,timezone,token,user,", parameters.holding, "API"),
				//New Structure("appType,timezone,token,user,", "API"),
				parameters.tokenContext,
				parameters.language,
				parameters.authKey,
				parameters.language.Code));
EndProcedure

Function TextQuery()
	Return "SELECT
	|	CT.Ref AS cacheType,
	|	CI.cacheInformation AS Ref,
	|	CI.cacheInformation IS NULL AS NoData,
	|	CI.cacheInformation.data AS data,
	|	ISNULL(CCT.isUsed, FALSE) AS Used,
	|	CT.PredefinedDataName AS PredefinedDataName,
	|	NOT &date BETWEEN CI.cacheInformation.startRotation AND CI.cacheInformation.endRotation AS Pass
	|INTO tabCI
	|FROM
	|	Catalog.cacheTypes AS CT
	|		LEFT JOIN InformationRegister.cacheIndex AS CI
	|		ON CT.Ref = CI.cacheType
	|		AND CI.user = &user
	|		AND (CI.chain = &chain
	|		OR CI.chain = VALUE(Catalog.chains.EmptyRef))
	|		AND CI.holding = &holding
	|		LEFT JOIN Catalog.chains.cacheTypes AS CCT
	|		ON CCT.Ref = &chain
	|		AND CCT.cacheType = CT.Ref
	|WHERE
	|	CT.Ref IN (&cacheTypes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tabCI.cacheType AS cacheType,
	|	tabCI.Ref AS Ref,
	|	tabCI.NoData AS NoData,
	|	tabCI.data AS data,
	|	tabCI.Used AS Used,
	|	tabCI.PredefinedDataName AS PredefinedDataName,
	|	tabCI.Pass
	|FROM
	|	tabCI AS tabCI
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	dscr.Ref AS Ref,
	|	dscr.Description AS Description,
	|	dscr.Description.data AS data
	|INTO tabDesr
	|FROM
	|	tabCI AS tabCI
	|		INNER JOIN Catalog.cacheInformations.Descriptions AS dscr
	|		ON dscr.Ref = tabCI.Ref
	|WHERE
	|	tabCI.Used
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tabDesr.Ref AS Ref,
	|	tabDesr.Description AS Description,
	|	tabDesr.data AS data
	|FROM
	|	tabDesr AS tabDesr"

EndFunction