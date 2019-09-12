
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
	tokenObject.systemVersion = parameters.systemVersion;
	tokenObject.timeZone = parameters.timeZone;
	tokenObject.Write();
	Return tokenObject.Ref;
EndFunction	

Function initContext() Export
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

Procedure block(token) Export
	tokenObject = token.GetObject();
	tokenObject.lockDate = ToUniversalTime(CurrentDate());
	tokenObject.Write();
	record = InformationRegisters.registeredDevices.CreateRecordManager();
	record.token = token;
	record.Read();
	If record.Selected() Then
		record.Delete();
	EndIf;
	ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), tokenObject.user);
EndProcedure

Procedure editProperty(token, struct) Export
	tokenObject = token.GetObject();
	If tokenObject <> Undefined Then		
		For Each element In struct Do
			If element.key = "account" Then
				ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), ?(ValueIsFilled(element.value), element.value, tokenObject.account));
			EndIf;
			tokenObject[element.key] = element.value;
		EndDo;
		tokenObject.changeDate = ToUniversalTime(CurrentDate());
		tokenObject.Write();
	EndIf;
EndProcedure
