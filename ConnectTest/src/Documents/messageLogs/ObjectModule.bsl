
Procedure Posting(Cancel, PostingMode)

	If (informationChannel = enums.informationChannels.pushCustomer Or informationChannel
		= enums.informationChannels.pushEmployee) And (messageStatus = enums.messageStatuses.sent Or messageStatus
		= enums.messageStatuses.read) Then
		RegisterRecords.pushStatus.Write = True;
		RegisterRecord = RegisterRecords.pushStatus.Add();
		RegisterRecord.user = message.user;
		RegisterRecord.informationChannel = informationChannel;
		RegisterRecord.message = message;
		RegisterRecord.Period = Date;
		RegisterRecord.amount = 1;
		If messageStatus = enums.messageStatuses.sent Then
			RegisterRecord.RecordType = AccumulationRecordType.Receipt;
		ElsIf messageStatus = enums.messageStatuses.read Then
			RegisterRecord.RecordType = AccumulationRecordType.Expense;
		EndIf;
	EndIf;
EndProcedure