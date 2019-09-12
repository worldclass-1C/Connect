
Procedure BeforeWrite(Cancel)
	If TrimAll(token) = "" Then
		token	= New UUID();
	EndIf;
EndProcedure

Procedure OnWrite(Cancel)
	Files.createHoldingDirectory(Code);
EndProcedure

Procedure OnCopy(CopiedObject)
	token	= "";
EndProcedure

