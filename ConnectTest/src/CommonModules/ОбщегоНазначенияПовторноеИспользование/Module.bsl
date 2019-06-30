
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

Функция ПроверитьТокен(ЯзыкПриложения, КлючАвторизации) Экспорт
	
	СтруктураОтвета		= Новый Структура;
	СтруктураОтвета.Вставить("Токен", Справочники.Токены.ПустаяСсылка());
	СтруктураОтвета.Вставить("Пользователь", Справочники.Пользователи.ПустаяСсылка());
	СтруктураОтвета.Вставить("ТипПользователя", "");
	СтруктураОтвета.Вставить("Холдинг", Справочники.Холдинги.ПустаяСсылка());
	СтруктураОтвета.Вставить("Сеть", Справочники.Сети.ПустаяСсылка());
	СтруктураОтвета.Вставить("ВидПриложения", Перечисления.ВидыПриложений.ПустаяСсылка());
	СтруктураОтвета.Вставить("ОперационнаяСистема", Перечисления.ОперационныеСистемы.ПустаяСсылка());
	СтруктураОтвета.Вставить("ЧасовойПояс", Справочники.ЧасовыеПояса.ПустаяСсылка());
	СтруктураОтвета.Вставить("ОписаниеОшибки", Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, "userNotIdentified"));		
	
	Если КлючАвторизации <> "" Тогда
		пЗапрос	= Новый Запрос;
		пЗапрос.Текст	= "ВЫБРАТЬ
		             	  |	ВЗ.Ссылка КАК Ссылка,
		             	  |	ВЗ.Пользователь КАК Пользователь,
		             	  |	ВЗ.ТипПользователя КАК ТипПользователя,
		             	  |	ВЗ.Сеть КАК Сеть,
		             	  |	ВЗ.Холдинг КАК Холдинг,
		             	  |	ВЗ.ВидПриложения КАК ВидПриложения,
		             	  |	ВЗ.ОперационнаяСистема КАК ОперационнаяСистема,
		             	  |	ВЗ.ЧасовойПояс КАК ЧасовойПояс
		             	  |ИЗ
		             	  |	(ВЫБРАТЬ
		             	  |		Токены.Ссылка КАК Ссылка,
		             	  |		Токены.Пользователь КАК Пользователь,
		             	  |		Токены.Пользователь.ТипПользователя КАК ТипПользователя,
		             	  |		Токены.Сеть КАК Сеть,
		             	  |		Токены.Холдинг КАК Холдинг,
		             	  |		Токены.ВидПриложения КАК ВидПриложения,
		             	  |		Токены.ОперационнаяСистема КАК ОперационнаяСистема,
		             	  |		Токены.ЧасовойПояс КАК ЧасовойПояс,
		             	  |		Токены.ДатаБлокировки КАК ДатаБлокировки
		             	  |	ИЗ
		             	  |		Справочник.Токены КАК Токены
		             	  |	ГДЕ
		             	  |		Токены.Ссылка = &Токен) КАК ВЗ
		             	  |ГДЕ
		             	  |	ВЗ.ДатаБлокировки = ДАТАВРЕМЯ(1, 1, 1)";
		
		пЗапрос.УстановитьПараметр("Токен", XMLЗначение(Тип("СправочникСсылка.Токены"), КлючАвторизации));		
		
		РезультатЗапроса	= пЗапрос.Выполнить();		
		
		Если Не РезультатЗапроса.Пустой() Тогда
			Выборка			= РезультатЗапроса.Выбрать();
			Выборка.Следующий();		
			СтруктураОтвета.Вставить("Токен", Выборка.Ссылка);
			СтруктураОтвета.Вставить("Пользователь", Выборка.Пользователь);
			СтруктураОтвета.Вставить("ТипПользователя", Выборка.ТипПользователя);
			СтруктураОтвета.Вставить("Холдинг", Выборка.Холдинг);
			СтруктураОтвета.Вставить("Сеть", Выборка.Сеть);
			СтруктураОтвета.Вставить("ВидПриложения", Выборка.ВидПриложения);
			СтруктураОтвета.Вставить("ОперационнаяСистема", Выборка.ОперационнаяСистема);
			СтруктураОтвета.Вставить("ЧасовойПояс", Выборка.ЧасовойПояс);
			СтруктураОтвета.Вставить("ОписаниеОшибки", Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, ""));
		КонецЕсли;		
	КонецЕсли;

	Возврат СтруктураОтвета;
	
КонецФункции
