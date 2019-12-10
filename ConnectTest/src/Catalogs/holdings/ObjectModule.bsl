
Procedure OnWrite(Cancel)
	Files.createHoldingDirectory(Code);
EndProcedure

Procedure OnCopy(CopiedObject)
	tokenDefault	= Catalogs.tokens.EmptyRef();
EndProcedure

