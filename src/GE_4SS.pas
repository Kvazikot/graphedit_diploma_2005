unit GE_4SS;

interface

uses
  GR32;

const
 BLOCK_SIZE=8;
 BLOCK_HALF=BLOCK_SIZE div 2;

type
  TMacroBlock=array[0..BLOCK_SIZE, 0..BLOCK_SIZE] of PColor32;

  TSADPoint=record
   Point:TPoint;
   SAD:integer;
  end;

  TMotionVector= record
   Point1,Point2:TPoint;
   NotNULL:boolean;
  end;

FourStepSearch=class
public

 Frame1,Frame2,OutputFrame:PBitmap32;
 BasePoint:TPoint;
 StepPoints:array[0..8] of TPoint;
 srcBlock:TMacroBlock;
 Done:boolean;
 MotionVectors:array of TMotionVector;
 NumVectors:integer;

 constructor Create(Fr1,Fr2,Output:PBitmap32);
 destructor  Destroy; override;
 function  GetNextSrcBlock:TMacroBlock;
 function  GetMacroBlock(Point:TPoint):TMacroBlock;
 function  GetSAD(Block1,Block2:TMacroBlock):integer;
 function  Search9Points(Point:TPoint):TSADPoint;
 function  StepIsReal(Point:TPoint):boolean;
 procedure MainLoop;
 procedure DrawVectors(Cl:TColor32);
 procedure DrawGrid;
 procedure FillMacroBlock(block:TMacroBlock; color:TColor32);

end;

implementation

var sw:boolean;

constructor FourStepSearch.Create(Fr1,Fr2,Output:PBitmap32);
var step:integer;
begin
  Frame1:=Fr1;
  Frame2:=Fr2;
  OutputFrame:=Output;
  BasePoint.X:=BLOCK_SIZE;
  BasePoint.Y:=BLOCK_SIZE;
  NumVectors:=Frame1.Width*Frame1.Height div 64;
  SetLength(MotionVectors,NumVectors);
  step:=3;
  StepPoints[0]:=Point(-step,step);
  StepPoints[1]:=Point(0,step);
  StepPoints[2]:=Point(step,step);

  StepPoints[3]:=Point(-step,0);
  StepPoints[4]:=Point(0,0);
  StepPoints[5]:=Point(step,0);

  StepPoints[6]:=Point(-step,-step);
  StepPoints[7]:=Point(0,-step);
  StepPoints[8]:=Point(step,-step);
  Done:=false;
end;

destructor FourStepSearch.Destroy;
begin
end;

function  FourStepSearch.StepIsReal(Point:TPoint):boolean;
begin
  if ((Point.X+BLOCK_SIZE)<Frame1.Width) and ((Point.Y+BLOCK_SIZE)<Frame1.Height)  then
     if ((Point.X-BLOCK_SIZE)>BLOCK_SIZE) and ((Point.Y-BLOCK_SIZE)>BLOCK_SIZE) then
       result:=true
     else result:=false
  else result:=false;
end;

procedure FourStepSearch.FillMacroBlock(block:TMacroBlock; color:TColor32);
var i,j:integer; sw:boolean;
begin
  for i:=0 to BLOCK_SIZE-1 do
  for j:=0 to BLOCK_SIZE-1 do
      block[i,j]^:=color;
end;

function  FourStepSearch.Search9Points(Point:TPoint):TSADPoint;
var searchPoint:TPoint; SAD,i:integer;
    searchBlock:TMacroBlock;
begin
    //search min SAD on 9 search points
    result.SAD:=1000;//big value
    for i:=0 to 8 do
    begin
      //set search point
      searchPoint.X:=Point.X+StepPoints[i].X;
      searchPoint.Y:=Point.Y+StepPoints[i].Y;
      //get block
      searchBlock:=GetMacroBlock(searchPoint);
      //get SAD
      SAD:=GetSAD(srcBlock, searchBlock);
      //check min
      if(SAD<result.SAD) then
      begin
       result.SAD:=SAD;
       result.Point:=searchPoint;
      end;
    end;
end;


procedure FourStepSearch.MainLoop;
var Min1,Min2,Min3:TSADPoint; MIN:TPoint;
iBlk:integer; sw:boolean;
begin
  iBlk:=0; Min1.Point:=Point(0,0); Min1.SAD:=0;  Min2:=Min1; Min3:=Min1;
  sw:=true;
  while not Done do
  begin
   //???????? ???? 1-??? ????? ??????? ???? ?? 2-??
    srcBlock:=GetNextSrcBlock();
    //STEP1
    Min1:=Search9Points(BasePoint);
    //STEP2
    if StepIsReal(Min1.Point) then
      Min2:=Search9Points(Min1.Point);
    //STEP3
    if StepIsReal(Min2.Point) then
      Min3:=Search9Points(Min2.Point);

     if (Min3.SAD<Min2.SAD)then MIN:=Min3.Point
     else if (Min2.SAD<Min1.SAD)then MIN:=Min2.Point
          else MIN:=Min1.Point;

    //SET MOTION VECTOR
    if((Min1.SAD<>0))then
    begin
      if abs(BasePoint.X-MIN.X)<50 then
      MotionVectors[iBlk].NotNULL:=true;
      MotionVectors[iBlk].Point1:=BasePoint;
      MotionVectors[iBlk].Point2:=MIN;
      inc(iBlk);
    end;
  end;
end;

procedure FourStepSearch.DrawVectors(Cl:TColor32);
var i:integer;
begin
//  OutputFrame.FillRect(0,0,OutputFrame.Width,OutputFrame.Height,clwhite32);
  for i:=0 to NumVectors-1 do
  if(MotionVectors[i].NotNULL)then
  begin
    OutputFrame.LineTS(MotionVectors[i].Point1.X,
                      MotionVectors[i].Point1.Y,
                      MotionVectors[i].Point2.X,
                      MotionVectors[i].Point2.Y,
                      CL);

    OutputFrame.Pixel[MotionVectors[i].Point2.X,MotionVectors[i].Point2.Y]:=clblue32;
    end;
end;

procedure FourStepSearch.DrawGrid;
var i:integer;
begin
 i:=0;
 while i<OutputFrame.Width-BLOCK_SIZE do
 begin
   OutputFrame.VertLine(i,0,OutputFrame.Height-1,clBlack32);
   i:=i+BLOCK_SIZE;
 end;
 i:=0;
 while i<OutputFrame.Height-BLOCK_SIZE do
 begin
   OutputFrame.HorzLine(0,i,OutputFrame.Width-1,clBlack32);
   i:=i+BLOCK_SIZE;
 end;

end;

function FourStepSearch.GetNextSrcBlock:TMacroBlock;
var i,j:integer; StartPoint:TPoint;
begin
  //???????? ?? ????? ?? ???????
  if (BasePoint.Y>Frame1.Height-BLOCK_SIZE*2) and
     (BasePoint.X>Frame1.Width-BLOCK_SIZE*2) then
  begin
    Done:=true;//????????? ????????
    exit;
  end;
   //????? ??????
   if (BasePoint.X>Frame1.Width-BLOCK_SIZE*2) then
   begin
     BasePoint.X:=BLOCK_SIZE*2;
     BasePoint.Y:=BasePoint.Y+BLOCK_SIZE;
   end
   else BasePoint.X:=BasePoint.X+BLOCK_SIZE;
   //?????? ?????????
  StartPoint.X:=BasePoint.X-BLOCK_HALF;
  StartPoint.Y:=BasePoint.Y-BLOCK_HALF;
  for i:=0 to BLOCK_SIZE-1 do
  for j:=0 to BLOCK_SIZE-1 do
    result[i,j]:=Frame1.PixelPtr[StartPoint.X+i,StartPoint.Y+j];
end;

function FourStepSearch.GetMacroBlock(Point:TPoint):TMacroBlock;
var i,j:integer;
begin
  for i:=0 to BLOCK_SIZE-1 do
  for j:=0 to BLOCK_SIZE-1 do
    result[i,j]:=Frame2.PixelPtr[Point.X-BLOCK_HALF+i,Point.Y-BLOCK_HALF+j];
end;

function FourStepSearch.GetSAD(Block1,Block2:TMacroBlock):integer;
var i,j:integer;
begin
 result:=0;
  for i:=0 to BLOCK_SIZE-1 do
  for j:=0 to BLOCK_SIZE-1 do
    result:=result+abs((Block1[i,j]^ and $00000FF)-(Block2[i,j]^and $00000FF));
end;

end.


