Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("description");
	array.Add("brand");	
	array.Add("holding");	
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation	= "" + data.description + " / " + data.brand + " / " + data.holding;		
EndProcedure