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
{ * IndyInterface                                                              * }
{ ****************************************************************************** }
(*
  INDY Server的最大连接被限制到20
  update history
*)
unit Z.Net.Server.Indy;
(*
  update history
*)

{$DEFINE FPC_DELPHI_MODE}
{$I ..\Z.Define.inc}

interface

uses Z.Net,
  Z.Core,
  Z.PascalStrings,
  Z.DFE, Z.ListEngine, Z.MemoryStream,

  Classes, SysUtils,

  IdCustomTCPServer, IdTCPServer, IdYarn, IdSchedulerOfThread, IdSocketHandle,
  IDGlobal, IdBaseComponent, IdComponent, IdTCPConnection, IdContext;

type
  TCommunicationFramework_Server_Context = class;

  TIDServer_PeerIO = class(TPeerIO)
  public
    RealSendBuff: TMS64;

    procedure CreateAfter; override;
    destructor Destroy; override;

    function Context: TCommunicationFramework_Server_Context;
    procedure ProcesRealSendBuff;

    function Connected: Boolean; override;
    procedure Disconnect; override;
    procedure Write_IO_Buffer(const buff: PByte; const Size: NativeInt); override;
    procedure WriteBufferOpen; override;
    procedure WriteBufferFlush; override;
    procedure WriteBufferClose; override;
    function GetPeerIP: SystemString; override;
  end;

  TCommunicationFramework_Server_Context = class(TIdServerContext)
  public
    ClientIntf: TIDServer_PeerIO;
    LastTimeTick: TTimeTick;
    constructor Create(AConnection: TIdTCPConnection; AYarn: TIdYarn; AList: TIdContextThreadList = nil); override;
    destructor Destroy; override;
  end;

  TZNet_Server_Indy = class(TZNet_Server)
  protected
    FDriver: TIdTCPServer;

    function GetPort: Word;
    procedure SetPort(const Value: Word);
    procedure SetIdleTimeout(const Value: TTimeTick); override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Progress; override;

    property Port: Word read GetPort write SetPort;

    procedure StopService; override;
    function StartService(Host: SystemString; Port: Word): Boolean; override;

    procedure Indy_Connect(AContext: TIdContext);
    procedure Indy_ContextCreated(AContext: TIdContext);
    procedure Indy_Disconnect(AContext: TIdContext);
    procedure Indy_Exception(AContext: TIdContext; AException: Exception);

    procedure Indy_Execute(AContext: TIdContext);

    function WaitSendConsoleCmd(p_io: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut_: TTimeTick): SystemString; override;
    procedure WaitSendStreamCmd(p_io: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDFE; TimeOut_: TTimeTick); override;

    property driver: TIdTCPServer read FDriver;
  end;

implementation

uses Z.UnicodeMixedLib, Z.Status;

function ToIDBytes(p: PByte; Size: Integer): TIdBytes;
begin
  SetLength(Result, Size);
  CopyPtr(p, @Result[0], Size);
end;

procedure TIDServer_PeerIO.CreateAfter;
begin
  inherited CreateAfter;
  RealSendBuff := TMS64.CustomCreate(1024 * 1024);
end;

destructor TIDServer_PeerIO.Destroy;
begin
  DisposeObject(RealSendBuff);
  inherited Destroy;
end;

function TIDServer_PeerIO.Context: TCommunicationFramework_Server_Context;
begin
  Result := IOInterface as TCommunicationFramework_Server_Context;
end;

procedure TIDServer_PeerIO.ProcesRealSendBuff;
var
  buff: ^TIdBytes;
begin
  new(buff);
  SetLength(buff^, 0);
  TCompute.Sync(procedure
    begin
      if RealSendBuff.Size > 0 then
        begin
          SetLength(buff^, RealSendBuff.Size);
          CopyPtr(RealSendBuff.Memory, @buff^[0], RealSendBuff.Size);
          RealSendBuff.Clear;
        end;
    end);

  if length(buff^) > 0 then
    begin
      Context.Connection.IOHandler.WriteBufferOpen;
      Context.Connection.IOHandler.write(buff^);
      Context.Connection.IOHandler.WriteBufferFlush;
      Context.Connection.IOHandler.WriteBufferClose;
      SetLength(buff^, 0);
    end;
  Dispose(buff);
end;

function TIDServer_PeerIO.Connected: Boolean;
begin
  if Context <> nil then
      Result := Context.Connection.Connected
  else
      Result := False;
end;

procedure TIDServer_PeerIO.Disconnect;
begin
  Context.Connection.Disconnect;
  inherited Disconnect;
end;

procedure TIDServer_PeerIO.Write_IO_Buffer(const buff: PByte; const Size: NativeInt);
begin
  if Size > 0 then
    begin
      RealSendBuff.Position := RealSendBuff.Size;
      RealSendBuff.WritePtr(buff, Size);
    end;
end;

procedure TIDServer_PeerIO.WriteBufferOpen;
begin
end;

procedure TIDServer_PeerIO.WriteBufferFlush;
begin
end;

procedure TIDServer_PeerIO.WriteBufferClose;
begin
end;

function TIDServer_PeerIO.GetPeerIP: SystemString;
begin
  Result := Context.Binding.PeerIP;
end;

constructor TCommunicationFramework_Server_Context.Create(AConnection: TIdTCPConnection; AYarn: TIdYarn; AList: TIdContextThreadList);
begin
  inherited Create(AConnection, AYarn, AList);
  LastTimeTick := GetTimeTick;
end;

destructor TCommunicationFramework_Server_Context.Destroy;
begin
  if ClientIntf <> nil then
    begin
      DisposeObject(ClientIntf);
      ClientIntf := nil;
    end;
  inherited Destroy;
end;

function TZNet_Server_Indy.GetPort: Word;
begin
  Result := FDriver.DefaultPort;
end;

procedure TZNet_Server_Indy.SetPort(const Value: Word);
begin
  FDriver.DefaultPort := Value;
end;

procedure TZNet_Server_Indy.SetIdleTimeout(const Value: TTimeTick);
begin
  inherited SetIdleTimeout(Value);
  FDriver.TerminateWaitTime := IdleTimeout;
end;

constructor TZNet_Server_Indy.Create;
begin
  inherited CreateCustomHashPool(128);
  EnabledAtomicLockAndMultiThread := False;

  FDriver := TIdTCPServer.Create(nil);
  FDriver.UseNagle := False;
  FDriver.MaxConnections := 20;
  FDriver.ContextClass := TCommunicationFramework_Server_Context;
  FDriver.TerminateWaitTime := IdleTimeout;

  FDriver.OnConnect := Indy_Connect;
  FDriver.OnContextCreated := Indy_ContextCreated;
  FDriver.OnDisconnect := Indy_Disconnect;
  FDriver.OnException := Indy_Exception;
  FDriver.OnExecute := Indy_Execute;

  name := 'INDY-Server';
end;

destructor TZNet_Server_Indy.Destroy;
begin
  ProgressPeerIOP(procedure(cli: TPeerIO)
    begin
      try
          cli.Disconnect;
      except
      end;
    end);

  try
    while Count > 0 do
      begin
        Check_Soft_Thread_Synchronize(1, False);
      end;
  except
  end;

  try
    if FDriver.Active then
        FDriver.StopListening;
  except
  end;

  DisposeObject(FDriver);
  inherited Destroy;
end;

procedure TZNet_Server_Indy.Progress;
begin
  inherited Progress;
end;

procedure TZNet_Server_Indy.StopService;
begin
  if FDriver.Active then
    begin
      Check_Soft_Thread_Synchronize(100, False);
      try
          FDriver.Active := False;
      except
      end;
    end;
end;

function TZNet_Server_Indy.StartService(Host: SystemString; Port: Word): Boolean;
var
  bIP: TIdSocketHandle;
begin
  FDriver.Bindings.Clear;
  bIP := FDriver.Bindings.Add;
  bIP.IP := Host;
  if IsIPV6(Host) then
      bIP.IPVersion := TIdIPVersion.Id_IPv6
  else
      bIP.IPVersion := TIdIPVersion.Id_IPv4;

  bIP.Port := Port;

  FDriver.DefaultPort := Port;
  Result := False;
  try
    if not FDriver.Active then
      begin
        FDriver.Active := True;
        Result := True;
      end;
  except
      Result := False;
  end;
end;

procedure TZNet_Server_Indy.Indy_Connect(AContext: TIdContext);
begin
  TCompute.Sync(procedure
    var
      c: TCommunicationFramework_Server_Context;
    begin
      c := TCommunicationFramework_Server_Context(AContext);
      c.ClientIntf := TIDServer_PeerIO.Create(Self, c);
      c.Binding.SetKeepAliveValues(True, 2000, 2);
    end);
end;

procedure TZNet_Server_Indy.Indy_ContextCreated(AContext: TIdContext);
var
  c: TCommunicationFramework_Server_Context;
begin
  c := TCommunicationFramework_Server_Context(AContext);
end;

procedure TZNet_Server_Indy.Indy_Disconnect(AContext: TIdContext);
begin
  TCompute.Sync(procedure
    var
      c: TCommunicationFramework_Server_Context;
    begin
      c := TCommunicationFramework_Server_Context(AContext);
      if c.ClientIntf <> nil then
        begin
          DisposeObject(c.ClientIntf);
          c.ClientIntf := nil;
        end;
    end);
end;

procedure TZNet_Server_Indy.Indy_Exception(AContext: TIdContext; AException: Exception);
begin
  TCompute.Sync(procedure
    var
      c: TCommunicationFramework_Server_Context;
    begin
      c := TCommunicationFramework_Server_Context(AContext);
      if c.ClientIntf <> nil then
        begin
          DisposeObject(c.ClientIntf);
          c.ClientIntf := nil;
        end;
    end);
end;

procedure TZNet_Server_Indy.Indy_Execute(AContext: TIdContext);
var
  t: TTimeTick;
  c: TCommunicationFramework_Server_Context;
  iBuf: TIdBytes;
begin
  c := TCommunicationFramework_Server_Context(AContext);

  if c.ClientIntf = nil then
      Exit;

  c.ClientIntf.ProcesRealSendBuff;

  try
    TCompute.Sync(procedure
      begin
        c.ClientIntf.Process_Send_Buffer;
      end);

    t := GetTimeTick + 5000;
    while (c.ClientIntf <> nil) and (c.Connection.Connected) and (c.ClientIntf.WaitOnResult) do
      begin
        TCompute.Sync(procedure
          begin
            c.ClientIntf.Process_Send_Buffer;
          end);

        c.Connection.IOHandler.CheckForDataOnSource(10);
        if c.Connection.IOHandler.InputBuffer.Size > 0 then
          begin
            t := GetTimeTick + 5000;
            c.LastTimeTick := GetTimeTick;
            c.Connection.IOHandler.InputBuffer.ExtractToBytes(iBuf);
            c.Connection.IOHandler.InputBuffer.Clear;
            TCompute.Sync(procedure
              begin
                c.ClientIntf.Write_Physics_Fragment(@iBuf[0], length(iBuf));
              end);
            SetLength(iBuf, 0);
          end
        else if GetTimeTick > t then
          begin
            if c.ClientIntf <> nil then
              begin
                DisposeObject(c.ClientIntf);
                c.ClientIntf := nil;
              end;
            Break;
          end;
      end;
  except
    if c.ClientIntf <> nil then
      begin
        DisposeObject(c.ClientIntf);
        c.ClientIntf := nil;
      end;
  end;

  if c.ClientIntf = nil then
      Exit;

  try
    c.Connection.IOHandler.CheckForDataOnSource(10);
    while c.Connection.IOHandler.InputBuffer.Size > 0 do
      begin
        c.LastTimeTick := GetTimeTick;
        c.Connection.IOHandler.InputBuffer.ExtractToBytes(iBuf);
        c.Connection.IOHandler.InputBuffer.Clear;
        try
          TCompute.Sync(procedure
            begin
              c.ClientIntf.Write_Physics_Fragment(@iBuf[0], length(iBuf));
            end);
          SetLength(iBuf, 0);
          c.Connection.IOHandler.CheckForDataOnSource(10);
        except
          if c.ClientIntf <> nil then
            begin
              DisposeObject(c.ClientIntf);
              c.ClientIntf := nil;
            end;
        end;
      end;
    if c.ClientIntf = nil then
        Exit;
  except
    if c.ClientIntf <> nil then
      begin
        DisposeObject(c.ClientIntf);
        c.ClientIntf := nil;
      end;
  end;

  if c.ClientIntf = nil then
      Exit;
end;

function TZNet_Server_Indy.WaitSendConsoleCmd(p_io: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut_: TTimeTick): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport IndyServer');
end;

procedure TZNet_Server_Indy.WaitSendStreamCmd(p_io: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDFE; TimeOut_: TTimeTick);
begin
  RaiseInfo('WaitSend no Suppport IndyServer');
end;

end.
 
