Function list(struct) Export
	Res = New Array;
	chain = struct.chain;
	user = struct.user;
	If ValueIsFilled(chain) and  ValueIsFilled(user) Then 
		Query = new Query("SELECT
		                  |	P.Ref AS ref,
		                  |	P.ДатаОкончания AS endDate,
		                  |	P.Наименование AS title,
		                  |	ISNULL(A.Posted, FALSE) AS isCompleted
		                  |FROM
		                  |	Document.НазначениеОпросов AS P
		                  |		LEFT JOIN Document.Анкета AS A
		                  |		ON A.Опрос = P.Ref
		                  |			AND (A.Респондент = &user
		                  |				AND NOT A.DeletionMark)
		                  |WHERE
		                  |	P.Posted
		                  |	AND NOT P.DeletionMark
		                  |	AND (P.ДатаНачала = DATETIME(1, 1, 1)
		                  |			OR BEGINOFPERIOD(P.ДатаНачала, DAY) < &CurrentDate)
		                  |	AND (P.ДатаОкончания = DATETIME(1, 1, 1)
		                  |			OR ENDOFPERIOD(P.ДатаОкончания, DAY) > &CurrentDate)
		                  |	AND P.chain = &chain");
	
		Query.SetParameter("CurrentDate",CurrentDate());
		Query.SetParameter("chain",chain);
		Query.SetParameter("user",user);
		
		Select = Query.Execute().Select();
		While Select.Next() Do
			Res.Add(New Structure("pollId,endDate,title,isCompleted",
			XMLString(Select.ref.UUID()),Select.endDate,Select.title, Select.isCompleted));
		EndDo;
	EndIf;
	
	Return Res

EndFunction

Function poll(struct) Export
	Res = new Array;
	
	poll = struct.poll;
	user = struct.user;
	
	Query = New Query("SELECT
	|	data.ЭлементарныйВопрос AS ЭлементарныйВопрос
	|INTO ЭлементарныеВопросы
	|FROM
	|	(SELECT
	|		ВопросыШаблонаАнкеты.ЭлементарныйВопрос AS ЭлементарныйВопрос
	|	FROM
	|		Catalog.ВопросыШаблонаАнкеты AS ВопросыШаблонаАнкеты
	|	WHERE
	|		ВопросыШаблонаАнкеты.Owner = &ШаблонАнкеты
	|		AND NOT ВопросыШаблонаАнкеты.IsFolder
	|		AND NOT ВопросыШаблонаАнкеты.DeletionMark
	|		AND NOT ВопросыШаблонаАнкеты.ЭлементарныйВопрос = VALUE(ChartOfCharacteristicTypes.ВопросыДляАнкетирования.Emptyref)
	|
	|	UNION
	|
	|	SELECT
	|		ВопросыШаблонаАнкетыСоставТабличногоВопроса.ЭлементарныйВопрос
	|	FROM
	|		Catalog.ВопросыШаблонаАнкеты.СоставТабличногоВопроса AS ВопросыШаблонаАнкетыСоставТабличногоВопроса
	|	WHERE
	|		ВопросыШаблонаАнкетыСоставТабличногоВопроса.Ref.Owner = &ШаблонАнкеты
	|		AND NOT ВопросыШаблонаАнкетыСоставТабличногоВопроса.Ref.IsFolder
	|		AND NOT ВопросыШаблонаАнкетыСоставТабличногоВопроса.Ref.DeletionMark
	|		AND NOT ВопросыШаблонаАнкетыСоставТабличногоВопроса.ЭлементарныйВопрос = UNDEFINED
	|
	|	UNION
	|
	|	SELECT
	|		ВопросыШаблонаАнкетыСоставКомплексногоВопроса.ЭлементарныйВопрос
	|	FROM
	|		Catalog.ВопросыШаблонаАнкеты.СоставКомплексногоВопроса AS ВопросыШаблонаАнкетыСоставКомплексногоВопроса
	|	WHERE
	|		ВопросыШаблонаАнкетыСоставКомплексногоВопроса.Ref.Owner = &ШаблонАнкеты
	|		AND NOT ВопросыШаблонаАнкетыСоставКомплексногоВопроса.Ref.IsFolder
	|		AND NOT ВопросыШаблонаАнкетыСоставКомплексногоВопроса.Ref.DeletionMark
	|		AND NOT ВопросыШаблонаАнкетыСоставКомплексногоВопроса.ЭлементарныйВопрос = UNDEFINED) AS data
	|;
	|
	|
	|
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ВопросыШаблонаАнкеты.Ref AS questionRef,
	|	PRESENTATION(ВопросыШаблонаАнкеты.Parent) AS section,
	|	CASE ВопросыШаблонаАнкеты.ТипВопроса
	|		WHEN VALUE(Enum.ТипыВопросовШаблонаАнкеты.Простой)
	|			THEN ""simple""
	|		WHEN VALUE(Enum.ТипыВопросовШаблонаАнкеты.ВопросСУсловием)
	|			THEN ""conditional""
	|		WHEN VALUE(Enum.ТипыВопросовШаблонаАнкеты.Комплексный)
	|			THEN ""complex""
	|		WHEN VALUE(Enum.ТипыВопросовШаблонаАнкеты.Табличный)
	|			THEN ""table""
	|		ELSE """"
	|	END AS typeQuestion,
	|	ISNULL(ВопросыШаблонаАнкеты.Формулировка, """") AS title,
	|	CASE ВопросыШаблонаАнкеты.ТипТабличногоВопроса
	|		WHEN VALUE(Enum.ТипыТабличныхВопросов.Составной)
	|			THEN ""simple""
	|		WHEN VALUE(Enum.ТипыТабличныхВопросов.ПредопределенныеОтветыВСтроках)
	|			THEN ""predefinedRows""
	|		WHEN VALUE(Enum.ТипыТабличныхВопросов.ПредопределенныеОтветыВКолонках)
	|			THEN ""predefinedColumns""
	|		WHEN VALUE(Enum.ТипыТабличныхВопросов.ПредопределенныеОтветыВСтрокахИКолонках)
	|			THEN ""predefinedRowsColumns""
	|		ELSE """"
	|	END AS typeTableQuestion,
	|	ВопросыШаблонаАнкеты.Подсказка AS prompt,
	|	ВопросыШаблонаАнкеты.ЭлементарныйВопрос AS ElementaryQuestion,
	|	ВопросыШаблонаАнкеты.РодительВопрос AS Condition,
	|	ВопросыШаблонаАнкеты.СоставТабличногоВопроса.(
	|		ЭлементарныйВопрос AS ЭлементарныйВопрос) AS СоставТабличногоВопроса,
	|	ВопросыШаблонаАнкеты.ПредопределенныеОтветы.(
	|		ЭлементарныйВопрос AS ЭлементарныйВопрос,
	|		Ответ AS Ответ) AS ПредопределенныеОтветы,
	|	ВопросыШаблонаАнкеты.СоставКомплексногоВопроса.(
	|		ЭлементарныйВопрос AS ElementaryQuestion) AS ContentComplexQuestion
	|FROM
	|	Catalog.ВопросыШаблонаАнкеты AS ВопросыШаблонаАнкеты
	|		LEFT JOIN ChartOfCharacteristicTypes.ВопросыДляАнкетирования AS ВопросыДляАнкетирования
	|		ON ВопросыШаблонаАнкеты.ЭлементарныйВопрос = ВопросыДляАнкетирования.Ref
	|WHERE
	|	NOT ВопросыШаблонаАнкеты.DeletionMark
	|	AND ВопросыШаблонаАнкеты.Owner = &ШаблонАнкеты
	|	AND NOT ВопросыШаблонаАнкеты.IsFolder
	|TOTALS
	|BY
	|	ВопросыШаблонаАнкеты.Parent
	|;
	|
	|
	|
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ВариантыОтветовАнкет.Owner AS ElementaryQuestion,
	|	ВариантыОтветовАнкет.Ref AS variant,
	|	ВариантыОтветовАнкет.Presentation AS title,
	|	ВариантыОтветовАнкет.ТребуетОткрытогоОтвета AS needComment,
	|	РеквизитДопУпорядочивания AS order
	|FROM
	|	ЭлементарныеВопросы AS ЭлементарныеВопросы
	|		INNER JOIN Catalog.ВариантыОтветовАнкет AS ВариантыОтветовАнкет
	|		ON (ВариантыОтветовАнкет.Owner = ЭлементарныеВопросы.ЭлементарныйВопрос)
	|WHERE
	|	NOT ВариантыОтветовАнкет.DeletionMark
	|ORDER BY
	|	ВариантыОтветовАнкет.РеквизитДопУпорядочивания
	|;
	|
	|
	|
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ЭлементарныеВопросы.ЭлементарныйВопрос AS ElementaryQuestion,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.Длина, 0) AS length,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.ТребуетсяКомментарий, FALSE) AS needComment,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.ПояснениеКомментария, """") AS сommentExplanation,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.МинимальноеЗначение, 0) AS minValue,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.МаксимальноеЗначение, 0) AS maxValue,
	|	ISNULL(ЭлементарныеВопросы.ЭлементарныйВопрос.Точность, 0) AS precision,
	|	CASE ЭлементарныеВопросы.ЭлементарныйВопрос.ТипОтвета
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.Строка)
	|			THEN ""string""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.Булево)
	|			THEN ""boolean""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.Дата)
	|			THEN ""date""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.Текст)
	|			THEN ""string""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.Число)
	|			THEN ""number""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.ОдинВариантИз)
	|			THEN ""oneOf""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.НесколькоВариантовИз)
	|			THEN ""severalOf""
	|		WHEN VALUE(Enum.ТипыОтветовНаВопрос.ЗначениеИнформационнойБазы)
	|			THEN ""--""
	|		ELSE """"
	|	END AS typeAnswer,
	|	ЭлементарныеВопросы.ЭлементарныйВопрос.ValueType AS ValueType,
	|	ЭлементарныеВопросы.ЭлементарныйВопрос.Формулировка AS title
	|FROM
	|	ЭлементарныеВопросы AS ЭлементарныеВопросы
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ОтветыНаВопросыАнкет.Вопрос AS question,
	|	ОтветыНаВопросыАнкет.ЭлементарныйВопрос AS elementaryQuestion,
	|	ОтветыНаВопросыАнкет.Ответ AS answer,
	|	ОтветыНаВопросыАнкет.ОткрытыйОтвет AS comment,
	|	ОтветыНаВопросыАнкет.НомерЯчейки AS cellNumber
	|FROM
	|	(SELECT
	|		Анкета.Ref AS Ref
	|	FROM
	|		Document.Анкета AS Анкета
	|	WHERE
	|		Анкета.Опрос = &Опрос
	|		AND Анкета.Респондент = &Респондент) AS Data
	|		INNER JOIN Document.Анкета.Состав AS ОтветыНаВопросыАнкет
	|		ON Data.Ref = ОтветыНаВопросыАнкет.Ref
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(&ШаблонАнкеты как catalog.ШаблоныАнкет).Заголовок as title,
	|	CAST(&ШаблонАнкеты как catalog.ШаблоныАнкет).Вступление as intro,
	|	CAST(&ШаблонАнкеты как catalog.ШаблоныАнкет).Заключение as outro");
	Query.SetParameter("ШаблонАнкеты",poll.ШаблонАнкеты);
	Query.SetParameter("Опрос",poll);
	Query.SetParameter("Респондент",user);

	ОписаниеТиповКлуб = Новый описаниетипов("СправочникСсылка.Gyms");
	Query.SetParameter("test",ОписаниеТиповКлуб);

	ResQuery = Query.ExecuteBatch();
	
	РазделыШаблона  = ResQuery[1].Select(QueryResultIteration.ByGroups);
	repository = new Structure("variants,elementaryQuestions,answers,template",
						ResQuery[2].Unload(),
						ResQuery[3].Unload(),
						ResQuery[4].Unload(),
						ResQuery[5].Unload());
	
	If repository.template.Count()=0 Then Return Res EndIf;
	
	While РазделыШаблона.Next() Do
		ArrayQuestion = New Array;
		
		StructSection = New Structure("section", РазделыШаблона.section);
		FillWhisCheck(repository.template[0],StructSection,"title");
		FillWhisCheck(repository.template[0],StructSection,"intro");
		FillWhisCheck(repository.template[0],StructSection,"outro");
		
		ВопросыШаблона = РазделыШаблона.Select();
		While ВопросыШаблона.Next() Do
			StructQuestion = New Structure();
				StructQuestion.Insert("uid", XMLString(ВопросыШаблона.questionRef));
			FillWhisCheck(ВопросыШаблона,StructQuestion,"title");

			
//			type:
//                        type: string
//                        description: тип вопроса
//                        enum:
//                          - oneOf
//                          - severalOf
			
//			StructQuestion = New Structure("typeQuestion,wording");
//			FillPropertyValues(StructQuestion,ВопросыШаблона);
//			
//			FillWhisCheck(ВопросыШаблона,StructQuestion,"typeTableQuestion");
//			FillWhisCheck(ВопросыШаблона,StructQuestion,"prompt");
			
//			If ValueIsFilled(ВопросыШаблона.Condition) Then
//				StructQuestion.Insert("condition", XMLString(ВопросыШаблона.Condition))
//			EndIf;
			
			//FillElementaryQuestion(ВопросыШаблона.ElementaryQuestion,repository,StructQuestion);
			
			FillVariants(ВопросыШаблона,repository,StructQuestion);
			
			//FillContentForComplex(ВопросыШаблона,repository,StructQuestion);

			//пока не реализуем табличные вопросы
			//If ValueIsFilled(ВопросыШаблона.typeTableQuestion) Then
			//	StructQuestion.Insert("typeTableQuestion", ВопросыШаблона.typeTableQuestion);
			//EndIf;
			//If ValueIsFilled(ВопросыШаблона.prompt) Then
			//	StructQuestion.Insert("typeTableQuestion", ВопросыШаблона.typeTableQuestion);
			//EndIf;
			
		
				
			ArrayQuestion.Add(StructQuestion);
		EndDo;
		StructSection.Insert("content", ArrayQuestion);
		Res.Add(StructSection);
	EndDo;
	
	Return Res;

EndFunction

Function pollanswer(struct) Export
	Res = New Structure("result", "no action");
	
	Query = new Query("SELECT TOP 1
	|	Q.Ref AS ref
	|FROM
	|	Document.Анкета AS Q
	|WHERE
	|	NOT Q.DeletionMark
	|	AND Q.Опрос = &poll
	|	AND Q.Респондент = &user
	|;
	|
	|
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ВопросыШаблонаАнкеты.ЭлементарныйВопрос AS ElementaryQuestion,
	|	ВопросыШаблонаАнкеты.ЭлементарныйВопрос.ValueType,
	|	ВопросыШаблонаАнкеты.ЭлементарныйВопрос.ТипОтвета AS TypeAnswer
	|FROM
	|	Catalog.ВопросыШаблонаАнкеты AS ВопросыШаблонаАнкеты
	|WHERE
	|	ВопросыШаблонаАнкеты.Owner = &ШаблонАнкеты
	|	AND &question = ВопросыШаблонаАнкеты.Ref
	|	AND NOT ВопросыШаблонаАнкеты.IsFolder
	|	AND NOT ВопросыШаблонаАнкеты.DeletionMark
	|	AND NOT ВопросыШаблонаАнкеты.ЭлементарныйВопрос = VALUE(ChartOfCharacteristicTypes.ВопросыДляАнкетирования.Emptyref)");
	
	Query.SetParameter("poll",struct.poll);
	Query.SetParameter("ШаблонАнкеты",struct.poll.ШаблонАнкеты);
	Query.SetParameter("user",struct.user);
	Query.SetParameter("question",struct.question);
	resQuery = Query.ExecuteBatch();
	elementaryQuestions = resQuery[1].Unload();
	IF elementaryQuestions.Count()=0 
		Or NOT ValueIsFilled(struct.user)
		Or NOT ValueIsFilled(struct.poll)
		Then
		return Res
	EndIf;
	elementaryQuestionInfo=   elementaryQuestions[0];
	
	CurrentDate = CurrentDate();

	Select = resQuery[0].Select();
	If Select.Next() Then
		obj = Select.ref.GetObject();
		//очистка старых значений
		For Each str in obj.Состав.FindRows(New Structure("Вопрос",struct.question)) Do
			obj.Состав.Delete(str)
		EndDo;	
	Else
		obj = Documents.Анкета.CreateDocument();
		obj.Опрос = Query.Parameters.poll;
		obj.ШаблонАнкеты = Query.Parameters.ШаблонАнкеты;
		obj.Респондент = Query.Parameters.user;
		obj.РежимАнкетирования=Enums.РежимыАнкетирования.Анкета;
		obj.Date = CurrentDate;
	EndIf;
	obj.ДатаРедактирования = CurrentDate;
	If struct.variants.Count()>0 Then
		Cnt = 0;
		For Each answerInfo in struct.variants Do
			AddAnswer( obj.Состав, struct.question, answerInfo, elementaryQuestionInfo, Cnt);
			Cnt=Cnt+1
		EndDo	
//		Else
//			AddAnswer( obj.Состав, struct.question, struct.answer,struct.comment);
	EndIf;
	
	Try 
		obj.Write(DocumentWriteMode.Write);
		Res.result = "OK"
	Except
	//	lErrorInfo = ErrorInfo()
	EndTry;

	
	Return Res

EndFunction

Function pollComplete(struct) Export
	Res = new Structure("result", "no action");
	
	Query = new Query("SELECT TOP 1
		|	Q.Ref AS ref
		|FROM
		|	Document.Анкета AS Q
		|WHERE
		|	NOT Q.DeletionMark
		|	AND Q.Опрос = &poll
		|	AND Q.Респондент = &user");
	
	Query.SetParameter("poll",struct.poll);
	Query.SetParameter("user",struct.user);
	Select = Query.Execute().Select();
	If Select.Next() Then
		obj = Select.ref.GetObject();
		Try 
			obj.Write(DocumentWriteMode.Posting);
			Res.result= "OK"
		Except
		EndTry;
	EndIf;
	
	Return Res

EndFunction

Procedure AddAnswer(Tab, question, answerInfo,elementaryQuestionInfo, Cnt=0)
	comment = answerInfo.comment;
	answer = ?(answerInfo.Property("variant"), answerInfo.variant, answerInfo.answer);
	
	If ValueIsFilled(answer) or ValueIsFilled(comment) Then
		newRow = Tab.Add();
		newRow.Вопрос = question;
		newRow.ЭлементарныйВопрос = newRow.Вопрос.ЭлементарныйВопрос;
		newRow.НомерЯчейки = Cnt;
		newRow.ОткрытыйОтвет = comment;
		newRow.Ответ = Typization(newRow.ЭлементарныйВопрос,answer);
	EndIf	
EndProcedure	

Function Typization(ElementaryQuestion,answer);
	res = answer;
	TypeAnswer = ElementaryQuestion.ТипОтвета;
	TypesAnswer = Enums.ТипыОтветовНаВопрос;
	If TypeAnswer = TypesAnswer.Булево Then
		res = Boolean(answer);
	ElsIf TypeAnswer = TypesAnswer.строка Then
		res = String(answer);
	ElsIf TypeAnswer = TypesAnswer.Текст Then
		res = String(answer);
	ElsIf TypeAnswer = TypesAnswer.Число Then
		res = Number(answer);
	ElsIf TypeAnswer = TypesAnswer.Дата Then
		res = XMLValue(type("Date"),answer)
	ElsIf TypeAnswer = TypesAnswer.ЗначениеИнформационнойБазы Then
		res = Undefined;
		For Each lType In TypesDB() Do
			If ElementaryQuestion.ValueType.ContainsType(lType) Then
				res = XMLValue(lType, answer);
				Break;
			EndIf;
		EndDo; 
	EndIf;
	Return res;
EndFunction	

Function TypesDB() //!!! при добавлении типов доопределить
	Res = New Array;
	Res.Add(Type("CatalogRef.gyms"));
	Res.Add(Type("CatalogRef.products"));
	Res.Add(Type("CatalogRef.employees"));
	
	return Res;
EndFunction

Procedure FillAnswer(elemQuestInfo, repository,StructQuestion,question=Undefined, variantInfo=Undefined)
	ElementaryQuestion =elemQuestInfo.ElementaryQuestion;
	If Not ValueIsFilled(ElementaryQuestion) Then Return EndIf;
	findStruct = New Structure("ElementaryQuestion", ElementaryQuestion);
	isVariant = Not variantInfo=Undefined;
	
	If isVariant Then 
		variant = variantInfo.variant;
		findStruct.Insert("answer", variant)
	EndIf; 
	findStruct.Insert("question", question);
	
	Find = repository.answers.FindRows(findStruct);
	If Find.Count()=0 Then Return EndIf; 
	
	source = Find[0];
	If isVariant Then
		StructQuestion.Insert("isSelected", истина);
		If variantInfo.needComment Then
			FillWhisCheck(source,StructQuestion,"comment");
		EndIf; 
	Else
		StructQuestion.Insert("answer", XMLString(source.answer));
		If elemQuestInfo.needComment Then
			FillWhisCheck(source,StructQuestion,"comment");
		EndIf; 
	EndIf; 

EndProcedure
 
Procedure FillContentForComplex(Select,repository,StructQuestion);
	If Not Select.typeQuestion="complex" Then Return EndIf;
	
	Array = New Array;
	
	Selection = Select.ContentComplexQuestion.Select();
	
	While Selection.Next() Do
		struc = New Structure; 
		FillElementaryQuestion(Selection.ElementaryQuestion,repository,struc,True,True);
		Array.Add(struc);
	EndDo; 
	
	StructQuestion.Insert("questions",Array);
EndProcedure

Procedure FillVariants(Select,repository,StructQuestion)
	ElementaryQuestion = Select.ElementaryQuestion;
	If Not ValueIsFilled(ElementaryQuestion) Then Return EndIf;
	
	Array = New Array;
	
	strucFind = New Structure("ElementaryQuestion", ElementaryQuestion);
	
	elemQuestInfo = repository.elementaryQuestions.FindRows(strucFind)[0];
	
	Find = repository.variants.FindRows(strucFind);
	If Find.Count() = 0 Then 
		StructQuestion.insert("type", "oneOf");
		
		struct = new Structure("needComment",elemQuestInfo.needComment);
		
		If elemQuestInfo.ValueType.ContainsType(Type("CatalogRef.gyms")) Then
			struct.Insert("type","gyms");
		ElsIf elemQuestInfo.ValueType.ContainsType(Type("CatalogRef.products")) Then
			struct.Insert("type","products");
		ElsIf elemQuestInfo.ValueType.ContainsType(Type("CatalogRef.employees")) Then
			struct.Insert("type","employees");
		ElsIf elemQuestInfo.typeAnswer="string"
			or elemQuestInfo.typeAnswer="date"
			or elemQuestInfo.typeAnswer="number"
			or elemQuestInfo.typeAnswer="boolean" Then
			struct.Insert("type",elemQuestInfo.typeAnswer);
			FillWhisCheck(elemQuestInfo,struct,"length");
			If elemQuestInfo.typeAnswer="number" Then
				struct.insert("precision", elemQuestInfo.precision);
			EndIf;
			If ValueIsFilled(elemQuestInfo.maxValue) Then
				struct.insert("minValue", elemQuestInfo.minValue);
				struct.insert("maxValue", elemQuestInfo.maxValue);
			EndIf;
		Else
			typeAnswer="new_type_error"//не смогли определить, видимо, появился новый тип
		EndIf;
		FillAnswer(elemQuestInfo,repository,struct,Select.questionRef);
		Array.Add(struct)
	Else 
		StructQuestion.insert("type", elemQuestInfo.typeAnswer);
		For Each row In Find Do
			struct = new Structure("title,needComment");
			FillPropertyValues(struct,row);
			struct.Insert("uid", XMLString(row.variant));
			struct.Insert("order", row.order);
			
			FillAnswer(elemQuestInfo,repository,struct,Select.questionRef,row);

			Array.Add(struct)
		EndDo; 
	EndIf;
	
	StructQuestion.Insert("answerList", Array);
EndProcedure	

Procedure FillElementaryQuestion(ElementaryQuestion,repository,StructQuestion,FillWording = False,FillKind = False)
	If Not ValueIsFilled(ElementaryQuestion) Then Return EndIf;
	
	Find = repository.ElementaryQuestions.Find(ElementaryQuestion, "ElementaryQuestion");
	If Find=Undefined Then Return EndIf; 
	
	typeAnswer=Find.typeAnswer;
	
	FillWhisCheck(Find,StructQuestion,"needComment");
	FillWhisCheck(Find,StructQuestion,"сommentExplanation");
	
	FillWhisCheck(Find,StructQuestion,"length");
	If typeAnswer="number" Then
		StructQuestion.insert("precision", Find.precision);
	EndIf;
	If ValueIsFilled(Find.maxValue) Then
		StructQuestion.insert("minValue", Find.minValue);
		StructQuestion.insert("maxValue", Find.maxValue);
	EndIf; 
	If FillWording Then
		StructQuestion.insert("wording", Find.Wording)
	EndIf;
	If FillKind Then
		StructQuestion.insert("kindQuestionId", XMLString(Find.ElementaryQuestion))
	EndIf; 
	
	//доопределение типа ответа
	If typeAnswer="--" Then
		If Find.ValueType.ContainsType(Type("CatalogRef.gyms")) Then
			typeAnswer="gyms"	
		ElsIf Find.ValueType.ContainsType(Type("CatalogRef.products")) Then
			typeAnswer="products"
		ElsIf Find.ValueType.ContainsType(Type("CatalogRef.employees")) Then
			typeAnswer="employees"
		Else
			typeAnswer="new_type_error"//не смогли определить, видимо, появился новый тип
		EndIf; 
	EndIf; 
	StructQuestion.insert("typeAnswer", typeAnswer);
	
	If NOT typeAnswer="oneOf" AND  NOT typeAnswer="severalOf" AND  NOT typeAnswer="--" Then
		FillAnswer(ElementaryQuestion,repository,StructQuestion);
	EndIf;
	
	FillVariants(ElementaryQuestion,repository,StructQuestion);
	
EndProcedure	

Procedure FillWhisCheck(source,destination,name)
	Value = source[name];
	If ValueIsFilled(Value) Then
		destination.Insert(name, Value);
	EndIf;
EndProcedure	
