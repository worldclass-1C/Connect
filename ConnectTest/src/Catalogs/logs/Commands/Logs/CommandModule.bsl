
&AtClient
Procedure CommandProcessing(commandParameter, commandExecuteParameters)
	If TypeOf(commandParameter) = Type("CatalogRef.tokens") Then
		filterStruct = New Structure("token", commandParameter);
	Else
		filterStruct = New Structure("account", commandParameter);
	EndIf;
	formStruct = New Structure("Filter", filterStruct);
	OpenForm("Catalog.logs.ListForm", formStruct, commandExecuteParameters.Source, commandExecuteParameters.Uniqueness, commandExecuteParameters.Window, commandExecuteParameters.URL);
EndProcedure
