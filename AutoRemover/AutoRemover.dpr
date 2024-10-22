library AutoRemover;

uses
  Windows,
  Variants,
  Classes,
  SysUtils,
  IniFiles,
  // API
  apiActions,
  apiGUI,
  apiCore,
  apiMenu,
  apiMessages,
  apiObjects,
  apiPlayer,
  apiPlaylists,
  apiPlugin,
  apiWrappers;

const
  myPluginName = 'Auto remover';
  myPluginVersion = '1.0';
  myPluginAuthor = 'Korney San';
  myPluginShortDescription = 'Removes "played" track from playlist.';
  myPluginFullDescription = 'Track is considered "played" when player goes to the next track.';
  myPluginDLLName = 'AutoRemover';
  //
  myPluginInfoName = myPluginName + ' v.' + myPluginVersion;
  myIniFileName = myPluginDLLName + '.ini';
  sectionPlaylists = 'Playlists';
  idActionSelectPlaylist = 'aimp.' + myPluginDLLName + '.action.selectplaylist';
  sActionSelectPlaylist = 'Remove "played" track from this playlist';
  idMenuSelectPlaylist = 'aimp.' + myPluginDLLName + '.menuitem.selectplaylist';
  sFormatSettingValueName = '%s\%s';
  //
  mpPlayerStateStopped = 0;
  mpPlayerStateStoppedText = 'Stopped';
  mpPlayerStatePaused = 1;
  mpPlayerStatePausedText = 'Paused';
  mpPlayerStatePlaying = 2;
  mpPlayerStatePlayingText = 'Playing';

type
  TPlaylistType = (ptActive, ptPlaying);

  TAutoRemoverPlugin = class;

  { TAIMPPluginExtensionPlaylistManagerListener }

  TAIMPPluginExtensionPlaylistManagerListener = class(TInterfacedObject, IAIMPExtensionPlaylistManagerListener)
  strict private
    FPlugin: TAutoRemoverPlugin;
  protected
    // IAIMPExtensionPlaylistManagerListener
    procedure PlaylistActivated(Playlist: IAIMPPlaylist); stdcall;
    procedure PlaylistAdded(Playlist: IAIMPPlaylist); stdcall;
    procedure PlaylistRemoved(Playlist: IAIMPPlaylist); stdcall;
  public
    property Plugin: TAutoRemoverPlugin read FPlugin write FPlugin default nil;
  end;

  { TAutoRemoverPlugin }

  TAutoRemoverPlugin = class(TInterfacedObject, IAIMPMessageHook, IAIMPPlugin)
  strict private
    FPlayingItem: IAIMPPlaylistItem;
    //FPlayingItemIndex: Integer;
    FDuration, FPosition: Double;
    //
    FMenuItem: IAIMPMenuItem;
    FUserProfilePath: string;
    FPlaylists: TStrings;
    FIniFile: TMemIniFile;
    FPML: TAIMPPluginExtensionPlaylistManagerListener;
    procedure GetTrackData;
    procedure FlushTrackData;
    function GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
    function GetPlaylist(const PlaylistType: TPlaylistType): IAIMPPlaylist;
    function GetPlaylistID(const Playlist: IAIMPPlaylist): string;
    procedure DeleteFromPlaylist(const PlaylistItem: IAIMPPlaylistItem);
    function GetPlaylistOfPlaylistItem(const PlaylistItem: IAIMPPlaylistItem): IAIMPPlaylist;
    function GetPlaylistIndexOfPlaylistItem(const PlaylistItem: IAIMPPlaylistItem): Integer;
  protected
    FCore: IAIMPCore;
    // IAIMPMessageHook
    procedure CoreMessage(Message: Cardinal; Param1: Integer; Param2: Pointer; var Result: HRESULT); stdcall;
    // IAIMPPlugin
    function InfoGet(Index: Integer): PChar; stdcall;
    function InfoGetCategories: LongWord; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; stdcall;
    procedure Finalize; virtual; stdcall;
    procedure SystemNotification(NotifyID: Integer; Data: IUnknown); virtual; stdcall;
    //Implementation
    procedure CreateMenuItem;
    procedure CheckMenuItem(const Value: Boolean);
    procedure SelectPlaylist(const Playlist: IAIMPPlaylist);
    procedure CheckPlaylist(const Playlist: IAIMPPlaylist);
    procedure RemovePlaylist(const Playlist: IAIMPPlaylist);
  end;

  { TAIMPActionEventHandler }

  TAIMPActionEventHandler = class(TInterfacedObject, IAIMPActionEvent)
  private
    FPlugin: TAutoRemoverPlugin;
  public
    constructor Create(const Plugin: TAutoRemoverPlugin);
    destructor Destroy; override;
    procedure OnExecute(Data: IInterface); stdcall;
  end;

  { TAutoRemoverPlugin }

procedure TAutoRemoverPlugin.CheckMenuItem(const Value: Boolean);
begin
  if Assigned(FMenuItem) then
  begin
    CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(Value)));
  end;
end;

procedure TAutoRemoverPlugin.CheckPlaylist(const Playlist: IAIMPPlaylist);
var
  Active: IAIMPPlaylist;
  ID: string;
  IDidx: Integer;
begin
  // Acquire given or active playlist
  if Playlist = nil then
    Active := GetPlaylist(ptActive)
  else
    Active := Playlist;
  //
  if (Active = nil) or (FPlaylists.Count = 0) then
    // None found or no playlists checked
    CheckMenuItem(false)
  else
  begin
    // Find playlist by ID and check if found
    ID := GetPlaylistID(Active);
    IDidx := FPlaylists.IndexOf(ID);
    CheckMenuItem(IDidx >= 0);
  end;
end;

procedure TAutoRemoverPlugin.CoreMessage(Message: Cardinal; Param1: Integer; Param2: Pointer; var Result: HRESULT);
var
  LService: IAIMPServicePlayer;
begin
  case Message of
    AIMP_MSG_CMD_NEXT:
      begin
        // Delete track from playlist
        if FPlayingItem <> nil then
        begin
          DeleteFromPlaylist(FPlayingItem);
          FlushTrackData;
        end;
      end;

    AIMP_MSG_CMD_STOP:
      begin
        FlushTrackData;
      end;

    AIMP_MSG_EVENT_STREAM_START, AIMP_MSG_EVENT_STREAM_START_SUBTRACK:
      begin
        GetTrackData;
      end;

    AIMP_MSG_EVENT_STREAM_END:
      begin
        // Delete played track from playlist
        if (FDuration - FPosition) <= 1.0 then
         begin
          DeleteFromPlaylist(FPlayingItem);
          FlushTrackData;
         end;
      end;

    AIMP_MSG_EVENT_PLAYER_UPDATE_POSITION_HR:
      begin
        if FCore.QueryInterface(IAIMPServicePlayer, LService) = S_OK then
         begin
          CheckResult(LService.GetPosition(FPosition));
         end
      end;

  end;
end;

procedure TAutoRemoverPlugin.CreateMenuItem;
var
  AAction: IAIMPAction;
begin
  AAction := nil;
  // Create Action
  CheckResult(FCore.CreateObject(IID_IAIMPAction, AAction));
  // Setup it
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionSelectPlaylist)));
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(sActionSelectPlaylist)));
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(myPluginName)));
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, TAIMPActionEventHandler.Create(Self)));
  // Register the action in manager
  FCore.RegisterExtension(IID_IAIMPServiceActionManager, AAction);
  // Create menu item
  CheckResult(FCore.CreateObject(IID_IAIMPMenuItem, FMenuItem));
  // Setup it
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, MakeString(idMenuSelectPlaylist)));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ACTION, AAction));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, MakeString(sActionSelectPlaylist)));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, GetBuiltInMenu(AIMP_MENUID_PLAYER_PLAYLIST_MISCELLANEOUS)));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, 0));
  // Register the menu item in manager
  FCore.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuItem);
  // Cleaning
  AAction := nil;
end;

procedure TAutoRemoverPlugin.DeleteFromPlaylist(const PlaylistItem: IAIMPPlaylistItem);
var
  Playlist: IAIMPPlaylist;
  PlaylistID: string;
begin
  if PlaylistItem <> nil then
  begin
    // Get playlist of track
    Playlist := GetPlaylistOfPlaylistItem(PlaylistItem);
    if Playlist <> nil then
    begin
      // Get playlist's ID and delete track if playlist is in list
      PlaylistID := GetPlaylistID(Playlist);
      if FPlaylists.IndexOf(PlaylistID) >= 0 then
      begin
        CheckResult(Playlist.Delete(PlaylistItem));
      end;
    end;
    Playlist := nil;
  end;
end;

function TAutoRemoverPlugin.GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
var
  AMenuService: IAIMPServiceMenuManager;
begin
  CheckResult(CoreIntf.QueryInterface(IAIMPServiceMenuManager, AMenuService));
  CheckResult(AMenuService.GetBuiltIn(ID, Result));
  AMenuService := nil;
end;

function TAutoRemoverPlugin.GetPlaylist(const PlaylistType: TPlaylistType): IAIMPPlaylist;
var
  APMService: IAIMPServicePlaylistManager;
begin
  Result := nil;
  if Supports(FCore, IAIMPServicePlaylistManager, APMService) then
  begin
    with APMService do
    begin
      case PlaylistType of
        ptActive:
          begin
            if Failed(GetActivePlaylist(Result)) then
              Result := nil;
          end;
        ptPlaying:
          begin
            if Failed(GetPlayingPlaylist(Result)) then
              Result := nil;
          end;
      end;
    end;
  end;
  APMService := nil;
end;

function TAutoRemoverPlugin.GetPlaylistID(const Playlist: IAIMPPlaylist): string;
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

function TAutoRemoverPlugin.GetPlaylistIndexOfPlaylistItem(
  const PlaylistItem: IAIMPPlaylistItem): Integer;
begin
  Result := -1;
  CheckResult(PlaylistItem.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, Result));
end;

function TAutoRemoverPlugin.GetPlaylistOfPlaylistItem(const PlaylistItem: IAIMPPlaylistItem): IAIMPPlaylist;
begin
  Result := nil;
  CheckResult(PlaylistItem.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_PLAYLIST, IAIMPPlaylist, Result));
end;

procedure TAutoRemoverPlugin.GetTrackData;
var
  LService: IAIMPServicePlayer;
begin
  if FCore.QueryInterface(IAIMPServicePlayer, LService) = S_OK then
   begin
    if Succeeded(LService.GetPlaylistItem(FPlayingItem)) then
      CheckResult(LService.GetDuration(FDuration))
    else
     begin
      FPlayingItem := nil;
      FDuration := 0;
     end;
   end
  else
   begin
    FPlayingItem := nil;
    FDuration := 0;
   end;
  FPosition := 0;
  LService := nil;
end;

function TAutoRemoverPlugin.InfoGet(Index: Integer): PChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
      Result := myPluginInfoName;
    AIMP_PLUGIN_INFO_AUTHOR:
      Result := myPluginAuthor;
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
      Result := myPluginShortDescription;
    AIMP_PLUGIN_INFO_FULL_DESCRIPTION:
      Result := myPluginFullDescription;
  else
    Result := nil;
  end;
end;

function TAutoRemoverPlugin.InfoGetCategories: LongWord;
begin
  Result := AIMP_PLUGIN_CATEGORY_ADDONS;
end;

function TAutoRemoverPlugin.Initialize(Core: IAIMPCore): HRESULT;
var
  LDispatcher: IAIMPServiceMessageDispatcher;
  LManager: IAIMPServicePlaylistManager;
  AIMPString: IAIMPString;
begin
  if Core.QueryInterface(IAIMPServicePlaylistManager, LManager) = S_OK then
  begin
    FCore := Core;
    // Hook setup
    if Core.QueryInterface(IAIMPServiceMessageDispatcher, LDispatcher) = S_OK then
      LDispatcher.Hook(Self);
    // Get user profile path for ini file
    CheckResult(FCore.GetPath(AIMP_CORE_PATH_PROFILE, AIMPString));
    FUserProfilePath := IncludeTrailingPathDelimiter(IAIMPStringToString(AIMPString));
    AIMPString := nil;
    // Load affected playlists list from ini file
    FPlaylists := TStringList.Create;
    FIniFile := TMemIniFile.Create(FUserProfilePath + myIniFileName);
    with FIniFile do
    begin
      if SectionExists(sectionPlaylists) then
        ReadSection(sectionPlaylists, FPlaylists);
    end;
    // Init wrappers
    TAIMPAPIWrappers.Initialize(FCore);
    // Playlists listener setup
    FPML := TAIMPPluginExtensionPlaylistManagerListener.Create;
    FPML.Plugin := Self;
    Core.RegisterExtension(IID_IAIMPServicePlaylistManager, FPML);
    // Menu setup
    CreateMenuItem;
    //
    Result := S_OK;
  end
  else
    Result := E_FAIL;
end;

procedure TAutoRemoverPlugin.RemovePlaylist(const Playlist: IAIMPPlaylist);
var
  ID: string;
  IDidx: Integer;
begin
  if Playlist <> nil then
  begin
    // Get playlist's ID and delete playlist from list and ini file if is in
    ID := GetPlaylistID(Playlist);
    IDidx := FPlaylists.IndexOf(ID);
    if IDidx >= 0 then
    begin
      FIniFile.DeleteKey(sectionPlaylists, ID);
      FIniFile.UpdateFile;
      FPlaylists.Delete(IDidx);
    end;
  end;
end;

procedure TAutoRemoverPlugin.Finalize;
var
  LDispatcher: IAIMPServiceMessageDispatcher;
  i: Integer;
begin
  // Save affected playlists list to ini file
  with FIniFile do
  begin
    EraseSection(sectionPlaylists);
    for i := 0 to FPlaylists.Count - 1 do
      WriteString(sectionPlaylists, FPlaylists[i], '');
  end;
  FreeAndNil(FiniFile);
  FreeAndNil(FPlaylists);
  // Clear the hook
  if FCore <> nil then
  begin
    if FCore.QueryInterface(IAIMPServiceMessageDispatcher, LDispatcher) = S_OK then
      LDispatcher.Unhook(Self);
  end;
  // Fin wrappers
  TAIMPAPIWrappers.Finalize;
  // Clear the core link
  FCore := nil;
end;

procedure TAutoRemoverPlugin.FlushTrackData;
begin
  FPlayingItem := nil;
  FDuration := 0;
  FPosition := 0;
end;

procedure TAutoRemoverPlugin.SelectPlaylist(const Playlist: IAIMPPlaylist);
var
  Selected: IAIMPPlaylist;
  ID: string;
  IDidx: Integer;
begin
  // Acquire given or active playlist
  if Playlist = nil then
    Selected := GetPlaylist(ptActive)
  else
    Selected := Playlist;
  //
  if Selected <> nil then
  begin
    // Get playlist's ID and toggle playlist's presence in list and ini file
    ID := GetPlaylistID(Selected);
    if ID<>'' then
     begin
      IDidx := FPlaylists.IndexOf(ID);
      if IDidx < 0 then
       begin
        //select
        FPlaylists.Add(ID);
        FIniFile.WriteString(sectionPlaylists, ID, '');
        //
        GetTrackData;
       end
      else
       begin
        //deselect
        FIniFile.DeleteKey(sectionPlaylists, ID);
        FPlaylists.Delete(IDidx);
       end;
      FIniFile.UpdateFile;
      CheckPlaylist(Selected);
     end;
  end;
  Selected := nil;
end;

procedure TAutoRemoverPlugin.SystemNotification(NotifyID: Integer; Data: IInterface);
begin
 // Do nothing
end;

  { AIMPPluginGetHeader }

function AIMPPluginGetHeader(out Header: IAIMPPlugin): HRESULT; stdcall;
begin
  try
    Header := TAutoRemoverPlugin.Create;
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

{ TAIMPActionEventHandler }

constructor TAIMPActionEventHandler.Create(const Plugin: TAutoRemoverPlugin);
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
  // Toggle active playlist processing
  FPlugin.SelectPlaylist(nil);
end;

exports
  AIMPPluginGetHeader;

{ TAIMPPluginExtensionPlaylistManagerListener }

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistActivated(Playlist: IAIMPPlaylist);
begin
  if Assigned(FPlugin) then
    // Update menu item "check" mark for playlist
    FPlugin.CheckPlaylist(Playlist);
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistAdded(Playlist: IAIMPPlaylist);
begin
 // Do nothing
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistRemoved(Playlist: IAIMPPlaylist);
begin
  FPlugin.RemovePlaylist(Playlist);
end;

end.

