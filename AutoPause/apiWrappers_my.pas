unit apiWrappers_my;

interface

uses
  Windows,
  apiObjects,
  apiGUI;

  { apiPlayer }

const
  // Player state
  AIMP_PLAYER_STATE_UNDEFINED = -1;
  AIMP_PLAYER_STATE_STOPPED = 0;
  AIMP_PLAYER_STATE_PAUSE = 1;
  AIMP_PLAYER_STATE_PLAYING = 2;

function GetPlayerState: Integer;

  { apiGUI }

procedure CreateOptionForm(const AParentWnd: HWND; const FormName: String;
  out AForm: IAIMPUIForm);
procedure CreateCategory(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  CategoryName, CategoryCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out ACategory: IAIMPUICategory;
  AServiceUI: IAIMPServiceUI = nil);
procedure CreateCheckBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  CheckBoxName, CheckBoxCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; const DefaultValue: Boolean;
  out ACheckBox: IAIMPUICheckBox; AServiceUI: IAIMPServiceUI = nil);
procedure SetCheckBoxCheck(ACheckBox: IAIMPUICheckBox; const Value: Boolean);
function GetCheckBoxCheck(ACheckBox: IAIMPUICheckBox): Boolean;
procedure CreateGroupBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  GroupBoxName, GroupBoxCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out AGroupBox: IAIMPUIGroupBox;
  AServiceUI: IAIMPServiceUI = nil);
procedure CreateComboBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  ComboBoxName: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; const SectionName: string;
  const Count: Integer; out AComboBox: IAIMPUIComboBox;
  AServiceUI: IAIMPServiceUI = nil);
procedure SetComboBoxItemIndex(AComboBox: IAIMPUIComboBox; const Value: Integer);
function GetComboBoxItemIndex(AComboBox: IAIMPUIComboBox): Integer;
procedure ComboBoxUpdateLocalization(AComboBox: IAIMPUIComboBox; const SectionName: string);
procedure CreateLabel(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  LabelName, LabelText: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out ALabel: IAIMPUILabel; AServiceUI: IAIMPServiceUI = nil);
procedure CreateButton(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  ButtonName, ButtonCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out AButton: IAIMPUIButton;
  AServiceUI: IAIMPServiceUI = nil);
procedure SetControlEnabled(APropertyList: IAIMPPropertyList; Enabled: Boolean);

implementation

uses
  SysUtils,
  // API
  apiWrappers,
  apiPlayer;

  { apiPlayer }

function GetPlayerState: Integer;
var
  APService: IAIMPServicePlayer;
begin
  Result := AIMP_PLAYER_STATE_UNDEFINED;
  if Supports(CoreIntf, IAIMPServicePlayer, APService) then
    Result := APService.GetState;
  APService := nil;
end;

  { apiGUI }

procedure CreateOptionForm(const AParentWnd: HWND; const FormName: String;
  out AForm: IAIMPUIForm);
var
  ABounds: Trect;
  AService: IAIMPServiceUI;
begin
  GetWindowRect(AParentWnd, ABounds);
  OffsetRect(ABounds, -ABounds.Left, -ABounds.Top);

  CoreGetService(IAIMPServiceUI, AService);
  CheckResult(AService.CreateForm(AParentWnd,
    AIMPUI_SERVICE_CREATEFORM_FLAGS_CHILD, MakeString(FormName), nil, AForm));
  CheckResult(AForm.SetValueAsInt32(AIMPUI_FORM_PROPID_BORDERSTYLE,
    AIMPUI_FLAGS_BORDERSTYLE_NONE));
  CheckResult(AForm.SetPlacement(TAIMPUIControlPlacement.Create(ABounds)));

  AService := nil;
end;

procedure CreateCategory(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  CategoryName, CategoryCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out ACategory: IAIMPUICategory;
  AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(CategoryName),
    EventsHandler, IAIMPUICategory, ACategory));
  CheckResult(ACategory.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(ACategory.SetValueAsObject(AIMPUI_CATEGORY_PROPID_CAPTION,
    MakeString(CategoryCaption)));
end;

procedure CreateCheckBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  CheckBoxName, CheckBoxCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; const DefaultValue: Boolean;
  out ACheckBox: IAIMPUICheckBox; AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(CheckBoxName),
    EventsHandler, IAIMPUICheckBox, ACheckBox));
  CheckResult(ACheckBox.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(ACheckBox.SetValueAsInt32(AIMPUI_CHECKBOX_PROPID_STATE,
    Ord(DefaultValue)));
  CheckResult(ACheckBox.SetValueAsObject(AIMPUI_CHECKBOX_PROPID_CAPTION,
    MakeString(CheckBoxCaption)));
end;

procedure SetCheckBoxCheck(ACheckBox: IAIMPUICheckBox; const Value: Boolean);
begin
  PropListSetInt32(ACheckBox, AIMPUI_CHECKBOX_PROPID_STATE, Ord(Value));
end;

function GetCheckBoxCheck(ACheckBox: IAIMPUICheckBox): Boolean;
begin
  Result := PropListGetBool(ACheckBox, AIMPUI_CHECKBOX_PROPID_STATE);
end;

procedure CreateGroupBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  GroupBoxName, GroupBoxCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out AGroupBox: IAIMPUIGroupBox;
  AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(GroupBoxName),
    EventsHandler, IAIMPUIGroupBox, AGroupBox));
  CheckResult(AGroupBox.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(AGroupBox.SetValueAsInt32(AIMPUI_GROUPBOX_PROPID_AUTOSIZE, 1));
  CheckResult(AGroupBox.SetValueAsObject(AIMPUI_GROUPBOX_PROPID_CAPTION,
    MakeString(GroupBoxCaption)));
end;

procedure CreateComboBox(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  ComboBoxName: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; const SectionName: string;
  const Count: Integer; out AComboBox: IAIMPUIComboBox;
  AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
  J: Integer;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(ComboBoxName),
    EventsHandler, IAIMPUIComboBox, AComboBox));
  CheckResult(AComboBox.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(AComboBox.SetValueAsInt32(AIMPUI_COMBOBOX_PROPID_STYLE, 1));
  //
  for J := 0 to Count - 1 do
    CheckResult(AComboBox.Add(LangLoadStringEx(SectionName + '\i[' + IntToStr(J)
      + ']'), 0));
  CheckResult(AComboBox.SetValueAsInt32(AIMPUI_COMBOBOX_PROPID_ITEMINDEX, 0));
end;

procedure ComboBoxUpdateLocalization(AComboBox: IAIMPUIComboBox; const SectionName: string);
var
  K: Integer;
begin
  if Assigned(AComboBox) then
   begin
     for K := 0 to AComboBox.GetItemCount-1 do
       AComboBox.SetItem(K, LangLoadStringEx(SectionName + '\i[' + IntToStr(K)
      + ']'));
   end;
end;

procedure SetComboBoxItemIndex(AComboBox: IAIMPUIComboBox; const Value: Integer);
begin
  PropListSetInt32(AComboBox, AIMPUI_COMBOBOX_PROPID_ITEMINDEX, Value);
end;

function GetComboBoxItemIndex(AComboBox: IAIMPUIComboBox): Integer;
begin
  Result := PropListGetInt32(AComboBox, AIMPUI_COMBOBOX_PROPID_ITEMINDEX);
end;

procedure CreateLabel(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  LabelName, LabelText: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out ALabel: IAIMPUILabel; AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(LabelName),
    EventsHandler, IAIMPUILabel, ALabel));
  CheckResult(ALabel.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(ALabel.SetValueAsObject(AIMPUI_LABEL_PROPID_TEXT,
    MakeString(LabelText)));
end;

procedure CreateButton(Owner: IAIMPUIForm; Parent: IAIMPUIWinControl;
  ButtonName, ButtonCaption: String; EventsHandler: IUnknown;
  const Alignment: TAIMPUIControlAlignment; out AButton: IAIMPUIButton;
  AServiceUI: IAIMPServiceUI = nil);
var
  ServiceUI: IAIMPServiceUI;
begin
  ServiceUI := AServiceUI;
  if not Assigned(ServiceUI) then
    CoreGetService(IAIMPServiceUI, ServiceUI);

  CheckResult(ServiceUI.CreateControl(Owner, Parent, MakeString(ButtonName),
    EventsHandler, IAIMPUIButton, AButton));
  CheckResult(AButton.SetPlacement(TAIMPUIControlPlacement.Create
    (Alignment, 0)));
  CheckResult(AButton.SetValueAsObject(AIMPUI_BUTTON_PROPID_CAPTION,
    MakeString(ButtonCaption)));
end;

procedure SetControlEnabled(APropertyList: IAIMPPropertyList; Enabled: Boolean);
begin
  PropListSetBool(APropertyList, AIMPUI_CONTROL_PROPID_ENABLED, Enabled);
end;

end.
