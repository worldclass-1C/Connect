
Функция ПроверитьПароль(ЯзыкПриложения, Пользователь, Пароль) Экспорт
		
	пЗапрос	= Новый Запрос;
	пЗапрос.Текст	= "ВЫБРАТЬ ПЕРВЫЕ 1
	             	  |	ПаролиПользователей.Пользователь КАК Пользователь
	             	  |ИЗ
	             	  |	РегистрСведений.ПаролиПользователей КАК ПаролиПользователей
	             	  |ГДЕ
	             	  |	ПаролиПользователей.Пользователь = &Пользователь
	             	  |	И ПаролиПользователей.Пароль = &Пароль";
	
	пЗапрос.УстановитьПараметр("Пользователь", Пользователь);
	пЗапрос.УстановитьПараметр("Пароль", Пароль);
	
	РезультатЗапроса	= пЗапрос.Выполнить();
	
	Если РезультатЗапроса.Пустой() Тогда		
		ОписаниеОшибки	= Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, "passwordIsNotCorrect");
	Иначе
		ОписаниеОшибки	= Служебный.ПолучитьОписаниеОшибки(ЯзыкПриложения, "");
	КонецЕсли;
	
	Возврат ОписаниеОшибки;
	
КонецФункции

Функция ВременныйПароль(ДлинаПароля = 4) Экспорт 
	Пароль	= "";	
	ГСЧ		= Новый ГенераторСлучайныхЧисел();	
	Для Сч = 1 По ДлинаПароля Цикл		
		СлучайноеЧисло	= ГСЧ.СлучайноеЧисло(48,57);		
		Пароль	=	Пароль + Символ(СлучайноеЧисло);
	КонецЦикла;	
	Возврат Пароль;	
КонецФункции

Функция УстановитьПарольПользователя(Пользователь, Пароль = "") Экспорт 
	
	СрокДействия	= Дата(1,1,1);
	
	Если Пароль = "" Тогда
		Пароль	= ВременныйПароль();
		СрокДействия	= УниверсальноеВремя(ТекущаяДата()) + 900; //время действия пароля 15 минут
	КонецЕсли;
	
	Запись	= РегистрыСведений.ПаролиПользователей.СоздатьМенеджерЗаписи();
	Запись.Пользователь	= Пользователь;
	Запись.Пароль		= Пароль;
	Запись.СрокДействия	= СрокДействия;
	Запись.Записать();
	
	Возврат Пароль;
	
КонецФункции

Процедура ОбработкаПолученияПолейПредставления(Поля, СтандартнаяОбработка)
	
	СтандартнаяОбработка = Ложь;
	
	ПоляПредставления = Новый Массив;
	ПоляПредставления.Добавить("Фамилия");
	ПоляПредставления.Добавить("Имя");	
	ПоляПредставления.Добавить("Холдинг");		
	
	Поля = ПоляПредставления;
	
КонецПроцедуры

Процедура ОбработкаПолученияПредставления(Данные, Представление, СтандартнаяОбработка)	
	
	СтандартнаяОбработка = Ложь;
	Представление	= "" + Данные.Фамилия + " " + Данные.Имя + " (" + Данные.Холдинг + ")";		
	
КонецПроцедуры

