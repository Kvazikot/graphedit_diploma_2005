//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
//Автор: Владимир Баранов
//wwww@sknt.ru ~ vdbar@rambler.ru
//GDI+ LAYOUT
//UNIT3.pas
//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unit GE_Layout;

interface


uses
//GDIPAPI, GDIPOBJ
  Math, ActnCtrls, QCKSRT,Windows, GR32, GR32_Image, GR32_Layers, GR32_Polygons, GR32_Transforms, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;


type

//BASE LAYOUT CLASS
 TLayout=class
  private
// image : TGPImage;
   Buffer:PBitmap32;
   Image:TImage32;
   //ToolBar:TActionToolBar;
   DC:HDC;
   procedure OnPaint(Sender:TObject);
   procedure OnDblClick(Sender:TObject);
   procedure OnResize(Sender:TObject);
  public
     FName:string;
     Frm:TForm;
     TopMost:boolean;
     bDrawHitogram:boolean;
     Size_X:integer;
     Size_Y:integer;
     CloseEvent:TCloseEvent;
   constructor Create;
   destructor Destroy; override;
   procedure SetName(name:string);
   procedure FormClose(Sender: TObject; var Action: TCloseAction);
   procedure MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer; Layer: TCustomLayer);

   //procedure SetCloseEvent(CloseEvent:TCloseEvent);
   //property  CloseEvent:TCloseEvent; write SetCloseEvent;
   property  Name:string read FName write SetName;
   procedure FastDraw(P:PBitmap32);
   procedure DrawGistorgam;
   procedure Draw(P:PBitmap32);
   procedure OverlayText(outstr:string; x,y:integer);

 end; PLayout=^TLayout;

implementation

uses Types;

constructor TLayout.Create;
begin
  //layout form
  Frm:=TForm.Create(nil);
  Frm.Show;
  Frm.Height:=300;
  Frm.Width:=300;
  Frm.OnResize:=OnResize;
  Frm.OnPaint:=OnPaint;
  Frm.OnClose:=FormClose;
  Frm.Color:=clBlack;
  Frm.BorderStyle:=bsSizeToolWin;
  TopMost:=true;
  bDrawHitogram:=false;
  //drop image ctrl on form
  Image:=TImage32.Create(Frm);
  Image.Parent:=TWinControl(frm);

  Image.Align:=alClient;
  Image.OnMouseMove:=MouseMove;
  Image.OnDblClick:=OnDblClick;
  Image.SetupBitmap(true,clBlack32);
  Image.BitmapAlign:=baTile;
  Image.ScaleMode:=smStretch;
  Image.Bitmap.StretchFilter:=sfNearest;
  DC:=GetDC(Image.Handle);
  Buffer:=@Image.Bitmap;
  Buffer.DrawMode:=dmBlend;
//  Buffer.SetSize(Frm.ClientWidth,Frm.ClientHeight);
//  image := TGPImage.Create('cyborg_g.bmp');
  SetWindowPos(Frm.Handle,HWND_TOPMOST,0,0,300,300,SWP_DRAWFRAME);
end;

procedure TLayout.OnPaint(Sender:TObject);
begin

end;

procedure TLayout.OnResize(Sender:TObject);
begin
//  Image.Bi (Frm.ClientWidth,Frm.ClientHeight);
  OnPaint(Self);
end;

procedure TLayout.OnDblClick(Sender:TObject);
begin
  TopMost:=not TopMost;
  if TopMost then
    SetWindowPos(Frm.Handle,HWND_TOPMOST,Frm.left,Frm.Top,Frm.Width,Frm.Height,SWP_DRAWFRAME)
  else SetWindowPos(Frm.Handle,HWND_NOTOPMOST,Frm.left,Frm.Top,Frm.Width,Frm.Height,SWP_DRAWFRAME)
end;

procedure TLayout.OverlayText(outstr:string; x,y:integer);
var Overlay:TBitmap32;
begin
   Overlay:=TBitmap32.Create;
   with Overlay do
   begin
     SetSize(TextWidth(outstr),TextHeight(outstr));
     RenderText(x,y,outstr,0,clwhite32);
     DrawTo(GetDC(Image.Handle),0,0);
   end;
   Overlay.Free;
end;

procedure TLayout.MouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer; Layer: TCustomLayer);
var outstr, clrstr:string; r1,r2:TRect; sx,sy:real;
 Overlay:TBitmap32;
begin
  r1:=Image.GetViewportRect;
  r2:=Image.Bitmap.BoundsRect;
  sx:=r1.Right / r2.Right;
  sy:=r1.Bottom / r2.Bottom;
  x:=round(x/sx);
  y:=round(y/sy);
 with Image.Bitmap do
   outstr:=format('R=%3.3d G=%3.3d B=%3.3d',[GetRvalue(Pixel[x,y]),GetGvalue(Pixel[x,y]),GetBvalue(Pixel[x,y])]);
  OverlayText(outstr,0,0);
end;

procedure TLayout.Draw(P:PBitmap32);
begin
  if (P^.Empty) then exit;
//P.DrawTo(Image.Bitmap,0,0);
  FastDraw(P);
  if(bDrawHitogram)then
  DrawGistorgam;
 // OnPaint(Self);
//  BufferedDraw(P);
end;

procedure TLayout.FastDraw(P:PBitmap32);
begin
  //check size of bmp
  if((P.Height<20) or (P.Width<20)) then begin Frm.Repaint; Exit; end;
  //check size of window
    if((P.Height<>Buffer.Height) or (P.Width<>Buffer.Width)) then
    begin
      Frm.ClientHeight:=P.Height;
      Frm.ClientWidth:=P.Width;
      Image.Bitmap.Assign(P^);
      Image.Bitmap.Changed;
      Image.Changed;
    end;
  // P.DrawTo(DC,0,0);
   P.DrawTo(Image.Bitmap,0,0);
end;

procedure TLayout.DrawGistorgam;
var i,k,j:integer; S: PColor32;
    Levels:array of integer;
    NormLevels:array of real;
    L:PByte;
    MaxY,MinY:integer;
    x1,x2,y1,y2:integer;
    DiaRect:TRect;
    step:real;
    Norm:real;
begin
  SetLength(Levels,256);
  SetLength(NormLevels,256);

  S:=@Image.Bitmap.Bits[0];
  L:=@Levels[0];
  for i:=0 to 255 do Levels[i]:=0;
  //process image
  for i:=0 to (Buffer.Width-1)*(Buffer.Height-1) do
  begin
    inc(Levels[S^ and 255]);
    inc(S);
  end;

  //ищу 3-4 максимума в гистограмме серий
  for j:=0 to 4 do
  begin
   k:=MaxIntValue(Levels);
   for i:=0 to 255 do
   if(Levels[i]=k)then
   begin
    Levels[i]:=0;
   end;
  end;


//find max
 MaxY:=MaxIntValue(Levels);

 //norm
 for i:=0 to 255 do
   NormLevels[i]:= Levels[i]/MaxY;

 step:=(Buffer.Width-62)/255;

 //Draw Rect for display grafic
  with Buffer^ do
  begin
//    BeginUpdate;
//    BlockTransfer();
    DiaRect.Left:=30;
    DiaRect.Right:=Buffer.Width-30;
    DiaRect.Top:=30;
    DiaRect.Bottom:=Buffer.Height-30;
    FillRectTS(DiaRect,Color32(0,0,250,140));
    HorzLine(DiaRect.Left,DiaRect.Top,DiaRect.Right,clWhite32);
    VertLine(DiaRect.Right,DiaRect.Top,DiaRect.Bottom,clWhite32);
    HorzLine(DiaRect.Left,DiaRect.Bottom,DiaRect.Right,clWhite32);
    VertLine(DiaRect.Left,DiaRect.Top,DiaRect.Bottom,clWhite32);
    //Font.Size:=12;
    //RenderText(30+(Buffer.Width-30)div(TextWidth('Распределение уровней')),40,'Распределение уровней',0,clwhite32);
    y2:=DiaRect.Bottom-1;
    for i:=0 to 255 do
    if(NormLevels[i]<>0)then
    begin
      x1:=DiaRect.Left+round(i*step);
      y1:=DiaRect.Bottom-1-round((DiaRect.Bottom-DiaRect.Top-3)*NormLevels[i]);
      Buffer.VertLine(x1,y1,y2,clWhite32);
      Buffer.HorzLine(x1-1,y1,x1+1,clRed32);
    end;
//    Buffer.VertLine(32+round(0*step),Buffer.Height-round(Buffer.Height*NormLevels[0])+31,Buffer.Height-31,clWhite32);
//    Buffer.VertLine(30+round(255*step),Buffer.Height-round(Buffer.Height*NormLevels[255])+31,Buffer.Height-31,clWhite32);
//    EndUpdate;
 end;
 Image.Update;
end;

{procedure AffineScale
var T: TAffineTransformation;
    sx,sy:Single;
begin
 T := TAffineTransformation.Create;
  T.SrcRect:=FloatRect(0,0,P.Width,P.Height);
  sx:=Frm.ClientWidth/P.Width;
  sy:=Frm.ClientHeight/P.Height;
  T.Scale(sx,sy);
  with Buffer do
  begin
      BeginUpdate;
      //StretchFilter:=sfLanczos;
      Transform(Buffer, P^, T);
      RenderText(10,10,'Buffered Frame',0,clGreen32);
      EndUpdate;
  end;
  T.Free;
end; }

procedure TLayout.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CloseEvent(Self,Action);
end;

procedure TLayout.SetName(name:string);
begin
  Frm.Caption:=name;
  FName:=name;
end;

destructor TLayout.Destroy;
begin
//  Frame.Free;
  Frm.Free;
//  image.Free;
end;

end.



















