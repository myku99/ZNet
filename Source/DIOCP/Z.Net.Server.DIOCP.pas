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
{ * DIOCP Support                                                              * }
{ ****************************************************************************** }
(*
  DIOCP Server的最大连接被限制到20000
  update history
*)
unit Z.Net.Server.DIOCP;

{$I ..\Z.Define.inc}

interface

uses SysUtils, Classes,
  Z.PascalStrings,
  Z.Net, Z.Core, Z.UnicodeMixedLib, Z.MemoryStream, Z.DFE,
  Z.diocp_tcp_server,
  Z.diocp_core_engine;

type
  TDIOCPServer_PeerIO = class;

  TIocpClientContextIntf_WithDServ = class(TIocpClientContext)
  private
    Link: TDIOCPServer_PeerIO;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TDIOCPServer_PeerIO = class(TPeerIO)
  private
    Link: TIocpClientContextIntf_WithDServ;
    lastSendBufferTag: Integer;
    WasSending: Boolean;
    SendingStream: TMS64;
  public
    procedure CreateAfter; override;
    destructor Destroy; override;

    function Connected: Boolean; override;
    procedure Disconnect; override;
    procedure Write_IO_Buffer(const buff: PByte; const Size: NativeInt); override;
    procedure WriteBufferOpen; override;
    procedure WriteBufferFlush; override;
    procedure WriteBufferClose; override;
    function GetPeerIP: SystemString; override;
    function WriteBuffer_is_NULL: Boolean; override;
    procedure Progress; override;
  end;

  TZNet_Server_DIOCP = class(TZNet_Server)
  private
  protected
    FDIOCPServer: TDiocpTcpServer;
    procedure DIOCP_IOAccept(pvSocket: THandle; pvAddr: String; pvPort: Integer; var vAllowAccept: Boolean);
    procedure DIOCP_IOConnected(pvClientContext: TIocpClientContext);
    procedure DIOCP_IODisconnect(pvClientContext: TIocpClientContext);
    procedure DIOCP_IOSend(pvContext: TIocpClientContext; pvRequest: TIocpSendRequest);
    procedure DIOCP_IOSendCompleted(pvContext: TIocpClientContext; pvBuff: Pointer; Len: Cardinal; pvBufferTag: Integer; pvTagData: Pointer; pvErrorCode: Integer);
    procedure DIOCP_IOReceive(pvClientContext: TIocpClientContext; Buf: Pointer; Len: Cardinal; ErrCode: Integer);
  public
    constructor Create; override;
    destructor Destroy; override;
    function StartService(Host: SystemString; Port: Word): Boolean; override;
    procedure StopService; override;
    procedure Progress; override;
    function WaitSendConsoleCmd(p_io: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut_: TTimeTick): SystemString; override;
    procedure WaitSendStreamCmd(p_io: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDFE; TimeOut_: TTimeTick); override;
  end;

implementation

constructor TIocpClientContextIntf_WithDServ.Create;
begin
  inherited Create;
  Link := nil;
end;

destructor TIocpClientContextIntf_WithDServ.Destroy;
var
  PeerIO: TDIOCPServer_PeerIO;
begin
  if Link <> nil then
    begin
      PeerIO := Link;
      Link := nil;
      DisposeObject(PeerIO);
    end;
  inherited Destroy;
end;

procedure TDIOCPServer_PeerIO.CreateAfter;
begin
  inherited CreateAfter;
  Link := nil;
  lastSendBufferTag := 0;
  WasSending := False;
  SendingStream := TMS64.Create;
end;

destructor TDIOCPServer_PeerIO.Destroy;
var
  clink: TIocpClientContextIntf_WithDServ;
begin
  if Link <> nil then
    begin
      clink := Link;
      Link := nil;
      clink.Link := nil;
      clink.PostWSACloseRequest;
    end;

  DisposeObject(SendingStream);
  inherited Destroy;
end;

function TDIOCPServer_PeerIO.Connected: Boolean;
begin
  Result := (Link <> nil);
end;

procedure TDIOCPServer_PeerIO.Disconnect;
var
  clink: TIocpClientContextIntf_WithDServ;
begin
  if Link <> nil then
    begin
      clink := Link;
      Link := nil;
      clink.Link := nil;
      clink.PostWSACloseRequest;
    end;
  DisposeObject(Self);
end;

procedure TDIOCPServer_PeerIO.Write_IO_Buffer(const buff: PByte; const Size: NativeInt);
begin
  if not Connected then
      Exit;

  if Size > 0 then
      SendingStream.WritePtr(buff, Size);
end;

procedure TDIOCPServer_PeerIO.WriteBufferOpen;
begin
  WriteBufferFlush;
end;

procedure TDIOCPServer_PeerIO.WriteBufferFlush;
begin
  if SendingStream.Size > 0 then
    begin
      inc(lastSendBufferTag);
      WasSending := True;
      // 因为DIOCP的发送是基于数据队列
      // 把所有的预置数据以队列方式fill后再发
      // 这里我用flush方式后置化发送数据，做到每次发送出去的是一个块，一般来说，这里被zs触发时，都是一个ip包左右的大小
      Link.PostWSASendRequest(SendingStream.Memory, SendingStream.Size, dtFreeMem, lastSendBufferTag, nil);
      SendingStream.DiscardMemory;
    end;
end;

procedure TDIOCPServer_PeerIO.WriteBufferClose;
begin
  WriteBufferFlush;
end;

function TDIOCPServer_PeerIO.GetPeerIP: SystemString;
begin
  if Connected then
      Result := Link.RemoteAddr + ' ' + IntToStr(Link.RemotePort)
  else
      Result := '';
end;

function TDIOCPServer_PeerIO.WriteBuffer_is_NULL: Boolean;
begin
  if Connected then
      Result := (not WasSending) and (Link.GetSendQueueSize <= 0)
  else
      Result := True;
end;

procedure TDIOCPServer_PeerIO.Progress;
begin
  inherited Progress;
  Process_Send_Buffer();
end;

procedure TZNet_Server_DIOCP.DIOCP_IOAccept(pvSocket: THandle; pvAddr: String; pvPort: Integer; var vAllowAccept: Boolean);
begin
  vAllowAccept := Count < 20000;
end;

procedure TZNet_Server_DIOCP.DIOCP_IOConnected(pvClientContext: TIocpClientContext);
begin
  TCompute.Sync(TCore_Thread.CurrentThread, procedure
    begin
      TIocpClientContextIntf_WithDServ(pvClientContext).Link := TDIOCPServer_PeerIO.Create(Self, pvClientContext);
      TIocpClientContextIntf_WithDServ(pvClientContext).Link.Link := TIocpClientContextIntf_WithDServ(pvClientContext);
    end);
end;

procedure TZNet_Server_DIOCP.DIOCP_IODisconnect(pvClientContext: TIocpClientContext);
begin
  if TIocpClientContextIntf_WithDServ(pvClientContext).Link = nil then
      Exit;

  TCompute.Sync(TCore_Thread.CurrentThread, procedure
    begin
      DisposeObject(TIocpClientContextIntf_WithDServ(pvClientContext).Link);
    end);
end;

procedure TZNet_Server_DIOCP.DIOCP_IOSend(pvContext: TIocpClientContext; pvRequest: TIocpSendRequest);
begin
end;

procedure TZNet_Server_DIOCP.DIOCP_IOSendCompleted(pvContext: TIocpClientContext; pvBuff: Pointer; Len: Cardinal; pvBufferTag: Integer; pvTagData: Pointer; pvErrorCode: Integer);
var
  PeerIO: TDIOCPServer_PeerIO;
begin
  if TIocpClientContextIntf_WithDServ(pvContext).Link = nil then
      Exit;
  PeerIO := TIocpClientContextIntf_WithDServ(pvContext).Link;
  if PeerIO.lastSendBufferTag = pvBufferTag then
      PeerIO.WasSending := False;
end;

procedure TZNet_Server_DIOCP.DIOCP_IOReceive(pvClientContext: TIocpClientContext; Buf: Pointer; Len: Cardinal; ErrCode: Integer);
begin
  if TIocpClientContextIntf_WithDServ(pvClientContext).Link = nil then
      Exit;
  TIocpClientContextIntf_WithDServ(pvClientContext).Link.Write_Physics_Fragment(Buf, Len);
end;

constructor TZNet_Server_DIOCP.Create;
begin
  inherited Create;
  EnabledAtomicLockAndMultiThread := False;

  FDIOCPServer := TDiocpTcpServer.Create(nil);

  FDIOCPServer.OnContextAccept := DIOCP_IOAccept;
  FDIOCPServer.OnContextConnected := DIOCP_IOConnected;
  FDIOCPServer.OnContextDisconnected := DIOCP_IODisconnect;
  FDIOCPServer.OnSendRequestResponse := DIOCP_IOSend;
  FDIOCPServer.OnSendBufferCompleted := DIOCP_IOSendCompleted;
  FDIOCPServer.OnDataReceived := DIOCP_IOReceive;

  FDIOCPServer.WorkerCount := 4;
  FDIOCPServer.MaxSendingQueueSize := 20000;
  FDIOCPServer.NoDelayOption := True;
  FDIOCPServer.KeepAlive := True;
  FDIOCPServer.KeepAliveTime := 5000;
  FDIOCPServer.RegisterContextClass(TIocpClientContextIntf_WithDServ);

  name := 'DIOCP-Server';
end;

destructor TZNet_Server_DIOCP.Destroy;
begin
  StopService;
  DisposeObject(FDIOCPServer);
  Check_Soft_Thread_Synchronize(1, False);
  inherited Destroy;
end;

function TZNet_Server_DIOCP.StartService(Host: SystemString; Port: Word): Boolean;
begin
  FDIOCPServer.DefaultListenAddress := Host;
  FDIOCPServer.Port := Port;

  try
    FDIOCPServer.Active := True;
    Result := True;
  except
      Result := False;
  end;
end;

procedure TZNet_Server_DIOCP.StopService;
begin
  FDIOCPServer.Active := False;
  Check_Soft_Thread_Synchronize(1, False);
end;

procedure TZNet_Server_DIOCP.Progress;
begin
  inherited Progress;
  Check_Soft_Thread_Synchronize(1, False);
end;

function TZNet_Server_DIOCP.WaitSendConsoleCmd(p_io: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut_: TTimeTick): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport');
end;

procedure TZNet_Server_DIOCP.WaitSendStreamCmd(p_io: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDFE; TimeOut_: TTimeTick);
begin
  RaiseInfo('WaitSend no Suppport');
end;

initialization

finalization

end.
 
