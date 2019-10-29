
&AtClient
Procedure ListOnActivateRow(Item)
	ListOnActivateRowAtServer();
EndProcedure

&AtServer
Procedure ListOnActivateRowAtServer()
	currentRow = Items.List.CurrentRow;
	If currentRow <> Undefined Then 
		docHTML = HTML.getPhoto(currentRow.photo, type("CatalogRef.employees"));
	EndIf;
EndProcedure
