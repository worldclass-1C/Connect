//Params - Структура, с ключами
//			user 
//			chain
//			cacheType
	
Function GetCache(Params) Export
	res = "";
	strucSeek = New Structure("user,chain,date,cacheType", 
						Catalogs.users.EmptyRef(),
						Catalogs.chains.EmptyRef(),
						CurrentUniversalDate(),);
	FillPropertyValues(strucSeek, Params);
	
	If ValueIsFilled(strucSeek.cacheType) Then
		Query = New Query(TextQuery());
		For Each KeyVal In strucSeek Do
			Query.SetParameter(KeyVal.Key,  KeyVal.Value);
		EndDo;
		arrRes = New Array;
		resQuery = Query.ExecuteBatch();
		select = resQuery[1].Select();
		tabDescriptions = resQuery[2].Unload();
		
		While select.Next() Do
			data =select.data;
			struct = HTTP.decodeJSON(data);
			
			arrDesc = New Array();
			For Each found In 	tabDescriptions.FindRows(New Structure("Ref", select.Ref)) Do
				If TypeOf(found.Description)=Type("CatalogRef.cacheInformations") Then
					If Not found.data="" and Not found.data="{}" Then
						arrDesc.Add(HTTP.decodeJSON(found.data));
					EndIf	
				Else
					//TODO: тут нужно собрать структуру по описаниям разного типа
				EndIf;		
			EndDo;
			If arrDesc.Count()>0 Then
				struct.Insert("desc", arrDesc);	
			EndIf;
			If struct.Count()>0 Then
				arrRes.Add(struct);
			EndIf
		EndDo;
		
		If arrRes.Count()=1  Then
			res = arrRes[0];
		ElsIf arrRes.Count()>1 Then
			res = arrRes
		EndIf
	EndIf;					
	
	Return HTTP.encodeJSON(res);
EndFunction

Function TextQuery()
	Return "SELECT
		|	cacheIndex.cacheInformation AS Ref,
		|	cacheIndex.cacheInformation.data AS data
		|INTO tabCI
		|FROM
		|	InformationRegister.cacheIndex AS cacheIndex
		|WHERE
		|	cacheIndex.user = &user
		|	AND cacheIndex.chain = &chain
		|	AND cacheIndex.cacheType = &cacheType
		|	AND &date between cacheIndex.cacheInformation.startRotation AND cacheIndex.cacheInformation.endRotation
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|select
		|	*
		|from
		|	tabCI
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	cacheInformationsDescriptions.Ref AS Ref,
		|	cacheInformationsDescriptions.Description,
		|	cacheInformationsDescriptions.Description.data AS data
		|FROM
		|	tabCI AS tabCI
		|		LEFT JOIN Catalog.cacheInformations.Descriptions AS cacheInformationsDescriptions
		|		ON cacheInformationsDescriptions.Ref = tabCI.Ref"
	
EndFunction