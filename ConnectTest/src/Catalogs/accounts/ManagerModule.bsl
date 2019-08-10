
Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("lastName");
	array.Add("firstName");	
	array.Add("code");	
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation	= "" + data.lastName + " " + data.firstName + " (" + data.code + ")";		
EndProcedure

