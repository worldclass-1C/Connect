&AtClient
Procedure OnChange(Item)
	OnChangeAtServer()
EndProcedure

&AtServer
Procedure OnChangeAtServer()
	Tab.Clear();
	For cht=1 to Count Do
		email = StrTemplate("%1%2@%3",Prefix,cht,Postfix);
		If Not ValueIsFilled(Catalogs.hostsZoom.FindByAttribute("email", email)) Then
			Tab.Add().email =email ;
		EndIf;	
	EndDo
EndProcedure

&AtClient
Procedure Create(Command)
	CreateAtServer();
EndProcedure

&AtServer
Procedure CreateAtServer()
	If ValueIsFilled(Application) Then
		arr =New Array();
		
		For Each str In Tab Do
				arr.Add(New Structure("type,email,first_name,last_name",
											2,
											str.email,
											"World",
											"Class"));		
		EndDo;
		
		ConnectInfo = New Structure("URL,APIKey,APISecret,LifeTimeToken",
							Application.APIURL,
							Application.APIKey,
							Application.APISecret,
							Application.LifeTimeToken);
		FillPropertyValues(ConnectInfo, Application);
		If arr.Count()>0 then
			Zoom.addhost(arr, ConnectInfo,Application);
		EndIf
	EndIf
EndProcedure

