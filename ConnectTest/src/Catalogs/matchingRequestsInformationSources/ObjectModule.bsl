
Procedure BeforeWrite(Cancel)
	For Each row In informationSources Do
		row.requestSource = Code;
		row.performBackground = performBackground;
		row.staffOnly = staffOnly;
		row.notSaveAnswer = notSaveAnswer;
		row.mockServerMode = mockServerMode;
	EndDo;
EndProcedure
