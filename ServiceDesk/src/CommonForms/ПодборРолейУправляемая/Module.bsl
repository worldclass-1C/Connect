////////////////////////////////////////////////////////////////////////////////
// ПРОЦЕДУРЫ ДЕРЕВА РОЛЕЙ
 
&НаКлиенте
Процедура ИзменитьПометкуГруппыРолей(ЭлементДерева, Пометка)
	
	Если ЭлементДерева = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	КоличествоПомеченныхЭлементов = Ложь;
	КоллекцияПодчиненныхЭлементов = ЭлементДерева.ПолучитьЭлементы();
	Для Каждого ПодчиненныйЭлемент Из КоллекцияПодчиненныхЭлементов Цикл
		Если ПодчиненныйЭлемент.Пометка = 1 Тогда
			КоличествоПомеченныхЭлементов = КоличествоПомеченныхЭлементов + 1;
		КонецЕсли; 
	КонецЦикла;	
	
	Если КоличествоПомеченныхЭлементов = 0 Тогда
		ЭлементДерева.Пометка = 0;
	ИначеЕсли КоличествоПомеченныхЭлементов = КоллекцияПодчиненныхЭлементов.Количество() Тогда
		ЭлементДерева.Пометка = 1;
	Иначе
		ЭлементДерева.Пометка = 2;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ИзменитьПометку(ЭлементДерева, Пометка)
	
	КоллекцияПодчиненныхЭлементов = ЭлементДерева.ПолучитьЭлементы();
	Для Каждого ПодчиненныйЭлемент Из КоллекцияПодчиненныхЭлементов Цикл
		ПодчиненныйЭлемент.Пометка = Пометка;		
	КонецЦикла;	
	
	Если ТипЗнч(ЭлементДерева) = Тип("ДанныеФормыЭлементКоллекции") Тогда
		ЭлементДерева.Пометка = Пометка;	
	КонецЕсли;
	
КонецПроцедуры

// Процедура заполняет дерево ролей
//
&НаСервере
Процедура ЗаполнитьДеревоРолейДляВыбора(СписокВыбранныхРолей)
	
	ДеревоРолей = РеквизитФормыВЗначение("ДеревоРолейДляВыбора");
	
	МакетОписаниеРолейКонфигурации = ПолучитьОбщийМакет("ОписаниеРолейКонфигурации");
	
	// Создадим группы ролей
	ОбластьГруппыРолей = МакетОписаниеРолейКонфигурации.ПолучитьОбласть("ГруппыРолей");
	Для Сч = 1 По ОбластьГруппыРолей.ВысотаТаблицы Цикл
		ИмяГруппы = ОбластьГруппыРолей.Область(Сч,1,Сч,1).Текст;
		СтрокаДереваРолей = ДеревоРолей.Строки.Добавить();
		СтрокаДереваРолей.Имя = ИмяГруппы;
		СтрокаДереваРолей.Представление = ИмяГруппы;
		СтрокаДереваРолей.ЭтоГруппаРолей = Истина;
	КонецЦикла; 
	
	Элементы.ДеревоРолейДляВыбора.ВысотаВСтрокахТаблицы = ?(ОбластьГруппыРолей.ВысотаТаблицы > 10, ОбластьГруппыРолей.ВысотаТаблицы, 10);
	
	// Обойдем список ролей из метаданных
	Для каждого РольКонфигурации Из СписокРолейКонфигурации Цикл
		
		СтрокаГруппыРолей = ДеревоРолей.Строки.Найти(РольКонфигурации.ИмяГруппы, "Имя");
		
		НоваяРоль = СтрокаГруппыРолей.Строки.Добавить();
		НоваяРоль.Имя               = РольКонфигурации.ИмяРоли;
		НоваяРоль.Представление     = РольКонфигурации.ПредставлениеРоли;
		НоваяРоль.Порядок 		    = РольКонфигурации.Порядок;
		НоваяРоль.Несамостоятельная = РольКонфигурации.Несамостоятельная;
		
		Если СписокВыбранныхРолей.Найти(РольКонфигурации.ИмяРоли) <> Неопределено Тогда
			НоваяРоль.Пометка = 1;
		Иначе
			НоваяРоль.Пометка = 0;
		КонецЕсли; 
	КонецЦикла; 
	
	
	// Установим пометки групп ролей
	Для каждого ГруппаРолей Из ДеревоРолей.Строки Цикл
		
		// Найдем роли, которые не выбраны
		МассивПометок = ГруппаРолей.Строки.НайтиСтроки(Новый Структура("Пометка", 0), Ложь);
		
		Если МассивПометок.Количество() = 0 Тогда
			// Все роли выбраны
			ГруппаРолей.Пометка = 1;
		Иначе
			// Есть роли, которые не выбраны
			
			// Найдем роли, которые выбраны
			МассивПометок = ГруппаРолей.Строки.НайтиСтроки(Новый Структура("Пометка", 1), Ложь);
			Если МассивПометок.Количество() <> 0 Тогда
				// Есть выбранные и невыбранные роли
				ГруппаРолей.Пометка = 2;
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЦикла; 
	
	ЗначениеВРеквизитФормы(ДеревоРолей, "ДеревоРолейДляВыбора");
	
КонецПроцедуры // ЗаполнитьДоступныеРоли

&НаКлиенте
Процедура ДеревоРолейДляВыбораПометкаПриИзменении(Элемент)
	
	ТекущиеДанные = Элементы.ДеревоРолейДляВыбора.ТекущиеДанные;
	
	Если ТекущиеДанные.Пометка = 2 Тогда
		ТекущиеДанные.Пометка = 0;
	КонецЕсли;
		
	ИзменитьПометку(ТекущиеДанные, ТекущиеДанные.Пометка);
	ИзменитьПометкуГруппыРолей(ТекущиеДанные.ПолучитьРодителя(), ТекущиеДанные.Пометка);
	
	Модифицированность = Истина;
	
КонецПроцедуры

// Процедура добавляет в состав профиля выбранные роли из списка доступных
//
&НаКлиенте
Процедура ДобавитьВыбранныеРоли()
	
	СоставРолей.Очистить();
	
	// Получим все выбранные роли
	МассивВыбранныхРолей = Новый Массив;
	КоллекцияГруппРолей = ДеревоРолейДляВыбора.ПолучитьЭлементы();
	Для каждого ГруппаРолей Из КоллекцияГруппРолей Цикл
		
		КоллеккцияРолей = ГруппаРолей.ПолучитьЭлементы();
		
		Для каждого ЭлРоль Из КоллеккцияРолей Цикл
			Если ЭлРоль.Пометка <> 1 Тогда
				Продолжить;
			КонецЕсли;
			МассивВыбранныхРолей.Добавить(ЭлРоль.Имя);
		КонецЦикла; 
	КонецЦикла; 
	
	// Роли нужно добавить в порядке ролей конфигурации
	Для каждого РольКонфигурации Из СписокРолейКонфигурации Цикл
		Если МассивВыбранныхРолей.Найти(РольКонфигурации.ИмяРоли) = Неопределено Тогда
			Продолжить;
		КонецЕсли; 
		
		НоваяРоль = СоставРолей.Добавить();
		НоваяРоль.ИмяРоли           = РольКонфигурации.ИмяРоли;
		НоваяРоль.ПредставлениеРоли = РольКонфигурации.ПредставлениеРоли;
		НоваяРоль.Пометка = Истина;
	КонецЦикла;
		
	Модифицированность = Ложь;
	
КонецПроцедуры // ДобавитьВыбранныеРоли

&НаКлиенте
Процедура ДеревоРолейДляВыбораВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	
	ТекущиеДанные = Элементы.ДеревоРолейДляВыбора.ТекущиеДанные;
	Если ТекущиеДанные.ПолучитьРодителя() = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	СтандартнаяОбработка = Ложь;
	
	Если ТекущиеДанные.Пометка = 2 ИЛИ ТекущиеДанные.Пометка = 1 Тогда
		ТекущиеДанные.Пометка = 0;
	Иначе
		ТекущиеДанные.Пометка = 1;
	КонецЕсли;
		
	ИзменитьПометку(ТекущиеДанные, ТекущиеДанные.Пометка);
	ИзменитьПометкуГруппыРолей(ТекущиеДанные.ПолучитьРодителя(), ТекущиеДанные.Пометка);
	
	Модифицированность = Истина;
	
КонецПроцедуры


////////////////////////////////////////////////////////////////////////////////
// ФОРМА

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	Заголовок = Параметры.ЗаголовокФормы;
	
	СписокРолейКонфигурации.Загрузить(УправлениеПользователями.ПолучитьСписокРолейКонфигурации(Истина));
	
	ЗаполнитьДеревоРолейДляВыбора(Параметры.СписокРолей);
	
КонецПроцедуры

&НаКлиенте
Процедура ПринятьИзменения(Команда)
	
	ДобавитьВыбранныеРоли();
	
	Закрыть(СоставРолей);
	
КонецПроцедуры

&НаКлиенте
Процедура РазвернутьВсеГруппы(Команда)
	КоллекцияГруппРолей = ДеревоРолейДляВыбора.ПолучитьЭлементы();
	Для каждого ГруппаРолей Из КоллекцияГруппРолей Цикл
		Элементы.ДеревоРолейДляВыбора.Развернуть(ГруппаРолей.ПолучитьИдентификатор());
	КонецЦикла; 
	
КонецПроцедуры

&НаКлиенте
Процедура СвернутьВсеГруппы(Команда)
	
	КоллекцияГруппРолей = ДеревоРолейДляВыбора.ПолучитьЭлементы();
	Для каждого ГруппаРолей Из КоллекцияГруппРолей Цикл
		Элементы.ДеревоРолейДляВыбора.Свернуть(ГруппаРолей.ПолучитьИдентификатор());
	КонецЦикла; 
	
КонецПроцедуры

