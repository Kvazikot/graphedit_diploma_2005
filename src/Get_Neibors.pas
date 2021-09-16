procedure GetNeibors(S:PColor32);
var 
    src:PBitmap32;//bitmap
    S,S1,S2,S3,S4,S5,S6,S7,S8:PColor32; //8 соседей
    ptr_0,ptr_lst:PColor32; //указатели на первый и последний пиксел
    d_0,d_lst:Integer; //расстояния до первого и последнего указателя (пиксела)
    stribe:Integer; //1 строка битмапа в байтах
begin

 ptr_0:=src.PixelPtr[0,0];
 ptr_lst:=src.PixelPtr[src.Width,src.Height];
 stribe:=src.width*4;

 d_0:=Integer(S)-Integer(ptr_0);
 d_lst:=Integer(ptr_lst)-Integer(S);
 if (d_0)>(stribe+1) then
 begin
   S1:=PColor32(Integer(S)-stribe-1);
   S2:=PColor32(Integer(S)-stribe);
   S3:=PColor32(Integer(S)-stribe+1);
 end;
 if (d_lst)>(stribe+1) then
 begin
   S6:=PColor32(Integer(S)+stribe-1);
   S7:=PColor32(Integer(S)+stribe);
   S8:=PColor32(Integer(S)+stribe+1);
 end;
 dec(d_0);
 dec(d_lst)
 if(d_0<>0) then
   S4:=PColor32(Integer(S)-1);
 if(d_lst<>0) then
   S5:=PColor32(Integer(S)+1);

end;