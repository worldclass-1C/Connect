
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
				ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), ?(ValueIsFilled(element.value), element.value, tokenObject[element.key]));
			EndIf;
			tokenObject[element.key] = element.value;
		EndDo;
		tokenObject.changeDate = ToUniversalTime(CurrentDate());
		tokenObject.Write();
	EndIf;
EndProcedure
