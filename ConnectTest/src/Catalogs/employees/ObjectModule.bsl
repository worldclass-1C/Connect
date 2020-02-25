
Procedure BeforeWrite(Cancel)
	If photos.Count() > 0 Then
		photo = photos[0].URL;	
	ElsIf gender = "female" Then
		photo = GeneralReuse.getBaseImgURL() + "/service/trainerfemale.jpg";
	Else
		photo = GeneralReuse.getBaseImgURL() + "/service/trainermale.jpg";	 
	EndIf;
EndProcedure
