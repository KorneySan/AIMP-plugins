library PlaylistAutoStop;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  apiPlugin,
  PlaylistAutoStop_Impl in 'PlaylistAutoStop_Impl.pas' {$R *.res},
  PlaylistAutoStop_Defines in 'PlaylistAutoStop_Defines.pas',
  PlaylistAutoStop_OptionForm in 'PlaylistAutoStop_OptionForm.pas';

{$R *.res}

function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
begin
  try
    Header := TAIMPPlugin.Create;
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

exports
  AIMPPluginGetHeader;

begin
end.
