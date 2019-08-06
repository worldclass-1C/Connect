Function checkPassword(language, user, password) Export

	query = New Query();
	query.Text = "select TOP 1
		|	UserPasswords.account as account
		|from
		|	InformationRegister.usersPasswords as UserPasswords
		|where
		|	UserPasswords.account = &account
		|	and UserPasswords.password = &password";

	query.SetParameter("account", user);
	query.SetParameter("password", password);

	queryResult = query.Execute();

	If queryResult.IsEmpty() Then
		errorDescription = Service.getErrorDescription(language, "passwordIsNotCorrect");
	Else
		errorDescription = Service.getErrorDescription(language, "");
	EndIf;

	Return errorDescription;

EndFunction

Function tempPassword(Length = 4) Export
	password = "";
	RNG = New RandomNumberGenerator();
	For index = 1 To Length Do
		password = password + Char(RNG.RandomNumber(48, 57));
	EndDo;
	Return password;
EndFunction

Function setUserPassword(user, password = "") Export
	validity = Date(1, 1, 1);
	If password = "" Then
		password = tempPassword();
		validity = ToUniversalTime(CurrentDate()) + 900; //время действия пароля 15 минут
	EndIf;
	record = InformationRegisters.usersPasswords.CreateRecordManager();
	record.account = user;
	record.Password = password;
	record.Validity = validity;
	record.Write();
	Return password;
EndFunction

Function getToken(token, parameters) Export
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

Procedure blockToken(token) Export
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

Procedure editPropertyInToken(token, name, value) Export
	tokenObject = token.GetObject();
	If name = "account" Then
		ExchangePlans.RecordChanges(GeneralReuse.nodeUsersCheckIn(Enums.registrationTypes.checkIn), ?(ValueIsFilled(value), value, tokenObject[name]));
	EndIf;
	tokenObject[name] = value;
	tokenObject.changeDate = ToUniversalTime(CurrentDate());
	tokenObject.Write();
EndProcedure

