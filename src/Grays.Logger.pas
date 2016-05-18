unit Grays.Logger;

interface

uses Windows, Classes, Sysutils, Generics.Collections, System.IOUtils, System.StrUtils, System.Types;

type
  TLoggerLevel = (llError, llWarning, llDebug, llInfo);

  TLogger = record
  private const
    C_LOGSTR: array [0 .. 3] of string = ('Error', 'Warning', 'Debug', 'Info');
    class function InitPart(APart: string): Boolean; static;
    class procedure FreeLog; static;
    class procedure InitLog; static;
  public
    class procedure EnableLog; static;
    class procedure AddLog(APart, AMsg: string; ALevel: TLoggerLevel = llInfo); static;
    class function LogEabled: Boolean; static;
  end;
{$IFDEF DEBUG}
{$ENDIF}

implementation

var
  FLogPath: string;
  FLogEnabled: Boolean;
  FLocks: TDictionary<String, TObject>;
  FPartStreams: TDictionary<String, TFileStream>;

  { TLogger }

class procedure TLogger.AddLog(APart, AMsg: string; ALevel: TLoggerLevel);
var
  I: Integer;
  AIndent: string;
  AObject: TObject;
  ALogs: TStringDynArray;
begin
  if not FLogEnabled then
    Exit;
  if not FLocks.ContainsKey(APart) then
  begin
    AObject := TObject.Create;
    FLocks.Add(APart, AObject);
  end;
  TMonitor.Enter(FLocks[APart]);
  try
    try
      if not TLogger.InitPart(APart) then
        Exit;

      AIndent := Format('[%s] [%s]: ', [FormatDateTime('hh:nn:ss.zzz', Now), C_LOGSTR[Integer(ALevel)]]);
      ALogs := SplitString(AMsg, #13);
      if Length(ALogs) > 0 then
        begin
          AMsg := AIndent + TrimRight(ALogs[0])+#13#10;
        for I := 1 to Length(ALogs)-1 do
          AMsg :=  AMsg + DupeString(' ', Length(AIndent))+TrimRight(ALogs[I])+#13#10;

        FPartStreams[APart].Write(AMsg[1], Length(AMsg)*2);
      end;
    except
    end;
  finally
    TMonitor.Enter(FLocks[APart]);
  end;
end;

class procedure TLogger.EnableLog;
begin
  try
    FLogPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'log\';
    if not DirectoryExists(FLogPath) then
      ForceDirectories(FLogPath);
    FLogEnabled := True;
  except
  end;
end;

class procedure TLogger.FreeLog;
var
  S: String;
begin
  for S in FPartStreams.Keys do
     FPartStreams[S].Free;

  FreeAndNil(FPartStreams);
  for S in FLocks.Keys do
     FLocks[S].Free;
  FreeAndNil(FLocks);
end;


class procedure TLogger.InitLog;
begin
  FLocks := TDictionary<String, TObject>.Create();
  FPartStreams := TDictionary<String, TFileStream>.Create();
end;

class function TLogger.InitPart(APart: string): Boolean;
var
  AFile: string;
  AMode: Integer;
  AStream: TFileStream;
begin
  try
    if FPartStreams.ContainsKey(APart) then
      Exit(True);

    AFile := Format('%s%s%s.log', [FLogPath, APart, FormatDateTime('yyyymmdd', Now)]);
    if TFile.Exists(AFile) then
      AMode := fmOpenWrite or fmShareDenyNone
    else
      AMode := fmCreate or fmShareDenyNone;
    AStream := TFileStream.Create(AFile, AMode);
    AStream.Position := AStream.Size;
    if AStream.Position =0 then
      AStream.Write(#$FF#$FE, 2);
    FPartStreams.AddOrSetValue(APart, AStream);
    Result := True;
  except
    Result := False;
  end;
end;

class function TLogger.LogEabled: Boolean;
begin
  Exit(FLogEnabled);
end;

initialization

TLogger.InitLog;

finalization

TLogger.FreeLog;

end.
