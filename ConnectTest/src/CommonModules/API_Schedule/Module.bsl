Procedure gymSchedule(parameters) Export

	requestStruct = parameters.requestStruct;
	tokenContext = parameters.tokenContext;
	language = parameters.language;
	classesScheduleArray = New Array;

	query = New Query;
	textSelectGyms = "SELECT
					 |	gyms.chain,
					 |	MAX(CASE
					 |		WHEN gyms.type = VALUE(Enum.gymTypes.studio)
					 |				THEN FALSE
					 |		ELSE TRUE
					 |	END) AS canAddOutdoor
					 |INTO TemporaryChains
					 |FROM
					 |	Catalog.gyms AS gyms
					 |WHERE
					 |	gyms.Ref IN (&gymList)
					 |GROUP BY
					 |	gyms.chain		
					 |;
					 |////////////////////////////////////////////////////////////////////////////////
					 |SELECT
					 |	gyms.Ref as gym
					 |INTO TemporaryGyms
					 |FROM
					 |	Catalog.gyms AS gyms
					 |WHERE
					 |	gyms.Ref IN (&gymList)
					 |
					 |UNION ALL
					 |
					 |SELECT
					 |	gyms.Ref as gym
					 |FROM
					 |	Catalog.gyms AS gyms
					 |		INNER JOIN TemporaryChains AS TemporaryChains
					 |		ON gyms.chain = TemporaryChains.chain
					 |		AND gyms.type = VALUE(Enum.gymTypes.Outdoor)
					 |		AND TemporaryChains.canAddOutdoor
					 |
					 |;
					 |////////////////////////////////////////////////////////////////////////////////";

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
					|		WHEN classMembers.user = &user
					|			THEN TRUE
					|		ELSE FALSE
					|	END) AS recorded,
					|	MAX(CASE
					|		WHEN &currentTime >= classesSchedule.startRegistration
					|		AND &currentTime <= classesSchedule.endRegistration
					|			THEN TRUE
					|		ELSE FALSE
					|	END) AS canRecord,
					|	MAX(CASE
					|		when &currentTime < classesSchedule.startRegistration
					|			then false
					|		WHEN NOT classesSchedule.isPrePaid and classMembers.user = &user
					|			THEN TRUE
					|		WHEN DATEDIFF(&currentTime, classesSchedule.period, HOUR) > 8 and classMembers.user = &user
					|			THEN TRUE
					|		ELSE FALSE
					|	END) AS canCancel,
					|	COUNT(classMembers.user) AS userPlaces,
					|	MAX(classesSchedule.availablePlaces) AS availablePlaces,
					|	ISNULL(MAX(CAST(Meetings.join_url AS STRING(200))), """") AS urlZoom
					|INTO TT
					|FROM
					|	Catalog.classesSchedule AS classesSchedule
					|		LEFT JOIN InformationRegister.classMembers AS classMembers
					|		ON classesSchedule.Ref = classMembers.class
					|		LEFT JOIN Catalog.meetingZoom AS Meetings
					|		ON classesSchedule.Ref = Meetings.doc";

	textCondition = "
					|WHERE
					|	classesSchedule.gym IN (Select TemporaryGyms.gym from TemporaryGyms as TemporaryGyms)
					|	AND classesSchedule.period BETWEEN &startDate AND &endDate
					|	AND classesSchedule.active";
	textConditionEmployee = "";
	textConditionService = "";
	textConditionDocId = "";

	textGroup = "
				|GROUP BY
				|	classesSchedule.Ref,
				|	classesSchedule.period,
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
	|	TT.room AS room,
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
	|		ELSE case
	|			when (TT.availablePlaces - TT.userPlaces) < 0
	|				then 0
	|			else TT.availablePlaces - TT.userPlaces
	|		end
	|	END AS availablePlaces,
	|	TT.urlZoom AS urlZoom
	|FROM
	|	TT AS TT
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.employee AS employee,
	|	ISNULL(employeestranslation.firstName, ISNULL(TT.employee.firstName, """")) AS firstName,
	|	ISNULL(employeestranslation.lastName, ISNULL(TT.employee.lastName, """")) AS lastName
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.employees.translation AS employeestranslation
	|		ON TT.employee = employeestranslation.Ref
	|		AND (employeestranslation.language = &language)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.gym AS gym,
	|	ISNULL(gymstranslation.description, ISNULL(TT.gym.Description, """")) AS name
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.gyms.translation AS gymstranslation
	|		ON TT.gym = gymstranslation.Ref
	|		AND (gymstranslation.language = &language)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.product AS product,
	|	ISNULL(productstranslation.description, ISNULL(TT.product.Description, """")) AS name,
	|	ISNULL(productstranslation.shortDescription, ISNULL(TT.product.shortDescription, """")) AS shortDescription,
	|	ISNULL(TT.product.photo, """") AS photo
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.products.translation AS productstranslation
	|		ON TT.product = productstranslation.Ref
	|		AND (productstranslation.language = &language)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.product AS product,
	|	ISNULL(tagstranslation.description, ISNULL(productstags.tag.Description, """")) AS tag,
	|	ISNULL(productstags.tag.level, 0) AS level,
	|	ISNULL(productstags.tag.weight, 0) AS weight
	|FROM
	|	TT AS TT
	|		INNER JOIN Catalog.products.tags AS productstags
	|			LEFT JOIN Catalog.tags.translation AS tagstranslation
	|			ON (productstags.tag = tagstranslation.Ref)
	|			AND (tagstranslation.language = &language)
	|		ON (TT.product = productstags.Ref)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.room AS room,
	|	ISNULL(TT.room.latitude, 0) AS latitude,
	|	ISNULL(TT.room.longitude, 0) AS longitude,
	|	ISNULL(roomstranslation.description, ISNULL(TT.room.Description, """")) AS name
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.rooms.translation AS roomstranslation
	|		ON TT.room = roomstranslation.Ref
	|		AND (roomstranslation.language = &language)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TT.doc as ref,
	|	classesScheduleexternalRefs.resoursType as type,
	|	classesScheduleexternalRefs.resourseRef as resourseRef
	|FROM
	|	TT AS TT
	|		INNER JOIN Catalog.classesSchedule.externalRefs AS classesScheduleexternalRefs
	|		ON classesScheduleexternalRefs.Ref = TT.doc
	|Where
	|	not classesScheduleexternalRefs.resourseRef = """"
	|	and
	|	not classesScheduleexternalRefs.resoursType = value(Enum.typeOfExternalRefs.emptyref)";

	gymList = New Array;
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

	If requestStruct.Property("docId") And ValueIsFilled(requestStruct.docId) Then
		textConditionDocId = "AND classesSchedule.ref = &docId";
		query.SetParameter("docId", XMLValue(Type("CatalogRef.classesSchedule"), requestStruct.docId));
	EndIf;

	querryConditionArray = New Array;
	querryConditionArray.Add(textCondition);
	querryConditionArray.Add(textConditionEmployee);
	querryConditionArray.Add(textConditionService);
	querryConditionArray.Add(textConditionDocId);

	querryTextArray = New Array;
	querryTextArray.Add(textSelectGyms);
	querryTextArray.Add(textTampTable);
	querryTextArray.Add(StrConcat(querryConditionArray, Chars.LF));
	querryTextArray.Add(textGroup);
	querryTextArray.Add(textResum);
	query.Text = StrConcat(querryTextArray, Chars.LF);

	results = query.ExecuteBatch();

	select = results[3].Select();
	selectEmployees = results[4].Select();
	selectGyms = results[5].Select();
	selectProducts = results[6].Select();
	selectTags = results[7].Select();
	selectRooms = results[8].Select();
	selectRefs = results[9].Select();
	While select.Next() Do
		classesScheduleStruct = New Structure;

		classesScheduleStruct.Insert("docId", XMLString(select.doc));
		classesScheduleStruct.Insert("date", XMLString(select.period));
		classesScheduleStruct.Insert("startDate", XMLString(select.period));
		classesScheduleStruct.Insert("endDate", XMLString(select.period + select.duration * 60));
		classesScheduleStruct.Insert("isPreBooked", select.isPreBooked);
		classesScheduleStruct.Insert("isPrePaid", select.isPrePaid);
		classesScheduleStruct.Insert("onlyWithParents", select.onlyWithParents);
		classesScheduleStruct.Insert("onlyMembers", select.onlyMembers);
		classesScheduleStruct.Insert("duration", select.duration);
		classesScheduleStruct.Insert("ageMin", select.ageMin);
		classesScheduleStruct.Insert("ageMax", select.ageMax);
		classesScheduleStruct.Insert("studentLevel", ?(select.studentLevel = "", "Any", select.studentLevel));
		classesScheduleStruct.Insert("recorded", select.recorded);
		classesScheduleStruct.Insert("canCancel", select.canCancel);
		//classesScheduleStruct.Insert("serviceKindName", "");
		If select.isPreBooked And select.availablePlaces = 0 Then
			classesScheduleStruct.Insert("canRecord", False);
		Else
			classesScheduleStruct.Insert("canRecord", select.canRecord And Not select.recorded);
		EndIf;
		classesScheduleStruct.Insert("availablePlaces", select.availablePlaces);
		urlZoom= select.urlZoom;
		If tokenContext.user.IsEmpty() Then
			classesScheduleStruct.Insert("price", Undefined);
		Else
			classesScheduleStruct.Insert("price", ?(select.price = 0, Undefined, select.price));
		EndIf;

		serviceStruct = New Structure;
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
		tagArray = New Array;
		While selectTags.FindNext(New Structure("product", select.product)) Do
			tagStruct = New Structure;
			tagStruct.Insert("tag", XMLString(selectTags.tag));
			tagStruct.Insert("level", selectTags.level);
			tagStruct.Insert("weight", selectTags.weight);
			tagArray.Add(tagStruct);
		EndDo;
		serviceStruct.Insert("tagList", tagArray);
		classesScheduleStruct.Insert("service", serviceStruct);
		selectProducts.Reset();
		selectTags.Reset();

		employeeStruct = New Structure;
		employeeStruct.Insert("uid", ?(select.employee.isEmpty(), "", XMLString(select.employee)));
		If selectEmployees.FindNext(New Structure("employee", select.employee)) Then
			employeeStruct.Insert("firstName", selectEmployees.firstName);
			employeeStruct.Insert("lastName", selectEmployees.lastName);
		Else
			employeeStruct.Insert("firstName", "");
			employeeStruct.Insert("lastName", "");
		EndIf;
		classesScheduleStruct.Insert("employee", employeeStruct);
		selectEmployees.Reset();

		gymStruct = New Structure;
		gymStruct.Insert("uid", XMLString(select.gym));
		If selectGyms.FindNext(New Structure("gym", select.gym)) Then
			gymStruct.Insert("name", selectGyms.name);
		Else
			gymStruct.Insert("name", "");
		EndIf;
		classesScheduleStruct.Insert("gym", gymStruct);
		selectGyms.Reset();

		roomStruct = New Structure;
		roomStruct.Insert("uid", ?(select.room.isEmpty(), "", XMLString(select.room)));
		If selectRooms.FindNext(New Structure("room", select.room)) Then
			roomStruct.Insert("name", selectRooms.name);
			roomStruct.Insert("latitude", selectRooms.latitude);
			roomStruct.Insert("longitude", selectRooms.longitude);
		Else
			roomStruct.Insert("name", "");
			roomStruct.Insert("latitude", 0);
			roomStruct.Insert("longitude", 0);
		EndIf;
		classesScheduleStruct.Insert("room", roomStruct);
		selectRooms.Reset();

		externalRefs = New Array;
		If (select.isPreBooked And select.recorded) Or Not select.isPreBooked Then
			While selectRefs.FindNext(New Structure("ref", select.doc)) Do
				refStruct = New Structure;
				refStruct.Insert("type", string(selectRefs.type));
				refStruct.Insert("ref", selectRefs.resourseRef);
				externalRefs.Add(refStruct);
			EndDo;
			If ValueIsFilled(urlZoom) Then
				externalRefs.Add(New Structure("type,ref", "zoom", urlZoom));
			EndIf;
		EndIf;
		classesScheduleStruct.Insert("externalRefs", externalRefs);
		selectRefs.Reset();

		classesScheduleArray.add(classesScheduleStruct);
	EndDo;

	parameters.Insert("answerBody", HTTP.encodeJSON(classesScheduleArray));

EndProcedure