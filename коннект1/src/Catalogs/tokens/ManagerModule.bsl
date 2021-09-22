
Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;	
	array = New Array();	
	array.Add("appType");
	array.Add("systemType");
	array.Add("createDate");		
	fields = array;	
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation = "" + data.appType + " / " + data.systemType + " / " + Format(data.createDate, "DF='dd.MM.yyyy HH:mm'");
EndProcedure