
&AtClient
Procedure CommandProcessing(commandParameter, commandExecuteParameters)
	formStruct = New Structure("Filter", New Structure("order", commandParameter));
	OpenForm("Catalog.acquiringLogs.ListForm", formStruct, commandExecuteParameters.Source, commandExecuteParameters.Uniqueness, commandExecuteParameters.Window, commandExecuteParameters.URL);
EndProcedure
