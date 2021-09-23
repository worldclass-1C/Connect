
Procedure BeforeWrite(Cancel)	
	photo = ?(photos.Count() > 0, photos[0].URL, "");
EndProcedure
