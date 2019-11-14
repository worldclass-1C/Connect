
Procedure BeforeWrite(Cancel)
	If photos.Count() > 0 Then
		photo = photos[0].URL;	
	ElsIf gender = "female" Then
		photo = GeneralReuse.getBaseImgURL() + "/service/trainer female.jpg"
	Else
		photo = GeneralReuse.getBaseImgURL() + "/service/trainer male.jpg"	 
	EndIf;
EndProcedure
