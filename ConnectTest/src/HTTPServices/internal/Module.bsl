
Function changeDataPOST(request)
	Return HTTP.processRequest(request);
EndFunction

Function sendMessagePOST(request)
	Return HTTP.processRequest(request, "sendMessage");
EndFunction

Function imagePUT(Request)
	Response = New HTTPServiceResponse(200);
	Return Response;
EndFunction

Function imageDELETE(Request)
	Response = New HTTPServiceResponse(200);
	Return Response;
EndFunction
