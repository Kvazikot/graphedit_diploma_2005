unit GE_FDistance;

interface

uses
  GR32, StdImageProcessing, Contnrs, PixelQuenue, Bits;

type

  TProjections = record
     X: array of integer;
     Y: array of integer;
     size_x: integer;
     size_y: integer;
  end;

 procedure DistanceFunction(In_Out_bmp:PBitmap32);
 procedure GetDistanceProj(src:PBitmap32; bDrawProj:boolean);

  const
        LOGICAL_1 = $FF;
        BOARDER = $66666666;
        BG       = Bit30;
        NOT_BG   = Bit29;
        SEEN     = Bit31;

implementation

////////////////////////////////////////////////////////////////////
//??????? ?????????
//???? - ???????? ???????????, ????? - ???????? ?????????
//????????? ?? ??????? ???????????
////////////////////////////////////////////////////////////////////

procedure DistanceFunction(In_Out_bmp:PBitmap32);
var     fifo: TPixelQuenue;
        pI, pI_0,pI_lst:PColor32;
        stribe:integer;
        I_bmp:PBitmap32;
        wd,hg,i,j,k:Integer;
        S,D,Su,Sd:PColor32; //temp pointers
        Iq:     array[0..7] of PColor32;
        msk: integer;
begin
   //pointer
   I_bmp:=In_Out_bmp;
   wd:=I_bmp.Width;
   hg:=I_bmp.Height;
   fifo:=TPixelQuenue.Create(wd*hg);//(wd*hg);
   pI_0:=I_bmp.PixelPtr[0,0];
   pI_lst:=I_bmp.PixelPtr[wd,hg];
   stribe:=wd*4;

   //???????? ?????????? ? ?????? (???? ?????)
   LabelBG(In_Out_bmp);
   LabelBoarders(In_Out_bmp);

  S:=I_bmp.PixelPtr[0,0];

  for j:=0 to wd*hg - 1 do
  begin
     //???? ??????? ?????? ??????????? ?????????
     if ((S^ and BG) = BG) then
     begin
       inc(S); continue;
     end;
     //S^:=clYellow32;
     //??????? ??????
     Iq[0]:=PColor32(Integer(S)-stribe);
     Iq[1]:=Iq[0]; dec(Iq[1]);
     Iq[2]:=Iq[0]; inc(Iq[2]);
     //??????? ??????
     Iq[3]:=S; dec(Iq[3]);
     Iq[4]:=S; inc(Iq[4]);
     //?????? ??????
     Iq[5]:=PColor32(Integer(S)+stribe);
     Iq[6]:=Iq[5]; inc(Iq[6]);
     Iq[7]:=Iq[5]; dec(Iq[7]);
     ///???? ?? ???????
     for k:=0 to 7 do
     begin
       if ((Iq[k]^ and BG)=BG) then
       begin
         fifo.Push(S);
         msk:=(S^ and $ff000000);
         S^ := 2 + msk;
         //if(Iq[k]^<>BOARDER) then
         //Iq[k]^:=clYellow32;
         //S^:=clYellow32;
         break;
       end;
     end;
      inc(S);
  end;
  // exit;

////////////////////////////////////////
//????????? ?????????
///////////////////////////////////////

  while fifo.Count<>0 do
  begin
   pI:=fifo.Pop;
   if (pI^=BOARDER) then continue;
   //??????? ??????
   Iq[0]:=PColor32(Integer(pI)-stribe);
   Iq[1]:=Iq[0]; dec(Iq[1]);
   Iq[2]:=Iq[0]; inc(Iq[2]);
   //??????? ??????
   Iq[3]:=pI; dec(Iq[3]);
   Iq[4]:=pI; inc(Iq[4]);
   //?????? ??????
   Iq[5]:=PColor32(Integer(pI)+stribe);
   Iq[6]:=Iq[5]; inc(Iq[6]);
   Iq[7]:=Iq[5]; dec(Iq[7]);
      ///???? ?? ???????
   for k:=0 to 7 do
   begin
     if (Iq[k]^ = 1) then
     begin
     ///////////////////
     //(Iq[k]^:=pI^ + 1)
     ////////////////////
         msk:= (S^ and $ff000000);
         Iq[k]^:= (pI^ and $0000FFFF) + 30 + msk;
         if (Iq[k]^>255) then Iq[k]^:=255;
         //Iq[k]^:=clgreen32;
         fifo.Push(Iq[k]);
     end;
   end;
 end;
 fifo.Free;
// GetDistanceProj(In_Out_bmp,true);
end;

////////////////////////////////////////////////////////////////////
//???????? ??????? ????????? ?? X ? Y
//???? - ??????????? ?????????, ????? - ????????
//????????? ?? ??????? ???????????
////////////////////////////////////////////////////////////////////

procedure GetDistanceProj(src:PBitmap32; bDrawProj:boolean);
var SumX,SumY:array of integer;
    j, i, wd, hg, sum: integer;
    S: PColor32;
begin
  SetLength(SumX,src.Height);
  SetLength(SumY,src.Width);
{
   (*????? ????????*)
  //scan line
  for j:=0 to src.Height-1 do
  begin
    S:=@src^.Bits[j*src.width];
    SumX[j]:=sum;
    sum:=0;
    for i:=0 to src.Width-1 do
      if ((S[i] and BG)<>BG) then
       sum:=sum+((S[i] and $000FFFF));
  end;
  sum:=0;
  //scan row
  for i:=0 to src.Width-1 do
  begin
    SumY[i]:=sum;
    sum:=0;
    for j:=0 to src.Height-1 do
    begin
      if ((S[i] and BG)<>BG) then
      begin
        S:=@src^.Bits[j*src.width];
        sum:=sum+((S[i] and $000FFFF));
      end;
    end;
  end;
}
   for j:=0 to src.Height-1 do
   begin
     S:=src.PixelPtr[0,j];
     for i:=0 to src.Width-1 do
     begin
       if ((S^ and BG)<>BG) then
       begin
         SumX[j]:=SumX[j] + S^;
         SumY[i]:=SumY[i] + S^;
       end;
       inc(S);
     end;
  end;

  (*?????*)
{    for i:=0 to src.Width-1 do //src.Width-1 do
     SumY[i];
    for j:=0 to src.Height-1 do
     SumX[j];
 }
  (* ?????? ????????*)
  if(bDrawProj)then
  begin
    for i:=0 to src.Width-1 do //src.Width-1 do
     src^.LineS(i,0,i,SumY[i],clred32);
//    for j:=0 to src.Height-1 do
//     src^.LineS(0,j,SumX[j],j,clred32);
  end;

end;

end.

