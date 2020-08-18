
// Возвращает ссылку на общий модуль по имени.
//
// Параметры:
//  Имя          - Строка - имя общего модуля, например:
//                 "ОбщегоНазначения",
//                 "ОбщегоНазначенияКлиент".
//
// Возвращаемое значение:
//  ОбщийМодуль.
//
Функция ОбщийМодуль(Имя) Экспорт
	
	Модуль = Вычислить(Имя);
	
#Если НЕ ВебКлиент Тогда
	Если ТипЗнч(Модуль) <> Тип("ОбщийМодуль") Тогда
		ВызватьИсключение СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(НСтр("ru = 'Общий модуль ""%1"" не найден.'"), Имя);
	КонецЕсли;
#КонецЕсли
	
	Возврат Модуль;
	
КонецФункции

// Устанавливает флаг скрытия рабочего стола при начале работы системы,
// который блокирует создание форм на рабочем столе.
// Снимает флаг скрытия и обновляет рабочий стол, когда это станет возможным,
// если скрытие выполнялось.
//
// Параметры:
//  Скрыть - Булево. Если передать Ложь, тогда при условии скрытия рабочего
//           стола он будет вновь показан.
//
//  УжеВыполненоНаСервере - Булево. Если передать Истина, тогда уже был вызван
//           метод в модуле СтандартныеПодсистемыВызовСервера, и его не требуется
//           вызвать, а требуется только установить на клиенте, что рабочий стол
//           был скрыт и позднее его требуется показать.
//
Процедура СкрытьРабочийСтолПриНачалеРаботыСистемы(Скрыть = Истина, УжеВыполненоНаСервере = Ложь) Экспорт
	
	Если Скрыть Тогда
		Если НЕ ПараметрыПриЗапускеИЗавершенииПрограммы.Свойство("СкрытьРабочийСтолПриНачалеРаботыСистемы") Тогда
			ПараметрыПриЗапускеИЗавершенииПрограммы.Вставить("СкрытьРабочийСтолПриНачалеРаботыСистемы");
			Если НЕ УжеВыполненоНаСервере Тогда
				ОбщегоНазначенияСервер.СкрытьРабочийСтолПриНачалеРаботыСистемы();
			КонецЕсли;
		КонецЕсли;
	Иначе
		Если ПараметрыПриЗапускеИЗавершенииПрограммы.Свойство("СкрытьРабочийСтолПриНачалеРаботыСистемы") Тогда
			ПараметрыПриЗапускеИЗавершенииПрограммы.Удалить("СкрытьРабочийСтолПриНачалеРаботыСистемы");
			Если НЕ УжеВыполненоНаСервере Тогда
				ОбщегоНазначенияСервер.СкрытьРабочийСтолПриНачалеРаботыСистемы(Ложь);
			КонецЕсли;
			ТекущееАктивноеОкно = АктивноеОкно();
			ОбновитьИнтерфейс();
			Если ТекущееАктивноеОкно <> Неопределено Тогда
				ТекущееАктивноеОкно.Активизировать();
			КонецЕсли;
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

// Открывает форму ввода параметров администрирования информационной базы и/или кластера
//
// Параметры:
//	ОписаниеОповещенияОЗакрытии - ОписаниеОповещения - Обработчик, который будет вызван после ввода параметров администрирования
//	ЗапрашиватьПараметрыАдминистрированияИБ - Булево - Признак необходимости ввода параметров администрирования информационной базы
//	ЗапрашиватьПараметрыАдминистрированияКластера - Булево - Признак необходимости ввода параметров администрирования кластера
//	ПараметрыАдминистрирования - Структура - Параметры администрирования, которые были введены ранее
//	Заголовок - Строка - Заголовок формы, описывающий для чего запрашиваются параметры администрирования
//	ПоясняющаяНадпись - Строка - Пояснение для выполняемого действия, в контексте которого запрашиваются параметры
//
Процедура ПоказатьПараметрыАдминистрирования(ОписаниеОповещенияОЗакрытии, ЗапрашиватьПараметрыАдминистрированияИБ = Истина,
	ЗапрашиватьПараметрыАдминистрированияКластера = Истина, ПараметрыАдминистрирования = Неопределено,
	Заголовок = "", ПоясняющаяНадпись = "") Экспорт
	
	ПараметрыФормы = Новый Структура;
	ПараметрыФормы.Вставить("ЗапрашиватьПараметрыАдминистрированияИБ", ЗапрашиватьПараметрыАдминистрированияИБ);
	ПараметрыФормы.Вставить("ЗапрашиватьПараметрыАдминистрированияКластера", ЗапрашиватьПараметрыАдминистрированияКластера);
	ПараметрыФормы.Вставить("ПараметрыАдминистрирования", ПараметрыАдминистрирования);
	ПараметрыФормы.Вставить("Заголовок", Заголовок);
	ПараметрыФормы.Вставить("ПоясняющаяНадпись", ПоясняющаяНадпись);
	
	//@skip-warning
	ОткрытьФорму("ОбщаяФорма.ПараметрыАдминистрированияПрограммы", ПараметрыФормы,,,,,ОписаниеОповещенияОЗакрытии);
	
КонецПроцедуры

// Функция получает цвет стиля по имени элемента стиля
//
// Параметры:
//	ИмяЦветаСтиля - строка с именем элемента
//
// Возвращаемое значение - цвет стиля
//
Функция ЦветСтиля(ИмяЦветаСтиля) Экспорт
	
	Возврат ОбщегоНазначенияСервер.ЦветСтиля(ИмяЦветаСтиля);
	
КонецФункции

Процедура ОткрытьЗаявкуПользователя(ДополнительныеПараметры) Экспорт
	
	ПараметрыФормы	= Новый Структура;
	ПараметрыФормы.Вставить("Ключ", ДополнительныеПараметры);
	ОткрытьФорму("Документ.ЗаявкаПользователя.ФормаОбъекта", ПараметрыФормы);
	
КонецПроцедуры

Процедура ПоказатьСообщениеПользователю(КлючДанных, ПутьКДанным, Поле, Текст) Экспорт
	
	Сообщение	= Новый СообщениеПользователю;
	Сообщение.Текст			= Текст;
	Сообщение.Поле			= Поле;
	Сообщение.ПутьКДанным	= ПутьКДанным;
	Сообщение.КлючДанных	= КлючДанных;               			
	Сообщение.Сообщить();
			
КонецПроцедуры