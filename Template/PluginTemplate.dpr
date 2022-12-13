library PluginTemplate;

uses
  apiPlugin,
  PluginTemplate.Impl in 'PluginTemplate.Impl.pas',
  PluginTemplate.Defines in 'PluginTemplate.Defines.pas',
  PluginTemplate.OptionsFrame in 'PluginTemplate.OptionsFrame.pas';

{$R *.res}

function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
begin
  try
    Header := TAIMPPluginTemplate.Create;
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

exports
  AIMPPluginGetHeader;

begin
end.
