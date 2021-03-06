//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//?????: ???????? ???????
//wwww@sknt.ru ~ vdbar@rambler.ru
//??????????? ?? ?????? Max-Tree
//GE_Max_Tree.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_Max_Tree;

interface

uses
  GR32, Classes, Math, Contnrs, QCKSRT, ComCtrls, SysUtils, StdCtrls;

type

  //Node of Max-Tree
  PMTNode = ^MTNode;
  MTNode = record
    h:integer;
    k:integer;
    father:PMTNode;   //pointer to father
    has_child:boolean;
    //child2:PMTNode;
    criteria:integer;
    preserve:boolean; //preserve\remove flag
  end;

  //Link of Max-Tree
  PMTLink = ^MTLink;
  MTLink = record
    h_f,k_f:integer; //father
    h_c,k_c:integer; //child
  end;

  type
  PMemo=^TMemo;
  //Max-Tree class
  TMaxTree = class
    public
      ORI:PBitmap32;
      number_nodes:array[0..255] of integer; //number_nodes at level h
      STATUS:array of integer; //status of pixel: assigned to C[h,k] node
      C:array of array of MTNode; //TREE DATA C[h,k]
      Links:TList;
      Console:TMemo;

      constructor Create(ORI:PBitmap32;Console:TMemo);
      procedure   Filter(dst:PBitmap32; n_path, n_start,n_end:integer);
      procedure   Entropy;
      destructor  Destroy; override;
      procedure   DrawTree(bmp:PBitmap32);

    private
      node_at_level:array[0..255] of boolean;
      hQueue:array[0..255] of TQueue;  //hierarhical quenue (h - level of hierarhy)
      ptr_0,ptr_lst:PColor32;//????????? ?? ?????? ? ????????? ??????
      d_0,d_lst:Integer; //?????????? ?? ??????? ? ?????????? ????????? (???????)
      stribe:Integer; //1 ?????? ??????? ? ??????
      Histogram:array[0..255] of integer;

      function Flood(h:integer):integer;

  end;

implementation

//procs for sorting (sorting by h)
function HCompare(Item1, Item2:Pointer):Integer;
begin
  result:=0;
  if((PMTNode(Item1)^.h)=(PMTNode(Item2)^.h)) then result:=0 else
  if((PMTNode(Item1)^.h)>(PMTNode(Item2)^.h)) then
    result:=1 else result:=-1;
end;
//sort by k (after h-sorting)
function KCompare(Item1, Item2:Pointer):Integer;
begin
  result:=0;
  if((PMTNode(Item1)^.h)=(PMTNode(Item2)^.h)) then
  begin
    if((PMTNode(Item1)^.k)>(PMTNode(Item2)^.k)) then
     result:=1 else result:=-1;
  end;
end;

constructor TMaxTree.Create(ORI:PBitmap32;Console:TMemo);
const NOT_ANALYZED = -1;
var h,i,j:integer;
    pSTATUS:^Integer;
    pNode:PMTNode;
    pLink:PMTLink;
    S:PColor32;
    f:Textfile;
begin
 //init and alloc memory
 Self.ORI:=ORI;
 Self.Console:=Console;
 //????? ????????? ?? ?????? ? ?????? ??????
 ptr_0:=ORI.PixelPtr[0,0];
 ptr_lst:=ORI.PixelPtr[ORI.Width,ORI.Height];
 stribe:=Integer(ptr_lst) - Integer(ptr_0);
 stribe:=ORI.width*4;

 //init
 for i:=0 to 255 do
 begin
   number_nodes[i]:=0;
   node_at_level[i]:=true;
 end;
 SetLength(STATUS,ORI.Width*ORI.Height);
 for i:=0 to ORI.Width*ORI.Height-1 do
   STATUS[i]:=NOT_ANALYZED;

 Links:=TList.Create;

 //create histogram
 S:=@ORI.Bits[0];
 FillChar(Histogram,255,0);
 for i:=0 to ORI.Width*ORI.Height - 1 do
 begin
   inc(Histogram[S^ and 255]);
   inc(S);
 end;

 //hQueue Create
 for h:=0 to 255 do
  hQueue[h]:=TQueue.Create;

 //find hmin
 for h:=0 to 255 do
   if(Histogram[h]<>0) then break;

 //find pixel(i,j)=hmin
 S:=@ORI.Bits[ORI.Width+2];
 for i:=0 to ORI.Width*ORI.Height - 1 do
   if(S^ and 255)=h then break else inc(S);

 //pixel in quenue(h)
 hQueue[h].Push(S);

 //Create Max by recursive flooding
 flood(h);

  //hQueue Free
 for h:=0 to 255 do
  hQueue[h].Free;

 //*******build Tree structure****

 //free mem
 SetLength(C,256,MaxIntValue(number_nodes));

 Assign(f,'STATUS.txt');
 Rewrite(f);

 //add nodes
 S:=@ORI.Bits[0];
 pSTATUS:=@STATUS[0];
 for i:=0 to ORI.Width*ORI.Height-1 do
 begin
   if (pSTATUS^>=0) then
   begin
     C[S^ and 255,pSTATUS^].h:=S^ and 255;
     C[S^ and 255,pSTATUS^].k:=pSTATUS^;
     C[S^ and 255,pSTATUS^].has_child:=false;
     write(f,',',Integer(pSTATUS^));
   end;
   inc(S); inc(pSTATUS);
 end;

 Links.Sort(HCompare);
 //Links.Sort(KCompare);

 //add relationships father-child
 for i:=0 to Links.Count-2 do
 begin
   pLink:=PMTLink(Links.Items[i]);
   if(number_nodes[pLink.h_c]>pLink.k_c)then //???????? ?? ???
   C[pLink.h_c,pLink.k_c].father:=@C[pLink.h_f,pLink.k_f];
   if(number_nodes[pLink.h_f]>pLink.k_f)then
   C[pLink.h_f,pLink.k_f].has_child:=true;
   //write(f,' ','[',pLink.h_f,']',pLink.k_f,'->','[',pLink.h_c,']',pLink.k_c);
 end;

 //?????? ???-?? ???
 j:=0;
 for i:=0 to Length(number_nodes)-1 do j:=j+number_nodes[i];
 Console.Text:='????? ???: '+inttostr(j);
 CloseFile(f);

end;

function TMaxTree.flood(h:integer):integer;
const NOT_ANALYZED = -1;
      IN_THE_QUENUE = -2;
var  m,j,i,x_offset,q:integer;
     p:PColor32; //p from quenue
     q8:array[0..7] of PColor32;//8 ??????? p
     n_cnt:byte; //????? ????????? ???????
     Link:PMTLink;
begin

  //First step: propagation

   while hQueue[h].Count<>0 do
   begin
     p:=hQueue[h].Pop;
     //pixel index
     d_0:=Integer(p)-Integer(ptr_0);
     d_lst:=Integer(ptr_lst)-Integer(p);
     STATUS[d_0 shr 2]:=number_nodes[h]; //status(p)
     //???????? ??????
     x_offset:=d_0 mod stribe;
     if ((x_offset-4)<>0) and ((x_offset+4)<>stribe) and (d_0>stribe+4) and (d_lst>stribe+4) then
     begin
      //????? ???????
      //??????? ??????
      q8[0]:=PColor32(Integer(p)-stribe);
      q8[1]:=q8[0]; dec(q8[1]);
      q8[2]:=q8[0]; inc(q8[2]);
      //??????? ??????
      q8[3]:=p; dec(q8[3]);
      q8[4]:=p; inc(q8[4]);
      //?????? ??????
      q8[5]:=PColor32(Integer(p)+stribe);
      q8[6]:=q8[5]; inc(q8[6]);
      q8[7]:=q8[5]; dec(q8[7]);
      //???? ?? ???????
      for i:=0 to 7 do
      begin
        q:=(Integer(q8[i])-Integer(ptr_0))shr 2;
        //q:=Length(STATUS);
        if STATUS[q]=NOT_ANALYZED then
        begin
          hQueue[q8[i]^ and 255].Push(q8[i]);
          STATUS[q]:=IN_THE_QUENUE;
          node_at_level[p^ and 255]:=true;
          if (q8[i]^ and 255)>(p^ and 255) then //we found a child at level q
          begin
            m:=q8[i]^and 255;
            repeat //flood the child
              m:=flood(m);
            until m=h;
          end;//if
        end;//if
       end;//for
     end;//if
   end;//while

   inc(number_nodes[h]);

  //Second step: define the father

  m:=h-1;
  //* Look for the father */
  while (m>=0) and (node_at_level[m]=false) do
    m:=m-1;
  //Assign the father
   if (m>=0) then
   begin
     i:=number_nodes[h]-1;
     j:=number_nodes[m];
     //father of C[h,i] is C[m,j]
     New(Link);
     Link.h_f:=m;
     Link.k_f:=j;
     Link.h_c:=h;
     Link.k_c:=i;
     Links.Add(Link);
   end
   else
   begin
    //C[h,i] has no father
     New(Link);
     Link.h_f:=0;
     Link.k_f:=0;
     Link.h_c:=h;
     Link.k_c:=i;
     Links.Add(Link);
   end;
   node_at_level[h]:=false;
   result:=m;
end;

{procedure TreeBacktrace(CheckNode:PMTNode; var Path:TList);
begin
   if(CheckNode.child<>nil) then
   begin
     Path.Add(CheckNode.child);
     TreeBacktrace(CheckNode.child,Path);
   end;
end;
}

procedure TraceToRoot(cur:PMTNode; var Path:TList);
begin
  if(cur.father<>nil) then
  begin
    cur:=cur.father;
    Path.Add(cur);
    TraceToRoot(cur,Path);
  end;
end;

procedure TMaxTree.Filter(dst:PBitmap32; n_path, n_start,n_end:integer);
var h,k,i,j,val,val_0:integer; S,D:PColor32; pSTATUS:^Integer;
    LivesList:TList; Path,tmp:TList; start_node:PMTNode;
    _dec:integer;
begin
  LivesList:=TList.Create;
  Path:=TList.Create;
  tmp:=TList.Create;

 //??????? ?????? ?????? (???? ?? ??????? ?????)
  for h:=0 to 255 do
  for k:=0 to number_nodes[h]-1 do
  begin
      if(not C[h,k].has_child) then
        LivesList.Add(@C[h,k]);
  end;
  Console.Lines.Add('???-?? ???????: '+inttostr(LivesList.Count));

 //???? ????? ???? ?????? ?? ???????
 if (n_path>LivesList.Count-1)then
 begin  dst.clear(clred32); exit; end;

 //???????? ???? ?? ????? ?? ?????? ?????
 start_node:=LivesList.Items[n_path];

 //?????????? ?? ?????
 TraceToRoot(start_node,tmp);

 //?????????? ???? (?????? ? ?????? ??????)
 for i:=tmp.Count-1 downto 0 do
   Path.Add(tmp.Items[i]);

 Console.Lines.Add('???-?? ??? ? ????????? ?????:'+inttostr(tmp.Count));

 if (n_start>Path.Count-1) or (n_end>Path.Count-1) then
 begin  dst.clear(clred32); exit; end;

 Console.Lines.Add(Format('n_start[h=%d,k=%d] -> n_end[h=%d,k=%d]',[PMTNode(Path.Items[n_start]).h, PMTNode(Path.Items[n_start]).k, PMTNode(Path.Items[n_end]).h, PMTNode(Path.Items[n_end]).k ]));
 h:=PMTNode(Path.Items[n_start]).h;
 Console.Lines.Add(Format('num_nodes[%d]=%d',[h,number_nodes[h]]));


 S:=@ORI.Bits[0];
 D:=@dst.Bits[0];
 pSTATUS:=@STATUS[0];
 if n_start<n_end then
 begin
   val:=n_end;
   val_0:=n_start;
 end
 else
 begin
   val:=n_start;
   val_0:=n_end;
 end;
 j:=val_0;

 for i:=0 to ORI.Width*ORI.Height-1 do
 begin
   D^:=S^;

     j:=val_0;
     while j<>val do
     begin
       if (pSTATUS^=PMTNode(Path.Items[j]).k) and ((S^ and 255)=PMTNode(Path.Items[j]).h) then
       begin
         D^:=clblue32;
         break;
       end;
       inc(j);
     end;


   inc(S); inc(pSTATUS); inc(D);
 end;
 LivesList.Free;
 Path.Free;
 tmp.Free;
end;

procedure TMaxTree.Entropy;
var h,k:integer;
begin
   //??????? ?????? ?????? (???? ?? ??????? ?????)
  for h:=0 to 255 do
  for k:=0 to number_nodes[h]-1 do
  begin

  end;

end;

procedure TMaxTree.DrawTree(bmp:PBitmap32);
var h,k,i,s_x,s_y,off_x:integer;pLink:PMTLink;
begin
  bmp.Clear(clwhite32);
  //draw nodes (square)
  for h:=1 to 255 do
  for k:=0 to number_nodes[h]-1 do
  begin
    s_x:=bmp.Width div number_nodes[h];
    off_x:=(number_nodes[h] div 2)*s_x+10;
    s_y:=bmp.Height div 256;
    bmp.FillRectTS(off_x+s_x*k-2, s_y*h-2, off_x+s_x*k+2, s_y*h+2,clred32);
  end;
  //draw links (lines)
  for i:=0 to Links.Count-1 do
  begin
    pLink:=PMTLink(Links.Items[i]);
//    bmp.LineS(s_x*pLink.k_f, s_y*pLink.h_f, s_x*pLink.k_c, s_y*pLink.h_c, clblue32);
  end;

end;

destructor TMaxTree.Destroy;
var i:integer;
begin
    //draw links (lines)
  for i:=0 to Links.Count-1 do
    Dispose(Links.Items[i]);

  Links.Free;
end;

end.



