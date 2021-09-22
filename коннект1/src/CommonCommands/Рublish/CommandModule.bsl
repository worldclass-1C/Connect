
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Process(CommandParameter);
 
EndProcedure

Procedure Process(CommandParameter)
	arrHolding = New Array;
	Data = CollectData(CommandParameter,arrHolding);
	language = Catalogs.languages.FindByCode("en");
	For Each holding In arrHolding Do
		SendData(Data, holding, language);
	EndDo;
EndProcedure

Function CollectData(Data,arrHolding)
	res = Undefined;
	If ValueIsFilled(Data) Then
		N = "";
		ChainToken = "";
		If TypeOf(Data)=Type("CatalogRef.chains") Then
			N = "chains";
			ChainToken = GetChainToken(Data);
			arrHolding.Add(Data.holding);
		ElsIf TypeOf(Data)=Type("CatalogRef.cacheTypes") Then
			N = "ИменаКэша";
			query = New Query("SELECT DISTINCT h.holding AS holding
						|FROM InformationRegister.holdingsConnectionsInformationSources AS h");
			arrHolding = query.Execute().Unload().UnloadColumn("holding")
		EndIf;
		
		If N<>"" Then
			arrEl = New Array;
			strucData = New Structure("Description,Code, domainName");
			strucData.Insert("ChainToken", ChainToken);
			FillPropertyValues(strucData, Data);
			For Each KeyVal In strucData Do
				If Not ValueIsFilled(KeyVal.Value) Then
					strucData.Delete(KeyVal.Key);
				EndIf;
			EndDo;
			arrEl.Add(New Structure("G,R",String(Data.UUID()),strucData));
	 		res = New Structure("N,E",N, arrEl); 
		EndIf;
	EndIf; 
	
	Return Res
EndFunction

Procedure SendData(requestStruct, holding, language)
	If ValueIsFilled(requestStruct) Then
		General.executeRequestMethod(
			New Structure("requestName,requestStruct,internalRequestMethod,tokenContext,language,authKey,languageCode,brand",
				"FillCatalog",
				requestStruct,
				True,
				New Structure("holding,appType,token,appVersion,systemType,timezone,user", holding, "API",holding.tokenDefault,"",""),
				language,
				"",
				language.Code,
				enums.brandTypes.WorldClass));
	EndIf; 
EndProcedure

Function GetChainToken(chain)
	ChainToken = "";
	Query = New Query;
	Query.Text = "SELECT TOP 1
		|	tokens.Ref AS Ref
		|FROM
		|	Catalog.tokens AS tokens
		|WHERE
		|	tokens.account = VALUE(Catalog.accounts.Tilda)
		|	AND tokens.chain = &chain";

	Query.SetParameter("chain", chain);
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();

	While SelectionDetailRecords.Next() Do
		ChainToken = XMLString(SelectionDetailRecords.Ref);
	EndDo;
	Return ChainToken
EndFunction



 