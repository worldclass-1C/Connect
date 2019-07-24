
Function getCaption() Export
	array = New Array();
	array.Add(Metadata.BriefInformation + " (" + Metadata.Version + ")");	
	array.Add(InfoBaseConnectionString());
	Return StrConcat(array, "; ");	
EndFunction