
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	filterStruct = New Structure("user", commandParameter);
	formStruct = New Structure("Filter", filterStruct);
	OpenForm("Catalog.messages.ListForm", formStruct, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
