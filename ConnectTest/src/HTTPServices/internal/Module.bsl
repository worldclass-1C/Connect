
Function changeDataPOST(request)
	Return HTTP.processRequest(request);
EndFunction

Function sendMessagePOST(request)
	Return HTTP.processRequest(request, "sendMessage");
EndFunction