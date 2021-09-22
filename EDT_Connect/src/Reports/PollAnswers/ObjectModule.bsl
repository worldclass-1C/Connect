
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	parPoll = new DataCompositionParameter("Poll");
	For Each usrSet in ThisObject.SettingsComposer.UserSettings.Items Do
		If usrSet.Parameter = parPoll Then
			Poll = usrSet.Value;
			Break;
		EndIf; 
	EndDo; 
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ВопросыШаблонаАнкеты.Ref AS Ref,
		|	ВопросыШаблонаАнкеты.Code AS Code,
		|	ВопросыШаблонаАнкеты.Формулировка AS text
		|FROM
		|	Catalog.ВопросыШаблонаАнкеты AS ВопросыШаблонаАнкеты
		|WHERE
		|	ВопросыШаблонаАнкеты.Owner = &Poll
		|	AND NOT ВопросыШаблонаАнкеты.IsFolder";
	
	Query.SetParameter("Poll", Poll);
	
	Selection = Query.Execute().Select();
	
	t1 = "";t2 = "";t3 = ""; counter=0;
	Query1 = New Query;
	Query1.Parameters.Insert("Poll",Poll);

	While Selection.Next() Do
		counter= counter+1;
		
		AddText(t1, StrTemplate("""%1"" AS Anser%2",Selection.text,Selection.Code), ",");
		AddText(t2, StrTemplate("q%1.Ответ",counter), ",");
		
		AddText(t3, StrTemplate("LEFT JOIN Data AS q%1
		|		ON d.Анкета = q%1.Анкета
		|			AND (q%1.Вопрос = &question%1)" ,counter));
		Query1.Parameters.Insert("question"+counter,Selection.Ref);

	EndDo;

	Query1.Text = StrTemplate(
		"SELECT
		|	ОтветыНаВопросыАнкет.Анкета AS Анкета,
		|	ОтветыНаВопросыАнкет.Вопрос AS Вопрос,
		|	ОтветыНаВопросыАнкет.ЭлементарныйВопрос AS ЭлементарныйВопрос,
		|	ОтветыНаВопросыАнкет.Ответ AS Ответ,
		|	ОтветыНаВопросыАнкет.Анкета.Респондент AS Респондент
		|INTO Data
		|FROM
		|	InformationRegister.ОтветыНаВопросыАнкет AS ОтветыНаВопросыАнкет
		|WHERE
		|	ОтветыНаВопросыАнкет.Анкета.ШаблонАнкеты = &Poll
		|
		|INDEX BY
		|	Анкета,
		|	Вопрос
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	""userCode"" AS userCode,
		|	""userType"" AS userType,
		|	""userGender"" AS userGender,
		|	""userBirthday"" AS userBirthday
		|	%1
		|UNION ALL
		|
		|SELECT
		|	d.Респондент.userCode,
		|	d.Респондент.userType,
		|	d.Респондент.Owner.gender,
		|	d.Респондент.Owner.birthday
		|	%2
		|FROM
		|	(SELECT DISTINCT
		|		Data.Анкета AS Анкета,
		|		Data.Респондент AS Респондент
		|	FROM
		|		Data AS Data) AS d
		|		%3",t1,t2,t3);
	
	ResultDocument.Очистить();
	ReportBuilder = New ReportBuilder;
	ReportBuilder.DataSource=New DataSourceDescription( Query1.Execute().Unload());
	ReportBuilder.PutReportHeader = Ложь;
	ReportBuilder.PutTableHeader = Ложь;
	ReportBuilder.Put(ResultDocument);
	
	ResultDocument.FixedTop = 1;
	Ar = ResultDocument.Area(1,2,1,5+counter);
	Ar.ColumnWidth=15;
	Ar.Font=New Font(Ar.Font,,,True);

EndProcedure

Procedure AddText(text, addText, prefix="")
	text = StrTemplate("%1%2
	|%3",text,prefix,addText)
EndProcedure