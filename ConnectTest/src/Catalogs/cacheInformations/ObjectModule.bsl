Procedure OnWrite(Cancel)
	Rec = InformationRegisters.cacheIndex.CreateRecordManager();
	FillPropertyValues(Rec,ThisObject);
	Rec.cacheInformation = Ref;
	Rec.Write();
EndProcedure
