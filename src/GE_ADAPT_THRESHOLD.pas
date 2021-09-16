//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//Автор: Владимир Баранов
//wwww@sknt.ru ~ vdbar@rambler.ru
//Адаптивный порог
//GE_ADAPT_THRESHOLD.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_ADAPT_THRESHOLD;

interface

uses
  GR32, Classes, Math, Contnrs, QCKSRT;

  procedure AdaptiveThresold(In_1,In_2,In_3,dst:PBitmap32; t:integer);
//  procedure

implementation


procedure AdaptiveThresold(In_1,In_2,In_3,dst:PBitmap32; t:integer);
var D,S1,S2,S3:PColor32;  i,j,k,m,hg,wd,max:integer;
    nrm:Double;
    val:Longint;
    A,B,Au,Bu,Ad,Bd:PColor32;
    src1_ln,src2_ln,src3_ln:array[0..2] of PColor32Array;
    dst_line:PColor32Array;

begin
  hg:=In_1.Height;
  wd:=In_2.Width;
  max:=1;
//умножение In1*In2 результат напрямую (4 байта)
  max:=0;
  S1:=@In_1^.Bits[0];
  S2:=@In_2^.Bits[0];
  S3:=@In_3^.Bits[0];
  D:=@dst^.Bits[0];
  for i:=0 to In_1.Width*In_1.Height-1 do
  begin

    D^:=(S1^ and 255) * (S2^ and 255)*(S3^ and 255);
    if(D^>max) then max:=D^;
    inc(S1); inc(S2); inc(S3); inc(D);
  end;


//умножение 2 /////////////////////////////////

{ for j:=1 to hg-2 do
  begin
   //беру указатели на 3 строк
   for k:=2 downto 0 do
   begin
     src1_ln[k]:=@In_1^.Bits[(j+k)*In_1.Width];
     src2_ln[k]:=@In_2^.Bits[(j+k)*In_1.Width];
     //src3_ln[k]:=@In_3^.Bits[(j+k)*In_1.Width];
   end;
   //линия центральных элементов [-][-][-][-]
   dst_line:=@dst^.Bits[(1+j)*dst.Width];
    //цикл по строкам
    for i:=1 to wd-2 do
    begin
     val:=1;
     for k:=0 to 2 do
     for m:=0 to 2 do
     begin
{       if ((k=0) and (m=0)) or
          ((k=0) and (m=2)) or
          ((k=2) and (m=0)) or
          ((k=2) and (m=2)) or
          ((k=1) and (m=1))
       then continue;

       val:=val + (src1_ln[k][m+i] and 255)*(src2_ln[k][m+i] and 255);//*(src3_ln[k][m+i] and 255);
     end;
      //val:=src1_ln[1][1+i]*src2_ln[1][1+i];
      dst_line[i]:=val;
      if(val>max) then max:=val;
      //inc(S); inc(Su); inc(Sd);
    end;
  end;
}  
  D:=@dst^.Bits[0];
  for i:=0 to In_1.Width*In_1.Height-1 do
  begin
    //порог
    if (D^<t*100) then D^:=0;
    //нормализация
    nrm:=Power((D^/max),0.6)*255;
    k:=Round(nrm);
    D^:=Color32(k,k,k);
    inc(D);
  end;


end;



end.


