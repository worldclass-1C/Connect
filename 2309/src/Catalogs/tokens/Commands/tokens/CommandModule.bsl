
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)	
	filterStruct = New Structure();
	If TypeOf(commandParameter) = Type("CatalogRef.accounts") Then
		filterStruct = New Structure("account", commandParameter);
	ElsIf TypeOf(commandParameter) = Type("CatalogRef.users") Then
		filterStruct = New Structure("user", commandParameter);
	EndIf;
	formStruct = New Structure("Filter", filterStruct);
	OpenForm("Catalog.tokens.ListForm", formStruct, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
EndProcedure
