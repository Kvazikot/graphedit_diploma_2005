procedure CA_Lava(pIn,pOut:PBitmap32);
var i,j,k,m:integer;
    Buffer:TBitmap32;
    pBuf,pTmp:PBitmap32;
    src,dst:array[0..2] of PColor32Array; //block
    bSurv, bBirth:array[0..8] of byte;
    Generations:integer;
    sum:integer;
begin
 Buffer:=TBitmap32.Create;
 Buffer.Assign(pOut^);
 pBuf:=@Buffer;
 //RULES LAVA SETUP
  FillChar(bSurv,8,0);
  FillChar(bBirth,8,0);
  for k:=1 to 5 do bSurv[k]:=1;
  for k:=4 to 8 do bBirth[k]:=1;
 Generations:=0;
 //MAIN LOOP
 while Generations<210 do
 begin
   for j:=0 to pIn.Height-8 do
   begin
     //беру указатели на 3 строки
     for k:=0 to 2 do
     begin
       src[k]:=@pOut^.Bits[(j+k)*pIn.Width];
       dst[k]:=@pBuf^.Bits[(j+k)*pIn.Width];
     end;
     //двигаю блок по строке []--->[]
     for i:=0 to pIn.Width-6 do
     begin
       sum:=0;
       //обход клеток блока [<^>]
       for k:=0 to 2 do
       for m:=0 to 2 do
       begin
         //подсчет соседей (бинариз.)
         if (k=1) and (m=1) then continue; //искл.
         //sum:=sum+(src[k][i+m] and 255);
         if (src[k][i+m] and 255)>40 then inc(sum);
       end;
       //выживает
       if (src[1][i+1] and 255)>40 then
         if (sum=0) or (sum>5) then dst[1][i+1]:=clBlack32
         else dst[1][i+1]:=src[1][i+1]
       //рождается
       else
         if (sum>=4) or (sum<=8) then dst[1][i+1]:=clWhite32
         else dst[1][i+1]:=src[1][i+1]
     end;
   end;
   inc(Generations);
   pTmp:=pBuf;
   pBuf:=pOut;
   pOut:=pTmp;
   end;
end;
