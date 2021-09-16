unit GE_BLOCK_SG;

interface

uses
  GR32, Math;

type

  TMacroBlock=record
    p:array of array of PColor32;
    size:integer;
  end;

TBlockSegment=class
public

 Frame1,Frame2,OutputFrame:PBitmap32;
 BasePoint:TPoint;
 Done:boolean;

 constructor Create(Fr1,Fr2,Output:PBitmap32);
 destructor  Destroy; override;
 function  GetMacroBlock(Point:TPoint; size:integer):TMacroBlock;
 function  GetSAD(Block1,Block2:TMacroBlock):integer;
 procedure FillMacroBlock(block:TMacroBlock; color:TColor32);
 function  StepIsReal(Point:TPoint; BLOCK_SIZE:integer):boolean;
 procedure MainLoop;

end;

implementation

constructor TBlockSegment.Create(Fr1,Fr2,Output:PBitmap32);
begin
  Frame1:=Fr1;
  Frame2:=Fr2;
  OutputFrame:=Output;
  Done:=false;
  MainLoop;
end;

procedure TBlockSegment.MainLoop;
begin

end;

destructor TBlockSegment.Destroy;
begin
end;

function  TBlockSegment.StepIsReal(Point:TPoint;BLOCK_SIZE:integer):boolean;
begin
  if ((Point.X+BLOCK_SIZE)<Frame1.Width) and ((Point.Y+BLOCK_SIZE)<Frame1.Height)  then
     if ((Point.X-BLOCK_SIZE)>BLOCK_SIZE) and ((Point.Y-BLOCK_SIZE)>BLOCK_SIZE) then
       result:=true
     else result:=false
  else result:=false;
end;

procedure TBlockSegment.FillMacroBlock(block:TMacroBlock; color:TColor32);
var i,j:integer; sw:boolean;
begin
  for i:=0 to block.size-1 do
  for j:=0 to block.size-1 do
      block.p[i,j]^:=color;
end;

function TBlockSegment.GetMacroBlock(point:TPoint; size:integer):TMacroBlock;
var i,j:integer;
begin
  for i:=0 to size-1 do
  for j:=0 to size-1 do
    result.p[i,j]:=Frame1.PixelPtr[Point.X-(size div 2)+i,Point.Y-(size div 2)+j];
end;

function TBlockSegment.GetSAD(Block1,Block2:TMacroBlock):integer;
var i,j:integer; size_min:integer;
begin
 result:=0;
  size_min:=Min(Block1.size,Block2.size);
  for i:=0 to size_min-1 do
  for j:=0 to size_min-1 do
    result:=result+abs((Block1.p[i,j]^ and 255)-(Block2.p[i,j]^and 255));
end;

end.



