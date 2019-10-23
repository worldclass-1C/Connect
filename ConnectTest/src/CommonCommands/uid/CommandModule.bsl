
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Message(uid(CommandParameter));
EndProcedure

&AtServer
Function uid(object)
	Return XMLString(object);
EndFunction


