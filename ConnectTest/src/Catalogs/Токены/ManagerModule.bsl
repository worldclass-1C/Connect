
Процедура ОбработкаПолученияПолейПредставления(Поля, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	ПоляПредставления = Новый Массив;
	ПоляПредставления.Добавить("НаименованиеПолное");
	Поля = ПоляПредставления;
КонецПроцедуры

Процедура ОбработкаПолученияПредставления(Данные, Представление, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	Представление	= Данные.НаименованиеПолное;
КонецПроцедуры
