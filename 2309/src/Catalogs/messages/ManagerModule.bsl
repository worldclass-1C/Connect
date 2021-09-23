
Procedure PresentationFieldsGetProcessing(fields, standardProcessing)	
	standardProcessing = False;
	array = New Array();
	array.Add("registrationDate");
	fields = array;
EndProcedure

Procedure PresentationGetProcessing(date, presentation, standardProcessing)	
	standardProcessing = False;
	presentation	= "" + date.registrationDate;
EndProcedure

