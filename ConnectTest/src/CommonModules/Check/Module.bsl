
Function requestParameters(parameters) Export
	For Each parameter In StrSplit(getRequiredParameters(parameters.requestName), ",") Do
		If parameter <> "" Then
			If Not parameters.requestStruct.Property(parameter)
					Or Not ValueIsFilled(parameters.requestStruct[parameter]) Then
				Return Service.getErrorDescription(parameters.language, parameter
					+ "Error");
			EndIf;
		EndIf;
	EndDo;
	Return Service.getErrorDescription();
EndFunction

Function getRequiredParameters(requestName)
	If requestName = "config" Then
		Return "appType,systemType";
	ElsIf requestName = "signin" Then
		Return "phone,chainCode";
	ElsIF requestName = "confirm" Then
		Return "password";
	ElsIF requestName = "registerdevice" Then
		Return "appType,appVersion,deviceModel,deviceToken,systemType,systemVersion";
	ElsIF requestName = "addusertotoken" Then
		Return "uid";	
	Else
		Return "";		
	EndIf;
EndFunction

Procedure legality(request, parameters) Export
	parameters.Insert("authKey", HTTP.GetRequestHeader(request, "auth-key"));
	parameters.Insert("tokenСontext", New Structure("token", Catalogs.tokens.EmptyRef()));
	If Not ValueIsFilled(parameters.authKey) Then
		If parameters.requestName <> "config"
				And parameters.requestName <> "chainlist"
				And parameters.requestName <> "countrycodelist" Then
			source = "";
			timeStamp = 0;
			hash = "";
			requestBody = request.GetBodyAsString();
			requestStruct = HTTP.decodeJSON(requestBody);
			requestStruct.Property("source", source);
			requestStruct.Property("timeStamp", timeStamp);
			requestStruct.Property("hash", hash);
			If Not ValueIsFilled(source) Or Not ValueIsFilled(timeStamp)
					Or Not ValueIsFilled(hash) Then
				parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));
			Else
				parameters.Insert("errorDescription", Crypto.checkHasp(parameters.language, source, timeStamp, hash));				
			EndIf;
		EndIf;
	Else
		tokenСontext = GeneralReuse.getTokenContext(parameters.language, parameters.authKey);
		If tokenСontext.token.IsEmpty() Then
			parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));			
		Else
			parameters.Insert("tokenСontext", tokenСontext);
		EndIf;
	EndIf;
EndProcedure