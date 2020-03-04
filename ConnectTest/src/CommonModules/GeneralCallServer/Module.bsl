
Function getCaption() Export
	array = New Array();
	array.Add(Metadata.BriefInformation + " (" + Metadata.Version + ")");	
	array.Add(InfoBaseConnectionString());
	Return StrConcat(array, "; ");	
EndFunction

Function getRef(ref) Export	
	Return Service.getRef(ref);		
EndFunction