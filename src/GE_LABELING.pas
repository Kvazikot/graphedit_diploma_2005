unit GE_LABELING;

interface

uses
  GR32, Classes, Math, Contnrs, QCKSRT, BITS, PixelQuenue, SysUtils, StdImageProcessing;

 type

  TGrain = record
     lbl: integer;  //метка области
     nPix: integer; //количество пикселей в области
     nCm: TPoint;  //геометрический центр

     //BBox: TRect;
     //x_proj: array of integer;
     //y_proj: array of integer;

     bDead: boolean;
  end;
  PGrain = ^TGrain;

  TLabeling = class
    Frame_1, Frame_2, Frame_Out  :PBitmap32;

    nL_1: integer; //количество меток 1 кадра
    nL_2: integer; //количество меток 2 кадра

   // bMode: boolean; //режим закраски

    LIntersectTree: array of array of integer; //дерево св€зных меток (областей)
    LStatus: array of integer; //количество пересечений дл€ метки i (2->0 2->1)
    LColors: array of TColor32;

    GrainList_1, GrainList_2: TList; //List of TGrain: области 1 и 2 кадров
    nPix1: integer;
    nPix2: integer;

    constructor Create(Fr_1,Fr_2,Fr_Out:PBitmap32; bMode: boolean; C1_old, C2_old: TPoint);
    destructor  Destroy; override;
    function    CCLabeling(In_bmp,Out_bmp:PBitmap32; var GrainList:TList):integer;
    procedure   BuildIntersectTree(lbl_bmp_1,lbl_bmp_2:PBitmap32);
    procedure   FillGrains(lbl_bmp_1,lbl_bmp_2,Fr_Out:PBitmap32; bMode: boolean);

    procedure IntersectLabels(In_bmp,Out_bmp:PBitmap32);
  end;

   {* функции дл€ сортировки областей *}
   //по возрастанию nPix
   function NPixSortProc(Item1, Item2:Pointer):Integer;

  const
   //$FF RR GG BB - обычный пиксел
   //$XX RR GG BB -  помеченный
    SEEN     = Bit31;
    BG       = Bit30;
    NOT_BG    = Bit29;
    BOARDER  = $66666666;

implementation

constructor TLabeling.Create(Fr_1,Fr_2,Fr_Out:PBitmap32; bMode:boolean; C1_old, C2_old: TPoint);
var Fr1_lbl,Fr2_lbl: TBitmap32;
    i,j,k,d,lbl,nDif1,nDif2:integer;
    pGrn,pGrn1,pGrn2,pGrn3:PGrain;
    l_11,l_12,l_21,l_22: integer;
begin

  Frame_1:=Fr_1;
  Frame_2:=Fr_2;
  Frame_Out:=Fr_Out;

  Fr1_lbl:=TBitmap32.Create;
  Fr2_lbl:=TBitmap32.Create;
  Fr1_lbl.SetSize(Fr_1.Width,Fr_1.Height);
  Fr2_lbl.SetSize(Fr_2.Width,Fr_2.Height);
  GrainList_1:=TList.Create;
  GrainList_2:=TList.Create;

  (* метим бекгроунд в двух кадрах *)
  LabelBG(Fr_1);
  LabelBG(Fr_2);

  (* метим граничные пикселы *)
  LabelBoarders(Fr_1);
  LabelBoarders(Fr_2);

  (* помечаем connected componets
    выход -> в Fr1_lbl и Fr2_lbl
    на выходе получаютс€ отбалдовые метки 1,2,3,4 *)
  nL_1:=CCLabeling(Fr_1,@Fr1_lbl,GrainList_1);
  nL_2:=CCLabeling(Fr_2,@Fr2_lbl,GrainList_2);

  //бекап режим (простое пересечение)
{  if(not bMode)then
  begin
    Fr1_lbl.DrawTo(Frame_1^);
    Fr2_lbl.DrawTo(Frame_Out^);
    Self.IntersectLabels(Frame_1,Frame_Out);
  end;
}
  (* ѕостроение дерева пересекающихс€ областей *)
  SetLength(LIntersectTree,nL_1 + 10,nL_2 + 10);
  SetLength(LStatus,Max(nL_1,nL_2) + 10);
  SetLength(LColors,Max(nL_1,nL_2) + 10);
  BuildIntersectTree(@Fr1_lbl,@Fr2_lbl);
  //exit;

 {* удалить непересекающиес€ метки из списков *}
 for i:=0 to GrainList_1.Count-1 do
 begin
   pGrn:=PGrain(GrainList_1.Items[i]);
   if (LStatus[pGrn.lbl-1]=0) then
   begin
     pGrn.bDead:=True;
     //pGrn.nPix:=0;
   end;
 end;

  (* отсортировать списки GrainList по возрастанию nPix *)
  GrainList_1.Sort(NPixSortProc);
  GrainList_2.Sort(NPixSortProc);
  //exit;

 {* составить массивчик цветов LColors дл€ областей
   --по пор€дку в списке GrainList
   --и по дереву пересечений LIntersectTree
   резкий контраст дл€ первых 2х            *}

 if GrainList_1.Count>1 then
 begin
     pGrn1:=PGrain(GrainList_1.Items[0]);
     pGrn2:=PGrain(GrainList_1.Items[1]);
     if (GrainList_1.Count>2) then
       pGrn3:=PGrain(GrainList_1.Items[2]);

     LColors[pGrn1.lbl]:=clred32;
     LColors[pGrn2.lbl]:=clBlue32;
     if (GrainList_1.Count>2) then
       LColors[pGrn3.lbl]:=clgreen32;
    //out to interface 
    nPix1:=pGrn1.nPix;
    nPix2:=pGrn2.nPix;

   for i:=3 to GrainList_1.Count - 1  do
    begin
     lbl:=PGrain(GrainList_1.Items[i]).lbl;
     LColors[lbl]:=1;//Color32(lbl*50,lbl*50,lbl*50);
    end;
 end;

 FillGrains(@Fr1_lbl,@Fr2_lbl,Frame_Out,bMode);

 Frame_Out.Font.Size:=12;
 Frame_Out.Font.Name:='Arial';
 Frame_Out.RenderText(5,20,' оличество ‘рагментов: '+inttostr(GrainList_1.Count),255,clwhite32);
// Frame_Out.RenderText(5,40,' оличество Ўумовых\Ќовых √рейнов: '+inttostr(GrainList_1.Count),255,clwhite32);
 {* закрасить лейблы по массивчику цветов LColors *}

  //LColors[]

  Fr1_lbl.Free;
  Fr2_lbl.Free;

end;

procedure TLabeling.FillGrains(lbl_bmp_1,lbl_bmp_2,Fr_Out:PBitmap32; bMode: boolean);
var S1,S2,D: PColor32;
   i,j:integer;
begin

  S1:=lbl_bmp_1.PixelPtr[0,0];
  S2:=lbl_bmp_2.PixelPtr[0,0];
  D:=Fr_Out.PixelPtr[0,0];
  
  for j:=0 to Frame_1.Height*Frame_1.Width-2 do
  begin
    if S1^=BOARDER then begin inc(S1); inc(S2); inc(D); continue; end;

{   if ((S^=0) and (D^<>0)) then D^:=0;
   if ((S^<>0) and (D^=0)) then D^:=0;}

    if (LColors[S1^] = 1)  then begin inc(S1);inc(S2); inc(D); continue; end;

    if (bMode) then
    begin
      if ((S1^<>0) and (S2^<>0)) and (S1^<=nL_1) then
        D^:=LColors[S1^]
     // else D^:=0;
    end
    else D^:=LColors[S1^];


    inc(S1);inc(S2); inc(D);
  end;

end;

function NPixSortProc(Item1, Item2:Pointer):Integer;
begin
  result:=0;
  if((PGrain(Item1)^.nPix)=(PGrain(Item2)^.nPix)) then result:=0 else
  if((PGrain(Item1)^.nPix)>(PGrain(Item2)^.nPix)) then result:=-1 else result:=1;
end;

procedure  TLabeling.BuildIntersectTree(lbl_bmp_1,lbl_bmp_2:PBitmap32);
var
    i,k:integer;
    S1,S2: PColor32;
begin
  S1:=lbl_bmp_1.PixelPtr[0,0];
  S2:=lbl_bmp_2.PixelPtr[0,0];

  //сканирование построение дерева пересечений меток
  for i:=0 to lbl_bmp_1.Height*lbl_bmp_1.Width-2 do
  begin
    if S1^=BOARDER then begin inc(S1); inc(S2); continue; end;

    if ((S1^<>0) and (S2^<>0)) and (S1^<nL_1) and (S2^<nL_2) then
    begin
      //сброс "левых" меток в 4 байте
      S1^:=S1^ and $000000FF;
      S2^:=S2^ and $000000FF;
      //проверка количества св€зей
      if (LStatus[S1^]=0) then
      begin
        LIntersectTree[S1^,0]:=S2^;
        inc(LStatus[S1^]);
      end;

      if (LStatus[S1^]>=1) then
      begin
        //сканирование св€зей текущей метки S2^
        k:=LStatus[S1^]-1;
        while k>=0 do
        begin
          if(S2^=LIntersectTree[S1^,k]) then break;
          dec(k);
        end;
        //если метку S2^ среди них не нашли, создаем новую св€зь
        if (k=-1) then
        begin
          LIntersectTree[S1^,LStatus[S1^]]:=S2^;
          inc(LStatus[S1^])
        end;
      end;
    end;

    inc(S1); inc(S2);
  end;

end;

////////////////////////////////////////////////////////////////////
//Connected Componet Labeling (алгоритм L. Vincent)
//в Out_bmp <- label image
//result = количество меток
////////////////////////////////////////////////////////////////////

function TLabeling.CCLabeling(In_bmp,Out_bmp:PBitmap32; var GrainList:TList):integer;
var lbl,stribe:integer; //метки
    i,j,k,d_0:integer;
    S,D,SS,DD,ptr_0_D, ptr_0_S: PColor32;
    fifo:TPixelQuenue;
    Iq:array[0..7] of PColor32;//8 соседей p
    nPix:integer;
    p_grn: PGrain;
begin

  fifo:=TPixelQuenue.Create(100);
  lbl:=0;
  nPix:=0;
  S:=In_bmp.PixelPtr[0,0];
  D:=Out_bmp.PixelPtr[0,0];
  ptr_0_S:=S;
  ptr_0_D:=D;
  stribe:=In_bmp.width*4;

  for j:=0 to In_bmp.Height*In_bmp.Width-2 do
  begin

    if S^=BOARDER then begin inc(S); inc(D); continue; end;

    if ((S^ and BG) = BG) then
    begin
      D^:=0;
      S^:=S^ or SEEN; //set SEEN bit
    end
    else if ((S^ and SEEN) <> SEEN) then
    begin
      //кол-во пикселей предыдущей найденной области
      if lbl>0 then
        PGrain(GrainList.Items[GrainList.Count-1]).nPix:=nPix;

      lbl:=lbl + 1;
      //создаем новую область
      New(p_grn);
      p_grn.lbl:=lbl;
      p_grn.nPix:=0;
      p_grn.bDead:=false;
      nPix:=0;
      GrainList.Add(p_grn);

      S^:=S^ or SEEN; //set SEEN bit
      fifo.Push(S);
      while fifo.Count<>0 do //помечаем grain
      begin
        SS:=fifo.Pop;
        if SS^=BOARDER then continue;
        //DD через SS
        d_0:=(Integer(SS)-Integer(ptr_0_S));
        DD:=PColor32(Integer(ptr_0_D)+d_0);
        if ((SS^ and BG) <> BG) then
        begin
          DD^:=lbl;
          inc(nPix);
          ///////////////////////////////
          ///{**fifo_add_neibors(SS)**}
          ///////////////////////////////
          //соседи верхн€€ строка
          Iq[0]:=PColor32(Integer(SS)-stribe);
          Iq[1]:=Iq[0]; dec(Iq[1]);
          Iq[2]:=Iq[0]; inc(Iq[2]);
          //соседи текуща€ строка
          Iq[3]:=SS; dec(Iq[3]);
          Iq[4]:=SS; inc(Iq[4]);
          //соседи нижн€€ строка
          Iq[5]:=PColor32(Integer(SS)+stribe);
          Iq[6]:=Iq[5]; inc(Iq[6]);
          Iq[7]:=Iq[5]; dec(Iq[7]);
          for k:=0 to 7 do
          begin
            if ((Iq[k]^ and SEEN) <> SEEN) then
            begin
              fifo.Push(Iq[k]);
              Iq[k]^:=Iq[k]^ or SEEN;
            end;
          end;

        end;
      end;
    end;
    inc(S); inc(D);
  end;

  if lbl>0 then
    PGrain(GrainList.Items[GrainList.Count-1]).nPix:=nPix;

 result:=lbl;

end;

/////////////////////////////////
//ѕересечение меток
////////////////////////////////

procedure TLabeling.IntersectLabels(In_bmp,Out_bmp:PBitmap32);
var lbl,stribe:integer; //метки
    i,j,k,d_0:integer;
    S,D,SS,DD,ptr_0_D, ptr_0_S: PColor32;
    fifo:TPixelQuenue;
    Iq:array[0..7] of PColor32;//8 соседей p
    NumPix:array of integer;
begin
  S:=In_bmp.PixelPtr[0,0];
  D:=Out_bmp.PixelPtr[0,0];
  for j:=0 to In_bmp.Height*In_bmp.Width-2 do
  begin
    if S^=BOARDER then begin inc(S); inc(D); continue; end;

    if ((S^=0) and (D^<>0)) then D^:=0;
    if ((S^<>0) and (D^=0)) then D^:=0;
    if ((S^<>0) and (D^<>0)) then
      D^:=Color32(S^*50,S^*50,200);

    inc(S); inc(D);
  end;
end;

destructor  TLabeling.Destroy;
var i:integer;
begin
  for i:=0 to GrainList_1.Count - 1 do
    Dispose(PGrain(GrainList_1.Items[i]));

  for i:=0 to GrainList_2.Count - 1 do
    Dispose(PGrain(GrainList_2.Items[i]));

 GrainList_1.Free;
 GrainList_2.Free;
 
end;


end.




