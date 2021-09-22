// Дополняет таблицу значений - приемник данными из таблицы значений - источника.
// Типы ТаблицаЗначений, ДеревоЗначений, ТабличнаяЧасть не доступны на клиенте.
//
// Параметры:
//  ТаблицаИсточник - ТаблицаЗначений
//                  - ДеревоЗначений
//                  - ТабличнаяЧасть
//                  - ДанныеФормыКоллекция - таблица, из которой будут
//                    браться строки для заполнения;
//  ТаблицаПриемник - ТаблицаЗначений
//                  - ДеревоЗначений
//                  - ТабличнаяЧасть
//                  - ДанныеФормыКоллекция - таблица, в которую будут
//                    добавлены строки из таблицы-источника.
//
Процедура ДополнитьТаблицу(ТаблицаИсточник, ТаблицаПриемник) Экспорт
	
	Для Каждого СтрокаТаблицыИсточник Из ТаблицаИсточник Цикл
		
		ЗаполнитьЗначенияСвойств(ТаблицаПриемник.Добавить(), СтрокаТаблицыИсточник);
		
	КонецЦикла;
	
КонецПроцедуры

#Область ДинамическийСписок

////////////////////////////////////////////////////////////////////////////////
// Функции для работы с отборами и параметрами динамических списков.
//

// Найти элемент или группу отбора по заданному имени поля или представлению.
//
// Параметры:
//  ОбластьПоиска - ОтборКомпоновкиДанных
//                - КоллекцияЭлементовОтбораКомпоновкиДанных
//                - ГруппаЭлементовОтбораКомпоновкиДанных    - контейнер с элементами и группами отбора,
//                                                             например Список.Отбор или группа в отборе.
//  ИмяПоля       - Строка - имя поля компоновки (не используется для групп).
//  Представление - Строка - представление поля компоновки.
//
// Возвращаемое значение:
//  Массив - коллекция отборов.
//
Функция НайтиЭлементыИГруппыОтбора(Знач ОбластьПоиска,
									Знач ИмяПоля = Неопределено,
									Знач Представление = Неопределено) Экспорт
	
	Если ЗначениеЗаполнено(ИмяПоля) Тогда
		ЗначениеПоиска = Новый ПолеКомпоновкиДанных(ИмяПоля);
		СпособПоиска = 1;
	Иначе
		СпособПоиска = 2;
		ЗначениеПоиска = Представление;
	КонецЕсли;
	
	МассивЭлементов = Новый Массив;
	
	НайтиРекурсивно(ОбластьПоиска.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
	
	Возврат МассивЭлементов;
	
КонецФункции

// Добавить группу отбора в коллекцию КоллекцияЭлементов.
//
// Параметры:
//  КоллекцияЭлементов - ОтборКомпоновкиДанных
//                     - КоллекцияЭлементовОтбораКомпоновкиДанных
//                     - ГруппаЭлементовОтбораКомпоновкиДанных    - контейнер с элементами и группами отбора,
//                                                                  например Список.Отбор или группа в отборе.
//  Представление      - Строка - представление группы.
//  ТипГруппы          - ТипГруппыЭлементовОтбораКомпоновкиДанных - тип группы.
//
// Возвращаемое значение:
//  ГруппаЭлементовОтбораКомпоновкиДанных - группа отбора.
//
Функция СоздатьГруппуЭлементовОтбора(Знач КоллекцияЭлементов, Представление, ТипГруппы) Экспорт
	
	Если ТипЗнч(КоллекцияЭлементов) = Тип("ГруппаЭлементовОтбораКомпоновкиДанных")
		Или ТипЗнч(КоллекцияЭлементов) = Тип("ОтборКомпоновкиДанных") Тогда
		
		КоллекцияЭлементов = КоллекцияЭлементов.Элементы;
	КонецЕсли;
	
	ГруппаЭлементовОтбора = НайтиЭлементОтбораПоПредставлению(КоллекцияЭлементов, Представление);
	Если ГруппаЭлементовОтбора = Неопределено Тогда
		ГруппаЭлементовОтбора = КоллекцияЭлементов.Добавить(Тип("ГруппаЭлементовОтбораКомпоновкиДанных"));
	Иначе
		ГруппаЭлементовОтбора.Элементы.Очистить();
	КонецЕсли;
	
	ГруппаЭлементовОтбора.Представление    = Представление;
	ГруппаЭлементовОтбора.Применение       = ТипПримененияОтбораКомпоновкиДанных.Элементы;
	ГруппаЭлементовОтбора.РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
	ГруппаЭлементовОтбора.ТипГруппы        = ТипГруппы;
	ГруппаЭлементовОтбора.Использование    = Истина;
	
	Возврат ГруппаЭлементовОтбора;
	
КонецФункции

// Добавить элемент компоновки в контейнер элементов компоновки.
//
// Параметры:
//  ОбластьДобавления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                                 например, Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  ПравоеЗначение          - Произвольный - сравниваемое значение.
//  Представление           - Строка - представление элемента компоновки данных.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
// Возвращаемое значение:
//  ЭлементОтбораКомпоновкиДанных - элемент компоновки.
//
Функция ДобавитьЭлементКомпоновки(ОбластьДобавления,
									Знач ИмяПоля,
									Знач ВидСравнения,
									Знач ПравоеЗначение = Неопределено,
									Знач Представление  = Неопределено,
									Знач Использование  = Неопределено,
									знач РежимОтображения = Неопределено,
									знач ИдентификаторПользовательскойНастройки = Неопределено) Экспорт
	
	Элемент = ОбластьДобавления.Элементы.Добавить(Тип("ЭлементОтбораКомпоновкиДанных"));
	Элемент.ЛевоеЗначение = Новый ПолеКомпоновкиДанных(ИмяПоля);
	Элемент.ВидСравнения = ВидСравнения;
	
	Если РежимОтображения = Неопределено Тогда
		Элемент.РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
	Иначе
		Элемент.РежимОтображения = РежимОтображения;
	КонецЕсли;
	
	Если ПравоеЗначение <> Неопределено Тогда
		Элемент.ПравоеЗначение = ПравоеЗначение;
	КонецЕсли;
	
	Если Представление <> Неопределено Тогда
		Элемент.Представление = Представление;
	КонецЕсли;
	
	Если Использование <> Неопределено Тогда
		Элемент.Использование = Использование;
	КонецЕсли;
	
	// Важно: установка идентификатора должна выполняться
	// в конце настройки элемента, иначе он будет скопирован
	// в пользовательские настройки частично заполненным.
	Если ИдентификаторПользовательскойНастройки <> Неопределено Тогда
		Элемент.ИдентификаторПользовательскойНастройки = ИдентификаторПользовательскойНастройки;
	ИначеЕсли Элемент.РежимОтображения <> РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный Тогда
		Элемент.ИдентификаторПользовательскойНастройки = ИмяПоля;
	КонецЕсли;
	
	Возврат Элемент;
	
КонецФункции

// Изменить элемент отбора с заданным именем поля или представлением.
//
// Параметры:
//  ОбластьПоиска - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                             например Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  Представление           - Строка - представление элемента компоновки данных.
//  ПравоеЗначение          - Произвольный - сравниваемое значение.
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
//
// Возвращаемое значение:
//  Число - количество измененных элементов.
//
Функция ИзменитьЭлементыОтбора(ОбластьПоиска,
								Знач ИмяПоля = Неопределено,
								Знач Представление = Неопределено,
								Знач ПравоеЗначение = Неопределено,
								Знач ВидСравнения = Неопределено,
								Знач Использование = Неопределено,
								Знач РежимОтображения = Неопределено,
								Знач ИдентификаторПользовательскойНастройки = Неопределено) Экспорт
	
	Если ЗначениеЗаполнено(ИмяПоля) Тогда
		ЗначениеПоиска = Новый ПолеКомпоновкиДанных(ИмяПоля);
		СпособПоиска = 1;
	Иначе
		СпособПоиска = 2;
		ЗначениеПоиска = Представление;
	КонецЕсли;
	
	МассивЭлементов = Новый Массив;
	
	НайтиРекурсивно(ОбластьПоиска.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
	
	Для Каждого Элемент Из МассивЭлементов Цикл
		Если ИмяПоля <> Неопределено Тогда
			Элемент.ЛевоеЗначение = Новый ПолеКомпоновкиДанных(ИмяПоля);
		КонецЕсли;
		Если Представление <> Неопределено Тогда
			Элемент.Представление = Представление;
		КонецЕсли;
		Если Использование <> Неопределено Тогда
			Элемент.Использование = Использование;
		КонецЕсли;
		Если ВидСравнения <> Неопределено Тогда
			Элемент.ВидСравнения = ВидСравнения;
		КонецЕсли;
		Если ПравоеЗначение <> Неопределено Тогда
			Элемент.ПравоеЗначение = ПравоеЗначение;
		КонецЕсли;
		Если РежимОтображения <> Неопределено Тогда
			Элемент.РежимОтображения = РежимОтображения;
		КонецЕсли;
		Если ИдентификаторПользовательскойНастройки <> Неопределено Тогда
			Элемент.ИдентификаторПользовательскойНастройки = ИдентификаторПользовательскойНастройки;
		КонецЕсли;
	КонецЦикла;
	
	Возврат МассивЭлементов.Количество();
	
КонецФункции

// Удалить элементы отбора с заданным именем поля или представлением.
//
// Параметры:
//  ОбластьУдаления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                               например, Список.Отбор или группа в отборе..
//  ИмяПоля         - Строка - имя поля компоновки (не используется для групп).
//  Представление   - Строка - представление поля компоновки.
//
Процедура УдалитьЭлементыГруппыОтбора(Знач ОбластьУдаления, Знач ИмяПоля = Неопределено, Знач Представление = Неопределено) Экспорт
	
	Если ЗначениеЗаполнено(ИмяПоля) Тогда
		ЗначениеПоиска = Новый ПолеКомпоновкиДанных(ИмяПоля);
		СпособПоиска = 1;
	Иначе
		СпособПоиска = 2;
		ЗначениеПоиска = Представление;
	КонецЕсли;
	
	МассивЭлементов = Новый Массив; // Массив из ЭлементОтбораКомпоновкиДанных, ГруппаЭлементовОтбораКомпоновкиДанных
	
	НайтиРекурсивно(ОбластьУдаления.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
	
	Для Каждого Элемент Из МассивЭлементов Цикл
		Если Элемент.Родитель = Неопределено Тогда
			ОбластьУдаления.Элементы.Удалить(Элемент);
		Иначе
			Элемент.Родитель.Элементы.Удалить(Элемент);
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры

// Добавить или заменить существующий элемент отбора.
//
// Параметры:
//  ОбластьПоискаДобавления - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                     например, Список.Отбор или группа в отборе.
//  ИмяПоля                 - Строка - имя поля компоновки данных (заполняется всегда).
//  ПравоеЗначение          - произвольный - сравниваемое значение.
//  ВидСравнения            - ВидСравненияКомпоновкиДанных - вид сравнения.
//  Представление           - Строка - представление элемента компоновки данных.
//  Использование           - Булево - использование элемента.
//  РежимОтображения        - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - режим отображения.
//  ИдентификаторПользовательскойНастройки - Строка - см. ОтборКомпоновкиДанных.ИдентификаторПользовательскойНастройки
//                                                    в синтакс-помощнике.
//
Процедура УстановитьЭлементОтбора(ОбластьПоискаДобавления,
								Знач ИмяПоля,
								Знач ПравоеЗначение = Неопределено,
								Знач ВидСравнения = Неопределено,
								Знач Представление = Неопределено,
								Знач Использование = Неопределено,
								Знач РежимОтображения = Неопределено,
								Знач ИдентификаторПользовательскойНастройки = Неопределено) Экспорт
	
	ЧислоИзмененных = ИзменитьЭлементыОтбора(ОбластьПоискаДобавления, ИмяПоля, Представление,
							ПравоеЗначение, ВидСравнения, Использование, РежимОтображения, ИдентификаторПользовательскойНастройки);
	
	Если ЧислоИзмененных = 0 Тогда
		Если ВидСравнения = Неопределено Тогда
			Если ТипЗнч(ПравоеЗначение) = Тип("Массив")
				Или ТипЗнч(ПравоеЗначение) = Тип("ФиксированныйМассив")
				Или ТипЗнч(ПравоеЗначение) = Тип("СписокЗначений") Тогда
				ВидСравнения = ВидСравненияКомпоновкиДанных.ВСписке;
			Иначе
				ВидСравнения = ВидСравненияКомпоновкиДанных.Равно;
			КонецЕсли;
		КонецЕсли;
		Если РежимОтображения = Неопределено Тогда
			РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
		КонецЕсли;
		ДобавитьЭлементКомпоновки(ОбластьПоискаДобавления, ИмяПоля, ВидСравнения,
								ПравоеЗначение, Представление, Использование, РежимОтображения, ИдентификаторПользовательскойНастройки);
	КонецЕсли;
	
КонецПроцедуры

// Добавить или заменить существующий элемент отбора динамического списка.
//
// Параметры:
//   ДинамическийСписок - ДинамическийСписок - список, в котором требуется установить отбор.
//   ИмяПоля            - Строка - поле, по которому необходимо установить отбор.
//   ПравоеЗначение     - Произвольный - значение отбора.
//       Необязательный. Значение по умолчанию Неопределено.
//       Внимание! Если передать Неопределено, то значение не будет изменено.
//   ВидСравнения  - ВидСравненияКомпоновкиДанных - условие отбора.
//   Представление - Строка - представление элемента компоновки данных.
//       Необязательный. Значение по умолчанию Неопределено.
//       Если указано, то выводится только флажок использования с указанным представлением (значение не выводится).
//       Для очистки (чтобы значение снова выводилось) следует передать пустую строку.
//   Использование - Булево - флажок использования этого отбора.
//       Необязательный. Значение по умолчанию: Неопределено.
//   РежимОтображения - РежимОтображенияЭлементаНастройкиКомпоновкиДанных - способ отображения этого отбора
//                                                                          пользователю:
//       * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.БыстрыйДоступ - в группе быстрых настроек над списком.
//       * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Обычный       - в настройка списка (в подменю Еще).
//       * РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный   - запретить пользователю менять этот отбор.
//   ИдентификаторПользовательскойНастройки - Строка - уникальный идентификатор этого отбора.
//       Используется для связи с пользовательскими настройками.
//
Процедура УстановитьЭлементОтбораДинамическогоСписка(ДинамическийСписок, ИмяПоля,
	ПравоеЗначение = Неопределено,
	ВидСравнения = Неопределено,
	Представление = Неопределено,
	Использование = Неопределено,
	РежимОтображения = Неопределено,
	ИдентификаторПользовательскойНастройки = Неопределено) Экспорт
	
	Если РежимОтображения = Неопределено Тогда
		РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный;
	КонецЕсли;
	
	Если РежимОтображения = РежимОтображенияЭлементаНастройкиКомпоновкиДанных.Недоступный Тогда
		ОтборДинамическогоСписка = ДинамическийСписок.КомпоновщикНастроек.ФиксированныеНастройки.Отбор;
	Иначе
		ОтборДинамическогоСписка = ДинамическийСписок.КомпоновщикНастроек.Настройки.Отбор;
	КонецЕсли;
	
	УстановитьЭлементОтбора(
		ОтборДинамическогоСписка,
		ИмяПоля,
		ПравоеЗначение,
		ВидСравнения,
		Представление,
		Использование,
		РежимОтображения,
		ИдентификаторПользовательскойНастройки);
	
КонецПроцедуры

// Удалить элемент группы отбора динамического списка.
//
// Параметры:
//  ДинамическийСписок - ДинамическийСписок - реквизит формы, для которого требуется установить отбор.
//  ИмяПоля         - Строка - имя поля компоновки (не используется для групп).
//  Представление   - Строка - представление поля компоновки.
//
Процедура УдалитьЭлементыГруппыОтбораДинамическогоСписка(ДинамическийСписок, ИмяПоля = Неопределено, Представление = Неопределено) Экспорт
	
	УдалитьЭлементыГруппыОтбора(
		ДинамическийСписок.КомпоновщикНастроек.ФиксированныеНастройки.Отбор,
		ИмяПоля,
		Представление);
	
	УдалитьЭлементыГруппыОтбора(
		ДинамическийСписок.КомпоновщикНастроек.Настройки.Отбор,
		ИмяПоля,
		Представление);
	
КонецПроцедуры

// Установить или обновить значение параметра ИмяПараметра динамического списка Список.
//
// Параметры:
//  Список          - ДинамическийСписок - реквизит формы, для которого требуется установить параметр.
//  ИмяПараметра    - Строка             - имя параметра динамического списка.
//  Значение        - Произвольный        - новое значение параметра.
//  Использование   - Булево             - признак использования параметра.
//
Процедура УстановитьПараметрДинамическогоСписка(Список, ИмяПараметра, Значение, Использование = Истина) Экспорт
	
	ЗначениеПараметраКомпоновкиДанных = Список.Параметры.НайтиЗначениеПараметра(Новый ПараметрКомпоновкиДанных(ИмяПараметра));
	Если ЗначениеПараметраКомпоновкиДанных <> Неопределено Тогда
		Если Использование И ЗначениеПараметраКомпоновкиДанных.Значение <> Значение Тогда
			ЗначениеПараметраКомпоновкиДанных.Значение = Значение;
		КонецЕсли;
		Если ЗначениеПараметраКомпоновкиДанных.Использование <> Использование Тогда
			ЗначениеПараметраКомпоновкиДанных.Использование = Использование;
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ДинамическийСписок

Процедура НайтиРекурсивно(КоллекцияЭлементов, МассивЭлементов, СпособПоиска, ЗначениеПоиска)
	
	Для каждого ЭлементОтбора Из КоллекцияЭлементов Цикл
		
		Если ТипЗнч(ЭлементОтбора) = Тип("ЭлементОтбораКомпоновкиДанных") Тогда
			
			Если СпособПоиска = 1 Тогда
				Если ЭлементОтбора.ЛевоеЗначение = ЗначениеПоиска Тогда
					МассивЭлементов.Добавить(ЭлементОтбора);
				КонецЕсли;
			ИначеЕсли СпособПоиска = 2 Тогда
				Если ЭлементОтбора.Представление = ЗначениеПоиска Тогда
					МассивЭлементов.Добавить(ЭлементОтбора);
				КонецЕсли;
			КонецЕсли;
		Иначе
			
			НайтиРекурсивно(ЭлементОтбора.Элементы, МассивЭлементов, СпособПоиска, ЗначениеПоиска);
			
			Если СпособПоиска = 2 И ЭлементОтбора.Представление = ЗначениеПоиска Тогда
				МассивЭлементов.Добавить(ЭлементОтбора);
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЦикла;
	
КонецПроцедуры

#КонецОбласти

// Выполняет поиск элемента отбора в коллекции по заданному представлению.
//
// Параметры:
//  КоллекцияЭлементов - КоллекцияЭлементовОтбораКомпоновкиДанных - контейнер с элементами и группами отбора,
//                                                                  например, Список.Отбор.Элементы или группа в отборе.
//  Представление - Строка - представление группы.
// 
// Возвращаемое значение:
//  ЭлементОтбораКомпоновкиДанных - элемент отбора.
//
Функция НайтиЭлементОтбораПоПредставлению(КоллекцияЭлементов, Представление) Экспорт
	
	ВозвращаемоеЗначение = Неопределено;
	
	Для каждого ЭлементОтбора Из КоллекцияЭлементов Цикл
		Если ЭлементОтбора.Представление = Представление Тогда
			ВозвращаемоеЗначение = ЭлементОтбора;
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Возврат ВозвращаемоеЗначение
	
КонецФункции

// Вызывает исключение, если тип значения параметра ИмяПараметра процедуры или функции ИмяПроцедурыИлиФункции
// отличается от ожидаемого.
// Для быстрой диагностики типов параметров, передаваемых в процедуры и функции программного интерфейса.
//
// В связи с особенностью реализации ОписанияТипов всегда включает в себя тип <Неопределено>.
// если требуется жесткая проверка типа, используйте в параметре ОжидаемыеТипы 
// конкретный тип, массив или соответствие типов.
//
// Параметры:
//   ИмяПроцедурыИлиФункции - Строка - имя процедуры или функции, параметр которой проверяется.
//   ИмяПараметра - Строка - имя проверяемого параметра процедуры или функции.
//   ЗначениеПараметра - Произвольный - фактическое значение параметра.
//   ОжидаемыеТипы - ОписаниеТипов
//                 - Тип
//                 - Массив
//                 - ФиксированныйМассив
//                 - Соответствие
//                 - ФиксированноеСоответствие - тип(ы)
//       параметра процедуры или функции.
//   ОжидаемыеТипыСвойств - Структура - если ожидаемый тип - структура, то 
//       в этом параметре можно указать типы ее свойств.
//
Процедура ПроверитьПараметр(Знач ИмяПроцедурыИлиФункции, Знач ИмяПараметра, Знач ЗначениеПараметра, 
	Знач ОжидаемыеТипы, Знач ОжидаемыеТипыСвойств = Неопределено) Экспорт
	
	Контекст = "ОбщегоНазначенияКлиентСервер.ПроверитьПараметр";
	Проверить(ТипЗнч(ИмяПроцедурыИлиФункции) = Тип("Строка"), 
		НСтр("ru = 'Недопустимое значение параметра ИмяПроцедурыИлиФункции'"), Контекст);
	Проверить(ТипЗнч(ИмяПараметра) = Тип("Строка"), 
		НСтр("ru = 'Недопустимое значение параметра ИмяПараметра'"), Контекст);
	
	ЭтоКорректныйТип = ЗначениеОжидаемогоТипа(ЗначениеПараметра, ОжидаемыеТипы);
	Проверить(ЭтоКорректныйТип <> Неопределено, 
		НСтр("ru = 'Недопустимое значение параметра ОжидаемыеТипы'"), Контекст);
	Проверить(ЭтоКорректныйТип,
		СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Недопустимое значение параметра %1 в %2. 
			           |Ожидалось: %3; передано значение: %4 (тип %5).'"),
			ИмяПараметра, ИмяПроцедурыИлиФункции, ПредставлениеТипов(ОжидаемыеТипы), 
			?(ЗначениеПараметра <> Неопределено, ЗначениеПараметра, НСтр("ru = 'Неопределено'")),
		ТипЗнч(ЗначениеПараметра)));
	
	Если ТипЗнч(ЗначениеПараметра) = Тип("Структура") И ОжидаемыеТипыСвойств <> Неопределено Тогда
		
		Проверить(ТипЗнч(ОжидаемыеТипыСвойств) = Тип("Структура"), 
			НСтр("ru = 'Недопустимое значение параметра ИмяПроцедурыИлиФункции'"), 
			Контекст);
		
		Для каждого Свойство Из ОжидаемыеТипыСвойств Цикл
			
			ОжидаемоеИмяСвойства = Свойство.Ключ;
			ОжидаемыйТипСвойства = Свойство.Значение;
			ЗначениеСвойства = Неопределено;
			
			Проверить(ЗначениеПараметра.Свойство(ОжидаемоеИмяСвойства, ЗначениеСвойства), 
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = 'Недопустимое значение параметра %1 (Структура) в %2. 
					           |В структуре ожидалось свойство %3 (тип %4).'"), 
					ИмяПараметра, ИмяПроцедурыИлиФункции, ОжидаемоеИмяСвойства, ОжидаемыйТипСвойства));
			
			ЭтоКорректныйТип = ЗначениеОжидаемогоТипа(ЗначениеСвойства, ОжидаемыйТипСвойства);
			Проверить(ЭтоКорректныйТип, 
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = 'Недопустимое значение свойства %1 в параметре %2 (Структура) в %3. 
					           |Ожидалось: %4; передано значение: %5 (тип %6).'"), 
					ОжидаемоеИмяСвойства, ИмяПараметра,	ИмяПроцедурыИлиФункции,
					ПредставлениеТипов(ОжидаемыеТипы), 
					?(ЗначениеСвойства <> Неопределено, ЗначениеСвойства, НСтр("ru = 'Неопределено'")),
				ТипЗнч(ЗначениеСвойства)));
			
		КонецЦикла;
	КонецЕсли;
	
КонецПроцедуры

// Вызывает исключение с текстом Сообщение, если Условие не равно Истина.
// Применяется для самодиагностики кода.
//
// Параметры:
//   Условие - Булево - если не равно Истина, то вызывается исключение.
//   Сообщение - Строка - текст сообщения. Если не задан, то исключение вызывается с сообщением по умолчанию.
//   КонтекстПроверки - Строка - например, имя процедуры или функции, в которой выполняется проверка.
//
Процедура Проверить(Знач Условие, Знач Сообщение = "", Знач КонтекстПроверки = "") Экспорт
	
	Если Условие <> Истина Тогда
		
		Если ПустаяСтрока(Сообщение) Тогда
			ТекстИсключения = НСтр("ru = 'Недопустимая операция'"); // Assertion failed
		Иначе
			ТекстИсключения = Сообщение;
		КонецЕсли;
		
		Если Не ПустаяСтрока(КонтекстПроверки) Тогда
			ТекстИсключения = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
				НСтр("ru = '%1 в %2'"), ТекстИсключения, КонтекстПроверки);
		КонецЕсли;
		
		ВызватьИсключение ТекстИсключения;
		
	КонецЕсли;
	
КонецПроцедуры

Функция ЗначениеОжидаемогоТипа(Значение, ОжидаемыеТипы)
	
	ТипЗначения = ТипЗнч(Значение);
	
	Если ТипЗнч(ОжидаемыеТипы) = Тип("ОписаниеТипов") Тогда
		
		Возврат ОжидаемыеТипы.СодержитТип(ТипЗначения);
		
	ИначеЕсли ТипЗнч(ОжидаемыеТипы) = Тип("Тип") Тогда
		
		Возврат ТипЗначения = ОжидаемыеТипы;
		
	ИначеЕсли ТипЗнч(ОжидаемыеТипы) = Тип("Массив") 
		Или ТипЗнч(ОжидаемыеТипы) = Тип("ФиксированныйМассив") Тогда
		
		Возврат ОжидаемыеТипы.Найти(ТипЗначения) <> Неопределено;
		
	ИначеЕсли ТипЗнч(ОжидаемыеТипы) = Тип("Соответствие") 
		Или ТипЗнч(ОжидаемыеТипы) = Тип("ФиксированноеСоответствие") Тогда
		
		Возврат ОжидаемыеТипы.Получить(ТипЗначения) <> Неопределено;
		
	КонецЕсли;
	
	Возврат Неопределено;
	
КонецФункции

Функция ПредставлениеТипов(ОжидаемыеТипы)
	
	Если ТипЗнч(ОжидаемыеТипы) = Тип("Массив")
		Или ТипЗнч(ОжидаемыеТипы) = Тип("ФиксированныйМассив")
		Или ТипЗнч(ОжидаемыеТипы) = Тип("Соответствие")
		Или ТипЗнч(ОжидаемыеТипы) = Тип("ФиксированноеСоответствие") Тогда
		
		Результат = "";
		Индекс = 0;
		Для Каждого Элемент Из ОжидаемыеТипы Цикл
			
			Если ТипЗнч(ОжидаемыеТипы) = Тип("Соответствие")
				Или ТипЗнч(ОжидаемыеТипы) = Тип("ФиксированноеСоответствие") Тогда 
				
				Тип = Элемент.Ключ;
			Иначе 
				Тип = Элемент;
			КонецЕсли;
			
			Если Не ПустаяСтрока(Результат) Тогда
				Результат = Результат + ", ";
			КонецЕсли;
			
			Результат = Результат + ПредставлениеТипа(Тип);
			Индекс = Индекс + 1;
			Если Индекс > 10 Тогда
				Результат = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = '%1,... (всего %2 типов)'"), 
					Результат, 
					ОжидаемыеТипы.Количество());
				Прервать;
			КонецЕсли;
		КонецЦикла;
		
		Возврат Результат;
		
	Иначе 
		Возврат ПредставлениеТипа(ОжидаемыеТипы);
	КонецЕсли;
	
КонецФункции

Функция ПредставлениеТипа(Тип)
	
	Если Тип = Неопределено Тогда
		
		Возврат "Неопределено";
		
	ИначеЕсли ТипЗнч(Тип) = Тип("ОписаниеТипов") Тогда
		
		ТипСтрокой = Строка(Тип);
		Возврат 
			?(СтрДлина(ТипСтрокой) > 150, 
				СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(
					НСтр("ru = '%1,... (всего %2 типов)'"),
					Лев(ТипСтрокой, 150),
					Тип.Типы().Количество()), 
				ТипСтрокой);
		
	Иначе
		
		ТипСтрокой = Строка(Тип);
		Возврат 
			?(СтрДлина(ТипСтрокой) > 150, 
				Лев(ТипСтрокой, 150) + "...", 
				ТипСтрокой);
		
	КонецЕсли;
	
КонецФункции

// Получает картинку для вывода на странице с комментарием в зависимости
// от наличия текста в комментарии.
//
// Параметры:
//  Комментарий  - Строка - текст комментария.
//
// Возвращаемое значение:
//  Картинка - картинка, которая должна отображаться на странице с комментарием.
//
Функция КартинкаКомментария(Комментарий) Экспорт

//	Если НЕ ПустаяСтрока(Комментарий) Тогда
//		Картинка = БиблиотекаКартинок.Комментарий;
//	Иначе
		Картинка = Новый Картинка;
//	КонецЕсли;
	
	Возврат Картинка;
	
КонецФункции



// Возвращает значение свойства структуры.
//
// Параметры:
//   Структура - Структура
//             - ФиксированнаяСтруктура - объект, из которого необходимо прочитать значение ключа.
//   Ключ - Строка - имя свойства структуры, для которого необходимо прочитать значение.
//   ЗначениеПоУмолчанию - Произвольный - необязательный. Возвращается когда в структуре нет значения по указанному
//                                        ключу.
//       Для скорости рекомендуется передавать только быстро вычисляемые значения (например примитивные типы),
//       а инициализацию более тяжелых значений выполнять после проверки полученного значения (только если это
//       требуется).
//
// Возвращаемое значение:
//   Произвольный - значение свойства структуры. ЗначениеПоУмолчанию если в структуре нет указанного свойства.
//
Функция СвойствоСтруктуры(Структура, Ключ, ЗначениеПоУмолчанию = Неопределено) Экспорт
	
	Если Структура = Неопределено Тогда
		Возврат ЗначениеПоУмолчанию;
	КонецЕсли;
	
	Результат = ЗначениеПоУмолчанию;
	Если Структура.Свойство(Ключ, Результат) Тогда
		Возврат Результат;
	Иначе
		Возврат ЗначениеПоУмолчанию;
	КонецЕсли;
	
КонецФункции

