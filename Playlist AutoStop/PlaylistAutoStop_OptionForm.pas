unit PlaylistAutoStop_OptionForm;

interface

uses
  Windows, SysUtils,
  //API
  apiObjects, apiCore, apiGUI, apiWrappersGUI;

type

  { TAIMPPluginOptionForm }

  TAIMPPluginOptionForm = class
  strict private
    FForm: IAIMPUIForm;
    FCategory: IAIMPUICategory;
    FSwitchOff: IAIMPUICheckBox;
    FHandlerChanged: TAIMPUINotifyEventAdapter;

    procedure HandlerChanged(const Sender: IUnknown);
  private
    function GetSwitchOff: Boolean;
    procedure SetSwitchOff(const Value: Boolean);
  protected
    procedure CreateControls(const AService: IAIMPServiceUI);
    //
    procedure SetControls;
  public
    OnModified: TProc;

    constructor Create(AParentWnd: HWND);
    destructor Destroy; override;
    function GetHandle: HWND;
    // External Events
    procedure ApplyLocalization;
    procedure ConfigLoad;
    procedure ConfigSave;
    //
    property SwitchOffEnabled: Boolean read GetSwitchOff write SetSwitchOff;
  end;

implementation

uses
  Math, apiWrappers, apiPlugin, apiMUI, PlaylistAutoStop_Defines;

{ TAIMPPluginOptionForm }

procedure TAIMPPluginOptionForm.ApplyLocalization;
begin
  //do nothing
end;

procedure TAIMPPluginOptionForm.ConfigLoad;
begin
  SwitchOffEnabled := mySettings.SwitchOff;
  //
  SetControls;
end;

procedure TAIMPPluginOptionForm.ConfigSave;
begin
  mySettings.SwitchOff := SwitchOffEnabled;
  SaveSettings(mySettings);
end;

constructor TAIMPPluginOptionForm.Create(AParentWnd: HWND);
var
  ABounds: Trect;
  AService: IAIMPServiceUI;
begin
  GetWindowRect(AParentWnd, ABounds);
  OffsetRect(ABounds, -ABounds.Left, -ABounds.Top);

  CoreGetService(IAIMPServiceUI, AService);
  CheckResult(AService.CreateForm(AParentWnd, AIMPUI_SERVICE_CREATEFORM_FLAGS_CHILD, MakeString(myPluginDLLName), nil, FForm));
  CheckResult(FForm.SetValueAsInt32(AIMPUI_FORM_PROPID_BORDERSTYLE, AIMPUI_FLAGS_BORDERSTYLE_NONE));
  CheckResult(FForm.SetPlacement(TAIMPUIControlPlacement.Create(ABounds)));

  FHandlerChanged := TAIMPUINotifyEventAdapter.Create(HandlerChanged);

  CreateControls(AService);
end;

procedure TAIMPPluginOptionForm.CreateControls(const AService: IAIMPServiceUI);
begin
  // Create the Category
  CheckResult(AService.CreateControl(FForm, FForm, MakeString(categoryAutostop), FHandlerChanged, IAIMPUICategory, FCategory));
  CheckResult(FCategory.SetPlacement(TAIMPUIControlPlacement.Create(ualClient, 0)));
  CheckResult(FCategory.SetValueAsObject(AIMPUI_CATEGORY_PROPID_CAPTION, GetLocalizationEx(myPluginDLLName, categoryAutostop, categoryAutostopDefault)));

  // Create the ExcludeOverride option
  CheckResult(AService.CreateControl(FForm, FCategory, MakeString('cbSwitchOffOnPlaylistOff'), FHandlerChanged, IAIMPUICheckBox, FSwitchOff));
  CheckResult(FSwitchOff.SetPlacement(TAIMPUIControlPlacement.Create(ualTop, 0)));
  CheckResult(FSwitchOff.SetValueAsInt32(AIMPUI_CHECKBOX_PROPID_STATE, Ord(False)));
end;

destructor TAIMPPluginOptionForm.Destroy;
begin
  FForm.Release(False);
  FForm := nil;

  inherited;
end;

function TAIMPPluginOptionForm.GetHandle: HWND;
begin
  Result := FForm.GetHandle;
end;

function TAIMPPluginOptionForm.GetSwitchOff: Boolean;
var
  Checked: Integer;
begin
  CheckResult(FSwitchOff.GetValueAsInt32(AIMPUI_CHECKBOX_PROPID_STATE, Checked));
  Result := Checked <> 0;
end;

procedure TAIMPPluginOptionForm.HandlerChanged(const Sender: IInterface);
begin
  if Assigned(OnModified) then OnModified();
end;

procedure TAIMPPluginOptionForm.SetControls;
begin

end;

procedure TAIMPPluginOptionForm.SetSwitchOff(const Value: Boolean);
begin
  CheckResult(FSwitchOff.SetValueAsInt32(AIMPUI_CHECKBOX_PROPID_STATE, IfThen(Value, 1, 0)));
end;

end.

