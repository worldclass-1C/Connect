
&AtServer
Procedure SendPushAtServer()
	//--Подготовка заголовка пуш messages
	newWordArray = New Array();
	wordArray = StrSplit(pushTitle, " ");
	For Each word In wordArray Do
		If Найти(word, "#emj") > 0 Then
			word	= DecodeString(StrReplace(word, "#emj", ""), StringEncodingMethod.URLEncoding);
		EndIf;
		newWordArray.add(word);
	EndDo;
	
	titleForPush = StrConcat(newWordArray, " ");	
	//--Подготовка текста пуш messages
	//НЕ ЗАБЫТЬ ЧТО СМАЙЛИК ДОЛЖЕН БЫТЬ В ФОРМАТЕ %F0%9F%8F%8B%20
	newWordArray = New Array();
	wordArray = StrSplit(text, " ");
	For Each word In wordArray Do
		If Найти(word, "#emj") > 0 Then
			word	= DecodeString(StrReplace(word, "#emj", ""), StringEncodingMethod.URLEncoding);
		EndIf;
		newWordArray.add(word);
	EndDo;                       
	pushText = StrConcat(newWordArray, " ");
		
	JSONWriter		= New JSONWriter;
	JSONWriter.SetString();
		
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
	          	  |	tokens.account IN(&accountArray)
	          	  |	AND tokens.Ref IN(&tokenArray)
	          	  |	AND tokens.lockDate = DATETIME(1, 1, 1)
	          	  |;
	          	  |
	          	  |////////////////////////////////////////////////////////////////////////////////
	          	  |SELECT
	          	  |	ВТ.token AS token,
	          	  |	ВТ.deviceToken AS deviceToken,
	          	  |	ВТ.SubscriberType AS SubscriberType,
	          	  |	ВТ.systemType AS systemType,
	          	  |	ISNULL(appCertificates.certificate, appCertificatesCommon.certificate) AS certificate
	          	  |FROM
	          	  |	ВТ AS ВТ
	          	  |		LEFT JOIN InformationRegister.appCertificates AS appCertificates
	          	  |		ON ВТ.chain = appCertificates.chain
	          	  |			AND ВТ.appType = appCertificates.appType
	          	  |			AND ВТ.systemType = appCertificates.systemType
	          	  |		LEFT JOIN InformationRegister.appCertificates AS appCertificatesCommon
	          	  |		ON (appCertificatesCommon.chain = VALUE(Справочник.chains.ПустаяСсылка))
	          	  |			AND ВТ.appType = appCertificatesCommon.appType
	          	  |			AND ВТ.systemType = appCertificatesCommon.systemType";
	
	query.SetParameter("accountArray", Recipients.Unload().UnloadColumn("account"));
	
	tokenArray	= Recipients.Unload().UnloadColumn("token");
	If tokenArray.Count() = 0 Then
		query.text	= СтрЗаменить(query.text, "AND tokens.ref IN (&tokenArray)", "");	
	Else
		query.SetParameter("tokenArray", tokenArray);
	EndIf;
	
	select = query.Execute().Select();
		
	While select.Next() Do
		If select.deviceToken <> "" Then
			pushStruct = New Structure();
			pushStruct.Insert("title", titleForPush);
			pushStruct.Insert("text", pushText);
			pushStruct.Insert("action", action);
			pushStruct.Insert("objectId", objectId);
			pushStruct.Insert("objectType", objectType);
			pushStruct.Insert("noteId", noteId);
			pushStruct.Insert("deviceToken", select.deviceToken);
			pushStruct.Insert("SubscriberType", select.SubscriberType);
			pushStruct.Insert("title", titleForPush);
			pushStruct.Insert("Badge", 0);
			pushStruct.Insert("systemType", select.systemType);
			pushStruct.Insert("certificate", select.certificate);
			pushStruct.Insert("token", select.token);
			pushStruct.Insert("informationChannel", "");			
			Messages.sendPush(pushStruct);
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure SendPush(Command)
	SendPushAtServer();
EndProcedure
