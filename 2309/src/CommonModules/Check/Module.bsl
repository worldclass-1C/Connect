
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
		Return New Structure("phone, error", "", "passwordRequired");
	Else
		select = queryResult.Select();
		select.Next();
		If ToUniversalTime(CurrentDate())
				- select.recordDate > 900 Then
			Account.delPassword(token);
			Return New Structure("phone, error", select.phone, "passwordExpired");
		ElsIf select.inputCount > 2 Then  	
			Return New Structure("phone, error", select.phone, "passwordExpired");			
		ElsIf select.password = password Then			
			Return New Structure("phone, error", select.phone, "");
		Else
			Account.incPasswordInputCount(token);
			Return New Structure("phone, error", select.phone, "passwordNotCorrect");			
		EndIf;
	EndIf;

EndFunction

Function requestParameters(parameters) Export
	For Each parameter In StrSplit(getRequiredParameters(parameters.requestName), ",") Do
		If parameter <> "" Then
			If Not parameters.requestStruct.Property(parameter)
					Or Not ValueIsFilled(parameters.requestStruct[parameter]) Then
				Return parameter + "Error";
			EndIf;
		EndIf;
	EndDo;
	Return "";
EndFunction

Function getRequiredParameters(requestName)
	If requestName = "config" Then
		Return "appType,systemType";
	ElsIF requestName = "gymschedule" Then
		Return "gymList,startDate,endDate";	
	ElsIf requestName = "signin" Then
		Return "phone,chainCode";
	ElsIF requestName = "confirmphone" Then
		Return "password";
	ElsIF requestName = "registerdevice" Then
		Return "appType,appVersion,deviceModel,systemType";
	ElsIF requestName = "payment" Then
		Return "uid";
	ElsIF requestName = "paymentstatus" Then
		Return "uid";
	ElsIF requestName = "unbindcard" Then
		Return "uid";	
	ElsIF requestName = "addusertotoken" Then
		Return "uid";		
//	ElsIF requestName = "imagePOST" Then
//		Return "object,extension";		
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
				parameters.Insert("error", "noValidRequest");
			Else
				requestStruct.Property("timeStamp", timeStamp);
				requestStruct.Property("hash", hash);
				If Not ValueIsFilled(timeStamp) Or Not ValueIsFilled(hash) Then
					parameters.Insert("error", "noValidRequest");
//				ElsIf (ToUniversalTime(CurrentDate()) - Date("19700101"))
//						- timeStamp > 300 Then
//					parameters.Insert("error", "noValidRequest");
				Else
					parameters.Insert("error", Crypto.checkHasp(timeStamp, hash));
				EndIf;
			EndIf;
		EndIf;
	Else
		tokenContext = TokenReuse.getContext(parameters.authKey);
		If tokenContext.token.IsEmpty() Then
			parameters.Insert("error", "noValidRequest");			
		Else
			parameters.Insert("tokenContext", tokenContext);
			parameters.Insert("currentTime", ToLocalTime(ToUniversalTime(CurrentDate()), tokenContext.timezone));			
		EndIf;
	EndIf;
EndProcedure

Procedure ChangeProperty(val account, struct) Export
	accountObject = account.GetObject();
	If accountObject <> Undefined Then		
		For Each element In struct Do
			accountObject[element.key] = element.value;
		EndDo;
		accountObject.changeDate = ToUniversalTime(CurrentDate());
		accountObject.Write();
	EndIf;
EndProcedure

Function accessRequest(parameters) Export
	If parameters.tokenContext.token = Catalogs.tokens.EmptyRef() then
		user = Catalogs.users.EmptyRef();
		chain = catalogs.chains.EmptyRef();
		appType = enums.appTypes.EmptyRef();
	else
		user = parameters.tokenContext.user;
		chain = parameters.tokenContext.token.chain;
		appType = parameters.tokenContext.appType;
	EndIf;
	method = parameters.requestName;
	query = new query;
	query.Text = "SELECT
	|	usersRestriction.restriction
	|INTO TTRestriction
	|FROM
	|	InformationRegister.usersRestriction AS usersRestriction
	|WHERE
	|	usersRestriction.user = &user
	|	AND usersRestriction.chain = &chain
	|	AND usersRestriction.restriction.appType = &appType
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTRestriction.restriction,
	|	restrictionsmethods.method
	|FROM
	|	TTRestriction AS TTRestriction
	|		LEFT JOIN Catalog.restrictions.methods AS restrictionsmethods
	|		ON TTRestriction.restriction = restrictionsmethods.Ref
	|WHERE
	|	restrictionsmethods.method LIKE &method";
	query.SetParameter("user", user);
	query.SetParameter("chain", chain);
	query.SetParameter("appType", appType);
	query.SetParameter("method", method);
	result = query.Execute();
	if result.IsEmpty() then
		return "";
	EndIf;
	return "accessDenied";
EndFunction
