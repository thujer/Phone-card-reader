Program TelePhoneCardReader;
Uses Crt,Dos,THApp,THString,THOpen,THGS,CZ;
Const
  OEM='Telephone Card Reader';Ver='5.2';
  HelpFile='TCR.HLP';

  Clk=2;
  Rst=1;
  RW=4;

Type
     TZaznam=Record
               NazevPolozky:String[20];
               Data:Array[0..31] of Byte;
             end;

Var
  X,Y,N,Locks0 :Byte;
  Data:Word;
  FSize,I:LongInt;
  F:File of Byte;
  Buffer,FBuffer:Array[0..31] of Byte;
  BinBuf:Array[0..255] of Byte;
  M,Ucc:Boolean;
  A,B:Byte;
  S:String;
  PSoubor,PuvAdr:String[80];
  Zaznam:TZaznam;
  Obsah:Array[0..1018] of String[20];
  DT : DateTime;
  LPT:Word;
  ScrX,ScrY:Byte;



Function Peek(Adr:Byte):String;
Var
  Bit,Byt:Byte;
begin
  Port[LPT]:=(1 xor Rst)or(Port[LPT] and 8);
  Port[LPT]:=(1 xor Rst xor Clk)or(Port[LPT] and 8);
  Port[LPT]:=(1 xor Rst)or(Port[LPT] and 8);
  Port[LPT]:=(1)or(Port[LPT] and 8);
  For Byt:=0 to Adr do
  begin
    Data:=0;
    For Bit:=0 to 7 do
    begin
      Data:=Data shl 1;
      If Port[LPT+1] and $80=0 then Inc(Data);
      Port[LPT]:=(1 xor Clk)or(Port[LPT] and 8);
      Port[LPT]:=(1)or(Port[LPT] and 8);
    end;
  end;
  Peek:=HexByte(Data);
end;


Function PeekDec(Adr:Byte):Byte;
Var
  Bit,Byt:Byte;
begin
  Port[LPT]:=(1 xor Rst)or(Port[LPT] and 8);
  Port[LPT]:=(1 xor Rst xor Clk)or(Port[LPT] and 8);
  Port[LPT]:=(1 xor Rst)or(Port[LPT] and 8);
  Port[LPT]:=(1)or(Port[LPT] and 8);
  For Byt:=0 to Adr do
  begin
    Data:=0;
    For Bit:=0 to 7 do
    begin
      Data:=Data shl 1;
      If Port[LPT+1] and $80=0 then Inc(Data);
      Port[LPT]:=(1 xor Clk)or(Port[LPT] and 8);
      Port[LPT]:=(1)or(Port[LPT] and 8);
    end;
  end;
  PeekDec:=Data;
end;


Procedure ExitHalt(ExitCode: byte);
begin
  Port[LPT]:=0;
  Port[LPT+2]:=0; {37A}
  Chdir(PuvAdr);
  TextCursor(True);
  TextColor(7);TextBackground(0);
  ClrScr;
  Writeln(#10#10#13'Copyright (C) 1999  Tomas Hujer');
  Halt(ExitCode);
end;


Procedure Help;
Var
  T:Text;
begin
  Assign(T,'TCR.TXT');
  Rewrite(T);
  Writeln(T,'TelePhone Card Reader');
  Writeln(T,'Tento program je ur‡en pro ‡ten¡ telefonn¡ch karet p©es paraleln¡');
  Writeln(T,'port LPT1 nebo LPT2. Schema zapojen¡ je v souboru TCR.GIF.');
  Writeln(T,'Kartu je mo‘n‚ nap jet z ploch‚ baterie ( 4.5 V ), ze stabilizovan‚ho zdroje,');
  Writeln(T,'nebo z konektoru klavesnice ( pin 5 je +5V ,pin 4 GND ).'#10#13);
  Writeln(T,'Telefonn¡ karty pou‘¡van‚ v €esk‚ republice £dajnˆ vyrab¡ firma');
  Writeln(T,'SGS Thomson.');
  Writeln(T,'CCC - Chips Caried by Cards - Jsou to vlastnˆ 256-bitov‚ s‚riov‚');
  Writeln(T,'pamˆti EPROM vyroben‚ technologi¡ NMOS.');
  Writeln(T);
  Writeln(T);
  Writeln(T);
  Writeln(T,'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  Writeln(T,'³  1     5      TELECARD    ³');
  Writeln(T,'³  2     6                  ³');
  Writeln(T,'³  3     7                  ³');
  Writeln(T,'³  4     8                  ³');
  Writeln(T,'³                           ³');
  Writeln(T,'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'#10#10#10#13);
  Writeln(T,' V˜vod     V˜znam    Funkce');
  Writeln(T,'-----------------------------');
  Writeln(T,'   1        Vcc=5V    Nap jen¡');
  Writeln(T,'   2        "R/W      Vstup');
  Writeln(T,'   3        Clock     Vstup');
  Writeln(T,'   4        "Reset    Vstup');
  Writeln(T,'   5        Gnd=0V    Nap jen¡');
  Writeln(T,'   6        Vpp       Vstup');
  Writeln(T,'   7        Out       V˜stup');
  Writeln(T,'   8        Fuse'#10#13);
  Writeln(T,'( Uvozovky znamenaj¡ negaci )'#13#10#10#10#10);
  Writeln(T,'     V˜znam jednotliv˜ch bit–:');
  Writeln(T,'------------------------------------');
  Writeln(T,'    0..7   kontroln¡ sou‡et');
  Writeln(T,'    8..19  831h pro Telefonn¡ karty');
  Writeln(T,'    20..31 po‡et jednotek na nov‚ kartˆ v BCD k¢du');
  Writeln(T,'    32..40 K¢d v˜robce karty');
  Writeln(T,'    41..79 s‚riov‚ ‡¡slo');
  Writeln(T,'    80..87 11h');
  Writeln(T,'    88..95 k¢d zemˆ');
  Writeln(T,'    96..255 Bitov‚ pole'#10#13);
  Close(T);

  if DosError<>0 then Writeln('Nelze spustit COMMAND.COM');
  Writeln(#10#13'Byl vytvo©en soubor TCR.TXT');
  Writeln('Chcete ho zobrazit (A/ ) ?  ');
  If UpCase(ReadKey)='A' then
  begin
    SwapVectors;
    Exec(GetEnv('COMSPEC'),'/C TYPE TCR.TXT  |MORE');
    SwapVectors;
  end;
  ExitHalt(0)
end;


Procedure DetectLPT;
begin
  Port[$278]:=(0)or(Port[$278] and 8);
  If Port[$278+1] and $40<>0 then
  begin
    Port[$378]:=(0)or(Port[$378] and 8);
    If Port[$378+1] and $40<>0 then
    begin
      Port[$3BC]:=(0)or(Port[$3BC] and 8);
      If Port[$3BC+1] and $40<>0 then
      begin
        LPT:=$378;
      end
      else LPT:=$3BC;
    end
    else LPT:=$378;
  end
  else LPT:=$278;
end;



Procedure TestZarizeni;
begin
  Repeat
    Port[LPT]:=($80)or(Port[LPT] and 8);
    If Port[LPT+1]and $40=0 then
    begin
      GetScreen;
      Message(7,'Nebylo detekov no za©¡zen¡ pro ‡ten¡ telefonn¡ch karet !!!',15,4);
      Scan:=0;
      GetKey;
      SetScreen;
      TextColor(7);
      Message(7,'Opakovat,Konec,Ignorovat',10,1);
      Repeat until Port[$60]>128;
      Scan:=0;
      Repeat
        GetKey;
      until (UpCase(Chr(ASCII))='K')or(UpCase(Chr(ASCII))='O')or(UpCase(Chr(ASCII))='I');
      SetScreen;
      If UpCase(chr(ASCII))='I' then Break;
      If UpCase(Chr(ASCII))='K' then
      begin
        Port[LPT]:=0;
        Port[LPT+2]:=0;{37A}
        TextCursor(True);
        TextColor(7);TextBackground(0);
        ClrScr;
        {Mem[0:$417]:=Locks0;}
        ExitHalt(0);
      end;
    end;
  until Port[LPT+1]and $40<>0;

  Repeat
    Port[LPT]:=(0)or(Port[LPT] and 8);
    If Port[LPT+1] and $40<>0 then
    begin
      TextColor(12+128);
      GetScreen;
      Message(7,'Nebylo detekov no za©¡zen¡ pro ‡ten¡ telefonn¡ch karet !!!',15,4);
      Scan:=0;
      GetKey;
      SetScreen;
      TextColor(7);
      Message(7,'Opakovat,Konec,Ignorovat',10,1);
      Repeat until Port[$60]>128;
      Scan:=0;
      Repeat
        GetKey;
      until (UpCase(chr(ASCII))='K')or(UpCase(chr(ASCII))='O')or(UpCase(chr(ASCII))='I');
      SetScreen;
      If UpCase(chr(ASCII))='I' then Break;
      If UpCase(chr(ASCII))='K' then ExitHalt(0);
    end;
  until Port[LPT+1]and $40=0;
end;



Procedure ReadToBuffer;
begin
  For I:=0 to 31 do Buffer[I]:=PeekDec(I);
end;



Function Medium:Boolean;
begin
  If Peek(10)='11' then Medium:=True else Medium:=False;
end;



Procedure TestKeyb;
begin
  If not KeyPressed then
  begin
    For I:=0 to 200 do
    begin
      If Port[$60]<128 then
      begin
        Delay(50);Break;
      end;
      Delay(1);
    end;


  Port[$278]:=(0)or(Port[$278] and 8);
  If Port[$278+1] and $40<>0 then
  begin
    Port[$378]:=(0)or(Port[$378] and 8);
    If Port[$378+1] and $40<>0 then
    begin
      Port[$3BC]:=255;
      Port[$3BC]:=(0)or(Port[$3BC] and 8);
      If Port[$3BC+1] and $40<>0 then
      begin
        TextColor(0);TextBackground(7);
        GotoXY(70,21);Write('         X');
      end
      else LPT:=$3BC;
    end
    else LPT:=$378;
  end
  else LPT:=$278;



    If Medium then
    begin
      If not M then
      begin
        Sound(1500);Delay(20);NoSound;
        Delay(50);
        ReadToBuffer;
      end;
      TextColor(1);TextBackground(7);
      GotoXY(72,21);Write(HexByte(Hi(LPT))+HexByte(Lo(LPT))+' h');
      TextColor(10);TextBackground(7);
      GotoXY(72,23);Write('ON   ');Port[LPT]:=Port[LPT] and 8;

      M:=True;
    end
    else
    begin
      If M then
      begin
        Sound(700);Delay(10);NoSound;
        Delay(50);
      end;
      TextColor(1);TextBackground(7);
      GotoXY(72,21);Write(HexByte(Hi(LPT))+HexByte(Lo(LPT))+' h');
      TextColor(4);TextBackground(7);
      GotoXY(72,23);Write('OFF  ');{Port[LPT]:=0;}
      M:=False;
    end;
    ReadToBuffer;
  end
  else GetKey;

  If (Scan=74)or(Port[$60]=74) then Ucc:=False;
  If (Scan=78)or(Port[$60]=78) then Ucc:=True;


  TextBackground(7);
  GotoXY(72,22);
  If Port[LPT] and 8=8 then
  begin
    TextColor(10);Write('+5V ');
  end
  else
  begin
    TextColor(0);
    Write(' 0V ');
  end;
  If Ucc then Port[LPT]:=Port[LPT] or 8
  else Port[LPT]:=Port[LPT] and (255-8);
end;



Procedure SaveToFile;
Var
  PSoubor:String;
  N: NameStr;
  E: ExtStr;
  D: DirStr;

begin
  GetScreen2(0);
  {Mem[0:$417]:=32;}
  PSoubor:='';
  Scan:=0;Ascii:=0;
  TextColor(0);TextBackground(7);
  Frame(23,10,55,13,129+64);
  TextColor(0);
  GotoXY(25,12);Write('Ulo‘it do');
  TextCursor(True);
  Repeat
    TextColor(15);TextBackground(1);
    InputLine(24,12,30,'');
  until (Vstup<>'')or(Scan=1);
  TextCursor(False);
  Vstup:=FExpand(Vstup);
  FSplit(Vstup,D,N,E);
  If E<>'.TCR' then E:='.TCR';
  Vstup:=D+N+E;
  SetScreen2(0);
  If Scan=28 then
  begin
    GetScreen2(0);
    PSoubor:=Vstup;
    Assign(F,PSoubor);
    {$I-}Reset(F);{$I+}
    If IOResult<>0 then
    begin
      {$I-}Rewrite(F);{$I+}ErrorMessage;
    end
    else
    begin
      OKMessage('Soubor '+UpString(PSoubor)+' ji‘ exituje, P©epsat ?');
      If (Scan=28)or(UpCase(chr(ASCII))='A')or(UpCase(chr(ASCII))='Y')or
         (UpCase(chr(Ascii))='P') then
         Rewrite(F)
      else
      begin
        Scan:=0;SaveToFile;
      end;
    end;
    SetScreen2(0);
    If IORes=0 then
    For I:=0 to 31 do
    begin
      {$I-}Write(F,Buffer[I]);{$I+}ErrorMessage;
    end;
    GetScreen2(0);
    If IORes=0 then
    begin
      {$I-}Close(F);{$I+}ErrorMessage;
      If IORes=0 then Message(0,'Vytvo©en nov˜ soubor '+UpString(N+E),0,7);
      GetKey;
    end;
    SetScreen2(0);
  end;
  Scan:=0;Ascii:=0;
  {Mem[0:$417]:=16+32;}
end;



Procedure ViewInfo;
Type
  TCard=Record
         Typ:String;
         NewCard:LongInt;
         Vyrobce:Word;
         SerialNumber:String[16];
         CountryNumber:Word;
         Now:Word;
       end;
Var
  Card:TCard;

begin
  GetScreen2(0);
  TextColor(15);TextBackground(1);
  Frame(10,3,69,20,129+64);
  TextColor(14);
  Center(3,' CARD INFO ');
  TextColor(10);
  GotoXY(12,5);Write('K¢d typu karty:');
  GotoXY(12,6);Write('Po‡et jednotek na nov‚ kartˆ:');
  GotoXY(12,7);Write('K¢d v˜robce karty:');
  GotoXY(12,8);Write('Seriov‚ ‡¡slo karty:');
  GotoXY(12,9);Write('K¢d zemˆ:');
  GotoXY(12,10);Write('Po‡et zb˜vaj¡c¡ch jednotek:');
  Repeat
    A:=0;
    For I:=0 to 31 do
    begin
      For B:=7 downto 0 do
      begin
        BinBuf[A]:=(Buffer[I] shr B)and 1;
        Inc(A);
      end;
    end;

    Card.Typ:=HexByte(Buffer[1])+Copy(HexByte(Buffer[2]),1,1);

    Card.NewCard:=0;
    A:=0;B:=0;X:=0;
    For I:=0 to 3 do
    begin
      A:=A+BinBuf[I+20] shl (3-I);
      B:=B+BinBuf[I+24] shl (3-I);
      X:=X+BinBuf[I+28] shl (3-I);
    end;
    Card.NewCard:=A*100+B*10+X;

    Card.Vyrobce:=Buffer[4];

    A:=0;B:=0;X:=0;Y:=0;N:=0;
    Card.SerialNumber:='';
    For I:=0 to 6 do
    begin
      A:=A + (BinBuf[I+41] shl I)
    end;
    For I:=0 to 7 do
    begin
      B:=B + (BinBuf[I+48] shl I);
      X:=X + (BinBuf[I+56] shl I);
      Y:=Y + (BinBuf[I+64] shl I);
      N:=N + (BinBuf[I+72] shl I);
    end;
    Card.SerialNumber:=HexByte(A)+HexByte(B)+HexByte(X)+HexByte(Y)+HexByte(N);

    Card.CountryNumber:=Buffer[11];

    Card.Now:=0;
    If Card.NewCard>159 then Card.NewCard:=0;
    For I:=96 to 96+Card.NewCard do
    begin
      If I>255 then Break;
      If BinBuf[I]=0 then Inc(Card.Now);
    end;

    TextColor(7);TextBackground(1);
    GotoXY(45,5);Write(Card.Typ+' h                    ');
    GotoXY(45,6);Write(Card.NewCard,'                     ');
    GotoXY(45,7);Write(HexByte(Card.Vyrobce)+' h ');
    If Card.Vyrobce=0 then Write('(Schlumberger)      ');
    If Card.Vyrobce=$40 then Write('(Gemplus)           ');
    GotoXY(45,8);Write(Card.SerialNumber,'               ');
    GotoXY(45,9);Write(HexByte(Card.CountryNumber)+' h  ');
    If Card.CountryNumber=$55 then Write('(€esk  republika)  ')
    else Write('                   ');
    GotoXY(45,10);Write(Card.Now,'                       ');
    TestKeyb;
    ReadToBuffer;
  until Scan=1;
  SetScreen2(0);
  Scan:=0;
end;



Procedure ViewCard;
begin
  GetScreen;
  TextColor(15);TextBackground(1);
  Frame(1,10,40,22,1+128);
  Frame(1,2,78,8,1+128);
  Frame(43,10,78,16,1+128);
  TextColor(14);
  Center(2,' HEX ');
  GotoXY(19,11);Write(' BIN ');
  GotoXY(59,11);Write(' ASCII ');
  Repeat
    TextBackground(1);TextColor(11);

    X:=0;Y:=0;I:=0;
    Repeat
      For X:=0 to 15 do
      begin
        GotoXY(X*4+10,Y+5);Write(HexByte(Buffer[I]));
        Inc(I);
      end;
      Inc(Y);
    until I>=31;

    I:=0;
    For X:=0 to 31 do
    begin
      GotoXY(X+45,12);Write(Chr(Buffer[I]));
      Inc(I);
    end;

    I:=0;N:=0;
    For X:=0 to 7 do
    For I:=0 to 3 do
    begin
      For B:=7 downto 0 do
      begin
        GotoXY(4+(7-B)+I*9,12+X);
        If (Buffer[N] and (1 shl B))=(1 shl B) then Write('1') else Write('0');
      end;
      Inc(N);
    end;

    TestKeyb;
    If Scan=60 then SaveToFile;
    If Scan=63 then ViewInfo;
  until (Scan=1)or((Scan=45)and(Ascii=0));
  If (Scan<>45)or(Ascii<>0) then Scan:=0;
  SetScreen;
end;


Procedure ViewFileInfo(Buf:Array of Byte);
Type
  TCard=Record
         Typ:String;
         NewCard:LongInt;
         Vyrobce:Word;
         SerialNumber:String[16];
         CountryNumber:Word;
         Now:Word;
       end;
Var
  Card:TCard;
  BinBuf:Array[0..255] of Byte;
  P: PathStr;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  C: Byte;

begin
  GetScreen;
  TextColor(15);TextBackground(1);
  Frame(10,3,69,20,129+64);
  TextColor(14);
  FSplit(PSoubor,D,N,E);
  Center(3,' FILE INFO Ä '+N+E+' ');
  TextColor(10);
  GotoXY(12,5);Write('K¢d typu karty:');
  GotoXY(12,6);Write('Po‡et jednotek na nov‚ kartˆ:');
  GotoXY(12,7);Write('K¢d v˜robce karty:');
  GotoXY(12,8);Write('Seriov‚ ‡¡slo karty:');
  GotoXY(12,9);Write('K¢d zemˆ:');
  GotoXY(12,10);Write('Po‡et zb˜vaj¡c¡ch jednotek:');
  Repeat
    A:=0;
    For I:=0 to 31 do
    begin
      For B:=7 downto 0 do
      begin
        BinBuf[A]:=(Buf[I] shr B)and 1;
        Inc(A);
      end;
    end;

    Card.Typ:=HexByte(Buf[1])+Copy(HexByte(Buf[2]),1,1);

    Card.NewCard:=0;
    A:=0;B:=0;X:=0;
    For I:=0 to 3 do
    begin
      A:=A+BinBuf[I+20] shl (3-I);
      B:=B+BinBuf[I+24] shl (3-I);
      X:=X+BinBuf[I+28] shl (3-I);
    end;
    Card.NewCard:=A*100+B*10+X;

    Card.Vyrobce:=Buf[4];

    A:=0;B:=0;X:=0;Y:=0;C:=0;
    Card.SerialNumber:='';
    For I:=0 to 6 do
    begin
      A:=A + (BinBuf[I+41] shl I)
    end;
    For I:=0 to 7 do
    begin
      B:=B + (BinBuf[I+48] shl I);
      X:=X + (BinBuf[I+56] shl I);
      Y:=Y + (BinBuf[I+64] shl I);
      C:=C + (BinBuf[I+72] shl I);
    end;
    Card.SerialNumber:=HexByte(A)+HexByte(B)+HexByte(X)+HexByte(Y)+HexByte(C);

    Card.CountryNumber:=Buf[11];

    Card.Now:=0;
    If Card.NewCard>159 then Card.NewCard:=0;
    For I:=96 to 96+Card.NewCard do
    begin
      If I>255 then Break;
      If BinBuf[I]=0 then Inc(Card.Now);
    end;

    TextColor(7);TextBackground(1);
    GotoXY(45,5);Write(Card.Typ+' h                    ');
    GotoXY(45,6);Write(Card.NewCard,'                     ');
    GotoXY(45,7);Write(HexByte(Card.Vyrobce)+' h ');
    If Card.Vyrobce=0 then Write('(Schlumberger)      ');
    If Card.Vyrobce=$40 then Write('(Gemplus)           ');
    GotoXY(45,8);Write(Card.SerialNumber,'               ');
    GotoXY(45,9);Write(HexByte(Card.CountryNumber)+' h  ');
    If Card.CountryNumber=$55 then Write('(€esk  republika)  ')
    else Write('                   ');
    GotoXY(45,10);Write(Card.Now,'                       ');
    TestKeyb;
  until Scan=1;
  SetScreen;
  Scan:=0;
end;


Procedure ViewCardInFile(Buf:Array of Byte);
begin
  GetScreen2(0);
  TextColor(15);TextBackground(1);
  Frame(1,10,40,22,1+128);
  Frame(1,2,78,8,1+128);
  Frame(43,10,78,16,1+128);
  TextColor(15);
  Center(2,' HEX ');
  GotoXY(19,11);Write(' BIN ');
  GotoXY(59,11);Write(' ASCII ');
  Repeat
    TextBackground(1);TextColor(11);
    X:=0;Y:=0;I:=0;
    Repeat
      For X:=0 to 15 do
      begin
        GotoXY(X*4+10,Y+5);Write(HexByte(Buf[I]));
        Inc(I);
      end;
      Inc(Y);
    until I>=31;
    I:=0;
    For X:=0 to 31 do
    begin
      GotoXY(X+45,12);Write(Chr(Buf[I]));
      Inc(I);
    end;

    I:=0;N:=0;
    For X:=0 to 7 do
    For I:=0 to 3 do
    begin
      For B:=7 downto 0 do
      begin
        GotoXY(4+(7-B)+I*9,12+X);
        If (Buf[N] and (1 shl B))=(1 shl B) then Write('1') else Write('0');
      end;
      Inc(N);
    end;

    If not KeyPressed then
    begin
      For I:=0 to 200 do
      begin
        If Port[$60]<128 then
        begin
          Delay(50);Break;
        end;
        Delay(1);
      end;

      If Medium then
      begin
        If not M then
        begin
          Sound(1500);Delay(20);NoSound;
          Delay(50);
        end;
        TextColor(10);TextBackground(7);
        GotoXY(72,23);Write('ON   ');

        M:=True;
      end
      else
      begin
        If M then
        begin
          Sound(700);Delay(10);NoSound;
          Delay(50);
        end;
        TextColor(12);TextBackground(7);
        GotoXY(72,23);Write('OFF  ');{Port[LPT]:=0;}
        M:=False;
      end;
    end
    else GetKey;
    If Scan=63 then ViewFileInfo(Buf);
  until (Scan=1)or((Scan=45)and(Ascii=0));
  If (Scan<>45)or(Ascii<>0) then Scan:=0;
  SetScreen2(0);
end;



Procedure ViewFile;
Var
  N: NameStr;
  E: ExtStr;
  D: DirStr;
  Data:Byte;
begin
  PSoubor:=ChooseFile('*.TCR');

  If Scan=28 then
  begin
    GetScreen;
    Assign(F,PSoubor);
    {$I-}Reset(F);{$I+}ErrorMessage;
    {$I-}FSize:=FileSize(F);{$I+}ErrorMessage;
    If IORes=0 then
    If FSize=32 then
    begin
      For I:=0 to 31 do Buffer[I]:=255;
      I:=0;
      While not EOF(F) do
      begin
        {$I-}Read(F,Buffer[I]);{$I+}ErrorMessage;
        Inc(I);
      end;
      {$I-}Close(F);{$I+}ErrorMessage;
      ViewCardInFile(Buffer);
    end
    else
    If FSize=256 then
    begin
      For I:=0 to 31 do FBuffer[I]:=0;
      I:=0;
      While not EOF(F) do
      begin
        FBuffer[I]:=0;
        For B:=7 downto 0 do
        begin
          {$I-}Read(F,Data);{$I+}ErrorMessage;
          If Data>1 then Data:=1;
          FBuffer[I]:=FBuffer[I]+Data shl B;
        end;
        x:=0;
        Inc(I);
      end;
      {$I-}Close(F);{$I+}ErrorMessage;
      ViewCardInFile(FBuffer);
    end
    else
    begin
      GetScreen2(0);
      TextColor(14+16);TextBackground(7);
      GotoXY(72,23);Write('STOP ');
      Message(10,'Soubor je po¨kozen nebo nem  spr vn˜ form t. Pokra‡ovat ?',10,4);
      GetKey;
      If (UpCase(chr(Ascii))='A')or(UpCase(chr(Ascii))='Y')or
         (UpCase(chr(Ascii))='P')or(Scan=28)then
      begin
        For I:=0 to 31 do Buffer[I]:=255;
        I:=0;
        While not EOF(F) do
        begin
          {$I-}Read(F,Buffer[I]);{$I+}ErrorMessage;
          Inc(I);
          If I>31 then Break;
        end;
        {$I-}Close(F);{$I+}ErrorMessage;
        ViewCardInFile(Buffer);
      end;
      SetScreen2(0);
    end;
  end;
end;


Procedure TestSN(SN:String);
begin
  SN:=Copy(SN,4,Length(SN));
  SN:=UpString(SN);
  GetScreen;
  TextColor(14+16);TextBackground(7);
  GotoXY(70,23);Write('TEST ');Port[LPT]:=0;
  Message(8,'Vlo‘te identifika‡n¡ kartu ...',0,7);
  Repeat
    begin
      For I:=0 to 200 do
      begin
        If Port[$60]<128 then
        begin
          Delay(50);Break;
        end;
        Delay(1);
      end;

      If Medium then
      begin
        If not M then
        begin
          ReadToBuffer;
          A:=0;
          For I:=0 to 31 do
          begin
            For B:=7 downto 0 do
            begin
              BinBuf[A]:=(Buffer[I] shr B)and 1;
              Inc(A);
            end;
          end;
          A:=0;B:=0;X:=0;Y:=0;N:=0;
          For I:=0 to 6 do
          begin
            A:=A + (BinBuf[I+41] shl I)
          end;
          For I:=0 to 7 do
          begin
            B:=B + (BinBuf[I+48] shl I);
            X:=X + (BinBuf[I+56] shl I);
            Y:=Y + (BinBuf[I+64] shl I);
            N:=N + (BinBuf[I+72] shl I);
          end;
          S:=HexByte(A)+HexByte(B)+HexByte(X)+HexByte(Y)+HexByte(N);
          If SN<>S then
          begin
            Message(4,'›patn  identifika‡n¡ karta !!!',0,4+16);
            Repeat
              For I:=0 to 50 do
              begin
                Sound(3000);Delay(10);NoSound;
                Sound(2000);Delay(10);NoSound;
                Sound(1000);Delay(10);NoSound;
              end;
              Delay(500);
              NoSound;
              M:=False;
            until not Medium;
            Message(8,'Vlo‘te identifika‡n¡ kartu ...',0,7);
          end
          else
          begin
            Message(15,'Identifika‡n¡ karta je OK. P©eji Dobr˜ den.',0,10+16);
            For I:=1 to 2 do
            begin
              Sound(2000);Delay(10);NoSound;Delay(100);
              Sound(1000);Delay(10);NoSound;Delay(100);
              Sound(500);Delay(10);NoSound;Delay(100);
            end;
            Delay(100);
          end;

        end;
        M:=False;
      end;
    end;
    ReadToBuffer;
  until (SN=S)or(Scan=1);
  SetScreen;
  Port[LPT]:=0;
  ExitHalt(255);
end;


Procedure ChoosePort;
begin
  GetScreen;
  Frame(32,11,50,15,1+128+64);
  Center(11,' V˜bˆr portu ');
  I:=2;
  If LPT=$278 then I:=1;
  If LPT=$378 then I:=2;
  If LPT=$3BC then I:=3;
  Repeat
    If Scan=80 then Inc(I);
    If Scan=72 then Dec(I);

    If I>3 then I:=3;
    If I<1 then I:=1;

    If I=1 then TextBackground(10) else TextBackground(7);
    Center(12,'      $278       ');

    If I=2 then TextBackground(10) else TextBackground(7);
    Center(13,'      $378       ');

    If I=3 then TextBackground(10) else TextBackground(7);
    Center(14,'      $3BC       ');

    GetKey;
  until (Scan=1)or(Scan=28);
  If Scan=28 then
  begin
    If I=1 then LPT:=$278;
    If I=2 then LPT:=$378;
    If I=3 then LPT:=$3BC;
  end;
  SetScreen;
  TestZarizeni;
end;


Begin
  GetDir(0,PuvAdr);
  DetectLPT;
  SetCBreak(False);
  {Locks0:=Mem[0:$417];}
  {Mem[0:$417]:=Mem[0:$417] or (16+32);}
  { LoadCZPage(10); }
  For I:=1 to ParamCount do If ParamStr(I)='/?' then Help;
  TextCursor(False);
  InitStandardScreen('±',1,8,2);
  TextColor(0);Frame(60,20,78,22,8+128);
  GotoXY(62,21);Write('Port:');
  GotoXY(62,22);Write('Ucc:');
  GotoXY(62,23);Write('Status:');
  TextColor(0);Center(0,'Telephone Card Reader');
  { SetASCIITab(10); }
  Port[LPT+2]:=0;
  Port[LPT]:=0;
  Ucc:=True;
  TestZarizeni;
  ReadToBuffer;
  For B:=1 to ParamCount do If Copy(UpString(ParamStr(B)),1,3)='SN=' then
    TestSN(ParamStr(B));
  InitDownMenu('~Alt+X~ Exit ~Alt+P~ Port ~F2~ Save ~F3~ Load '+
               '~F4~ ViewCard ~F5~ Info ~F10~ About ~+/-~ ON/OFF',25);
  TextColor(14);TextBackground(7);
  GotoXY(72,23);Write('TEST ');Port[LPT]:=Port[LPT] and 8;
  M:=False;
  If (LPT<>$378)and(LPT<>$278)and(LPT<>$3BC) then LPT:=$378;
  About(OEM,Ver);
  TextBackground(7);
  Repeat
    Scan:=0;Ascii:=0;

    TestKeyb;

    If Scan=60 then SaveToFile;
    If Scan=61 then ViewFile;
    If Scan=63 then ViewInfo;
    If (Scan=25) and (Ascii=0) then ChoosePort;
    If Scan=68 then
    begin
      TextColor(14+16);TextBackground(7);
      GotoXY(72,23);Write('STOP ');Port[LPT]:=Port[LPT] and 8;
      About(OEM,Ver);
    end;
    If Scan=62 then ViewCard;

    TextBackground(7);TextColor(0);

  until (Scan=45)and(Ascii=0);
  ExitHalt(0);
end.