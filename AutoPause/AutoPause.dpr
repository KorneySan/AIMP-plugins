library AutoPause;

uses
  apiPlugin,
  AutoPause_Impl in 'AutoPause_Impl.pas' {$R *.res},
  AutoPause_Defines in 'AutoPause_Defines.pas',
  AutoPause_OptionForm in 'AutoPause_OptionForm.pas',
  apiWrappers_my in 'apiWrappers_my.pas';

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
