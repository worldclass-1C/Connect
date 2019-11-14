
Procedure BeforeWrite(Cancel)	
	photo = ?(photos.Count() > 0, photos[0].URL, GeneralReuse.getBaseImgURL() + "/service/clubs.jpg");	
	departments = HTTP.decodeJSON(departmentWorkSchedule, Enums.JSONValueTypes.array); 
	If departments.Count() > 0 Then
		departments[0].Property("phone", phone);
		departments[0].Property("weekdaysTime", weekdaysTime);
		departments[0].Property("holidaysTime", holidaysTime);	
	Else
		phone = "";
		weekdaysTime = "";
		holidaysTime = "";
	EndIf; 
EndProcedure
