﻿(*
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
{******************************************************************************}
{                                                                              }
{       Delphi cross platform socket library                                   }
{                                                                              }
{       Copyright (c) 2017 WiNDDRiVER(soulawing@gmail.com)                     }
{                                                                              }
{       Homepage: https://github.com/winddriver/Delphi-Cross-Socket            }
{                                                                              }
{******************************************************************************}
unit Z.Utils.RegEx;

// winddriver是个喜欢把程序模型写死的家伙，这并不是一个好习惯，cross的代码一旦出问题，非常难改
// 编译符号全局定义可以有效统一和优化参数，建议所有的库，包括用户自己在工程建的库都引用一下全局定义
{$I ..\..\Z.Define.inc}

interface

uses
  System.RegularExpressions, System.RegularExpressionsCore;

type
  TMatchEvaluatorProc = reference to function(const AMatch: TMatch): string;

  IScopeEvaluator = interface
    function GetMatchEvaluator: TMatchEvaluator;

    property MatchEvaluator: TMatchEvaluator read GetMatchEvaluator;
  end;

  TScopeEvaluator = class(TInterfacedObject, IScopeEvaluator)
  private
    FMatchEvaluatorProc: TMatchEvaluatorProc;

    function MatchEvaluator(const AMatch: TMatch): string;
    function GetMatchEvaluator: TMatchEvaluator;
  public
    constructor Create(AMatchEvaluatorProc: TMatchEvaluatorProc);
  end;

  TRegExHelper = record helper for TRegEx
    function Replace(const Input: string; Evaluator: TMatchEvaluatorProc): string; overload;
    function Replace(const Input: string; Evaluator: TMatchEvaluatorProc; Count: Integer): string; overload;
    class function Replace(const Input, Pattern: string; Evaluator: TMatchEvaluatorProc): string; overload; static;
    class function Replace(const Input, Pattern: string; Evaluator: TMatchEvaluatorProc; Options: TRegExOptions): string; overload; static;
  end;

implementation

{ TScopeEvaluator }

constructor TScopeEvaluator.Create(AMatchEvaluatorProc: TMatchEvaluatorProc);
begin
  FMatchEvaluatorProc := AMatchEvaluatorProc;
end;

function TScopeEvaluator.GetMatchEvaluator: TMatchEvaluator;
begin
  Result := Self.MatchEvaluator;
end;

function TScopeEvaluator.MatchEvaluator(const AMatch: TMatch): string;
begin
  if Assigned(FMatchEvaluatorProc) then
    Result := FMatchEvaluatorProc(AMatch);
end;

{ TRegExHelper }

function TRegExHelper.Replace(const Input: string;
  Evaluator: TMatchEvaluatorProc; Count: Integer): string;
var
  LScopeEvaluator: IScopeEvaluator;
begin
  LScopeEvaluator := TScopeEvaluator.Create(Evaluator);
  Result := Self.Replace(Input, LScopeEvaluator.MatchEvaluator, Count);
end;

function TRegExHelper.Replace(const Input: string;
  Evaluator: TMatchEvaluatorProc): string;
var
  LScopeEvaluator: IScopeEvaluator;
begin
  LScopeEvaluator := TScopeEvaluator.Create(Evaluator);
  Result := Self.Replace(Input, LScopeEvaluator.MatchEvaluator);
end;

class function TRegExHelper.Replace(const Input, Pattern: string;
  Evaluator: TMatchEvaluatorProc; Options: TRegExOptions): string;
var
  LScopeEvaluator: IScopeEvaluator;
begin
  LScopeEvaluator := TScopeEvaluator.Create(Evaluator);
  Result := Replace(Input, Pattern, LScopeEvaluator.MatchEvaluator, Options);
end;

class function TRegExHelper.Replace(const Input, Pattern: string;
  Evaluator: TMatchEvaluatorProc): string;
var
  LScopeEvaluator: IScopeEvaluator;
begin
  LScopeEvaluator := TScopeEvaluator.Create(Evaluator);
  Result := Replace(Input, Pattern, LScopeEvaluator.MatchEvaluator);
end;

end.
 
