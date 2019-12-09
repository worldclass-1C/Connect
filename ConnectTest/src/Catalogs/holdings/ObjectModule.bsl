
Procedure BeforeWrite(Cancel)
	If TrimAll(tokenDefault) = "" Then
		tokenDefault = New UUID();
	EndIf;
EndProcedure

Procedure OnWrite(Cancel)
	Files.createHoldingDirectory(Code);
EndProcedure

Procedure OnCopy(CopiedObject)
	tokenDefault	= "";
EndProcedure

