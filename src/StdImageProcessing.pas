unit StdImageProcessing;

interface

uses
  GR32, Bits, Contnrs, Math;

 type
    THistogram = class
      pbmp:PBitmap32;
      nData:array[0..260] of Longint;
      nlevels: integer;
      nMax: integer;
      nMin: integer;
      constructor Create(In_bmp:PBitmap32);
      function    Get(In_bmp:PBitmap32):integer; //num levels
      procedure   Clear;
      destructor  Destroy; override;
      function    Update: integer;
    end;

    procedure   LabelBoarders(In_bmp:PBitmap32);
    procedure   LabelBG(In_bmp:PBitmap32);

  const
   //$FF RR GG BB - ??????? ??????
   //$XX RR GG BB -  ??????????
    BG       = 1073741824;//Bit30
    NOT_BG    = Bit29;
    BOARDER  = $66666666;

implementation

////////////////////////////////////////////
//???????????
///////////////////////////////////////////

constructor THistogram.Create(In_bmp:PBitmap32);
begin
  if (In_bmp = nil) then exit;
  pbmp:=In_bmp;
  Clear;
  nlevels:=Get(In_bmp);
end;

destructor THistogram.Destroy; begin  end;

function THistogram.Update:integer;
begin
  result:=Get(pbmp);
end;

function THistogram.Get(In_bmp:PBitmap32):integer;
var S: PColor32; j:integer;
begin
   //?????? ??????? ???????????
   S:=In_bmp.PixelPtr[0,0];
   for j:=0 to In_bmp.Height*In_bmp.Width-1 do
   begin
     inc(nData[S^ and 255]);
     inc(S);
   end;
   result:=0;
   for j:=0 to 255 do
     if nData[j] = 0 then inc(result);
end;

procedure THistogram.Clear;
var i:integer;
begin
  for i:=0 to 255 do nData[i]:=0;
end;

////////////////////////////////////////////
//???????? ??? ????????? ???????
///////////////////////////////////////////

procedure LabelBoarders(In_bmp:PBitmap32);
var S,Sd: PColor32; i:integer;
begin
  //1-?? ? ????????? ??????
  S:=In_bmp.PixelPtr[0,0];
  Sd:=In_bmp.PixelPtr[0,(In_bmp.Height-1)];
   for i:=0 to In_bmp.Width-1 do
   begin
     S^:=BOARDER;
     Sd^:=BOARDER;
     inc(S); inc(Sd);
   end;
  //1-?? ? ????????? ???????
  for i:=0 to In_bmp.Height-1 do
  begin
    In_bmp.PixelPtr[0,i]^:=BOARDER;
    In_bmp.PixelPtr[In_bmp.Width-1,i]^:=BOARDER;
  end;
end;


////////////////////////////////////////////
//?????? ???????? ?????????? ?? ???????????
///////////////////////////////////////////

procedure LabelBG(In_bmp:PBitmap32);
var
     BGVal:array of integer;
     Gist: THistogram;
     Val,j,i,k:integer;
     S,ptr_0: PColor32;
begin

   Gist:= THistogram.Create(In_bmp);

   SetLength(BGVal,5);

  //??? 3-4 ????????? ? ???????????
  for j:=0 to 4 do
  begin
   k:=MaxIntValue(Gist.nData);
   for i:=0 to 255 do
   if(Gist.nData[i]=k)then
   begin
    BGVal[j]:=i;
    Gist.nData[i]:=0;
   end;
  end;
   Gist.Free;
  //??????? ?????????
   S:=In_bmp.PixelPtr[0,0];
   for j:=0 to In_bmp.Height*In_bmp.Width-2 do
   begin
    //????? 4 ?????
    S^:=S^ and $00FFFFFF;
     //???????? ??????????
    if((S^ and 255)=BGVal[0]) then //or ((S^ and 255)=RemVal[1]) then //or ((S^ and 255)=RemVal[1]) then //or (S^ and 255=RemVal[2]) then// or (S^ and 255=RemVal[1]) or (S^ and 255=RemVal[2]) then
      S^:=S^ or BG
    else S^:=1;  

     inc(S);
   end;

end;



end.


