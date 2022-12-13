unit PluginTemplate.OptionsFrame;

interface

uses
  //Common
  Windows,
  SysUtils,
  //API
  AIMPCustomPlugin,
  apiObjects,
  apiCore,
  apiGUI,
  apiOptions;

type

  { TAIMPPluginTemplateOptionForm }

  TAIMPPluginTemplateOptionForm = class
  strict private
    FForm: IAIMPUIForm;

    procedure HandlerChanged(const Sender: IUnknown);
  protected
    procedure CreateControls(const AService: IAIMPServiceUI);
  public
    OnModified: TProc;

    constructor Create(AParentWnd: HWND);
    destructor Destroy; override;
    function GetHandle: HWND;
    // External Events
    procedure ApplyLocalization;
    procedure ConfigLoad;
    procedure ConfigSave;
  end;

  { TAIMPPluginTemplateOptionFrame }

  TAIMPPluginTemplateOptionFrame = class(TInterfacedObject, IAIMPOptionsDialogFrame)
  strict private
    FForm: TAIMPPluginTemplateOptionForm;

    procedure HandlerModified;
  protected
    // IAIMPOptionsDialogFrame
    function CreateFrame(ParentWnd: HWND): HWND; stdcall;
    procedure DestroyFrame; stdcall;
    function GetName(out S: IAIMPString): HRESULT; stdcall;
    procedure Notification(ID: Integer); stdcall;
  end;

implementation

uses
  //API
  apiWrappers,
  //PluginTemplate
  PluginTemplate.Defines;

{ TAIMPPluginTemplateOptionForm }

procedure TAIMPPluginTemplateOptionForm.ApplyLocalization;
begin
 //do something extra with controls
end;

procedure TAIMPPluginTemplateOptionForm.ConfigLoad;
begin
 //do something with plugin settings
end;

procedure TAIMPPluginTemplateOptionForm.ConfigSave;
begin
 //do something with plugin settings
end;

constructor TAIMPPluginTemplateOptionForm.Create(AParentWnd: HWND);
var
  ABounds: Trect;
  AService: IAIMPServiceUI;
begin
  GetWindowRect(AParentWnd, ABounds);
  OffsetRect(ABounds, -ABounds.Left, -ABounds.Top);

  CoreGetService(IAIMPServiceUI, AService);
  CheckResult(AService.CreateForm(AParentWnd, AIMPUI_SERVICE_CREATEFORM_FLAGS_CHILD, MakeString('DemoForm'), nil, FForm));
  CheckResult(FForm.SetValueAsInt32(AIMPUI_FORM_PROPID_BORDERSTYLE, AIMPUI_FLAGS_BORDERSTYLE_NONE));
  CheckResult(FForm.SetPlacement(TAIMPUIControlPlacement.Create(ABounds)));

  CreateControls(AService);
end;

procedure TAIMPPluginTemplateOptionForm.CreateControls(
  const AService: IAIMPServiceUI);
begin
 //create any controls required
end;

destructor TAIMPPluginTemplateOptionForm.Destroy;
begin
  FForm.Release(False);
  FForm := nil;

  inherited;
end;

function TAIMPPluginTemplateOptionForm.GetHandle: HWND;
begin
  Result := FForm.GetHandle;
end;

procedure TAIMPPluginTemplateOptionForm.HandlerChanged(const Sender: IInterface);
begin
  if Assigned(OnModified) then OnModified();
end;

{ TAIMPPluginTemplateOptionFrame }

function TAIMPPluginTemplateOptionFrame.CreateFrame(ParentWnd: HWND): HWND;
begin
  FForm := TAIMPPluginTemplateOptionForm.Create(ParentWnd);
  FForm.OnModified := HandlerModified;
  Result := FForm.GetHandle;
end;

procedure TAIMPPluginTemplateOptionFrame.DestroyFrame;
begin
  FreeAndNil(FForm);
end;

function TAIMPPluginTemplateOptionFrame.GetName(out S: IAIMPString): HRESULT;
begin
  try
    S := MakeString(thisPluginName);
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

procedure TAIMPPluginTemplateOptionFrame.HandlerModified;
var
  AServiceOptions: IAIMPServiceOptionsDialog;
begin
  if Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions) then
    AServiceOptions.FrameModified(Self);
end;

procedure TAIMPPluginTemplateOptionFrame.Notification(ID: Integer);
begin
  if FForm <> nil then
    case ID of
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOCALIZATION:
        FForm.ApplyLocalization;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOAD:
        FForm.ConfigLoad;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_SAVE:
        FForm.ConfigSave;
    end;
end;

end.
