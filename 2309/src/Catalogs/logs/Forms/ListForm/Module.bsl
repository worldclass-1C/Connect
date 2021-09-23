
&AtServerNoContext
Function getResponseBody(log)		
	CompressedBinaryData	= log.request.Get();
	request	= ?(CompressedBinaryData = Undefined, "", XDTOSerializer.XMLValue(Type("ValueStorage"), Base64String(CompressedBinaryData)).Get());	
	CompressedBinaryData	= log.response.Get();
	response	=  ?(CompressedBinaryData = Undefined, "", XDTOSerializer.XMLValue(Type("ValueStorage"), Base64String(CompressedBinaryData)).Get());
	Return New Structure("request, response", request, response);
EndFunction

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	StandardProcessing	= False;
	CurrentData	= Items.List.CurrentData;
	If CurrentData <> Undefined Then
		formParameters	= New Structure("key", CurrentData.token);
		OpenForm("Catalog.tokens.ObjectForm", formParameters, ThisForm,,,,, FormWindowOpeningMode.Independent);
	EndIf;	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	CurrentRow	= Items.List.CurrentRow;
	If CurrentRow <> Undefined Then
		answer		= getResponseBody(CurrentRow);
		request		= answer.request;
		response	= answer.response;
	EndIf;
EndProcedure

