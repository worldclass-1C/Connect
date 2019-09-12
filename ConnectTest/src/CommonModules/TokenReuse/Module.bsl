
Function getContext(authKey) Export
		
	query = New Query();
	query.Text = "SELECT
	|	tokens.Ref AS token,
	|	tokens.appType,
	|	tokens.appVersion,
	|	tokens.chain,
	|	tokens.changeDate,
	|	tokens.createDate,
	|	tokens.deviceModel,
	|	tokens.deviceToken,
	|	tokens.holding,
	|	tokens.lockDate,
	|	tokens.systemType,
	|	tokens.systemVersion,
	|	tokens.timeZone,
	|	tokens.user,
	|	ISNULL(tokens.user.userType, """") AS userType
	|FROM
	|	Catalog.tokens AS tokens
	|WHERE
	|	NOT tokens.DeletionMark
	|	AND tokens.Ref = &token";

	query.SetParameter("token", XMLValue(Type("CatalogRef.tokens"), Left(authKey, 36)));
	queryResult = query.Execute();
	tokenСontext = Token.initContext();
	If Not queryResult.IsEmpty() Then		
		selection = queryResult.Select();
		selection.Next();
		FillPropertyValues(tokenСontext, selection);				
	EndIf;
		
	Return New FixedStructure(tokenСontext);
	
EndFunction

