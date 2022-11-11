unit AutoPause_Impl;

interface

uses
  Windows, Messages,
  AIMPCustomPlugin, apiCore, apiOptions, apiObjects,
  apiMessages, apiMenu, apiPlaylists, apiPlayer, AutoPause_Defines,
  AutoPause_OptionForm;

type

  { TAIMPPluginOptionFrame }

  TAIMPPluginOptionFrame = class(TInterfacedObject, IAIMPOptionsDialogFrame)
  strict private
    FForm: TAIMPPluginOptionForm;

    procedure HandlerModified;
  protected
    // IAIMPOptionsDialogFrame
    function CreateFrame(ParentWnd: HWND): HWND; stdcall;
    procedure DestroyFrame; stdcall;
    function GetName(out S: IAIMPString): HRESULT; stdcall;
    procedure Notification(ID: Integer); stdcall;
  public
  end;

  { TAIMPPlugin }

  TAIMPPlugin = class(TAIMPCustomPlugin)
  private
    FFrame: TAIMPPluginOptionFrame;
    FMessageHWnd: HWND;
    procedure WndMethod(var Msg: TMessage);
    function ServiceTest: Boolean;
    //
    procedure PlayerPause;
    procedure PlayerResume;
    procedure PlayerStop;
    function PlayerState: Integer;
    procedure DoStopAction(const AAction: TSettingsActions);
    procedure DoResumeAction(const AAction: TSettingsActions);
  protected
    function InfoGet(Index: Integer): PWideChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  public
  end;

procedure RestartTimer(DoStart: Boolean);

implementation

uses
  Classes, SysUtils, Math, MMSystem,
  apiWrappers, apiPlugin, apiWrappers_my;

var
  myPlugin: TAIMPPlugin = nil;
  FAPITimer: Integer;

procedure TimeCallBack(uTimerID, uMessage: UINT; dwUser, dw1,
  dw2: DWORD);
var
  IsRunning: BOOL;
begin
  if not Assigned(myPlugin) then Exit;

  SystemParametersInfo(SPI_GETSCREENSAVERRUNNING, 0, @IsRunning, 0);
  if IsRunning then
   begin
    if myPlugin.PlayerState = AIMP_PLAYER_STATE_PLAYING then
     begin
      myPlugin.DoStopAction(mySettings.PCScreenSaver);
     end;
   end
  else
   begin
    if myPlugin.PlayerState = AIMP_PLAYER_STATE_PAUSE then
     begin
      myPlugin.DoResumeAction(mySettings.PCScreenSaver);
     end;
   end;
end;

procedure StartTimer;
begin
  FAPITimer := timeSetEvent(1000, 100, @TimeCallBack, 100, TIME_CALLBACK_FUNCTION or TIME_PERIODIC);
end;

procedure StopTimer;
begin
  timeKillEvent(FAPITimer);
end;

procedure RestartTimer(DoStart: Boolean);
begin
  StopTimer;
  if DoStart then
    StartTimer;
end;

{ TAIMPPlugin }

procedure TAIMPPlugin.DoResumeAction(const AAction: TSettingsActions);
begin
  with AAction do
  begin
    if (PlayerAction = apPause) and DoResume then
      PlayerResume;
  end;
end;

procedure TAIMPPlugin.DoStopAction(const AAction: TSettingsActions);
begin
  case AAction.PlayerAction of
    apPause:
      PlayerPause;
    apStop:
      PlayerStop;
  end;
end;

procedure TAIMPPlugin.Finalize;
var
  AMDService: IAIMPServiceMessageDispatcher;
begin
  StopTimer;
  myPlugin := nil;
  WTSUnRegisterSessionNotification(FMessageHWnd);
  DeallocateHWnd(FMessageHWnd);
  // Options frame
  if Assigned(FFrame) then
  begin
    FFrame := nil;
  end;
  //
  SaveSettings(mySettings);
  FinalizeSettings;
  inherited;
end;

function TAIMPPlugin.InfoGet(Index: Integer): PWideChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      begin
        if myPluginName = '' then
          Result := nil
        else
          Result := myPluginName + ' v' + myPluginVersion;
      end;
    AIMP_PLUGIN_INFO_AUTHOR:
      begin
        if myPluginAuthor = '' then
          Result := nil
        else
          Result := myPluginAuthor;
      end;
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      begin
        if myPluginShortDescription = '' then
          Result := nil
        else
          Result := myPluginShortDescription;
      end;
    AIMP_PLUGIN_INFO_FULL_DESCRIPTION:
      begin
        if myPluginFullDescription = '' then
          Result := nil
        else
          Result := myPluginFullDescription;
      end
  else
    Result := nil;
  end;
end;

function TAIMPPlugin.InfoGetCategories: Cardinal;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAIMPPlugin.Initialize(Core: IAIMPCore): HRESULT;
var
  AMDService: IAIMPServiceMessageDispatcher;
  AString: IAIMPString;
begin
  Result := inherited Initialize(Core);
  if Succeeded(Result) then
  begin
    if not ServiceTest then
    begin
      Result := E_UNEXPECTED;
      Exit;
    end;
    // settings
    Core.GetPath(AIMP_CORE_PATH_PROFILE, AString);
    InitializeSettings(ServiceGetConfig);
    AString := nil;
    LoadSettings(mySettings);
    // Option frame
    FFrame := TAIMPPluginOptionFrame.Create;
    Core.RegisterExtension(IID_IAIMPServiceOptionsDialog, FFrame);
    // windows message hook
    FMessageHWnd := AllocateHWnd(WndMethod);
    SetWindowPos(FMessageHWnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
    WTSRegisterSessionNotification(FMessageHWnd, NOTIFY_FOR_THIS_SESSION);
    RegisterPowerSettingNotification(FMessageHWnd, GUID_SESSION_USER_PRESENCE, DEVICE_NOTIFY_WINDOW_HANDLE);
    // timer for screensaver capture
    myPlugin := Self;
    if mySettings.PCScreenSaver.PlayerAction <> apNothing then
      StartTimer;
  end;
end;

procedure TAIMPPlugin.PlayerPause;
var
  APService: IAIMPServicePlayer;
begin
  if Supports(CoreIntf, IAIMPServicePlayer, APService) then
  begin
    APService.Pause;
  end;
  APService := nil;
end;

procedure TAIMPPlugin.PlayerResume;
var
  APService: IAIMPServicePlayer;
begin
  if Supports(CoreIntf, IAIMPServicePlayer, APService) then
  begin
    if (APService.GetState = AIMP_PLAYER_STATE_PAUSE) then
      APService.Resume;
  end;
  APService := nil;
end;

function TAIMPPlugin.PlayerState: Integer;
var
  APService: IAIMPServicePlayer;
begin
  if Supports(CoreIntf, IAIMPServicePlayer, APService) then
    Result := APService.GetState
  else
    Result := AIMP_PLAYER_STATE_UNDEFINED;
  APService := nil;
end;

procedure TAIMPPlugin.PlayerStop;
var
  APService: IAIMPServicePlayer;
begin
  if Supports(CoreIntf, IAIMPServicePlayer, APService) then
  begin
    APService.Stop;
  end;
  APService := nil;
end;

function TAIMPPlugin.ServiceTest: Boolean;
var
  AServiceOptions: IAIMPServiceOptionsDialog;
  APService: IAIMPServicePlayer;
begin
  Result := True;
  // Options service
  Result := Result and Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions);
  AServiceOptions := nil;
  // Player service
  Result := Result and Supports(CoreIntf, IAIMPServicePlayer, APService);
  APService := nil;
end;

procedure TAIMPPlugin.WndMethod(var Msg: TMessage);
var
  PBS: POWERBROADCAST_SETTING;
  myWParam: WPARAM;
begin
  case Msg.Msg of
    WM_WTSSESSION_CHANGE:
      begin
        case Msg.WParam of
          WTS_SESSION_LOCK:
            DoStopAction(mySettings.PCLock);
          WTS_SESSION_UNLOCK:
            DoResumeAction(mySettings.PCLock);
        end;
      end;

    WM_POWERBROADCAST:
      begin
        case Msg.WParam of
          PBT_POWERSETTINGCHANGE:
            begin
              PBS := POWERBROADCAST_SETTING(Pointer(Msg.LParam)^);
              if GUID_CONSOLE_DISPLAY_STATE = PBS.PowerSetting then
              begin
                // for GUID_CONSOLE_DISPLAY_STATE
                case PBS.Data[0] of
                  0:
                    DoStopAction(mySettings.PCIdle);
                  1:
                    DoResumeAction(mySettings.PCIdle);
                end;
              end;
              if (GUID_GLOBAL_USER_PRESENCE = PBS.PowerSetting)
                 or (GUID_SESSION_USER_PRESENCE = PBS.PowerSetting) then
              begin
                // for GUID_GLOBAL_USER_PRESENCE or GUID_SESSION_USER_PRESENCE
                case PBS.Data[0] of
                  2:
                    DoStopAction(mySettings.PCIdle);
                  0:
                    DoResumeAction(mySettings.PCIdle);
                end;
              end;
            end;
        end;
      end;
  end;
  Msg.Result := DefWindowProc(FMessageHWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

{ TAIMPPluginOptionFrame }

function TAIMPPluginOptionFrame.CreateFrame(ParentWnd: HWND): HWND;
begin
  FForm := TAIMPPluginOptionForm.Create(ParentWnd);
  FForm.OnModified := HandlerModified;
  //
  Result := FForm.GetHandle;
end;

procedure TAIMPPluginOptionFrame.DestroyFrame;
begin
  FreeAndNil(FForm);
end;

function TAIMPPluginOptionFrame.GetName(out S: IAIMPString): HRESULT;
begin
  try
    S := LangLoadStringEx(MakeSettingName(myPluginDLLName, myPluginDLLName));
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

procedure TAIMPPluginOptionFrame.HandlerModified;
var
  AServiceOptions: IAIMPServiceOptionsDialog;
begin
  if Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions) then
    AServiceOptions.FrameModified(Self);
end;

procedure TAIMPPluginOptionFrame.Notification(ID: Integer);
begin
  if FForm <> nil then
    case ID of
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOCALIZATION:
        FForm.ApplyLocalization;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOAD:
        FForm.ConfigLoad;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_SAVE:
        FForm.ConfigSave;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_CAN_SAVE:
        begin
          // do nothing yet
        end;
    end;
end;

end.

