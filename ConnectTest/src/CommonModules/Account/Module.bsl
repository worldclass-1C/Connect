
Function tempPassword(Length = 4) Export
	password = "";
	RNG = New RandomNumberGenerator();
	For index = 1 To Length Do
		password = password + Char(RNG.RandomNumber(48, 57));
	EndDo;
	Return password;
EndFunction

Function getFromExternalSystem(val parameters, val parametrName,
		val parametrValue, val account = Undefined) Export
	
	parametersNew = Service.getStructCopy(parameters);
	parametersNew.Insert("requestName", "userProfileBack");
	parametersNew.Insert("internalRequestMethod", True);
	parametersNew.requestStruct.Insert(parametrName, parametrValue);
	
	tokenContext = parametersNew.tokenContext;	
	error = parametersNew.error;	
	authKey = parametersNew.authKey;
	userProfile = Users.initProfileStruct();
	userList = New Array();		
	
	General.executeRequestMethod(parametersNew);
	error = parametersNew.error;
	If error = "" Then
		answerStruct = HTTP.decodeJSON(parametersNew.answerBody);
		If answerStruct.Count() = 1 Then
			If account = Undefined Then
				accountArray = DataLoad.createItems("addChangeAccounts", tokenContext.holding, answerStruct,, parametersNew.brand);
				account = accountArray[0];
				setStatus(account);								
			EndIf;			
			userArray = DataLoad.createItems("addChangeUsers", tokenContext.holding, answerStruct, account, parametersNew.brand);
			userProfile = Users.profile(userArray[0], tokenContext.appType, tokenContext.chain);
			Token.editProperty(tokenContext.token, New Structure("account, user", account, userArray[0]));			
			authKey = XMLString(tokenContext.token) + tempPassword();			
			//parametersNew.tokenContext.Insert("user", userArray[0]);			
			//Users.updateCache(parametersNew);		
			
			//запрос кэша при регистрации пользователя
			parametersNew.tokenContext.Insert("user", userArray[0]);
			arrParams = New Array();
			arrParams.Add(parametersNew);
			BackgroundJobs.Execute("Cache.UpdateCache",arrParams )	
		ElsIf answerStruct.Count() > 1 Then			
			For Each user In answerStruct Do
				userList.Add(New Structure("name, uid", user.lastName + " "
					+ user.firstName + " " + user.secondName, user.uid));
			EndDo;
			If account <> Undefined Then
				Token.editProperty(tokenContext.token, New Structure("account", account));
			EndIf;			
		Else
			error = "passwordNotCorrect"; //Хотя такого быть не должно									
		EndIf;
	EndIf;

	Return New Structure("response, error", New Structure("userProfile, userList, token", userProfile, userList, authKey), error);

EndFunction

Function changeUser(tokenContext, user) Export
	Token.editProperty(tokenContext.token, New Structure("user", user));
	authKey = XMLString(tokenContext.token) + tempPassword();
	userProfile = Users.profile(user, tokenContext.appType, tokenContext.chain);	
	Return New Structure("response, error", New Structure("userProfile, token", userProfile, authKey), "");
EndFunction

Function getStatus(account)
	
	querry = New Query("SELECT
	|	CASE
	|		WHEN accounts.firstName = """"
	|		OR accounts.lastName = """"
	|		OR accounts.gender = """"
	|		OR accounts.birthday = DATETIME(1, 1, 1)
	|			THEN VALUE(Enum.accountStatuses.missingPersonalData)
	|		ELSE VALUE(Enum.accountStatuses.active)
	|	END AS status
	|FROM
	|	Catalog.accounts AS accounts
	|WHERE
	|	accounts.Ref = &account");
	querry.SetParameter("account", account);
	
	queryResult = querry.Execute();
	If queryResult.IsEmpty() Then
		Return Enums.accountStatuses.unauthorized;
	Else
		select = queryResult.Select();
		select.Next();
		Return select.status;
	EndIf;
		
EndFunction

Function setStatus(val account, val status = Undefined)
	If status = Undefined Then
		status = getStatus(account);	
	EndIf;	
	accountObject = account.GetObject();
	If accountObject.status <> status Then
		accountObject.status = status;
		accountObject.Write();
	EndIf;	
	Return status;
EndFunction

Function profile(account) Export
	
	struct = initProfileStruct();

	query = New Query();
	query.Text	= "SELECT
	|	accounts.Code as phone,
	|	CASE
	|		WHEN accounts.birthday = DATETIME(1, 1, 1)
	|			THEN UNDEFINED
	|		ELSE accounts.birthday
	|	END AS birthday,
	|	accounts.canUpdatePersonalData,
	|	accounts.email,
	|	accounts.firstName,
	|	accounts.lastName,
	|	accounts.registrationDate,
	|	accounts.secondName,
	|	CASE
	|		WHEN accounts.gender = """"
	|			THEN ""none""
	|		ELSE accounts.gender
	|	END AS gender,
	|	REFPRESENTATION(accounts.status) AS status,
	|	accounts.photo AS photo
	|FROM
	|	Catalog.accounts AS accounts
	|WHERE
	|	accounts.Ref = &account";
	
	query.SetParameter("account", account);
	
	queryResult	= query.Execute();
	
	If Not queryResult.IsEmpty() Then
		selection = queryResult.Select();
		selection.Next();
		FillPropertyValues(struct, selection);		
	EndIf;
	
	Return struct;
	
EndFunction

Function initProfileStruct()
	Return New Structure("phone, birthday, canUpdatePersonalData, email, firstName, lastName, registrationDate, secondName, gender, status, photo, barcode", "", Undefined, False, "", "", "", Undefined, "", "none", "unauthorized", "", "");
EndFunction

Procedure incPasswordSendCount(token, phone, password) Export
	record = InformationRegisters.usersAuthorizationCodes.CreateRecordManager();
	record.token = token;		
	record.Read();
	If record.Selected() Then
		record.password = password;
		record.phone = phone;
		record.sendCount = record.sendCount + 1;
		record.inputCount = 0;  
	Else
		record.token = token;		
		record.password = password;
		record.phone = phone;
		record.sendCount = 1;
		record.inputCount = 0;
	EndIf;	
	record.recordDate	= ToUniversalTime(CurrentDate());			
	record.Write();
EndProcedure

Procedure incPasswordInputCount(token) Export
	record = InformationRegisters.usersAuthorizationCodes.CreateRecordManager();
	record.token = token;		
	record.Read();
	If record.Selected() Then
		record.inputCount = record.inputCount + 1;
		record.recordDate	= ToUniversalTime(CurrentDate());			
		record.Write();  
	EndIf;	
EndProcedure

Procedure delPassword(token) Export
	record = InformationRegisters.usersAuthorizationCodes.CreateRecordManager();
	record.token = token;
	record.Read();
	If record.Selected() Then
		record.Delete();
	EndIf;
EndProcedure

Procedure ChangeProperty(val account, struct) Export
	accountObject = account.GetObject();
	If accountObject <> Undefined Then		
		For Each element In struct Do
			accountObject[element.key] = element.value;
		EndDo;
		accountObject.Write();
	EndIf;
EndProcedure