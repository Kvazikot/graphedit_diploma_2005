unit PixelQuenue;

interface

uses
  GR32, Classes, Math, Contnrs;

type
 PPColor32 = ^PColor32;

 TPixelQuenue = class

    Data: array of PColor32;

    Count: integer;
    p_top:PPColor32;
    p_cur:PPColor32;
    p_0: PPColor32;
    p_lst: PPColor32;

    public
     constructor Create(size:integer);
     destructor  Destroy; override;
     procedure   Push(p:PColor32);
     function    Pop:PColor32;
  end;

implementation

   constructor TPixelQuenue.Create(size:integer);
   begin
     SetLength(Data, size+2);
     p_0:=@Data[0];
     p_lst:=@Data[size];
     p_cur:=p_0;
     p_top:=p_0;
     Count:=0;
   end;

   destructor TPixelQuenue.Destroy;  begin   end;

   procedure TPixelQuenue.Push(p:PColor32);
   begin
     p_cur^:=p;
     inc(p_cur);
     inc(Count);
     //cброс на начало
     if (p_cur = p_lst) then p_cur:=p_0;
   end;

   function  TPixelQuenue.Pop:PColor32;
   begin
     result:=p_top^;
     inc(p_top);
     dec(Count);
     //cброс на начало
     if (p_top = p_lst) then p_top:=p_0;
   end;

end.
