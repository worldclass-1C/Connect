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
			If FoundRows.Count()=0 Then
				Continue
			EndIf;
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
			If FoundRow.cacheType=Catalogs.cacheTypes.bannerList Then
				strucRes.Insert(FoundRow.PredefinedDataName,arrData);
			ElsIf arrData.Count()>0 Then
				strucRes.Insert(FoundRow.PredefinedDataName,arrData[0]);
			EndIf; 
//			If arrData.Count()=1 and Not FoundRow.cacheType =   Then
//				strucRes.Insert(FoundRow.PredefinedDataName,arrData[0]);
//			ElsIf arrData.Count()>1 Then
//				strucRes.Insert(FoundRow.PredefinedDataName,arrData);
//			EndIf; 
		EndDo;
//		If strucRes.Count()=1 Then
//			For Each KeyVal In strucRes Do
//				Result = KeyVal.Value
//			EndDo;
//		Else 
			Result = strucRes
//		EndIf;
	EndIf;

	Return Result;

EndFunction

Function ClearCache(parameters, struсRequest) Export
	strucSeek = New Structure("user,chain,holding,date,languageCode,language,cacheTypes,date", 
								Catalogs.users.EmptyRef(), 
								Catalogs.chains.EmptyRef(),
								Catalogs.holdings.EmptyRef(),
								CurrentUniversalDate(), 
								"",
								Catalogs.languages.EmptyRef(),
								New Array,
								CurrentUniversalDate());

	FillPropertyValues(strucSeek, struсRequest);
	
	If strucSeek.cacheTypes.Count()>0 Then
		Query = New Query(TextClearQuery());
		For Each KeyVal In strucSeek Do
			Query.SetParameter(KeyVal.Key, KeyVal.Value);
		EndDo;
		resQuery = Query.ExecuteBatch();
		tab = resQuery[0].Unload();
		
		For Each str In tab Do
			Set = InformationRegisters.cacheIndex.CreateRecordSet();
			Set.Filter.user.Set(str.user);
			Set.Filter.cacheType.Set(str.cacheType);
			Set.Filter.holding.Set(str.holding);
			Set.Filter.chain.Set(str.chain);
			Set.Filter.cacheInformation.Set(str.cacheInformation);
			Set.Write();
			str.cacheInformation.GetObject().Delete();
		EndDo;
	EndIf;

	Return "";

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
			strucData = HTTP.decodeJSON(found.data);
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
			Eval(StrTemplate("API_List.%1(New Structure(""byArray,Array,language,short"",True,KeyVal.Value.Array,language,True))",KeyVal.Value.Handler));
			For Each lDecr In KeyVal.Value.Array Do
				ValRepl = mapDescr.Get(lDecr);
				If ValRepl=Undefined Then
					ValRepl="null"
				EndIf; 
				res.Insert(StrTemplate("""%1""",String(lDecr.UUID())),ValRepl)
			EndDo;
		EndIf; 
	EndDo; 
	
//	res.Insert("""_empty_product_""", "null");
//	res.Insert("""_empty_employee_""", "null");
//	res.Insert("""_empty_gym_""", "null");
//	res.Insert("""_empty_room_""", "null");

	Return res
EndFunction

Procedure AskCache(parameters, struсRequest) Export
	For Each KeyVal In struсRequest Do
		struсRequest[KeyVal.Key] = XMLString(KeyVal.Value)
	EndDo;
	
	General.executeRequestMethod(
		New Structure("requestName,requestStruct,internalRequestMethod,tokenContext,language,authKey,languageCode,brand",
				"AskCache",
				struсRequest,
				True,
				//New Structure("holding,appType,timezone,token,user,", parameters.holding, "API"),
				//New Structure("appType,timezone,token,user,", "API"),
				parameters.tokenContext,
				parameters.language,
				parameters.authKey,
				parameters.languageCode,
				parameters.brand));
EndProcedure

Procedure UpdateCache(parameters) Export
	Query = New Query("SELECT
	|	chainscacheTypes.cacheType AS CacheType
	|FROM
	|	Catalog.chains.cacheTypes AS chainscacheTypes
	|WHERE
	|	chainscacheTypes.isUsed
	|	AND chainscacheTypes.Ref = &chain
	|	AND chainscacheTypes.isUpdated");
	
	Query.SetParameter("chain",parameters.tokenContext.chain);
	Sel = Query.Execute().Select();
	While Sel.Next() Do
		If ValueIsFilled(Sel.cachetype) Then
			AskCache(parameters, 
				New Structure("user,chain,cacheType", parameters.tokenContext.user, parameters.tokenContext.chain, Sel.cachetype))
		EndIf; 
	EndDo;
EndProcedure

Function TextQuery()
	Return "SELECT
	|	CT.Ref AS cacheType,
	|	CI.cacheInformation AS Ref,
	|	CI.cacheInformation IS NULL AS NoData,
	|	CI.cacheInformation.data AS data,
	|	ISNULL(CCT.isUsed, FALSE) AS Used,
	|	CT.PredefinedDataName AS PredefinedDataName,
	|	NOT (&date BETWEEN CI.cacheInformation.startRotation AND CI.cacheInformation.endRotation) AS Pass
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
	|	and CCT.isUpdated
	|;
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	tabDesr.Ref AS Ref,
	|	tabDesr.Description AS Description,
	|	tabDesr.data AS data
	|FROM
	|	tabDesr AS tabDesr
	//SC-101645 Проверяем на битую ссылку -- Подправлено задачей SC-101784  
	|WHERE tabDesr.Description.Ref IS NOT NULL 
	//
	|"

EndFunction

Function TextClearQuery()
	Return "SELECT
	|	CI.*
	|FROM
	|	InformationRegister.cacheIndex AS CI
	|		LEFT JOIN Catalog.chains.cacheTypes AS CCT
	|		ON CCT.Ref = &chain
	|		AND CCT.cacheType = CI.cacheType
	|WHERE
	|	CI.cacheType IN (&cacheTypes)
	|	AND CI.user = &user
	|	AND (CI.chain = &chain
	|	OR CI.chain = VALUE(Catalog.chains.EmptyRef))
	|	AND CI.holding = &holding
	|	and CCT.isUpdated
	|	AND CI.cacheInformation.registrationDate < &date"

EndFunction

Function tabGyms() Export

	gyms = New ValueTable();
	gyms.Columns.Add("ref",new TypeDescription("catalogref.gyms"));
	gyms.Columns.Add("base",new TypeDescription("Boolean"));
	Return gyms;
	
EndFunction // ()

Function getMyClubs(data,parameters) Export
	
	strucSeek = New Structure("user,chain,holding,date,languageCode,language,cacheTypes", 
								Catalogs.users.EmptyRef(), 
								Catalogs.chains.EmptyRef(),
								Catalogs.holdings.EmptyRef(),
								CurrentUniversalDate(), 
								"",
								Catalogs.languages.EmptyRef(),
								New Array);

	FillPropertyValues(strucSeek, data);
	cacheTypes = new array();
	cacheTypes.Add(Catalogs.cacheTypes.gymList);
	strucSeek.cacheTypes = cacheTypes;
	Query = New Query(TextQuery());
	For Each KeyVal In strucSeek Do
		Query.SetParameter(KeyVal.Key, KeyVal.Value);
	EndDo;	
	resQuery = Query.ExecuteBatch();
	common = resQuery[1].Unload();
	
	gyms = tabGyms();
	
	dateNow = CurrentDate();
	
	For each cacheVal in common Do
		If cacheVal.NoData then
			arrParams = New Array();
			arrParams.Add(parameters);
			arrParams.Add(New Structure("user,chain,cacheType", strucSeek.user, strucSeek.chain, Catalogs.cacheTypes.gymList));
			BackgroundJobs.Execute("Cache.AskCache",arrParams );
		else
			cacheData = HTTP.decodeJSON(cacheVal.data);
			For Each elCache In cacheData Do
				strucGym = New Structure("base,ref",false);
				If TypeOf(elCache)=Type("Structure") Then
					//если контракт уже закончился, то пропускаем
					If XMLValue(Type("date"),elCache.d)<dateNow Then
						Continue;
					EndIf; 
					strucGym.ref = Service.getRef(elCache.c, Type("CatalogRef.gyms"));
					If elCache.property("b") and elCache.b Then
						strucGym.base= true
					EndIf; 
				Else
					strucGym.ref = Service.getRef(elCache, Type("CatalogRef.gyms"));
				EndIf;
				FillPropertyValues(gyms.Add(),strucGym);
			EndDo;
		EndIf;
	EndDo;
	
	Return gyms;
EndFunction
Procedure ClearCacheRecord() Export
	Message(CurrentDate());
	Query = Новый Query;
	Query.Text = 
		"SELECT TOP 10000
		|	S.holding AS holding,
		|	S.cacheType AS cacheType,
		|	S.user AS user,
		|	S.chain AS chain,
		|	S.cacheInformation AS cacheInformation
		|FROM
		|	InformationRegister.cacheIndex AS S
		|WHERE
		|	S.cacheInformation.endRotation <= &Date";
	
	Query.SetParameter("Date", CurrentUniversalDate());
	
	Select = Query.Execute().Select();
	 cnt=0;
	While Select.Next() Do
		RecordSet = InformationRegisters.cacheIndex.CreateRecordSet();
		RecordSet.Filter.holding.Set(Select.holding);   
		RecordSet.Filter.cacheType.Set(Select.cacheType);  
		RecordSet.Filter.user.Set(Select.user);  
		RecordSet.Filter.chain.Set(Select.chain); 
		RecordSet.Filter.cacheInformation.Set(Select.cacheInformation);
		RecordSet.Write();
		Select.cacheInformation.GetObject().Delete();
		cnt=cnt+1
	EndDo;
	Message(CurrentDate());
	
	Message(cnt)
EndProcedure
