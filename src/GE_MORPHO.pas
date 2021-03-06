//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//?????: ???????? ???????
//wwww@sknt.ru ~ vdbar@rambler.ru
//????????? ??????????????? ????????
//GE_MORPHO.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_MORPHO;

interface

uses
  GR32, Classes, Math, Contnrs, QCKSRT;

const
  BOARDER  = $66666666;

  procedure MorphoErode(In_bmp,Out_bmp:PBitmap32);
  procedure MorphoDilate(In_bmp,Out_bmp:PBitmap32);
  procedure MorphoDilateEx(In_bmp,Out_bmp:PBitmap32);
  procedure MorphoOpen_Close(In_bmp,Out_bmp:PBitmap32; N:integer);
  procedure FastMorphoGrad(In_bmp,Out_bmp:PBitmap32);
  procedure MorphoOpening(In_bmp,Out_bmp:PBitmap32; N:integer);
  procedure MorphoCloasing(In_bmp,Out_bmp:PBitmap32; N:integer);
  procedure FastGreyReconstr(Mask_bmp,Marker_bmp:PBitmap32; Max_iterations:integer);
  procedure ReconstrBugFix(In_bmp:PBitmap32; bg_color:TColor32);
  procedure LabelBoarders(In_bmp:PBitmap32);

implementation

procedure MMX_1(col:TColor32);
asm
  //movq mm5,col;
  Pcmpeqb mm2,mm0 ;
  MAXSS xmm0, xmm1 ;
   {      asm
         mov  esi,p_J
         mov  edx,p_I
         MOVUPS xmm0,[esi] //; ???????? ?????? ???? ???????? ?????
         MOVUPS xmm1,[edx]
         //PMINSW mm1, mm0
         SUBPS xmm0,xmm1
         //psubw mm0,mm1
         mov  esi,D
         MOVUPS [esi], xmm0//xmm0 //; ?????? ??? ?? ????? (? ??????????)
       end;
 }

  EMMS;
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

////////////////////////////////////////////////////////////////////
//??????????? ????????????? (?? ????????? Luc Vincent)
////////////////////////////////////////////////////////////////////

procedure FastGreyReconstr(Mask_bmp,Marker_bmp:PBitmap32; Max_iterations:integer);
var  fifo:TQueue;
     JJ,II:PColor32;
    _max,_min,i,j,k,m,l,wd,hg:integer;
     p_J,p_I,S:PColor32; //p from quenue
     Iq,Jq:array[0..7] of PColor32;//8 ??????? p
     ptr_0_I,ptr_0_J,ptr_lst_I:PColor32;//????????? ?? ?????? ? ????????? ??????
     d_0,d_lst:Integer; //?????????? ?? ??????? ? ?????????? ????????? (???????)
     stribe,x_offset,x_offset2:Integer; //1 ?????? ??????? ? ??????

     s1,d1,s2,d2:PColor32;
begin
 fifo:=TQueue.Create;

 LabelBoarders(Mask_bmp);
 LabelBoarders(Marker_bmp);

 wd:=Mask_bmp.Width;
 hg:=Mask_bmp.Height;
 //fifo.Capacity:=Mask_bmp.Width*Mask_bmp.Height;

  //????? ????????? ?? ?????? ? ?????? ??????
 ptr_0_I:=Mask_bmp.PixelPtr[0,0];
 ptr_0_J:=Marker_bmp.PixelPtr[0,0];
 p_I:=ptr_0_I;
 p_J:=ptr_0_J;

 ptr_lst_I:=Mask_bmp.PixelPtr[Mask_bmp.Width,Mask_bmp.Height];
 stribe:=Mask_bmp.width*4;

 //Scan D1 in raster order
 for j:=0 to wd*hg - 1 do
 begin

      if p_I^=BOARDER then begin inc(p_I); inc(p_J); continue; end;
      (*????? ???????  N+*)
      Iq[0]:=PColor32(Integer(p_I)-stribe);
      Iq[1]:=Iq[0]; dec(Iq[1]);
      Iq[2]:=Iq[0]; inc(Iq[2]);
      Iq[3]:=p_I; dec(Iq[3]);

      Jq[0]:=PColor32(Integer(p_J)-stribe);

      Jq[1]:=Jq[0]; dec(Jq[1]);
      Jq[2]:=Jq[0]; inc(Jq[2]);
      Jq[3]:=p_J; dec(Jq[3]);

      //???? ?? ???????
     _max:=0;
      for k:=0 to 3 do
      begin
        if (Jq[k]^=clblue32) then continue;
        if ((Jq[k]^ and 255)>_max) then _max:=(Jq[k]^ and 255);
      end;
      _max:=Min(_max,(p_I^ and 255));
      p_J^:=Color32(_max,_max,_max);

   inc(p_I); inc(p_J);
 end;

     //??????????? ?????
(*  d1:=Marker_bmp.PixelPtr[0,0];
  s1:=Marker_bmp.PixelPtr[0,1];
  d2:=Marker_bmp.PixelPtr[0,(Marker_bmp.Height-1)];
  s2:=Marker_bmp.PixelPtr[0,(Marker_bmp.Height-2)];
   for i:=0 to Marker_bmp.Width-1 do
   begin
     d1^:=s1^; d2^:=s2^;
     inc(d1); inc(d2); inc(s1); inc(s2);
   end;
  //??????????? ????????
  for i:=0 to Marker_bmp.Height-1 do
  begin
    Marker_bmp.PixelPtr[0,i]^:=Marker_bmp.PixelPtr[1,i]^;
    Marker_bmp.PixelPtr[Marker_bmp.Width-1,i]^:=Marker_bmp.PixelPtr[Marker_bmp.Width-2,i]^;
  end;
*)

 p_I:=ptr_0_I;
 p_J:=ptr_0_J;
  //Scan D1 in anti-raster order
 for j:=wd*hg-1 downto 0 do
 begin
       //if (p_I^=clwhite32) then begin dec(p_I); dec(p_J); continue; end;
      if p_I^=BOARDER then begin inc(p_I); inc(p_J); continue; end;
       //????? ???????  N-
      Iq[4]:=p_I; inc(Iq[4]);
      Iq[5]:=PColor32(Integer(p_I)+stribe);
      Iq[6]:=Iq[5]; dec(Iq[6]);
      Iq[7]:=Iq[5]; inc(Iq[7]);
      Jq[4]:=p_J; inc(Jq[4]);
      Jq[5]:=PColor32(Integer(p_J)+stribe);
      Jq[6]:=Jq[5]; inc(Jq[6]);
      Jq[7]:=Jq[5]; dec(Jq[7]);

      //???? ?? ???????
      _max:=0;
      for k:=4 to 7 do
      begin
        //q:=(Integer(q8[i])-Integer(ptr_0))shr 2;

        if ((Jq[k]^ and 255)>_max) then _max:=(Jq[k]^ and 255);

        if(((Jq[k]^ and 255)<(p_J^ and 255) ) and
           ((Jq[k]^ and 255)<(Iq[k]^ and 255)) )then
        begin
          //if p_I^<>BOARDER then
            fifo.Push(p_I);
        end;

      end;
      _max:=Min(_max,(p_I^ and 255));
      p_J^:=Color32(_max,_max,_max);

      dec(p_I); dec(p_J);
 end;

 ///////////
 //fifo.Free;//////////
 //exit;///////////////////////////

   //Propagation step:
   i:=0;
   while fifo.Count<>0 do
   begin
      p_I:=fifo.Pop;
      if p_I^=BOARDER then continue;
     //???????? ??????

      //////////////////////////
      //????? ???????
      //////////////////////////
      //??????? ??????
      Iq[0]:=PColor32(Integer(p_I)-stribe);
      Iq[1]:=Iq[0]; dec(Iq[1]);
      Iq[2]:=Iq[0]; inc(Iq[2]);
      //??????? ??????
      Iq[3]:=p_I; dec(Iq[3]);
      Iq[4]:=p_I; inc(Iq[4]);
      //?????? ??????
      Iq[5]:=PColor32(Integer(p_I)+stribe);
      Iq[6]:=Iq[5]; inc(Iq[6]);
      Iq[7]:=Iq[5]; dec(Iq[7]);

      //????????? p_J ?? ????????? p_I
      d_0:=Integer(p_I)-Integer(ptr_0_I);
      d_0:=(Integer(p_I)-Integer(ptr_0_I));
      p_J:=PColor32(Integer(ptr_0_J)+d_0);

      Jq[0]:=PColor32(Integer(p_J)-stribe);
      Jq[1]:=Jq[0]; dec(Jq[1]);
      Jq[2]:=Jq[0]; inc(Jq[2]);
      //??????? ??????
      Jq[3]:=p_J; dec(Jq[3]);
      Jq[4]:=p_J; inc(Jq[4]);
      //?????? ??????
      Jq[5]:=PColor32(Integer(p_J)+stribe);
      Jq[6]:=Jq[5]; inc(Jq[6]);
      Jq[7]:=Jq[5]; dec(Jq[7]);
      //???? ?? ???????
      for k:=0 to 7 do
      begin
        if(((Jq[k]^ and 255)<(p_J^ and 255) ) and
           ((Iq[k]^ and 255)<>(Jq[k]^ and 255)) )then
        begin
          _min:=Min(p_J^ and 255,Iq[k]^ and 255);
          Jq[k]^:=Color32(_min,_min,_min);
          fifo.Push(Iq[k]);
        end;
      end;

     //??????? ?? ?????????
     inc(i);
     if (i>Max_iterations*100) then
     begin
      //fifo.Free;
      //exit;
      break;
     end;
   end;

   fifo.Free;

end;

//////////////////////////////////////////////////////
/////////////////////////////////////////////////////
//RECONSTRUCTION BUG FIX ALGO (based on pixel serias)
/////////////////////////////////////////////////////

procedure ReconstrBugFix(In_bmp:PBitmap32; bg_color:TColor32);
type
  PixSeria = record
    i:integer;
    val:integer;
    len:integer;
  end;
  PPixSeria=^PixSeria;

const MAX_SERIA_LEN = 20;
      STRIBE = 4;

var
     SeriasList:TList;
     Gist,RemVal:array of integer;
     pSer:^PixSeria;
     CurSer:PixSeria;
     Val,j,i,k:integer;
     S,ptr_0: PColor32;

begin
  if (In_bmp=nil) then exit;

{ SeriasList:=TList.Create;
  //init 1 pix
  S:=In_bmp.PixelPtr[0,0];
  Val:=S^ and 255;
  inc(S);
  //BUILD SERIASLIST  (scanning image)
  k:=0;
  for j:=0 to In_bmp.Height*In_bmp.Width-2 do
  begin
    if ((S^ and 255)=Val) then inc(k)
    else
    begin
      if (k>MAX_SERIA_LEN) then
      begin
       New(pSer);
       pSer.i:=j-k;
       pSer.val:=Val;
       //S^:=clred32;
       pSer.len:=k;
       SeriasList.Add(pSer);
      end;
      k:=0;
    end;
    Val:=S^ and 255;
    inc(S);
  end;


  //?????? ??????????? ?????
  SetLength(Gist,256);
  for i:=0 to SeriasList.Count-1 do
  begin
     Val:=PPixSeria(SeriasList.Items[i]).val;
     k:=PPixSeria(SeriasList.Items[i]).len;
     Gist[Val]:=Gist[Val]+k;
  end;
}

//?????? ??????? ???????????
   SetLength(Gist,256);
   S:=In_bmp.PixelPtr[0,0];
    for j:=0 to In_bmp.Height*In_bmp.Width-2 do
    begin
      inc(Gist[S^ and 255]);
      inc(S);
    end;

  //?????? ?????? ??????\????? ??????
  for i:=0 to 10 do Gist[i]:=0;
  //??? 3-4 ????????? ? ??????????? ?????
  SetLength(RemVal,5);
  for j:=0 to 4 do
  begin
   k:=MaxIntValue(Gist);
   for i:=0 to 255 do
   if(Gist[i]=k)then
   begin
    RemVal[j]:=i;
    Gist[i]:=0;
   end;
  end;

  //??????? ??????? ?????? ??????? \ ?????????? ??? ^
    S:=@In_bmp.Bits[0];
    Val:=S^ and 255;
    for j:=0 to In_bmp.Height*In_bmp.Width-2 do
    begin
      if((S^ and 255)=RemVal[0]) then//or ((S^ and 255)=RemVal[1]) then //or ((S^ and 255)=RemVal[1]) then //or (S^ and 255=RemVal[2]) then// or (S^ and 255=RemVal[1]) or (S^ and 255=RemVal[2]) then
       S^:=bg_color;
      inc(S);
    end;


//?????? ?????
{    ptr_0:= In_bmp.PixelPtr[0,0];
    for j:=0 to SeriasList.Count-1 do
    begin
       val:=PPixSeria(SeriasList.Items[j]).val;
       if (val=RemVal[0]) or (val=RemVal[1]) or (val=RemVal[2]) then
       begin
         k:=PPixSeria(SeriasList.Items[j]).len;
         i:=PPixSeria(SeriasList.Items[j]).i - 1;
         S:=PColor32(Integer(ptr_0) + i*STRIBE);
         while k>0 do
         begin
           S^:=bg_color;
           dec(k); inc(S);
         end;
       end;
    end;
    SeriasList.Free;
}

end;

////////////////////////////////////////////////////////////////////
//??????????????? ??????????
////////////////////////////////////////////////////////////////////

procedure MorphoErode(In_bmp,Out_bmp:PBitmap32);
var src, dst:PBitmap32;
    i,j,k,m:integer; SUP,SDOWN,SC,DC: PColor32Array; MIN:TColor32;
    s1,d1,s2,d2:PColor32;
begin
  src:=In_bmp;
  dst:=Out_bmp;
  for j:=1 to src.Height-2 do
  begin
      SUP:=@src^.Bits[(j-1)*src.Width];
      SC:=@src^.Bits[j*src.Width];     //center line of active element
      SDOWN:=@src^.Bits[(j+1)*src.Width]; //down line -#-
      DC:=@dst^.Bits[j*dst.Width];
      for i:=1 to src.Width-2 do
      begin
      {  asm
           //maximum positive and negative differences
          movq    mm3, pos_D8
          movq    mm2, neg_D8
          pmaxub    mm3, mm0
          pmaxub    mm2, mm1
          movq    pos_D8, mm3
          movq    neg_D8, mm2
        end;}

        MIN:=SUP[i-1] and 255;//find min value in window (by red component)
        for k:=1 to 2 do
          if((SUP[i-1+k] and 255)<MIN)then MIN:=SUP[i-1+k] and 255;
        for k:=0 to 2 do
          if((SC[i-1+k] and 255)<MIN)then MIN:=SC[i-1+k] and 255;
        for k:=0 to 2 do
          if((SDOWN[i-1+k] and 255)<MIN)then MIN:=SDOWN[i-1+k] and 255;
        DC[i]:=Color32(MIN,MIN,MIN);
      end;
  end;
      //??????????? ?????
  d1:=dst.PixelPtr[0,0];
  s1:=dst.PixelPtr[0,1];
  d2:=dst.PixelPtr[0,(src.Height-1)];
  s2:=dst.PixelPtr[0,(src.Height-2)];
   for i:=0 to src.Width-1 do
   begin
     d1^:=s1^; d2^:=s2^;
     inc(d1); inc(d2); inc(s1); inc(s2);
   end;
  //??????????? ????????
  for i:=0 to src.Height-1 do
  begin
    dst.PixelPtr[0,i]^:=dst.PixelPtr[1,i]^;
    dst.PixelPtr[src.Width-1,i]^:=dst.PixelPtr[src.Width-2,i]^;
  end;

end;

procedure MorphoDilate(In_bmp,Out_bmp:PBitmap32);
var src, dst:PBitmap32;
    i,j,k,m:integer; SUP,SDOWN,SC,DC: PColor32Array; MAX:byte;
   s1,d1,s2,d2:PColor32;
begin
  src:=In_bmp;
  dst:=Out_bmp;
    for j:=1 to src.Height-2 do
    begin
      SUP:=@src^.Bits[(j-1)*src.Width];
      SC:=@src^.Bits[j*src.Width];     //center line of active element
      SDOWN:=@src^.Bits[(j+1)*src.Width]; //down line -#-
      DC:=@dst^.Bits[j*dst.Width];
      for i:=1 to src.Width-2 do
      begin
        MAX:=0;//find min value in window (by red component)
        for k:=1 to 2 do
          if((SUP[i-1+k] and 255)>MAX)then MAX:=SUP[i-1+k] and 255;
        for k:=0 to 2 do
          if((SC[i-1+k] and 255)>MAX)then MAX:=SC[i-1+k] and 255;
        for k:=0 to 2 do
          if((SDOWN[i-1+k] and 255)>MAX)then MAX:=SDOWN[i-1+k] and 255;
        DC[i]:=Color32(MAX,MAX,MAX);
      end;
   end;

  //??????????? ?????
  d1:=dst.PixelPtr[0,0];
  s1:=dst.PixelPtr[0,1];
  d2:=dst.PixelPtr[0,(src.Height-1)];
  s2:=dst.PixelPtr[0,(src.Height-2)];
   for i:=0 to src.Width-1 do
   begin
     d1^:=s1^; d2^:=s2^;
     inc(d1); inc(d2); inc(s1); inc(s2);
   end;
  //??????????? ????????
  for i:=0 to src.Height-1 do
  begin
    dst.PixelPtr[0,i]^:=dst.PixelPtr[1,i]^;
    dst.PixelPtr[src.Width-1,i]^:=dst.PixelPtr[src.Width-2,i]^;
  end;


end;

////////////////////////////////////////////////////////////////////
//??????????????? ????????, N-???-?? ?????? ??????????? ????????? 3x3
////////////////////////////////////////////////////////////////////
procedure MorphoOpening(In_bmp,Out_bmp:PBitmap32; N:integer);
var src, dst:PBitmap32;
    i,j,k,m:integer;
    Buffer:TBitmap32; p:PColor32; new_val:integer;
begin
  Buffer:=TBitmap32.Create;
  Buffer.SetSize(In_bmp.Width,In_bmp.Height);
  In_bmp.DrawTo(Buffer);
  src:=@Buffer;
  dst:=Out_bmp;
{  //???????? h ??? ?????????????
  p:=@src^.Bits[0];
  for j:=1 to src.Height*src.Width-1 do
  begin
    new_val:=(p^ and 255)-10;
    if new_val<0 then new_val:=0;
    p^:=Color32(new_val,new_val,new_val);
    inc(p);
  end;}
  //????????
  for m:=0 to N do
  begin
     MorphoDilate(src,dst);
     dst.Drawto(src^);
     //MorphoDilate(src,dst);
  end;
  Buffer.Free;
end;


////////////////////////////////////////////////////////////////////
//??????????????? ????????, N-???-?? ?????? ??????????? ????????? 3x3
////////////////////////////////////////////////////////////////////
procedure MorphoCloasing(In_bmp,Out_bmp:PBitmap32; N:integer);
var src, dst:PBitmap32;
    i,j,k,m:integer;
    Buffer:TBitmap32; p:PColor32; new_val:integer;
begin
  Buffer:=TBitmap32.Create;
  Buffer.SetSize(In_bmp.Width,In_bmp.Height);
  In_bmp.DrawTo(Buffer);
  src:=@Buffer;
  dst:=Out_bmp;
  for m:=0 to N do
  begin
     MorphoErode(src,dst);
     dst.Drawto(src^);
  end;
  Buffer.Free;
end;

procedure MorphoOpen_Close(In_bmp,Out_bmp:PBitmap32; N:integer);
var src, dst:PBitmap32;
    i,j,k,m:integer;
    Buffer:TBitmap32; p:PColor32; new_val:integer;
begin
  Buffer:=TBitmap32.Create;
  Buffer.SetSize(In_bmp.Width,In_bmp.Height);
  In_bmp.DrawTo(Buffer);
  src:=@Buffer;
  dst:=Out_bmp;
  for m:=0 to N do
  begin
     MorphoErode(src,dst);
     dst.Drawto(src^);
  end;
  for m:=0 to N do
  begin
     MorphoDilate(dst,src);
     src.Drawto(dst^);
  end;
  dst.Drawto(src^);
  Buffer.Free;
end;

////////////////////////////////////////////////////////////////////
//MULTISCALE GRADIENT, N-???-?? ?????? ??????????? ????????? 3x3
////////////////////////////////////////////////////////////////////

procedure FastMorphoGrad(In_bmp,Out_bmp:PBitmap32);

    procedure minmax(const cl:TColor32; var _min,_max:Word);
    begin
         if ((cl and 255)<_min) then
         begin
           _min:=(cl and 255)
         end
        else
        if((cl and 255)>_max) then
           _max:=(cl and 255);
    end;

var i,j,k,m:integer;
    min33,min55,min77:Word;
    max33,max55,max77:Word;
    MorphoGrad:Word;
    //Mask:array[0..5,0..5] of boolean;
    src_ln:array[0..6] of PColor32Array;
    dst_line,src_line:PColor32Array;
    tmp:PColor32Array;
begin

 for j:=0 to In_bmp.Height-8 do
 begin
   //???? ????????? ?? 6 ?????
   for k:=0 to 6 do
     src_ln[k]:=@In_bmp^.Bits[(j+k)*In_bmp.Width];
   //????? ??????????? ????????? [-][-][-][-]
   dst_line:=@Out_bmp^.Bits[(3+j)*Out_bmp.Width];
   //?????? ??????. ??????? ?? ?????? []--->[]
   for i:=0 to In_bmp.Width-6 do
   begin
   //????? min\max
     //? ???? 3x3 (?????)
     min33:=255;   max33:=0;
     for k:=2 to 4 do
     for m:=2 to 4 do minmax(src_ln[k][m+i],min33,max33);
     //? ???? 5x5
     min55:=min33;   max55:=max33;
     for k:=1 to 5 do minmax(src_ln[k][1+i],min55,max55);
     for k:=1 to 5 do minmax(src_ln[1][k+i],min55,max55);
     for k:=1 to 5 do minmax(src_ln[k][5+i],min55,max55);
     for k:=1 to 5 do minmax(src_ln[5][k+i],min55,max55);
     //? ???? 7x7
     min77:=min55;   max77:=max55;
     for k:=0 to 6 do minmax(src_ln[k][0+i],min77,max77);
     for k:=0 to 6 do minmax(src_ln[0][k+i],min77,max77);
     for k:=0 to 6 do minmax(src_ln[k][6+i],min77,max77);
     for k:=0 to 6 do minmax(src_ln[6][k+i],min77,max77);
     //?????
     MorphoGrad:=max33-min33;//(max77-min77+max55-min55+max33-min33) div 3;//max33-min33;
     MorphoGrad:=255-MorphoGrad;
     dst_line[i]:=Color32(MorphoGrad,MorphoGrad,MorphoGrad);
   end;
 end;


end;

//////////////////////////////////
//parametric DILATE
//////////////////////////////////

procedure MorphoDilateEx(In_bmp,Out_bmp:PBitmap32);
    procedure minmax(const cl:TColor32; var _min,_max:Word);
    begin
         if ((cl and 255)<_min) then
         begin
           _min:=(cl and 255)
         end
        else
        if((cl and 255)>_max) then
           _max:=(cl and 255);
    end;

var i,j,k,m:integer;
    min33,min55,min77:Word;
    max33,max55,max77:Word;
    Val:Word;
    //Mask:array[0..5,0..5] of boolean;
    src_ln,dst_ln:array[0..6] of PColor32Array;
    dst_line,src_line:PColor32Array;
    tmp:PColor32Array;
    bg: TColor32;
begin

 //In_bmp.DrawTo(Out_Bmp^);
 bg:=In_bmp.Pixel[20,20];

 //for j:=0 to In_bmp.Height-8 do
 j:=0;
 while j<In_bmp.Height-8 do
 begin
   //???? ????????? ?? 6 ?????
   for k:=6 downto 0 do
   begin
     src_ln[k]:=@In_bmp^.Bits[(j+k)*In_bmp.Width];
     dst_ln[k]:=@Out_bmp^.Bits[(j+k)*In_bmp.Width];
   end;
   //????? ??????????? ????????? [-][-][-][-]
   dst_line:=@Out_bmp^.Bits[(3+j)*Out_bmp.Width];
   //?????? ??????. ??????? ?? ?????? []--->[]
   for i:=0 to In_bmp.Width-6 do
   begin
   //????? min\max
   //? ???? 7x7
    min77:=255;   max77:=0;
    for k:=0 to 6 do minmax(src_ln[k][i],min77,max77);
    dst_line[i]:=Color32(max77,max77,max77);

{     if (src_ln[0][i] = bg) and (src_ln[3][i] = bg) then
       for k:=0 to 3 do dst_ln[k][i]:=bg; // dst_ln[k][i]:=clgreen32;
 }
   end;
   j:=j+1;
 end;


end;


end.
















