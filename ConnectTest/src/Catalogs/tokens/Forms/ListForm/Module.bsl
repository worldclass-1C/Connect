
&AtClient
Procedure findToken(Command)
	notify = New NotifyDescription("afterInputCityCode", ThisObject);
	ShowInputValue(notify, "", NStr("ru = 'Введтие токен!'; en = 'Enter token!'"), type("String"));
EndProcedure

&AtClient
Procedure afterInputCityCode(ref, city) Export
	If ref <> Undefined And ref <> "" then
		ShowValue(, getRef(ref));
	EndIf;	
EndProcedure

&AtServer
Function getRef(ref)	
	Return XMLValue(Type("CatalogRef.tokens"), ref);		
EndFunction