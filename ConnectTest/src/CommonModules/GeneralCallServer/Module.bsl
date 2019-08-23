
Function getCaption() Export
	array = New Array();
	array.Add(Metadata.BriefInformation + " (" + Metadata.Version + ")");	
	array.Add(InfoBaseConnectionString());
	Return StrConcat(array, "; ");	
EndFunction

Procedure afterInputCityCode(hhCityCode, city) Export
	If hhCityCode <> Undefined And hhCityCode <> 0 then
		connectStruct = New Structure();
		connectStruct.Insert("server", "api.hh.ru");
		connectStruct.Insert("port", Undefined);
		connectStruct.Insert("account", "");
		connectStruct.Insert("password", "");
		connectStruct.Insert("timeout", 30);
		connectStruct.Insert("secureConnection", True);
		connectStruct.Insert("UseOSAuthentication", False);
		connectStruct.Insert("URL", "metro");
		connectStruct.Insert("requestReceiver", "/" + hhCityCode);
		connectStruct.Insert("HTTPRequestType", Enums.HTTPRequestTypes.GET);
		connectStruct.Insert("parametersFromURL", "");		
		response = Service.runRequest(connectStruct, "");
		statusCode = response.statusCode;		
		If statusCode = 200 Then
			query = New Query("SELECT
			|	metro.Ref,
			|	metro.Code,
			|	metro.Description,
			|	metro.lineColor,
			|	metro.lineName,
			|	metro.lineNumber,
			|	metro.order
			|FROM
			|	Catalog.metro AS metro
			|WHERE
			|	metro.city = &city");
			query.SetParameter("city", city);			
			select = query.Execute().Select();			
			answerStruct = HTTP.decodeJSON(response.GetBodyAsString());
			
			For Each line In answerStruct.lines Do
				For Each station In line.stations Do
					If select.FindNext(New Structure("code", station.id)) Then
						metroObject = select.ref.GetObject();
					Else
						metroObject = Catalogs.metro.CreateItem();
						metroObject.city = city;
						metroObject.code = station.id;	
					EndIf;
					metroObject.lineColor = line.hex_color;
					metroObject.lineName = line.name;
					metroObject.lineNumber = line.id;
					metroObject.description = station.name;
					metroObject.order = station.order;
					metroObject.Write();
					select.Reset();
				EndDo;	
			EndDo; 
			
		EndIf;
	EndIf;
EndProcedure