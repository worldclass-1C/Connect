
Function okPOST(Request)
	Response = New HTTPServiceResponse(200);
	Response.Headers.Insert("Content-type", "text/html");
	Body = "<!DOCTYPE html>
			|<html>
			|<head>
			| <meta charset=""utf-8"">
			|  <title>Payment success</title>
			|</head>
			|<style>
			|  	.success-page {
			|	    margin: 0 auto;
			|	    text-align: center;
			|	    position: relative;
			|	    top: 50%;
			|	}
			|	h2 {
			|	    margin-top: 25px;
			|	}
			|	a {
			|	  	text-decoration: none;
			|	}
			|</style>
			|<body>
			|	<div class=""success-page"">
			|		<h2>Платеж успешно принят</h2>
			|		<a href=""#"" onclick=""return window.close();"">Закрыть</a>
			|	</div>
			|	<script>
			| 		setTimeout(function () {
			|			window.close();
			|  		}, 3000);
			|  	</script>
			|</body>
			|</html>";
	Response.SetBodyFromString(Body);
	Return Response;
EndFunction

Function failPOST(Request)
	Response = New HTTPServiceResponse(200);
	Response.Headers.Insert("Content-type", "text/html");
	Body = "<!DOCTYPE html>
			|<html>
			|<head>
			|  <meta charset=""utf-8"">
			|  <title>Payment fail</title>
			|</head>
			|<style>
			|  	.fail-page {
			|	    margin: 0 auto;
			|	    text-align: center;
			|	    position: relative;
			|	    top: 50%;
			|	}
			|	h2 {
			|	    margin-top: 25px;
			|	}
			|	a {
			|	  	text-decoration: none;
			|	}
			|</style>
			|<body>
			|	<div class=""fail-page"">
			|		<h2>Произошла ошибка, повторите оплату снова.</h2>
			|		<a href=""#"" onclick=""return window.close();"">Закрыть</a>
			|	</div>
			|	<script>
			|		setTimeout(function () {
			|			window.close();
			|		}, 3000);
			|	</script>
			|</body>
			|</html>";
	Response.SetBodyFromString(Body);
	Return Response;
EndFunction
