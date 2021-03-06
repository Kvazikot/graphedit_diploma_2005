unit BITS;

interface

 { The Word   -  0  0  0  0  0  0 0 0 0 0 0 0 0 0 0 0  }
 { Bit Number - 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0  }

Const
 Bit0 = 1;
 Bit1 = 2;
 Bit2 = 4;
 Bit3 = 8;
 Bit4 = 16;
 Bit5 = 32;
 Bit6 = 64;
 Bit7 = 128;

 Bit8 = 256;
 Bit9 = 512;
 Bit10 = 1024;
 Bit11 = 2048;
 Bit12 = 4096;
 Bit13 = 8192;
 Bit14 = 16384;
 Bit15 = 32768;

 Bit32 = 4294967296;
 Bit31 = 2147483648;
 Bit30 = 1073741824;
 Bit29 = 536870912;

 Procedure SetBit(SetWord, BitNum : Word);
 Procedure ClearBit(SetWord, BitNum : Word);
 Procedure ToggleBit(SetWord, BitNum : Word);
 Function  CheckBit(SetWord, BitNum : Word) : Boolean;

 implementation

Procedure SetBit(SetWord, BitNum : Word);
 Begin
  SetWord := SetWord Or BitNum;     { Set bit }
 End;

Procedure ClearBit(SetWord, BitNum : Word);
 Begin
  SetWord := SetWord Or BitNum;     { Set bit    }
  SetWord := SetWord Xor BitNum;    { Toggle bit }
 End;

Procedure ToggleBit(SetWord, BitNum : Word);
 Begin
  SetWord := SetWord Xor BitNum;    { Toggle bit }
 End;

 Function CheckBit(SetWord, BitNum : Word) : Boolean;
  Begin
   If SetWord And BitNum = BitNum Then            { If bit is set }
    CheckBit := True Else CheckBit := False;
  End;

  end.
