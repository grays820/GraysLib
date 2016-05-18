unit Grays.Loger;

interface

uses Windows, Classes, Sysutils, Generics.Collections;

type
   TLogger = record
   private
     class procedure InitPart(APart: string); static;
     class procedure _AddLog(APart,AMsg: string); static;
     class procedure FreeLog; static;
   public
     class procedure EnableLog; static;
     class procedure AddLog(APart, AMsg: string); static;
     class function LogEabled: Boolean; static;
   end;

implementation

var
  FFiles: TDictionary<String,String>;
  LogPath: string;
  BEnableLog: Boolean;
  FThreadLock: TRTLCriticalSection;

{ TLogger }

class procedure TLogger.AddLog(APart,AMsg: string);
var
  I: Integer;
  AList: TStrings;
begin
  if not BEnableLog then
    Exit;
  EnterCriticalSection(FThreadLock);
  try
    try
      TLogger.InitPart(APart);
      AList := TStringList.Create;
      try
        AList.Text := AMsg;
        if AList.Count > 0 then
        begin
          AList[0] := FormatDateTime('[yy-mm-dd hh:nn:ss] ', Now) + AList[0];
          for I := 1 to AList.Count - 1 do
            AList[I] := '                   ' + AList[I];
          AMsg := AList.Text;
        end;
        TLogger._AddLog(APart, AMsg);
      finally
        AList.Free;
      end;
    except
    end;
  finally
    LeaveCriticalSection(FThreadLock);
  end;
end;

class procedure TLogger.EnableLog;
begin
  try
    LogPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +'log\';
    if not DirectoryExists(LogPath) then
      ForceDirectories(LogPath);
    BEnableLog := True;
  except
  end;
end;

class procedure TLogger.FreeLog;
begin
  if Assigned(FFiles) then
    FreeAndNil(FFiles);
end;

class procedure TLogger.InitPart(APart: string);
var
  AFile: string;
begin
  try
    if not Assigned(FFiles) then
      FFiles := TDictionary<String,String>.Create;
    if not FFiles.ContainsKey(APart) then
    begin
      AFile := Format('%s%s.log',[LogPath,APart]);
      FFiles.Add(APart,AFile);
    end;
  except
  end;
end;

class function TLogger.LogEabled: Boolean;
begin
  Exit(BEnableLog);
end;

class procedure TLogger._AddLog(APart, AMsg: String);
var
  HFile: TextFile;
begin
  try
    AssignFile(Hfile,FFiles[APart]);
    try
      if FileExists(FFiles[APart]) then
        Append(Hfile)
      else
        Rewrite(HFile);
      writeln(Hfile, Trim(AMsg));
    finally
       CloseFile(Hfile);
    end;
  Except
  end;
end;

initialization
  InitializeCriticalSection(FThreadLock);

finalization
  TLogger.FreeLog;
  DeleteCriticalSection(FThreadLock);

end.
