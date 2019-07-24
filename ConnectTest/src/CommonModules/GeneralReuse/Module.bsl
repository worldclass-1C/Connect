
Function УзелСообщенияКОтправке(КаналИнформирования) Export
	Возврат ПланыОбмена.messagesToSend.НайтиПоРеквизиту("informationChannel", КаналИнформирования);	
EndFunction

Function УзелСообщенияПроверкаСтатуса(КаналИнформирования) Export
	Возврат ПланыОбмена.messagesToCheckStatus.НайтиПоРеквизиту("informationChannel", КаналИнформирования);	
EndFunction

Function УзелРегистрацияПользователя(ТипРегистрации) Export
	Возврат ПланыОбмена.usersCheckIn.НайтиПоРеквизиту("ТипРегистрации", ТипРегистрации);	
EndFunction

Function ДанныеАутентификации(ОперационнаяСистема, Сертификат) Export
	Если ОперационнаяСистема = Enums.systemTypes.Android Тогда
		Возврат Сертификат;
	Иначе	
		Возврат ПолучитьОбщийМакет(Сертификат);
	КонецЕсли;
EndFunction

Function checkToken(language, token) Export
	
	answer		= New Structure();
	answer.Insert("token", Catalogs.tokens.EmptyRef());
	answer.Insert("user", Catalogs.users.EmptyRef());
	answer.Insert("userType", "");
	answer.Insert("holding", Catalogs.holdings.EmptyRef());
	answer.Insert("chain", Catalogs.chain.EmptyRef());
	answer.Insert("appType", Enums.appTypes.EmptyRef());
	answer.Insert("systemType", Enums.systemTypes.EmptyRef());
	answer.Insert("timezone", Catalogs.timeZones.EmptyRef());
	answer.Insert("errorDescription", Service.getErrorDescription(language, "userNotIdentified"));		
	
	If ValueIsFilled(token) Then
		
		query = New Query();			
		query.Text	= "ВЫБРАТЬ
		|	ВЗ.token КАК token,
		|	ВЗ.user КАК user,
		|	ВЗ.userType КАК userType,
		|	ВЗ.chain КАК chain,
		|	ВЗ.holding КАК holding,
		|	ВЗ.appType КАК appType,
		|	ВЗ.systemType КАК systemType,
		|	ВЗ.timezone КАК timezone
		|ИЗ
		|	(ВЫБРАТЬ
		|		Токены.Ссылка КАК token,
		|		Токены.user КАК user,
		|		Токены.user.userType КАК userType,
		|		Токены.chain КАК chain,
		|		Токены.holding КАК holding,
		|		Токены.appType КАК appType,
		|		Токены.systemType КАК systemType,
		|		Токены.timeZone КАК timezone,
		|		Токены.lockDate КАК lockDate
		|	ИЗ
		|		Справочник.tokens КАК Токены
		|	ГДЕ
		|		Токены.Ссылка = &token) КАК ВЗ
		|ГДЕ
		|	ВЗ.lockDate = ДАТАВРЕМЯ(1, 1, 1)";
		
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

Function ПолучитьБазовыйURL() Export
	Возврат  Константы.BaseURL.Получить();	
EndFunction

Function phoneMasksList() Export
	
	array	= New Array();		
	query	= New Query();
	
	query.Text	= "ВЫБРАТЬ
	|	МаскиНомеровТелефонов.CountryCode,
	|	МаскиНомеровТелефонов.Description
	|ИЗ
	|	Справочник.phoneMasks КАК МаскиНомеровТелефонов
	|ГДЕ
	|	Не МаскиНомеровТелефонов.ПометкаУдаления";
	
	selection	= query.Execute().Select();
	
	While selection.Next() Do
		answer	= New Structure();
		answer.Вставить("code", selection.КодСтраны);
		answer.Вставить("mask", selection.Description);		
		array.add(answer);
	EndDo;
		
	Return array;
	
EndFunction


