
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

Function initTokenContext() Export
	tokenСontext		= New Structure();
	tokenСontext.Insert("token", Catalogs.tokens.EmptyRef());
	tokenСontext.Insert("appType", Enums.appTypes.EmptyRef());
	tokenСontext.Insert("appVersion", 0);
	tokenСontext.Insert("chain", Catalogs.chains.EmptyRef());
	tokenСontext.Insert("changeDate", Date(1,1,1));
	tokenСontext.Insert("createDate", Date(1,1,1));
	tokenСontext.Insert("deviceModel", "");
	tokenСontext.Insert("deviceToken", "");
	tokenСontext.Insert("holding", Catalogs.holdings.EmptyRef());
	tokenСontext.Insert("lockDate", Date(1,1,1));
	tokenСontext.Insert("systemType", Enums.systemTypes.EmptyRef());
	tokenСontext.Insert("systemVersion", "");
	tokenСontext.Insert("timezone", Catalogs.timeZones.EmptyRef());
	tokenСontext.Insert("user", Catalogs.users.EmptyRef());
	tokenСontext.Insert("userType", "");
	Return tokenСontext;	
EndFunction

Function getTokenContext(language, authKey) Export
		
	query = New Query();
	query.Text = "SELECT
	|	tokens.Ref AS token,
	|	tokens.appType,
	|	tokens.appVersion,
	|	tokens.chain,
	|	tokens.changeDate,
	|	tokens.createDate,
	|	tokens.deviceModel,
	|	tokens.deviceToken,
	|	tokens.holding,
	|	tokens.lockDate,
	|	tokens.systemType,
	|	tokens.systemVersion,
	|	tokens.timeZone,
	|	tokens.user,
	|	ISNULL(tokens.user.userType, """") AS userType
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	NOT tokens.DeletionMark
	|	AND tokens.Ref = &token";

	query.SetParameter("token", XMLValue(Type("CatalogRef.tokens"), authKey));
	queryResult = query.Execute();
	tokenСontext = GeneralReuse.initTokenContext();
	If Not queryResult.IsEmpty() Then		
		selection = queryResult.Select();
		selection.Next();
		FillPropertyValues(tokenСontext, selection);				
	EndIf;
		
	Return tokenСontext;
	
EndFunction

