Unit QCKSRT;

interface

procedure QuickSort(var A:array of integer; L, R: integer);overload;
//Out_Index - массив начальных индексов после сортировки (для двухсвязности)
procedure QuickSort(var A:array of integer; var Out_Index:array of integer; L, R: integer); overload;

implementation

procedure QuickSort(var A:array of integer; L, R: integer);

  var i, j: integer;
      x, t: integer;

  begin

  while L < R do

    begin

    x:= A[L];

    i:= L; j:= R;

    repeat

      while A[i] < x do inc(i);

      while x < A[j] do dec(j);

      if i <= j then

        begin

        t:= A[i]; A[i]:= A[j]; A[j]:= t;

        inc(i); dec(j);

        end;

    until i > j;

    if (j - L) > (R - i) then

      begin

      QuickSort(A, i, R);

      R:= j;

      end

    else

      begin

      QuickSort(A, L, j);

      L:= i;

      end;

    end; {end of while}

  end; {end of QuickSort}




procedure QuickSort(var A:array of integer; var Out_Index:array of integer; L, R: integer); overload;

  var i, j: integer;
      x, t: integer;

  begin

 for i:=L to R do Out_Index[i]:=i;
 i:=0;

  while L < R do

    begin

    x:= A[L];

    i:= L; j:= R;

    repeat

      while A[i] < x do inc(i);

      while x < A[j] do dec(j);

      if i <= j then

        begin

        t:= A[i]; A[i]:= A[j]; A[j]:= t;
        t:= Out_Index[i]; Out_Index[i]:= Out_Index[j]; Out_Index[j]:= t;

        inc(i); dec(j);

        end;

    until i > j;

    if (j - L) > (R - i) then

      begin

      QuickSort(A, i, R);

      R:= j;

      end

    else

      begin

      QuickSort(A, L, j);

      L:= i;

      end;

    end; {end of while}

  end; {end of QuickSort}

end.
