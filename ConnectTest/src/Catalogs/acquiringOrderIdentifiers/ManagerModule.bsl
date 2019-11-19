
Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("ref");		
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation	= XMLString(data.ref);		
EndProcedure