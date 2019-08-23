
Function nodeMessagesToSend(informationChannel) Export
	Return ExchangePlans.messagesToSend.FindByAttribute("informationChannel", informationChannel);	
EndFunction

Function nodeMessagesToCheckStatus(informationChannel) Export
	Return ExchangePlans.messagesToCheckStatus.FindByAttribute("informationChannel", informationChannel);	
EndFunction

Function nodeUsersCheckIn(registrationType) Export
	Return ExchangePlans.usersCheckIn.FindByAttribute("registrationType", registrationType);	
EndFunction

Function getAuthorizationKey(systemType, certificate) Export
	If systemType = Enums.systemTypes.Android Then
		Return certificate;
	Else	
		Return GetCommonTemplate(certificate);
	EndIf;
EndFunction

Function getBaseURL() Export
	Return  Constants.BaseURL.Get();	
EndFunction
