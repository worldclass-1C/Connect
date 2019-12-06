
Function ProcessRequestPOST(Request)
	Return HTTP.processRequest(Request);
EndFunction

Function ProcessRequestOPTIONS(Request)
	response = New HTTPServiceResponse(200);	
	origin = HTTP.getRequestHeader(request, "origin");
	response.Headers.Insert("Access-Control-Allow-Headers", "content-type, server, date, content-length, Access-Control-Allow-Headers, Authorization, X-Requested-With, auth-key,brand,content-type,kpo-code,language,request");
//	response.Headers.Insert("Access-Control-Allow-Headers", "*, content-type");
	If HTTP.inTheWhiteList(origin) Then		
		//	response.Headers.Insert("Access-Control-Allow-Credentials", "true");
		response.Headers.Insert("Access-Control-Allow-Methods", "POST,GET,OPTIONS");
		response.Headers.Insert("Access-Control-Allow-Origin", origin);
	EndIf;
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
	response.SetBodyFromString(HTTP.encodeJSON(array), TextEncoding.UTF8, ByteOrderMarkUsage.DontUse);
	Return response;
	
EndFunction
