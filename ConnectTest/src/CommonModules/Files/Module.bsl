
Procedure createHoldingDirectory(holdingCode) Export	
	holdingPath = getHoldingPath(holdingCode);
	holdingDirectory = New File(holdingPath);	
	If Not holdingDirectory.Exist() Then
		CreateDirectory(holdingPath);
		CreateDirectory(holdingPath + "\gyms");
		CreateDirectory(holdingPath + "\services");
		CreateDirectory(holdingPath + "\users");			
	EndIf;	
EndProcedure

Function pathConcat(path1, path2, separator = "") Export
	pathArray = New Array();
	pathArray.Add(path1);
	pathArray.Add(path2);
	Return StrConcat(pathArray, separator);
EndFunction

Function getImgStoragePath()
	Return Constants.ImgStorage.Get();
EndFunction

Function getBaseImgURL()
	Return Constants.BaseImgURL.Get();
EndFunction

Function getHoldingPath(holdingCode, url = False)
	Return pathConcat(?(url, getBaseImgURL(), getImgStoragePath()), holdingCode, ?(url, "/", "\"));
EndFunction

Function getPath(object) Export	
	objectMetadata = object.Metadata();
	If objectMetadata.Attributes.Find("holding") = Undefined Then
		Return New Structure("location, URL", getImgStoragePath() + "\service", getBaseImgURL() + "/service");	
	Else
		holdingPath = getHoldingPath(object.holding.code);
		holdingURL = getHoldingPath(object.holding.code, True);
		metadataName = objectMetadata.Name;		
		Return New Structure("location, URL", pathConcat(holdingPath, metadataName, "\"), pathConcat(holdingURL, metadataName, "/"));		
	EndIf;	
EndFunction

