///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

#Область ДляВызоваИзДругихПодсистем

//// СтандартныеПодсистемы.ВариантыОтчетов
//
//// См. ВариантыОтчетовПереопределяемый.НастроитьВариантыОтчетов.
////
//Процедура НастроитьВариантыОтчета(Настройки, НастройкиОтчета) Экспорт
//	МодульВариантыОтчетов = ОбщегоНазначения.ОбщийМодуль("ВариантыОтчетов");
//	МодульВариантыОтчетов.УстановитьРежимВыводаВПанеляхОтчетов(Настройки, НастройкиОтчета, Истина);
//	
//	НастройкиВарианта = МодульВариантыОтчетов.ОписаниеВарианта(Настройки, НастройкиОтчета, "");
//	НастройкиВарианта.Описание = 
//		НСтр("ru = 'Информация о респондентах, заполнивших анкеты по опросу,
//		|количестве ответов на вопросы, количестве данных вариантов ответов.'");
//	НастройкиВарианта.НастройкиДляПоиска.НаименованияПолей = 
//		НСтр("ru = 'Респондент
//		|Опрос
//		|Вопрос
//		|Ответ'");
//	НастройкиВарианта.НастройкиДляПоиска.НаименованияПараметровИОтборов = 
//		НСтр("ru = 'Опрос
//		|Вид отчета'");
//КонецПроцедуры
//
//// Конец СтандартныеПодсистемы.ВариантыОтчетов

#КонецОбласти

#КонецОбласти

#КонецЕсли