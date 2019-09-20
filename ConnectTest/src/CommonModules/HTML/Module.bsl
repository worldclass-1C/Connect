
Function getPhoto(gym) Export
	
	strArray = New Array();
	
	head = "<html>
		|<head>
		|<style>
		|.square{
		|			width: 300px;
		|			height: 300px;
		|			object-fit: contain;
		|		}
		|
		|a{ 
		|			float: left;						
		|			margin: 1.5% 0 0 1.5%;
		|			background: #f0f0f0;						
		|			padding: 0.5%;
		|		}
		|</style>
		|</head>
		|<body>";
		
	down = "</body></html>";
	
	query = New Query("SELECT
	|	gymsfoto.URL,
	|	gymsfoto.LineNumber
	|FROM
	|	Catalog.gyms.fhoto AS gymsfoto
	|WHERE
	|	gymsfoto.Ref = &gym");
	
	query.SetParameter("gym", gym);
	
	select = query.Execute().Select();
	bodyArray = New Array();
	
	While select.Next() Do
		bodyArray.Add("<a href = ""#"" id = """ + select.LineNumber + """>");
		bodyArray.Add("<img class=""square"" src=""" + select.url + """ alt=""fhoto"">");
		bodyArray.Add("</a>");
	EndDo;
	
	bodyArray.Add("<a href = ""#"" id = ""addPhoto"">");
	bodyArray.Add("<img class=""square"" src=""https://tsolutions.worldclass.ru/img/service/addPhoto.jpg"" alt=""fhoto"">");
	bodyArray.Add("</a>");
		
	strArray.Add(head);
	strArray.Add(StrConcat(bodyArray, Chars.LF));
	strArray.Add(down);	
	
	Return StrConcat(strArray, Chars.LF);
	
EndFunction