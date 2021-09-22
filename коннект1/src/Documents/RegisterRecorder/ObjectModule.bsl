
Процедура ПередЗаписью(Отказ, РежимЗаписи, РежимПроведения)
	Если ОбменДанными.Загрузка Тогда
		Возврат;
	КонецЕсли;
	Если Не ЭтоНовый() И Ссылка.ПометкаУдаления <> ПометкаУдаления Тогда
		УстановитьАктивностьДвижений(НЕ ПометкаУдаления);
	ИначеЕсли ПометкаУдаления Тогда
		УстановитьАктивностьДвижений(Ложь);
	КонецЕсли;
КонецПроцедуры

Процедура УстановитьАктивностьДвижений(ФлагАктивности)
	Для Каждого Движение Из Движения Цикл
		Движение.Прочитать();
		Движение.УстановитьАктивность(ФлагАктивности);
	КонецЦикла;
КонецПроцедуры
