
Procedure gymSchedule(parameters) Export

	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	classesScheduleArray = New Array();
	
	errorDescription = Service.getErrorDescription(language);
	
	If Not requestStruct.Property("gymList") Then
		errorDescription = Service.getErrorDescription(language, "gymError");
	ElsIf Not requestStruct.Property("startDate") Then
		errorDescription = Service.getErrorDescription(language, "startDateError");
	ElsIf Not requestStruct.Property("endDate") Then
		errorDescription = Service.getErrorDescription(language, "endDateError");
	EndIf;

	If errorDescription.result = "" Then
		query = New Query();
		
		textTampTable = "SELECT
		|	classesSchedule.Ref AS Doc,
		|	classesSchedule.period AS period,
		|	classesSchedule.employee AS employee,
		|	classesSchedule.gym AS gym,
		|	classesSchedule.room AS room,
		|	classesSchedule.product AS product,	
		|	classesSchedule.isPreBooked AS isPreBooked,
		|	classesSchedule.isPrePaid AS isPrePaid,
		|	classesSchedule.onlyWithParents AS onlyWithParents,
		|	classesSchedule.onlyMembers AS onlyMembers,
		|	classesSchedule.duration AS duration,
		|	classesSchedule.ageMin AS ageMin,
		|	classesSchedule.ageMax AS ageMax,
		|	classesSchedule.studentLevel AS studentLevel,
		|	classesSchedule.price AS price,
		|	MAX(CASE
		|			WHEN classMembers.user = &user
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS recorded,
		|	MAX(CASE
		|			WHEN &currentTime >= classesSchedule.startRegistration
		|					AND &currentTime <= classesSchedule.endRegistration
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS canRecord,
		|	MAX(CASE
		|			WHEN DATEDIFF(&currentTime, classesSchedule.period, HOUR) > 8
		|				THEN TRUE
		|			ELSE FALSE
		|		END) AS canCancel,
		|	COUNT(classMembers.user) AS userPlaces,
		|	MAX(classesSchedule.availablePlaces) AS availablePlaces
		|INTO TT
		|FROM
		|	Catalog.classesSchedule AS classesSchedule
		|		LEFT JOIN InformationRegister.classMembers AS classMembers
		|		ON (classesSchedule.Ref = classMembers.class)";
		textCondition = "
		|WHERE
		|	classesSchedule.gym IN (&gymList)
		|	AND classesSchedule.period BETWEEN &startDate AND &endDate
		|	AND classesSchedule.active";
		textConditionEmployee = "";
		textConditionService = "";
		
		textGroup = "
		|GROUP BY
		|	classesSchedule.Ref,
		|	classesSchedule.period
		|	classesSchedule.employee,
		|	classesSchedule.gym,
		|	classesSchedule.room,
		|	classesSchedule.product,
		|	classesSchedule.isPreBooked,
		|	classesSchedule.isPrePaid,
		|	classesSchedule.onlyWithParents,
		|	classesSchedule.onlyMembers,
		|	classesSchedule.duration,
		|	classesSchedule.ageMin,
		|	classesSchedule.ageMax,
		|	classesSchedule.studentLevel,
		|	classesSchedule.price
		|
		|;
		|////////////////////////////////////////////////////////////////////////////////";
		textResum = "SELECT
		|	TT.Doc AS Doc,
		|	TT.period AS period,
		|	TT.employee AS employee,
		|	TT.gym AS gym,
		|	TT.product AS product,
		|	TT.recorded AS recorded,
		|	TT.canRecord AS canRecord,
		|	TT.canCancel AS canCancel,
		|	TT.userPlaces AS userPlaces,
		|	TT.isPreBooked AS isPreBooked,
		|	TT.isPrePaid AS isPrePaid,
		|	TT.onlyWithParents AS onlyWithParents,
		|	TT.onlyMembers AS onlyMembers,
		|	TT.duration AS duration,
		|	TT.ageMin AS ageMin,
		|	TT.ageMax AS ageMax,
		|	TT.studentLevel AS studentLevel,
		|	TT.price AS price,
		|	CASE
		|		WHEN TT.availablePlaces = 0
		|			THEN -1
		|		ELSE TT.availablePlaces - TT.userPlaces
		|	END AS availablePlaces
		|FROM
		|	TT AS TT
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.employee AS employee,
		|	ISNULL(employeestranslation.firstName, TT.employee.firstName) AS firstName,
		|	ISNULL(employeestranslation.lastName, TT.employee.lastName) AS lastName
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.employees.translation AS employeestranslation
		|		ON TT.employee = employeestranslation.Ref
		|			AND (employeestranslation.language = &language)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.gym AS gym,
		|	ISNULL(gymstranslation.description, TT.gym.Description) AS name
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
		|		ON TT.gym = gymstranslation.Ref
		|			AND (gymstranslation.language = &language)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.product AS product,
		|	ISNULL(productstranslation.description, TT.product.Description) AS name,
		|	ISNULL(productstranslation.shortDescription, TT.product.shortDescription) AS shortDescription,
		|	TT.product.photo AS photo
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.products.translation AS productstranslation
		|		ON TT.product = productstranslation.Ref
		|			AND (productstranslation.language = &language)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.product AS product,	
		|	ISNULL(tagstranslation.description, productstags.tag.Description) AS tag,
		|	ISNULL(productstags.tag.level, 0) AS level,
		|	ISNULL(productstags.tag.weight, 0) AS weight
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.products.tags AS productstags
		|			LEFT JOIN Catalog.tags.translation AS tagstranslation
		|			ON (productstags.tag = tagstranslation.Ref)
		|				AND (tagstranslation.language = &language)
		|		ON (TT.product = productstags.Ref)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TT.room AS room,
		|	TT.room.latitude AS latitude,
		|	TT.room.longitude AS longitude,
		|	ISNULL(roomstranslation.description, TT.room.Description) AS name
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.rooms.translation AS roomstranslation
		|		ON TT.room = roomstranslation.Ref
		|			AND (roomstranslation.language = &language)";
								
		gymList = New Array();
		For Each gymUid In requestStruct.gymList Do
			gymList.Add(XMLValue(Type("CatalogRef.gyms"), gymUid));	
		EndDo; 
		
		query.SetParameter("gymList", gymList);
		query.SetParameter("user", tokenContext.user);
		query.SetParameter("language", language);
		query.SetParameter("currentTime", parameters.currentTime);
		query.SetParameter("startDate", BegOfDay(XMLValue(Type("Date"), requestStruct.startDate)));
		query.SetParameter("endDate", EndOfDay(XMLValue(Type("Date"), requestStruct.endDate)));				
		
		If requestStruct.Property("employeeId") And ValueIsFilled(requestStruct.employeeId) Then
			textConditionEmployee = "AND classesSchedule.employee = &employee";
			query.SetParameter("employee", XMLValue(Type("CatalogRef.employees"), requestStruct.employeeId));	
		EndIf;		 
		If requestStruct.Property("serviceDescriptionId") And ValueIsFilled(requestStruct.serviceDescriptionId) Then
			textConditionService = "AND classesSchedule.product = &product";
			query.SetParameter("product", XMLValue(Type("CatalogRef.products"), requestStruct.serviceDescriptionId));	
		EndIf; 
		
		querryConditionArray = New Array();
		querryConditionArray.Add(textCondition);
		querryConditionArray.Add(textConditionEmployee);
		querryConditionArray.Add(textConditionService);
		
		querryTextArray = New Array();
		querryTextArray.Add(textTampTable);
		querryTextArray.Add(StrConcat(querryConditionArray, " "));
		querryTextArray.Add(textGroup);
		querryTextArray.Add(textResum);
		query.Text = StrConcat(querryTextArray, " ");
		
		results = query.ExecuteBatch();
			
		select = results[1].Select();
		selectEmployees = results[2].Select();
		selectGyms = results[3].Select();
		selectProducts = results[4].Select();
		selectTags = results[5].Select();
		selectRooms = results[6].Select();
		 
		While select.Next() Do
			classesScheduleStruct = New Structure();			
			
			classesScheduleStruct.Insert("docId", XMLString(select.doc));			
			classesScheduleStruct.Insert("date", XMLString(select.period));
			classesScheduleStruct.Insert("isPreBooked", select.isPreBooked);
			classesScheduleStruct.Insert("isPrePaid", select.isPrePaid);
			classesScheduleStruct.Insert("onlyWithParents", select.onlyWithParents);
			classesScheduleStruct.Insert("onlyMembers", select.onlyMembers);
			classesScheduleStruct.Insert("duration", select.duration);
			classesScheduleStruct.Insert("ageMin", select.ageMin);
			classesScheduleStruct.Insert("ageMax", select.ageMax);
			classesScheduleStruct.Insert("studentLevel", select.studentLevel);
			classesScheduleStruct.Insert("recorded", select.recorded);			
			classesScheduleStruct.Insert("canCancel", select.canCancel);
			classesScheduleStruct.Insert("canRecord", select.canRecord and Not select.recorded);
			classesScheduleStruct.Insert("availablePlaces", select.availablePlaces);
			If tokenContext.user.IsEmpty() Then				
				classesScheduleStruct.Insert("price", Undefined);	
			EndIf;			
			
			serviceStruct = New Structure();
			serviceStruct.Insert("uid", XMLString(select.product));
			If selectProducts.FindNext(New Structure("product", select.product)) Then
				serviceStruct.Insert("name", selectProducts.name);
				serviceStruct.Insert("shortDescription", selectProducts.shortDescription);
				serviceStruct.Insert("photo", selectProducts.photo);
			Else
				serviceStruct.Insert("name", "");
				serviceStruct.Insert("shortDescription", "");
				serviceStruct.Insert("photo", "");
			EndIf;			
			tagArray = New Array();
			While selectTags.FindNext(New Structure("product", select.product)) Do
				tagStruct = New Structure();
				tagStruct.Insert("tag", XMLString(selectTags.tag));
				tagStruct.Insert("level", selectTags.level);
				tagStruct.Insert("weight", selectTags.weight);
				tagArray.Add(tagStruct);	
			EndDo;
			serviceStruct.Insert("tagList", tagArray);
			classesScheduleStruct.Insert("service", serviceStruct);
			selectProducts.Reset();
			selectTags.Reset();			
			
			employeeStruct = New Structure();
			employeeStruct.Insert("uid", XMLString(select.employee));
			If selectEmployees.FindNext(New Structure("employee", select.employee)) Then
				employeeStruct.Insert("firstName", selectEmployees.firstName);
				employeeStruct.Insert("lastName", selectEmployees.lastName);
			Else
				employeeStruct.Insert("firstName", "");
				employeeStruct.Insert("lastName", "");
			EndIf;						
			classesScheduleStruct.Insert("employee", employeeStruct);
			selectEmployees.Reset();
			
			gymStruct = New Structure();
			gymStruct.Insert("uid", XMLString(select.gym));
			If selectGyms.FindNext(New Structure("gym", select.gym)) Then
				gymStruct.Insert("name", selectGyms.name);
			Else
				gymStruct.Insert("name", "");	
			EndIf;						
			classesScheduleStruct.Insert("gym", gymStruct);
			selectGyms.Reset();
			
			roomStruct = New Structure();
			roomStruct.Insert("uid", XMLString(select.room));
			If selectRooms.FindNext(New Structure("room", select.room)) Then
				roomStruct.Insert("name", selectRooms.name);
				roomStruct.Insert("latitude", selectRooms.latitude);
				roomStruct.Insert("longitude", selectRooms.longitude);
			Else
				roomStruct.Insert("name", "");
				roomStruct.Insert("latitude", "");
				roomStruct.Insert("longitude", "");
			EndIf;						
			classesScheduleStruct.Insert("room", roomStruct);
			selectRooms.Reset();			
						
			classesScheduleArray.add(classesScheduleStruct);
		EndDo;
	EndIf;
		
	parameters.Insert("answerBody", HTTP.encodeJSON(classesScheduleArray));
	parameters.Insert("notSaveAnswer", True);
	parameters.Insert("compressAnswer", True);
	parameters.Insert("errorDescription", errorDescription);
	
EndProcedure
