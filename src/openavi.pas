procedure flipIt(buffer: Pointer);                                              // Prohodí èervenou a modrou složku pixelù v 
obrázku
{asm                                                                            // Asm kód mi nechodí korektnì, okno se pøi 
animaci neustále zavírá a znovu otvírá...
  mov ecx, 256*256                                                              // Zjistil jsem, že mi nìjakým zpùsobem 
zmìní hodnotu lokální promìnné isMessagePumpActive v proceduøe WinMain
  mov ebx, buffer                                                               // Kdyby nìkdo vìdìl proè, dejte mi prosím 
vìdìt. Pro mì je to záhadou.
@@loop :
  mov al,[ebx+0]
  mov ah,[ebx+2]
  mov [ebx+2],al
  mov [ebx+0],ah
  add ebx,3
  dec ecx
  jnz @@loop  }
var                                                                             // Klasika - jako pøi naèítání TGA textur
  i: integer;
  B, R: PGLubyte;
  temp: GLubyte;
begin
  for i := 0 to 256 * 256 - 1 do                                                // Prochází data obrázku
    begin
    B := Pointer(Integer(buffer) + i * 3);                                      // Ukazatel na B
    R := Pointer(Integer(buffer) + i * 3+2);                                    // Ukazatel na R
    temp := B^;                                                                 // B uložíme do pomocné promìnné
    B^ := R^;                                                                   // R je na správném místì
    R^ := temp;                                                                 // B je na správném místì
    end;
end;

procedure OpenAVI(szFile: LPCSTR);                                              // Otevøe AVI soubor
var
  title: PAnsiChar;                                                             // Pro vypsání textu do titulku okna
  bmi: BITMAPINFO;
  hdd: HDRAWDIB;                                        // Handle DIBu
  h_bitmap: HBITMAP;                                    // Handle bitmapy závislé na zaøízení
  h_dc: HDC;                                            // Kontext zaøízení
  data: Pointer = nil;                                  // Ukazatel na bitmapu o zmìnìné velikosti

begin
  AVIFileInit;                                                                  // Pøipraví knihovnu AVIFile na použití
  if AVIStreamOpenFromFile(pavi,szFile,streamtypeVIDEO,0,OF_READ,nil) <> 0 then // Otevøe AVI proud
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Stream','Error',MB_OK or MB_ICONEXCLAMATION); // Chybová zpráva
  AVIStreamInfo(pavi,psi,sizeof(psi));                                          // Naète informace o proudu
  width := psi.rcFrame.Right - psi.rcFrame.Left;                                // Výpoèet šíøky
  height := psi.rcFrame.Bottom - psi.rcFrame.Top;                               // Výpoèet výšky
  lastframe := AVIStreamLength(pavi);                                           // Poslední snímek proudu
  mpf := AVIStreamSampleToTime(pavi,lastframe) div lastframe;                   // Poèet milisekund na jeden snímek
  with bmih do
    begin
    biSize := sizeof(BITMAPINFOHEADER);                                         // Velikost struktury
    biPlanes := 1;                                                              // BiPlanes
    biBitCount := 24;                                                           // Poèet bitù na pixel
    biWidth := 256;                                                             // Šíøka bitmapy
    biHeight := 256;                                                            // Výška bitmapy
    biCompression := BI_RGB;                                                    // RGB mód
    end;
  bmi.bmiHeader := bmih;
  h_bitmap := CreateDIBSection(h_dc,bmi,DIB_RGB_COLORS,data,0,0);
  SelectObject(h_dc,h_bitmap);                                                  // Zvolí bitmapu do kontextu zaøízení
  pgf := AVIStreamGetFrameOpen(pavi,nil);                                       // Vytvoøí PGETFRAME použitím požadovaného 
módu
  if pgf = nil then                                                             // Neúspìch?
    MessageBox(HWND_DESKTOP,'Failed To Open The AVI Frame','Error',MB_OK or MB_ICONEXCLAMATION);
  title := PAnsiChar(Format('NeHe''s AVI Player: Width: %d, Height: %d, Frames: %d',[width,height,lastframe])); // Informace 
o videu (šíøka, výška, poèet snímkù)
  SetWindowText(g_window.hWnd,title);                                           // Modifikace titulku okna
end;

procedure GrabAVIFrame(frame: integer);                                               // Grabuje požadovaný snímek z proudu
var
  lpbi: PBitmapInfoHeader;                                                            // Hlavièka bitmapy
begin
  lpbi := AVIStreamGetFrame(pgf,frame);                                               // Grabuje data z AVI proudu
  pdata := Pointer(Integer(lpbi) + lpbi.biSize + lpbi.biClrUsed * sizeof(RGBQUAD));   // Ukazatel na data
  DrawDibDraw(hdd,h_dc,0,0,256,256,lpbi,pdata,0,0,width,height,0);                    // Konvertování obrázku na požadovaný 
formát
  flipIt(data);                                                                       // Prohodí R a B složku pixelù
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 256, 256, GL_RGB, GL_UNSIGNED_BYTE, data);  // Aktualizace textury
end;
 
procedure CloseAVI;                                                             // Zavøení AVI souboru
begin
  DeleteObject(h_bitmap);                                                       // Smaže bitmapu
  DrawDibClose(hdd);                                                            // Zavøe DIB
  //AVIStreamGetFrameClose(pgf);                                                  // Dealokace GetFrame zdroje - pøi použití 
hodí chybu, nevím proè
  //AVIStreamRelease(pavi);                                                       // Uvolnìní proudu - pøi použití hodí 
chybu, nevím proè
  AVIFileExit;                                                                  // Uvolnìní souboru
end;
