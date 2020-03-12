
Procedure findObject(list, typeOfObject) Export
	notify = New NotifyDescription("afterInputToken", ServiceClient, New Structure("list, typeOfObject", list, typeOfObject));
	ShowInputValue(notify, "", NStr("ru = 'Введтие токен!'; en = 'Enter token!'"), type("String"));
EndProcedure

Procedure afterInputToken(uid, addParameters) Export
	If uid <> Undefined And uid <> "" then		
		addParameters.list.CurrentRow = GeneralCallServer.getRef(uid, addParameters.typeOfObject);		
	EndIf;	
EndProcedure