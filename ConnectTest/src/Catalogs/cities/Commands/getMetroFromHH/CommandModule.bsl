
&AtClient
Procedure commandProcessing(CommandParameter, CommandExecuteParameters)	
	notify = New NotifyDescription("afterInputCityCode", GeneralCallServer, CommandParameter);
	ShowInputValue(notify, 0, NStr("ru = 'Введтие код города!'; en = 'Enter city code!'"), type("String"));	
EndProcedure
