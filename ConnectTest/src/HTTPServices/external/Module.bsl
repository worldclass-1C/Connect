
Function ProcessRequestPOST(Request)
	Return HTTP.processRequest(Request);
EndFunction

Function ProcessRequestOPTIONS(Request)
	Response = New HTTPServiceResponse(200);		
	Response.Headers.Insert("Access-Control-Allow-Headers", "*");	
	Return Response;
EndFunction

Function pingGet(Request)
	
	array = New Array();
	
	query = New Query("SELECT
	|	PRESENTATION(currentAppVersions.brand) AS brand,
	|	PRESENTATION(currentAppVersions.appType) AS appType,
	|	PRESENTATION(currentAppVersions.systemType) AS systemType,
	|	currentAppVersions.appVersion
	|FROM
	|	InformationRegister.currentAppVersions AS currentAppVersions");
	
	select = query.Execute().Select();
	
	While select.Next() Do
		struct = New Structure();
		struct.Insert("brand", select.brand);
		struct.Insert("appType", select.appType);
		struct.Insert("systemType", select.systemType);
		struct.Insert("appVersion", select.appVersion);
		array.Add(struct);		
	EndDo;
	
	response = New HTTPServiceResponse(200);
	response.Headers.Insert("Content-type", "application/json;  charset=utf-8");
	response.SetBodyFromString(HTTP.encodeJSON(array), TextEncoding.UTF8, ByteOrderMarkUsage.Use);
	Return response;
	
EndFunction
