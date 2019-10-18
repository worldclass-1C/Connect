
Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("description");
	array.Add("holding");
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation	= "" + data.description + " (" + data.holding + ")";		
EndProcedure