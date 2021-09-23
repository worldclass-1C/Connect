
Procedure sendOrder(parameters) Export
	
	PlainText = parameters.user + 
				Left(XMLString(parameters.order)+"-"+XMLString(parameters.bindingUser),64)+
				format(parameters.acquiringAmount,"NG=0; NFD=2") + 
				Constants.acquiringURL.Get()+"/okURL" + 
				Constants.acquiringURL.Get()+"/failURL" +
				"Auth"+  
				Left(XMLString(parameters.order),20) + 
				parameters.key;    
	hashFunc = New DataHashing(HashFunction.SHA1);
	hashFunc.Append(PlainText);
	requestBody = New Array();
	requestBody.Add("clientid=" + parameters.user);
	requestBody.Add("storetype=3d_Pay_Hosting");
	requestBody.Add("storekey="+parameters.key);
	requestBody.Add("hash=" + base64string(hashFunc.HashSum));
	requestBody.Add("trantype=Auth");
	requestBody.Add("amount=" + format(parameters.acquiringAmount,"NG=0; NFD=2"));
	requestBody.Add("currency=417");
	requestBody.Add("oid="+Left(XMLString(parameters.order)+"-"+XMLString(parameters.bindingUser),64));
	requestBody.Add("okUrl=" + Constants.acquiringURL.Get()+"/okURL");
	requestBody.Add("failUrl=" + Constants.acquiringURL.Get()+"/failURL");
	requestBody.Add("lang=en");
	requestBody.Add("encoding=UTF-8");
	requestBody.Add("rnd="+Left(XMLString(parameters.order),20));
		
	requestURL = New Array();
	Connection ="/fim/est3Dgate";
	Body = StrConcat(requestBody, "&");
	requestURL.Add(Body);
	URL = Body;
	parameters.Insert("requestBody", URL);	
	ConnectionHTTP = New HTTPConnection(parameters.server, parameters.port,,,, parameters.timeout, ?(parameters.secureConnection, New OpenSSLSecureConnection(), Undefined), parameters.useOSAuthentication);
	
	requestHTTP = New HTTPRequest(Connection);
	requestHTTP.Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	requestHTTP.Headers.Insert("Host", parameters.server);
	requestHTTP.SetBodyFromString(Body, TextEncoding.UTF8);
	answerHTTP = ConnectionHTTP.Post(requestHTTP);		
	parameters.insert("response", answerHTTP.getbodyasstring());
	
	file = new TextDocument;
	file.AddLine(answerHTTP.getbodyasstring());	
	fileName = files.getFilePath(parameters.order);	
	file.Write(fileName.location+"\"+ XMLString(parameters.order) +".html", );
	parameters.insert("orderid", XMLString(new UUID()));
	parameters.insert("formurl", fileName.URL+"/"+ XMLString(parameters.order) +".html");
	parameters.insert("errorcode", "");
	Acquiring.orderidentifier(parameters.order, ,XMLString(parameters.order));
		
EndProcedure

Procedure checkOrder(parameters) Export
	parameters.errorCode = "noData";
EndProcedure

