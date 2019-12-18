
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
Procedure fillSegments()
	query = New Query("SELECT
		|	segments.Ref AS segment
		|FROM
		|	Catalog.segments AS segments");
	select = query.Execute().Select();
	While select.Next() Do
		newRow = segments.Add();
		newRow.segment = select.segment;
	EndDo;
EndProcedure

&AtServer
Procedure fillAtServer()
	If Items.GroupPages.CurrentPage = Items.Page1 Then
		fillRequest();
	ElsIf Items.GroupPages.CurrentPage = Items.Page2 Then
		fillErrors();
	ElsIf Items.GroupPages.CurrentPage = Items.Page3 Then
		fillSegments();
	EndIf;
EndProcedure

&AtServer
Procedure unloadAtServer()

	If Items.GroupPages.CurrentPage = Items.Page1 Then
		list = requests.Unload().UnloadColumn("request");
	ElsIf Items.GroupPages.CurrentPage = Items.Page2 Then
		list = Errors.Unload().UnloadColumn("Error");
	ElsIf Items.GroupPages.CurrentPage = Items.Page3 Then
		list = segments.Unload().UnloadColumn("segment");
	EndIf;

	requestBody = getRequestBody(list);

	server = "solutions.worldclass.ru";
	user = "";
	password = "";
	timeout = 30;
	URL = "API/hs/internal/synch";

	headers = New Map;
	headers.Insert("Content-Type", "application/json");
	headers.Insert("request", "synchronization");
	headers.Insert("auth-key", "76a5daac-e434-11e9-bba9-005056b11c47");
	headers.Insert("brand", "WorldClass");

	HTTPConnection = New HTTPConnection(server, , user, password, , timeout, New OpenSSLSecureConnection(), False);
	HTTPRequest = New HTTPRequest(URL, headers);
	HTTPRequest.SetBodyFromString(requestBody);
	HTTPResponse = HTTPConnection.Post(HTTPRequest);
	Message(HTTPResponse.GetBodyAsString());

EndProcedure

&AtServer
Function getRequestBody(list)
	array = New Array();
	For Each element In list Do
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		array.Add(element.GetObject());
	EndDo;
	XDTOSerializer.WriteJSON(JSONWriter, array, XMLTypeAssignment.Explicit);
	Return JSONWriter.Close();
EndFunction

&AtClient
Procedure fill(Command)
	fillAtServer();
EndProcedure

&AtClient
Procedure unload(Command)
	unloadAtServer();
EndProcedure
