
Function megalabPOST(Request)
		Return SmsMegalab.checkSmsStatus(Request);
EndFunction

Function iDigital(Request)
	
	MethodName = Request.URLParameters["MethodName"];

	If MethodName = "ping" Then
		Response = New HTTPServiceResponse(200);
	ElsIf MethodName = "states" Then
		Return SmsIDigital.checkSmsStatus(Request);
	Else
		Response = New HTTPServiceResponse(404);
		Response.SetBodyFromString("Неизвестное имя метода");
	Endif;

	Return Response;
	
EndFunction
