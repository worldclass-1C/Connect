
&AtClient
Procedure CommandProcessing(commandParameter, commandExecuteParameters)
	filterStruct = New Structure();
	If TypeOf(commandParameter) = Type("CatalogRef.tokens") Then
		filterStruct = New Structure("token", commandParameter);
	ElsIf TypeOf(commandParameter) = Type("CatalogRef.users") Then
		filterStruct = New Structure("user", commandParameter);
	EndIf;
	formStruct = New Structure("Filter", filterStruct);
	OpenForm("Catalog.logs.ListForm", formStruct, commandExecuteParameters.Source, commandExecuteParameters.Uniqueness, commandExecuteParameters.Window, commandExecuteParameters.URL);
EndProcedure
