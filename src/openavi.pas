procedure flipIt(buffer: Pointer);                                              // Prohod� �ervenou a modrou slo�ku pixel� v 
obr�zku
{asm                                                                            // Asm k�d mi nechod� korektn�, okno se p�i 
animaci neust�le zav�r� a znovu otv�r�...
  mov ecx, 256*256                                                              // Zjistil jsem, �e mi n�jak�m zp�sobem 
zm�n� hodnotu lok�ln� prom�nn� isMessagePumpActive v procedu�e WinMain
  mov ebx, buffer                                                               // Kdyby n�kdo v�d�l pro�, dejte mi pros�m 
v�d�t. Pro m� je to z�hadou.
@@loop :
  mov al,[ebx+0]
  mov ah,[ebx+2]
  mov [ebx+2],al
  mov [ebx+0],ah
  add ebx,3
  dec ecx
  jnz @@loop  }
var                                                                             // Klasika - jako p�i na��t�n� TGA textur
  i: integer;
  B, R: PGLubyte;
  temp: GLubyte;
begin
  for i := 0 to 256 * 256 - 1 do                                                // Proch�z� data obr�zku
    begin
    B := Pointer(Integer(buffer) + i * 3);                                      // Ukazatel na B
    R := Pointer(Integer(buffer) + i * 3+2);                                    // Ukazatel na R
    temp := B^;                                                                 // B ulo��me do pomocn� prom�nn�
    B^ := R^;                                                                   // R je na spr�vn�m m�st�
    R^ := temp;                                                                 // B je na spr�vn�m m�st�
    end;
end;

procedure OpenAVI(szFile: LPCSTR);                                              // Otev�e AVI soubor
var
  title: PAnsiChar;                                                             // Pro vyps�n� textu do titulku okna
  bmi: BITMAPINFO;
  hdd: HDRAWDIB;                                        // Handle DIBu
  h_bitmap: HBITMAP;                                    // Handle bitmapy z�visl� na za��zen�
  h_dc: HDC;                                            // Kontext za��zen�
  data: Pointer = nil;                                  // Ukazatel na bitmapu o zm�n�n� velikosti

begin
  AVIFileInit;                                                                  // P�iprav� knihovnu AVIFile na pou�it�
  if AVIStreamOpenFromFile(pavi,szFile,streamtypeVIDEO,0,OF_READ,nil) <> 0 then // Otev�e AVI proud
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Stream','Error',MB_OK or MB_ICONEXCLAMATION); // Chybov� zpr�va
  AVIStreamInfo(pavi,psi,sizeof(psi));                                          // Na�te informace o proudu
  width := psi.rcFrame.Right - psi.rcFrame.Left;                                // V�po�et ���ky
  height := psi.rcFrame.Bottom - psi.rcFrame.Top;                               // V�po�et v��ky
  lastframe := AVIStreamLength(pavi);                                           // Posledn� sn�mek proudu
  mpf := AVIStreamSampleToTime(pavi,lastframe) div lastframe;                   // Po�et milisekund na jeden sn�mek
  with bmih do
    begin
    biSize := sizeof(BITMAPINFOHEADER);                                         // Velikost struktury
    biPlanes := 1;                                                              // BiPlanes
    biBitCount := 24;                                                           // Po�et bit� na pixel
    biWidth := 256;                                                             // ���ka bitmapy
    biHeight := 256;                                                            // V��ka bitmapy
    biCompression := BI_RGB;                                                    // RGB m�d
    end;
  bmi.bmiHeader := bmih;
  h_bitmap := CreateDIBSection(h_dc,bmi,DIB_RGB_COLORS,data,0,0);
  SelectObject(h_dc,h_bitmap);                                                  // Zvol� bitmapu do kontextu za��zen�
  pgf := AVIStreamGetFrameOpen(pavi,nil);                                       // Vytvo�� PGETFRAME pou�it�m po�adovan�ho 
m�du
  if pgf = nil then                                                             // Ne�sp�ch?
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Frame','Error',MB_OK or MB_ICONEXCLAMATION);
  title := PAnsiChar(Format('NeHe''s AVI Player: Width: %d, Height: %d, Frames: %d',[width,height,lastframe])); // Informace 
o videu (���ka, v��ka, po�et sn�mk�)
  SetWindowText(g_window.hWnd,title);                                           // Modifikace titulku okna
end;

procedure GrabAVIFrame(frame: integer);                                               // Grabuje po�adovan� sn�mek z proudu
var
  lpbi: PBitmapInfoHeader;                                                            // Hlavi�ka bitmapy
begin
  lpbi := AVIStreamGetFrame(pgf,frame);                                               // Grabuje data z AVI proudu
  pdata := Pointer(Integer(lpbi) + lpbi.biSize + lpbi.biClrUsed * sizeof(RGBQUAD));   // Ukazatel na data
  DrawDibDraw(hdd,h_dc,0,0,256,256,lpbi,pdata,0,0,width,height,0);                    // Konvertov�n� obr�zku na po�adovan� 
form�t
  flipIt(data);                                                                       // Prohod� R a B slo�ku pixel�
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 256, 256, GL_RGB, GL_UNSIGNED_BYTE, data);  // Aktualizace textury
end;
 
procedure CloseAVI;                                                             // Zav�en� AVI souboru
begin
  DeleteObject(h_bitmap);                                                       // Sma�e bitmapu
  DrawDibClose(hdd);                                                            // Zav�e DIB
  //AVIStreamGetFrameClose(pgf);                                                  // Dealokace GetFrame zdroje - p�i pou�it� 
hod� chybu, nev�m pro�
  //AVIStreamRelease(pavi);                                                       // Uvoln�n� proudu - p�i pou�it� hod� 
chybu, nev�m pro�
  AVIFileExit;                                                                  // Uvoln�n� souboru
end;
