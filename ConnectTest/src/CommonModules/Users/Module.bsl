
Function checkPassword(language, user, password) Export
		
	query	= New Query();
	query.Text	= "select TOP 1
	|	UserPasswords.user as user
	|from
	|	InformationRegister.UserPasswords as UserPasswords
	|where
	|	UserPasswords.user = &user
	|	and UserPasswords.password = &password";
	
	query.SetParameter("user", user);
	query.SetParameter("password", password);
	
	queryResult	= query.Execute();
		
	If queryResult.IsEmpty() Then		
		errorDescription	= Service.getErrorDescription(language, "passwordIsNotCorrect");
	Else
		errorDescription	= Service.getErrorDescription(language, "");
	EndIf;
	
	Return errorDescription;
	
EndFunction

Function tempPassword(Length = 4) Export 
	password	= "";	
	RNG			= New RandomNumberGenerator();	
	For index = 1 To Length Do				
		password		= password + Char(RNG.RandomNumber(48,57));
	EndDo;		
	Return password;	
EndFunction

Function setUserPassword(user, password = "") Export
	validity	= Date(1,1,1);	
	If password = "" Then
		password	= tempPassword();
		validity	= ToUniversalTime(CurrentDate()) + 900; //время действия пароля 15 минут
	EndIf;	
	record	= InformationRegisters.UserPasswords.CreateRecordManager();
	record.User			= user;
	record.Password		= password;
	record.Validity	= validity;
	record.Write();	
	Return password;
EndFunction

Function token(requestStruct, user, chain, holding, timezone) Export
	tokenObject	= Catalogs.Токены.CreateItem();
	tokenObject.ДатаСоздания		= ToUniversalTime(CurrentDate());
	tokenObject.Пользователь		= user;
	tokenObject.Холдинг				= holding;
	tokenObject.Сеть				= chain;
	tokenObject.ЧасовойПояс			= timezone;
	tokenObject.ВидПриложения		= Перечисления.ВидыПриложений[requestStruct.appType];
	tokenObject.ОперационнаяСистема	= Перечисления.ОперационныеСистемы[requestStruct.systemType];
	tokenObject.Write();
	ExchangePlans.RecordChanges(ОбщегоНазначенияПовторноеИспользование.УзелРегистрацияПользователя(Enums.ТипыРегистрации.Регистрация), user);
	Return tokenObject;
EndFunction

Procedure blockToken(token) Export	
	tokenObject	= token.GetObject();
	tokenObject.ДатаБлокировки	= ToUniversalTime(CurrentDate());
	tokenObject.Write();	
	record	= InformationRegisters.ЗарегистрированныеУстройства.CreateRecordManager();
	record.Токен	= token;
	record.Read();
	If record.Selected() Then
		record.Delete();
	EndIf;	
	ExchangePlans.RecordChanges(ОбщегоНазначенияПовторноеИспользование.УзелРегистрацияПользователя(Enums.ТипыРегистрации.Регистрация), tokenObject.user);	
EndProcedure
