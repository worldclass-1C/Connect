
Function getCaption() Export
	array = New Array();
	array.Add(Metadata.BriefInformation + " (" + Metadata.Version + ")");	
	array.Add(InfoBaseConnectionString());
	Return StrConcat(array, "; ");	
EndFunction

Function getRef(uid, typeOfObject) Export	
	Return Service.getRef(uid, typeOfObject);		
EndFunction

Procedure executeRequestMethod(requestParameters) Export
	General.executeRequestMethod(requestParameters);
EndProcedure