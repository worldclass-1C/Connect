
Function password(token, password, language) Export

	query = New Query();
	query.Text = "SELECT
	|	usersAuthorizationCodes.password,
	|	usersAuthorizationCodes.phone,
	|	usersAuthorizationCodes.inputCount,
	|	usersAuthorizationCodes.recordDate
	|FROM
	|	InformationRegister.usersAuthorizationCodes AS usersAuthorizationCodes
	|WHERE
	|	usersAuthorizationCodes.token = &token";

	query.SetParameter("token", token);

	queryResult = query.Execute();
	If queryResult.isEmpty() Then
		Return New Structure("phone, errorDescription", "", Service.getErrorDescription(language, "passwordRequired"));
	Else
		select = queryResult.Select();
		select.Next();
		If ToUniversalTime(CurrentDate())
				- select.recordDate > 900 Then
			Account.delPassword(token);
			Return New Structure("phone, errorDescription", select.phone, Service.getErrorDescription(language, "passwordExpired"));
		ElsIf select.inputCount > 2 Then  	
			Return New Structure("phone, errorDescription", select.phone, Service.getErrorDescription(language, "passwordExpired"));			
		ElsIf select.password = password Then			
			Return New Structure("phone, errorDescription", select.phone, Service.getErrorDescription(language));
		Else
			Account.incPasswordInputCount(token);
			Return New Structure("phone, errorDescription", select.phone, Service.getErrorDescription(language, "passwordNotCorrect"));			
		EndIf;
	EndIf;

EndFunction

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
	Return Service.getErrorDescription(parameters.language);
EndFunction

Function getRequiredParameters(requestName)
	If requestName = "config" Then
		Return "appType,systemType";
	ElsIf requestName = "signin" Then
		Return "phone,chainCode";
	ElsIF requestName = "confirmphone" Then
		Return "password";
	ElsIF requestName = "registerdevice" Then
		Return "appType,appVersion,deviceModel,systemType,systemVersion";
	ElsIF requestName = "paymentstatus" Then
		Return "orderId";
	ElsIF requestName = "addusertotoken" Then
		Return "uid";		
	ElsIF requestName = "imagePOST" Then
		Return "object,extension";		
	Else
		Return "";		
	EndIf;
EndFunction

Function timeBeforeSendSms(token) Export
	query	= New Query();
	query.Text	= "SELECT
	|	usersAuthorizationCodes.sendCount,
	|	usersAuthorizationCodes.recordDate
	|FROM
	|	InformationRegister.usersAuthorizationCodes AS usersAuthorizationCodes
	|WHERE
	|	usersAuthorizationCodes.token = &token";
	
	query.SetParameter("token", token);
	queryResult	= query.Execute();	
	If queryResult.IsEmpty() Then
		Return 0; 
	Else
		universalTime		= ToUniversalTime(CurrentDate());
		selection = queryResult.Select();
		selection.Next();
		retryTime = ?(selection.sendCount > 2, 600, 60);
		delta = universalTime - selection.recordDate;
		Return ?(delta > retryTime, 0, retryTime - delta);						
	EndIf;
EndFunction

Procedure legality(request, parameters) Export
	parameters.Insert("authKey", HTTP.GetRequestHeader(request, "auth-key"));
	parameters.Insert("tokenContext", New Structure("token, user", Catalogs.tokens.EmptyRef(),Catalogs.users.EmptyRef()));
	If Not ValueIsFilled(parameters.authKey) Then
		If parameters.requestName <> "config"
				And parameters.requestName <> "chainlist"
				And parameters.requestName <> "countrycodelist" Then
			timeStamp = 0;
			hash = "";
			requestBody = request.GetBodyAsString();
			requestStruct = HTTP.decodeJSON(requestBody);			
			If TypeOf(requestStruct) <> Type("Structure") Then
				parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));
			Else
				requestStruct.Property("timeStamp", timeStamp);
				requestStruct.Property("hash", hash);
				If Not ValueIsFilled(timeStamp) Or Not ValueIsFilled(hash) Then
					parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));
//				ElsIf (ToUniversalTime(CurrentDate()) - Date("19700101"))
//						- timeStamp > 300 Then
//					parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));
				Else
					parameters.Insert("errorDescription", Crypto.checkHasp(parameters.language, timeStamp, hash));
				EndIf;
			EndIf;
		EndIf;
	Else
		tokenContext = TokenReuse.getContext(parameters.authKey);
		If tokenContext.token.IsEmpty() Then
			parameters.Insert("errorDescription", Service.getErrorDescription(parameters.language, "noValidRequest"));			
		Else
			parameters.Insert("tokenContext", tokenContext);
			parameters.Insert("currentTime", ToLocalTime(ToUniversalTime(CurrentDate()), tokenContext.timezone));
			parameters.Insert("underControl", tokenContext.underControl);
		EndIf;
	EndIf;
EndProcedure