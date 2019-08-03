
Function requestParameters(parameters) Export	
	For Each parameter In StrSplit(getRequiredParameters(parameters.requestName), ",") Do
		If Not parameters.requestStruct.Property(parameter)
				Or Not ValueIsFilled(parameters.requestStruct[parameter]) Then
			Return Service.getErrorDescription(parameters.language, parameter + "Error");
		EndIf;		
	EndDo;
	Return Service.getErrorDescription();	
EndFunction

Function getRequiredParameters(requestName)	
	If requestName = "signin" Then
		Return "phone";
	ElsIF requestName = "confirmation" Then
		Return "password";
	ElsIF requestName = "registerdevice" Then
		Return "appType,appVersion,chainCode,deviceModel,deviceToken,systemType,systemVersion";
	Else
		Return "";		
	EndIf;
EndFunction

Procedure legality(request, parameters) Export
	parameters.Insert("authKey", HTTP.GetRequestHeader(request, "auth-key"));
	If Not ValueIsFilled(parameters.authKey) Then
		source = HTTP.GetRequestHeader(request, "source");
		timeStamp = HTTP.GetRequestHeader(request, "timeStamp");
		hash = HTTP.GetRequestHeader(request, "hash");
		If Not ValueIsFilled(source) Or Not ValueIsFilled(timeStamp)
				Or Not ValueIsFilled(hash) Then
			parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));
		Else			
			parameters.Insert("errorDescription", Crypto.checkHasp(parameters.language, source, timeStamp, hash));
			parameters.Insert("tokenСontext", New Structure("token", Catalogs.tokens.EmptyRef()));
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