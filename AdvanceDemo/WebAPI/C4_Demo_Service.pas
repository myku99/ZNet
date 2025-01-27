unit C4_Demo_Service;

interface

uses Variants,
{$IFDEF FPC}
  Z.FPC.GenericList,
{$ENDIF FPC}
  Z.Core, Z.PascalStrings, Z.UPascalStrings, Z.Status, Z.UnicodeMixedLib,
  Z.Geometry2D, Z.DFE, Z.ListEngine,
  Z.Parsing, Z.Expression, Z.OpCode,
  Z.Notify, Z.Cipher, Z.MemoryStream,
  Z.Net, Z.Net.PhysicsIO, Z.Net.DoubleTunnelIO.NoAuth, Z.Net.C4,
  Z.TextDataEngine,
  Z.ZDB2.TE, Z.ZDB2, Z.HashList.Templet;

type
  TC40_Demo_Service = class(TC40_Base_NoAuth_Service)
  protected
    // 服务器请求命令
    procedure cmd_Get_Demo_info(Sender: TPeerIO; InData, OutData: TDFE);
  protected
    // 服务器调试命令
    // 编写c4服务器时,凡能调试的地方,需要看状态的地方,都往这里堆命令
    procedure CC_Set_Demo_Info(var OP_Param: TOpParam);
  public
    Demo_Info: string;
    constructor Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String); override;
    destructor Destroy; override;
    procedure SafeCheck; override;
    procedure Progress; override;
  end;

  TC40_Demo_Client = class(TC40_Base_NoAuth_Client)
  public
    constructor Create(PhysicsTunnel_: TC40_PhysicsTunnel; source_: TC40_Info; Param_: U_String); override;
    destructor Destroy; override;
    procedure Progress; override;
    procedure Get_Demo_Info_M(OnResult: TOnStream_M);
    procedure Get_Demo_Info_P(OnResult: TOnStream_P);
  end;

implementation


procedure TC40_Demo_Service.cmd_Get_Demo_info(Sender: TPeerIO; InData, OutData: TDFE);
begin
  OutData.WriteString(Demo_Info);
end;

procedure TC40_Demo_Service.CC_Set_Demo_Info(var OP_Param: TOpParam);
begin
  Demo_Info := VarToStr(OP_Param[0]);
end;

constructor TC40_Demo_Service.Create(PhysicsService_: TC40_PhysicsService; ServiceTyp, Param_: U_String);
begin
  inherited;
  // 注册请求
  DTNoAuthService.RecvTunnel.RegisterStream('Get_Demo_info').OnExecute := {$IFDEF FPC}@{$ENDIF FPC}cmd_Get_Demo_info;

  Demo_Info := 'hello world';

  // 注册调试命令
  Register_ConsoleCommand('Set_Demo_Info', 'Set_Demo_Info(设置webapi的返回值)').OnEvent_M := {$IFDEF FPC}@{$ENDIF FPC}CC_Set_Demo_Info;
end;

destructor TC40_Demo_Service.Destroy;
begin
  inherited;
end;

procedure TC40_Demo_Service.SafeCheck;
begin
  inherited;
end;

procedure TC40_Demo_Service.Progress;
begin
  inherited;
end;

constructor TC40_Demo_Client.Create(PhysicsTunnel_: TC40_PhysicsTunnel; source_: TC40_Info; Param_: U_String);
begin
  inherited;
end;

destructor TC40_Demo_Client.Destroy;
begin
  inherited;
end;

procedure TC40_Demo_Client.Progress;
begin
  inherited;
end;

procedure TC40_Demo_Client.Get_Demo_Info_M(OnResult: TOnStream_M);
begin
  DTNoAuthClient.SendTunnel.SendStreamCmdM('Get_Demo_Info', nil, OnResult);
end;

procedure TC40_Demo_Client.Get_Demo_Info_P(OnResult: TOnStream_P);
begin
  DTNoAuthClient.SendTunnel.SendStreamCmdP('Get_Demo_Info', nil, OnResult);
end;

initialization

RegisterC40('Demo', TC40_Demo_Service, TC40_Demo_Client);

end.
