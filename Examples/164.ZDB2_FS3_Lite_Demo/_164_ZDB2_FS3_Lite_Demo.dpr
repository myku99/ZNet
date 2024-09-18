﻿program _164_ZDB2_FS3_Lite_Demo;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  Z.Core,
  Z.PascalStrings, Z.UPascalStrings, Z.UnicodeMixedLib, Z.Status, Z.Notify, Z.Cadencer, Z.MemoryStream,
  Z.ZDB2,
  Z.ZDB2.Thread,
  Z.ZDB2.Thread.LiteData,
  Z.Net.C4_FS3.ZDB2.LiteData;

{
  FS3-Lite是C4-FS3系统的底层数据库引擎(使用ZDB2设计数据引擎),FS3-Lite用于直接操作数据,不需要经过网络

  使用FS3-Lite前必须了解的事情

  FS3-Lite的整个设计放弃了使用线程锁机制
  繁多线程锁会让设计环节无法深入,也会导致使用中的陷进,作为周全考虑,线程锁放在用户层来干,怎么调度,由用户自定

  FS3-Lite有管线概念:当写入速度>物理IO速度,数据就会在内存滞留
  长时间运行这会让系统崩溃,通常万兆以太跑不满物理带宽,只需要做到IO写入速度>网络存取速度,该问题也就迎刃而解
  使用FS3-Lite时一定要明确管线,IO读取->写入FS3->数据放入FS3写入队列->完成写入

  FS3-Lite的设计和结构,以符合计算机运行机理方式编写而出,请自行研究代码
}

type
  TFS3_Lite_Demo = class
  public
    cad: TCadencer;
    inst: TZDB2_FS3_Lite;
    constructor Create;
    destructor Destroy; override;
    procedure do_Progress(Sender: TObject; const deltaTime, newTime: Double);
    procedure Run_FS3_Lite_Demo;
    procedure Do_Write_File_Demo;
  end;

constructor TFS3_Lite_Demo.Create;
begin
  inherited Create;
  cad := TCadencer.Create;
  cad.OnProgress := do_Progress;
  inst := TZDB2_FS3_Lite.Create(umlCombinePath(umlCurrentPath, 'FS3-Demo'));
  inst.Debug_Mode := True; // 开Debug是为了看见lite里面的运行状态
  inst.Build_Script_And_Open('Demo', True);
end;

destructor TFS3_Lite_Demo.Destroy;
begin
  DisposeObject(inst);
  DisposeObject(cad);
  inherited Destroy;
end;

procedure TFS3_Lite_Demo.do_Progress(Sender: TObject; const deltaTime, newTime: Double);
begin
  inst.Check_Life(deltaTime);
end;

procedure TFS3_Lite_Demo.Do_Write_File_Demo;
var
  i: Integer;
  tmp: TMem64;
  post_tool: TZDB2_FS3_Sync_Post_Queue_Tool;
begin
  for i := 0 to 5000 do // 仿真写入5000个文件,每个文件生命周期为5秒
    begin
      post_tool := inst.Create_Sync_Post_Queue;
      tmp := TMem64.Create;
      tmp.Size := 1024 * 500 + TMT19937.Rand32(1024 * 1024);
      TMT19937.Rand32(MaxInt, tmp.Memory, tmp.Size shr 2);
      post_tool.Begin_Post(TPascalString.RandomString(30), tmp.Size, tmp.ToMD5, umlNow, 5);
      post_tool.Post(tmp, True);
      post_tool.End_Post_And_Free;
    end;
end;

procedure TFS3_Lite_Demo.Run_FS3_Lite_Demo;
var
  tk: TTimeTick;
  running: Boolean;
begin
  DoStatus('开始运行FS3-Lite写入Demo,10秒后以IO完成状态自动退出.');

  // 单独开一条写入线程,仿真生成文件
  TCompute.RunM_NP(Do_Write_File_Demo, @running, nil);

  while running do
    begin
      cad.Progress;
      inst.Check_Recycle_Pool;
      CheckThread;
      TCompute.Sleep(100);
    end;
  DoStatus('全部仿真数据写入完成.');
  DoStatus('10秒后退出.');
  tk := GetTimeTick;
  while GetTimeTick - tk < 10000 do
    begin
      cad.Progress;
      inst.Check_Recycle_Pool;
      CheckThread;
      TCompute.Sleep(100);
    end;
end;

begin
  with TFS3_Lite_Demo.Create do
    begin
      Run_FS3_Lite_Demo;
      Free;
    end;

end.