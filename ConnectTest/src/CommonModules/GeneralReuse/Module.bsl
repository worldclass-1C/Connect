
Function nodeMessagesToSend(informationChannel) Export
	Return ExchangePlans.messagesToSend.FindByAttribute("informationChannel", informationChannel);	
EndFunction

Function nodeMessagesToCheckStatus(informationChannel) Export
	Return ExchangePlans.messagesToCheckStatus.FindByAttribute("informationChannel", informationChannel);	
EndFunction

Function nodeUsersCheckIn(registrationType) Export
	Return ExchangePlans.usersCheckIn.FindByAttribute("registrationType", registrationType);	
EndFunction

Function getAuthorizationKey(systemType, certificate) Export
	If systemType = Enums.systemTypes.Android Then
		Return certificate;
	Else	
		Return GetCommonTemplate(certificate);
	EndIf;
EndFunction

Function checkToken(language, token) Export
	
	answer		= New Structure();
	answer.Insert("token", Catalogs.tokens.EmptyRef());
	answer.Insert("user", Catalogs.users.EmptyRef());
	answer.Insert("userType", "");
	answer.Insert("holding", Catalogs.holdings.EmptyRef());
	answer.Insert("chain", Catalogs.chains.EmptyRef());
	answer.Insert("appType", Enums.appTypes.EmptyRef());
	answer.Insert("systemType", Enums.systemTypes.EmptyRef());
	answer.Insert("timezone", Catalogs.timeZones.EmptyRef());
	answer.Insert("errorDescription", Service.getErrorDescription(language, "userNotIdentified"));		
	
	If ValueIsFilled(token) Then
		
		query = New Query();			
		query.Text	= "SELECT
		|	SQ.token AS token,
		|	SQ.user AS user,
		|	SQ.userType AS userType,
		|	SQ.chain AS chain,
		|	SQ.holding AS holding,
		|	SQ.appType AS appType,
		|	SQ.systemType AS systemType,
		|	SQ.timezone AS timezone
		|FROM
		|	(SELECT
		|		tokens.ref AS token,
		|		tokens.user AS user,
		|		tokens.user.userType AS userType,
		|		tokens.chain AS chain,
		|		tokens.holding AS holding,
		|		tokens.appType AS appType,
		|		tokens.systemType AS systemType,
		|		tokens.timeZone AS timezone,
		|		tokens.lockDate AS lockDate
		|	FROM
		|		Catalog.tokens AS tokens
		|	WHERE
		|		tokens.ref = &token) AS SQ
		|WHERE
		|	SQ.lockDate = DATETIME(1, 1, 1)";
		
		query.SetParameter("token", XMLValue(Type("CatalogRef.tokens"), token));		
		
		queryResult	= query.Execute();		
		
		If Not queryResult.IsEmpty() Then
			selection	= queryResult.Select();
			selection.Next();		
			answer.Insert("token", selection.token);
			answer.Insert("user", selection.user);
			answer.Insert("userType", selection.userType);
			answer.Insert("holding", selection.holding);
			answer.Insert("chain", selection.chain);
			answer.Insert("appType", selection.appType);
			answer.Insert("systemType", selection.systemType);
			answer.Insert("timezone", selection.timezone);
			answer.Insert("errorDescription", Service.getErrorDescription(language, ""));
		EndIf;		
	
	EndIf;
	
	Return answer;
	
EndFunction

Function getBaseURL() Export
	Return  Constants.BaseURL.Get;	
EndFunction

Function getCountryCodeList() Export
	
	array	= New Array();		
	query	= New Query();
	
	query.Text	= "SELECT
	|	CountryCodes.CountryCode,
	|	CountryCodes.Description
	|FROM
	|	Catalog.CountryCodes AS CountryCodes
	|WHERE
	|	NOT CountryCodes.DeletionMark";
	
	selection	= query.Execute().Select();
	
	While selection.Next() Do
		answer	= New Structure();
		answer.Вставить("code", selection.CountryCode);
		answer.Вставить("mask", selection.Description);		
		array.add(answer);
	EndDo;
		
	Return array;
	
EndFunction


