unit GE_WS;

interface

uses
  GR32, Classes, Math, QCKSRT;

type

 WS_Pixel=record
  // pix:PColor32;//pointer to pixel
   grad:Byte;   //gradient value
  // lab:Longword;//pixel label
   x:integer;
   y:integer;
 end;
 PWS_Pixel = ^WS_Pixel;

  TWatershed=class
  public
    PixelsList:TList;
    In_bmp:PBitmap32;
    Out_bmp:PBitmap32;
    Grad_bmp:PBitmap32; //Gradient image
    Labels:array of array of Longword; //Pixel Labels

    constructor Create(In_bmp,Out_bmp, Grad_bmp:PBitmap32);
    destructor  Destroy; override;
    procedure   CreatePixList;
    procedure   Watershed;
    procedure   Draw;

  end;
    function    PixelCompare(Item1, Item2:Pointer):Integer;



implementation

uses GE_Main;

constructor TWatershed.Create(In_bmp,Out_bmp,Grad_bmp:PBitmap32);
begin
   Self.In_bmp:=In_bmp;
   Self.Out_bmp:=Out_bmp;
   Self.Grad_bmp:=Grad_bmp;
   PixelsList:=TList.Create;
   SetLength(Labels,In_bmp.Width,In_bmp.Height);
   //в Out_bmp - морфоградиентное изображение
   CreatePixList;
   //сортировка пикселей по убыванию нормы вектора градиента
   PixelsList.Sort(PixelCompare);
   //преобразование водораздела
   Watershed;
   Draw;
end;

destructor TWatershed.Destroy;
begin
  PixelsList.Free;
end;

procedure TWatershed.Watershed;
var delta,h,i,k,m:integer;
    ws:PWS_Pixel;
    L:Cardinal;
    new_L:boolean;
    done:boolean;
begin
  h:=20;
  delta:=20; //thresld delta
  L:=1; //first label
  //первичное затопление (уровень 20)
  for i:=PixelsList.Count-1 downto 0 do
  begin
    ws:=PWS_Pixel(PixelsList.Items[i]);
    //ws.lab:=L;
    Labels[ws.x,ws.y]:=L;
    if ws.grad>h then break;
  end;
  //дальнейшее затопление (h+delta)
  while h<255 do
  begin
    h:=h+delta;
    for i:=i downto 0 do
    begin
      ws:=PWS_Pixel(PixelsList.Items[i]);
      //поиск меток соседних пикселей
      new_L:=true;
      for k:=-1 to 1 do
      for m:=-1 to 1 do
        if (Labels[ws.x+k,ws.y+m]<>0) then //если соседи имеют метку
        begin
          Labels[ws.x,ws.y]:=Labels[ws.x+k,ws.y+m];
          new_L:=false;
          break;
        end;
     //если соседи не имеют метки СОЗДАЕМ НОВУЮ МЕТКУ L
      if new_L then
      begin
        inc(L);
        Labels[ws.x,ws.y]:=L;
      end;
      //переход к след. уровню
      //if ws.grad>h then break;
    end;
  end;
end;

function PixelCompare(Item1, Item2:Pointer):Integer;
begin
  result:=0;
  if((PWS_Pixel(Item1)^.grad)=(PWS_Pixel(Item2)^.grad)) then result:=0 else
  if((PWS_Pixel(Item1)^.grad)>(PWS_Pixel(Item2)^.grad)) then result:=-1 else result:=1;
end;

procedure TWatershed.Draw;
var i,j:integer; p_dst,p_src:PColor32; ws:PWS_Pixel;
    Histogram, SortedLabels:array of integer;
    f:Textfile; l_size:integer;
begin
//  p_src:=@In_bmp^.Bits[0];
  Assign(f,'Labels.txt');
  Rewrite(f);
  //строим гистограмму меток
 SetLength(Histogram,Out_bmp.Height*Out_bmp.Width);
  for j:=0 to Out_bmp.Height - 1 do
  for i:=0 to Out_bmp.Width - 1 do
    inc(Histogram[Labels[i,j]]);

  //обрежем гистограмму до нулей
  i:=0; j:=0;
  while j<5 do begin
    if Histogram[i]=0 then inc(j);
    inc(i);
  end;
  l_size:=i;
  SetLength(Histogram,l_size+1);
  SetLength(SortedLabels,l_size+1);
  //быстрая сортировка
  QuickSort(Histogram,SortedLabels,0,l_size);
  //гистограмму\метки в файл
  for i:=0 to l_size - 1 do
  begin
      //if (Histogram[i]<>0) then
       Write(f,',',i,'-',SortedLabels[i]);
  end;
  CloseFile(f);

  //отрисовываем помеченные области
  for j:=0 to Out_bmp.Height - 1 do
  begin
    p_dst:=@Out_bmp^.Bits[j*Out_bmp.Width];
    for i:=0 to Out_bmp.Width - 1 do
    begin
      //if (Labels[i,j]=SortedLabels[l_size-25])then
      if (Labels[i,j]>25) and (Labels[i,j]<550)then
        p_dst^:=Color32(180,180,Labels[i,j]);
      inc(p_dst);
    end;
  end;

end;

procedure TWatershed.CreatePixList;
var i,j:integer; p,p2:PColor32; ws:PWS_Pixel;
begin
//  p:=@Out_bmp^.Bits[0];
  for j:=3 to Grad_bmp.Height - 3 do
  begin
    p:=@Grad_bmp^.Bits[Grad_bmp.Width*j];
    for i:=3 to Grad_bmp.Width - 3 do
    begin
      New(ws);
      //ws.pix:=p;
      //ws.lab:=0;
      ws.grad:=p^ and 255;
      ws.x:=i;
      ws.y:=j;
      PixelsList.Add(ws);
      inc(p);
    end;
  end;
end;

end.




