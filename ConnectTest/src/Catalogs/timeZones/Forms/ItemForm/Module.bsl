
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Description.ChoiceList.LoadValues(GetAvailableTimeZones());
EndProcedure
