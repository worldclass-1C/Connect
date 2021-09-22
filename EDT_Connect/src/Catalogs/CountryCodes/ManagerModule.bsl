
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	array = New Array();
	array.add("CountryCode");
	array.add("Description");
	Fields = array;
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	Presentation	= Data.CountryCode + " " + Data.Description;
EndProcedure



