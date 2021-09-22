
Function getContext(authKey) Export
	
	tokenContext = Token.initContext();		
	If StrLen(authKey) > 35 Then
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
		|	tokens.underControl,
		|	tokens.user,
		|	tokens.account AS account,
		|	ISNULL(tokens.user.userType, """") AS userType
		|FROM
		|	Catalog.tokens AS tokens
		|WHERE
		|	NOT tokens.DeletionMark
		|	AND tokens.Ref = &token";

		query.SetParameter("token", XMLValue(Type("CatalogRef.tokens"), Left(authKey, 36)));
		queryResult = query.Execute();
		If Not queryResult.IsEmpty() Then
			selection = queryResult.Select();
			selection.Next();
			FillPropertyValues(tokenContext, selection);
		EndIf;
	EndIf;	
	Return New FixedStructure(tokenContext);
	
EndFunction

