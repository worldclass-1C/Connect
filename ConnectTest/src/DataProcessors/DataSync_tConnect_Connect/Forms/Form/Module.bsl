
&AtServer
Procedure fillErrors()
	query = New Query("SELECT
	|	errorDescriptions.Ref AS Error
	|FROM
	|	Catalog.errorDescriptions AS errorDescriptions");
	
	select = query.Execute().Select();	
	While select.Next() Do
		newRow = Errors.Add();
		newRow.Error = select.Error;
	EndDo;	
EndProcedure

&AtServer
Procedure fillRequest()
	query = New Query("SELECT
	                  |	matchingRequestsInformationSources.Ref AS request
	                  |FROM
	                  |	Catalog.matchingRequestsInformationSources AS matchingRequestsInformationSources");
	
	select = query.Execute().Select();	
	While select.Next() Do
		newRow = requests.Add();
		newRow.request = select.request;
	EndDo;	
EndProcedure

&AtServer
Procedure fillAtServer()
	If Items.GroupPages.CurrentPage = Items.Page1 Then
		fillRequest();		
	ElsIf Items.GroupPages.CurrentPage = Items.Page2 Then
		fillErrors();
	EndIf;
EndProcedure

&AtServer
Procedure unloadAtServer()
	
	requestName = "";
	
	If Items.GroupPages.CurrentPage = Items.Page1 Then
		requestName = "addrequest";
		requestBody	= getRequestBody_Requests(requests.Unload().UnloadColumn("request"));	
	ElsIf Items.GroupPages.CurrentPage = Items.Page2 Then
		requestName = "adderrordescription";
		requestBody	= getRequestBody_Errors(Errors.Unload().UnloadColumn("Error"));
	EndIf;
	
	If requestName <> "" Then
		server = "solutions.worldclass.ru";
		user = "";
		password = "";
		timeout = 30;	
		URL = "API/hs/internal/edit";
		
		headers	= New Map;
		headers.Insert("Content-Type", "application/json");
		headers.Insert("request", requestName);
		headers.Insert("auth-key", "76a5daac-e434-11e9-bba9-005056b11c47");
		headers.Insert("brand", "WorldClass");
		
		HTTPConnection	= New HTTPConnection(server,, user, password,, timeout, New OpenSSLSecureConnection(), False);	
		HTTPRequest = New HTTPRequest(URL, headers);			
		HTTPRequest.SetBodyFromString(requestBody);			
		HTTPResponse = HTTPConnection.Post(HTTPRequest);		
		Message(HTTPResponse.GetBodyAsString());
	Else
		Message("reuest name is empty");
	EndIf;
EndProcedure

&AtServer
Function getRequestBody_Requests(requestList)
	
	array = New Array();	
		
	query = New Query();
	query.text	= "SELECT
	|	matchingRequestsInformationSources.Ref AS Ref,
	|	matchingRequestsInformationSources.Ref.Code AS Code,
	|	matchingRequestsInformationSources.Attribute AS attribute,
	|	matchingRequestsInformationSources.performBackground AS performBackground,
	|	matchingRequestsInformationSources.requestSource AS requestSource,
	|	matchingRequestsInformationSources.requestReceiver AS requestReceiver,
	|	matchingRequestsInformationSources.informationSource AS informationSource,
	|	matchingRequestsInformationSources.notUse AS notUse,
	|	matchingRequestsInformationSources.notSaveAnswer AS notSaveAnswer,
	|	matchingRequestsInformationSources.compressAnswer AS compressAnswer,
	|	matchingRequestsInformationSources.staffOnly AS staffOnly,
	|	matchingRequestsInformationSources.Ref.IsFolder AS IsFolder,
	|	matchingRequestsInformationSources.Ref.Parent AS parent
	|FROM
	|	Catalog.matchingRequestsInformationSources.informationSources AS matchingRequestsInformationSources
	|WHERE
	|	matchingRequestsInformationSources.Ref IN (&requestList)
	|TOTALS
	|	MAX(Code),
	|	MAX(performBackground),
	|	MAX(notSaveAnswer),
	|	MAX(compressAnswer),
	|	MAX(staffOnly)
	|BY
	|	Ref";
	
	query.SetParameter("requestList", requestList);
	select	= query.Execute().Select(QueryResultIteration.ByGroups);	
	
	While select.Next() Do 
		struct = New Structure();
		struct.Insert("uid", XMLString(select.Ref));
		struct.Insert("code", select.Code);
		struct.Insert("IsFolder", select.IsFolder);
		struct.Insert("parent", New Structure("uid", XMLString(select.parent)));
		struct.Insert("performBackground", select.performBackground);
		struct.Insert("notSaveAnswer", select.notSaveAnswer);
		struct.Insert("compressAnswer", select.compressAnswer);
		struct.Insert("staffOnly", select.staffOnly);
		
		selectDetail = select.Select();
		informationSources	= New Array();
		While selectDetail.Next() Do			
			structDetail = New Structure();
			structDetail.Insert("attribute", selectDetail.attribute);		
			structDetail.Insert("performBackground", selectDetail.performBackground);
			structDetail.Insert("requestSource", selectDetail.requestSource);
			structDetail.Insert("requestReceiver", selectDetail.requestReceiver);
			structDetail.Insert("notUse", selectDetail.notUse);
			structDetail.Insert("notSaveAnswer", selectDetail.notSaveAnswer);
			structDetail.Insert("compressAnswer", selectDetail.compressAnswer);
			structDetail.Insert("staffOnly", selectDetail.staffOnly);
			
			informationSourceStruct	= New Structure();
			informationSourceStruct.Insert("uid", XMLString(selectDetail.informationSource));
			structDetail.Insert("informationSource", informationSourceStruct);
			
			informationSources.add(structDetail);
		EndDo;
		
		struct.Insert("informationSources", informationSources);
		
		array.add(struct);
	EndDo;		
	Message(HTTP.encodeJSON(array));	
	Return HTTP.encodeJSON(array);  
	
EndFunction 

&AtServer
Function getRequestBody_Errors(errorsList)
	
	arrayJSON		= New Array();	
	recordJSON		= New JSONWriter();
	recordJSON.УстановитьСтроку(); 		
		
	query	= New Query();
	query.Text	= "SELECT
	          	  |	errorDescriptions.Ref AS Ref,
	          	  |	errorDescriptions.Code AS Code,
	          	  |	errorDescriptions.Parent AS Parent,
	          	  |	errorDescriptions.translation.(
	          	  |		language.Code AS language,
	          	  |		description AS description
	          	  |	) AS translation,
	          	  |	errorDescriptions.IsFolder AS IsFolder
	          	  |FROM
	          	  |	Catalog.errorDescriptions AS errorDescriptions
	          	  |WHERE
	          	  |	errorDescriptions.Ref IN(&errorsList)";
	
	query.SetParameter("errorsList", errorsList);
	select	= query.Execute().Select(QueryResultIteration.ByGroups);	
	
	While select.Next() Do
		requestStruct	= New Structure();
		requestStruct.Insert("uid", XMLString(select.Ref));
		requestStruct.Insert("isfolder", select.IsFolder);
		requestStruct.Insert("code", XMLString(select.code));				
		requestStruct.Insert("parent", New Structure("uid", XMLString(select.Parent)));
		
		arrayInfoSource	= New Array;
		detail = select.translation.Unload();
		For Each record In detail Do
			infoSource	= New Structure();
			infoSource.Insert("language", New Structure("code", record.language));
			infoSource.Insert("description", record.description);			
			arrayInfoSource.add(infoSource);			
		EndDo;
		requestStruct.Insert("translation", arrayInfoSource);
		
		arrayJSON.add(requestStruct);
	EndDo;		
	
	WriteJSON(recordJSON, arrayJSON);
	
	Return recordJSON.Закрыть();
	
EndFunction 

&AtClient
Procedure fill(Command)
	fillAtServer();
EndProcedure

&AtClient
Procedure unload(Command)
	unloadAtServer();	
EndProcedure
