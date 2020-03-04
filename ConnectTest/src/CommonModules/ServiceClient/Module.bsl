
Procedure findObject(items) Export
	notify = New NotifyDescription("afterInputToken", ServiceClient, items);
	ShowInputValue(notify, "", NStr("ru = 'Введтие токен!'; en = 'Enter token!'"), type("String"));
EndProcedure

Procedure afterInputToken(ref, items) Export
	If ref <> Undefined And ref <> "" then		
		items.List.CurrentRow = GeneralCallServer.getRef(ref);		
	EndIf;	
EndProcedure