
Function get(token, parameters) Export
	currentDate = ToUniversalTime(CurrentDate());
	If token.IsEmpty() Then
		tokenObject = Catalogs.tokens.CreateItem();
		tokenObject.createDate = currentDate;
	Else
		tokenObject = token.GetObject();
	EndIf;
	tokenObject.appType = parameters.appType;
	tokenObject.appVersion = parameters.appVersion;
	tokenObject.chain = parameters.chain;
	tokenObject.changeDate = currentDate;
	tokenObject.deviceModel = parameters.deviceModel;
	tokenObject.deviceToken = parameters.deviceToken;
	tokenObject.holding = parameters.holding;
	tokenObject.systemType = parameters.systemType;
	tokenObject.systemVersion = ?(parameters.Property("systemVersion"),parameters.systemVersion,"");
	tokenObject.timeZone = parameters.timeZone;
	tokenObject.Write();
	Return tokenObject.Ref;
EndFunction	

Function initContext() Export
	tokenContext		= New Structure();
	tokenContext.Insert("token", Catalogs.tokens.EmptyRef());
	tokenContext.Insert("appType", Enums.appTypes.EmptyRef());
	tokenContext.Insert("appVersion", 0);
	tokenContext.Insert("chain", Catalogs.chains.EmptyRef());
	tokenContext.Insert("changeDate", Date(1,1,1));
	tokenContext.Insert("createDate", Date(1,1,1));
	tokenContext.Insert("deviceModel", "");
	tokenContext.Insert("deviceToken", "");
	tokenContext.Insert("holding", Catalogs.holdings.EmptyRef());
	tokenContext.Insert("lockDate", Date(1,1,1));
	tokenContext.Insert("systemType", Enums.systemTypes.EmptyRef());
	tokenContext.Insert("systemVersion", "");
	tokenContext.Insert("timezone", Catalogs.timeZones.EmptyRef());
	tokenContext.Insert("underControl", False);	
	tokenContext.Insert("user", Catalogs.users.EmptyRef());
	tokenContext.Insert("account", Catalogs.accounts.EmptyRef());
	tokenContext.Insert("userType", "");
	Return tokenContext;	
EndFunction

Procedure block(token) Export
	tokenObject = token.GetObject();
	tokenObject.lockDate = ToUniversalTime(CurrentDate());
	tokenObject.Write();	
	If not token.user.IsEmpty() Then
		ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), token.user);
	EndIf;
EndProcedure

Procedure editProperty(val token, struct) Export
	tokenObject = token.GetObject();
	If tokenObject <> Undefined Then
		If (ValueIsFilled(tokenObject.account) and tokenObject.account<>catalogs.accounts.Tilda) or (NOT ValueIsFilled(tokenObject.account)) then		
			For Each element In struct Do
				If element.key = "user" Then
					ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), ?(ValueIsFilled(element.value), element.value, tokenObject.user));
				EndIf;
				tokenObject[element.key] = element.value;
			EndDo;
			tokenObject.changeDate = ToUniversalTime(CurrentDate());
			try
				tokenObject.Write();
			Except
			EndTry;	
		EndIf;
	EndIf;
EndProcedure
