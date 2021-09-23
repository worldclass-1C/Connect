Procedure  BeforeWrite(Cancel,Replacing)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	T.Holding as holding,
		|	T.app as app
		|INto Tabl
		|from
		|	&Dat T
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|select
		|	COUNT(DISTINCT D.holding) AS holding,
		|	D.app AS app
		|FROM
		|	(select
		|		Holding as holding,
		|		app as app
		|	from
		|		Tabl
		|
		|	union all
		|
		|	SELECT
		|		M.Holding as holding,
		|		M.app as app
		|	FROM
		|		Tabl as t
		|			inner JOIN InformationRegister.matchingAppZoom AS M
		|			ON M.app = t.app) as D
		|GROUP BY
		|	D.app
		|having
		|	COUNT(DISTINCT D.holding) > 1";
	
	Query.SetParameter("Dat", ThisObject.Unload());
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Cancel = True;
		Message("Различные сопоставления для одного приложения не разрешены");
	EndIf;
	
	
EndProcedure