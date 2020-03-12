
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Source = CommandExecuteParameters.Source;
	If TypeOf(Source) = Type("ClientApplicationForm") And TypeOf(Source.CurrentItem) = Type("FormTable")
		And Source.CurrentItem.Name = "List" Then
		ServiceClient.findObject(Source.CurrentItem, TypeOf(CommandParameter));
	EndIf;
EndProcedure
