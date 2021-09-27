Function ComposeJSON(Obj)

	If Not ValueIsFilled(Obj) Then
		Return "";
	EndIf;
	
	JSONWriter = New JSONWriter;
	Settings = New JSONWriterSettings(JSONLineBreak.None);
	JSONWriter.SetString(Settings);
	WriteJSON(JSONWriter, Obj);
	Return JSONWriter.Close();

EndFunction

Function HMAC(Val SecretKey, Val Message, Val HashFunc) Export
	
	CheckHashFuncIsSupported(HashFunc);
	
	BlSz = 64;
	
	If SecretKey.Size() > BlSz Then
		SecretKey = Hash(SecretKey, HashFunc);
	EndIf;
	
	EmptyBin = GetBinaryDataFromString("");
	SecretKey = BinLeft(SecretKey, BlSz);
	
	K0 = BinRightPad(SecretKey, BlSz, "0x00");
	
	ipad = BinRightPad(EmptyBin, BlSz, "0x36");
	k_ipad = BinBitwiseXOR(K0, ipad);
	
	opad = BinRightPad(EmptyBin, BlSz, "0x5C");
	k_opad = BinBitwiseXOR(K0, opad);
	
	k_ipad_Message = BinConcat(k_ipad, Message);
	k_opad_Hash = BinConcat(k_opad, Hash(k_ipad_Message, HashFunc));
	res = Hash(k_opad_Hash, HashFunc);
	
	Return res;

EndFunction

Procedure CheckHashFuncIsSupported(HashFunc)

	If HashFunc <> HashFunction.MD5 And	HashFunc <> HashFunction.SHA1 And HashFunc <> HashFunction.SHA256 Then
		Raise "HMAC: unsupported hash function: " + HashFunc;
	EndIf;
	
EndProcedure

Function BinLeft(Val BinaryData, Val CountOfBytes)
	
	DataReader = New DataReader(BinaryData);
	
	MemoryStream = New MemoryStream();
	DataWriter = New DataWriter(MemoryStream);
	
	Buffer = DataReader.ReadIntoBinaryDataBuffer(CountOfBytes);
	DataWriter.WriteBinaryDataBuffer(Buffer);
	
	Return MemoryStream.CloseAndGetBinaryData();
	
EndFunction

Function BinRightPad(Val BinaryData, Val Length, Val HexString)

	PadByte = NumberFromHexString(HexString);
	
	DataReader = New DataReader(BinaryData);
	
	MemoryStream = New MemoryStream();
	DataWriter = New DataWriter(MemoryStream);
	
	Buffer = DataReader.ReadIntoBinaryDataBuffer();
	If Buffer.Size > 0 Then
		DataWriter.WriteBinaryDataBuffer(Buffer);
	EndIf;
	
	For n = Buffer.Size + 1 To Length Do
		DataWriter.WriteByte(PadByte);
	EndDo;
	
	Return MemoryStream.CloseAndGetBinaryData();
	
EndFunction

Function BinBitwiseXOR(Val BinaryData1, Val BinaryData2)
	
	MemoryStream = New MemoryStream();
	DataWriter = New DataWriter(MemoryStream);
	
	DataReader1 = New DataReader(BinaryData1);
	DataReader2 = New DataReader(BinaryData2);
	
	Buffer1 = DataReader1.ReadIntoBinaryDataBuffer();
	Buffer2 = DataReader2.ReadIntoBinaryDataBuffer();
	
	If Buffer1.Size > Buffer2.Size Then
		Buffer1.WriteBitwiseXor(0, Buffer2, Buffer2.Size);
		DataWriter.WriteBinaryDataBuffer(Buffer1);
	Else 
		Buffer2.WriteBitwiseXor(0, Buffer1, Buffer1.Size);
		DataWriter.WriteBinaryDataBuffer(Buffer2);
	EndIf;
	
	res = MemoryStream.CloseAndGetBinaryData();
	Return res;

EndFunction

Function Hash(Val Value, Val HashFunc) Export
	DataHashing = New DataHashing(HashFunc);
	DataHashing.Append(Value);
	Return DataHashing.HashSum;
EndFunction

Function BinConcat(Val BinaryData1, Val BinaryData2)

	MemoryStream = New MemoryStream();
	DataWriter = New DataWriter(MemoryStream);
	
	DataReader1 = New DataReader(BinaryData1);
	DataReader2 = New DataReader(BinaryData2);
	
	Buffer1 = DataReader1.ReadIntoBinaryDataBuffer();
	Buffer2 = DataReader2.ReadIntoBinaryDataBuffer();
	
	DataWriter.WriteBinaryDataBuffer(Buffer1);
	DataWriter.WriteBinaryDataBuffer(Buffer2);
	
	res = MemoryStream.CloseAndGetBinaryData();
	Return res;

EndFunction

Function Base64UrlEncode(Val input) Экспорт

	output = Base64String(input);
	output = StrSplit(output, "=")[0]; // Remove any trailing '='s
	output = StrReplace(output, Chars.CR + Chars.LF, "");
	output = StrReplace(output, "+", "-"); // 62nd char of encoding
	output = StrReplace(output, "/", "_"); // 63rd char of encoding
	Return output;

EndFunction

Function EncodeHS256(Val SecretKey, Val Payload = Undefined, Val ExtraHeaders = Undefined) Export
	
	If Payload = Undefined Then
		Payload = New Structure;
	EndIf;
	
	header = New Structure;
	header.Insert("alg", "HS256");
	header.Insert("typ", "JWT");
	
	If ExtraHeaders <> Undefined Then
		For Each eh In ExtraHeaders Do
			header.Insert(eh.Key, eh.Value);
		EndDo;	
	EndIf;
	
	headerBytes = GetBinaryDataFromString(ComposeJSON(header));
	payloadBytes = GetBinaryDataFromString(ComposeJSON(Payload));
	
	segments = New Array;
	segments.Add(Base64UrlEncode(headerBytes));
	segments.Add(Base64UrlEncode(payloadBytes));
	
	stringToSign = StrConcat(segments, ".");
	
	signature = HMAC(
		GetBinaryDataFromString(SecretKey),
		GetBinaryDataFromString(stringToSign),
		HashFunction.SHA256);
		
	segments.Add(Base64UrlEncode(signature));
	
	res = StrConcat(segments, ".");
	
	Return res;

EndFunction

Function DateInTimestamp(Date = Undefined)
	Return Format(Number(?(TypeOf(Date) = Type("Date"), Date, CurrentDate())-Date("19700101")),"NZ=0; NG=0;");
EndFunction

Function TimestampInDate(TS)
	Try
		Return Date("19700101")+?(TypeOf(TS) = Type("String"), Number(TS), TS);
	Except
		Return Неопределено;
	EndTry;
EndFunction

//parameters - Structure( APIKey, APISecret, LifeTimeToken)
Function GetToken(parameters) Export
	
	JWTToken = EncodeHS256(parameters.APISecret,  
							New Structure("iss,exp",
								parameters.APIKey,
								DateInTimestamp(CurrentUniversalDate() + parameters.LifeTimeToken)));
	
	Return JWTToken;
	
EndFunction

