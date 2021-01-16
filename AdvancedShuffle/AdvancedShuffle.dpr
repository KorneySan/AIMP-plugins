library AdvancedShuffle;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  apiPlugin,
  AdvancedShuffle_Impl in 'AdvancedShuffle_Impl.pas',
  AdvancedShuffle_Defines in 'AdvancedShuffle_Defines.pas',
  AdvancedShuffle_SetupFrame in 'AdvancedShuffle_SetupFrame.pas' {AIMPOptionFrame},
  ControlsLocalization in '..\Utils\ControlsLocalization.pas',
  AdvancedShuffle_Intf in 'AdvancedShuffle_Intf.pas';

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
