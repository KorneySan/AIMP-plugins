unit AutoPause_OptionForm;

interface

uses
  Windows, SysUtils,
  // API
  apiObjects, apiGUI, apiWrappersGUI;

type

  { TAIMPPluginOptionForm }

  TAIMPPluginOptionForm = class
  strict private
    FForm: IAIMPUIForm;
    FCategory: IAIMPUICategory;
    FGroupBoxPCLock: IAIMPUIGroupBox;
    FComboBoxPCLock: IAIMPUIComboBox;
    FCheckBoxPCLock: IAIMPUICheckBox;
    FHandlerChanged: TAIMPUINotifyEventAdapter;
    FComboBoxChanged: TAIMPUINotifyEventAdapter;
    FGroupBoxPCIdle: IAIMPUIGroupBox;
    FComboBoxPCIdle: IAIMPUIComboBox;
    FCheckBoxPCIdle: IAIMPUICheckBox;
    FGroupBoxPCScreenSaver: IAIMPUIGroupBox;
    FComboBoxPCScreenSaver: IAIMPUIComboBox;
    FCheckBoxPCScreenSaver: IAIMPUICheckBox;

    procedure HandlerChanged(const Sender: IUnknown);
    procedure ComboBoxChanged(const Sender: IUnknown);
  private

  protected
    procedure CreateControls;
    //
    procedure GetControls;
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
  end;

implementation

uses
  Math, apiWrappers, AutoPause_Defines, apiWrappers_my;

{ TAIMPPluginOptionForm }

procedure TAIMPPluginOptionForm.ApplyLocalization;
begin
  // do nothing
end;

procedure TAIMPPluginOptionForm.ComboBoxChanged(const Sender: IInterface);
  procedure CheckChomboBoxForCheck(AComboBox: IAIMPUIComboBox; ACheckBox: IAIMPUICheckBox);
  var
    b: Boolean;
  begin
   if Assigned(AComboBox) then
    begin
     b := PropListGetInt32(AComboBox, AIMPUI_COMBOBOX_PROPID_ITEMINDEX) = 1;
     if Assigned(ACheckBox) then
       SetControlEnabled(ACheckBox, b);
    end;
  end;
begin
  CheckChomboBoxForCheck(FComboBoxPCLock, FCheckBoxPCLock);
  CheckChomboBoxForCheck(FComboBoxPCIdle, FCheckBoxPCIdle);
  CheckChomboBoxForCheck(FComboBoxPCScreenSaver, FCheckBoxPCScreenSaver);
  HandlerChanged(Sender);
end;

procedure TAIMPPluginOptionForm.ConfigLoad;
begin
  SetControls;
end;

procedure TAIMPPluginOptionForm.ConfigSave;
begin
  GetControls;
  SaveSettings(mySettings);
end;

constructor TAIMPPluginOptionForm.Create(AParentWnd: HWND);
begin
  CreateOptionForm(AParentWnd, myPluginDLLName, FForm);

  FHandlerChanged := TAIMPUINotifyEventAdapter.Create(HandlerChanged);
  FComboBoxChanged := TAIMPUINotifyEventAdapter.Create(ComboBoxChanged);

  CreateControls;
end;

procedure TAIMPPluginOptionForm.CreateControls;
  procedure CreateSettingsGroup(Parent: IAIMPUIWinControl; const Name, DefaultName: String; out AGroup: IAIMPUIGroupBox);
  begin
   CreateGroupBox(FForm, Parent, Name,
     GetLocalization(Name, DefaultName), FHandlerChanged,
     ualTop, AGroup);
  end;
  procedure CreateSettingsCombo(Parent: IAIMPUIWinControl; const Name: String; out ACombo: IAIMPUIComboBox);
  begin
   CreateComboBox(FForm, Parent, Name, FComboBoxChanged,
     ualTop, comboboxItems, 3, ACombo);
  end;
  procedure CreateSettingsCheck(Parent: IAIMPUIWinControl; const Name, DefaultName: String; const DefaultValue: Boolean; out ACheck: IAIMPUICheckBox);
  begin
   CreateCheckBox(FForm, Parent, Name,
     GetLocalization(Name, DefaultName), FHandlerChanged,
     ualTop, DefaultValue, ACheck);
  end;
begin
  // Create the Category
  CreateCategory(FForm, FForm, categoryAutopause,
    GetLocalization(categoryAutopause, categoryAutopauseDefault),
    FHandlerChanged, ualClient, FCategory);
  // PC Lock
  CreateSettingsGroup(FCategory, groupboxPCLock, groupboxPCLockDefault, FGroupBoxPCLock);
  CreateSettingsCombo(FGroupBoxPCLock, comboboxPCLock, FComboBoxPCLock);
  CreateSettingsCheck(FGroupBoxPCLock, checkboxPCLock, checkboxPCLockDefault,
  checkboxPCLockDefaultValue, FCheckBoxPCLock);
  SetControlEnabled(FCheckBoxPCLock, False);
  // PC Idle
  CreateSettingsGroup(FCategory, groupboxPCIdle, groupboxPCIdleDefault, FGroupBoxPCIdle);
  CreateSettingsCombo(FGroupBoxPCIdle, comboboxPCIdle, FComboBoxPCIdle);
  CreateSettingsCheck(FGroupBoxPCIdle, checkboxPCIdle, checkboxPCIdleDefault,
  checkboxPCIdleDefaultValue, FCheckBoxPCIdle);
  SetControlEnabled(FCheckBoxPCIdle, False);
  // ScreenSaver
  CreateSettingsGroup(FCategory, groupboxPCScreenSaver, groupboxPCScreenSaverDefault, FGroupBoxPCScreenSaver);
  CreateSettingsCombo(FGroupBoxPCScreenSaver, comboboxPCScreenSaver, FComboBoxPCScreenSaver);
  CreateSettingsCheck(FGroupBoxPCScreenSaver, checkboxPCScreenSaver, checkboxPCScreenSaverDefault,
  checkboxPCScreenSaverDefaultValue, FCheckBoxPCScreenSaver);
  SetControlEnabled(FCheckBoxPCScreenSaver, False);
end;

destructor TAIMPPluginOptionForm.Destroy;
begin
  FForm.Release(False);
  FForm := nil;

  inherited;
end;

procedure TAIMPPluginOptionForm.GetControls;
  procedure ControlsToSettings(AComboBox: IAIMPUIComboBox; ACheckBox: IAIMPUICheckBox; var SActions: TSettingsActions);
  begin
   with SActions do
    begin
     PlayerAction := TAPAction(GetComboBoxItemIndex(AComboBox));
     DoResume := GetCheckBoxCheck(ACheckBox);
    end;
  end;
begin
  with mySettings do
   begin
    ControlsToSettings(FComboBoxPCLock, FCheckBoxPCLock, PCLock);
    ControlsToSettings(FComboBoxPCIdle, FCheckBoxPCIdle, PCIdle);
    ControlsToSettings(FComboBoxPCScreenSaver, FCheckBoxPCScreenSaver, PCScreenSaver);
   end;
end;

function TAIMPPluginOptionForm.GetHandle: HWND;
begin
  Result := FForm.GetHandle;
end;

procedure TAIMPPluginOptionForm.HandlerChanged(const Sender: IInterface);
begin
  if Assigned(OnModified) then
    OnModified();
end;

procedure TAIMPPluginOptionForm.SetControls;
  procedure SettingsToControls(const SActions: TSettingsActions; AComboBox: IAIMPUIComboBox; ACheckBox: IAIMPUICheckBox);
  begin
   with SActions do
    begin
     SetComboBoxItemIndex(AComboBox, Ord(PlayerAction));
     SetCheckBoxCheck(ACheckBox, DoResume);
    end;
  end;
begin
  with mySettings do
   begin
    SettingsToControls(PCLock, FComboBoxPCLock, FCheckBoxPCLock);
    SettingsToControls(PCIdle, FComboBoxPCIdle, FCheckBoxPCIdle);
    SettingsToControls(PCScreenSaver, FComboBoxPCScreenSaver, FCheckBoxPCScreenSaver);
   end;
end;

end.
