Program CardReader;
Uses Crt,Dos;
Const
  Clock=2;
  Reset=1;
  RW=4;
Var
  i,x,D:Byte;
  Data:Word;
  CRC:LongInt;
  Ch:Char;
  F:File of Byte;


Procedure Hide;Assembler;{Skryt textovy kurzor}
Asm
  MOV AH,1
  MOV CH,20h
  MOV CL,20h
  INT 10h
end;

Procedure Show;Assembler;{Zobrazit textovy kurzor}
Asm
  MOV AH,1
  MOV CH,15
  MOV CL,16
  INT 10h
end;

Function Hex(B:Word):Char;
begin
  If B< $A then Hex:=Char(B+Byte('0')) else Hex:=Char(B+(Byte('A') - $A));
end;

Function HexByte(B:Word):String;
begin
  HexByte:=Hex(B shr 4) + Hex(B and $F)
end;

Function Peek(Adr:Byte):String;
Var
  Bit,Byt:Byte;
begin
  Port[$378]:=1 xor Reset;
  Port[$378]:=1 xor Reset xor Clock;
  Port[$378]:=1 xor Reset;
  Port[$378]:=1;
  For Byt:=0 to Adr do
  begin
    Data:=0;
    For Bit:=0 to 7 do
    begin
      Data:=Data shl 1;
      If Port[$379] and $80=0 then Inc(Data);
      Port[$378]:=1 xor Clock;
      Port[$378]:=1;
    end;
  end;
  Peek:=HexByte(Data);
end;

Function PeekDec(Adr:Byte):Byte;
Var
  Bit,Byt:Byte;
begin
  Port[$378]:=1 xor Reset;
  Port[$378]:=1 xor Reset xor Clock;
  Port[$378]:=1 xor Reset;
  Port[$378]:=1;
  For Byt:=0 to Adr do
  begin
    Data:=0;
    For Bit:=0 to 7 do
    begin
      Data:=Data shl 1;
      If Port[$379] and $80=0 then Inc(Data);
      Port[$378]:=1 xor Clock;
      Port[$378]:=1;
    end;
  end;
  PeekDec:=Data;
end;

Function PeekBin(Adr:Byte):Byte;
Var
  Bit:Byte;
begin
  Port[$378]:=1 xor Reset;
  Port[$378]:=1 xor Reset xor Clock;
  Port[$378]:=1 xor Reset;
  Port[$378]:=1;
  For Bit:=0 to Adr do
  begin
    If Port[$379] and $80=0 then PeekBin:=1 else PeekBin:=0;
    Port[$378]:=1 xor Clock;
    Port[$378]:=1;
  end;
end;

Procedure Help;
Var
  T:Text;
begin
  Assign(T,'HELP.TXT');
  Rewrite(T);
  Writeln(T,'Card Reader');
  Writeln(T,'Tento program je urcen pro cteni telefonnich karet pres LPT 1 .');
  Writeln(T,'Schema zapojeni je v souboru CARDREAD.GIF .Napajeni karty je take');
  Writeln(T,'mozne z konektoru klavesnice ( pin 5 je +5V ,pin 4 GND ),');
  Writeln(T,'je ale nutna vetsi opatrnost,radeji pouzijte externi zdroj.');
  Writeln(T);
  Writeln(T,'Telefonni karty pouzivane v Ceske republice udajne vyrabi firma');
  Writeln(T,'SGS Thomson. CCC - Chips Caried by Cards - Jsou to vlastne');
  Writeln(T,'256-bitove seriove pameti eprom vyrobene technologii NMOS.');
  Writeln(T);
  Writeln(T);
  Writeln(T);
  Writeln(T);
  Writeln(T,'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
  Writeln(T,'³  1     5      TELECARD    ³');
  Writeln(T,'³  2     6                  ³');
  Writeln(T,'³  3     7                  ³');
  Writeln(T,'³  4     8                  ³');
  Writeln(T,'³                           ³');
  Writeln(T,'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
  Writeln(T);
  Writeln(T);
  Writeln(T,' Vyvod     Vyznam    Funkce');
  Writeln(T,'-----------------------------');
  Writeln(T,'   1        Vcc=5V    Napajeni');
  Writeln(T,'   2        "R/W      Vstup');
  Writeln(T,'   3        Clock     Vstup');
  Writeln(T,'   4        "Reset    Vstup');
  Writeln(T,'   5        Gnd=0V    Napajeni');
  Writeln(T,'   6        Vpp       Vstup');
  Writeln(T,'   7        Out       Vystup');
  Writeln(T,'   8        Fuse                                                     ');
  Writeln(T);
  Writeln(T,'( Uvozovky znamenaji negaci )');
  Writeln(T);
  Writeln(T);
  Writeln(T);
  Writeln(T);
  Writeln(T,'     Vyznam jednotlivych bitu:');
  Writeln(T,'------------------------------------');
  Writeln(T,'    0..7   kontrolni soucet');
  Writeln(T,'    8..19  831h pro Telefonni karty');
  Writeln(T,'    20..31 pocet jednotek na nove karte v BCD kodu');
  Writeln(T,'    32..40 Kod vyrobce karty');
  Writeln(T,'    41..79 seriove cislo');
  Writeln(T,'    80..87 11h');
  Writeln(T,'    88..95 kod zeme');
  Writeln(T,'    96..255 Bitove pole');
  Writeln(T);
  Close(T);

  if DosError<>0 then Writeln('Nelze spustit COMMAND.COM');
  Writeln(#10#13'Byl vytvoren soubor HELP.TXT');
  Writeln('Chcete ho zobrazit (A/ ) ?  ');
  If UpCase(ReadKey)='A' then
  begin
    {$M 8192,0,0}
    SwapVectors;
    Exec(GetEnv('COMSPEC'),'/C TYPE HELP.TXT  |MORE');
    SwapVectors;
  end;
  Halt(0);
end;

Procedure HexZpusob;
begin
  Repeat
    TextBackground(1);
    ClrScr;
    TextBackground(7);TextColor(4);
    Window(1,25,80,25);ClrScr;Window(1,1,80,25);
    GotoXY(2,25);Write('ENTER');
    GotoXY(22,25);Write('ESC');
    TextColor(0);
    GotoXY(8,25);Write('Nacist znovu');
    GotoXY(26,25);Write('Zpet');
    TextBackground(1);
    TextColor(14);GotoXY(32,1);Writeln('Card reader');
    TextBackground(7);TextColor(0);
    Window(1,2,80,2);ClrScr;Window(1,1,80,25);
    GotoXY(1,2);Write('Adresa');
    GotoXY(36,2);Write('HEX');
    GotoXY(69,2);Write('ASCII');
    TextBackground(1);TextColor(14);
    GotoXY(1,3);Write(#10#13'0000  ');
    TextColor(7);
    D:=0;
    For i:=1 to 4 do
    begin
      For x:=1 to 4 do
      begin
        Write(Peek(D),' ');
        D:=D+1;
      end;
      Write('  ');
    end;
    D:=0;
    For i:=1 to 4 do
    begin
      For x:=1 to 4 do
      begin
        If (PeekDec(D)<>13)and(PeekDec(D)<>10)and(PeekDec(D)<>9)
        and(PeekDec(D)<>8) then Write(Chr(PeekDec(D)));
        D:=D+1;
      end;
      Write('  ');
    end;

    TextColor(14);
    GotoXY(1,4);Write(#10#13'0010  ');
    TextColor(7);
    Data:=D;
    For i:=1 to 4 do
    begin
      For x:=1 to 4 do
      begin
        Write(Peek(D),' ');
        D:=D+1;
      end;
      Write('  ');
    end;
    D:=16;
    For i:=1 to 4 do
    begin
      For x:=1 to 4 do
      begin
        If (PeekDec(D)<>13)and(PeekDec(D)<>10)and(PeekDec(D)<>9)
        and(PeekDec(D)<>8) then Write(Chr(PeekDec(D)));
        D:=D+1;
      end;
      Write('  ');
    end;
    Repeat
      Data:=Ord(ReadKey);
      If Port[$60]=64 then Data:=27;
    until (Data=27)or(Data=13);
  until Data=27;
  Data:=13;
end;

Procedure TestZarizeni;
begin
  Repeat
    Port[$378]:=$80;
    If Port[$379]and $40=0 then
    begin
      TextColor(12+128);
      Writeln(#10#13'Selhani zarizeni na portu 378h !!!');
      TextColor(7);
      Write(#10#13'Opakovat,Konec : ');
      Repeat
        Ch:=ReadKey;
      until (UpCase(Ch)='K')or(UpCase(Ch)='O');
      Write(Ch,#10#13);
      If UpCase(Ch)='K' then Halt(0);
    end;
  until Port[$379]and $40<>0;

  Repeat
    Port[$378]:=$00;If Port[$379] and $40<>0 then
    begin
      TextColor(12+128);
      Writeln(#10#13'Zarizeni na portu 378h nepracuje !!!');
      TextColor(7);
      Write(#10#13'Opakovat,Konec,Pokracovat : ');
      Repeat
        Ch:=ReadKey;
      until (UpCase(Ch)='K')or(UpCase(Ch)='O')or(UpCase(Ch)='P');
      Write(Ch,#10#13);
      If UpCase(Ch)='P' then Exit;
      If UpCase(Ch)='K' then Halt(0);
    end;
  until Port[$379]and $40=0;
end;




Begin
  If ParamStr(1)='/?' then Help;
  TestZarizeni;
  Repeat
    Hide;
    Asm
      MOV AX,1001h
      MOV BH,1
      Int 10h
    end;
    TextBackground(1);
    ClrScr;
    TextBackground(7);
    Window(1,25,80,25);
    ClrScr;
    Window(1,1,80,25);
    TextColor(4);
    GotoXY(2,25);Write('ENTER');
    GotoXY(22,25);Write('F9');
    GotoXY(50,25);Write('F6');
    GotoXY(58,25);Write('ESC');
    TextColor(0);
    GotoXY(8,25);Write('Nacist znovu');
    GotoXY(25,25);Write('Ulozit obsah do souboru');
    GotoXY(53,25);Write('Hex');
    GotoXY(62,25);Write('Konec');
    TextBackground(1);
    TextColor(14);GotoXY(32,1);Writeln('Card reader');
    TextBackground(7);TextColor(0);
    Window(1,2,80,2);ClrScr;Window(1,1,80,25);
    GotoXY(36,2);Write('BIN');
    GotoXY(1,3);
    TextBackground(1);TextColor(7);
    CRC:=0;
    For x:=0 to 31 do
    begin
      For i:=0 to 7 do
      begin
        Write(PeekBin(CRC));
        CRC:=CRC+1;
      end;
      Write('  ');
    end;
    TextBackground(7);TextColor(0);
    Window(1,8,80,8);ClrScr;Window(1,1,80,25);
    GotoXY(36,8);Write('HEX');
    GotoXY(1,9);
    TextBackground(1);TextColor(7);
    For i:=0 to 31 do Write(Peek(i),'        ');

    TextBackground(7);TextColor(0);
    Window(1,14,80,14);ClrScr;Window(1,1,80,25);
    GotoXY(36,14);Write('INFO');
    TextColor(7);TextBackground(1);
    GotoXY(1,15);Write('Typ karty:');
    GotoXY(1,16);Write('Pocet jednotek na nove karte:');
    GotoXY(1,17);Write('Pocet jednotek na karte nyni:');
    GotoXY(1,18);Write('Kod vyrobce karty:');
    GotoXY(1,19);Write('Kod zeme:');
    GotoXY(1,20);Write('Vyrobni cislo:');

    TextColor(10);
    Data:=0;
    GotoXY(32,15);
    For i:=8 to 19 do
    begin
      Data:=Data shl 1;
      If PeekBin(i)=1 then Inc(Data);
    end;
    If Data=$831 then Write(Data,' - Telefonni karta');
    Data:=0;
    GotoXY(32,16);
    For I:=20 to 31 do
    begin
      Data:=Data shl 1;
      If PeekBin(I)=1 then Inc(Data);
    end;
    Write(Data);

    GotoXY(32,17);
      CRC:=0;
      For I:=96 to 255 do CRC:=CRC+PeekBin(I);
      Write(CRC);

    GotoXY(32,18);Write(Peek(3)+Peek(4));
                  If Peek(3)+Peek(4)='0000'then Write(' - Schlumberger');
                  If Peek(3)+Peek(4)='0040'then Write(' - Gemplus');
    GotoXY(32,19);Write(Peek(11),'h');
                  If Peek(11)='55'then Write(' - Ceska republika');
    GotoXY(32,20);
    Data:=0;
    For i:=41 to 79 do
    begin
      Data:=Data shl 1;
      If PeekBin(i)=1 then Inc(Data);
    end;
    For I:=41 to 79 do Write(PeekBin(I));
    Repeat
      D:=0;
      If Port[$60]=67 then
      begin
        Assign(F,'CARD.DAT');
        Rewrite(F);
        Port[$378]:=1 xor Reset;
        Port[$378]:=1 xor Reset xor Clock;
        Port[$378]:=1 xor Reset;
        Port[$378]:=1;
        For I:=0 to 255 do
        begin
          If Port[$379] and $80=0 then D:=1 else D:=0;
          Port[$378]:=1 xor Clock;
          Port[$378]:=1;
          Write(F,D);
        end;
        Close(F);
      end;
      If not Keypressed then
      begin
        Port[$378]:=8;
        Delay(100);
        Port[$378]:=0;
        Delay(100);
      end
      else Data:=Ord(ReadKey);
      If Port[$60]=64 then HexZpusob;
    until (Data=27)or(Data=13);
    Show;
  until Data=27;
  TextColor(7);
  TextBackground(0);
  ClrScr;
  Writeln(#10#10#13'Copyright (C) 1998  Tomas Hujer');
  Asm
    MOV AX,1001h
    MOV BH,0
    Int 10h
  end;
end.