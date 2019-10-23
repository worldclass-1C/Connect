
&AtClient
Procedure findToken(Command)
	notify = New NotifyDescription("afterInputToken", ThisObject);
	ShowInputValue(notify, "", NStr("ru = 'Введтие токен!'; en = 'Enter token!'"), type("String"));
EndProcedure

&AtClient
Procedure afterInputToken(ref, city) Export
	If ref <> Undefined And ref <> "" then
		ShowValue(, getRef(ref));
	EndIf;	
EndProcedure

&AtServer
Function getRef(ref)	
	Return XMLValue(Type("CatalogRef.tokens"), ref);		
EndFunction