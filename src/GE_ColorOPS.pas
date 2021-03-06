unit GE_ColorOPS;

interface

uses GR32;

function ColorAdd(C1, C2: TColor32): TColor32;
function ColorSub(C1, C2: TColor32): TColor32;
function ColorSubAbs(C1, C2: TColor32): TColor32;
function ColorModulate(C1, C2: TColor32): TColor32;
function ColorMax(C1, C2: TColor32): TColor32;
function ColorMin(C1, C2: TColor32): TColor32;
function Lighten(C: TColor32; Amount: Integer): TColor32;


implementation

{ Color Algebra }

function ColorAdd(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: Integer;
  r2, g2, b2, a2: Integer;
begin
  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  a1 := a1 + a2;
  r1 := r1 + r2;
  g1 := g1 + g2;
  b1 := b1 + b2;

  if a1 > $FF then a1 := $FF;
  if r1 > $FF0000 then r1 := $FF0000;
  if g1 > $FF00 then g1 := $FF00;
  if b1 > $FF then b1 := $FF;

  Result := a1 shl 24 + r1 + g1 + b1;
end;

function ColorSub(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: Integer;
  r2, g2, b2, a2: Integer;
begin
  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  r1 := r1 shr 16;
  g1 := g1 shr 8;

  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  r2 := r2 shr 16;
  g2 := g2 shr 8;

  a1 := a1 - a2;
  r1 := r1 - r2;
  g1 := g1 - g2;
  b1 := b1 - b2;

  if a1 < 0 then a1 := 0;
  if r1 < 0 then r1 := 0;
  if g1 < 0 then g1 := 0;
  if b1 < 0 then b1 := 0;

  Result := a1 shl 24 + r1 shl 16 + g1 shl 8 + b1;
end;

function ColorSubAbs(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: Integer;
  r2, g2, b2, a2: Integer;
begin
//  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  r1 := r1 shr 16;
  g1 := g1 shr 8;

//  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  r2 := r2 shr 16;
  g2 := g2 shr 8;

//  a1 := abs(a1 - a2);
  r1 := abs(r1 - r2);
  g1 := abs(g1 - g2);
  b1 := abs(b1 - b2);

  Result := $FF shl 24 + r1 shl 16 + g1 shl 8 + b1;
end;


function ColorModulate(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: Integer;
  r2, g2, b2, a2: Integer;
begin
  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  r1 := r1 shr 16;
  g1 := g1 shr 8;

  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  r2 := r2 shr 16;
  g2 := g2 shr 8;

  a1 := a1 * a2 shr 8;
  r1 := r1 * r2 shr 8;
  g1 := g1 * g2 shr 8;
  b1 := b1 * b2 shr 8;

  if a1 > 255 then a1 := 255;
  if r1 > 255 then r1 := 255;
  if g1 > 255 then g1 := 255;
  if b1 > 255 then b1 := 255;

  Result := a1 shl 24 + r1 shl 16 + g1 shl 8 + b1;
end;

function ColorMax(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: TColor32;
  r2, g2, b2, a2: TColor32;
begin
  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  if a2 > a1 then a1 := a2;
  if r2 > r1 then r1 := r2;
  if g2 > g1 then g1 := g2;
  if b2 > b1 then b1 := b2;

  Result := a1 shl 24 + r1 + g1 + b1;
end;

function ColorMin(C1, C2: TColor32): TColor32;
var
  r1, g1, b1, a1: TColor32;
  r2, g2, b2, a2: TColor32;
begin
  a1 := C1 shr 24;
  r1 := C1 and $00FF0000;
  g1 := C1 and $0000FF00;
  b1 := C1 and $000000FF;

  a2 := C2 shr 24;
  r2 := C2 and $00FF0000;
  g2 := C2 and $0000FF00;
  b2 := C2 and $000000FF;

  if a2 < a1 then a1 := a2;
  if r2 < r1 then r1 := r2;
  if g2 < g1 then g1 := g2;
  if b2 < b1 then b1 := b2;

  Result := a1 shl 24 + r1 + g1 + b1;
end;

function Lighten(C: TColor32; Amount: Integer): TColor32;
var
  r, g, b, a: Integer;
begin
  a := C shr 24;
  r := C and $00FF0000;
  g := C and $0000FF00;
  b := C and $000000FF;

  r := r shr 16;
  g := g shr 8;

  Inc(r, Amount);
  Inc(g, Amount);
  Inc(b, Amount);

  if r > 255 then r := 255 else if r < 0 then r := 0;
  if g > 255 then g := 255 else if g < 0 then g := 0;
  if b > 255 then b := 255 else if b < 0 then b := 0;

  Result := a shl 24 + r shl 16 + g shl 8 + b;
end;


end.

