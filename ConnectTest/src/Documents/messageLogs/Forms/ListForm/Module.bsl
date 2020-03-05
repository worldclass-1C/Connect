

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If parameters.Property("message") then
		element = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		element.LeftValue = new DataCompositionField("message");
		element.ComparisonType = DataCompositionComparisonType.Equal;
		element.RightValue = parameters.message;
		element.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
EndProcedure
