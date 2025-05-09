(*
https://zpascal.net
https://github.com/PassByYou888/ZNet
https://github.com/PassByYou888/zRasterization
https://github.com/PassByYou888/ZSnappy
https://github.com/PassByYou888/Z-AI1.4
https://github.com/PassByYou888/ZAI_1.41
https://github.com/PassByYou888/InfiniteIoT
https://github.com/PassByYou888/zMonitor_3rd_Core
https://github.com/PassByYou888/tcmalloc4p
https://github.com/PassByYou888/jemalloc4p
https://github.com/PassByYou888/zCloud
https://github.com/PassByYou888/ZServer4D
https://github.com/PassByYou888/zShell
https://github.com/PassByYou888/ZDB2.0
https://github.com/PassByYou888/zGameWare
https://github.com/PassByYou888/CoreCipher
https://github.com/PassByYou888/zChinese
https://github.com/PassByYou888/zSound
https://github.com/PassByYou888/zExpression
https://github.com/PassByYou888/ZInstaller2.0
https://github.com/PassByYou888/zAI
https://github.com/PassByYou888/NetFileService
https://github.com/PassByYou888/zAnalysis
https://github.com/PassByYou888/PascalString
https://github.com/PassByYou888/zInstaller
https://github.com/PassByYou888/zTranslate
https://github.com/PassByYou888/zVision
https://github.com/PassByYou888/FFMPEG-Header
*)
{ ****************************************************************************** }
{ * GBK Big data                                                               * }
{ ****************************************************************************** }
unit Z.GBKBig;

{$DEFINE FPC_DELPHI_MODE}
{$I Z.Define.inc}

interface

uses Z.Status, Z.Core, Z.PascalStrings, Z.UPascalStrings, Z.MemoryStream, Z.ListEngine, Z.UnicodeMixedLib;

procedure BigKeyAnalysis(const Analysis: THashVariantList);
function BigKey(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
function BigKeyValue(const s: TUPascalString; const MatchSingleWord: Boolean; const Analysis: THashVariantList): Integer;
function BigKeyWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer; overload;
function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString; overload;

implementation

uses Z.GBKMediaCenter, Z.GBK, Z.GBKVec;

type
  TBigKeyAnalysis = class(TCore_Object_Intermediate)
    output: THashVariantList;
    procedure doProgress(Sender: THashStringList; Name: PSystemString; const v: SystemString);
  end;

procedure TBigKeyAnalysis.doProgress(Sender: THashStringList; Name: PSystemString; const v: SystemString);
begin
  umlSeparatorText(v, output, ',;'#9);
end;

procedure BigKeyAnalysis(const Analysis: THashVariantList);
var
  tmp: TBigKeyAnalysis;
begin
  tmp := TBigKeyAnalysis.Create;
  tmp.output := Analysis;
  bigKeyDict.ProgressM(tmp.doProgress);
  DisposeObject(tmp);
end;

function BigKey(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
var
  n, tmp: TUPascalString;
  i, j: Integer;
  Successed: Boolean;
begin
  n := GBKString(s);
  Result := 0;

  i := 1;
  while i <= n.L do
    begin
      Successed := False;
      j := umlMin(bigKeyDict.HashList.MaxKeySize, n.L - i + 1);
      while j > 1 do
        begin
          tmp := n.Copy(i, j);
          Successed := bigKeyDict.Exists(tmp);
          if Successed then
            begin
              Completed.Add(tmp.Text);
              inc(Result);
              inc(i, j);
              Break;
            end;
          dec(j);
        end;

      if not Successed then
        begin
          Successed := MatchSingleWord and bigKeyDict.Exists(n[i]);
          if Successed then
            begin
              Completed.Add(n[i]);
              inc(Result);
            end
          else
            begin
              Unidentified.Add(n[i]);
            end;
          inc(i);
        end;
    end;
end;

function BigKeyValue(const s: TUPascalString; const MatchSingleWord: Boolean; const Analysis: THashVariantList): Integer;
var
  Unidentified: TListPascalString;
  Completed: TListPascalString;
  i: Integer;
begin
  Analysis.Clear;
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  Result := BigKey(s, MatchSingleWord, Unidentified, Completed);
  if Result > 0 then
    for i := 0 to Completed.Count - 1 do
        umlSeparatorText(bigKeyDict.GetDefaultValue(Completed[i], ''), Analysis, ',;'#9);
  DisposeObject([Unidentified, Completed]);
end;

function BigKeyWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;
var
  Unidentified: TListPascalString;
  Completed: TListPascalString;
  i: Integer;
begin
  Result := '';
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  if BigKey(s, MatchSingleWord, Unidentified, Completed) > 0 then
    begin
      for i := 0 to Completed.Count - 1 do
        begin
          if Result.L > 0 then
              Result.Append(',');
          Result.Append(Completed[i]);
        end;
    end;
  DisposeObject([Unidentified, Completed]);
end;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean; const Unidentified, Completed: TListPascalString): Integer;
var
  n, tmp: TUPascalString;
  i, j: Integer;
  Successed: Boolean;
begin
  n := GBKString(s);
  Result := 0;

  i := 1;
  while i <= n.L do
    begin
      Successed := False;
      j := umlMin(bigWordDict.MaxKeySize, n.L - i + 1);
      while j > 1 do
        begin
          tmp := n.Copy(i, j);
          Successed := bigWordDict.Exists(tmp);
          if Successed then
            begin
              Completed.Add(tmp.Text);
              inc(Result);
              inc(i, j);
              Break;
            end;
          dec(j);
        end;

      if not Successed then
        begin
          Successed := MatchSingleWord and bigWordDict.Exists(n[i]);
          if Successed then
            begin
              Completed.Add(n[i]);
              inc(Result);
            end
          else
            begin
              Unidentified.Add(n[i]);
            end;
          inc(i);
        end;
    end;
end;

function BigWord(const s: TUPascalString; const MatchSingleWord: Boolean): TPascalString;
var
  Unidentified: TListPascalString;
  Completed: TListPascalString;
  i: Integer;
begin
  Result := '';
  Unidentified := TListPascalString.Create;
  Completed := TListPascalString.Create;
  if BigWord(s, MatchSingleWord, Unidentified, Completed) > 0 then
    begin
      for i := 0 to Completed.Count - 1 do
        begin
          if Result.L > 0 then
              Result.Append(',');
          Result.Append(Completed[i]);
        end;
    end;
  DisposeObject([Unidentified, Completed]);
end;

initialization

end.
 
