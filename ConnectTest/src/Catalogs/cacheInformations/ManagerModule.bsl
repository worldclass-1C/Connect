Procedure PresentationFieldsGetProcessing(fields, standardProcessing)
	standardProcessing = False;
	array = New Array();
	array.Add("cacheType");
	array.Add("user");	
	array.Add("startRotation");
	array.Add("endRotation");
	fields = array;
EndProcedure

Procedure PresentationGetProcessing(data, presentation, standardProcessing)
	standardProcessing = False;
	presentation = "" + data.cacheType + " / " + data.user + " / "
		+ Format(data.startRotation, "DF='dd.MM.yyyy'") + " - " + Format(data.endRotation, "DF='dd.MM.yyyy'");
EndProcedure