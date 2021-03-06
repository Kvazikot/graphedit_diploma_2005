//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//?????: ???????? ???????
//wwww@sknt.ru ~ vdbar@rambler.ru
//Graph Editor
//GE_Main.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_Main;

interface

uses
  Dialogs, Menus, ImgList, Controls, ExtDlgs,
  StdCtrls, ExtCtrls, GR32_RangeBars, Buttons, Windows, Types, Contnrs, Messages, SysUtils, Variants, Classes, Graphics, Forms,
  GR32, GR32_Polygons, GR32_Layers, GR32_Blend, GR32_Image,
  GR32_Transforms,  VfW, scanf,ToolWin, Math, ValEdit, Grids, FileCtrl, Outline,
  DirOutln, GE_Layout, GE_ColorOPS, GE_4SS, ActnMan, ActnCtrls, StdActns, ActnList,
  CustomizeDlg, GE_WS, ComCtrls, TeEngine, Series, TeeProcs, Chart, GE_MORPHO, GE_BLOCK_SG,
  GE_Max_Tree, GE_FastWS, GE_ADAPT_THRESHOLD, GE_LABELING, GE_FDistance, Spin;

type
  TForm1 = class(TForm)
    Console: TMemo;
    OpenPictureDialog1: TOpenPictureDialog;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Edit2: TMenuItem;
    View1: TMenuItem;
    AddLayout1: TMenuItem;
    RemoveLayout1: TMenuItem;
    Interactive1: TMenuItem;
    Open1: TMenuItem;
    SaveTo1: TMenuItem;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    DeleteAll1: TMenuItem;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet5: TTabSheet;
    TabSheet1: TTabSheet;
    ListView1: TListView;
    TabSheet3: TTabSheet;
    ListView3: TListView;
    TabSheet2: TTabSheet;
    ListView4: TListView;
    TabSheet4: TTabSheet;
    ListView2: TListView;
    TabSheet6: TTabSheet;
    StaticText1: TStaticText;
    Edit1: TEdit;
    LAYOUTH: TGaugeBar;
    LFixed: TCheckBox;
    FrameBar: TGaugeBar;
    Image321: TImage32;
    BitBtn1: TBitBtn;
    RadioGroup1: TRadioGroup;
    RadioGroup2: TRadioGroup;
    Edit4: TEdit;
    Label1: TLabel;
    RadioGroup3: TRadioGroup;
    CheckBox1: TCheckBox;
    Chart1: TChart;
    FastLineSeries1: TFastLineSeries;
    Save1: TMenuItem;
    TreeView1: TTreeView;
    Memo1: TMemo;
    SpeedButton1: TSpeedButton;
    SpinEdit1: TSpinEdit;
    Button1: TButton;
    procedure Image321MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure Image321MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer; Layer: TCustomLayer);
    procedure Image321MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);

    procedure onFileItemClick(Sender: TObject);
//    procedure onGUIItemEnter(Sender: TObject);

    procedure Color_Add(F: TColor32; var B: TColor32; M: TColor32);

    procedure FormCreate(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure Image321Resize(Sender: TObject);
    procedure GaugeBar1Change(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure AddLayout1Click(Sender: TObject);
    procedure Image321KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ListView2Click(Sender: TObject);
    procedure ListView3Click(Sender: TObject);
    procedure ListView4Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SaveTo1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure DeleteAll1Click(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure DirectoryOutline1Change(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);

  private
    { Private declarations }
  protected
  public
    { Public declarations }
  end;

//  procedure LayerMouseMove(Sender: TObject; Buttons: TMouseButton; Shift: TShiftState; X, Y: Integer);


const MAX_INPUTS=100;
      MAX_NODES=500;
      MAX_CONNECTIONS=MAX_NODES*MAX_INPUTS;
      AUTOLOADGRAF_FILENAME='trees\realtime.vvg';//'trees\ccLAB_1.vvg';
      FIN_IMG = 0;
      FIN_SEQ = 1;
      FIN_AVI = 2;

type
//useful pointers
PLayerCollection=^TLayerCollection;
PBitmapLayer=^TBitmapLayer;


//===================================================
// BASE TYPES
//===================================================


//CONNECTION
TConnection = record
  ID:Integer;
  HBmp: PBitmap32;     //pointer to layer bmp
  src: Integer;       //src node
  dst: Integer;      //dst node
  out_id: Integer;  //input id
  in_id: Integer;  //output id
  link_color:TColor32;
end; PConnection = ^TConnection;

//INPUTS & OUTPUSTS
TInputOutput = record
 Name:string;
 Data: Pointer; //DATA POINTER
 Linked: TList;//array of PNode;
 Rect: TRect; // rect for mouse ops
 end; PInputOutput=^TInputOutput;

//DRAG SET
TDragSet = record
 x,y:integer;
 dx,dy:integer;
 dragstate: byte;  //0: not draged 1: draged
end;

//NODE PARAMETRES (SET IN ATTRIBUTE EDITOR)
TParam = record
  //parametres arrays
  filename: ^string;
  str:     ^string;
  int:     ^integer;
  bool:    ^boolean;
  float:   ^real;
  range:   array[0..1] of real;
end; PParam = ^TParam;

//////////////////////////////////////
//BASE NODE CLASS
//////////////////////////////////////
PNode=^TNode;
PFileInManager=^TFileInManager;

TNodeStatus = record
  Enabled:boolean;  //node is enabled
  Rendered:boolean; //node buffer is rendered
  Processed:boolean //node is processed
end;

TNodeSkin = record
  TextWidth:Integer;
  LeftRect:TRect;
  TextRect:TRect;
  RightRect:TRect;
  InputRect:TRect;
  OutputRect:TRect;
end;

TNode=class
  private
   Name: string;
   NumInputs: Integer;
   NumOutputs: Integer;
   ID: Integer;
   PLayers: PLayerCollection; //pointer to TImage32 control
   HBmp: PBitmap32;  //bitmap handle

  public
//   has_buf: Boolean;
   data: PBitmap32;
   p_manager: PFileInManager;
   p_proc: procedure(PNode:PNode);
   frame_event: procedure(PNode:PNode; Frame:integer);
   param_list: TList;
   param_names: TStringList;
   info:string;

   Skin:TNodeSkin;
   Status:TNodeStatus;
   TreePath:TList;
   Order:integer;
   Inputs: array of TInputOutput;
   Outputs: array of TInputOutput;
   loc: TDragSet; //node position & drag state
   ActIn:Integer;
   ActOut:Integer;
   ActLayout:Integer;
   BodyRect:TRect;
   inQuenque:boolean;
   //property  Changed:boolean read FChanged write SetStatus();
   //property  Name:string read FName write Update;

   constructor Create(Lays:PLayerCollection);
   destructor  Destroy; override;
   procedure   Update;
   procedure   SetNumOutputs(Num:integer);
   procedure   DestroyData;
  //params procs
   function    GetParam(Name:string):PParam;
   procedure   AssignAllOutputs(P:Pointer);
   procedure   AddStrParam(description:string; default:string);
   procedure   AddFloatParam(description:string; default:real; min,max:real);
   procedure   AddFileParam(filename:string);
   procedure   AddBoolParam(description:string; default:boolean);
   procedure   AddIntParam(description:string; default:integer; min,max:real);
   //GUI
   procedure   SetParamsToGUI(AOwner:TComponent);
   procedure   GetParamsFromGUI(Sender:TObject);
   procedure   onSliderChange(Sender:TObject);
   procedure   SetActLayout(Sender:TObject);
   procedure   SetQuenque(Sender:TObject);

   procedure   RenderBuffer(LayoutIndex:integer);
   procedure   ProcessTree;
{   procedure   CopyBufferFrom(P:PNode);
   procedure   onConnect(C:PConnection);
}
  end; //PNode=^TNode;



//Input Data Manager
TFileInManager=class
  private
    ParentNode:    PNode;
    isFrameBuffered: boolean;

    FrameBuffers:  TBitmap32Collection;
    StartBuf:      longint;

    AviInfo:       TAVIFILEINFOW;
    pFile:         PAVIFile;
    AVIStream:     PAVIStream;
    gapgf:         PGETFRAME;

    procedure    OpenAVIFile(filename:string);
    procedure    LoadAVIFrames;
    procedure    LoadImageSequence;
    procedure    CloseAVIFile;

  public
    FILE_IN_TYPE:  byte;
    MaxBuffers:    longint;
    Filenames:     TStringList;
    JumpKeyFrames: boolean;
    FrameCount:    Longint;
//    FrameOffset:   Longint;
    FrameRate:     Longint;

   constructor  Create(Node:PNode);
   destructor   Destroy; override;
   procedure    Open;
   procedure    LoadFrame(index:integer);
//   procedure    SetMaxBufferedFrames(max:integer);
   procedure    FreeBuffers;

end;

//GRAPH EDITOR OBJECT
GEObject=record //using for working process
  isNode:Boolean;
  isConnection:Boolean;
  isLayout:Boolean;
  Node:PNode;
  Connection:PConnection;
end;

//FUNCTION CONTAINER
 TGEProcs = class
   public
   name:TStringList;
   addr:TList;
   procedure   AddProc(str:string; P:Pointer);
   function    GetProc(str:string):Pointer;
   function    GetName(P:Pointer):string;
   constructor Create;
   destructor  Destroy; override;
 end;

//BASE CLASS GRAPH EDITOR
TGraphEditor=class
  public
  ActObj:GEObject; //object under focus
  OldObj:GEObject; //previos focused object
  doinLine:Boolean;//user start link creation flag
  Dwn, Nrm:TBitmap32; //skin bitmaps
  PLayers: PLayerCollection; //pointer to TImage32 control
  SelNode:PNode;
  NumNodes:Integer;
  NumConnections:Integer;
  Nodes: array[0..MAX_NODES] of PNode; //Array of pointers to Nodes
  Connections: array[0..MAX_CONNECTIONS] of PConnection; //Array of pointers to Connections
  Layouts:TObjectList;
  GUI_Elements:TObjectList;
  GE_PATH:String;
  GraphFilename:String;
  CurrentFrame:integer;

  constructor Create;
  destructor Destroy; override;
  //interface code
  function  AddNode(x,y:integer; name:string; numInputs,numOutputs:Integer; DataBuffer, ProcedurePointer:Pointer):PNode;
  procedure AddConnection(src,dst,out_id,in_id:Integer);
  procedure AddLayout(Name:string);
  function GetNode(Name:string):PNode;
  procedure DeleteNode(N:PNode);
  procedure DeleteLayout(P:PLayout);
  procedure DeleteConnection(C:PConnection);
  procedure DeleteAllNodes;
  procedure UpdateNodeConnections(P:PNode);
  procedure LayoutClose(Sender: TObject; var Action: TCloseAction);
  procedure SaveToFile(filename:string);
  procedure LoadFromFile(filename:string);
//  function  CopyNode(src:PNode):PNode;
  function  ConnectonExist(src,dst,out_id,in_id:Integer):boolean;
  procedure ResetActObj;
  //procedure out_str(str:string);
  function  FindObjByLayer(HBmp:PBitmap32):GEObject; //find obj by focused layer
  function  FindLayerByBmp(HBmp:PBitmap32):Integer;
  procedure onLoseFocus(obj:GEObject); //on lose focus of active obj
  procedure onFocus(obj:GEObject; IOB:byte; io_id:integer); //
  procedure SelectNode(P:PNode);
  //drawing code
  procedure UpdateNodeLinks(N:PNode);
//  procedure UpdateNode;
  procedure DrawLink(C:PConnection; col:TColor32);
{  procedure DeleteNode(ID:Integer);

 }
 end;

   TGrain = record
     lbl: integer;  //????? ???????
     nPix: integer; //?????????? ???????? ? ???????
     nCm: TPoint;  //?????????????? ?????

     //BBox: TRect;
     //x_proj: array of integer;
     //y_proj: array of integer;

     bDead: boolean;
  end;
  PGrain = ^TGrain;


//SAMPLE PROCS
 procedure FILE_IN_PROC(N:PNode);
 procedure FILE_OUT_PROC(N:PNode);
 procedure _4SS_PROC(N:PNode);
 procedure CHECKER_PROC(N:PNode);
 procedure GRAY_PROC(N:PNode);
 procedure RANDOMER_PROC(N:PNode);
 procedure INVERT_PROC(N:PNode);
 procedure BIN_PROC(N:PNode);
 procedure ERODE_PROC(N:PNode);
 procedure DILATE_PROC(N:PNode);
 procedure OPEN_CLOSE_PROC(N:PNode);
 procedure ISUB_PROC(N:PNode);
 procedure IAND_PROC(N:PNode);
 procedure STROB_PROC(N:PNode);
 procedure WS_PROC(N:PNode);
 procedure GRAD_PROC(N:PNode);
 procedure RECONSTRUCT_PROC(N:PNode);
 procedure MAXTREE_PROC(N:PNode);
 procedure BUGFIX_PROC(N:PNode);
 procedure IMUL_PROC(N:PNode);

var
  Form1: TForm1;
  GE:TGraphEditor;
  GEProcs:TGEProcs;
  x_d,y_d:integer;
  C1_gb,C2_gb:TPoint;
//  FIN:TFileInNode;
  //LayersID:array[0..1000] of IDs;

implementation


//uses Unit1;

{$R *.dfm}

constructor TGEProcs.Create;
begin
  name:=TStringList.Create;
  addr:=TList.Create;
  AddProc('@CHECKER',@CHECKER_PROC);
  AddProc('@GRAY',@GRAY_PROC);
  AddProc('@RANDOMER',@RANDOMER_PROC);
  AddProc('@INVERT',@INVERT_PROC);
  AddProc('@BIN',@BIN_PROC);
  AddProc('@ERODE',@ERODE_PROC);
  AddProc('@DILATE',@DILATE_PROC);
  AddProc('@ISUB',@ISUB_PROC);
  AddProc('@IAND',@IAND_PROC);
  AddProc('@STROB_PROC',@STROB_PROC);
  AddProc('_4SS_PROC',@_4SS_PROC);
  AddProc('@Watershed',@WS_PROC);
  AddProc('@MGrad',@GRAD_PROC);
  AddProc('@RECONSTRUCT_PROC',@RECONSTRUCT_PROC);
  AddProc('@MAXTREE_PROC',@MAXTREE_PROC);
  AddProc('@FILE_OUT_PROC',@FILE_OUT_PROC);
  AddProc('@BUGFIX_PROC',@BUGFIX_PROC);
  AddProc('@IMUL_PROC',@IMUL_PROC);
  AddProc('@OPEN_CLOSE_PROC',@OPEN_CLOSE_PROC);

end;

destructor TGEProcs.Destroy;
begin
  name.Free;
  addr.Free;
end;

procedure TGEProcs.AddProc(str:string; P:Pointer);
begin
  name.Add(str);
  addr.Add(P);
end;

function TGEProcs.GetProc(str:string):Pointer;
begin
  if (name.IndexOf(str)<>-1) then
   result:=addr.Items[name.IndexOf(str)]
  else result:=nil;
end;

function TGEProcs.GetName(P:Pointer):string;
begin
  if (addr.IndexOf(P)<>-1) then
   result:=name.Strings[addr.IndexOf(P)]
  else result:='';
end;

constructor TGraphEditor.Create;
var  Alfa:TBitmap32; PX,PPX,APX: PColor32; i,j:integer;
begin
  GEProcs:=TGEProcs.Create;
  doinLine:=false;
  Nrm:=TBitmap32.Create;
  Dwn:=TBitmap32.Create;
  Alfa:=TBitmap32.Create;
  GUI_Elements:=TObjectList.Create;
  if (FileExists('bmp\1-1_node.bmp')) then
    Nrm.LoadFromFile('bmp\1-1_node.bmp')
  else
  begin
    Nrm.SetSize(148,43);
    Nrm.Clear(clBlack32);
  end;
  if (FileExists('bmp\1-1_node_dwn.bmp')) then
    Dwn.LoadFromFile('bmp\1-1_node_dwn.bmp')
  else
  begin
    Dwn.SetSize(148,43);
    Dwn.Clear(clred32);
  end;
  if (FileExists('bmp\node_alfa.bmp')) then
    Alfa.LoadFromFile('bmp\node_alfa.bmp')
  else
  begin
    Alfa.SetSize(148,43);
    Alfa.Clear(clwhite32);
  end;
  PLayers:=@Form1.Image321.Layers;
  Layouts:=TObjectList.Create;
  //assign alfa channel
  PX:=@Nrm.Bits[0];
  PPX:=@Dwn.Bits[0];
  APX:=@Alfa.Bits[0];
  for i := 0 to Nrm.Width * Nrm.Height - 1 do
  begin
    PX^ := SetAlpha(PX^, Intensity(APX^));
    PPX^:= SetAlpha(PPX^, Intensity(APX^));
    Inc(PX); Inc(PPX); Inc(APX);
  end;

end;

destructor TGraphEditor.Destroy;
var i:integer;
begin
  //FREE NODES MEMORY
  for i:=0 to NumNodes-1 do
    if Nodes[i]<>nil then
    begin
      Nodes[i].Destroy;
      Dispose(Nodes[i]);
    end;
  //FREE CONNECTIONS MEMORY
  for i:=0 to NumConnections-1 do
    if Connections[i]<>nil then
      Dispose(Connections[i]);

  //free procs
  GEProcs.Destroy;
  //free Layouts
  Layouts.Free;
end;

function TGraphEditor.AddNode(x,y:integer; name:string; numInputs,numOutputs:Integer; DataBuffer, ProcedurePointer:Pointer):PNode;
var N:PNode; i:integer;
begin
  New(N);
  N^:=TNode.Create(@Form1.Image321.Layers);
  N^.ID:=NumNodes;
  N^.loc.x:=x;
  N^.loc.y:=y;
  N^.p_proc:=ProcedurePointer;
  for i:=0 to NumNodes-1 do
    if Nodes[i].Name=Name then
      name:=name+'#';
  N^.Name:=name;
  N^.AddStrParam('NODE_NAME',name);
  N^.NumInputs:=NumInputs;
  N^.NumOutputs:=NumOutputs;
  SetLength(N^.Inputs,NumInputs);
  SetLength(N^.Outputs,NumOutputs);
  if (NumInputs>0) then
  for i:=0 to NumInputs-1 do
  begin
    N^.Inputs[i].Linked:=TList.Create;
    N^.Inputs[i].Data:=nil;
  end;
  if (NumOutputs>0) then
  for i:=0 to NumOutputs-1 do
  begin
    N^.Outputs[i].Linked:=TList.Create;
    N^.Outputs[i].Data:=N^.Data;
  end;
  N^.Update;
  Nodes[N^.ID]:=N;
  Form1.Console.Lines[0]:='AddNode "'+N.Name+'"';
  inc(NumNodes);
  Result:=N;
end;

function TGraphEditor.GetNode(Name:string):PNode;
var i:integer;
begin
 result:=nil;
 for i:=0 to NumNodes-1 do
   if Nodes[i].Name=Name then
     result:=Nodes[i];
end;

function TGraphEditor.ConnectonExist(src,dst,out_id,in_id:Integer):boolean;
var i:integer;
begin
  Result:=false;
  for i:=0 to NumConnections-1 do
    if ((Connections[i].src=src) and (Connections[i].dst=dst) and (Connections[i].out_id=out_id) and (Connections[i].in_id=in_id)) then Result:=true
    else Result:=false;
end;

procedure TGraphEditor.AddConnection(src,dst,out_id,in_id:Integer);
var C:PConnection;
    Lay:TBitmapLayer;
begin
  if (src>NumNodes) or (dst>NumNodes) then exit;
  if (Nodes[src].NumOutputs<=out_id) then exit;
  if (Nodes[dst].NumInputs<=in_id) then exit;
  New(C);
  Nodes[src].Outputs[out_id].Linked.Add(Nodes[dst]);
  Nodes[dst].Inputs[in_id].Linked.Add(Nodes[src]);
  Nodes[dst].Inputs[in_id].Data:=Nodes[src].Outputs[out_id].Data;
  C^.ID:=NumConnections;
  C^.src:=src;
  C^.dst:=dst;
  C^.out_id:=out_id;
  C^.in_id:=in_id;
  if(ConnectonExist(src,dst,out_id,in_id)) then begin
    Application.MessageBox('Connection already exist, wanna delete?', 'Hey!', MB_ICONERROR or MB_OKCANCEL);
    Dispose(C);
    Exit;
  end;
  Connections[C^.ID]:=C;
  //create new layer for display connection
  Lay:=TBitmapLayer.Create(Form1.Image321.Layers);
  Lay.Bitmap:=TBitmap32.Create;
  Lay.Bitmap.DrawMode:=dmBlend;
  Lay.AlphaHit:=true;
  C^.HBmp:=@TBitmapLayer(Form1.Image321.Layers.Items[Lay.Index]).Bitmap;
  //set random link color
  Randomize;
  C.link_color:=Color32(RGB(Random(200),Random(200),Random(200)));
  C.link_color:=SetAlpha(C.link_color,120);
  //draw link
  DrawLink(C,C.link_color);
  Form1.Console.Lines[0]:=Format('Add Connection: "%s"[%d]->"%s"[%d]',[Nodes[C.src].Name,C.out_id,Nodes[C.dst].Name,C.in_id]);
  inc(NumConnections);
end;

procedure TGraphEditor.DeleteConnection(C:PConnection);
var i:integer;
begin

  Nodes[C^.src].Outputs[C^.out_id].Linked.Extract(Nodes[C^.dst]);
  Nodes[C^.dst].Inputs[C^.in_id].Linked.Extract(Nodes[C^.src]);
  Nodes[C^.dst].Inputs[C^.in_id].Data:=nil;
  //defrag connection array
//  while(Connections[i]<>C.ID) do inc(i);
  for i:=C.ID to NumConnections-1 do
  begin
    Connections[i]:=Connections[i+1];
    if(Connections[i]<>nil) then
      Connections[i]^.ID:=i;
  end;
  PLayers.Items[FindLayerByBmp(C.HBmp)].Free;
  dec(NumConnections);
  Form1.Console.Lines[0]:=Format('Broke Connection: %s[%d]->%s[%d]',[Nodes[C.src].Name,C.out_id,Nodes[C.dst].Name,C.in_id]);;
  //Free Mem
  Dispose(C);
end;

procedure TGraphEditor.UpdateNodeConnections(P:PNode);
var i:integer; C:TConnection;
begin
 for i:=0 to NumConnections-1 do
   if Connections[i]<>nil then
   begin
     C:=Connections[i]^;
     if(C.src=P.ID)then
       Nodes[C.dst].Inputs[C.in_id].Data:=Nodes[C.src].Outputs[C.out_id].Data;
   end;
end;


procedure TGraphEditor.DeleteNode(N:PNode);
var i:integer;
begin
  //delete links
  i:=0;
  while (i<NumConnections) do
  begin
    if ((Connections[i].src=N.ID) or (Connections[i].dst=N.ID)) then
    begin
      DeleteConnection(Connections[i]);
      dec(i);
    end;
    inc(i);
  end;
  
  //defrag nodes array
 for i:=N.ID to NumNodes-1 do
 begin
    Nodes[i]:=Nodes[i+1];
    //chang ids
    if (Nodes[i]<>nil) then
      Nodes[i]^.ID:=i;
 end;

 //changing id's in connections array
 for i:=0 to NumConnections-1 do
 begin
    if Connections[i].src>=N.ID then
      dec(Connections[i].src);
    if Connections[i].dst>=N.ID then
      dec(Connections[i].dst);
 end;

  //delete layer
  PLayers.Items[FindLayerByBmp(N.HBmp)].Free;

 //delete GUI Params
  while (GE.GUI_Elements.Count<> 0) do
    GE.GUI_Elements.Delete(0);

  Form1.Console.Lines[0]:=Format('Delete Node: %s',[N^.name]);;
  dec(NumNodes);
  ResetActObj;
  SelNode:=nil;
  N.Destroy;
  Dispose(N);
end;

procedure TGraphEditor.DeleteAllNodes;
var i:integer;
begin
 for i:=NumNodes-1 downto 0  do DeleteNode(Nodes[i]);
end;

procedure TGraphEditor.SaveToFile(filename:string);
var Script:TStringList; i,j:integer;
P:PParam;
begin
//append extenshion
  if(ExtractFileExt(filename)<>'.vvg') then
    AppendStr(filename,'.vvg');

  Script:=TStringList.Create;

 for i:=0 to NumNodes-1 do
 begin
   if (@Nodes[i].p_proc<>nil) then
     Script.Add(Format('AddNode(%d,%d,%s,%d,%d,nil,%s)',[Nodes[i]^.loc.x,Nodes[i]^.loc.y,Nodes[i]^.Name,Nodes[i]^.NumInputs,Nodes[i]^.NumOutputs,GEProcs.GetName(@Nodes[i].p_proc)]));
   if (Nodes[i].p_manager<>nil) then
     Script.Add(Format('AddNode(%d,%d,%s,%d,%d,nil,0)',[Nodes[i]^.loc.x,Nodes[i]^.loc.y,Nodes[i]^.Name,Nodes[i]^.NumInputs,Nodes[i]^.NumOutputs]));

   //save params
   for j:=0 to Nodes[i].param_names.Count-1 do
   begin
     P:=PParam(Nodes[i].param_list.Items[j]);
     if ((P.str<>nil) and (Nodes[i].param_names.Strings[j]<>'NODE_NAME'))then
       Script.Add(Format('AddStrParam(%s,%s)',[Nodes[i].param_names.Strings[j],P.str^]));
     if (P.filename<>nil)then
       Script.Add(Format('AddFileParam(%s,%s)',[Nodes[i].param_names.Strings[j],P.filename^]));
     if (P.bool<>nil)then
       Script.Add(Format('AddBoolParam(%s,%d)',[Nodes[i].param_names.Strings[j],Integer(P.bool^)]));
     if (P.int<>nil)then
       Script.Add(Format('AddIntParam(%s,%d,%f,%f)',[Nodes[i].param_names.Strings[j],P.int^,P.range[0],P.range[1]]));
     if (P.float<>nil)then
       Script.Add(Format('AddFloatParam(%s,%f,%f,%f)',[Nodes[i].param_names.Strings[j],P.float^,P.range[0],P.range[1]]));
   end;

   //manager
   if (Nodes[i].p_manager<>nil) then
   begin
     Script.Add('AddFileInManager{');
     if (Nodes[i].p_manager.Filenames<>nil) then
     for j:=0 to Nodes[i].p_manager.Filenames.Count-1 do
       Script.Add(Nodes[i].p_manager.Filenames.Strings[j]);
     Script.Add('}');
   end;
   Script.Add('');
 end;

 //connections
 for i:=0 to NumConnections-1 do
   Script.Add(Format('AddConnection(%d,%d,%d,%d)',[Connections[i].src,Connections[i].dst,Connections[i].out_id,Connections[i].in_id]));

 //select node
 if (SelNode<>nil) then
   Script.Add(Format('SelectNode(%s)',[SelNode.Name]));

 //paths
 if((pos(':\',filename)=0))then filename:=GE_PATH+'\'+filename;
 
 Script.SaveToFile(filename);
 Script.Free;
end;

procedure TGraphEditor.LoadFromFile(filename:string);
var Script:TStringList; i,j:integer;
    lx,ly,NumInp,NumOut:integer; p_proc:pointer;
    int,int1,int2,int3:integer; float1,float2,float3:extended;
    P:PParam; N:PNode; R:byte;
    s1,s2:string[30];
begin
  if(not FileExists(filename)) then exit;
  Self.GraphFilename:=filename;
  DeleteAllNodes;
  Script:=TStringList.Create;
  //paths
  if((pos(':\',filename)=0))then filename:=GE_PATH+'\'+filename;
  Script.LoadFromFile(filename);
  //start script executing
  i:=0;
  while i<Script.Count do
  begin
     SetLength(s1,30);
     SetLength(s2,30);
     FillChar(s1,30,'A');
     FillChar(s2,30,'A');
     if(pos('AddNode',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddNode(%d,%d,%[^,],%d,%d,nil,%[^)])',[@lx,@ly,@s1[1],@NumInp,@NumOut,@s2[1]]);
       SetLength(s1,pos(#0,s1)-1);
       SetLength(s2,pos(#0,s2)-1);
       p_proc:=GEProcs.GetProc(s2);
       if R=6 then N:=AddNode(lx,ly,s1,NumInp,NumOut,nil,p_proc);
     end;
     if(pos('AddFileParam',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddFileParam(%[^,],%[^,])',[@s1[1],@s2[1]]);
       SetLength(s2,pos(#0,s2)-2);
       if R=2 then N.AddFileParam(s2);
     end;
     if(pos('AddStrParam',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddStrParam(%[^,],%[^,])',[@s1[1],@s2[1]]);
       SetLength(s1,pos(#0,s1)-1);
       SetLength(s2,pos(#0,s2)-2);
       if R=2 then N.AddStrParam(s1,s2);
     end;

     if(pos('SelectNode',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'SelectNode(%[^,])',[@s1[1]]);
       SetLength(s1,pos(#0,s1)-2);
       if R=1 then SelectNode(GetNode(s1));
     end;
     if(pos('AddIntParam',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddIntParam(%[^,],%d,%f,%f)',[@s1[1],@int,@float1,@float2]);
       SetLength(s1,pos(#0,s1)-1);
       if R=4 then N.AddIntParam(s1,int,float1,float2);
     end;
     if(pos('AddFloatParam',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddFloatParam(%[^,],%f,%f,%f)',[@s1[1],@float1,@float2,@float3]);
       SetLength(s1,pos(#0,s1)-1);
       if R=4 then N.AddIntParam(s1,int,float1,float2);
     end;
     if(pos('AddBoolParam',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddBoolParam(%[^,],%d)',[@s1[1],@int]);
       SetLength(s1,pos(#0,s1)-1);
       if R=2 then N.AddBoolParam(s1,boolean(int));
     end;
     if(pos('AddFileInManager{',Script.Strings[i])<>0) then
     begin
       inc(i);
       New(N.p_manager);
       N.p_manager^:=TFileInManager.Create(N);
       while(Script.Strings[i][1]<>'}') do
       begin
         if((pos(':\',Script.Strings[i])=0))then Script.Strings[i]:=GE_PATH+'\'+Script.Strings[i];
         if (FileExists(Script.Strings[i])) then
         N.p_manager^.filenames.Add(Script.Strings[i]);
         inc(i);
       end;
       dec(i);
       N.p_manager.Open;
     end;
     if(pos('AddConnection',Script.Strings[i])<>0) then
     begin
       R:=DeFormat(Script.Strings[i],'AddConnection(%d,%d,%d,%d)',[@int,@int1,@int2,@int3]);
       if R=4 then AddConnection(int,int1,int2,int3);
     end;
     inc(i);
  end;
  ResetActObj;
  //Script.SaveToFile(filename);
  Script.Free;
  //SelectNode(Nodes[0]);
end;

function  TGraphEditor.FindObjByLayer(HBmp:PBitmap32):GEObject;
var i:integer;
begin
  if(HBmp=nil) then exit;

  Result.isNode:=false;
  for i:=0 to GE.NumNodes-1 do
    if (GE.Nodes[i].HBmp=HBmp) then
    begin
      Result.isNode:=true; // found node
      Result.Node:=GE.Nodes[i];
      break;
    end else Result.isNode:=false;

  Result.isConnection:=false;
    if (not Result.isNode) then
      for i:=0 to GE.NumConnections-1 do
        if (GE.Connections[i].HBmp=HBmp) then //found connection
        begin
          Result.Connection:=GE.Connections[i];
          Result.isConnection:=true;
          break;
        end else Result.isConnection:=false;

end;

function TGraphEditor.FindLayerByBmp(HBmp:PBitmap32):Integer;
var i:integer;
begin
Result:=0;
  for i:=0 to PLayers.Count-1 do
    if (@TBitmapLayer(PLayers.Items[i]).Bitmap=HBmp) then
      Result:=i;
end;


procedure TGraphEditor.DeleteLayout(P:PLayout);
begin
  Layouts.Extract(P^);
  if(SelNode<>nil) then SelNode.SetParamsToGUI(Form1.TabSheet5);
end;

procedure TGraphEditor.LayoutClose(Sender: TObject; var Action: TCloseAction);
begin
  GE.Layouts.Remove(Sender);
end;

procedure TGraphEditor.AddLayout(Name:string);
var Layout:TLayout;
begin
  Layout:=TLayout.Create;
  Layout.Name:=Name;
  Layout.CloseEvent:=LayoutClose;
  Layouts.Add(Layout);
  if(SelNode<>nil) then SelNode.SetParamsToGUI(Form1.TabSheet5);
end;

procedure TGraphEditor.UpdateNodeLinks(N:PNode);
var i:integer;
begin
  for i:=0 to NumConnections-1 do
    if ((Connections[i].src=N^.ID) or (Connections[i].dst=N^.ID)) then
      DrawLink(Connections[i],Connections[i].link_color);
end;

procedure TGraphEditor.DrawLink(C:PConnection; col:TColor32);
var j:integer; x1,tmp,x2,y1,y2:Integer; ln_typ,fg:byte;   Polygon: TPolygon32;
begin
  Polygon := TPolygon32.Create;
  Polygon.Antialiased:=true;
  Polygon.FillMode := pfAlternate;
  if (C=nil) then exit;
   Form1.Image321.BeginUpdate;
  //setup coord of connection bmp
  x1:=Nodes[C^.src].loc.x+(Nodes[C^.src].Outputs[C^.out_id].Rect.Right+Nodes[C^.src].Outputs[C^.out_id].Rect.Left) div 2;
  y1:=Nodes[C^.src].loc.y+Nodes[C^.src].Outputs[C^.out_id].Rect.Bottom;
  x2:=Nodes[C^.dst].loc.x+(Nodes[C^.dst].Inputs[C^.in_id].Rect.Left+Nodes[C^.dst].Inputs[C^.in_id].Rect.Right) div 2;
  y2:=Nodes[C^.dst].loc.y+Nodes[C^.dst].Inputs[C^.in_id].Rect.Bottom;
  //setup bitmap size
  C.HBmp.BeginUpdate;
  C.HBmp.SetSize(abs(x2-x1)+6,abs(y2-y1)+6);
  C.HBmp.Clear(SetAlpha(clBlack32,0));
  //detect line type and rot angle \ or /
  ln_typ:=0; fg:=0;
  if (y1>y2) and (x1>x2) then fg:=1;
  if (y1>y2) then begin ln_typ:=2;tmp:=y1; y1:=y2; y2:=tmp; end;
  if (x1>x2) then begin ln_typ:=1; tmp:=x1; x1:=x2; x2:=tmp; end;
  if(fg=1) then ln_typ:=3;
  //set layer coord
  //find layer
  for j:=0 to Form1.Image321.Layers.Count-1 do
    if (@TBitmapLayer(Form1.Image321.Layers.Items[j]).Bitmap=C.HBmp) then
      TBitmapLayer(Form1.Image321.Layers.Items[j]).Location:=FloatRect(x1-3,y1-3,x2+3,y2+3);
  Polygon.Clear;
  Polygon.NewLine;
//  C.HBmp.FillRect(0,0,abs(x2-x1),abs(y2-y1),SetAlpha(clBlue32,100));
  case ln_typ of
    0: begin
         Polygon.Add(FixedPoint(3,0));
         Polygon.Add(FixedPoint(x2-x1+3,y2-y1));
         Polygon.Draw(C.HBmp^,col,clGreen32);
       end;
    1: begin
         Polygon.Add(FixedPoint(x2-x1+3,0));
         Polygon.Add(FixedPoint(3,y2-y1));
         Polygon.Draw(C.HBmp^,col,clGreen32);
       end;
    2: begin
         Polygon.Add(FixedPoint(x2-x1+3,0));
         Polygon.Add(FixedPoint(0,y2-y1));
         Polygon.Draw(C.HBmp^,col,clGreen32);
         C.HBmp.LineT(abs(x1-x2)+3,0,0,abs(y2-y1),clred32);
       end;
    3: begin
         Polygon.Add(FixedPoint(0,0));
         Polygon.Add(FixedPoint(abs(x1-x2)+3,abs(y2-y1)));
         Polygon.Draw(C.HBmp^,col,clGreen32);
         C.HBmp.LineT(0,0,abs(x1-x2)+3,abs(y2-y1),clred32);
       end;
  end;
  C.HBmp.EndUpdate;
  Form1.Image321.EndUpdate;
  Form1.Image321.Changed;
  Form1.Image321.Invalidate;

end;

procedure TGraphEditor.onLoseFocus(obj:GEObject);
var dstrect,srcrect:TRect;
begin
  if ((obj.Node<>nil) and (obj.isNode)) then with obj.Node^ do
    if (not GE.doinLine) then
    begin
    //render in led
      if ActIn<>-1 then
      begin
        srcrect:=Rect(56,0,56+18,11);
        dstrect:=Inputs[ActIn].Rect;
        ActIn:=-1;
        GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
      end;
    //render out led
      if ActOut<>-1 then
      begin
        srcrect:=Rect(56,32,56+18,43);
        dstrect:=Outputs[ActOut].Rect;
        ActOut:=-1;
        GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
      end;
    end;
    if ((obj.Connection<>nil) and (obj.isConnection)) then
      DrawLink(Obj.Connection,Obj.Connection.link_color);
end;

procedure TGraphEditor.onFocus(obj:GEObject; IOB:byte; io_id:integer);
var dstrect,srcrect:TRect;
begin
  if (obj.isNode) then with Obj.Node^ do
  case IOB of
  0: begin srcrect:=Rect(56,0,56+18,11);
          dstrect:=Inputs[io_id].Rect;
          GE.Dwn.DrawTo(HBmp^,dstrect,srcrect);
          HBmp.Changed;
          if(Inputs[io_id].Name<>'') then
             Form1.Console.Text:=Format('%s.%s[%d] Data=%p',[Name,Inputs[io_id].Name,io_id,Inputs[io_id].Data])
          else Form1.Console.Text:=Format('%s.%s[%d] Data=%p',[Name,'Unknow_in',io_id,Inputs[io_id].Data]);
    end;//render active in
  1: begin
            srcrect:=Rect(56,32,56+18,43);
            dstrect:=Outputs[io_id].Rect;
            GE.Dwn.DrawTo(HBmp^,dstrect,srcrect);
            HBmp.Changed;
            if(Outputs[io_id].Name<>'') then
             Form1.Console.Text:=Format('%s.%s[%d] Data=%p',[Name,Outputs[io_id].Name,io_id,Outputs[io_id].Data])
            else Form1.Console.Text:=Format('%s.%s[%d] Data=%p',[Name,'Unknow_out',io_id,Outputs[io_id].Data]);
     end;//render active out
  end;
  //if connection render white
  if (obj.isConnection) then
  begin
    DrawLink(Obj.Connection,clYellow32);
    Form1.Console.Lines[0]:=Format('Link: %s[in_%d]->%s[out_%d]',[Nodes[Obj.Connection.src].Name,Obj.Connection.out_id,Nodes[Obj.Connection.dst].Name,Obj.Connection.in_id]);
    //Application.HintMouseMessage();
  end;
end;

procedure TGraphEditor.SelectNode(P:PNode);
var srcrect:TRect;
begin
//  Form1.PageControl1.ActivePage:=Form1.TabSheet5;
  if (P=nil) then exit;
  srcrect:=Rect(20,11,20+10,33);
  //render unselected
  if(SelNode<>nil) then with SelNode^ do
  begin
    Nrm.DrawTo(HBmp^,BodyRect,srcrect);
    HBmp^.RenderText(14+((BodyRect.Right-3) div 2-HBmp.TextWidth(Name) div 2),13+(15-HBmp.TextHeight(Name)) div 2,Name,0,Color32(clWhite));
  end;
  //render currently selected
  with P^ do
  begin
    Dwn.DrawTo(HBmp^,BodyRect,srcrect);
    HBmp^.RenderText(14+((BodyRect.Right-3) div 2-HBmp.TextWidth(Name) div 2),13+(15-HBmp.TextHeight(Name)) div 2,Name,0,Color32(clWhite));
  end;
  Form1.Console.Lines[0]:='SelectNode  '+'"'+P.Name+'"';

 //ON CLICK EVENTS HANDLER

  if(SelNode=nil) then P.SetParamsToGUI(Form1.TabSheet5)
  else
    if(SelNode^<>P^) then P.SetParamsToGUI(Form1.TabSheet5);

  SelNode:=P;

 //renderin WHOLE TREE
  if SelNode^.NumInputs>0 then  SelNode^.ProcessTree;

  //render node buffer to active layout
  if(SelNode^.Data<>nil) then  SelNode^.RenderBuffer(SelNode.ActLayout);

end;

procedure TGraphEditor.ResetActObj;
begin
  ActObj.isNode:=false;
  ActObj.isConnection:=false;
  ActObj.isLayout:=false;
end;

constructor TFileInManager.Create(Node:PNode);
begin
//  Filenames:=TStrings.Create;
  ParentNode:=Node;
  FrameBuffers:=TBitmap32Collection.Create(Form1,TBitmap32Item);
  isFrameBuffered:=True;
  JumpKeyFrames:=False;
  StartBuf:=0;
  MaxBuffers:=2;
  Filenames:=TStringList.Create;
  FILE_IN_TYPE:=255;
end;

destructor TFileInManager.Destroy;
begin
  if (FILE_IN_TYPE=FIN_AVI) then CloseAVIFile;
  FreeBuffers;
  Filenames.Free;
{  if (Filenames<>nil)then
    while Filenames.Count<>0 do
      Filenames.Delete(0);}
  FrameBuffers.Free;
end;

procedure TFileInManager.FreeBuffers;
begin
  while FrameBuffers.Count<>0 do
    FrameBuffers.Delete(0);
end;

procedure TFileInManager.LoadImageSequence;
var i,EndBuf:integer;
begin
  if (StartBuf>=FrameCount) then exit;
  if ((StartBuf+MaxBuffers)>FrameCount) then
   EndBuf:=FrameCount
  else EndBuf:=StartBuf+MaxBuffers;

  for i:=StartBuf to EndBuf-1 do
  begin
    //check if buffer exist
    if ((i-StartBuf)>(FrameBuffers.Count-1)) then
     FrameBuffers.Add;
    //load data
    try
      FrameBuffers.Items[i-StartBuf].Bitmap.LoadFromFile(Filenames.Strings[i]);
    except end;
  end;
    //assign buffers to outputs
    for i:=0 to ParentNode.NumOutputs-1 do
    if i<=EndBuf-1 then
      ParentNode.Outputs[i].Data:=@FrameBuffers.Items[i].Bitmap;
end;

procedure TFileInManager.Open;
var ext:string; i:integer;
begin
//  Filenames:=fnames;
  i:=0;
  while i<Filenames.Count do
   if (not FileExists(Filenames.Strings[i])) then
   begin
     if Filenames.Count=1 then
     begin
        Filenames.Clear;
        break;
     end;
     Filenames.Delete(i);
     Form1.Console.Lines.Add(Format('File %s not found',[Filenames.Strings[i]]));
     dec(FrameCount);
   end
   else inc(i);

  FrameCount:=Filenames.Count;
  if Filenames.Count=0 then exit;

  MaxBuffers:=ParentNode.GetParam('Frame Buffers').int^;

  if(FILE_IN_TYPE<>255) then
  begin
    //free databuf
    while FrameBuffers.Count<>0 do
      FrameBuffers.Delete(0);
    for i:=0 to ParentNode.NumOutputs-1 do
      ParentNode.Outputs[i].Data:=nil;
  end;

  if (FILE_IN_TYPE=FIN_AVI) then
    CloseAVIFile;

  //open avi
  ext:=ExtractFileExt(filenames.Strings[0]);
  if filenames.Count=1 then
    if ext='.avi' then
    begin
      OpenAVIFile(filenames.Strings[0]);
      FILE_IN_TYPE:=FIN_AVI;
      LoadFrame(0);
      exit;
    end;
  //or open sequence
  FILE_IN_TYPE:=FIN_SEQ;
  //load first images from files to frame buffers
  LoadImageSequence;
  LoadFrame(0);
end;

procedure TFileInManager.OpenAVIFile(filename:string);
var
  Error: Integer;
  hBmp: HBITMAP;
  sError: string;
begin
//  Result := False;
  // Initialize the AVIFile library.
  AVIFileInit;

  // The AVIFileOpen function opens an AVI file
  Error := AVIFileOpen(pFile, PChar(filename), 0, nil);
  if Error <> 0 then
  begin
    AVIFileExit;
    case Error of
      AVIERR_BADFORMAT: sError := 'The file couldn''t be read';
      AVIERR_MEMORY: sError := 'The file could not be opened because of insufficient memory.';
      AVIERR_FILEREAD: sError := 'A disk error occurred while reading the file.';
      AVIERR_FILEOPEN: sError := 'A disk error occurred while opening the file.';
    end;
    ShowMessage(sError);
    Exit;
  end;

  // AVIFileInfo obtains information about an AVI file
  if AVIFileInfo(pFile, @AVIINFO, SizeOf(AVIINFO)) <> AVIERR_OK then
  begin
    // Clean up and exit
    AVIFileRelease(pFile);
    AVIFileExit;
    Exit;
  end;
  FrameCount:=AVIINFO.dwLength;
  FrameRate:=AVIINFO.dwRate;
  // Open a Stream from the file
  Error := AVIFileGetStream(pFile, AVIStream, streamtypeVIDEO, 0);
  if Error <> AVIERR_OK then
  begin
    // Clean up and exit
    AVIFileRelease(pFile);
    AVIFileExit;
    Exit;
  end;

  // Prepares to decompress video frames
  gapgf := AVIStreamGetFrameOpen(AVIStream, nil);
  if gapgf = nil then
  begin
    AVIStreamRelease(AVIStream);
    AVIFileRelease(pFile);
    AVIFileExit;
    Exit;
  end;
  //load first frames to framebuffer
  LoadAVIFrames;
end;

procedure TFileInManager.CloseAVIFile;
begin
    AVIStreamGetFrameClose(gapgf);
    AVIStreamRelease(AVIStream);
    AVIFileRelease(pfile);
    AVIFileExit;
end;

procedure TFileInManager.LoadAVIFrames;
var
     lpbi: PBITMAPINFOHEADER;
     sError: string;
     Bits:Pointer;
     i, EndBuf:longint;
begin
  if (StartBuf>FrameCount) then exit;
  if ((StartBuf+MaxBuffers)>FrameCount) then
   EndBuf:=FrameCount
  else EndBuf:=StartBuf+MaxBuffers;

  for i:=StartBuf to EndBuf do
  begin
     lpbi := AVIStreamGetFrame(gapgf, i);
     if lpbi = nil then
     begin
      AVIStreamGetFrameClose(gapgf);
      AVIStreamRelease(AVIStream);
      AVIFileRelease(pFile);
      AVIFileExit;
      Exit;
     end;
     //check if buffer exist
     if ((i-StartBuf)>(FrameBuffers.Count-1)) then
       FrameBuffers.Add;
     //check size of a buffer
     if (lpbi.biWidth<>FrameBuffers.Items[i-StartBuf].Bitmap.Width) or (lpbi.biHeight<>FrameBuffers.Items[i-StartBuf].Bitmap.Height) then
       FrameBuffers.Items[i-StartBuf].Bitmap.SetSize(lpbi.biWidth,lpbi.biHeight);
     //set buffer bits
     Bits:=Pointer(Integer(lpbi) + SizeOf(TBITMAPINFOHEADER));
     SetDIBits(FrameBuffers.Items[i-StartBuf].Bitmap.Handle,FrameBuffers.Items[i-StartBuf].Bitmap.BitmapHandle,0,lpbi.biHeight,Bits,PBITMAPINFO(lpbi)^,DIB_RGB_COLORS);
  end;
end;

procedure TFileInManager.LoadFrame(index:integer);
var EndBuf,Delta,i:integer;
begin
//  FrameOffset:=ParentNode.GetParam('Frame Offset').int^;
//  index:=FrameOffset+index;
{  if (FILE_IN_TYPE=FIN_AVI) then
    ParentNode.info:='AVI'
  else ParentNode.info:='NOT AVI';
}
  if(index>=FrameCount) then exit;

  MaxBuffers:=ParentNode.GetParam('Frame Buffers').int^;
  Delta:=ParentNode.GetParam('Frames Delta').int^;

  if (StartBuf>FrameCount) then
    StartBuf:=FrameCount-MaxBuffers;

  if ((StartBuf+MaxBuffers)>FrameCount) then
   EndBuf:=FrameCount
  else EndBuf:=StartBuf+MaxBuffers;

  if (index>=StartBuf) and (index<=EndBuf-1) then
  begin
    if ((index-StartBuf)>FrameBuffers.Count) then exit;
    ParentNode.Data:=@FrameBuffers.Items[index-StartBuf].Bitmap;
    //assign buffers to outputs
    for i:=0 to ParentNode.NumOutputs-1 do
    if ((index-StartBuf+i*Delta)<=(FrameBuffers.Count-1)) then
    begin
      ParentNode.Outputs[i].Data:=@FrameBuffers.Items[index-StartBuf+i*Delta].Bitmap;
    end;
    //ParentNode.AssignAllOutputs(ParentNode.Data);
 //   for i:=0 to ParentNode.Outputs[0].Linked.Count-1 do
//      PNode(ParentNode.Outputs[0].Linked.Items[i]).Status.Processed:=false;
  end
  else
  begin
    StartBuf:=index;
    case FILE_IN_TYPE of
      FIN_AVI: LoadAVIFrames;
      FIN_SEQ: LoadImageSequence;
    end;
  end;

end;


constructor TNode.Create(Lays:PLayerCollection);
var Lay:TBitmapLayer;
  begin
  Lay:=TBitmapLayer.Create(Lays^);
  Lay.AlphaHit:=true;
  Lay.Cropped:=true;
  Lay.Bitmap.DrawMode:=dmOpaque;
  Lay.Bitmap.StretchFilter:=sfLinear;
  //skin setup
  Skin.LeftRect:=Rect(0,0,20,43);
  Skin.TextRect:=Rect(20,11,20+10,33);
  Skin.RightRect:=Rect(112,0,112+35,43);
  Skin.InputRect:=Rect(56,0,56+18,11);
  Skin.OutputRect:=Rect(56,32,56+18,43);
  //param list create
  param_list:=TList.Create;
  param_names:=TStringList.Create;
  @frame_event:=nil;
  p_manager:=nil;
  @p_proc:=nil;
  TreePath:=TList.Create;
  TreePath.Add(@Self);
  Status.Enabled:=true;
  Status.Processed:=false;
  Status.Rendered:=false;
  New(Data);
  Data^:=TBitmap32.Create;
  PLayers:=Lays; // ???????? ?????? ?? ???? ? TNode
  HBmp:=@TBitmapLayer(PLayers.Items[Lay.Index]).Bitmap;
//  PLayer:=TBitmapLayer(PLayers.Items[0]);
  HBmp.Font.Size:=12;
  HBmp.StretchFilter:=sfMitchell;
  HBmp.DrawMode:=dmBlend;
  ActIn:=-1;
  ActOut:=-1;
  ActLayout:=0;
  inQuenque:=false;
  loc.x:=15; loc.y:=15;
  loc.dragstate:=0;
end;

destructor TNode.Destroy;
var i:integer;
begin
  for i:=0 to param_list.Count-1 do
   Dispose(param_list.Items[i]);
  param_list.Free;
  if p_manager<>nil then
  begin
    p_manager.Destroy;
    Dispose(p_manager);
  end
  else DestroyData;
end;

procedure TNode.DestroyData;
begin
  if Data<>nil then
  begin
    Data.Free;
//  Dispose(Data);
    Data:=nil;
  end;
end;

procedure TNode.SetNumOutputs(Num:integer);
var i:integer;
begin
  if (Num<=0) or (NumOutputs=Num) then exit;
  if(NumOutputs<Num) then
  begin
    SetLength(Outputs,Num);
    for i:=NumOutputs to Num-1 do
      Outputs[i].Linked:=TList.Create;
  end
  else
  begin
     for i:=Num to NumOutputs-1 do
     begin
       //GE.DeleteConnection();
      //check connections to delete
      Outputs[i].Linked.Free;
     end;
    SetLength(Outputs,Num);
  end;
  NumOutputs:=Num;
  Update;
end;

procedure TNode.AssignAllOutputs(P:Pointer);
var i,j:integer;
begin
  for i:=0 to NumOutputs-1 do
  begin
    Outputs[i].Data:=P;
  end;
end;

procedure TNode.Update;
var dstrect,srcrect:TRect; i,cw,dt:integer;
begin
  //center border width
  if (NumOutputs>=NumInputs) then cw:=HBmp.TextWidth(Name)+NumOutputs*18
  else cw:=HBmp.TextWidth(Name)+NumInputs*18;
  HBmp.SetSize(20+cw+40,GE.Nrm.Height);
  //left border
  srcrect:=Rect(0,0,20,GE.Nrm.Height);
  dstrect:=srcrect;
  GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
  //body
  srcrect:=Rect(20,11,20+10,33);
  dstrect:=Rect(20,11,cw+3,33);
  BodyRect:=dstrect; //for mouse ops
  GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
  //right border
  srcrect:=Rect(112,0,112+35,GE.Nrm.Height);
  dstrect:=Rect(cw+3,0,cw+35,GE.Nrm.Height);
  GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
  //render Name
  HBmp.RenderText(14+(cw div 2-HBmp.TextWidth(Name) div 2),13+(15-HBmp.TextHeight(Name)) div 2,Name,0,Color32(clWhite));
  //set input chain
  srcrect:=Rect(56,0,56+18,11);
  dt:=0;
  for i:=0 to NumInputs-1 do
  begin
    dt:=dt+(cw div (NumInputs+1));
    dstrect:=Rect(dt,0,18+dt,11);
    Inputs[i].Rect:=dstrect;
    GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
  end;
  //set output chain
  srcrect:=Rect(56,32,56+18,43);
  dt:=0;
  for i:=0 to NumOutputs-1 do
  begin
    dt:=dt+(cw div (NumOutputs+1));
    dstrect:=Rect(dt,32,18+dt,43);
    Outputs[i].Rect:=dstrect;
    GE.Nrm.DrawTo(HBmp^,dstrect,srcrect);
  end;
  //find & setup layer pos
   TBitmapLayer(PLayers.Items[GE.FindLayerByBmp(HBmp)]).Location:=FloatRect(loc.x,loc.y,HBmp.Width+loc.x,HBmp.Height+loc.y);
end;

procedure TNode.RenderBuffer(LayoutIndex:integer);
begin
   Status.Rendered:=true;
  if (Data=nil) then
  begin
    Form1.console.Text:=Name+': No Data For Rendering';
    Exit;
  end;
  if((LayoutIndex<GE.Layouts.count) and (LayoutIndex<>-1)) then
  begin
       TLayout(GE.Layouts.Items[LayoutIndex]).Draw(Data);
  end
  else Form1.console.Text:=Name+': No Layouts for rendering';

end;

procedure TreeBacktrace(Root,CheckNode:PNode);
var i:integer;
begin
 for i:=0 to CheckNode.NumInputs-1 do
 begin
   if(Root.TreePath.IndexOf(CheckNode)=-1) then
     Root.TreePath.Add(CheckNode);
   //set order value to up node
   if (CheckNode.Inputs[i].Linked.Count<>0) then
     PNode(CheckNode.Inputs[i].Linked.Items[0]).Order:=CheckNode.Order+1;
   //backtrace up node
   if (CheckNode.Inputs[i].Linked.Count>0) then
     TreeBacktrace(Root, CheckNode.Inputs[i].Linked.Items[0]);
 end;
end;

function OrderCompare(Item1, Item2:Pointer):Integer;
var i:integer;
begin
  result:=0;
  if(PNode(Item1)^.Order>PNode(Item2)^.Order) then result:=-1 else result:=1;
  if(PNode(Item1)^.Order=PNode(Item2)^.Order) then result:=0;
end;

procedure TNode.ProcessTree;
var i:integer; N,UpdatedN:PNode; job:boolean;
    ticks:Cardinal;
begin
  Self.Order:=0;
{  for i:=0 to GE.NumNodes-1 do
  begin
    GE.Nodes[i].TreePath.Clear;
    TreeBacktrace(GE.Nodes[i], GE.Nodes[i]);
  end; }
  TreePath.Clear;
  TreeBacktrace(@Self, @Self);
  TreePath.Sort(OrderCompare);
  UpdatedN:=nil;

  ticks:=GetTickCount;

  if TreePath.Count=0 then exit;
  for i:=0 to TreePath.Count-1 do
  begin
    N:=PNode(TreePath.Items[i]);
    //if(not N.Status.Processed) then UpdatedN:=N;
//    if UpdatedN<>nil then
//    begin
//      if(N.TreePath.IndexOf(UpdatedN)<>-1) then
//      begin
        if(@N.p_proc<>nil) then N.p_proc(N);
        N.Status.Processed:=true;
        GE.UpdateNodeConnections(N);
//        Form1.memo1.Lines.Add(PNode(TreePath.Items[i]).Name+' '+inttostr(PNode(TreePath.Items[i]).Order));
//        UpdatedN:=nil;
//      end;
   end;

   //Form1.Console.Text:=inttostr(GetTickCount-ticks)+' msec';

end;

function TNode.GetParam(Name:string):PParam;
var i:integer;
begin
  i:=param_names.IndexOf(Name);
  if i<>-1 then
    result:=PParam(param_list.Items[i])
  else result:=nil;
end;


procedure TNode.AddStrParam(description:string; default:string);
var param:PParam;
begin
    New(param);
    New(param.str);
    param^.str^:=default;
    param^.int:=nil;
    param^.filename:=nil;
    param^.float:=nil;
    param^.bool:=nil;
    param_list.Add(param);
    param_names.Add(description);
end;

procedure TNode.AddFileParam(filename:string);
var param:PParam;
begin
    New(param);
    New(param.filename);
    param^.filename^:=filename;
    param^.int:=nil;
    param^.str:=nil;
    param^.float:=nil;
    param^.bool:=nil;
    param_list.Add(param);
    param_names.Add('FILENAME');
end;


procedure TNode.AddIntParam(description:string; default:integer; min,max:real);
var param:PParam;
begin
    New(param);
    New(param.int);
    param^.int^:=default;
    param^.range[0]:=min;
    param^.range[1]:=max;
    param^.filename:=nil;
    param^.str:=nil;
    param^.float:=nil;
    param^.bool:=nil;
    param_list.Add(param);
    param_names.Add(description);
end;

procedure TNode.AddBoolParam(description:string; default:boolean);
var param:PParam;
begin
    New(param);
    New(param.bool);
    param^.bool^:=default;
    param^.filename:=nil;
    param^.int:=nil;
    param^.str:=nil;
    param^.float:=nil;
    param_list.Add(param);
    param_names.Add(description);
end;

procedure TNode.AddFloatParam(description:string; default:real; min,max:real);
var param:PParam;
begin
    New(param);
    New(param.float);
    param^.float^:=default;
    param^.range[0]:=min;
    param^.range[1]:=max;
    param^.filename:=nil;
    param^.int:=nil;
    param^.str:=nil;
    param^.bool:=nil;
    param_list.Add(param);
    param_names.Add(description);
end;

procedure TForm1.onFileItemClick(Sender: TObject);
var i:integer;
begin
  if OpenPictureDialog1.Execute then
  begin
    if (GE.SelNode.p_manager<>nil) then
    begin
       //GE.SelNode.SetParamsToGUI(TabSheet5);
       TEdit(Sender).Text:=ExtractFileName(OpenPictureDialog1.FileName);
       GE.SelNode.p_manager.Filenames.Clear;
       if (OpenPictureDialog1.Files.Count>0) then
         for i:=0 to OpenPictureDialog1.Files.Count-1 do
           GE.SelNode.p_manager.Filenames.Add(OpenPictureDialog1.Files.Strings[i]);
        GE.SelNode.p_manager.Open;
        GE.UpdateNodeConnections(GE.SelNode);
    end;
   GE.SelNode.RenderBuffer(0);
  end;
end;

procedure TNode.SetParamsToGUI(AOwner:TComponent);
var
  i:integer;
  Edit:TEdit;
  StaticText:TLabel;
  CheckBox:TCheckBox;
  Combo:TComboBox;
  Bar:TGaugeBar;
  P:PParam;
begin

  while (GE.GUI_Elements.Count<>0) do
     GE.GUI_Elements.Delete(0);

  //create descriptions
  for i:=0 to param_list.Count-1 do
  begin
    StaticText:=TLabel.Create(AOwner);
    StaticText.Parent:=TWinControl(AOwner);
    StaticText.AutoSize:=true;
    StaticText.Left:=5;
    StaticText.Top:=14+i*(33);
    P:=param_list.items[i];
    StaticText.Caption:=param_names.Strings[i];
    GE.GUI_Elements.Add(StaticText);
    if (P^.bool=nil) then begin
      Edit:=TEdit.Create(Form1.TabSheet5);
      Edit.Parent:=TWinControl(AOwner);
      Edit.Font.Color:=clBlack;
      //Edit.Name:=param_names.Strings[i];
      Edit.Left:=80;
      Edit.Top:=13+i*33;
      Edit.OnDblClick:=Self.GetParamsFromGUI;
    end;

    if (P^.filename<>nil) then
    begin
      StaticText.font.Style:=[fsBold];
      Edit.Text:=ExtractFileName(P^.filename^);
      Edit.OnClick:=Form1.onFileItemClick;
    end;

    if (P^.str<>nil) then Edit.Text:=P^.str^;
    if (P^.int<>nil) then
    begin
      Edit.Text:=inttostr(P^.int^);
      Edit.Width:=33;
      Bar:=TGaugeBar.Create(AOwner);
      Bar.Parent:=TWinControl(AOwner);
      Bar.Style:=rbsMac;
      Bar.Left:=Edit.Left+35;
      Bar.Top:=Edit.Top+2;
      Bar.Min:=round(P^.range[0]);
      Bar.Max:=round(P^.range[1]);
      Bar.Position:=P^.int^;
      Bar.OnChange:=Self.onSliderChange;
    end;

    if (P^.float<>nil) then
    begin
      Edit.Text:=floattostr(P^.float^);
      Edit.Width:=33;
      Bar:=TGaugeBar.Create(AOwner);
      Bar.Parent:=TWinControl(AOwner);
      Bar.Left:=Edit.Left+35;
      Bar.Top:=Edit.Top+2;
      Bar.Min:=round(P^.range[0]);
      Bar.Max:=round(P^.range[1]);
      Bar.Position:=round(P^.float^);
      Bar.OnChange:=Self.onSliderChange;
    end;

    if (P^.bool<>nil) then
    begin
      CheckBox:=TCheckBox.Create(AOwner);
      CheckBox.Parent:=TWinControl(AOwner);
      CheckBox.Left:=150;
      CheckBox.Top:=13+i*33;
      CheckBox.Checked:=P^.bool^;
      CheckBox.OnClick:=Self.GetParamsFromGUI;
      GE.GUI_Elements.Add(CheckBox);
    end else GE.GUI_Elements.Add(Edit);
   if((P^.int<>nil) or (P^.float<>nil)) then GE.GUI_Elements.Add(Bar);
    //StaticText.Free;
  end;
   //layout selector
   if(GE.Layouts.Count<>0) then
   begin
     CheckBox:=TCheckBox.Create(AOwner);
     CheckBox.Parent:=TWinControl(AOwner);
     CheckBox.Left:=10;
     CheckBox.Top:=13+i*33;
     CheckBox.Checked:=inQuenque;
     CheckBox.Caption:='Update';
     CheckBox.OnClick:=Self.SetQuenque;
     GE.GUI_Elements.Add(CheckBox);
     Combo:=TComboBox.Create(AOwner);
     Combo.Parent:=TWinControl(AOwner);
     Combo.Left:=80;
     Combo.Width:=100;
     Combo.Top:=13+i*33;
     for i:=0 to GE.Layouts.Count-1 do
     begin
       Combo.Items.Add(TLayout(GE.Layouts.Items[i]).Name);
     end;
     Combo.ItemIndex:=ActLayout;
     Combo.OnChange:=SetActLayout;
     GE.GUI_Elements.Add(Combo);
   end;
end;

procedure TNode.SetQuenque(Sender:TObject);
begin
  inQuenque:=not inQuenque;
end;

procedure TNode.SetActLayout(Sender:TObject);
begin
  ActLayout:=TComboBox(Sender).ItemIndex;
  RenderBuffer(ActLayout);
end;

procedure TNode.GetParamsFromGUI(Sender:TObject);
var i,k:integer; P:PParam;
begin
  Status.Processed:=false;
  //get param index
  with GE.GUI_Elements do
  begin
    if Items[IndexOf(Sender)-1] is TLabel then
      i:=Self.param_names.IndexOf(TLabel(Items[IndexOf(Sender)-1]).Caption)
    else exit;
  end;
  //update params
  P:=Self.param_list[i];
//  if P^.str<>nil then
  if param_names.Strings[i]='NODE_NAME' then
  begin
    Self.Name:=TEdit(Sender).Text;
    Self.Update;
    P^.str^:=Self.Name;
    GE.UpdateNodeLinks(@Self);
    //GE.SelectNode(@self);
    Exit;
  end;

  if param_names.Strings[i]='N Outputs' then
  begin
    P^.int^:=strtoint(TEdit(Sender).Text);
    Self.SetNumOutputs(P^.int^);
    GE.UpdateNodeLinks(@Self);
    Exit;
  end;

  if (Sender is TCheckBox) then if (P^.bool<>nil) then P^.bool^:=TCheckBox(Sender).Checked;
  if (P^.str<>nil) then P^.str^:=TEdit(Sender).Text;
  if (P^.int<>nil) then P^.int^:=strtoint(TEdit(Sender).Text);
  if (P^.float<>nil) then P^.float^:=strtofloat(TEdit(Sender).Text);
  if (@p_proc<>nil) then p_proc(@Self);
  if (p_manager<>nil) then p_manager.LoadFrame(Form1.FrameBar.Position);

  //RENDER CURRENT
  RenderBuffer(ActLayout);
  Status.Processed:=false;
  //update nodes in Layouts
  k:=0;
  for i:=0 to GE.NumNodes-1 do
    if (GE.Nodes[i].inQuenque) then
    begin
      GE.Nodes[i].ProcessTree;
      GE.Nodes[i].RenderBuffer(GE.Nodes[i].ActLayout);
      inc(k);
      if(k>GE.Layouts.Count) then break;
    end;
end;

procedure TNode.onSliderChange(Sender:TObject);
var i:integer;
begin
  i:=GE.GUI_Elements.IndexOf(Sender)-1;
  if (GE.GUI_Elements.Items[i] is TEdit) then
  begin
    TEdit(GE.GUI_Elements.Items[i]).Text:=inttostr(TGaugeBar(Sender).Position);
    GetParamsFromGUI(GE.GUI_Elements.Items[i]);
  end;
end;

procedure TForm1.Color_Add(F: TColor32; var B: TColor32; M: TColor32);
begin
//  B := ColorAdd(F, B);
  B := ColorSub(F, B);
end;

procedure TForm1.Image321MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var lx,ly:integer;
begin
  FocusControl(Image321);
  
  if(GE.ActObj.isConnection and (Button=mbRight)) then begin
    Layer.BringToFront;
    GE.DeleteConnection(GE.ActObj.Connection);
    GE.ResetActObj;
  end;

  if (Layer<>nil) and (GE.ActObj.isNode) and (Button=mbLeft) then
  with GE.ActObj.Node^ do
  begin
  //set delta for draging active Node
    loc.dx:=loc.x-x;
    loc.dy:=loc.y-y;
    loc.dragstate:=1;
  //mouse local node coord
    lx:=abs(loc.dx);
    ly:=abs(loc.dy);
  //render body if mouse in area
    try
    if((lx>BodyRect.Left)and(lx<BodyRect.Right)and(ly>BodyRect.Top)and(ly<BodyRect.Bottom))then
      GE.SelectNode(GE.ActObj.Node);
    except
      loc.dragstate:=0;
      GE.onLoseFocus(GE.ActObj);
      exit;
    end;

    Layer.BringToFront;

  //if exist inputs under cursor -- start line creation
    if((ActIn<>-1) or (ActOut<>-1))then
    begin
     loc.dragstate:=0;
     GE.doinLine:=true;
     //move pen in activeinput area for line creation
     if(ActIn=-1) then Image321.Canvas.MoveTo(loc.x+Outputs[ActOut].Rect.Left,loc.y+Outputs[ActOut].Rect.Top)
     else Image321.Canvas.MoveTo(loc.x+Inputs[ActIn].Rect.Left,loc.y+Inputs[ActIn].Rect.Top);
    end;
  end;
  x_d:=x; y_d:=y; //old style (?? ?????? ??????) :))
end;

procedure TForm1.Image321MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer; Layer: TCustomLayer);
var find:GEObject; i:integer; Area:TRect;
begin
Image321.BeginUpdate;
//DRAG OPERATIONS PROCESSING
  if Layer<>nil then
  begin
//    FocusControl(Image321);
    //detect object by layer
    GE.ActObj:=GE.FindObjByLayer(@TBitmapLayer(Layer).Bitmap);
    if (GE.ActObj.isNode) then
   begin
     Hint:=GE.ActObj.Node^.info;
     ShowHint:=true;
    //drag op for node
    with GE.ActObj.Node^ do
      if (loc.dragstate=1) then
      begin
        //save Node coord
        loc.x:=x+loc.dx;
        loc.y:=y+loc.dy;
        Form1.Console.Lines[0]:=Format('Drag Node "%s" %d %d',[Name,loc.x,loc.y]);
        //set Node layer coord
        with TBitmapLayer(Layer) do
        Location:=FloatRect(loc.x,loc.y,Bitmap.Width+loc.x,Bitmap.Height+loc.y);
        //update links
//        if (GE.SelNode<>nil) then
          GE.UpdateNodeLinks(GE.ActObj.Node);
      end;
    end;


    if (GE.ActObj.isConnection) then
    begin
      GE.onLoseFocus(GE.ActObj);
      GE.onFocus(GE.ActObj,0,0); //focus link
    end;

    //if user start connection creation
    if (GE.doinLine) then
    begin
    //find new layer under mouse pos
      for i:=0 to Image321.Layers.Count-1 do
      if(Image321.Layers.Items[i].HitTest(x,y)) then
      begin
         //recognize new object
         find:=GE.FindObjByLayer(@TBitmapLayer(Image321.Layers.Items[i]).Bitmap);
         if (find.isNode) then
         begin
          GE.OldObj:=GE.ActObj;          //save previos obj
          GE.ActObj:=find;
          break;
         end;
      end;
      //render line
      with (Image321.Bitmap) do
      begin
        BeginUpdate;
        Clear(clLightGray32);
        MoveTo(x_d,y_d);
        LineToS(x,y);
        EndUpdate;
        Changed;
      end;
      //GE.onLoseFocus(GE.ActObj);
    end;
  //capture mouse on inputs
    if (GE.ActObj.isNode) then with GE.ActObj.Node^ do
    begin
      GE.onLoseFocus(GE.ActObj);
      //local node axis
      x:=x-loc.x; y:=y-loc.y;
      //check selection in inputs area
      for i:=0 to NumInputs-1 do
      begin
        Area:=Inputs[i].Rect;
        if((X>Area.Left)and(X<Area.Right)and(Y>Area.Top)and(Y<Area.Bottom))then
        begin
          GE.onFocus(GE.ActObj,0,i);
          ActIn:=i;
        end;
      end;
    //check selection in outputs area
      for i:=0 to NumOutputs-1 do
      begin
        Area:=Outputs[i].Rect;
        if((X>Area.Left)and(X<Area.Right)and(Y>Area.Top)and(Y<Area.Bottom))then
        begin
          GE.onFocus(GE.ActObj,1,i);
          ActOut:=i;
        end;
      end;
    end;
  end else
  begin
   GE.onLoseFocus(GE.ActObj);
   GE.ResetActObj;
  end;
Image321.EndUpdate;
Image321.Changed;
Image321.Invalidate;
end;

procedure TForm1.Image321MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if Layer<>nil then
  begin
    if (GE.ActObj.isNode) then with GE.ActObj.Node^ do
      if (loc.dragstate=1)then
      begin
        loc.x:=X+loc.dx;
        loc.y:=Y+loc.dy;
        loc.dragstate:=0;
      end;


    if (GE.doinLine)then
    begin
     //i focus on out\in
     if ((GE.ActObj.Node.ActIn=-1) and (GE.ActObj.Node.ActOut=-1)) then
     begin
       GE.doinLine:=false;
       Image321.Bitmap.Clear(clLightGray32);
       GE.onLoseFocus(GE.OldObj);
       GE.onLoseFocus(GE.ActObj);
       exit;
     end;
     Image321.Bitmap.Clear(clLightGray32);
      //check colision & create connection
      if(GE.OldObj.Node<>GE.ActObj.Node) then
      if ((GE.OldObj.Node.ActIn<>-1) xor (GE.ActObj.Node.ActIn<>-1)) then
      if(GE.OldObj.Node.ActIn=-1) then
        GE.AddConnection(GE.OldObj.Node.ID,
                         GE.ActObj.Node.ID,
                         GE.OldObj.Node.ActOut,
                         GE.ActObj.Node.ActIn)
      else
        GE.AddConnection(GE.ActObj.Node.ID,
                         GE.OldObj.Node.ID,
                         GE.ActObj.Node.ActOut,
                         GE.OldObj.Node.ActIn)
    else Application.MessageBox(PCHAR('MAY BE COLLISION! '+GE.ActObj.Node.Name+'<->'+GE.OldObj.Node.Name), 'Hey!', MB_ICONERROR or MB_OK);

      GE.doinLine:=false;
      GE.onLoseFocus(GE.OldObj);
      GE.onLoseFocus(GE.ActObj);
    end;
  end;
end;


procedure FILE_IN_PROC(N:PNode);
var i:integer;
begin
  N.Status.Rendered:=true;
  if(N.Data<>nil) then
    if (FileExists(N.GetParam('filename').filename^)) then
    begin
      N.Data.LoadFromFile(N.GetParam('filename').filename^);
      N.Outputs[0].Data:=N.Data;
    end
    else Form1.Console.Text:='File not found';
end;

procedure FILE_OUT_PROC(N:PNode);
var fname:string;
begin
  if(N.Inputs[0].Data=nil) then exit;
  fname:=N.GetParam('path').str^;
  fname:=fname + '\' + N.Name + '_' + inttostr(Form1.FrameBar.Position) + '.bmp';
  PBitmap32(N.Inputs[0].Data).SaveToFile(fname);
end;

procedure FRAME_EVENT_FILE_IN(N:PNode; Frame:integer);
var i:integer;
begin
end;

procedure CHECKER_PROC(N:PNode);
var i,j,x,y:integer; S: PColor32; sw,sw2:boolean;
begin
//N:=@TNode(Sender);
  with N^ do
  begin
    if(Data<>nil)then
    begin
      Data^.SetSize(GetParam('WIDTH').int^,GetParam('HEIGHT').int^);
      x:=GetParam('RECT_SIZE').int^;
      //create checker structure
    sw:=true;
    for j:=1 to Data^.Height-2 do
    begin
      S:=@Data^.Bits[j*Data^.Width];     //center line of active element
      if ((j mod x)=0) then sw:=not sw;
      for i:=1 to Data^.Width-2 do
      begin
       if ((i mod x)=0) then sw:=not sw;
       if(sw) then S^:=clblack32
       else S^:=clWhite32;
       inc(S);
      end;
  end;
    end;
  end;
end;

procedure _4SS_PROC(N:PNode);
var Fr1,Fr2,OutputFrame:PBitmap32;
 FourStepObj:FourStepSearch;
begin
  if(N.Inputs[0].Data=nil) then exit;
  if(N.Inputs[1].Data=nil) then exit;
  Fr1:=N.Inputs[0].Data;
  Fr2:=N.Inputs[1].Data;
  OutputFrame:=N.Data;
  OutputFrame.SetSize(Fr1.width,Fr1.Height);
  if(N.GetParam('Switch').bool^) then  Fr1.DrawTo(OutputFrame^)
  else Fr2.DrawTo(OutputFrame^);

  FourStepObj:=FourStepSearch.Create(Fr1,Fr2,OutputFrame);
  if(N.GetParam('DrawVectors').bool^)then
  begin
    FourStepObj.MainLoop;
    FourStepObj.DrawVectors(clred32);
  end;
  if(N.GetParam('DrawGrid').bool^)then
    FourStepObj.DrawGrid;

  FourStepObj.Destroy;
end;

procedure WS_PROC(N:PNode);
var  pIn, pIn2,pOut:PBitmap32;
     Buffer:TBitmap32;
     WS:TWatershed;
     BS:TBlockSegment;
     i:integer;
begin
  if(N.Inputs[0].Data=nil) then exit;
//  if(N.Inputs[1].Data=nil) then exit;
  pIn:=N.Inputs[0].Data;
  pOut:=N.Data;
  pOut.SetSize(pIn.width,pIn.Height);
  FastWatershed(pIn,pOut);

end;

procedure GRAD_PROC(N:PNode);
var  pIn, pIn2,pOut:PBitmap32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  pIn:=N.Inputs[0].Data;
  pOut:=N.Data;
  pOut.SetSize(pIn.width,pIn.Height);
  pOut.Clear;
  FastMorphoGrad(pIn,pOut);
end;

procedure RECONSTRUCT_PROC(N:PNode);
var  pIn, pIn2,pOut:PBitmap32; buf:TBitmap32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  if(N.Inputs[1].Data=nil) then exit;
  pIn:=N.Inputs[0].Data;
  pIn2:=N.Inputs[1].Data;
  pOut:=N.Data;
  pOut.SetSize(pIn.width,pIn.Height);
  pOut.Clear;
  pIn2.DrawTo(pOut^);

  buf:=TBitmap32.Create;
  buf.SetSize(pIn.width,pIn.Height);

//   MorphoDilateEx(pIn,@buf);
//  FastGreyReconstr(@buf,pOut,N.GetParam('max_iter').int^);
    FastGreyReconstr(pIn,pOut,N.GetParam('max_iter').int^);
//  buf.DrawTo(pOut^);
//  buf.Free;

//  pOut^.SaveToFile('reconstruct.bmp');
end;

procedure BUGFIX_PROC(N:PNode);
var pIn,pOut:PBitmap32;
begin
  if(N.Inputs[0].Data = nil) then exit;
  pIn:=N.Inputs[0].Data;
  pOut:=N.Data;
  pOut.SetSize(pIn.width,pIn.Height);
  pIn.DrawTo(pOut^);
  //ReconstrBugFix(pOut,clblue32);
  //CCLabeling(pIn,pOut);
end;

procedure MAXTREE_PROC(N:PNode);
var MT:TMaxTree;
    src,dst:PBitmap32;
    S,S1,S2,S3,S4,S5,S6,S7,S8:PColor32;
    ptr_0,ptr_lst:PColor32;
    i,d_lst:Integer;
    D,stribe:Integer;
    qu:TQueue;
    f:Textfile;
begin
 if(N.Inputs[0].Data=nil) then exit;
 src:=N.Inputs[0].Data;
 dst:=N.Data;
 dst.SetSize(src.Width,src.Height);
 MT:=TMaxTree.Create(src,Form1.Memo1);
 MT.Filter(dst,N.GetParam('Path').int^,N.GetParam('N_start').int^,N.GetParam('N_end').int^);
 MT.Free;
// TLayout(GE.Layouts.Items[0]).DrawGistorgam;

end;

procedure RANDOMER_PROC(N:PNode);
var src, dst:PBitmap32;
i,j,level:integer; S,D: PColor32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  S:=@src^.Bits[0];
  D:=@dst^.Bits[0];
  Randomize;
  level:=N.GetParam('NOISE (%)').int^;
  for i:=0 to src.Height*src.Width - 1 do
  begin
    if (random(100)<level) then D^:=Color32(random(255),random(255),random(255))
    else D^:=S^;
    inc(S); inc(D);
  end;
end;

procedure GRAY_PROC(N:PNode);
var src, dst:PBitmap32;
i,j:integer; S,D: PColor32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  S:=@src^.Bits[0];
  D:=@dst^.Bits[0];
  for i:=0 to src.Height*src.Width - 1 do
  begin
    D^ := Gray32(Intensity(S^));
    inc(S); inc(D);
  end;
end;

procedure STROB_PROC(N:PNode);
var src, src2, dst:PBitmap32;
    i,j,k,tmp,level,Steps,sum:integer; S,D: PColor32Array;
    SumX,SumY:array of integer; Strb:TRect;
begin
  if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  level:=N.GetParam('Noise_level').int^;
  src:=N.Inputs[0].Data;
  src2:=N.Inputs[1].Data;
  if (src2=nil) then src2:=src;
  if(N.GetParam('Conture\Overlay').bool^)then src2:=src;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  S:=@src^.Bits[0];
//  D:=@dst^.Bits[0];
  SetLength(SumX,src.Height);
  SetLength(SumY,src.Width);
  sum:=0;
  //scan line
  for j:=0 to src.Height-1 do
  begin
    S:=@src^.Bits[j*src.width];
    SumX[j]:=sum;
    sum:=0;
    for i:=0 to src.Width-1 do sum:=sum+((S[i] and $00000FF) shr 7);
  end;
  sum:=0;
  //scan row
  for i:=0 to src.Width-1 do
  begin
    SumY[i]:=sum;
    sum:=0;
    for j:=0 to src.Height-1 do
    begin
      S:=@src^.Bits[j*src.width];
      sum:=sum+((S[i] and $00000FF) shr 7);
    end;
  end;
  //set bounding rect
  Steps:=N.GetParam('Steps').int^;
  Strb:=Rect(0,0,0,0);
  i:=0; k:=0;
  while i<src.Width do
  begin
    tmp:=0;
    for k:=0 to Steps*2 do if(SumY[i+k]>level) then inc(tmp);
    if tmp>Steps then
    begin
      Strb.Left:=i;
      break;
    end
    else i:=i+1;
  end;

  i:=src.Width-1;

  while i>Steps*2 do
  begin
    tmp:=0;
    for k:=0 to Steps*2 do if(SumY[i-k]>level) then inc(tmp);
    if tmp>Steps then
    begin
      Strb.Right:=i;
      break;
    end
    else i:=i-1;
  end;

  j:=0;

  while j<src.Height do
  begin
    tmp:=0;
    for k:=0 to Steps*2 do if(SumX[j+k]>level) then inc(tmp);
    if tmp>Steps then
    begin
      Strb.top:=j;
      break;
    end
    else j:=j+1;
  end;

   j:=src.Height-1;

  while j>Steps*2 do
  begin
    tmp:=0;
    for k:=0 to Steps*2 do if(SumX[j-k]>level) then inc(tmp);
    if tmp>Steps then
    begin
      Strb.Bottom:=j;
      break;
    end
    else j:=j-1;
  end;

  if(Strb.Bottom<Strb.Top) then begin j:=Strb.Bottom; Strb.Bottom:=Strb.Top; Strb.Top:=j; end;
  if(Strb.Right<Strb.Left) then begin j:=Strb.Right; Strb.Right:=Strb.left; Strb.left:=j; end;
  if(Strb.Right>src^.Width-1) then Strb.Right:=src^.Width;

  //draw bounding rect
    src2^.DrawTo(dst^);

  if(N.GetParam('Show_Gistogram').bool^)then
  begin
    for i:=0 to src.Width-1 do
     dst^.Line(i,0,i,SumY[i],clred32);
    for j:=0 to src.Height-1 do
     dst^.Line(0,j,SumX[j],j,clred32);
  end;

//fil rect
//  dst^.FillRectTS(Strb,Color32(0,255,255,100));
  if(not N.GetParam('Conture\Overlay').bool^)then
  for j:=Strb.Top to Strb.Bottom do
  begin
    S:=@src2^.Bits[j*src.width];
    D:=@dst^.Bits[j*src.width];
    for i:=Strb.Left to Strb.Right do
      D[i]:=S[i] and $0000FFFF;
  end;

//edges of rect
   dst^.Line(Strb.Left,Strb.top,Strb.Right,Strb.top,clWhite32);
   dst^.Line(Strb.Left,Strb.Bottom,Strb.Right,Strb.Bottom,clWhite32);
   dst^.Line(Strb.Left,Strb.top,Strb.Left,Strb.Bottom,clWhite32);
   dst^.Line(Strb.Right,Strb.top,Strb.Right,Strb.Bottom,clWhite32);

   dst^.RenderText(Strb.Left-40,Strb.Top-20,format('Target: (%d,%d,%d,%d)',[Strb.left,Strb.top,Strb.Right,Strb.bottom]),0,clWhite32);
   dst^.RenderText(5,10,'?????????????',0,clWhite32);
   dst^.RenderText(5,22,'????? ??????: in console',0,clWhite32);

{  dst^.RenderText(5,34,'?????? ?????: @SUB_XX_224367',0,clWhite32);
  dst^.RenderText(5,48,'??????? ???? (??): 14.003',0,clWhite32);
 }

end;

procedure INVERT_PROC(N:PNode);
var src, dst:PBitmap32;
i,j:integer; S,D: PColor32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  S:=@src^.Bits[0];
  D:=@dst^.Bits[0];
  for i:=0 to src.Height*src.Width - 1 do
  begin
    D^ := S^ xor $00FFFFFF;
    inc(S); inc(D);
  end;
end;


procedure BIN_PROC(N:PNode);
var src, dst:PBitmap32;
i,j:integer; S,D: PColor32; level, max_level:integer;
begin
  if(N.Inputs[0].Data=nil) then exit;
  level:=N.GetParam('BIN_Level').int^;
  max_level:=N.GetParam('MAX_Level').int^;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  S:=@src^.Bits[0];
  D:=@dst^.Bits[0];
  src.DrawTo(dst^);

  if (level=0) then
  begin
    DistanceFunction(dst);
    exit;
  end;

  for i:=0 to src.Height*src.Width - 1 do
  begin
    if (((S^ and $000000FF)>level) and ((S^ and $000000FF)<max_level)) then
      D^:=clblack32 //Color32((S^ and 255) + level,(S^ and 255) + level,(S^ and 255) + level);//
    else D^:=clwhite32;
    inc(S); inc(D);
  end;


end;


procedure ERODE_PROC(N:PNode);
var src, dst:PBitmap32; i:integer;
begin
  if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  //do proc
  MorphoOpening(src,dst,N.GetParam('N').int^);
end;

procedure DILATE_PROC(N:PNode);
var src, dst:PBitmap32;
begin
 if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  //do proc
  MorphoCloasing(src,dst,N.GetParam('N').int^);
end;

procedure OPEN_CLOSE_PROC(N:PNode);
var src, dst:PBitmap32; buf:TBitmap32;
begin
 if(N.Inputs[0].Data=nil) then exit;
  N.Status.Rendered:=true;
  src:=N.Inputs[0].Data;
  dst:=N.Data;
  if ((src^.Width<>dst^.Width)or(src^.Height<>dst^.Height)) then
    dst.SetSize(src.width,src.Height);
  //do proc
  MorphoOpen_Close(src,dst,N.GetParam('N').int^);
end;

procedure ISUB_PROC(N:PNode);
var src1, src2, dst:PBitmap32;
    i,j:integer; S1,S2,D:PColor32; R,G,B:integer;
    a:boolean; min_w, min_h:integer;
    ptr_lst:PColor32;
    Color_func:function(C1,C2:TColor32):TColor32;
    num1, num2:integer;
begin
  if(N.Inputs[0].Data=nil) then exit;
  if(N.Inputs[1].Data=nil) then exit;
  N.Status.Rendered:=true;
  src1:=N.Inputs[0].Data;
  src2:=N.Inputs[1].Data;
  dst:=N.Data;
  dst.SetSize(src1.Width,src1.Height);

  if(not N.GetParam('ABS').bool^)then
    Color_func:=@ColorSub
  else Color_func:=@ColorSubAbs;

   S1:=src1.PixelPtr[0,0];
   S2:=src2.PixelPtr[0,0];
   D:=dst.PixelPtr[0,0];
   i:=0;
   num1:=0; num2:=0;
   for i:=0 to src1.Height*src1.Width - 1 do
   begin
       if((S1^ and 255)<>255) then inc(num1);
       if((S2^ and 255)<>255) then inc(num2);
       D^:=ColorSubAbs(S1^,S2^);
       inc(S1);
       inc(S2);
       inc(D);
   end;
   Form1.Memo1.Lines.Add(inttostr(num1));
   Form1.Memo1.Lines.Add(inttostr(num2));
   j:=Round((num2 * 100) / num1);
   Form1.Memo1.Lines.Add('sum='+inttostr(j));
   Form1.FastLineSeries1.AddXY(GE.CurrentFrame, j, '', clMaroon);
     //  asm emms end;
    // ticks:Cardinal;
   //  ticks:=GetTickCount;
   //  Form1.Console.Text:=inttostr(GetTickCount-ticks);
end;

procedure IMUL_PROC(N:PNode);
var src1, src2, src3, dst:PBitmap32;
begin
  if(N.Inputs[0].Data=nil) then exit;
  if(N.Inputs[1].Data=nil) then exit;
  if(N.Inputs[2].Data=nil) then exit;
  src1:=N.Inputs[0].Data;
  src2:=N.Inputs[1].Data;
  src3:=N.Inputs[2].Data;
  dst:=N.Data;
  dst.SetSize(src1.width,src1.Height);
  AdaptiveThresold(src1,src2,src3,dst,N.GetParam('Porog').int^);
end;

procedure IAND_PROC(N:PNode);
const ETALON_1 = 800;
      ETALON_2 = 650;
var src1, src2,src3,dst:PBitmap32;
    LblObj:TLabeling;
    i,x,y:integer; str:string; //Grain:PGrain;
begin
  if(N.Inputs[0].Data=nil) then exit;
  if(N.Inputs[1].Data=nil) then exit;
//  if(N.Inputs[2].Data=nil) then exit;
  if (N.GetParam('mode')=nil) then exit;
  N.Status.Rendered:=true;
  src1:=N.Inputs[0].Data;
  src2:=N.Inputs[1].Data;
  src3:=N.Inputs[2].Data;
  dst:=N.Data;
  dst.SetSize(src1.width,src1.Height);
  if(src3<>nil) then
    src3.DrawTo(dst^);

  LblObj:=TLabeling.Create(src1,src2,dst,N.GetParam('mode').bool^,C1_gb,C2_gb);
  //grains statistica
  Form1.Memo1.Clear;
  for i:=0 to LblObj.GrainList_1.Count - 1 do
  begin
    str:=Format('lbl:=%d, npix=%d',[PGrain(LblObj.GrainList_1.Items[i]).lbl,PGrain(LblObj.GrainList_1.Items[i]).npix]);
    Form1.Memo1.Lines.Add(str);
  end;

 x:=GE.CurrentFrame;
 y:=abs(LblObj.nPix1-ETALON_1);
 Form1.FastLineSeries1.AddXY(x, y, '', clMaroon);
    //Form1.Memo1.Lines.Add('nPix1:='+inttostr(LblObj.nPix1));
    //Form1.Memo1.Lines.Add('nPix2:='+inttostr(LblObj.nPix2));
  LblObj.Destroy;

 {
 //i:integer; S1,S2,D:PColor32; L,R1,R2:Byte;
  S1:=@src1^.Bits[0];
  S2:=@src2^.Bits[0];
  if (S2=nil) then exit;
  D:=@dst^.Bits[0];
  for i:=0 to src1.Width*src1.Height-1 do
  begin
    R1:=S1^ and $000000FF;
    R2:=S2^ and $000000FF;
     D^:=clBlack32;
    if ((R1=255) and (R2=255)) then
      D^:=clWhite32;
    inc(S1); inc(S2); inc(D);  end;}
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  DecimalSeparator:='.';
  GE:=TGraphEditor.Create;
  GE.GE_PATH:=GetCurrentDir;
  GE.LoadFromFile(AUTOLOADGRAF_FILENAME);
  Sleep(100);
  GE.AddLayout('Layout_0');
  C1_gb.X:=0;
  C1_gb.Y:=0;
  C2_gb.X:=0;
  C2_gb.Y:=0;
  //GE.SelectNode(GE.GetNode('Watershed'));
  Image321.SetupBitmap(false);
  Image321.Bitmap.PenColor:=SetAlpha(clGray,100);
  Image321.Color:=clLightGray32;
  Image321.Bitmap.Clear(clLightGray32);
  Image321.Bitmap.SetStipple([clWhite32, clRed32, clGreen32, 0, 0, 0]);
end;


procedure TForm1.Image321Resize(Sender: TObject);
begin
Image321.Bitmap.SetSizeFrom(Image321);
Image321.Bitmap.Clear(clLightGray32);
end;

procedure TForm1.GaugeBar1Change(Sender: TObject);
var i:integer;
begin
  Console.Text:='Frame '+inttostr(FrameBar.Position);
//send frame number to all filein nodes
  for i:=0 to GE.NumNodes-1 do
   if(GE.Nodes[i].p_manager<>nil) then
   begin
     if (FrameBar.Position>=GE.Nodes[i].p_manager.FrameCount) then exit;
     GE.Nodes[i].p_manager.LoadFrame(FrameBar.Position);
     GE.CurrentFrame:=FrameBar.Position;
     GE.UpdateNodeConnections(GE.Nodes[i]);
   end;

//process currently selected node
 if (GE.SelNode<>nil) then
 begin
  GE.SelNode.ProcessTree;
  GE.SelNode.RenderBuffer(GE.SelNode.ActLayout);
 end;

{ if (AVIStreamIsKeyFrame(FIN.AVIStream,FrameBar.Position))
 then
   FIN.LoadFrame(FrameBar.Position);
   FIN.Data^.Drawto(GetDC(Form1.Panel1.Handle),0,0);
}
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Panel2.Left:=Form1.Width-Panel2.Width-15;
end;

procedure TForm1.AddLayout1Click(Sender: TObject);
var Frame:TFrame;
begin
   GE.AddLayout('Layout_'+inttostr(GE.Layouts.Count));
end;


procedure TForm1.Image321KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((Key=VK_DELETE) and not GE.doinLine) then
  begin
    if (GE.SelNode<>nil) then
      GE.DeleteNode(GE.SelNode);
    GE.ResetActObj;
  end;

end;

procedure TForm1.ListView1Click(Sender: TObject);
var Node:PNode;
begin
FocusControl(Image321);
  case ListView1.ItemIndex of
  0: begin //FILE_IN
         Node:=GE.AddNode(Random(70),100+Random(70),'FILE_IN',0,1,nil,nil);
         Node.AddFileParam('cyborg_g.bmp');
         Node.AddIntParam('Frame Buffers',30,0,100);
         Node.AddIntParam('N Outputs',1,1,10);
         Node.AddIntParam('Frames Delta',0,0,10);
         Node.SetParamsToGUI(Form1.TabSheet5);
         Node.Outputs[0].Name:='bmp_out';
         New(Node.p_manager);
         //Node.p_proc:=@Node.p_manager.LoadFrame;
         Node.p_manager^:=TFileInManager.Create(Node);
         Node.p_manager.MaxBuffers:=30;
         GE.SelectNode(Node);
     end;

  1: begin //FILE_OUT
       Node:=GE.AddNode(Random(70),100+Random(70),'FILE_OUT',1,0,nil,nil);
       Node.AddStrParam('path',GE.GE_PATH);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@FILE_OUT_PROC;
       Node.Inputs[0].Name:='bmp_in';
       Node.p_proc(Node);
     end;

  2: begin //CHECKER
       Node:=GE.AddNode(Random(70),100+Random(70),'CHECKER',0,1,nil,nil);
       Node.AddIntParam('WIDTH',300,0,900);
       Node.AddIntParam('HEIGHT',300,0,900);
       Node.AddIntParam('RECT_SIZE',24,2,900);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@CHECKER_PROC;
       //Form1.Console.Text:=inttostr(integer(@CHECKER_PROC));
       Node.Outputs[0].Name:='bmp_out';
       Node.p_proc(Node);
     end;

    3: begin //RAND
         Node:=GE.AddNode(Random(70),100+Random(70),'RANDOMER',1,1,nil,nil);
         Node.AddIntParam('SEED',300,0,1000);
         Node.AddIntParam('NOISE (%)',50,0,100);
         Node.SetParamsToGUI(Form1.TabSheet5);
         Node.p_proc:=@RANDOMER_PROC;
         Node.Inputs[0].Name:='image_in';
         Node.Outputs[0].Name:='noised_out';
         Node.p_proc(Node);
     end;
    4: begin //NEW FILE IN AVI SUPPORT
     end;
    else Exit;
  end;
  if (GE.SelNode=nil) then GE.SelNode:=Node;
  GE.SelectNode(Node);
end;

procedure TForm1.ListView2Click(Sender: TObject);
var Node:PNode;
begin
  FocusControl(Image321);
  case ListView2.ItemIndex of
  0: begin //GRAY
       Node:=GE.AddNode(Random(70),100+Random(70),'256_Gray',1,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@GRAY_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;

  1: begin //BINARIZATION
       Node:=GE.AddNode(Random(70),100+Random(70),'BIN',1,1,nil,nil);
       Node.AddIntParam('BIN_Level',125,0,255);
       Node.AddIntParam('MAX_Level',255,0,255);
       Node.AddBoolParam('ext',true);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@BIN_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;

  2: begin //INVERT
       Node:=GE.AddNode(Random(70),100+Random(70),'Invert',1,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@INVERT_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;

  else Exit;
  end;
  if (GE.SelNode=nil) then GE.SelNode:=Node;
    GE.SelectNode(Node);

end;

procedure TForm1.ListView3Click(Sender: TObject);
var Node:PNode;
begin
  FocusControl(Image321);
  case ListView3.ItemIndex of
  0: begin //ERODE
       Node:=GE.AddNode(Random(70),100+Random(70),'ERODE',1,1,nil,nil);
       Node.AddIntParam('N',1,0,100);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@ERODE_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;
  1: begin //DILATE
       Node:=GE.AddNode(Random(70),100+Random(70),'DILATE',1,1,nil,nil);
       Node.AddIntParam('N',1,0,100);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@DILATE_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;
   2: begin //OPEN_CLOSE
       Node:=GE.AddNode(Random(70),100+Random(70),'OPEN_CLOSE',1,1,nil,nil);
       Node.AddIntParam('N',1,0,100);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@OPEN_CLOSE_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;
   else Exit;
  end;
  if (GE.SelNode=nil) then GE.SelNode:=Node;
  GE.SelectNode(Node);
end;

procedure TForm1.ListView4Click(Sender: TObject);
var Node:PNode;
begin
  FocusControl(Image321);
  case ListView4.ItemIndex of
   0: begin //ISUB
       Node:=GE.AddNode(Random(70),100+Random(70),'ISUB',2,1,nil,nil);
       Node.AddBoolParam('ABS',false);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@ISUB_PROC;
       Node.Inputs[0].Name:='A_in';
       Node.Inputs[1].Name:='B_in';
       Node.Outputs[0].Name:='A-B_out';
       Node.p_proc(Node);
     end;
   1: begin //STROB
       Node:=GE.AddNode(Random(70),100+Random(70),'STROB',2,1,nil,nil);
       Node.AddIntParam('Noise_level',30,0,700);
       Node.AddBoolParam('Show_Gistogram',false);
       Node.AddIntParam('Steps',3,1.00,10.00);
       Node.AddBoolParam('Conture\Overlay',false);

       Node.p_proc:=@STROB_PROC;
       Node.SetParamsToGUI(Form1.TabSheet5);
       //Node.p_proc(Node);
     end;
   2: begin //CCLABELING
       Node:=GE.AddNode(Random(70),100+Random(70),'CCLABELING',3,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.AddBoolParam('mode',true);
       Node.p_proc:=@IAND_PROC;
       Node.Inputs[0].Name:='A_in';
       Node.Inputs[1].Name:='B_in';
       Node.Inputs[2].Name:='Overlay_in';
       Node.Outputs[0].Name:='A+B_out';
       Node.p_proc(Node);
     end;
   3: begin //4SS
       Node:=GE.AddNode(Random(70),100+Random(70),'4SS',2,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.AddBoolParam('Switch',false);
       Node.AddBoolParam('DrawGrid',false);
       Node.AddBoolParam('DrawVectors',true);
       Node.p_proc:=@_4SS_PROC;
       Node.p_proc(Node);
     end;

   4: begin //Watershed
       Node:=GE.AddNode(Random(70),100+Random(70),'Watershed',2,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.Inputs[0].Name:='In_bmp';
       Node.Inputs[1].Name:='Grad_Bmp';
       Node.AddBoolParam('Switch',false);
       Node.AddBoolParam('DrawGrid',false);
       Node.AddBoolParam('DrawVectors',true);
       Node.p_proc:=@WS_PROC;
       Node.p_proc(Node);
     end;
     5: begin
       Node:=GE.AddNode(Random(70),100+Random(70),'MorphoGrad',1,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.Inputs[0].Name:='In_bmp';
       Node.Outputs[0].Name:='Grad_Bmp';
       Node.p_proc:=@GRAD_PROC;
       Node.p_proc(Node);
     end;
     6: begin
       Node:=GE.AddNode(Random(70),100+Random(70),'MReconstruct',2,1,nil,nil);
       Node.AddIntParam('max_iter',30,0,700);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.Inputs[0].Name:='Mask_bmp';
       Node.Inputs[1].Name:='Marker_Bmp';
       Node.p_proc:=@RECONSTRUCT_PROC;
       Node.p_proc(Node);
     end;
       7: begin
       Node:=GE.AddNode(Random(70),100+Random(70),'Max-Tree',1,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.AddIntParam('Path',2,0.00,100.00);
       Node.AddIntParam('N_start',0,0.00,100.00);
       Node.AddIntParam('N_end',33,0.00,100.00);
       Node.Inputs[0].Name:='Mask_bmp';
       Node.p_proc:=@MAXTREE_PROC;
       Node.p_proc(Node);
       end;
       8: begin //BUG FIX
       Node:=GE.AddNode(Random(70),100+Random(70),'Bug-Fix',1,1,nil,nil);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@BUGFIX_PROC;
       Node.Inputs[0].Name:='image_in';
       Node.Outputs[0].Name:='image_out';
       Node.p_proc(Node);
     end;
    9: begin //IMUL
       Node:=GE.AddNode(Random(70),100+Random(70),'IMUL',3,1,nil,nil);
       Node.AddBoolParam('ABS',false);
       Node.AddIntParam('Porog',130,0,65025);
       Node.SetParamsToGUI(Form1.TabSheet5);
       Node.p_proc:=@IMUL_PROC;
       Node.Inputs[0].Name:='A_in';
       Node.Inputs[1].Name:='B_in';
       Node.Outputs[0].Name:='A*B_out';
       Node.p_proc(Node);
     end;


   else Exit;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var  Node:PNode;
begin
  FastLineSeries1.Clear;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  GE.Destroy;
end;

procedure TForm1.SaveTo1Click(Sender: TObject);
begin
 if SaveDialog1.Execute then
  GE.SaveToFile(SaveDialog1.fileName);
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
if OpenDialog1.Execute then
  GE.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm1.DeleteAll1Click(Sender: TObject);
begin
  GE.DeleteAllNodes;
end;

procedure TForm1.FormPaint(Sender: TObject);
begin
{  if(GE=nil) then exit;
  graphics := TGPGraphics.Create(Form1.Canvas.Handle);
  aquaBrush  := TGPSolidBrush.Create(MakeColor(255, 180, 255, 255));
//bitmap:=TGPBitmap.Create('bmp\TEST.bmp');
//  graphics.Clear(Form1.Color);
//  graphics.DrawImage(bitmap,40,40,bitmap.GetWidth,bitmap.GetHeight);
  for i:=0 to GE.NumNodes-1 do
  begin
    rect.X:=GE.Nodes[i].loc.x;
    rect.Y:=GE.Nodes[i].loc.y;
    rect.Width:=50;
    rect.Height:=50;
    graphics.SetClip(rect);
    graphics.DrawImage(GE.SkinBmp,GE.Nodes[i].loc.x,GE.Nodes[i].loc.y,GE.SkinBmp.GetWidth,GE.SkinBmp.GetHeight);
  end;
  graphics.Free;}
end;

procedure TForm1.DirectoryOutline1Change(Sender: TObject);
begin
// FileListBox1.Directory:=DirectoryOutline1.Directory;
// FileListBox1.ApplyFilePath(FileListBox1.Directory);
//GetNext

end;


procedure TForm1.Save1Click(Sender: TObject);
begin
  GE.SaveToFile(GE.GraphFilename);
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  TLayout(GE.Layouts.Items[0]).bDrawHitogram:=not TLayout(GE.Layouts.Items[0]).bDrawHitogram;
  if (GE.SelNode.data<>nil) then
  TLayout(GE.Layouts.Items[0]).Draw(GE.SelNode.data);
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var i:integer;
begin
  while FrameBar.Position<SpinEdit1.Value do
  begin
    FrameBar.Position:=FrameBar.Position + 1;
    FrameBar.OnUserChange(Self);
    if GE.Layouts.Count>0 then
      TLayout(GE.Layouts[0]).Frm.Update;
  end;
end;

end.
