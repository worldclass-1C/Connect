
Функция УзелСообщенияКОтправке(КаналИнформирования) Экспорт
	Возврат ПланыОбмена.СообщенияКОтправке.НайтиПоРеквизиту("КаналИнформирования", КаналИнформирования);	
КонецФункции

Функция УзелСообщенияПроверкаСтатуса(КаналИнформирования) Экспорт
	Возврат ПланыОбмена.СообщенияПроверкаСтатуса.НайтиПоРеквизиту("КаналИнформирования", КаналИнформирования);	
КонецФункции

Функция УзелРегистрацияПользователя(ТипРегистрации) Экспорт
	Возврат ПланыОбмена.РегистрацияПользователей.НайтиПоРеквизиту("ТипРегистрации", ТипРегистрации);	
КонецФункции

Функция ДанныеАутентификации(ОперационнаяСистема, Сертификат) Экспорт
	Если ОперационнаяСистема = Перечисления.ОперационныеСистемы.Android Тогда
		Возврат Сертификат;
	Иначе	
		Возврат ПолучитьОбщийМакет(Сертификат);
	КонецЕсли;
КонецФункции

Function checkToken(language, token) Export
	
	answer		= New Structure();
	answer.Insert("token", Catalogs.Токены.EmptyRef());
	answer.Insert("user", Catalogs.Пользователи.EmptyRef());
	answer.Insert("userType", "");
	answer.Insert("holding", Catalogs.Холдинги.EmptyRef());
	answer.Insert("chain", Catalogs.Сети.EmptyRef());
	answer.Insert("appType", Catalogs.ВидыПриложений.EmptyRef());
	answer.Insert("systemType", Перечисления.ОперационныеСистемы.EmptyRef());
	answer.Insert("timezone", Catalogs.ЧасовыеПояса.EmptyRef());
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
		|		Токены.Пользователь КАК user,
		|		Токены.Пользователь.ТипПользователя КАК userType,
		|		Токены.Сеть КАК chain,
		|		Токены.Холдинг КАК holding,
		|		Токены.ВидПриложения КАК appType,
		|		Токены.ОперационнаяСистема КАК systemType,
		|		Токены.ЧасовойПояс КАК timezone,
		|		Токены.ДатаБлокировки КАК ДатаБлокировки
		|	ИЗ
		|		Справочник.Токены КАК Токены
		|	ГДЕ
		|		Токены.Ссылка = &token) КАК ВЗ
		|ГДЕ
		|	ВЗ.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)";
		
		query.SetParameter("token", XMLValue(Type("CatalogRef.Токены"), token));		
		
		queryResult	= query.Execute();		
		
		If Not queryResult.IsEmpty() Then
			selection	= queryResult.Select();
			selection.Next();		
			answer.Insert("token", selection.token);
			answer.Insert("user", selection.user);
			answer.Insert("userType", selection.ТипПользователя);
			answer.Insert("holding", selection.Холдинг);
			answer.Insert("chain", selection.Сеть);
			answer.Insert("appType", selection.ВидПриложения);
			answer.Insert("systemType", selection.ОперационнаяСистема);
			answer.Insert("timezone", selection.ЧасовойПояс);
			answer.Insert("errorDescription", Service.getErrorDescription(language, ""));
		EndIf;		
	
	EndIf;
	
	Return answer;
	
EndFunction

Функция ПолучитьБазовыйURL() Экспорт
	Возврат  Константы.БазовыйURL.Получить();	
КонецФункции

Function phoneMasksList() Export
	
	array	= New Array();		
	query	= New Query();
	
	query.Text	= "ВЫБРАТЬ
	|	МаскиНомеровТелефонов.КодСтраны,
	|	МаскиНомеровТелефонов.Description
	|ИЗ
	|	Справочник.МаскиНомеровТелефонов КАК МаскиНомеровТелефонов
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


