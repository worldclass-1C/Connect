
Function tempPassword(Length = 4) Export
	password = "";
	RNG = New RandomNumberGenerator();
	For index = 1 To Length Do
		password = password + Char(RNG.RandomNumber(48, 57));
	EndDo;
	Return password;
EndFunction

Function getUserFromExternalSystem(val parameters, val parametrName,
		val parametrValue, val account = Undefined) Export

	tokenСontext = parameters.tokenСontext;
	language = parameters.language;
	errorDescription = parameters.errorDescription;	
	userProfile = initProfileStruct();
	userList = New Array();
	
	parametersNew = Service.getStructCopy(parameters);
	parametersNew.Insert("requestName", "userProfile");
	parametersNew.requestStruct.Insert(parametrName, parametrValue);
	General.executeRequestMethod(parametersNew);
	If parametersNew.errorDescription.result = "" Then
		answerStruct = HTTP.decodeJSON(parametersNew.answerBody);
		If answerStruct.Count() = 1 Then
			If account = Undefined Then
				accountArray = Service.createCatalogItems("addChangeAccounts", tokenСontext.holding, answerStruct);
				account = accountArray[0];
				setAccountStatus(account);								
			EndIf;
			userProfile = profileStruct(account);
			userArray = Service.createCatalogItems("addChangeUsers", tokenСontext.holding, answerStruct, account);
			Token.editProperty(tokenСontext.token, New Structure("account, user", account, userArray[0]));
			tokenСontext.account = account;
			tokenСontext.user = userArray[0];						
		ElsIf answerStruct.Count() > 1 Then			
			For Each user In answerStruct Do
				userList.Add(New Structure("name, uid", user.lastName + " "
					+ user.firstName + " " + user.secondName, user.uid));
			EndDo;
			If account <> Undefined Then
				Token.editProperty(tokenСontext.token, New Structure("account", account));
				tokenСontext.account = account;			
			EndIf;			
		Else
			errorDescription = Service.getErrorDescription(language, "passwordNotCorrect"); //Хотя такого быть не должно									
		EndIf;
	Else
		errorDescription = parametersNew.errorDescription;
	EndIf;

	Return New Structure("response, errorDescription", New Structure("userProfile, userList", userProfile, userList), errorDescription);

EndFunction

Function getStatus(account)
	
	querry = New Query("SELECT
	|	CASE
	|		WHEN accounts.firstName = """"
	|		OR accounts.lastName = """"
	|		OR accounts.email = """"
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

Function setAccountStatus(val account, val status = Undefined) Export
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

Function profileStruct(account) Export
	
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
	|	accounts.gender,
	|	REFPRESENTATION(accounts.status) AS status
	|FROM
	|	Catalog.accounts AS accounts
	|WHERE
	|	accounts.Ref = &account";
	
	query.SetParameter("account", account);
	
	queryResult	= query.Execute();
	
	If Not queryResult.IsEmpty() Then
		selection = queryResult.Select();
		selection.Next();
		struct.Insert("phone", selection.phone);
		struct.Insert("birthday", selection.birthday);
		struct.Insert("canUpdatePersonalData", selection.canUpdatePersonalData);
		struct.Insert("email", selection.email);
		struct.Insert("firstName", selection.firstName);
		struct.Insert("lastName", selection.lastName);
		struct.Insert("registrationDate", selection.registrationDate);
		struct.Insert("secondName", selection.secondName);
		struct.Insert("gender", selection.gender);
		struct.Insert("status", selection.status);
		struct.Insert("photo", "");
	EndIf;
	
	Return struct;
	
EndFunction

Function initProfileStruct()	
	Return New Structure("phone, birthday, canUpdatePersonalData, email, firstName, lastName, registrationDate, secondName, gender, status, photo", "", Undefined, False, "", "", "", Undefined, "", "", "", "");
EndFunction

Procedure incPasswordSendCount(token, phone, password) Export
	record = InformationRegisters.usersAuthorizationCodes.CreateRecordManager();
	record.token = token;		
	record.Read();
	If record.Selected() Then
		record.password = password;
		record.phone = phone;
		record.sendCount = record.sendCount + 1;  
	Else
		record.token = token;		
		record.password = password;
		record.phone = phone;
		record.sendCount = 1;
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
