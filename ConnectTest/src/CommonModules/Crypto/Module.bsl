
Function checkHasp(timeStamp, hash) Export
	template = GetCommonTemplate("Connect");
	If TypeOf(template) = Type("TextDocument") Then
		word = template.GetText();		
		timeKey = StrReplace(Service.getAmountOfNumbers(timeStamp), Chars.NBSp, "");		
		hmac = hmac(word + timeKey, word, HashFunction.SHA256);
		If hmac = hash Then
			Return "";									
		EndIf;
	EndIf;
	Return "noValidRequest";
EndFunction

Function hmac(_secretKey, _text, hashFunc)
	
	secretKey = GetBinaryDataFromString(_secretKey);
	text = GetBinaryDataFromString(_text);
	
	checkHashFuncIsSupported(hashFunc);
	
	BlSz = 64;
	
	If secretKey.Size() > BlSz Then
		secretKey = hash(secretKey, hashFunc);
	EndIf;
	
	emptyBin = GetBinaryDataFromString("");
	secretKey = binLeft(secretKey, BlSz);
	
	K0 = binRightPad(secretKey, BlSz, "0x00");
	
	ipad = binRightPad(emptyBin, BlSz, "0x36");
	k_ipad = binBitwiseXOR(K0, ipad);
	
	opad = binRightPad(emptyBin, BlSz, "0x5C");
	k_opad = binBitwiseXOR(K0, opad);
	
	k_ipad_text = binConcat(k_ipad, text);
	k_opad_hash = binConcat(k_opad, hash(k_ipad_text, hashFunc));
	
	Return StrReplace(Lower(Hash(k_opad_hash, hashFunc))," ","");
	
EndFunction

Procedure checkHashFuncIsSupported(hashFunc)
	If hashFunc <> HashFunction.MD5 And HashFunc <> HashFunction.SHA1
			And HashFunc <> HashFunction.SHA256 Then
		Raise "HMAC: unsupported hash function: " + HashFunc;
	EndIf;
EndProcedure

Function hash(Val value, Val hashFunc) Export
	dataHashing = New DataHashing(hashFunc);
	dataHashing.Append(value);
	Return dataHashing.HashSum;
EndFunction

Function binLeft(Val binaryData, Val countOfBytes)	
	dataReader = New DataReader(binaryData);	
	memoryStream = New memoryStream();
	dataWriter = New dataWriter(memoryStream);	
	buffer = dataReader.ReadIntoBinaryDataBuffer(countOfBytes);
	dataWriter.WriteBinaryDataBuffer(buffer);	
	Return memoryStream.CloseAndGetBinaryData();	
EndFunction

Function BinRightPad(Val binaryData, Val length, Val hexString)
	padByte = NumberFromHexString(hexString);	
	dataReader = New DataReader(binaryData);	
	memoryStream = New MemoryStream();
	dataWriter = New DataWriter(memoryStream);	
	buffer = dataReader.ReadIntoBinaryDataBuffer();
	If buffer.Size > 0 Then
		dataWriter.WriteBinaryDataBuffer(buffer);
	EndIf;	
	For n = buffer.Size + 1 To length Do
		dataWriter.WriteByte(padByte);
	EndDo;	
	Return memoryStream.CloseAndGetBinaryData();	
EndFunction

Function binBitwiseXOR(Val binaryData1, Val binaryData2)
	memoryStream = New MemoryStream();
	dataWriter = New DataWriter(memoryStream);	
	dataReader1 = New DataReader(binaryData1);
	dataReader2 = New DataReader(binaryData2);	
	buffer1 = dataReader1.ReadIntoBinaryDataBuffer();
	buffer2 = dataReader2.ReadIntoBinaryDataBuffer();	
	If buffer1.Size > buffer2.Size Then
		buffer1.WriteBitwiseXor(0, buffer2, buffer2.Size);
		dataWriter.WriteBinaryDataBuffer(buffer1);
	Else 
		buffer2.WriteBitwiseXor(0, buffer1, buffer1.Size);
		dataWriter.WriteBinaryDataBuffer(buffer2);
	EndIf;	
	res = memoryStream.CloseAndGetBinaryData();
	Return res;
EndFunction

Function binConcat(Val binaryData1, Val binaryData2)
	memoryStream = New MemoryStream();
	dataWriter = New DataWriter(memoryStream);	
	dataReader1 = New DataReader(binaryData1);
	dataReader2 = New DataReader(binaryData2);	
	buffer1 = dataReader1.ReadIntoBinaryDataBuffer();
	buffer2 = dataReader2.ReadIntoBinaryDataBuffer();	
	dataWriter.WriteBinaryDataBuffer(buffer1);
	dataWriter.WriteBinaryDataBuffer(buffer2);	
	res = memoryStream.CloseAndGetBinaryData();
	Return res;
EndFunction

Function EncryptBase64(String, Encoding) Export
	
	TemporaryFileName = GetTempFileName();
	
	TextWriter = New TextWriter(TemporaryFileName, Encoding);
	TextWriter.Write(String);
	TextWriter.Close();
	
	BinaryData = Новый BinaryData(TemporaryFileName);
	Result = Base64String(BinaryData);
	If Лев(Result, 4) = "77u/" Then
		Result = Сред(Result, 5);
	EndIf; 
	Result = StrReplace(Result, Chars.LF, "");
	
	DeleteFiles(TemporaryFileName);
	
	Return Result;
	
EndFunction