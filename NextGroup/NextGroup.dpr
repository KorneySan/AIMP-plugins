library NextGroup;

uses
  apiPlugin,
  NextGroup_Impl in 'NextGroup_Impl.pas',
  NextGroup_Defines in 'NextGroup_Defines.pas';

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

