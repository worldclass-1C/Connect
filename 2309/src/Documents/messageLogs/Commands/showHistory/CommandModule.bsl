
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//TODO: Paste handler content.
	FormParameters = New Structure("message", CommandParameter);
	OpenForm("Document.messageLogs.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
