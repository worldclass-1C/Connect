
Function changeDataPOST(request)
	Return HTTP.processRequest(request);
EndFunction

Function sendMessagePOST(request)
	Return HTTP.processRequest(request, "sendMessage");
EndFunction

Function imagePOST(Request)
	Return HTTP.processRequest(request, "imagePOST");
EndFunction

Function imageDELETE(Request)
	Return HTTP.processRequest(request, "imageDELETE");
EndFunction

Function synchMethod(Request)
	Return HTTP.processRequest(request,, True);
EndFunction

Function filePOST(Request)
	Return HTTP.processRequest(request, "filePOST");
EndFunction

Function fileDELETE(Request)
	Return HTTP.processRequest(request, "fileDELETE");
EndFunction

Function ProcessRequestPOST(Request)
	Return HTTP.processRequest(Request);
EndFunction
