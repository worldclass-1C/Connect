&AtServerNoContext
Function getResponseBody(log)		
	CompressedBinaryData	= log.request.Get();
	request	= ?(CompressedBinaryData = Undefined, "", XDTOSerializer.XMLValue(Type("ValueStorage"), Base64String(CompressedBinaryData)).Get());	
	CompressedBinaryData	= log.response.Get();
	response	=  ?(CompressedBinaryData = Undefined, "", XDTOSerializer.XMLValue(Type("ValueStorage"), Base64String(CompressedBinaryData)).Get());
	Return New Structure("request, response", request, response);
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If parameters.Property("message") then
		element = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		element.LeftValue = new DataCompositionField("message");
		element.ComparisonType = DataCompositionComparisonType.Equal;
		element.RightValue = parameters.message;
		element.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
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

