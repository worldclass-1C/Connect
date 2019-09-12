
&AtServer
Procedure OnReadAtServer(CurrentObject)
	docHTML = HTML.getPhoto(Object.Ref);
EndProcedure

&AtServer
Function putFileAtServer(address, selectedFileName) Export
	gymObject = FormAttributeToValue("Object");
	transferredFile = New File(selectedFileName);
	pathStruct = Files.getPath(gymObject);
	fileName = Files.pathConcat("" + New UUID(), transferredFile.Extension);
	BinaryData = GetFromTempStorage(address);
	BinaryData.write(Files.pathConcat(pathStruct.location, fileName, "\"));
	newRow = gymObject.fhoto.add();
	newRow.location = Files.pathConcat(pathStruct.location, fileName, "\");
	newRow.URL = Files.pathConcat(pathStruct.URL, fileName, "/");
	gymObject.Write();
	ValueToFormAttribute(gymObject, "Object");
	docHTML = HTML.getPhoto(Object.Ref);
	Return "";	
EndFunction

&AtClient
Procedure docHTMLOnClick(Item, EventData, StandardProcessing)	
	If EventData.Property("Anchor")
			And EventData.Anchor.id <> Undefined 
			And EventData.Anchor.id <> "" Then
		If EventData.Anchor.id = "addPhoto" Then
			StandardProcessing = False;			
			ExecuteAction("addFile");
		EndIf;
	EndIf;	
EndProcedure

&AtClient
Procedure executeAction(action)	
	BeginAttachingFileSystemExtension(New NotifyDescription("attachingFileSystemExtension", ThisForm, action));
EndProcedure

&AtClient
Procedure attachingFileSystemExtension(connected, additionalParameters) Export
	If connected Then
		executeActionWithFile(AdditionalParameters);
	Else		
		BeginInstallFileSystemExtension(New NotifyDescription("installFileSystemExtension", ThisForm, additionalParameters));
	EndIf;	
EndProcedure

&AtClient
Procedure executeActionWithFile(additionalParameters)
	If additionalParameters = "addFile" Then		
		address = "";
		BeginPutFile(New NotifyDescription("putFileAtClient", ThisForm), address, "", True);		
	EndIf;
EndProcedure

&AtClient
Procedure putFileAtClient(result, address, selectedFileName, additionalParameters) Export	
	If result Then
		putFileAtServer(address, selectedFileName);		
	EndIf;	
EndProcedure
