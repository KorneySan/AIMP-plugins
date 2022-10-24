unit PlaylistAutoStop_Impl;

interface

uses
  Windows, AIMPCustomPlugin, apiCore, apiOptions, apiObjects, apiMessages,
  apiActions, apiMenu, apiPlaylists, apiPlayer,
  PlaylistAutoStop_Defines,
  PlaylistAutoStop_OptionForm;

type

  { TAIMPHook }

  TAIMPHook = class(TInterfacedObject, IAIMPMessageHook)
  private
    FPlugin: TAIMPCustomPlugin;
    procedure CoreMessage(Message: DWORD; Param1: Integer; Param2: Pointer; var Result: HRESULT); stdcall;
  public
    destructor Destroy; override;
    property Plugin: TAIMPCustomPlugin read FPlugin write FPlugin default nil;
  end;

  { TAIMPPluginExtensionPlaylistManagerListener }

  TAIMPPluginExtensionPlaylistManagerListener = class(TInterfacedObject, IAIMPExtensionPlaylistManagerListener)
  private
    FPlugin: TAIMPCustomPlugin;
  protected
    // IAIMPExtensionPlaylistManagerListener
    procedure PlaylistActivated(Playlist: IAIMPPlaylist); stdcall;
    procedure PlaylistAdded(Playlist: IAIMPPlaylist); stdcall;
    procedure PlaylistRemoved(Playlist: IAIMPPlaylist); stdcall;
  public
    property Plugin: TAIMPCustomPlugin read FPlugin write FPlugin default nil;
  end;

  { TAIMPPluginOptionFrame }

  TAIMPPluginOptionFrame = class(TInterfacedObject, IAIMPOptionsDialogFrame)
  strict private
    FForm: TAIMPPluginOptionForm;

    procedure HandlerModified;
  protected
    {
    function GetSettings: TPluginSettings;
    procedure SetSettings(ASettings: TPluginSettings);
    }
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
    FHook: TAIMPHook;
    FPML: TAIMPPluginExtensionPlaylistManagerListener;
    FMenuItem: IAIMPMenuItem;
    NeedLocalization: Boolean;
    procedure GetVersionInfo;
    function GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
    function ServiceTest: Boolean;
    //
    procedure CreateMenuItem;
    procedure CheckMenuItem(const Value: Boolean);
    function GetPlaylist(const PlaylistType: TPlaylistType): IAIMPPlaylist;
    function GetPlaylistID(const Playlist: IAIMPPlaylist): string;
  protected
    function InfoGet(Index: Integer): PWideChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  public
    procedure ToggleStop;
    procedure SelectPlaylist(const Playlist: IAIMPPlaylist);
    procedure CheckPlaylist(const Playlist: IAIMPPlaylist);
  end;

  { TAIMPActionEventHandler }

  TAIMPActionEventHandler = class(TInterfacedObject, IAIMPActionEvent)
  private
    FPlugin: TAIMPPlugin;
  public
    constructor Create(const Plugin: TAIMPPlugin);
    destructor Destroy; override;
    procedure OnExecute(Data: IInterface); stdcall;
  end;

implementation

uses
  madExcept, Classes, SysUtils, Math,
  apiWrappers, apiPlugin;

{ TAIMPPlugin }

procedure TAIMPPlugin.SelectPlaylist(const Playlist: IAIMPPlaylist);
var
  Selected: IAIMPPlaylist;
  ID: string;
  IDidx: Integer;
begin
  if Playlist = nil then
    Selected := GetPlaylist(ptActive)
  else
    Selected := Playlist;
  if Selected <> nil then
  begin
    ID := GetPlaylistID(Selected);
    IDidx := mySettings.Playlists.IndexOf(ID);
    if IDidx < 0 then
      mySettings.Playlists.Add(ID) //select
    else
     begin
      UpdateSettings(mySettings, ID); //deselect
     end;
  end;
  CheckPlaylist(Selected);
  Selected := nil;
  ToggleStop;
end;

procedure TAIMPPlugin.CheckMenuItem(const Value: Boolean);
begin
  if Assigned(FMenuItem) then
  begin
    CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(Value)));
  end;
end;

procedure TAIMPPlugin.CheckPlaylist(const Playlist: IAIMPPlaylist);
var
  Active: IAIMPPlaylist;
  ID: string;
  IDidx: Integer;
begin
  if Playlist = nil then
    Active := GetPlaylist(ptActive)
  else
    Active := Playlist;
 //
  if (Active = nil) or (mySettings.Playlists.Count = 0) then
    CheckMenuItem(false)
  else
  begin
    ID := GetPlaylistID(Active);
    IDidx := mySettings.Playlists.IndexOf(ID);
    CheckMenuItem(IDidx >= 0);
  end;
end;

procedure TAIMPPlugin.CreateMenuItem;
var
  AAction: IAIMPAction;
  FrameName: WideString;
begin
  // Create Action
  CheckResult(CoreIntf.CreateObject(IID_IAIMPAction, AAction));
  // Setup it
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionSelectPlaylist)));
  if NeedLocalization then
  begin
    FrameName := LocalizedFrameName;
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(GetLocalization(idActionSelectPlaylist, sActionSelectPlaylist))));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(FrameName)));
  end;
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, TAIMPActionEventHandler.Create(Self)));
  // Register the action in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceActionManager, AAction);

  // Create menu item
  CheckResult(CoreIntf.CreateObject(IID_IAIMPMenuItem, FMenuItem));
  // Setup it
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, MakeString(idMenuSelectPlaylist)));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ACTION, AAction));
  if NeedLocalization then
    CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, MakeString(GetLocalization(idMenuSelectPlaylist, FrameName))));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, GetBuiltInMenu(AIMP_MENUID_PLAYER_PLAYLIST_MISCELLANEOUS)));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, 0));
  // Register the menu item in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuItem);

  //cleaning
  AAction := nil;
end;

procedure TAIMPPlugin.Finalize;
var
  AMDService: IAIMPServiceMessageDispatcher;
begin
  if Assigned(FHook) then
  begin
    if CoreGetService(IID_IAIMPServiceMessageDispatcher, AMDService) then
      AMDService.Unhook(FHook);
    AMDService := nil;
    FHook.Plugin := nil;
    FHook := nil;
  end;
  //Playlists listener
  if Assigned(FPML) then
  begin
    FPML.Plugin := nil;
    FPML := nil;
  end;
  //Options frame
  if Assigned(FFrame) then
   begin
    FFrame := nil;
   end;
  //
  SaveSettings(mySettings);
  FinalizeSettings;
  inherited;
end;

function TAIMPPlugin.GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
var
  AMenuService: IAIMPServiceMenuManager;
begin
  CheckResult(CoreIntf.QueryInterface(IAIMPServiceMenuManager, AMenuService));
  CheckResult(AMenuService.GetBuiltIn(ID, Result));
  AMenuService := nil;
end;

function TAIMPPlugin.GetPlaylist(const PlaylistType: TPlaylistType): IAIMPPlaylist;
var
  APMService: IAIMPServicePlaylistManager;
begin
  Result := nil;
  if Supports(CoreIntf, IAIMPServicePlaylistManager, APMService) then
  begin
    with APMService do
    begin
      case PlaylistType of
        ptActive:
          begin
            if not Succeeded(GetActivePlaylist(Result)) then
              Result := nil;
          end;
        ptPlaying:
          begin
            if not Succeeded(GetPlayingPlaylist(Result)) then
              Result := nil;
          end;
      end;
    end;
  end;
  APMService := nil;
end;

function TAIMPPlugin.GetPlaylistID(const Playlist: IAIMPPlaylist): string;
var
  plpl: IAIMPPropertyList;
  AIMPString: IAIMPString;
begin
  Result := '';
  if Supports(Playlist, IAIMPPropertyList, plpl) then
  begin
    CheckResult(plpl.GetValueAsObject(AIMP_PLAYLIST_PROPID_ID, IID_IAIMPString, AIMPString));
    Result := IAIMPStringToString(AIMPString);
    AIMPString := nil;
  end;
  plpl := nil;
end;

procedure TAIMPPlugin.GetVersionInfo;
var
  AVIService: IAIMPServiceVersionInfo;
  i: Integer;
begin
  NeedLocalization := True;
  if Supports(CoreIntf, IAIMPServiceVersionInfo, AVIService) then
  begin
    i := AVIService.GetBuildNumber;
    if i > 1683 then
      NeedLocalization := False;
    AVIService := nil;
  end;
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
    GetVersionInfo;
    //settings
    Core.GetPath(AIMP_CORE_PATH_PROFILE, AString);
    InitializeSettings(IAIMPStringToString(AString));
    AString := nil;
    LoadSettings(mySettings);
    //Option frame
    FFrame := TAIMPPluginOptionFrame.Create;
    Core.RegisterExtension(IID_IAIMPServiceOptionsDialog, FFrame);
    //FFrame.Settings := FSettings;
    //hook
    FHook := TAIMPHook.Create;
    FHook.Plugin := Self;
    if CoreGetService(IID_IAIMPServiceMessageDispatcher, AMDService) then
      AMDService.Hook(FHook);
    AMDService := nil;
    //playlists listener
    FPML := TAIMPPluginExtensionPlaylistManagerListener.Create;
    FPML.Plugin := Self;
    Core.RegisterExtension(IID_IAIMPServicePlaylistManager, FPML);
    //menu
    CreateMenuItem;
  end;
end;

function TAIMPPlugin.ServiceTest: Boolean;
var
  AMDService: IAIMPServiceMessageDispatcher;
  APMService: IAIMPServicePlaylistManager;
  AServiceOptions: IAIMPServiceOptionsDialog;
  AVIService: IAIMPServiceVersionInfo;
  APService: IAIMPServicePlayer;
begin
  Result := true;
  //Hook service
  Result := Result and CoreGetService(IID_IAIMPServiceMessageDispatcher, AMDService);
  AMDService := nil;
  //Playlist service
  Result := Result and CoreGetService(IAIMPServicePlaylistManager, APMService);
  APMService := nil;
  //Options service
  Result := Result and Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions);
  AServiceOptions := nil;
  //Version info service
  Result := Result and Supports(CoreIntf, IAIMPServiceVersionInfo, AVIService);
  AVIService := nil;
  //Player service
  Result := Result and Supports(CoreIntf, IAIMPServicePlayer, APService);
  APService := nil;
end;

procedure TAIMPPlugin.ToggleStop;
var
  APService: IAIMPServicePlayer;
  CurrentPlaylist, ItemPlaylist: IAIMPPlaylist;
  CurrentPlaylistItem: IAIMPPlaylistItem;
  ppl: IAIMPPropertyList;
  ID: string;
  Value: Integer;
  Result: HRESULT;
begin
  CurrentPlaylist := GetPlaylist(ptActive);
  if CurrentPlaylist <> nil then
  begin
    //get current playlist id
    ID := GetPlaylistID(CurrentPlaylist);
    if Supports(CoreIntf, IAIMPServicePlayer, APService) then
    begin
      //get playing item
      Result := APService.GetPlaylistItem(CurrentPlaylistItem);
      if Result = S_OK then
      begin
        CheckResult(CurrentPlaylistItem.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_PLAYLIST, IID_IAIMPPlaylist, ItemPlaylist));
        //check if we toggling the playlist what is playing
        if ItemPlaylist = CurrentPlaylist then
        begin
          CheckResult(APService.QueryInterface(IID_IAIMPPropertyList, ppl));
          CheckResult(ppl.SetValueAsInt32(AIMP_PLAYER_PROPID_ACTION_ON_END_OF_TRACK, IfThen(mySettings.Playlists.IndexOf(ID) >= 0, 1, 0)));
        end;
      end;
    end;
  end;
end;

{ TAIMPHook }

procedure TAIMPHook.CoreMessage(Message: DWORD; Param1: Integer; Param2: Pointer; var Result: HRESULT);
begin
  case Message of
    AIMP_MSG_EVENT_STREAM_START, AIMP_MSG_EVENT_STREAM_START_SUBTRACK:
      begin
        TAIMPPlugin(Plugin).ToggleStop;
      end;
  end;
end;

destructor TAIMPHook.Destroy;
begin
  FPlugin := nil;
  inherited;
end;

{ TAIMPActionEventHandler }

constructor TAIMPActionEventHandler.Create(const Plugin: TAIMPPlugin);
begin
  inherited Create;
  FPlugin := Plugin;
end;

destructor TAIMPActionEventHandler.Destroy;
begin
  FPlugin := nil;
  inherited;
end;

procedure TAIMPActionEventHandler.OnExecute(Data: IInterface);
begin
 //MessageBox(0, 'Action', myPluginName, MB_OK or MB_ICONWARNING); //debug
  FPlugin.SelectPlaylist(nil);
end;

{ TAIMPPluginExtensionPlaylistManagerListener }

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistActivated(Playlist: IAIMPPlaylist);
begin
  if Assigned(FPlugin) then
    TAIMPPlugin(FPlugin).CheckPlaylist(Playlist);
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistAdded(Playlist: IAIMPPlaylist);
begin
 //do nothing
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistRemoved(Playlist: IAIMPPlaylist);
begin
 //do nothing
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
    S := LangLoadStringEx(MakeSettingName(myPluginDLLName, optFrameName));
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
        //do nothing yet
       end;
    end;
end;

end.

