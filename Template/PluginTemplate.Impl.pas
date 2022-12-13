unit PluginTemplate.Impl;

interface

uses
  //Common
  Windows,
  //Helpers
  AIMPCustomPlugin,
  //API
  apiCore,
  apiPlugin;

type

  { TAIMPPlugin }

  TAIMPPluginTemplate = class(TAIMPCustomPlugin)
  private
    function TestForServices: Boolean;
  protected
    // IAIMPPlugin
    function InfoGet(Index: Integer): PWideChar; virtual; stdcall;
    function InfoGetCategories: DWORD; virtual; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; virtual; stdcall;
    procedure Finalize; virtual; stdcall;
  end;

implementation

uses
  //Common
  SysUtils,
  //API
  apiOptions,
  apiWrappers,
  //PluginTemplate
  PluginTemplate.Defines,
  PluginTemplate.OptionsFrame;

{ TAIMPPluginTemplate }

procedure TAIMPPluginTemplate.Finalize;
begin
 //do something
end;

function TAIMPPluginTemplate.InfoGet(Index: Integer): PWideChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      begin
        if thisPluginName = '' then
          Result := nil
        else
          Result := thisPluginName + ' v' + thisPluginVersion;
      end;
    AIMP_PLUGIN_INFO_AUTHOR:
      begin
        if thisPluginAuthor = '' then
          Result := nil
        else
          Result := thisPluginAuthor;
      end;
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      begin
        if thisPluginShortDescription = '' then
          Result := nil
        else
          Result := thisPluginShortDescription;
      end;
    AIMP_PLUGIN_INFO_FULL_DESCRIPTION:
      begin
        if thisPluginFullDescription = '' then
          Result := nil
        else
          Result := thisPluginFullDescription;
      end
  else
    Result := nil;
  end;
end;

function TAIMPPluginTemplate.InfoGetCategories: DWORD;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPPluginTemplate.Initialize(Core: IAIMPCore): HRESULT;
begin
  Result := inherited Initialize(Core);
  if Succeeded(Result) then
   begin
    if not TestForServices then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    Core.RegisterExtension(IID_IAIMPServiceOptionsDialog, TAIMPPluginTemplateOptionFrame.Create);
   end;
end;

function TAIMPPluginTemplate.TestForServices: Boolean;
var
  AServiceOptions: IAIMPServiceOptionsDialog;
begin
  Result := true;
  //Options service
  Result := Result and Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions);
  AServiceOptions := nil;
end;

end.
