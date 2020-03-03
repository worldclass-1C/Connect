

Procedure Posting(Cancel, PostingMode)
	
if     (informationChannel = enums.informationChannels.pushCustomer or informationChannel = enums.informationChannels.pushEmployee) 
and (messageStatus = enums.messageStatuses.sent or messageStatus = enums.messageStatuses.read) then
		RegisterRecords.pushStatus.Write = true;
		RegisterRecord = RegisterRecords.pushStatus.Add();
		RegisterRecord.user = token.user;
		RegisterRecord.informationChannel = informationChannel;
		RegisterRecord.message = message;
		RegisterRecord.Period = Date;
		RegisterRecord.amount = 1;
		if messageStatus = enums.messageStatuses.sent then
			RegisterRecord.RecordType = AccumulationRecordType.Receipt;
		ElsIf messageStatus = enums.messageStatuses.read Then 
			RegisterRecord.RecordType = AccumulationRecordType.Expense;
		EndIf;
	endif;
EndProcedure
