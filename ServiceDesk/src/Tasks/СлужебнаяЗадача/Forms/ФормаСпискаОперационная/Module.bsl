&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)

	ТекущийПользователь		= ПараметрыСеанса.ТекущийПользователь;
	ОтображатьДеталиЗаявки	= Истина;

	Элементы.СписокТекущие.АвтоОбновление				= Ложь;
	Элементы.СписокЗарегистрированные.АвтоОбновление	= Ложь;
	Элементы.СписокМоиЗаявки.АвтоОбновление				= Ложь;
	Элементы.СписокНаблюдатель.АвтоОбновление			= Ложь;

	Если РольДоступна("Консультант") Тогда
		Элементы.СписокТекущие.АвтоОбновление	= Истина;
		СписокТекущие.ТекстЗапроса = "ВЫБРАТЬ
									 |	СлужебнаяЗадачаЗадачиПоИсполнителю.ЗаявкаПользователя КАК ЗаявкаПользователя,
									 |	СлужебнаяЗадачаЗадачиПоИсполнителю.СрокИсполнения КАК СрокИсполнения,
									 |	СтатусыЗаявокОстатки.СостояниеЗаявки КАК СостояниеЗаявки,
									 |	ВЫБОР
									 |		КОГДА СлужебнаяЗадачаЗадачиПоИсполнителю.СрокИсполнения < &ДатаОтсечения1
									 |			ТОГДА ИСТИНА
									 |		ИНАЧЕ ЛОЖЬ
									 |	КОНЕЦ КАК Просрочена
									 |ПОМЕСТИТЬ ВТ
									 |ИЗ
									 |	Задача.СлужебнаяЗадача.ЗадачиПоИсполнителю КАК СлужебнаяЗадачаЗадачиПоИсполнителю
									 |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.СтатусыЗаявок.Остатки КАК СтатусыЗаявокОстатки
									 |		ПО СлужебнаяЗадачаЗадачиПоИсполнителю.ЗаявкаПользователя = СтатусыЗаявокОстатки.Заявка
									 |ГДЕ
									 |	НЕ СлужебнаяЗадачаЗадачиПоИсполнителю.Выполнена
									 |	И НЕ СлужебнаяЗадачаЗадачиПоИсполнителю.ПометкаУдаления
									 |	И СтатусыЗаявокОстатки.СостояниеЗаявки <> ЗНАЧЕНИЕ(Справочник.СостоянияЗаявки.Зарегистрирована)
									 |
									 |ОБЪЕДИНИТЬ ВСЕ
									 |
									 |ВЫБРАТЬ
									 |	СлужебнаяЗадача.ЗаявкаПользователя,
									 |	СлужебнаяЗадача.СрокИсполнения,
									 |	СтатусыЗаявокОстатки.СостояниеЗаявки,
									 |	ВЫБОР
									 |		КОГДА СлужебнаяЗадача.СрокИсполнения < &ДатаОтсечения1
									 |			ТОГДА ИСТИНА
									 |		ИНАЧЕ ЛОЖЬ
									 |	КОНЕЦ
									 |ИЗ
									 |	Задача.СлужебнаяЗадача КАК СлужебнаяЗадача
									 |		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.СтатусыЗаявок.Остатки КАК СтатусыЗаявокОстатки
									 |		ПО СлужебнаяЗадача.ЗаявкаПользователя = СтатусыЗаявокОстатки.Заявка
									 |ГДЕ
									 |	НЕ СлужебнаяЗадача.Выполнена
									 |	И НЕ СлужебнаяЗадача.ПометкаУдаления
									 |	И (СтатусыЗаявокОстатки.СостояниеЗаявки = ЗНАЧЕНИЕ(Справочник.СостоянияЗаявки.Зарегистрирована)
									 |			ИЛИ СтатусыЗаявокОстатки.СостояниеЗаявки = ЗНАЧЕНИЕ(Справочник.СостоянияЗаявки.ОжиданиеОтвета)
									 |				И СтатусыЗаявокОстатки.СостояниеЗаявкиСтарое = ЗНАЧЕНИЕ(Справочник.СостоянияЗаявки.Зарегистрирована))
									 |;
									 |
									 |////////////////////////////////////////////////////////////////////////////////
									 |ВЫБРАТЬ РАЗЛИЧНЫЕ
									 |	пЗаявка.Ссылка КАК Заявка,
									 |	пЗаявка.Важность КАК Важность,
									 |	ВТ.СрокИсполнения КАК СрокИсполнения,
									 |	ВТ.СостояниеЗаявки КАК СостояниеЗаявки,
									 |	пЗаявка.База1С КАК База1С,
									 |	пЗаявка.ВидДеятельности КАК ВидДеятельности,
									 |	ВТ.Просрочена КАК Просрочена,
									 |	пЗаявка.Заказчик КАК Заказчик,
									 |	пЗаявка.Релиз КАК Релиз,
									 |	пЗаявка.Исполнитель КАК Исполнитель,
									 |	пЗаявка.Тестировщик КАК Тестировщик
									 |ИЗ
									 |	ВТ КАК ВТ
									 |		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Документ.ЗаявкаПользователя КАК пЗаявка
									 |		ПО ВТ.ЗаявкаПользователя = пЗаявка.Ссылка";
	ИначеЕсли РольДоступна("Пользователь") Тогда
		Элементы.СписокМоиЗаявки.АвтоОбновление	= Истина;
		Элементы.Страницы.ТекущаяСтраница		= Элементы.ГруппаМоиЗаявки;
		Элементы.Страницы.ОтображениеСтраниц	= ОтображениеСтраницФормы.Нет;
		Элементы.ГруппаМоиЗаявки.Видимость = Истина;
	Иначе
		Элементы.СписокТекущие.АвтоОбновление	= Истина;
		Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаТекущие;
	КонецЕсли;

	ДатаОтсечения	= НачалоДня(ТекущаяДатаСеанса());
	СписокТекущие.Параметры.УстановитьЗначениеПараметра("ДатаОтсечения1", ДатаОтсечения);

	СписокНаблюдатель.Параметры.УстановитьЗначениеПараметра("Наблюдатель", ТекущийПользователь);

	СписокМоиЗаявки.КомпоновщикНастроек.ПользовательскиеНастройки.Элементы[0].ПравоеЗначение	= ТекущийПользователь;
КонецПроцедуры

&НаКлиенте
Процедура СтраницыПриСменеСтраницы(Элемент, ТекущаяСтраница)

	Если Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаТекущие Тогда
		Если ДатаОтсечения <> НачалоДня(ТекущаяДата()) Тогда
			ДатаОтсечения	= НачалоДня(ТекущаяДата());
			СписокТекущие.Параметры.УстановитьЗначениеПараметра("ДатаОтсечения1", ДатаОтсечения);
		КонецЕсли;
		Элементы.СписокТекущие.АвтоОбновление				= Истина;
		Элементы.СписокЗарегистрированные.АвтоОбновление	= Ложь;
		Элементы.СписокМоиЗаявки.АвтоОбновление				= Ложь;
		Элементы.СписокНаблюдатель.АвтоОбновление			= Ложь;
		Элементы.СписокТекущие.Обновить();
		СписокТекущиеПриАктивизацииСтроки(Элемент);
	ИначеЕсли Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаЗарегистрированные Тогда
		Элементы.СписокТекущие.АвтоОбновление				= Ложь;
		Элементы.СписокЗарегистрированные.АвтоОбновление	= Истина;
		Элементы.СписокМоиЗаявки.АвтоОбновление				= Ложь;
		Элементы.СписокНаблюдатель.АвтоОбновление			= Ложь;
		Элементы.СписокЗарегистрированные.Обновить();
	ИначеЕсли Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаМоиЗаявки Тогда
		Элементы.СписокТекущие.АвтоОбновление				= Ложь;
		Элементы.СписокЗарегистрированные.АвтоОбновление	= Ложь;
		Элементы.СписокМоиЗаявки.АвтоОбновление				= Истина;
		Элементы.СписокНаблюдатель.АвтоОбновление			= Ложь;
		Элементы.СписокМоиЗаявки.Обновить();
		СписокМоиЗаявкиПриАктивизацииСтроки(Элемент);
	ИначеЕсли Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаНаблюдатель Тогда
		Элементы.СписокТекущие.АвтоОбновление				= Ложь;
		Элементы.СписокЗарегистрированные.АвтоОбновление	= Ложь;
		Элементы.СписокМоиЗаявки.АвтоОбновление				= Ложь;
		Элементы.СписокНаблюдатель.АвтоОбновление			= Истина;
		Элементы.СписокНаблюдатель.Обновить();
	КонецЕсли;

КонецПроцедуры

&НаКлиенте
Процедура ПолучитьHTMLИзЗаявки(Заявка)
	СтруктураОтвета	= ЗаявкаПользователяВызовСервера.ПолучитьHTMLИзЗаявки(Заявка);
	ОписаниеHTML						= СтруктураОтвета.ОписаниеHTML;
	КоличествоКомментариев				= "" + СтруктураОтвета.КоличествоКомментариев;
	ОписаниеРазработчикаHTML			= СтруктураОтвета.ОписаниеРазработчикаHTML;
	КоличествоКомментариевРазработчика	= "" + СтруктураОтвета.КоличествоКомментариевРазработчика;
КонецПроцедуры

&НаКлиенте
Процедура СписокТекущиеПриАктивизацииСтроки(Элемент)
	ТекущиеДанные	= Элементы.СписокТекущие.ТекущиеДанные;
	Если ОтображатьДеталиЗаявки И ТекущиеДанные <> Неопределено И ТекущиеДанные.Свойство("Заявка") Тогда
		ПолучитьHTMLИзЗаявки(ТекущиеДанные.Заявка);
	Иначе
		ОписаниеHTML				= "";
		ОписаниеРазработчикаHTML	= "";
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура СписокМоиЗаявкиПриАктивизацииСтроки(Элемент)
	ТекущиеДанные	= Элементы.СписокМоиЗаявки.ТекущиеДанные;
	Если ОтображатьДеталиЗаявки И ТекущиеДанные <> Неопределено И ТекущиеДанные.Свойство("Заявка") Тогда
		ПолучитьHTMLИзЗаявки(ТекущиеДанные.Заявка);
	Иначе
		ОписаниеHTML	= "";
		ОписаниеРазработчикаHTML	= "";
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаОповещения(ИмяСобытия, Параметр, Источник)
	Если ИмяСобытия = "ОбновитьОписаниеHTML" Тогда
		Если Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаТекущие Тогда
			Элементы.СписокТекущие.Обновить();
		ИначеЕсли Элементы.Страницы.ТекущаяСтраница = Элементы.ГруппаМоиЗаявки Тогда
			Элементы.СписокМоиЗаявки.Обновить();
		КонецЕсли;
		ТекущиеДанные	= Элементы.СписокТекущие.ТекущиеДанные;
		Если ОтображатьДеталиЗаявки И ТекущиеДанные <> Неопределено И ТекущиеДанные.Свойство("Заявка") И Параметр
			= ТекущиеДанные.Заявка Тогда
			ПолучитьHTMLИзЗаявки(ТекущиеДанные.Заявка);
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеОписаниеДобавить(Результат, ДополнительныеПараметры) Экспорт
	Если Результат = "ОК" Тогда
		ПолучитьHTMLИзЗаявки(ДополнительныеПараметры);
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ОписаниеHTMLПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
КонецПроцедуры

&НаКлиенте
Процедура Детали(Команда)
	ОтображатьДеталиЗаявки					= Не ОтображатьДеталиЗаявки;
	Элементы.ГруппаОписание.Видимость		= ОтображатьДеталиЗаявки;
	Элементы.СписокТекущиеДетали.Пометка	= ОтображатьДеталиЗаявки;
КонецПроцедуры