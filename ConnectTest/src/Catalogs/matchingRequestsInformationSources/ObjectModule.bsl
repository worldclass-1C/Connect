
Процедура ПередЗаписью(Отказ)
	Для Каждого СтрокаТЧ Из informationSources Цикл
		СтрокаТЧ.requestSource			= Код;
		СтрокаТЧ.performBackground			= performBackground;
		СтрокаТЧ.staffOnly	= staffOnly;
		СтрокаТЧ.notSaveAnswer	= notSaveAnswer;
	КонецЦикла;
КонецПроцедуры
