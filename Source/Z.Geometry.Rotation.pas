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
{ * geometry Rotation imp                                                      * }
{ ****************************************************************************** }

unit Z.Geometry.Rotation;

{$DEFINE FPC_DELPHI_MODE}
{$I Z.Define.inc}

interface

uses
  Z.Geometry.Low;

procedure NormalizeMat(var M: TMatrix);
procedure MulRMat(var M: TMatrix; const ScaleXYZ: TAffineVector);

procedure DecodeOrderAngle(lvec, uvec, dvec: TAffineVector; var p, t, r: Single); overload;
procedure DecodeOrderAngle(lvec, uvec, dvec: TVector; var p, t, r: Single); overload;
procedure DecodeOrderAngle(uvec, dvec: TVector; var p, t, r: Single); overload;
procedure DecodeOrderAngle(M: TMatrix; var p, t, r: Single); overload;

function ComputePitch(uvec, dvec: TAffineVector): Single; overload;
function ComputePitch(uvec, dvec: TVector): Single; overload;
function ComputePitch(M: TMatrix): Single; overload;

function ComputeTurn(uvec, dvec: TAffineVector): Single; overload;
function ComputeTurn(uvec, dvec: TVector): Single; overload;
function ComputeTurn(M: TMatrix): Single; overload;

function ComputeRoll(uvec, dvec: TAffineVector): Single; overload;
function ComputeRoll(uvec, dvec: TVector): Single; overload;
function ComputeRoll(M: TMatrix): Single; overload;

procedure StepPitch(var uvec, dvec: TVector; angle: Single); overload;
procedure StepPitch(uvec, dvec: TVector; angle: Single; var p, t, r: Single); overload;
procedure StepPitch(M: TMatrix; angle: Single; var p, t, r: Single); overload;
procedure StepPitch(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

procedure StepTurn(var uvec, dvec: TVector; angle: Single); overload;
procedure StepTurn(uvec, dvec: TVector; angle: Single; var p, t, r: Single); overload;
procedure StepTurn(M: TMatrix; angle: Single; var p, t, r: Single); overload;
procedure StepTurn(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

procedure StepRoll(var uvec, dvec: TVector; angle: Single); overload;
procedure StepRoll(uvec, dvec: TVector; angle: Single; var p, t, r: Single); overload;
procedure StepRoll(M: TMatrix; angle: Single; var p, t, r: Single); overload;
procedure StepRoll(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

procedure SetPitch(var uvec, dvec: TAffineVector; angle: Single); overload;
procedure SetPitch(var uvec, dvec: TVector; angle: Single); overload;
procedure SetPitch(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

procedure SetTurn(var uvec, dvec: TAffineVector; angle: Single); overload;
procedure SetTurn(var uvec, dvec: TVector; angle: Single); overload;
procedure SetTurn(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

procedure SetRoll(var uvec, dvec: TAffineVector; angle: Single); overload;
procedure SetRoll(var uvec, dvec: TVector; angle: Single); overload;
procedure SetRoll(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single); overload;

implementation

procedure NormalizeMat(var M: TMatrix);
begin
  NormalizeVector(M[0]);
  NormalizeVector(M[1]);
  NormalizeVector(M[2]);
end;

procedure MulRMat(var M: TMatrix; const ScaleXYZ: TAffineVector);
begin
  M[0][0] := M[0][0] * ScaleXYZ[0];
  M[0][0] := M[0][1] * ScaleXYZ[0];
  M[0][0] := M[0][2] * ScaleXYZ[0];
  M[0][0] := M[0][3] * ScaleXYZ[0];

  M[1][0] := M[1][0] * ScaleXYZ[1];
  M[1][0] := M[1][1] * ScaleXYZ[1];
  M[1][0] := M[1][2] * ScaleXYZ[1];
  M[1][0] := M[1][3] * ScaleXYZ[1];

  M[2][0] := M[2][0] * ScaleXYZ[2];
  M[2][0] := M[2][1] * ScaleXYZ[2];
  M[2][0] := M[2][2] * ScaleXYZ[2];
  M[2][0] := M[2][3] * ScaleXYZ[2];
end;

procedure DecodeOrderAngle(lvec, uvec, dvec: TAffineVector; var p, t, r: Single);
var
  sinTurn, cosTurn, sinPitch, cosPitch, sinRoll, cosRoll: Single;
begin
  sinTurn := -dvec[0];
  cosTurn := Sqrt(1 - sinTurn * sinTurn);

  if (Abs(cosTurn) > Epsilon) then
    begin
      sinPitch := dvec[1] / cosTurn;
      cosPitch := dvec[2] / cosTurn;
      sinRoll := uvec[0] / cosTurn;
      cosRoll := lvec[0] / cosTurn;
    end
  else
    begin
      sinPitch := -uvec[2];
      cosPitch := uvec[1];
      sinRoll := 0;
      cosRoll := 1;
    end;

  p := RadToDeg_(ArcTan2_(sinPitch, cosPitch));
  t := -RadToDeg_(ArcTan2_(sinTurn, cosTurn));
  r := -RadToDeg_(ArcTan2_(sinRoll, cosRoll));
end;

procedure DecodeOrderAngle(lvec, uvec, dvec: TVector; var p, t, r: Single);
begin
  DecodeOrderAngle(PAffineVector(@lvec)^, PAffineVector(@uvec)^, PAffineVector(@dvec)^, p, t, r);
end;

procedure DecodeOrderAngle(uvec, dvec: TVector; var p, t, r: Single);
var
  lvec: TVector;
begin
  lvec := VectorCrossProduct(uvec, dvec);
  NormalizeVector(lvec);
  DecodeOrderAngle(lvec, uvec, dvec, p, t, r);
end;

procedure DecodeOrderAngle(M: TMatrix; var p, t, r: Single);
begin
  DecodeOrderAngle(M[0], M[1], M[2], p, t, r);
end;

function ComputePitch(uvec, dvec: TAffineVector): Single; overload;
var
  sinTurn, cosTurn, sinPitch, cosPitch: Single;
begin
  sinTurn := -dvec[0];
  cosTurn := Sqrt(1 - sinTurn * sinTurn);
  sinPitch := dvec[1] / cosTurn;
  cosPitch := dvec[2] / cosTurn;
  Result := RadToDeg_(ArcTan2_(sinPitch, cosPitch));
end;

function ComputePitch(uvec, dvec: TVector): Single; overload;
begin
  Result := ComputePitch(PAffineVector(@uvec)^, PAffineVector(@dvec)^);
end;

function ComputePitch(M: TMatrix): Single; overload;
begin
  Result := ComputePitch(M[1], M[2]);
end;

function ComputeTurn(uvec, dvec: TAffineVector): Single; overload;
var
  sinTurn, cosTurn: Single;
begin
  sinTurn := -dvec[0];
  cosTurn := Sqrt(1 - sinTurn * sinTurn);

  Result := -RadToDeg_(ArcTan2_(sinTurn, cosTurn));
end;

function ComputeTurn(uvec, dvec: TVector): Single; overload;
begin
  Result := ComputeTurn(PAffineVector(@uvec)^, PAffineVector(@dvec)^);
end;

function ComputeTurn(M: TMatrix): Single; overload;
begin
  Result := ComputeTurn(M[1], M[2]);
end;

function ComputeRoll(uvec, dvec: TAffineVector): Single; overload;
var
  lvec: TAffineVector;
  sinTurn, cosTurn, sinRoll, cosRoll: Single;
begin
  lvec := VectorCrossProduct(uvec, dvec);

  sinTurn := -dvec[0];
  cosTurn := Sqrt(1 - sinTurn * sinTurn);

  sinRoll := uvec[0] / cosTurn;
  cosRoll := lvec[0] / cosTurn;

  Result := -RadToDeg_(ArcTan2_(sinRoll, cosRoll));
end;

function ComputeRoll(uvec, dvec: TVector): Single; overload;
begin
  Result := ComputeRoll(PAffineVector(@uvec)^, PAffineVector(@dvec)^);
end;

function ComputeRoll(M: TMatrix): Single; overload;
begin
  Result := ComputeRoll(M[1], M[2]);
end;

procedure StepPitch(var uvec, dvec: TVector; angle: Single);
var
  rvec: TVector;
begin
  angle := -DegToRad_(angle);
  rvec := VectorCrossProduct(dvec, uvec);

  RotateVector(uvec, rvec, angle);
  NormalizeVector(uvec);

  RotateVector(dvec, rvec, angle);
  NormalizeVector(dvec);
end;

procedure StepPitch(uvec, dvec: TVector; angle: Single; var p, t, r: Single);
begin
  StepPitch(uvec, dvec, angle);
  DecodeOrderAngle(uvec, dvec, p, t, r);
end;

procedure StepPitch(M: TMatrix; angle: Single; var p, t, r: Single);
begin
  StepPitch(M, XYZVector, angle);
  DecodeOrderAngle(M, p, t, r);
end;

procedure StepPitch(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  StepPitch(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

procedure StepTurn(var uvec, dvec: TVector; angle: Single);
var
  uvec2: TAffineVector;
begin
  angle := -DegToRad_(angle);
  uvec2 := AffineVectorMake(uvec);

  RotateVector(uvec, uvec2, angle);
  NormalizeVector(uvec);

  RotateVector(dvec, uvec2, angle);
  NormalizeVector(dvec);
end;

procedure StepTurn(uvec, dvec: TVector; angle: Single; var p, t, r: Single);
begin
  StepTurn(uvec, dvec, angle);
  DecodeOrderAngle(uvec, dvec, p, t, r);
end;

procedure StepTurn(M: TMatrix; angle: Single; var p, t, r: Single);
begin
  StepTurn(M, XYZVector, angle);
  DecodeOrderAngle(M, p, t, r);
end;

procedure StepTurn(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  StepTurn(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

procedure StepRoll(var uvec, dvec: TVector; angle: Single);
var
  dvec2: TVector;
begin
  angle := -DegToRad_(angle);
  dvec2 := dvec;

  RotateVector(uvec, dvec2, angle);
  NormalizeVector(uvec);

  RotateVector(dvec, dvec2, angle);
  NormalizeVector(dvec);
end;

procedure StepRoll(uvec, dvec: TVector; angle: Single; var p, t, r: Single);
begin
  StepRoll(uvec, dvec, angle);
  DecodeOrderAngle(uvec, dvec, p, t, r);
end;

procedure StepRoll(M: TMatrix; angle: Single; var p, t, r: Single);
begin
  StepRoll(M, XYZVector, angle);
  DecodeOrderAngle(M, p, t, r);
end;

procedure StepRoll(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  StepRoll(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

procedure SetPitch(var uvec, dvec: TAffineVector; angle: Single);
var
  rvec: TAffineVector;
  Diff: Single;
  rotMatrix: TMatrix;
begin
  rvec := VectorCrossProduct(dvec, uvec);
  Diff := DegToRad_(ComputePitch(uvec, dvec) - angle);
  rotMatrix := CreateRotationMatrix(rvec, Diff);

  uvec := VectorTransform(uvec, rotMatrix);
  NormalizeVector(uvec);

  dvec := VectorTransform(dvec, rotMatrix);
  NormalizeVector(dvec);
end;

procedure SetPitch(var uvec, dvec: TVector; angle: Single);
begin
  SetPitch(PAffineVector(@uvec)^, PAffineVector(@dvec)^, angle);
end;

procedure SetPitch(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  SetPitch(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

procedure SetTurn(var uvec, dvec: TAffineVector; angle: Single);
var
  rvec: TAffineVector;
  Diff: Single;
  rotMatrix: TMatrix;
begin
  rvec := VectorCrossProduct(dvec, uvec);
  Diff := DegToRad_(ComputeTurn(uvec, dvec) - angle);

  rotMatrix := CreateRotationMatrix(uvec, Diff);

  uvec := VectorTransform(uvec, rotMatrix);
  NormalizeVector(uvec);

  dvec := VectorTransform(dvec, rotMatrix);
  NormalizeVector(dvec);
end;

procedure SetTurn(var uvec, dvec: TVector; angle: Single);
begin
  SetTurn(PAffineVector(@uvec)^, PAffineVector(@dvec)^, angle);
end;

procedure SetTurn(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  SetTurn(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

procedure SetRoll(var uvec, dvec: TAffineVector; angle: Single);
var
  rvec: TAffineVector;
  Diff: Single;
  rotMatrix: TMatrix;
begin
  rvec := VectorCrossProduct(dvec, uvec);
  Diff := DegToRad_(ComputeRoll(uvec, dvec) - angle);

  rotMatrix := CreateRotationMatrix(dvec, Diff);

  uvec := VectorTransform(uvec, rotMatrix);
  NormalizeVector(uvec);

  dvec := VectorTransform(dvec, rotMatrix);
  NormalizeVector(dvec);
end;

procedure SetRoll(var uvec, dvec: TVector; angle: Single);
begin
  SetRoll(PAffineVector(@uvec)^, PAffineVector(@dvec)^, angle);
end;

procedure SetRoll(var M: TMatrix; ScaleXYZ: TAffineVector; angle: Single);
begin
  NormalizeMat(M);
  SetRoll(M[1], M[2], angle);
  // change left vector
  M[0] := VectorCrossProduct(M[1], M[2]);
  MulRMat(M, ScaleXYZ);
end;

end.
 
