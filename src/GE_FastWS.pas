//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//Автор: Владимир Баранов
//wwww@sknt.ru ~ vdbar@rambler.ru
//Быстрые водоразделы
//GE_FastWS.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_FastWS;

interface

uses
  GR32, Classes, Math, QCKSRT, Contnrs, GE_MORPHO ;

  procedure FastWatershed(In_bmp,Out_bmp:PBitmap32);

implementation

type

  TPixelPtr=record
    ptr:PColor32;
  end;
  PPixelPtr = ^TPixelPtr;

var
      f:Textfile;

procedure FastWatershed(In_bmp,Out_bmp: PBitmap32);
const
     WSHED = $00000000;
     INIT = $10000000;
     MASK = $20000000;
     INQUEUE = $30000000;
     SHR_MASK = 24;
var
    Isrt:               array of TPixelPtr; //sorted pixel pointers
    Isrt_idx:           array[0..256] of Longint; //indexes for sorting
    Imd:                array of array of TColor32; //image of distance
    pIsrt,pIsrt_0:              PPixelPtr;
    hg,wd,i,idx,k, h, hmax, hmin:      integer;
    S,D,Su,Sd:          PColor32; //temp pointers
    pfict_pixel:        Pointer; //левый пиксел
    flag:               boolean;
    Histogram:          array of Longint;
    current_label,current_dist:integer;
    fifo:               TQueue;
 //УКАЗАТЕЛИ
    pImi,pImo,pImd:     PColor32; //pointers to Imi and Imo
    qImi,qImo,qImd:     array[0..7] of PColor32;//8 соседей pImi и pImo
    d_0,d_lst:          Integer; //расстояния до первого и последнего указателя (пиксела)
    pImi_0,pImi_lst,pImd_0,pImd_lst,pImo_0,pImo_lst:PColor32; //указатели на первый и последний пиксел
    stribe,x_offset:    Integer; //одна строка битмапа в байтах
begin

/////////////////////////////////
//      инициализация
/////////////////////////////////

  current_label:=0;
  flag:=false;
  pfict_pixel:=ptr($11111111);
  hg:=In_bmp.Height;
  wd:=In_bmp.Width;

  //init Im0 to INIT value
  S:=@Out_bmp.Bits[0];
  for i:=0 to hg*wd - 1 do
  begin
    S^:=INIT; inc(S);
  end;

  LabelBoarders(In_bmp);
  LabelBoarders(Out_bmp);

  SetLength(Isrt,wd*hg + 10);
  SetLength(Imd,wd*hg + 10);
  SetLength(Histogram,259);
  fifo:=TQueue.Create;

//////////////////////////////////////////////////
//    1 этап: Сортировка указателей на пикселы
//////////////////////////////////////////////////

//строим распределение (1-ое сканирование)
 S:=@In_bmp.Bits[0];
 for i:=0 to hg*wd - 1 do
 begin
  // if S^=BOARDER then begin inc(S); continue; end;
   inc(Histogram[S^ and 255]);
   inc(S);
 end;

 //инициализируем индексы для сортировки
 idx:=0;
 for i:=0 to 255 do
 begin
  if(Histogram[i]<>0) then
  begin
   Isrt_idx[i]:=idx;
   idx:=idx+Histogram[i];
  end;
 end;

 //сортировка (2-ое сканирование)
 S:=@In_bmp.Bits[0];
 for i:=0 to hg*wd - 1 do
 begin
   //if S^=BOARDER then begin inc(S); continue; end;
   Isrt[Isrt_idx[S^ and 255]].ptr:=S;
   inc(Isrt_idx[S^ and 255]);
   inc(S);
 end;
 
 ///вывод в Out_bmp отсортированных пикселей
{ pIsrt:=@Isrt[0];
 D:=@Out_bmp.Bits[0];
 for i:=0 to hg*wd - 1 do
 begin
   if(pIsrt.ptr<>nil) then
   D^:=pIsrt^.ptr^;
   inc(D); inc(pIsrt);
 end; }
//exit;
//////////////////////////////////////////////
//      2 этап: Флудинг (затопление)
///////////////////////////////////////////////
  pImi_0:=In_bmp.PixelPtr[0,0];
  pImo_0:=Out_bmp.PixelPtr[0,0];
  pImi_lst:=In_bmp.PixelPtr[wd,hg];
  pImo_lst:=Out_bmp.PixelPtr[wd,hg];
  stribe:=wd*4;
  pIsrt:=@Isrt[0];
  hmin:=Isrt[0].ptr^ and 255;
  i:=hg*wd;
  while (Isrt[i].ptr=nil) do dec(i);
  hmax:=Isrt[i].ptr^ and 255;
//FOR hmin -> hmax
 for h:=hmin to hmax do
 begin
   pIsrt_0:= pIsrt; //первый пиксел текущего уровня h
   if (pIsrt.ptr<>nil) then
   while ((pIsrt.ptr^ and 255) = h) do
   begin
    //вычисляем соответсвующий пиксел Imo по указателю
    //из отсортированного массива
    d_0:=Integer(pIsrt.ptr)-Integer(pImi_0);
    pImo:=PColor32(Integer(pImo_0)+d_0);
    if pImo^=BOARDER then
    begin
        inc(pIsrt); continue;
   end;
    pImo^:=MASK;
    //проверка выхода за границу
      //////////поиск соседей pImo
      //верхняя строка
      qImo[0]:=PColor32(Integer(pImo)-stribe);
      qImo[1]:=qImo[0]; dec(qImo[1]);
      qImo[2]:=qImo[0]; inc(qImo[2]);
      //средняя строка
      qImo[3]:=pImo; dec(qImo[3]);
      qImo[4]:=pImo; inc(qImo[4]);
      //нижняя строка
      qImo[5]:=PColor32(Integer(pImo)+stribe);;
      qImo[6]:=qImo[5]; inc(qImo[6]);
      qImo[7]:=qImo[5]; dec(qImo[7]);
      ///цикл по соседям
      for k:=0 to 7 do
      begin
        //(qImo[k]^ shr 24) = $FF  заменяет  imo(p) > 0
        if ((qImo[k]^ shr 24) = $FF) or ((qImo[k]^ = WSHED)) then
        begin
          if pImo^<>BOARDER then
          begin
            pImo^:=INQUEUE;
            fifo.Push(pImo);
          end;
        end;
      end;
  inc(pIsrt);
  end;
//-------------------------------------------------

  while fifo.Count<>0 do
  begin
    pImo:=fifo.Pop;
    //проверка выхода за границу
    if pImo^=BOARDER then continue;
    d_0:=Integer(pImo)-Integer(pImo_0);
     //////////поиск соседей pImo
    //верхняя строка
    qImo[0]:=PColor32(Integer(pImo)-stribe);
    qImo[1]:=qImo[0]; dec(qImo[1]);
    qImo[2]:=qImo[0]; inc(qImo[2]);
    //средняя строка
    qImo[3]:=pImo; dec(qImo[3]);
    qImo[4]:=pImo; inc(qImo[4]);
    //нижняя строка
    qImo[5]:=PColor32(Integer(pImo)+stribe);
    qImo[6]:=qImo[5]; inc(qImo[6]);
    qImo[7]:=qImo[5]; dec(qImo[7]);
    //цикл по соседям
    for k:=0 to 7 do
    begin
      if qImo[k]^=BOARDER then continue;

      case (qImo[k]^ shr 24) of

      $FF:  // Imo(p') > 0
       begin
          if( pImo^ = INQUEUE ) or ( (pImo^ = WSHED) and (flag = true) ) then
            pImo^:=qImo[k]^
          else if ((pImo^ shr 24) = $FF) and (pImo^<>qImo[k]^) then
          begin
            pImo^:=WSHED;
            flag:=false;
          end;
       end;

      WSHED shr 24: // Imo(p') = WSHED
       begin
          if (pImo^ = INQUEUE) then
          begin
            pImo^:=WSHED;
            flag:=true;
          end;
       end;

      MASK shr 24: // Imo(p') = MASK
       begin
          if (pImo^ = INQUEUE) then
          begin
            qImo[k]^:=INQUEUE;
            fifo.Push(qImo[k]);
          end;
       end;

     end;//case
    end;//for k:=0 to 7
  end;//while fifo<>empty

//------------------------------------------------------
   pIsrt:= pIsrt_0; //первый пиксел текущего уровня h
   while ((pIsrt.ptr^ and 255) = h) do
   begin
    //вычисляем соответсвующий пиксел Imo по указателю
    //из отсортированного массива
    d_0:=Integer(pIsrt.ptr)-Integer(pImi_0);
    pImo:=PColor32(Integer(pImo_0)+d_0);
    if (pImo^ = MASK) then
    begin
      current_label:=current_label+1;
      fifo.Push(pImo);
      pImo^:=current_label;
      while fifo.Count<>0 do
      begin
        pImo:=fifo.Pop;
         //проверка выхода за границу
        //d_0:=Integer(pImo)-Integer(pImo_0);
        if pImo^=BOARDER then continue;
        //////////поиск соседей pImo
        //верхняя строка
        qImo[0]:=PColor32(Integer(pImo)-stribe);
        qImo[1]:=qImo[0]; dec(qImo[1]);
        qImo[2]:=qImo[0]; inc(qImo[2]);
        //средняя строка
        qImo[3]:=pImo; dec(qImo[3]);
        qImo[4]:=pImo; inc(qImo[4]);
         //нижняя строка
         qImo[5]:=PColor32(Integer(pImo)+stribe);
        qImo[6]:=qImo[5]; inc(qImo[6]);
        qImo[7]:=qImo[5]; dec(qImo[7]);
        //цикл по соседям
        for k:=0 to 7 do
          if(qImo[k]^ = MASK) then
          begin
             fifo.Push(qImo[k]);
             qImo[k]^:=current_label;
          end;
       end;//while
    end;
    inc(pIsrt);
   end;

 end; //for hmin -> hmax
 //------------------------------------------------------

 Assign(f,'LABELS.txt');
 Rewrite(f);
 D:=@Out_bmp.Bits[0];
 S:=@In_bmp.Bits[0];
 for i:=1 to hg*wd - 2 do
 begin
   if(D^<>WSHED) and (D^<>INIT) and (D^<>MASK) and (D^<>INQUEUE) then
   begin
     write(f,',',D^);
     D^:=clred32;
   end
   else D^:=S^;
   inc(D); inc(S);
 end;
 CloseFile(f);

 //FREE MEMORY
 fifo.Free;

end;


end.
