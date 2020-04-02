//Params - Структура, с ключами
//			user 
//			chain
//			cacheTypes - массив cacheTypes

Function GetCache(parameters, struсRequest) Export
	
	strucSeek = New Structure("user,chain,holding,date,cacheTypes", Catalogs.users.EmptyRef(), Catalogs.chains.EmptyRef(),
		CurrentUniversalDate(), );
	FillPropertyValues(strucSeek, struсRequest);

	If ValueIsFilled(strucSeek.cacheTypes) Then
		Query = New Query(TextQuery());
		For Each KeyVal In strucSeek Do
			Query.SetParameter(KeyVal.Key, KeyVal.Value);
		EndDo;
		strucRes = New Structure();;
		resQuery = Query.ExecuteBatch();
		common = resQuery[1].Unload();
		tabDescriptions = resQuery[2].Unload();

		//emptyTypes = New Array;

		For Each cachetype In strucSeek.cacheTypes Do
			FoundRows = common.FindRows(New Structure("cacheType", cachetype));
			If FoundRows.Count() = 0 Then
				//TODO нужно решить, сразу посылать в фоне при нахождении
				//или собрать и синхронно запросить данные
				//возможно в зависимости от типа cachetype
				//	пока сделал в фоне
				//emptyTypes.Add(XMLString(cachetype));
				arrParams = New Array();
				arrParams.Add(parameters);
				arrParams.Add(New Structure("user,chain,cacheType", strucSeek.user, strucSeek.chain, cachetype));
				BackgroundJobs.Execute("Cache.AskCache",arrParams )
			Else
				arrRes = New Array;
				For Each FoundRow In FoundRows Do
					data =FoundRow.data;
					struct = HTTP.decodeJSON(data);
					arrDesc = New Array;
					For Each found In tabDescriptions.FindRows(New Structure("Ref", FoundRow.Ref)) Do
						If TypeOf(found.Description) = Type("CatalogRef.cacheInformations") Then
							If Not found.data = "" And Not found.data = "{}" Then
								arrDesc.Add(HTTP.decodeJSON(found.data));
							EndIf
						Else
							//TODO: тут нужно собрать структуру по описаниям разного типа
						EndIf
					EndDo;
					If arrDesc.Count() > 0 Then
						struct.Insert("desc", arrDesc);
					EndIf;
					If struct.Count() > 0 Then
						arrRes.Add(struct);
					EndIf	
				EndDo;
				strucRes.Insert(cachetype.PredefinedDataName, arrRes)
			EndIf
		EndDo
	EndIf;

	Return strucRes;
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
	|	CI.cacheType,
	|	CI.cacheInformation AS Ref,
	|	CI.cacheInformation.data AS data
	|INTO tabCI
	|FROM
	|	InformationRegister.cacheIndex AS CI
	|		LEFT JOIN Catalog.chains.cacheTypes AS CCT
	|		ON CCT.Ref = CI.chain
	|		AND CCT.cacheType = CI.cacheType
	|WHERE
	|	CI.user = &user
	|	AND CI.chain = &chain
	||	AND CI.holding = &holding
	|	AND CI.cacheType in (&cacheTypes)
	|	AND &date between CI.cacheInformation.startRotation AND CI.cacheInformation.endRotation
	|	AND ISNULL(CCT.isUsed, FALSE)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|select
	|	*
	|from
	|	tabCI
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	dscr.Ref AS Ref,
	|	dscr.Description,
	|	dscr.Description.data AS data
	|FROM
	|	tabCI AS tabCI
	|		INNER JOIN Catalog.cacheInformations.Descriptions AS dscr
	|		ON dscr.Ref = tabCI.Ref"

EndFunction