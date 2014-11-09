Program TeleCardReader;

uses    crt;

type    string8 = string[8];
        string2 = string[2];

const   PrinterPort = $378;
const   OutPort = PrinterPort + 0;
         InPort = PrinterPort + 1;
const   sgReset = $04;
        sgClock = $01;
        sgRW    = $02;
const   sgDefault = sgReset;
const   Napajeni = 128;
        s8 = $08;

var     konec:char;
        kontrola:boolean;

procedure Send (B: byte);
        begin Port[OutPort] := B end;

function Get:Byte;
        begin Get := Port[Inport] end;

procedure Waiting;  {cekani na stisk klavesy}
        begin
          Writeln;
          Write('Pres Enter to continue, E to exit: ');
          Writeln;
          if kontrola=false then Gotoxy(30,2);
            if kontrola=true then Gotoxy(30,3);
        end;

var Data : array [0..31] of Byte;
    DataI : array [1..32] of Byte;

procedure Reading; {cteni obsahu pameti karty}
        var i, j, k, Value: Byte;

        begin
          Send(sgDefault xor sgReset + Napajeni + s8);
          Send(sgDefault xor sgReset xor sgClock + Napajeni + s8);
          Send(sgDefault xor sgReset + Napajeni + s8);
          Send(sgDefault + Napajeni + s8);
        for i := Low(Data) to High(Data) do
          begin
            Value := 0;
            for j := 0 to 7 do
              begin
                Value := Value shl 1;
                  if Get and $80 = 0 then inc(Value);
                    Send(sgDefault xor sgClock + Napajeni + s8);
                    Send(sgDefault + Napajeni + s8);
              end;
          Data[i] := Value;
          end;
        Send(0)
        end;

Procedure ReadingI; {opetovne cteni obsahu pameti karty}
        var i, j, k, ValueI: Byte;

        begin
          Send(sgDefault xor sgReset + Napajeni + s8);
          Send(sgDefault xor sgReset xor sgClock + Napajeni + s8);
          Send(sgDefault xor sgReset + Napajeni + s8);
          Send(sgDefault + Napajeni + s8);
        for i := Low(DataI) to High(DataI) do
          begin
            ValueI := 0;
            for j := 0 to 7 do
              begin
                ValueI := ValueI shl 1;
                  if Get and $80 = 0 then inc(ValueI);
                    Send(sgDefault xor sgClock + Napajeni + s8);
                    Send(sgDefault + Napajeni + s8);
              end;
          DataI[i] := ValueI;
          end;
        Send(0)
        end;

Function Hex(b: byte) : Char;
        begin
          if b < $A then Hex := Char(b + Byte('0'))
             else Hex := Char( b + (Byte('A') - $a));
        end;

Function HexByte(b: Byte): String;
        begin HexByte := Hex(b shr 4) + Hex(b and $F) end;

procedure Dumping; {vypsani obsahu pameti karty}
        var i: Byte;
        begin
          Writeln;
          for i := Low(Data) to High(Data) do
            begin
              Write(HexByte(Data[i]));
              if (i and $F) = $F then writeln
              else write(' ');
            end;
        end;

Function dec2hexa(value:byte): char;
        begin case value of
                0..9    : dec2hexa:=chr(value+$30);
                10..15  : dec2hexa:=chr(value+$37);
              end;
        end;

function d2h(value:byte):string2;
        begin d2h:=dec2hexa(value div $10) + dec2hexa(value and $0F);
        end;

function binary(b:byte):string8;
        var weight:byte;
            s     :string8;

        begin weight:=$80;
          s:='';
          while (weight > 0) do
          begin if ((b and weight) = weight) then s:=s+'1'
                else s:=s+'0';
                weight:=weight div $02;
          end;
        binary:=s;
        end;

procedure Full_Displaying;
        var i, j, byte_number:Integer;
        begin
          byte_number:=32;
          writeln('Memory dump:');
          for i:=1 to 80 do write('-');
          for i:=1 to (byte_number div 6 +1) do
          begin for j:=1 to 6 do
                if j+6*(i-1) <= byte_number then write(binary(DataI[j+6*(i-1)]))
                else write('         ');
                write('    ');
                for j:=1 to 6 do
                if j+6*(i-1) <= byte_number then write(d2h(DataI[j+6*(i-1)]),' ');
                writeln;
          end;
          for i:=1 to 80 do write('-');
          writeln;
        end;

{ Kontrola se zajisti spojenim pinu ACK_ a D7

function kontrol:boolean;
        begin
        clrscr;
        Send(Napajeni + s8);
        send($80);
        if Get and $40 = 0 then
          begin
            writeln('Hardware not connected!');
            kontrola:=true;
          exit end;
        Send($00);
        if Get and $40 <> 0 then
          begin
            writeln('Hardware not connected!');
            kontrola:=true;
          end;
        end;}

begin
  Repeat
{    Kontrol;}
    Waiting;
    konec:=upcase(readkey);
    Reading;
    ReadingI;
    if kontrola=false then Gotoxy(1,3);
    if kontrola=true then Gotoxy(1,4);
    Full_Displaying;
    Dumping;
    if konec=chr(13) then readkey;
    if konec='E' then clrscr;
  until konec='E'
end.