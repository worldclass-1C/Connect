
Function getPhoto(url, type = Undefined) Export
	
	If type = type("CatalogRef.employees") Then
		width = "200px;";
		height = "300px;";				
	Else
		width = "300px;";
		height = "300px;";
	EndIf;

	strArray = New Array();
	
	head = "<html>
		|<head>
		|<style>
		|.square{
		|			width: " + width + "
		|			height: " + height + "
		|			object-fit: contain;
		|			margin: 0;
		|			background: #f0f0f0;
      	|			position: absolute;
      	|			top: 50%;
      	|			left: 50%;
      	|			transform: translate(-50%, -50%);
		|		}				
		|</style>
		|</head>
		|<body>";
		
	down = "</body></html>";
	
	bodyArray = New Array();
	
	bodyArray.Add("<a href = ""#"" id = ""photo"">");
	bodyArray.Add("<img class=""square"" src=" + url + " alt=""photos"">");
	bodyArray.Add("</a>");
		
	strArray.Add(head);
	strArray.Add(StrConcat(bodyArray, Chars.LF));
	strArray.Add(down);	
	
	Return StrConcat(strArray, Chars.LF);
	
EndFunction