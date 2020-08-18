&НаКлиенте
Перем Буфер;
&НаКлиенте
Перем СтраницаРазработчика;
&НаКлиенте
Перем ОтветПередЗакрытием;

&НаСервереБезКонтекста
Функция ПолучитьСтруктуруДействия(НавигационнаяСсылка)
	Возврат Справочники.КомментарииЗаявок.ПолучитьСтруктуруДействия(НавигационнаяСсылка);
КонецФункции


#Область НаСервере

&НаСервере
Функция СформироватьДеревоДокументов()
	Возврат ЗаявкаПользователя.СформироватьДеревоДокументов(ЭтаФорма);
КонецФункции

&НаСервере
Процедура ПриЧтенииНаСервере(ТекущийОбъект)
	ЗаявкаПользователя.ПриЧтенииНаСервере(ЭтаФорма, ТекущийОбъект);
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ЗаявкаПользователя.ПриСозданииНаСервере(ЭтаФорма, Отказ, СтандартнаяОбработка);
КонецПроцедуры

&НаСервере
Процедура ПередЗаписьюНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	ЗаявкаПользователя.ПередЗаписьюНаСервере(ЭтаФорма, Отказ, ТекущийОбъект, ПараметрыЗаписи);
КонецПроцедуры

&НаСервере
Процедура ПослеЗаписиНаСервере(ТекущийОбъект, ПараметрыЗаписи)
	ЗаявкаПользователя.ПослеЗаписиНаСервере(ЭтаФорма, ТекущийОбъект, ПараметрыЗаписи);	
КонецПроцедуры

&НаСервере
Функция ДобавитьФайлНаСервере(Адрес, ИмяФайла)
	
	Заявка = РеквизитФормыВЗначение("Объект");
	Попытка
		ВыбранныйФайл = Новый Файл(ИмяФайла);
		НоваяСтрока = Заявка.ВложенныеФайлы.Добавить();		
		НоваяСтрока.ИмяФайла		= ВыбранныйФайл.Имя;
		НоваяСтрока.Хранилище		= Новый ХранилищеЗначения(ПолучитьИзВременногоХранилища(Адрес), Новый СжатиеДанных(9));
		НоваяСтрока.ИндексКартинки  = РаботаСФайламиКлиентСервер.ПолучитьИндексПиктограммыФайла(ВыбранныйФайл.Расширение);
		
		Отказ	= Ложь;
		ПередЗаписьюНаСервере(Отказ, Заявка, Новый Структура("РежимЗаписи, РежимПроведения", РежимЗаписиДокумента.Проведение, РежимПроведенияДокумента.Неоперативный));
		Если Не Отказ Тогда
			Заявка.Записать(РежимЗаписиДокумента.Проведение, РежимПроведенияДокумента.Неоперативный);			
		КонецЕсли;
		ЗначениеВРеквизитФормы(Заявка,"Объект");
		Возврат "";
	Исключение
		Возврат ОписаниеОшибки();
	КонецПопытки;
	
КонецФункции	

&НаСервере
Функция ПроверитьДанныеХранилища(НомерСтрокиВложений) Экспорт 
	
	Заявка = РеквизитФормыВЗначение("Объект");
	СтруктураДанных = Новый Структура("ТипДанных,Расширение,ВложенныйФайл,ИмяФайла");
	ТекСтрока = Заявка.ВложенныеФайлы[НомерСтрокиВложений];
	Данные = ТекСтрока.Хранилище.Получить();
	Если Данные <> Неопределено Тогда
		Если ТипЗнч(Данные) = Тип("ДвоичныеДанные") Тогда
			СтруктураДанных.ТипДанных = "ДвоичныеДанные";
			СтруктураДанных.ВложенныйФайл = Данные;
			СтруктураДанных.ИмяФайла = ТекСтрока.ИмяФайла;
		Иначе
			СтруктураДанных.ТипДанных = Неопределено;	
			СтруктураДанных.ВложенныйФайл = Неопределено;
			СтруктураДанных.ИмяФайла = Неопределено;
		КонецЕсли;
		
	Иначе
		СтруктураДанных.ТипДанных = Неопределено;
	КонецЕсли;
	СтруктураДанных.Расширение = ОбщегоНазначения.ПолучитьРасширениеФайла(ТекСтрока.ИмяФайла);
	Возврат СтруктураДанных;
	
КонецФункции // ПроверитьДанныеХранилища()

&НаСервере
Функция ЗаписатьВоВременныйФайл(НомерСтрокиВложений) Экспорт
	
	Структура = Новый Структура("ИмяФайла, Расширение, Адрес");
	
	Заявка = РеквизитФормыВЗначение("Объект");
	ТекСтрока = Заявка.ВложенныеФайлы[НомерСтрокиВложений];
	Структура.ИмяФайла		= ТекСтрока.ИмяФайла;
	Структура.Расширение	= ОбщегоНазначения.ПолучитьРасширениеФайла(ТекСтрока.ИмяФайла);
	Структура.Адрес			= ПоместитьВоВременноеХранилище(ТекСтрока.Хранилище.Получить(), УникальныйИдентификатор);	
	
	Возврат Структура;
	
КонецФункции

&НаСервере
Процедура УдалитьФайлНаСервере(НомерСтрокиВложений)
	Заявка = РеквизитФормыВЗначение("Объект");
	ТекСтрока = Заявка.ВложенныеФайлы[НомерСтрокиВложений];
	Заявка.ВложенныеФайлы.Удалить(ТекСтрока);
	ЗначениеВРеквизитФормы(Заявка,"Объект");
КонецПроцедуры

#КонецОбласти

#Область НаКлиенте

&НаКлиенте
Процедура ОповещениеОписаниеДобавить(Результат, ДополнительныеПараметры) Экспорт	
	ЗаявкаПользователяКлиент.ОповещениеОписаниеДобавить(ЭтаФорма, Результат, ДополнительныеПараметры);
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеЗаявкаОтменить(Результат, ДополнительныеПараметры) Экспорт
	ЗаявкаПользователяКлиент.ОповещениеЗаявкаОтменить(ЭтаФорма, Результат, ДополнительныеПараметры);
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеВыбратьЗаказчика(Результат, ДополнительныеПараметры) Экспорт
	ЗаявкаПользователяКлиент.ОповещениеВыбратьЗаказчика(ЭтаФорма, Результат, ДополнительныеПараметры);	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеПослеВводаДаты(Время, ДополнительныеПараметры) Экспорт
	ЗаявкаПользователяКлиент.ОповещениеПослеВводаДаты(ЭтаФорма, Время, ДополнительныеПараметры);	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеВыборИзМеню(Результат, ДополнительныеПараметры) Экспорт	
	Если Результат <> Неопределено Тогда
		ЗаявкаПользователяКлиент.ОповещениеВыборИзМеню(ЭтаФорма, Результат, ДополнительныеПараметры);
		ПодключитьОбработчикОжидания("ОбработчикОжиданияОписаниеДобавить", 0.1, Истина);		
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаОповещения(ИмяСобытия, Параметр, Источник)
	ЗаявкаПользователяКлиент.ОбработкаОповещения(ЭтаФорма, ИмяСобытия, Параметр, Источник);
КонецПроцедуры

&НаКлиенте
Процедура ПриПовторномОткрытии()
	ЗаявкаПользователяКлиент.ПриПовторномОткрытии(ЭтаФорма);
КонецПроцедуры

//--------------------------------------------------------------------------
//Работа с файлами

//Оповещения
&НаКлиенте
Процедура ОповещениеУстановкаРасширенияРаботыСФайлами(ДополнительныеПараметры) Экспорт
	ВыполнитьДействиеСФайлом(ДополнительныеПараметры);	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеПодключениеРасширенияРаботыСФайлами(Подключено, ДополнительныеПараметры) Экспорт
	Если Подключено Тогда
		ВыполнитьДействиеСФайлом(ДополнительныеПараметры);
	Иначе
		ОписаниеОповещенияУстановкаРасширенияРаботыСФайлами	= Новый ОписаниеОповещения("ОповещениеУстановкаРасширенияРаботыСФайлами", ЭтаФорма, ДополнительныеПараметры);
		НачатьУстановкуРасширенияРаботыСФайлами(ОписаниеОповещенияУстановкаРасширенияРаботыСФайлами);
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеВыбратьФайл(Результат, Адрес, ВыбранноеИмяФайла, ДополнительныеПараметры) Экспорт	
	Если Результат Тогда
		ДобавитьФайлНаСервере(Адрес, ВыбранноеИмяФайла);
		КоличествоВложенныхФайлов	= "" + Объект.ВложенныеФайлы.Количество();
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеСохранениеФайла(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт
	
	Если ВыбранныеФайлы <> Неопределено Тогда
		Для Каждого ВыбранныйФайл Из ВыбранныеФайлы Цикл
			Попытка
				Данные = ДополнительныеПараметры.ВложенныйФайл;
				Данные.Записать(ВыбранныйФайл);
				ПоказатьПредупреждение(, "Файл успешно записан!");
			Исключение
				ПоказатьПредупреждение(, ОписаниеОшибки());
			КонецПопытки;
		КонецЦикла;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеПолучитьФайлЗавершение(ПолученныеФайлы, ДополнительныеПараметры) Экспорт
	Если ДополнительныеПараметры = "Открыть" И ПолученныеФайлы <> Неопределено И ТипЗнч(ПолученныеФайлы) = Тип("Массив") И ПолученныеФайлы.Количество() Тогда    	
		//@skip-warning
		НачатьЗапускПриложения(Новый ОписаниеОповещения("ОповещениеЗапускПриложения", ЭтотОбъект), ПолученныеФайлы[0].ПолноеИмя);
	ИначеЕсли ДополнительныеПараметры = "Сохранить" Тогда
		ПоказатьОповещениеПользователя("Файл сохранен", "", ПолученныеФайлы[0].Имя, БиблиотекаКартинок.Дискета, СтатусОповещенияПользователя.Информация);		
	КонецЕсли;    
КонецПроцедуры


//@skip-warning
&НаКлиенте
Процедура ОповещениеЗапускПриложения(КодВозврата, ДополнительныеПараметры) Экспорт
	//Служебный метод не удалять 			
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеСохранитьФайлЗавершение(ПолученныеФайлы, ДополнительныеПараметры) Экспорт
	Если ПолученныеФайлы <> Неопределено И ТипЗнч(ПолученныеФайлы) = Тип("Массив") И ПолученныеФайлы.Количество() Тогда			
		МассивПолучаемыхФайлов = Новый Массив;
		МассивПолучаемыхФайлов.Добавить(Новый ОписаниеПередаваемогоФайла(ПолученныеФайлы[0], ДополнительныеПараметры.Адрес));		
		НачатьПолучениеФайлов(Новый ОписаниеОповещения("ОповещениеПолучитьФайлЗавершение", ЭтотОбъект, "Сохранить"), МассивПолучаемыхФайлов,,Ложь);
	КонецЕсли;    
КонецПроцедуры

&НаКлиенте
Процедура ОповещениеПоказатьВопросУдалитьФайл(РезультатВопроса, ДополнительныеПараметры) Экспорт
	
	Если РезультатВопроса <> Неопределено Тогда		
		Если РезультатВопроса = КодВозвратаДиалога.Да Тогда			
			УдалитьФайлНаСервере(ДополнительныеПараметры.НомерСтроки - 1);
			КоличествоВложенныхФайлов	= "" + Объект.ВложенныеФайлы.Количество();
			//++Степовая 28.08.19
			ЭтаФорма.Модифицированность = Истина;
			//--Степовая 28.09.19
		КонецЕсли;		
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьДействие(Действие)
	ОписаниеОповещенияПодключениеРасширенияРаботыСФайлами	= Новый ОписаниеОповещения("ОповещениеПодключениеРасширенияРаботыСФайлами", ЭтаФорма, Действие);
	НачатьПодключениеРасширенияРаботыСФайлами(ОписаниеОповещенияПодключениеРасширенияРаботыСФайлами);
КонецПроцедуры

&НаКлиенте
Процедура ВыполнитьДействиеСФайлом(ДополнительныеПараметры)
	
	Если ДополнительныеПараметры = "ДобавитьФайл" Тогда
		
		Адрес = "";		
		ОписаниеОповещенияВыбораФайла	= Новый ОписаниеОповещения("ОповещениеВыбратьФайл", ЭтаФорма);
		НачатьПомещениеФайла(ОписаниеОповещенияВыбораФайла, Адрес, "", Истина);				
		
	ИначеЕсли ДополнительныеПараметры = "ОткрытьФайл" Тогда
		
		ТекДанные = Элементы.ВложенныеФайлы.ТекущиеДанные;
		
		Если ТекДанные = Неопределено Тогда
			ПоказатьПредупреждение(, "Выделите курсором нужный файл");
		Иначе		
			НомерСтрокиВложений = Элементы.ВложенныеФайлы.ТекущиеДанные.НомерСтроки - 1;
			Структура	= ЗаписатьВоВременныйФайл(НомерСтрокиВложений);		
			ВремФайл	= ОбщегоНазначенияСервер.ПолучитьИмяВременногоФайлаСервер(Структура.Расширение);
			
			МассивПолучаемыхФайлов = Новый Массив;
			МассивПолучаемыхФайлов.Добавить(Новый ОписаниеПередаваемогоФайла(ВремФайл, Структура.Адрес));
			
			НачатьПолучениеФайлов(Новый ОписаниеОповещения("ОповещениеПолучитьФайлЗавершение", ЭтотОбъект, "Открыть"), МассивПолучаемыхФайлов,, Ложь);			
		КонецЕсли;
		
	ИначеЕсли ДополнительныеПараметры = "СохранитьФайл" Тогда
		
		ТекДанные = Элементы.ВложенныеФайлы.ТекущиеДанные;
		Если ТекДанные = Неопределено Тогда
			ПоказатьПредупреждение(, "Выделите курсором нужный файл");
		Иначе			
			НомерСтрокиВложений = Элементы.ВложенныеФайлы.ТекущиеДанные.НомерСтроки - 1;
			Структура	= ЗаписатьВоВременныйФайл(НомерСтрокиВложений);		
			
			ДиалогСохранениеФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);
			ДиалогСохранениеФайла.МножественныйВыбор	= Ложь;
			ДиалогСохранениеФайла.ПолноеИмяФайла		= Структура.ИмяФайла;
			ДиалогСохранениеФайла.Показать(Новый ОписаниеОповещения("ОповещениеСохранитьФайлЗавершение", ЭтотОбъект, Структура));			
		КонецЕсли;	
		
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ВложенныеФайлыВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	ОткрытьФайл("");	
КонецПроцедуры

//&НаКлиенте
//Процедура ОповещениеОтветНаВопросМодифицированности(РезультатВопроса, ДополнительныеПараметры) Экспорт	
//	Если РезультатВопроса = КодВозвратаДиалога.Да Тогда		
//		Если Записать() Тогда
//			ИзменитьСостояниеЗаявкиВФорме(ДополнительныеПараметры);
//		КонецЕсли;
//	КонецЕсли;	
//КонецПроцедуры

//Обработчики команд
&НаКлиенте
Процедура ДобавитьФайл(Команда)
	ВыполнитьДействие("ДобавитьФайл");
	//++Степовая
	Если Объект.Ссылка.Пустая() Тогда
		ЗаявкаПользователяКлиент.ПроверитьМодифицированностьФормы(ЭтаФорма, Элементы.ЗаявкаЗарегистрировать);
	КонецЕсли;
	//--Степовая
КонецПроцедуры

&НаКлиенте
Процедура ОткрытьФайл(Команда)
	ВыполнитьДействие("ОткрытьФайл");
КонецПроцедуры

&НаКлиенте
Процедура СохранитьФайл(Команда)	
	ВыполнитьДействие("СохранитьФайл");		
КонецПроцедуры

&НаКлиенте
Процедура УдалитьФайл(Команда)
	
	ТекДанные = Элементы.ВложенныеФайлы.ТекущиеДанные;
	Если ТекДанные = Неопределено Тогда
		ПоказатьПредупреждение(,"Выделите строку, которую хотите удалить");
	Иначе
		ОписаниеОповещенияПоказатьВопросУдалитьФайл	= Новый ОписаниеОповещения("ОповещениеПоказатьВопросУдалитьФайл", ЭтаФорма, ТекДанные);
		ПоказатьВопрос(ОписаниеОповещенияПоказатьВопросУдалитьФайл,"Вы действительно хотите удалить вложенный файл",РежимДиалогаВопрос.ДаНет);
	КонецЕсли;
	
КонецПроцедуры

//Служебные процедуры 
&НаКлиенте
Процедура ИзменитьРелизЗаявки()	
	ЗаявкаПользователяКлиент.ИзменитьРелизЗаявки(ЭтаФорма);
КонецПроцедуры

//&НаКлиенте
//Процедура ИзменитьСостояниеЗаявкиВФорме(Команда)
//	ЗаявкаПользователяКлиент.ИзменитьСостояниеЗаявкиВФорме(ЭтаФорма, Команда);
//КонецПроцедуры

&НаКлиенте
Процедура ПроверитьМодифицированностьФормы(Команда)
	ЗаявкаПользователяКлиент.ПроверитьМодифицированностьФормы(ЭтаФорма, Команда);
КонецПроцедуры

&НаКлиенте
Процедура ИсполнительПриИзменении(Элемент)	
	ЗаявкаПользователяКлиент.ИсполнительПриИзменении(ЭтаФорма,Элемент);
КонецПроцедуры

&НаКлиенте
Процедура ДатаВыполненияПриИзменении(Элемент)
	ЗаявкаПользователяКлиент.ДатаВыполненияПриИзменении(ЭтаФорма, Элемент);
КонецПроцедуры

&НаКлиенте
Процедура ВидДеятельностиПриИзменении(Элемент)
	ЗаявкаПользователяКлиент.ВидДеятельностиПриИзменении(ЭтаФорма, Элемент);
КонецПроцедуры

&НаКлиенте
Процедура ОбработчикОжиданияОписаниеДобавить() Экспорт 
	ЗаявкаПользователяКлиент.ОбработчикОжиданияОписаниеДобавить(ЭтаФорма);
КонецПроцедуры

&НаКлиенте
Процедура ОписаниеДобавить(Команда)	
	//++Степовая
	ЭтоОтменаЗаявки = Ложь;
	Если ЗаявкаПользователяКлиент.ДобавитьКомментарий(ЭтаФорма, Команда) Тогда
		ПодключитьОбработчикОжидания("ОбработчикОжиданияОписаниеДобавить", 0.1, Истина);
	КонецЕсли;	
	Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
		СтраницаРазработчика = Истина;
	Иначе
		СтраницаРазработчика = Ложь;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ЗадатьВопрос(Команда)
	
	Если Объект.Ссылка.Пустая() Тогда
		ОбщегоНазначенияКлиент.ПоказатьСообщениеПользователю(Объект.Ссылка, "Объект", "Номер", "Необходимо записать заявку");
	Иначе
		СписокПунктовМеню	= Новый СписокЗначений;		
		
		Если Истина
			И ТекущийПользователь <> Объект.Заказчик 
			И Элементы.ГруппаСтаницыОписания.ТекущаяСтраница <> Элементы.СтраницаОписаниеРазработчика 
		Тогда
			СписокПунктовМеню.Добавить(Объект.Заказчик, Объект.Заказчик,, БиблиотекаКартинок.Заказчик16х16);
		КонецЕсли;		
		
		Если Истина
			И Не Объект.Исполнитель.Пустая() 
			И ТекущийПользователь <> Объект.Исполнитель 
			И Объект.Заказчик <> Объект.Исполнитель 
		Тогда
			СписокПунктовМеню.Добавить(Объект.Исполнитель, Объект.Исполнитель,, БиблиотекаКартинок.Разработчик16х16);
		КонецЕсли;
		
		Если Истина
			И Не Объект.Тестировщик.Пустая() 
			И ТекущийПользователь <> Объект.Тестировщик 
			И Объект.Заказчик <> Объект.Тестировщик 
			И Объект.Исполнитель <> Объект.Тестировщик 
		Тогда
			СписокПунктовМеню.Добавить(Объект.Тестировщик, Объект.Тестировщик,, БиблиотекаКартинок.Тестировщик16х16);
		КонецЕсли;
		
		Для Каждого СтрокаТЗ Из ТЗНаблюдатели Цикл
			Если Истина
				И ТекущийПользователь <> СтрокаТЗ.Наблюдатель 
				И Объект.Заказчик <> СтрокаТЗ.Наблюдатель 
				И Объект.Исполнитель <> СтрокаТЗ.Наблюдатель 
				И Объект.Тестировщик <> СтрокаТЗ.Наблюдатель 
				Тогда
				СписокПунктовМеню.Добавить(СтрокаТЗ.Наблюдатель, СтрокаТЗ.Наблюдатель,, БиблиотекаКартинок.Очки24х24);
			КонецЕсли;
		КонецЦикла;
		
		ОписаниеОповещенияПослеВыборкаИзМеню = Новый ОписаниеОповещения("ОповещениеВыборИзМеню", ЭтотОбъект);
		ПоказатьВыборИзМеню(ОписаниеОповещенияПослеВыборкаИзМеню, СписокПунктовМеню, Команда);		
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ЗаказчикИзменить(Команда)
	Оповещение = Новый ОписаниеОповещения("ОповещениеВыбратьЗаказчика", ЭтотОбъект);
	ПоказатьВводЗначения(Оповещение, Объект.Заказчик, "Выберите заказчика");	
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаСохранить(Команда)
	//++Степовая 27.11.19
	Если ПроверитьКомментарий() Тогда
		Оповещение = Новый ОписаниеОповещения("ПослеВопросаСохранитьКомментарий",ЭтотОбъект);	
		ПоказатьВопрос(Оповещение,"Сохранить комментарий?",
		РежимДиалогаВопрос.ДаНетОтмена,0, КодВозвратаДиалога.Да, "Есть несохраненный комментарий!"); 
	КонецЕсли;
	//--Степовая 27.11.19
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры
//++Степовая 27.11.19
&НаКлиенте
Процедура ПослеВопросаСохранитьКомментарий(Результат, Параметры) Экспорт
	Если Результат = КодВозвратаДиалога.Да Тогда
		СохранитьКомментарийНаСервере();
		ОповещениеОписаниеДобавить("ОК", Неопределено);
		Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
			Элементы.ГруппаКомментарийРазработчика.Видимость	= Ложь;
		Иначе
			Элементы.ГруппаКомментарий.Видимость	= Ложь;		
		КонецЕсли;
		Элементы.ЗаявкаСохранить.КнопкаПоУмолчанию	= Истина;
	КонецЕсли;
	Если Параметры = Истина Тогда
		ОтветПередЗакрытием = Истина;
		Закрыть();
	КонецЕсли;
	
КонецПроцедуры	
//--Степовая 27.11.19
&НаКлиенте
Процедура ЗаявкаПередатьКИсполнению(Команда)	
	ПроверитьМодифицированностьФормы(Команда);	
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаСогласовать(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаПередатьНаСогласованиеПР(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаСогласоватьПР(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаВернутьПРВРаботу(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаОтменить(Команда)
	Если Не ПроверитьДоступностьНаСервере() Тогда //++Степовая
		Если ЭтаФорма.ПроверитьЗаполнение()Тогда //++Степовая
			ЭтоОтменаЗаявки = Истина;
			Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеЗаказчика; 
			Если ЗаявкаПользователяКлиент.ДобавитьКомментарий(ЭтаФорма, Команда) Тогда
				ПодключитьОбработчикОжидания("ОбработчикОжиданияОписаниеДобавить", 0.1, Истина);
			КонецЕсли;	
			
			//ПараметрыФормы = Новый Структура();
			//ПараметрыФормы.Вставить("Заявка", Объект.Ссылка);
			//ОписаниеОповещенияЗаявкаОтменить = Новый ОписаниеОповещения("ОповещениеЗаявкаОтменить", ЭтотОбъект, Команда);
			//ОткрытьФорму("Документ.ЗаявкаПользователя.Форма.ФормаКомментария", ПараметрыФормы, ЭтаФорма,,,, ОписаниеОповещенияЗаявкаОтменить, РежимОткрытияОкнаФормы.Независимый);
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры
//+++Степовая
&НаСервере
Функция  ПроверитьДоступностьНаСервере()
	Отказ = Ложь;
	СтруктураОтвета	= Справочники.БазыДанных.ПроверитьДоступностьИнформационнойСистемыПользователямЗаявки(Объект);
	Для Каждого Ответ Из СтруктураОтвета Цикл
		Сообщение	= Новый СообщениеПользователю;
		Сообщение.Текст			= Ответ.Значение;
		Сообщение.Поле			= Ответ.Ключ;
		Сообщение.ПутьКДанным	= "Объект";
		Сообщение.КлючДанных	= Объект.Ссылка;               			
		Сообщение.Сообщить();
		Отказ	= Истина;	
	КонецЦикла; 
	Возврат Отказ;
КонецФункции 
//--Степовая	
&НаКлиенте
Процедура ЗаявкаВзятьВРаботу(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаПередатьНаКонтроль(Команда)	
	Если КонтрольРелизов И Объект.РелизОписание = "" Тогда
		ОбщегоНазначенияКлиент.ПоказатьСообщениеПользователю(Объект.Ссылка, "Объект", "РелизОписание", "Необходимо заполнить описание для релиза");		
	Иначе
		ПоказатьОповещениеПользователя("ВНИМАНИЕ!!!",,"Не забудьте отразить заявку в УРВ", БиблиотекаКартинок.КругКрасный);
		ПроверитьМодифицированностьФормы(Команда);
	КонецЕсли; 
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаПередатьНаПроверку(Команда)	
	ПроверитьМодифицированностьФормы(Команда);	
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаПолученОтвет(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаВОжидании(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаВыполнено(Команда)
	ПроверитьМодифицированностьФормы(Команда);	
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаЗакрыть(Команда)
	ПроверитьМодифицированностьФормы(Команда);
	Закрыть();
КонецПроцедуры

&НаКлиенте
Процедура ЗаявкаЗарегистрировать(Команда)
	ПроверитьМодифицированностьФормы(Команда);
КонецПроцедуры

&НаКлиенте
Процедура ПередЗаписью(Отказ, ПараметрыЗаписи)
	Если Объект.База1С.Пустая() Тогда
		ОбщегоНазначенияКлиент.ПоказатьСообщениеПользователю(Объект.Ссылка, "Объект", "База1С", "Необходимо заполнить инф. систему");
		Отказ	= Истина;	
	КонецЕсли; 
КонецПроцедуры

//&НаКлиенте
//Процедура ПослеЗаписи(ПараметрыЗаписи)
//	//ЗаявкаПользователяКлиент.УстановитьДоступностьЭлементовФормы(ЭтаФорма, СостояниеЗаявки);
//КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	ЗаявкаПользователяКлиент.УстановитьДоступностьЭлементовФормы(ЭтаФорма, СостояниеЗаявки);
	//++Степовая 
	ЭтоОтменаЗаявки = Ложь;
	СтраницаРазработчика = Ложь;
КонецПроцедуры

&НаКлиенте
Процедура ПриЗакрытии(ЗавершениеРаботы)	
	Если ЕстьИзменения И Не ЗавершениеРаботы Тогда		
		ОповеститьОбИзменении(Объект.Ссылка);			
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Процедура ДобавитьВУРВ(Команда)
	Оповещение = Новый ОписаниеОповещения("ОповещениеПослеВводаДаты", ЭтаФорма);
	ПоказатьВводДаты(Оповещение, Дата(1,1,1), "Введите длительность", ЧастиДаты.Время);
КонецПроцедуры

&НаКлиенте
Процедура РелизНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)	
	СтандартнаяОбработка = Ложь;
	ПараметрыФормы = Новый Структура();
	ПараметрыФормы.Вставить("ИнформационнаяСистема", Объект.База1С);
	ПараметрыФормы.Вставить("ДатаВыполнения", Объект.ДатаВыполнения);
	ОткрытьФорму("Справочник.Релизы.ФормаВыбора", ПараметрыФормы, Элемент);	
КонецПроцедуры

&НаКлиенте
Процедура СписокЗадачВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	СтандартнаяОбработка	= Ложь;
КонецПроцедуры

&НаКлиенте
Процедура База1СНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)	
	Если ДоступнаРольПользователь Тогда
		СтандартнаяОбработка	= Ложь;		
		ЗначениеОтбора	= Новый Структура("Организация", Организация);
		ПараметрыФормы	= Новый Структура("Отбор", ЗначениеОтбора);	
		ОткрытьФорму("Справочник.БазыДанных.ФормаВыбора", ПараметрыФормы, Элемент,,,,, РежимОткрытияОкнаФормы.БлокироватьОкноВладельца);
	КонецЕсли;	
КонецПроцедуры

&НаКлиенте
Процедура ГруппаСтаницыОписанияПриСменеСтраницы(Элемент, ТекущаяСтраница)
	
	Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтарницаСтруктураПодчиненности Тогда
		Если Не Объект.Ссылка.Пустая() Тогда
			Идентификатор	= СформироватьДеревоДокументов();
			Элементы.ДеревоДокументов.Развернуть(Идентификатор, Истина);
			Элементы.ДеревоДокументов.ТекущаяСтрока	= Идентификатор;
		КонецЕсли; 
	КонецЕсли;
	//++Степовая 28.08.19
	Если ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
		Элементы.ГруппаКомментарий.Видимость	= Ложь;
		Если СтраницаРазработчика Тогда
			Если КомментарийОписания.ПолучитьТекст() <> "" Тогда
				Элементы.ГруппаКомментарийРазработчика.Видимость	= Истина;
			КонецЕсли;
		КонецЕсли;
		
	ИначеЕсли ТекущаяСтраница = Элементы.СтраницаОписаниеЗаказчика Тогда
		Элементы.ГруппаКомментарийРазработчика.Видимость	= Ложь;
		Если Не СтраницаРазработчика Тогда
			Если КомментарийОписания.ПолучитьТекст() <> "" Тогда
				Элементы.ГруппаКомментарий.Видимость	= Истина;
			КонецЕсли; 
		КонецЕсли;
	КонецЕсли;
	//---
КонецПроцедуры

&НаКлиенте
Процедура ДеревоДокументовВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	
	Если Элементы.ДеревоДокументов.ТекущиеДанные <> Неопределено Тогда
		ПараметрыФормы	= Новый Структура;
		ПараметрыФормы.Вставить("Ключ", Элемент.ТекущиеДанные.Заявка);
		ОткрытьФорму("Документ.ЗаявкаПользователя.ФормаОбъекта", ПараметрыФормы, ЭтаФорма);
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ЗаказчикПриИзменении(Элемент)
	ЗаявкаПользователяКлиент.ЗаказчикПриИзменении(ЭтаФорма, Элемент);
КонецПроцедуры

&НаКлиенте
Процедура ОписаниеHTMLПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
	Если ДанныеСобытия.Anchor <> Неопределено И ДанныеСобытия.Anchor.name <> "" Тогда		
		Если ДанныеСобытия.Anchor.name <> "Основание" Тогда			
			СтандартнаяОбработка = Ложь;
			СтруктураОтвета	= ПолучитьСтруктуруДействия(ДанныеСобытия.Href);			
			Если ТекущийПользователь = СтруктураОтвета.Автор Тогда
				Комментарий		= СтруктураОтвета.Комментарий;
				УстановитьHTMLКомментария();
			Иначе 	
				АдресатВопроса	= СтруктураОтвета.Автор;				
			КонецЕсли;
			Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
				Элементы.ГруппаКомментарийРазработчика.Видимость	= Истина;
			Иначе
				Элементы.ГруппаКомментарий.Видимость	= Истина;
			КонецЕсли;
			ПодключитьОбработчикОжидания("ОбработчикОжиданияОписаниеДобавить", 0.1, Истина);			
		КонецЕсли;		
	КонецЕсли;		
КонецПроцедуры

&НаКлиенте
Процедура База1СПриИзменении(Элемент)	
	ИзменитьРелизЗаявки();
КонецПроцедуры

&НаСервере
Процедура НаблюдателиПриИзмененииНаСервере()
	ТЗНаблюдатели.Загрузить(Объект.Наблюдатели.Выгрузить());
КонецПроцедуры

&НаКлиенте
Процедура НаблюдателиПриИзменении(Элемент)
	НаблюдателиПриИзмененииНаСервере();
	КоличествоНаблюдателей	= "" + Объект.Наблюдатели.Количество();
КонецПроцедуры

&НаКлиенте
Процедура СохранитьКомментарий(Команда)
	//++Степовая
	Если ЭтоОтменаЗаявки Тогда
		ЗаявкаПользователяКлиент.ОповещениеЗаявкаОтменить(ЭтаФорма, "ОК", ЭтаФорма.Команды.ЗаявкаОтменить);
	КонецЕсли;
	//--Степовая
	СохранитьКомментарийНаСервере();
	ОповещениеОписаниеДобавить("ОК", Неопределено);
	Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
		Элементы.ГруппаКомментарийРазработчика.Видимость	= Ложь;
	Иначе
		Элементы.ГруппаКомментарий.Видимость	= Ложь;		
	КонецЕсли;
	Элементы.ЗаявкаСохранить.КнопкаПоУмолчанию		= Истина;
КонецПроцедуры

&НаСервере
Процедура СохранитьКомментарийНаСервере()
	СтруктураПараметров	= Новый Структура;
	СтруктураПараметров.Вставить("Заявка", Объект.Ссылка);
	СтруктураПараметров.Вставить("Комментарий", Комментарий);
	СтруктураПараметров.Вставить("Основание", Комментарий.ПорядковыйНомер);	
	СтруктураПараметров.Вставить("АдресатВопроса", АдресатВопроса);
	СтруктураПараметров.Вставить("ДляВнутреннегоИспользования", Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика);
	СтруктураПараметров.Вставить("ТекущийПользователь", ПараметрыСеанса.ТекущийПользователь);
	СтруктураПараметров.Вставить("ТекстHTML", РаботаСHTML.ПолучитьHTMLИзФорматированногоДокумента(КомментарийОписания));
	СтруктураПараметров.Вставить("Вложения", Новый ТаблицаЗначений);
	Справочники.КомментарииЗаявок.ДобавитьОбновитьКомментарий(СтруктураПараметров);
	АдресатВопроса	= Справочники.Пользователи.ПустаяСсылка();
	Комментарий		= Справочники.КомментарииЗаявок.ПустаяСсылка();
	//@skip-warning
	КомментарийОписания	= "";
КонецПроцедуры
//++Степовая 27.11.19
&НаСервере
Функция ПроверитьКомментарий()
	ЕстьНеСохраненныйКомментарий = Ложь;
	КомментарийHTML = РаботаСHTML.ПолучитьHTMLИзФорматированногоДокумента(КомментарийОписания);
	Если Не КомментарийHTML = "" Тогда 
		
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	КомментарииЗаявок.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник.КомментарииЗаявок КАК КомментарииЗаявок
		|ГДЕ
		|	КомментарииЗаявок.Заявка = &Заявка
		|	И КомментарииЗаявок.ПорядковыйНомер = &ПорядковыйНомер";
		
		Запрос.УстановитьПараметр("Заявка"			,Объект.Ссылка);
		Запрос.УстановитьПараметр("ОписаниеHTML"	,КомментарийHTML);
		Запрос.УстановитьПараметр("ПорядковыйНомер"	,Комментарий.ПорядковыйНомер);
		
		Выборка = Запрос.Выполнить().Выбрать();
		
		Если  Выборка.Следующий() Тогда
			ДокHTML = Новый ФорматированныйДокумент;
			ДокHTML.УстановитьHTML(РаботаСHTML.ПолучитьHTMLИзКомментария(Выборка.Ссылка), Новый Структура);
			СохраненныйКомментарий = ДокHTML.ПолучитьТекст();
			КомментарийЗаявки = КомментарийОписания.ПолучитьТекст();
			Если не СохраненныйКомментарий = КомментарийЗаявки Тогда
				ЕстьНеСохраненныйКомментарий = Истина;
			КонецЕсли;
		Иначе
			ЕстьНеСохраненныйКомментарий = Истина;
		КонецЕсли; 
	КонецЕсли; 
	Возврат ЕстьНеСохраненныйКомментарий;
КонецФункции

//--Степовая 27.11.19
&НаСервере
Процедура УстановитьHTMLКомментария()
	КомментарийОписания.УстановитьHTML(РаботаСHTML.ПолучитьHTMLИзКомментария(Комментарий), Новый Структура);
КонецПроцедуры

&НаКлиенте
Процедура ЗакрытьКомментарий(Команда)
	Если Элементы.ГруппаСтаницыОписания.ТекущаяСтраница = Элементы.СтраницаОписаниеРазработчика Тогда
		Элементы.ГруппаКомментарийРазработчика.Видимость	= Ложь;
	Иначе
		Элементы.ГруппаКомментарий.Видимость	= Ложь;
	КонецЕсли;
	Элементы.ЗаявкаСохранить.КнопкаПоУмолчанию	= Истина;
	Комментарий	= Неопределено;
	//@skip-warning
	КомментарийОписания	= "";	
КонецПроцедуры

&НаКлиенте
Процедура ПередЗакрытием(Отказ, ЗавершениеРаботы, ТекстПредупреждения, СтандартнаяОбработка)
	Если Не ЗавершениеРаботы И ПроверитьКомментарий() Тогда
		Если ОтветПередЗакрытием <> Истина Тогда
			Отказ = Истина;
			Оповещение = Новый ОписаниеОповещения("ПослеВопросаСохранитьКомментарий",ЭтотОбъект,Истина);	
			ПоказатьВопрос(Оповещение,"Сохранить комментарий?",
			РежимДиалогаВопрос.ДаНетОтмена,0, КодВозвратаДиалога.Да, "Есть несохраненный комментарий!");
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти