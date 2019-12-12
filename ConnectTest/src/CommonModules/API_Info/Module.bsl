
Procedure gymInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	gymStruct = New Structure();
	
	errorDescription = Service.getErrorDescription(language);
	
	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "gymError");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query();
		query.Text = "SELECT TOP 1
		|	gyms.Ref,
		|	gyms.latitude,
		|	gyms.longitude,
		|	ISNULL(gyms.segment.Description, """") AS segment,
		|	ISNULL(gyms.segment.color, """") AS segmentColor,
		|	CASE
		|		WHEN gymstranslation.description IS NULL
		|			THEN gyms.Description
		|		WHEN gymstranslation.description = """"
		|			THEN gyms.Description
		|		ELSE gymstranslation.description
		|	END AS Description,
		|	CASE
		|		WHEN gymstranslation.address IS NULL
		|			THEN gyms.address
		|		WHEN gymstranslation.address = """"
		|			THEN gyms.address
		|		ELSE gymstranslation.address
		|	END AS address,
		|	CASE
		|		WHEN gymstranslation.departmentWorkSchedule IS NULL
		|			THEN gyms.departmentWorkSchedule
		|		WHEN gymstranslation.departmentWorkSchedule = ""[]""
		|			THEN gyms.departmentWorkSchedule
		|		ELSE gymstranslation.departmentWorkSchedule
		|	END AS departments,
		|	CASE
		|		WHEN gymstranslation.nearestMetro IS NULL
		|			THEN gyms.nearestMetro
		|		WHEN gymstranslation.nearestMetro = ""[]""
		|			THEN gyms.nearestMetro
		|		ELSE gymstranslation.nearestMetro
		|	END AS nearestMetro,
		|	CASE
		|		WHEN gymstranslation.additional IS NULL
		|			THEN gyms.additional
		|		ELSE gymstranslation.additional
		|	END AS additional,
		|	CASE
		|		WHEN gymstranslation.state IS NULL
		|			THEN gyms.state
		|		WHEN gymstranslation.state = """"
		|			THEN gyms.state
		|		ELSE gymstranslation.state
		|	END AS state,
		|	gyms.photos.(
		|		URL)
		|FROM
		|	Catalog.gyms AS gyms
		|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
		|		ON gymstranslation.Ref = gyms.Ref
		|		AND gymstranslation.language = &language
		|WHERE
		|	NOT gyms.DeletionMark
		|	AND gyms.Ref = &gym
		|	AND gyms.startDate <= &currentTime
		|	AND gyms.endDate >= &currentTime";

		query.SetParameter("gym", XMLValue(Type("CatalogRef.gyms"), requestStruct.uid));
		query.SetParameter("language", language);
		query.SetParameter("currentTime", parameters.currentTime);		

		select = query.Execute().Select();

		If select.Next() Then
			
			gymStruct.Insert("uid", XMLString(select.Ref));
			gymStruct.Insert("gymId", gymStruct.uid);
			gymStruct.Insert("name", select.Description);
			gymStruct.Insert("type", "");
			gymStruct.Insert("state", select.state);			
			gymStruct.Insert("address", select.address);
			
			coords = New Structure();
			coords.Insert("latitude", select.latitude);
			coords.Insert("longitude", select.longitude);
			gymStruct.Insert("coords", coords);
			
			segment = New Structure();
			segment.Insert("name", select.segment);
			segment.Insert("color", select.segmentColor);
			gymStruct.Insert("segment", segment);			
			
			gymStruct.Insert("departments", HTTP.decodeJSON(select.departments, Enums.JSONValueTypes.array));
			gymStruct.Insert("metro", HTTP.decodeJSON(select.nearestMetro, Enums.JSONValueTypes.array));
			gymStruct.Insert("additional", HTTP.decodeJSON(select.additional, Enums.JSONValueTypes.array));
						 
			gymStruct.Insert("photos", select.photos.Unload().UnloadColumn("URL"));
						
		EndIf;
		
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(gymStruct));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure

Procedure employeeInfo(parameters) Export

	requestStruct = parameters.requestStruct;
	language = parameters.language;
	struct = New Structure();
	
	errorDescription = Service.getErrorDescription(language);

	If Not requestStruct.Property("uid") Then
		errorDescription = Service.getErrorDescription(language, "stuff");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query("SELECT
		|	employees.Ref AS employee,
		|	ISNULL(employeestranslation.firstName, employees.firstName) AS firstName,
		|	ISNULL(employeestranslation.lastName, employees.lastName) AS lastName,
		|	employees.gender,
		|	ISNULL(employeestranslation.descriptionFull, employees.descriptionFull) AS descriptionFull,
		|	ISNULL(employeestranslation.categoryList, employees.categoryList) AS categoryList,
		|	employees.tagList,
		|	employees.photo AS photo,
		|	employees.photos.(
		|		URL)
		|FROM
		|	Catalog.employees AS employees
		|		LEFT JOIN Catalog.employees.translation AS employeestranslation
		|		ON employees.Ref = employeestranslation.Ref
		|		and employeestranslation.language = &language
		|WHERE
		|	employees.Ref = &employee");

		query.SetParameter("employee", XMLValue(Type("CatalogRef.employees"), requestStruct.uid));
		query.SetParameter("language", language);				
		
		select = query.Execute().Select();

		If select.Next() Then			
			struct.Insert("uid", requestStruct.uid);
			struct.Insert("firstName", select.firstName);
			struct.Insert("lastName", select.lastName);
			struct.Insert("gender", select.gender);			
			struct.Insert("isMyCoach", False);
			struct.Insert("categoryList", HTTP.decodeJSON(select.categoryList, Enums.JSONValueTypes.array));
			struct.Insert("tagList", HTTP.decodeJSON(select.tagList, Enums.JSONValueTypes.array));
			struct.Insert("presentation", HTTP.decodeJSON(select.descriptionFull, Enums.JSONValueTypes.array));			
			struct.Insert("photos", select.photos.Unload().UnloadColumn("URL"));
		EndIf;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
		
EndProcedure

Procedure accountProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Account.profile(parameters.tokenContext.account)));		
EndProcedure

Procedure userProfile(parameters) Export
	parameters.Insert("answerBody", HTTP.encodeJSON(Users.profile(parameters.tokenContext.user, parameters.tokenContext.appType)));	
EndProcedure

Procedure userSummary(parameters) Export
	tokenContext = parameters.tokenContext;
	
	query = New Query("SELECT
	|	chainscacheValues.cacheValuesType.Code AS cacheCode,
	|	usersStates.stateValue AS cacheValue,
	|	chainscacheValues.cacheValuesType.defaultValueType AS defaultValueType
	|FROM
	|	Catalog.chains.cacheValuesTypes AS chainscacheValues
	|		LEFT JOIN InformationRegister.usersStates AS usersStates
	|		ON chainscacheValues.cacheValuesType = usersStates.cacheValuesType
	|		AND usersStates.user = &user
	|		AND usersStates.appType = &appType
	|WHERE
	|	chainscacheValues.Ref = &chain
	|	AND chainscacheValues.isUsed");
	
	query.SetParameter("chain", tokenContext.chain);
	query.SetParameter("user", tokenContext.user);
	query.SetParameter("appType", tokenContext.appType);
	
	struct = New Structure();
	select = query.Execute().Select();
	While select.Next() Do
		struct.Insert(select.cacheCode, HTTP.decodeJSON(?(select.cacheValue = null, "", select.cacheValue), select.defaultValueType));
	EndDo;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(struct));
	
EndProcedure

