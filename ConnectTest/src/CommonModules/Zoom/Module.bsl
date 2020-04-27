Function ConnectInfo()
	Return New Structure("URL,APIKey,APISecret,LifeTimeToken",
						"api.zoom.us/v2",
						"2fNSZ0QXStyVCD3VPIhmUA",
						"V0La9g4ICGwhmNFzRNPyrW5Ib7fv7AT2Kom1",
						30);
EndFunction

Function Query(EndPoint="", body=Undefined, metod="POST")
	
	bodyexist = Not body=Undefined;
	ConnectInfo = ConnectInfo();
	JWTToken = JWT.GetToken(ConnectInfo);
	
	isPOST = metod="POST";
	
	// Для авторизации по токену
	Headers = New Map;
	Headers.Insert("authorization", "Bearer " + JWTToken);
	If bodyexist Then
		Headers.Insert("Content-Type",  "application/json");
	EndIf;
	
	// Подключаемся к сайту.
	Connection = New HTTPConnection(
								ConnectInfo.URL,,,,,,New ЗащищенноеСоединениеOpenSSL());
	
	Req = New HTTPRequest(EndPoint, Headers);
	
	If bodyexist Then
		Req.SetBodyFromString(HTTP.encodeJSON(body), TextEncoding.UTF8);
	EndIf;
	
	If isPOST Then
		Res = Connection.Post(Req); 
	ElsIf metod="GET" Then
		Res = Connection.Get(Req);
	ElsIf metod="DELETE" Then
		Res = Connection.Delete(Req);
	ElsIf metod="PATCH" Then
		Res = Connection.Patch(Req);
	EndIf;
	
	Return Res;
	
EndFunction

Procedure integration(parameters) Export
	Var process; 
	struct = New Structure();
	
	requeststruct= parameters.requeststruct;
	If TypeOf(requeststruct) = Type("Structure") And requeststruct.Property("process", process) Then
		If process= "add_acc" Then //создание аккаунта
			//struct=addAccount(requeststruct)
		ElsIf process= "del_acc" Then //удаление аккаунта
			//struct=delAccount(requeststruct)
		ElsIf process= "add_meet" Then //cоздание конференции 
			struct=addMeeting(requeststruct)
		ElsIf process= "upd_meet" Then //изменение параметров конференции
			struct=updMeeting(requeststruct)
		ElsIf process= "del_meet" Then //удаление конференции
			struct=delMeeting(requeststruct)
		EndIf	
	EndIf;
	
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));	
EndProcedure

Procedure addhost(arrAcc, domain) Export
	message = "";
	
	For Each strucAcc In arrAcc Do
		strucZoom = New Structure("action,user_info",
									strucAcc);
		Try
			res = Query("users", strucZoom);
			body = res.GetBodyAsString();
			If res.StatusCode=201 Then
				hostObj = Catalogs.hostsZoom.CreateItem();
				hostObj.email = strucAcc.email;
				hostObj.Description = HTTP.decodeJSON(body).Id;
				hostObj.Write();
			Else
				message = body
			EndIf
		Except
			message =  ErrorDescription();
		EndTry;
	EndDo;
	If Not message="" Then
		message(message)
	EndIf;	
			
EndProcedure

//Function addAccount(parameters) 
//	struct = DefStructRes(); 
//	obj = Catalogs.employees.GetRef(New UUID(parameters.employee)).GetObject();
//	
//	If obj = Undefined Then 
//		struct.message = "Employee not exist";
//	Else	
//		
//		If ValueIsFilled(obj.IDZoom) Then
//			struct.message = "account already exists"
//		Else	
//			strucZoom = New Structure("action,user_info",
//									"autoCreate",
//									New Structure("type,email,first_name,last_name,password",
//														2,
//														StrTemplate("%1@wclass.ru",String(new UUID())),
//														obj.firstName,
//														obj.lastName,
//														StrTemplate("%1%2",Left(String(new UUID()),16),Upper(Left(String(new UUID()),16)))));
//			Try
//				res = Query("users", strucZoom);
//				body = res.GetBodyAsString();
//				If res.StatusCode=201 Then
//					obj.IDZoom = HTTP.decodeJSON(body).Id;
//					obj.Write();
//					struct.result = "OK";
//				Else
//					struct.message = body
//				EndIf
//			Except
//				struct.message =  ErrorDescription();
//			EndTry;
//		EndIf;
//	Endif;
//	Return struct
//EndFunction
//
//Function delAccount(parameters) 
//	struct = DefStructRes(); 
//	obj = Catalogs.employees.GetRef(New UUID(parameters.employee)).GetObject();
//	
//	If obj = Undefined Then 
//		struct.message = "Employee not exist";
//	Else	
//		
//		If Not ValueIsFilled(obj.IDZoom) Then
//			struct.message = "account not exists"
//		Else	
//			strucZoom = New Structure("action",
//									"delete");
//			Try
//				res = Query(StrTemplate("users/%1",obj.IDZoom),strucZoom,"DELETE");
//				body = res.GetBodyAsString();
//				If res.StatusCode=204 Then
//					obj.IDZoom = "";
//					obj.Write();
//					struct.result = "OK";
//				Else
//					struct.message = body
//				EndIf
//			Except
//				struct.message =  ErrorDescription();
//			EndTry;
//		EndIf;
//	Endif;
//	Return struct
//
//EndFunction
//
Function addMeeting(parameters) 
	struct = DefStructRes(); 

	//создаем конференцию
	
	Ref = Catalogs.meetingZoom.GetRef(New UUID(parameters.MeetingZoom));
	meetObj=Ref.GetObject();
	createdNow = False;
	If meetObj=Undefined Then
		meetObj = Catalogs.meetingZoom.CreateItem();
		meetObj.SetNewObjectRef(Ref);
		createdNow=True;
	Else
		meetObj.id="";meetObj.join_url="";meetObj.start_url="";meetObj.password="";
	EndIf;
	FillPropertyValues(meetObj, parameters, "description, password");
	meetObj.doc		 = Catalogs.classesSchedule.GetRef(New UUID(parameters.doc));
	meetObj.startDate = XmlValue(Type("Date"), parameters.startDate);
	meetObj.endDate   = XmlValue(Type("Date"), parameters.endDate);
	meetObj.Write();
	
	IDZoom = getHost(New Structure("meeting,startDate,endDate", meetObj.Ref, meetObj.startDate, meetObj.endDate), struct);
	
	If Not IDZoom=Undefined Then
		StrucMeet = DefMeet(meetObj.Description, meetObj.Description, meetObj.startDate, meetObj.endDate, parameters.password);
		Try
			res = Query(StrTemplate("/users/%1/meetings",IDZoom), StrucMeet);
			body = res.GetBodyAsString();
			If res.StatusCode=201 Then
				meetstruct = HTTP.decodeJSON(body);
				meetObj.ID = Format(meetstruct.id,"ND=15; NFD=0; NG=0");
				FillPropertyValues(meetObj, meetstruct, "start_url,join_url,password");
				meetObj.Write();
				struct.Insert("Id", meetObj.ID);
				struct.Insert("start_url", meetObj.start_url);
				struct.Insert("join_url", meetObj.join_url);
				struct.Insert("password", meetObj.password);
				struct.result = "OK";
			Else
				struct.message = body
			EndIf
		Except
			struct.message =  ErrorDescription();
		EndTry;
	Else	
		struct.message = "no free hosts"
	EndIf;
	
	//очистка предсозданного объекта
	//и возможного распределения хостов
	If createdNow And Not struct.result = "OK" Then
		setHost(New Structure("startDate,endDate,meeting",meetObj.startDate,meetObj.endDate,meetObj.Ref));
		meetObj.Delete();
	EndIf;

	Return struct;
EndFunction

Procedure setHost(parameters, Add=False)
		RecSet = InformationRegisters.busyhostZoom.CreateRecordSet();
		RecSet.Filter.startDate.Set(parameters.startDate);
		RecSet.Filter.endDate.Set(parameters.endDate);
		RecSet.Filter.meeting.Set(parameters.meeting);
		If Add Then
			FillPropertyValues(RecSet.Add(), parameters);
		EndIf;
		RecSet.Write();
EndProcedure

Function updMeeting(parameters) 
	
	struct = DefStructRes(); 
	
	meetObj = Catalogs.meetingZoom.GetRef(New UUID(parameters.MeetingZoom)).GetObject();
	//meeting
	If Not meetObj =Undefined Then
		
		HostNotChanged = False;
		
		startDate = XmlValue(Type("Date"), parameters.startDate);
		endDate   = XmlValue(Type("Date"), parameters.endDate);
		getHost(new Structure("meeting, startDate, endDate", meetObj.Ref, startDate, endDate),
						struct, True, meetObj.startDate, meetObj.endDate, HostNotChanged);
		
		If HostNotChanged Then
	 		meetObj.description		 = parameters.description;
			meetObj.startDate = startDate;
			meetObj.endDate   =endDate;
		
			StrucMeet = DefMeet(meetObj.Description, meetObj.Description, meetObj.startDate, meetObj.endDate);
			StrucMeet.Insert("occurrence_id",meetObj.id);
			Try
				res = Query(StrTemplate("/meetings/%1",EncodeString(meetObj.id, StringEncodingMethod.URLEncoding)), StrucMeet,"PATCH");
				body = res.GetBodyAsString();
				If res.StatusCode=204 or res.StatusCode=200 Then
					meetObj.Write();
					struct.Insert("Id", meetObj.ID);
					struct.result = "OK";
				Else
					struct.message = body
				EndIf
			Except
				struct.message =  ErrorDescription();
			EndTry;
		Else
			//хост изменился, значит нужно создавать под другим хостом
			struct = delMeeting(parameters);
			If struct.result="OK" Then
				struct =addMeeting(parameters)
			EndIf
		EndIf;
	Else
		struct.message = "meeting not found"
	EndIf; 

	Return struct;
EndFunction

Function DefMeet(topic,agenda, startDate, endDate, password=Undefined)
	
	StrucMeet = New Structure;
	StrucMeet.Insert("topic", Left(topic, 199));
	StrucMeet.Insert("agenda", Left(agenda, 1990));
	StrucMeet.Insert("type", 2);
	StrucMeet.Insert("timezone", "UTC");
	StrucMeet.Insert("start_time", startDate);
	StrucMeet.Insert("duration", (endDate-startDate)/60);
	If Not password=Undefined Then
		StrucMeet.Insert("password", password);
	EndIf; 
	
	StrucMeet.Insert("settings", New Structure("watermark,host_video,participant_video,join_before_host",
											True,True,True,True));

	Return StrucMeet

EndFunction // ()

Function delMeeting(parameters) 
	
	struct = DefStructRes(); 
	
	meeting = Catalogs.meetingZoom.GetRef(New UUID(parameters.MeetingZoom));
	meet_id = meeting.id;

	If Not meet_id =Undefined Then
		Try
			res = Query(StrTemplate("/meetings/%1",meet_id), ,"DELETE");
			body = res.GetBodyAsString();
			If res.StatusCode=204 or  res.StatusCode=200 Then
				struct.result = "OK";
				setHost(New Structure("startDate,endDate,meeting",meeting.startDate,meeting.endDate,meeting));
			Else
				struct.message = body
			EndIf
		Except
			struct.message =  ErrorDescription();
		EndTry;
	
	Else
		struct.message = "meeting not found"
	EndIf; 

	Return struct;
EndFunction

Function DefStructRes()
	Return New Structure("result,message", "error", "");
EndFunction

Function getHost(findStruc, struct, replace = False, oldstartDate=Undefined, oldendDate = Undefined, HostNotChanged=False)
	res = Undefined;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	hostsZoom.Ref
		|FROM
		|	Catalog.hostsZoom AS hostsZoom
		|		LEFT JOIN InformationRegister.busyhostZoom AS busyhostZoom
		|		ON busyhostZoom.host = hostsZoom.Ref
		|		AND (busyhostZoom.startDate BETWEEN &startDate AND &endDate
		|		OR &startDate BETWEEN busyhostZoom.startDate AND busyhostZoom.endDate)
		|		AND
		|		NOT busyhostZoom.meeting = &meeting
		|where
		|	busyhostZoom.host IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|select
		|	busyhostZoom.startDate,
		|	busyhostZoom.endDate,
		|	busyhostZoom.meeting,
		|	busyhostZoom.host
		|FROM
		|	InformationRegister.busyhostZoom AS busyhostZoom
		|where
		|	&replace
		|	AND busyhostZoom.startDate = &oldstartDate
		|	AND busyhostZoom.endDate = &oldendDate
		|	AND busyhostZoom.meeting = &meeting";
	
	Query.SetParameter("startDate", findStruc.startDate);
	Query.SetParameter("endDate", findStruc.endDate);
	Query.SetParameter("oldstartDate", oldstartDate);
	Query.SetParameter("oldendDate", oldendDate);
	Query.SetParameter("meeting", findStruc.meeting);
	Query.SetParameter("replace", replace);
	
	resQuery = Query.ExecuteBatch();
	hosts = resQuery[0].Unload().UnloadColumn("Ref");
	
	host = Undefined;
	
	NothingChanged = False;
	
	If replace Then
		selectOld = resQuery[1].Select();
		If selectOld.Next() Then
			//в доступных хостах есть старый - оставлем его
			If Not hosts.Find(selectOld.host) = Undefined Then
				host=selectOld.host;
				HostNotChanged =True
			EndIf;
			If (selectOld.startDate = findStruc.startDate AND selectOld.endDate = findStruc.endDate) and Not host = Undefined Then
				NothingChanged=True //ничего не менялось
			Else //если период изменился - удаляем запись
				setHost(New Structure("startDate,endDate,meeting",selectOld.startDate,selectOld.endDate,selectOld.meeting));
			EndIf
		EndIf
	EndIf;
	
	If host = Undefined AND hosts.Count()>0 Then
		host = hosts[0];
	EndIf;
	
	If Not host = Undefined And Not NothingChanged Then
		findStruc.insert("host", host);
		setHost(findStruc, True);
		res = host.Description
	EndIf;
	
	Return res
EndFunction