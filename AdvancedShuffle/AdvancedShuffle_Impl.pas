unit AdvancedShuffle_Impl;

{.$DEFINE LOG}

interface

uses
 Windows, Classes,
 AIMPCustomPlugin, apiCore, apiOptions, apiObjects, apiMessages, apiActions,
 apiMenu, apiPlaylists, apiPlayer,
 AdvancedShuffle_SetupFrame,
 AdvancedShuffle_Defines,
 AdvancedShuffle_Intf;

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

  { TAIMPPluginOptionFrame }

  TAIMPPluginOptionFrame = class(TInterfacedObject, IAIMPOptionsDialogFrame)
  strict private
    FFrame: TAIMPOptionFrame;
    FPlugin: TAIMPCustomPlugin;
    procedure HandlerModified(Sender: TObject);
  protected
    // IAIMPOptionsDialogFrame
    function CreateFrame(ParentWnd: HWND): HWND; stdcall;
    procedure DestroyFrame; stdcall;
    function GetName(out S: IAIMPString): HRESULT; stdcall;
    procedure Notification(ID: Integer); stdcall;
  public
    property Frame: TAIMPOptionFrame read FFrame default nil;
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

  { TAIMPPlugin }

  TAIMPPlugin = class(TAIMPCustomPlugin)
  private
    FFrame: TAIMPPluginOptionFrame;
    FHook: TAIMPHook;
    FPlaylistsList: IAIMPObjectList;
    FGroupsList: IAIMPObjectList;
    FTracksList: IAIMPObjectList;
    NeedLocalization: Boolean;
    FMenuItem: IAIMPMenuItem;
    FPML: TAIMPPluginExtensionPlaylistManagerListener;
    {$IFDEF LOG}
    FLog: TStrings;
    {$ENDIF}
    FPluginsPath: WideString;
    FPlaylistsData: TPlaylistInfoArray;
    procedure SettingsChanged(const OldSettings, NewSettings: TSettings);
    procedure GetVersionInfo;
    function GetPluginsPath: WideString;
    function GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
    procedure CreateMenuItem;
    procedure CheckMenuItem(const Value: Boolean);
    //
    function ServiceTest: Boolean;
    procedure UpdateFrameHeader;
    function GetCurrentPlaylist: IAIMPPlaylist;
    function GetCurrentGroup: IAIMPPlaylistGroup;
    function GetCurrentPlaylistItem: IAIMPPlaylistItem;
    function GetRandomPlaylist(const ICurrent: IAIMPPlaylist): IAIMPPlaylist;
    function GetRandomGroup(const ICurrentPlaylist: IAIMPPlaylist; const ICurrentGroup: IAIMPPlaylistGroup): IAIMPPlaylistGroup;
    function GetRandomTrack(const ICurrentPlaylist: IAIMPPlaylist; const ICurrentGroup: IAIMPPlaylistGroup; const ICurrentTrack: IAIMPPlaylistItem): IAIMPPlaylistItem;
    procedure ClearPlaylistsList;
    procedure ClearGroupsList;
    procedure ClearTracksList;
    //
    function IsPlayable(const Track: IAIMPPlaylistItem): Boolean;
    function IsGroupping(const Playlist: IAIMPPlaylist): Boolean;
    function IsRandomizable(const Playlist: IAIMPPlaylist): Integer; overload;
    function IsRandomizable(const Group: IAIMPPlaylistGroup): Integer; overload;
    function GetPlayableTrackList(const Playlist: IAIMPPlaylist): IAIMPObjectList; overload;
    function GetPlayableTrackList(const Group: IAIMPPlaylistGroup): IAIMPObjectList; overload;
    function GetPlayableGroupList(const Playlist: IAIMPPlaylist): IAIMPObjectList;
    function GetPlayablePlaylistList: IAIMPObjectList;
    function TrackIndexInGroup(const Track: IAIMPPlaylistItem; const Group: IAIMPPlaylistGroup): Integer;
    function Shuffle(Current: IAIMPPlaylistItem = nil): IAIMPPlaylistItem;
    {$IFDEF LOG}
    function GetItemName(const Item: IInterface): WideString;
    {$ENDIF}
    procedure UpdatePlaylistList(const Playlist: IAIMPPlaylist; Add: Boolean = false);
    procedure GetPlaylistsList;
    procedure AddNewPlaylist(const Playlist: IAIMPPlaylist);
    procedure RemovePlaylist(const Playlist: IAIMPPlaylist);
    procedure UpdatePlaylistsInfo;
    procedure SetplaylistInfoState(const NewState: TPlaylistInfoStateOnly);
    function ExcludePlaylistID(const AID: WideString; Add: Boolean = false): Integer;
  protected
    function InfoGet(Index: Integer): PWideChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  public
    property Frame: TAIMPPluginOptionFrame read FFrame default nil;
    //
    procedure SetShuffle(const NewShuffle: LongBool);
    procedure Switch;
  end;

  { TAIMPExtensionPlaybackQueue }

  TAIMPExtensionPlaybackQueue = class(TInterfacedObject, IAIMPExtensionPlaybackQueue)
  private
    FPlugin: TAIMPPlugin;
    FCurrent: IUnknown;
    FResult: IAIMPPlaylistItem;
    procedure GetResult(const inCurrent: IUnknown; outResult: IAIMPPlaybackQueueItem);
  public
    constructor Create(const Plugin: TAIMPPlugin);
    destructor Destroy; override;
    function GetNext(Current: IUnknown; Flags: DWORD; QueueItem: IAIMPPlaybackQueueItem): LongBool; stdcall;
    function GetPrev(Current: IUnknown; Flags: DWORD; QueueItem: IAIMPPlaybackQueueItem): LongBool; stdcall;
    procedure OnSelect(Item: IAIMPPlaylistItem; QueueItem: IAIMPPlaybackQueueItem); stdcall;
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

  { TAdvancedShuffleCustomService }

  TAdvancedShuffleCustomService = class(TInterfacedObject,
  IAdvancedShuffleCustomService
  )
  private
    FPlugin: TAIMPPlugin;
  protected
  //IAdvancedShuffleCustomService
    function AddPlaylistID(PlaylistID: IAIMPString; out Index: Integer): HRESULT; stdcall;
    function RemovePlaylistID(PlaylistID: IAIMPString; out Index: Integer): HRESULT; stdcall;
  public
    constructor Create(const Plugin: TAIMPPlugin);
    destructor Destroy; override;
    property Plugin: TAIMPPlugin read FPlugin write FPlugin default nil;
  end;

implementation

uses
 SysUtils,
 madExcept,
 apiWrappers,
 apiPlugin;

{ TAIMPPluginOptionFrame }

function TAIMPPluginOptionFrame.CreateFrame(ParentWnd: HWND): HWND;
var
  R: Trect;
begin
  FFrame := TAIMPOptionFrame.CreateParented(ParentWnd);
  FFrame.OnModified := HandlerModified;
  GetWindowRect(ParentWnd, R);
  OffsetRect(R, -R.Left, -R.Top);
  FFrame.BoundsRect := R;
  FFrame.Visible := True;
  //
  FFrame.Plugin:=Self.Plugin;
  FFrame.UpdateFrameCaption;
  //
  Result := FFrame.Handle;
end;

procedure TAIMPPluginOptionFrame.DestroyFrame;
begin
  FreeAndNil(FFrame);
end;

function TAIMPPluginOptionFrame.GetName(out S: IAIMPString): HRESULT;
begin
  try
    S := MakeString(LocalizedFrameName);
    Result := S_OK;
  except
    Result := E_UNEXPECTED;
  end;
end;

procedure TAIMPPluginOptionFrame.HandlerModified(Sender: TObject);
 var
  AServiceOptions: IAIMPServiceOptionsDialog;
begin
  if Supports(CoreIntf, IAIMPServiceOptionsDialog, AServiceOptions) then
    AServiceOptions.FrameModified(Self);
  AServiceOptions:=nil;
end;

procedure TAIMPPluginOptionFrame.Notification(ID: Integer);
begin
  if FFrame <> nil then
    case ID of
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOCALIZATION:
        TAIMPOptionFrame(FFrame).ApplyLocalization;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_LOAD:
        TAIMPOptionFrame(FFrame).ConfigLoad;
      AIMP_SERVICE_OPTIONSDIALOG_NOTIFICATION_SAVE:
        TAIMPOptionFrame(FFrame).ConfigSave;
    end;
end;

{ TAIMPPlugin }

procedure TAIMPPlugin.AddNewPlaylist(const Playlist: IAIMPPlaylist);
 var
  APList: IAIMPPropertyList;
  AIMPString: IAIMPString;
  AID, AName: WideString;
  i: Integer;
begin
  if Assigned(Playlist) and Supports(Playlist, IID_IAIMPPropertyList, APList) then
   begin
    CheckResult(APList.GetValueAsObject(AIMP_PLAYLIST_PROPID_ID, IID_IAIMPString, AIMPString));
    AID:=IAIMPStringToString(AIMPString);
    CheckResult(APList.GetValueAsObject(AIMP_PLAYLIST_PROPID_NAME, IID_IAIMPString, AIMPString));
    AName:=IAIMPStringToString(AIMPString);
    i:=GetIndexPlaylistInfoByID(FPlaylistsData, AID);
    if i<0 then
      i:=AddPlaylistInfo(FPlaylistsData, AID, AName)
    else
      FPlaylistsData[i].Name:=AName;
    LoadPlaylistInfoState(Self, myPluginDLLName, FPlaylistsData[i]);
    //for debug only
    // if Length(FPlaylistsData)>1 then
    //   FPlaylistsData[1].State:=soExternal;
   end;
  AIMPString:=nil;
  APList:=nil;
end;

procedure TAIMPPlugin.CheckMenuItem(const Value: Boolean);
begin
 if Assigned(FMenuItem) then
  begin
   CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, Integer(Value)));
  end;
end;

procedure TAIMPPlugin.ClearGroupsList;
begin
  if Assigned(FGroupsList) then
   begin
    CheckResult(FGroupsList.Clear);
    FGroupsList:=nil;
   end;
end;

procedure TAIMPPlugin.ClearPlaylistsList;
begin
  if Assigned(FPlaylistsList) then
   begin
    CheckResult(FPlaylistsList.Clear);
    FPlaylistsList:=nil;
   end;
end;

procedure TAIMPPlugin.ClearTracksList;
begin
  if Assigned(FTracksList) then
   begin
    CheckResult(FTracksList.Clear);
    FTracksList:=nil;
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
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionSwitch)));
  if NeedLocalization then
   begin
    FrameName:=LocalizedFrameName;
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(GetLocalization(idActionSwitch, sActionSwitch))));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(FrameName)));
   end;
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, TAIMPActionEventHandler.Create(Self)));
  // Register the action in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceActionManager, AAction);

  // Create menu item
  CheckResult(CoreIntf.CreateObject(IID_IAIMPMenuItem, FMenuItem));
  // Setup it
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ID, MakeString(idMenuSwitch)));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_ACTION, AAction));
  if NeedLocalization then
    CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_NAME, MakeString(GetLocalization(idMenuSwitch, FrameName))));
  CheckResult(FMenuItem.SetValueAsObject(AIMP_MENUITEM_PROPID_PARENT, GetBuiltInMenu(AIMP_MENUID_PLAYER_PLAYLIST_MISCELLANEOUS)));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_STYLE, AIMP_MENUITEM_STYLE_CHECKBOX));
  CheckResult(FMenuItem.SetValueAsInt32(AIMP_MENUITEM_PROPID_CHECKED, 0));
  // Register the menu item in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceMenuManager, FMenuItem);

  //cleaning
  AAction:=nil;
end;

function TAIMPPlugin.ExcludePlaylistID(const AID: WideString; Add: Boolean): Integer;
begin
 Result:=GetIndexPlaylistInfoByID(FPlaylistsData, AID);
 if Result>=0 then
  begin
   with FPlaylistsData[Result] do
    begin
     if Add then
       State:=soExternal
     else
      begin
       if State=soExternal then
         State:=soNormal;
      end;
    end;
   UpdatePlaylistsInfo;
  end;
end;

procedure TAIMPPlugin.Finalize;
 var
  AMDService: IAIMPServiceMessageDispatcher;
begin
  //MessageBox(0, 'CTITF Finalize 0', myPluginName, MB_OK); //debug
  //Log
  {$IFDEF LOG}
  FLog.SaveToFile(FPluginsPath+myPluginLogName);
  FreeAndNil(FLog);
  {$ENDIF}
  //Lists
  ClearTracksList;
  ClearGroupsList;
  ClearPlaylistsList;
  //Hook
  if Assigned(FHook) then
   begin
    if CoreGetService(IID_IAIMPServiceMessageDispatcher, AMDService) then
      AMDService.Unhook(FHook);
    AMDService:=nil;
    FHook.Plugin:=nil;
    FHook:=nil;
   end;
  //Options frame
  if Assigned(FFrame) then
   begin
    FFrame.Plugin:=nil;
    FFrame:=nil;
   end;
  //Playlists listener
  if Assigned(FPML) then
   begin
    FPML.Plugin:=nil;
    FPML:=nil;
   end;
  ClearPlaylistInfoArray(FPlaylistsData);
  //
  FinalizeSettings;
  inherited;
end;

function TAIMPPlugin.GetBuiltInMenu(ID: Integer): IAIMPMenuItem;
var
  AMenuService: IAIMPServiceMenuManager;
begin
  CheckResult(CoreIntf.QueryInterface(IAIMPServiceMenuManager, AMenuService));
  CheckResult(AMenuService.GetBuiltIn(ID, Result));
  AMenuService:=nil;
end;

function TAIMPPlugin.GetCurrentGroup: IAIMPPlaylistGroup;
 var
  pli: IAIMPPlaylistItem;
begin
  Result:=nil;
  pli:=GetCurrentPlaylistItem;
  if Assigned(pli) then
    CheckResult(pli.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_GROUP, IAIMPPlaylistGroup, Result));
  pli:=nil;
end;

function TAIMPPlugin.GetCurrentPlaylist: IAIMPPlaylist;
 var
  APMService: IAIMPServicePlaylistManager;
  pc: Integer;
begin
 Result:=nil;
 if Supports(CoreIntf, IAIMPServicePlaylistManager, APMService) then
  begin
   with APMService do
    begin
     //get current playlist
     if not Succeeded(GetPlayablePlaylist(Result)) then
      begin
       pc:=GetLoadedPlaylistCount;
       //select playlist
       if pc=0 then
         Result:=nil
       else
         CheckResult(GetLoadedPlaylist(0, Result));
      end;
    end;
  end;
 APMService:=nil;
end;

function TAIMPPlugin.GetCurrentPlaylistItem: IAIMPPlaylistItem;
 var
  APService: IAIMPServicePlayer;
  pl: IAIMPPlaylist;
  plpl: IAIMPPropertyList;
  pii: Integer;
begin
 Result:=nil;
 if Supports(CoreIntf, IAIMPServicePlayer, APService) then
   APService.GetPlaylistItem(Result);
 if not Assigned(Result) then
  begin
   pl:=GetCurrentPlaylist;
   if Assigned(pl) then
    begin
     if Supports(pl, IAIMPPropertyList, plpl) then
      begin
       CheckResult(plpl.GetValueAsInt32(AIMP_PLAYLIST_PROPID_PLAYINGINDEX, pii));
       if pii>=0 then
         CheckResult(pl.GetItem(pii, IAIMPPlaylistItem, Result));
      end;
     plpl:=nil;
    end;
   pl:=nil;
  end;
 APService:=nil;
end;

{$IFDEF LOG}
function TAIMPPlugin.GetItemName(const Item: IInterface): WideString;
 var
  pl: IAIMPPlaylist;
  gr: IAIMPPlaylistGroup;
  tr: IAIMPPlaylistItem;
  prl: IAIMPPropertyList;
  AIMPString: IAIMPString;
begin
 Result:='';
 if Supports(Item, IID_IAIMPPlaylist, pl) then
  begin
   if Supports(pl, IID_IAIMPPropertyList, prl) then
    begin
     CheckResult(prl.GetValueAsObject(AIMP_PLAYLIST_PROPID_NAME, IID_IAIMPString, AIMPString));
     Result:=IAIMPStringToString(AIMPString);
     AIMPString:=nil;
     prl:=nil;
    end;
   pl:=nil;
  end
 else
 if Supports(Item, IID_IAIMPPlaylistGroup, gr) then
  begin
   CheckResult(gr.GetValueAsObject(AIMP_PLAYLISTGROUP_PROPID_NAME, IID_IAIMPString, AIMPString));
   Result:=IAIMPStringToString(AIMPString);
   AIMPString:=nil;
   gr:=nil;
  end
 else
 if Supports(Item, IID_IAIMPPlaylistItem, tr) then
  begin
   CheckResult(tr.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_DISPLAYTEXT, IID_IAIMPString, AIMPString));
   Result:=IAIMPStringToString(AIMPString);
   AIMPString:=nil;
   tr:=nil;
  end;
end;
{$ENDIF}

function TAIMPPlugin.GetPlayableTrackList(
  const Playlist: IAIMPPlaylist): IAIMPObjectList;
 var
  i, tc, ci, pi: Integer;
  pli: IAIMPPlaylistItem;
  pl: IAIMPPropertyList;
begin
 if Assigned(Playlist) then
  begin
   CoreIntf.CreateObject(IID_IAIMPObjectList, Result);
   tc:=Playlist.GetItemCount;
   CheckResult(Playlist.QueryInterface(IID_IAIMPPropertyList, pl));
   CheckResult(pl.GetValueAsInt32(AIMP_PLAYLIST_PROPID_PLAYINGINDEX, ci));
   for i := 0 to tc-1 do
    begin
     CheckResult(Playlist.GetItem(i, IID_IAIMPPlaylistItem, pli));
     if IsPlayable(pli) then
      begin
       CheckResult(pli.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, pi));
       if (pi<>ci) or (tc=1) then
         CheckResult(Result.Add(pli));
      end;
    end;
   pl:=nil;
   pli:=nil;
  end
 else
   Result:=nil;
end;

function TAIMPPlugin.GetPlayableGroupList(
  const Playlist: IAIMPPlaylist): IAIMPObjectList;
 var
  i, gc: Integer;
  plg: IAIMPPlaylistGroup;
begin
 if Assigned(Playlist) and IsGroupping(Playlist) then
  begin
   CoreIntf.CreateObject(IID_IAIMPObjectList, Result);
   gc:=Playlist.GetGroupCount;
   for i := 0 to gc-1 do
    begin
     CheckResult(Playlist.GetGroup(i, IID_IAIMPPlaylistGroup, plg));
     if IsRandomizable(plg)>irNone then
       CheckResult(Result.Add(plg));
    end;
   plg:=nil;
  end
 else
   Result:=nil;
end;

function TAIMPPlugin.GetPlayablePlaylistList: IAIMPObjectList;
 var
  APMService: IAIMPServicePlaylistManager;
  i, plc: Integer;
  pl: IAIMPPlaylist;
begin
 if Supports(CoreIntf, IAIMPServicePlaylistManager, APMService) then
   with APMService do
    begin
     CoreIntf.CreateObject(IID_IAIMPObjectList, Result);
     plc:=GetLoadedPlaylistCount;
     for i := 0 to plc-1 do
      begin
       CheckResult(GetLoadedPlaylist(i, pl));
       if IsRandomizable(pl)>irNone then
        begin
         if IsPlaylistAllowed(FPlaylistsData, pl) then
           CheckResult(Result.Add(pl));
        end;
      end;
     pl:=nil;
    end
 else
   Result:=nil;
 APMService:=nil;
end;

function TAIMPPlugin.GetPlayableTrackList(
  const Group: IAIMPPlaylistGroup): IAIMPObjectList;
 var
  i, tc: Integer;
  pli: IAIMPPlaylistItem;
begin
 if Assigned(Group) then
  begin
   CoreIntf.CreateObject(IID_IAIMPObjectList, Result);
   tc:=Group.GetItemCount;
   for i := 0 to tc-1 do
    begin
     CheckResult(Group.GetItem(i, IID_IAIMPPlaylistItem, pli));
     if IsPlayable(pli) then
       CheckResult(Result.Add(pli));
    end;
   pli:=nil;
  end
 else
   Result:=nil;
end;

procedure TAIMPPlugin.GetPlaylistsList;
 var
  APMService: IAIMPServicePlaylistManager;
  i, plc: Integer;
  Playlist: IAIMPPlaylist;
begin
 ClearPlaylistInfoArray(FPlaylistsData);
 if Supports(CoreIntf, IAIMPServicePlaylistManager, APMService) then
   with APMService do
    begin
     plc:=GetLoadedPlaylistCount;
     for i := 0 to plc-1 do
      begin
       CheckResult(GetLoadedPlaylist(i, Playlist));
       AddNewPlaylist(Playlist);
      end;
     Playlist:=nil;
    end;
 APMService:=nil;
end;

function TAIMPPlugin.GetPluginsPath: WideString;
 var
  AIMPString: IAIMPString;
begin
 CheckResult(CoreIntf.GetPath(AIMP_CORE_PATH_PLUGINS, AIMPString));
 Result:=IAIMPStringToString(AIMPString);
 AIMPString:=nil;
end;

function TAIMPPlugin.GetRandomGroup(const ICurrentPlaylist: IAIMPPlaylist;
  const ICurrentGroup: IAIMPPlaylistGroup): IAIMPPlaylistGroup;
 var
  cg: IAIMPPlaylistGroup;
  cp: IAIMPPlaylist;
  lst: IAIMPObjectList;
  lc, lgi, cgi, gi: Integer;
begin
 if Assigned(ICurrentGroup) then
   cg:=ICurrentGroup
 else
  begin
   if mySettings.GroupRandom>rtNone then
     cg:=GetCurrentGroup //can be nil
   else
     cg:=nil;
  end;
 if Assigned(ICurrentPlaylist) then
   cp:=ICurrentPlaylist
 else
   cp:=GetCurrentPlaylist; //should be always accessible but can be nil
 //MessageBox(0, 'GR 0', myPluginName, MB_OK); //debug
 case mySettings.GroupRandom of
  rtList, rtOrder:
   begin
    if not Assigned(FGroupsList) or (FGroupsList.GetCount=0) then
     begin
      FGroupsList:=nil;
      if Assigned(cp) then
        FGroupsList:=GetPlayableGroupList(cp) //can be nil
      else
        FGroupsList:=nil;
     end;
    if Assigned(FGroupsList) then
     begin
      lc:=FGroupsList.GetCount;
      //MessageBox(0, PWideChar('LG C = '+IntToStr(lc)), myPluginName, MB_OK); //debug
      if lc>0 then
       begin
        if mySettings.GroupRandom=rtList then
          lgi:=Random(lc)
        else
          lgi:=0; //Order mode
        CheckResult(FGroupsList.GetObject(lgi, IID_IAIMPPlaylistGroup, Result));
        FGroupsList.Delete(lgi);
        //
        {$IFDEF LOG}
        FLog.Add(Format(sLogFormat, [sGroup, GetItemName(Result), lgi, lc]));
        {$ENDIF}
       end
      else
        Result:=nil;
     end
    else
      Result:=nil;
   end;
  rtSimple:
   begin
    if Assigned(cp) then
     begin
      lst:=GetPlayableGroupList(cp); //can be nil
      if Assigned(lst) then
       begin
        lc:=lst.GetCount;
        case lc of
         0: Result:=nil;
         1: CheckResult(lst.GetObject(0, IID_IAIMPPlaylistGroup, Result));
         else
          begin
           if Assigned(cg) then
             CheckResult(cg.GetValueAsInt32(AIMP_PLAYLISTGROUP_PROPID_INDEX, cgi))
           else
             cgi:=-1;
           repeat
            lgi:=Random(lc);
            CheckResult(lst.GetObject(lgi, IID_IAIMPPlaylistGroup, Result));
            if Assigned(Result) then
              CheckResult(Result.GetValueAsInt32(AIMP_PLAYLISTGROUP_PROPID_INDEX, gi))
            else
              gi:=-2;
           until gi<>cgi;
           //
           {$IFDEF LOG}
           FLog.Add(Format(sLogFormat, [sGroup, GetItemName(Result), lgi, lc]));
           {$ENDIF}
          end;
        end;
        lst:=nil;
       end
      else
        Result:=nil;
     end
    else
      Result:=nil;
   end;
  rtNone:
   begin
    Result:=nil;
   end;
  else
    Result:=cg;
 end;
 //MessageBox(0, 'GR 1', myPluginName, MB_OK); //debug
 cp:=nil;
end;

function TAIMPPlugin.GetRandomPlaylist(
  const ICurrent: IAIMPPlaylist): IAIMPPlaylist;
 var
  lst: IAIMPObjectList;
  cpl: IAIMPPlaylist;
  plc, plr: Integer;

begin
 if Assigned(ICurrent) then
   cpl:=ICurrent
 else
   cpl:=GetCurrentPlaylist; //may be nil
   //MessageBox(0, 'PL 0', myPluginName, MB_OK); //debug
   case mySettings.PlaylistRandom of
    rtList, rtOrder:
     begin
      if not Assigned(FPlaylistsList) or (FPlaylistsList.GetCount=0) then
       begin
        FPlaylistsList:=nil;
        FPlaylistsList:=GetPlayablePlaylistList; //may be nil
       end;
      if Assigned(FPlaylistsList) then
       begin
        plc:=FPlaylistsList.GetCount;
        //MessageBox(0, PWideChar('LP C = '+IntToStr(plc)), myPluginName, MB_OK); //debug
        repeat
         if plc>0 then
          begin
           if mySettings.PlaylistRandom=rtList then
             plr:=Random(plc)
           else
             plr:=0; //Order mode
           CheckResult(FPlaylistsList.GetObject(plr, IID_IAIMPPlaylist, Result));
           CheckResult(FPlaylistsList.Delete(plr));
           //
           if not IsPlaylistAllowed(FPlaylistsData, Result) then
             Result:=cpl;
           //
           {$IFDEF LOG}
           FLog.Add(Format(sLogFormat, [sPlaylist, GetItemName(Result), plr, plc]));
           {$ENDIF}
           plc:=FPlaylistsList.GetCount;
          end
         else
           Result:=cpl;
        until (plc=0) or (Result<>cpl);
       end
      else
        Result:=cpl;
     end;
    rtSimple:
     begin
      lst:=GetPlayablePlaylistList;
      if Assigned(lst) then
       begin
        plc:=lst.GetCount;
        case plc of
         0: Result:=cpl;
         1: CheckResult(lst.GetObject(0, IID_IAIMPPlaylist, Result));
         else
          begin
           repeat
            plr:=Random(plc);
            CheckResult(lst.GetObject(plr, IID_IAIMPPlaylist, Result));
            CheckResult(lst.Delete(plr));
            if not IsPlaylistAllowed(FPlaylistsData, Result) then
              Result:=cpl;
            plc:=lst.GetCount;
           until (plc=0) or (Result<>cpl);
           //
           {$IFDEF LOG}
           FLog.Add(Format(sLogFormat, [sPlaylist, GetItemName(Result), plr, plc]));
           {$ENDIF}
          end;
        end;
       end
      else
        Result:=cpl;
      lst:=nil;
     end;
    else
      Result:=cpl;
   end;
   //MessageBox(0, 'PL 1', myPluginName, MB_OK); //debug
end;

function TAIMPPlugin.GetRandomTrack(const ICurrentPlaylist: IAIMPPlaylist;
  const ICurrentGroup: IAIMPPlaylistGroup;
  const ICurrentTrack: IAIMPPlaylistItem): IAIMPPlaylistItem;
 var
   ct: IAIMPPlaylistItem;
   cg, tg: IAIMPPlaylistGroup;
   cp, tp: IAIMPPlaylist;
   lst: IAIMPObjectList;
   lc, lti, cti, ti: Integer;
begin
 //MessageBox(0, 'CT', myPluginName, MB_OK); //debug
 if Assigned(ICurrentTrack) then
   ct:=ICurrentTrack
 else
  begin
   if mySettings.TrackRandom>rtNone then
     ct:=GetCurrentPlaylistItem //should not, but can be nil
   else
     ct:=nil;
  end;
 //MessageBox(0, 'CG', myPluginName, MB_OK); //debug
 if Assigned(ICurrentGroup) then
   cg:=ICurrentGroup
 else
  begin
   if mySettings.GroupRandom>rtNone then
     cg:=GetCurrentGroup //can be nil
   else
     cg:=nil;
  end;
 //MessageBox(0, 'CP', myPluginName, MB_OK); //debug
 if Assigned(ICurrentPlaylist) then
   cp:=ICurrentPlaylist
 else
   cp:=GetCurrentPlaylist; //should be always accessible but can be nil
 //MessageBox(0, 'RT 0', myPluginName, MB_OK); //debug
 Result:=nil;
 case mySettings.TrackRandom of
  rtList, rtOrder:
   begin
    if not Assigned(FTracksList) or (FTracksList.GetCount=0) then
     begin
      FTracksList:=nil;
      if Assigned(cg) then
        FTracksList:=GetPlayableTrackList(cg)  //can be nil
      else
        FTracksList:=GetPlayableTrackList(cp); //can be nil
     end;
    if Assigned(FTracksList) then
     begin
      lc:=FTracksList.GetCount;
      //MessageBox(0, PWideChar('LT C = '+IntToStr(lc)), myPluginName, MB_OK); //debug
      if lc>0 then
       begin
        if mySettings.TrackRandom=rtList then
          lti:=Random(lc)
        else
          lti:=0; //Order mode
        CheckResult(FTracksList.GetObject(lti, IID_IAIMPPlaylistItem, Result));
        FTracksList.Delete(lti);
        //
        {$IFDEF LOG}
        FLog.Add(Format(sLogFormat, [sTrack, GetItemName(Result), lti, lc]));
        {$ENDIF}
       end
      else
        Result:=nil;
     end
    else
      Result:=nil;
   end;
  rtSimple:
   begin
    if (mySettings.GroupRandom>rtNone) and Assigned(cg) then
     begin
      //random track in group
      lst:=GetPlayableTrackList(cg);
      if Assigned(lst) then
       begin
        lc:=lst.GetCount;
        case lc of
         0: Result:=nil;
         1: CheckResult(lst.GetObject(0, IID_IAIMPPlaylistItem, Result));
         else
          begin
           if Assigned(ct) then
            begin
             cti:=TrackIndexInGroup(ct, cg);
             if cti>=0 then
              begin
               CheckResult(Result.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_GROUP, IID_IAIMPPlaylistGroup, tg));
               if Assigned(tg) then
                begin
                 if tg<>cg then
                   cti:=-1;
                end
               else
                 cti:=-1;
              end;
             tg:=nil;
            end
           else
             cti:=-1;
           repeat
            lti:=Random(lc);
            CheckResult(lst.GetObject(lti, IID_IAIMPPlaylistItem, Result));
            if Assigned(Result) then
              CheckResult(Result.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, ti))
            else
              ti:=-2;
           until ti<>cti;
           //
           {$IFDEF LOG}
           FLog.Add(Format(sLogFormat, [sTrack, GetItemName(Result), lti, lc]));
           {$ENDIF}
          end;
        end;
        lst:=nil;
       end
      else
        Result:=nil;
     end
    else
     begin
      //random track in playlist
      //MessageBox(0, 'RT PL', myPluginName, MB_OK); //debug
      if Assigned(cp) then
       begin
        lst:=GetPlayableTrackList(cp);
        //MessageBox(0, 'RT PL 0', myPluginName, MB_OK); //debug
        if Assigned(lst) then
         begin
          lc:=lst.GetCount;
          //MessageBox(0, PWideChar('RT PL = '+IntToStr(lc)), myPluginName, MB_OK); //debug
          case lc of
           0: Result:=nil;
           1: CheckResult(lst.GetObject(0, IID_IAIMPPlaylistItem, Result));
           else
            begin
             //MessageBox(0, 'RT PL CT', myPluginName, MB_OK); //debug
             if Assigned(ct) then
              begin
               //MessageBox(0, 'RT PL CT 0', myPluginName, MB_OK); //debug
               CheckResult(ct.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, cti));
               //MessageBox(0, PWideChar('RT PL CTi = '+IntToStr(cti)), myPluginName, MB_OK); //debug
               CheckResult(ct.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_PLAYLIST, IID_IAIMPPlaylist, tp));
               //MessageBox(0, 'RT PL CT TP', myPluginName, MB_OK); //debug
               if Assigned(tp) then
                begin
                 if tp<>cp then
                   cti:=-1;
                end
               else
                 cti:=-1;
               tp:=nil;
              end
             else
               cti:=-1;
             //MessageBox(0, PWideChar('RT PL CTI = '+IntToStr(cti)), myPluginName, MB_OK); //debug
             repeat
              lti:=Random(lc);
              CheckResult(lst.GetObject(lti, IID_IAIMPPlaylistItem, Result));
              if Assigned(Result) then
                CheckResult(Result.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, ti))
              else
                ti:=-2;
             until ti<>cti;
             //
             {$IFDEF LOG}
             FLog.Add(Format(sLogFormat, [sTrack, GetItemName(Result), lti, lc]));
             {$ENDIF}
            end;
          end;
          lst:=nil;
         end
        else
          Result:=nil;
       end
      else
        Result:=nil;
     end;
   end;
  rtNone:
   begin
    if Assigned(cg) then
     begin
      //first track in group
      lst:=GetPlayableTrackList(cg);
      if Assigned(lst) then
       begin
        lc:=lst.GetCount;
        case lc of
         0: Result:=nil;
         else CheckResult(lst.GetObject(0, IID_IAIMPPlaylistItem, Result));
        end;
       end
      else
        Result:=nil;
      lst:=nil;
     end
    else
     begin
      if Assigned(cp) then
       begin
        //first track in playlist
        lst:=GetPlayableTrackList(cp);
        if Assigned(lst) then
         begin
          lc:=lst.GetCount;
          case lc of
           0: Result:=nil;
           else CheckResult(lst.GetObject(0, IID_IAIMPPlaylistItem, Result));
          end;
         end
        else
          Result:=nil;
        lst:=nil;
       end
      else
        Result:=nil;
     end;
   end;
  else
    Result:=ct;
 end;
 ct:=nil;
 cg:=nil;
 cp:=nil;
 //MessageBox(0, 'RT 1', myPluginName, MB_OK); //debug
end;

procedure TAIMPPlugin.GetVersionInfo;
 var
  AVIService: IAIMPServiceVersionInfo;
  i: Integer;
begin
 NeedLocalization:=True;
 if Supports(CoreIntf, IAIMPServiceVersionInfo, AVIService) then
  begin
   i:=AVIService.GetBuildNumber;
   if i>1683 then
     NeedLocalization:=False;
   AVIService:=nil;
  end;
end;

function TAIMPPlugin.InfoGet(Index: Integer): PWideChar;
begin
  case Index of
    AIMP_PLUGIN_INFO_NAME:
     begin
      if myPluginName='' then
        Result := nil
      else
        Result := myPluginName;
     end;
    AIMP_PLUGIN_INFO_AUTHOR:
     begin
      if myPluginAuthor='' then
        Result := nil
      else
        Result := myPluginAuthor;
     end;
    AIMP_PLUGIN_INFO_SHORT_DESCRIPTION:
     begin
      if myPluginShortDescription='' then
        Result := nil
      else
        Result := myPluginShortDescription;
     end;
    AIMP_PLUGIN_INFO_FULL_DESCRIPTION:
     begin
      if myPluginFullDescription='' then
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
begin
  Result := inherited Initialize(Core);
  if Succeeded(Result) then
   begin
    //MessageBox(0, 'Init Begin', myPluginName, MB_OK); //debug
    if not ServiceTest then
     begin
      Result:=E_UNEXPECTED;
      Exit;
     end;
    //MessageBox(0, 'Init 1', myPluginName, MB_OK); //debug
    GetVersionInfo;
    Randomize;
    //settings
    LoadSettings(Self, myPluginDLLName, mySettings);
    OnSettingsChange:=SettingsChanged;
    //MessageBox(0, 'Init 2', myPluginName, MB_OK); //debug
    //options frame
    FFrame:=TAIMPPluginOptionFrame.Create;
    FFrame.Plugin:=Self;
    Core.RegisterExtension(IID_IAIMPServiceOptionsDialog, FFrame);
    //MessageBox(0, 'Init 3', myPluginName, MB_OK); //debug
    //hook
    FHook:=TAIMPHook.Create;
    FHook.Plugin:=Self;

    if CoreGetService(IID_IAIMPServiceMessageDispatcher, AMDService) then
      AMDService.Hook(FHook);

    AMDService:=nil;
    //MessageBox(0, 'Init 4', myPluginName, MB_OK); //debug
    //queue extension
    Core.RegisterExtension(IID_IAIMPServicePlaybackQueue, TAIMPExtensionPlaybackQueue.Create(Self));
    //menu
    CreateMenuItem;
    //
    SettingsChanged(mySettings, mySettings);
    //MessageBox(0, 'Init 5', myPluginName, MB_OK); //debug
    //activate
    MessageDispatcherGetPropValue(AIMP_MSG_PROPERTY_SHUFFLE, @isShuffle);
    //MessageBox(0, 'Init 6', myPluginName, MB_OK); //debug
    UpdateFrameHeader;
    //MessageBox(0, 'Init 7', myPluginName, MB_OK); //debug
    FPlaylistsList:=nil;
    FGroupsList:=nil;
    FTracksList:=nil;
    //Log
    FPluginsPath:=IncludeTrailingPathDelimiter(GetPluginsPath);
    {$IFDEF LOG}
    FLog:=TStringList.Create;
    if FileExists(FPluginsPath+myPluginLogName) then
      FLog.LoadFromFile(FPluginsPath+myPluginLogName);
    {$ENDIF}
    //prepare playlists data
    SetLength(FPlaylistsData, 0);
    //GetPlaylistsList; //no need?
    //UpdatePlaylistsInfo; //no need?
    OnNeedPlaylistsData:=UpdatePlaylistsInfo;
    OnPlaylistInfoStateChange:=SetPlaylistInfoState;
    //playlists listener
    FPML:=TAIMPPluginExtensionPlaylistManagerListener.Create;
    FPML.Plugin:=Self;
    Core.RegisterExtension(IID_IAIMPServicePlaylistManager, FPML);
    // Register the custom service
    Core.RegisterService(TAdvancedShuffleCustomService.Create(Self));
    //MessageBox(0, 'Init End', myPluginName, MB_OK); //debug
   end;
end;

function TAIMPPlugin.IsRandomizable(const Playlist: IAIMPPlaylist): Integer;
 var
  i, tc, c: Integer;
  pli: IAIMPPlaylistItem;
begin
 Result:=irNone;
 c:=0;
 if Assigned(Playlist) then
  begin
   tc:=Playlist.GetItemCount;
   for i := 0 to tc-1 do
    begin
     CheckResult(Playlist.GetItem(i, IID_IAIMPPlaylistItem, pli));
     if IsPlayable(pli) then
      begin
       Inc(c);
       if c>1 then
        begin
         Result:=irMany;
         Break;
        end;
      end;
    end;
   if c=1 then
     Result:=irOne;
  end;
 pli:=nil;
end;

function TAIMPPlugin.IsGroupping(const Playlist: IAIMPPlaylist): Boolean;
 var
  APList: IAIMPPropertyList;
  v: Integer;
begin
 if Assigned(Playlist) and Supports(Playlist, IID_IAIMPPropertyList, APList) then
  begin
   APList.GetValueAsInt32(AIMP_PLAYLIST_PROPID_GROUPPING, v);
   Result:=v>0;
   APList:=nil;
  end
 else
   Result:=false;
end;

function TAIMPPlugin.IsPlayable(const Track: IAIMPPlaylistItem): Boolean;
 var
  v: Integer;
begin
 if Assigned(Track) then
  begin
   Track.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_PLAYINGSWITCH, v);
   Result:=v>0;
  end
 else
   Result:=false;
end;

function TAIMPPlugin.IsRandomizable(const Group: IAIMPPlaylistGroup): Integer;
 var
  i, tc, c: Integer;
  pli: IAIMPPlaylistItem;
begin
 Result:=irNone;
 c:=0;
 if Assigned(Group) then
  begin
   tc:=Group.GetItemCount;
   for i := 0 to tc-1 do
    begin
     CheckResult(Group.GetItem(i, IID_IAIMPPlaylistItem, pli));
     if IsPlayable(pli) then
      begin
       Inc(c);
       if c>1 then
        begin
         Result:=irMany;
         Break;
        end;
      end;
    end;
   if c=1 then
     Result:=irOne;
  end;
 pli:=nil;
end;

procedure TAIMPPlugin.RemovePlaylist(const Playlist: IAIMPPlaylist);
 var
  AID: WideString;
  Index: Integer;
begin
  if Assigned(Playlist) then
   begin
    AID:=GetPlaylistID(Playlist);
    Index:=GetIndexPlaylistInfoByID(FPlaylistsData, AID);
    if Index>=0 then
     begin
      //delete saved state
      FPlaylistsData[Index].State:=soNormal;
      SavePlaylistInfoState(Self, myPluginDLLName, FPlaylistsData[Index]);
      //delete itself
      DeletePlaylistInfo(FPlaylistsData, Index);
     end;
   end;
end;

function TAIMPPlugin.ServiceTest: Boolean;
 var
  AFrame: TAIMPPluginOptionFrame;
  AMDService: IAIMPServiceMessageDispatcher;
  APQService: IAIMPServicePlaybackQueue;
  APMService: IAIMPServicePlaylistManager;
  AMenuService: IAIMPServiceMenuManager;
  AVIService: IAIMPServiceVersionInfo;
begin
 Result:=True;
 //Options service
 Result:=Result and Supports(CoreIntf, IAIMPServiceOptionsDialog, AFrame);
 AFrame:=nil;
 //Message dispatcher service
 Result:=Result and Supports(CoreIntf, IAIMPServiceMessageDispatcher, AMDService);
 AMDService:=nil;
 //Playback queue
 Result:=Result and Supports(CoreIntf, IAIMPServicePlaybackQueue, APQService);
 APQService:=nil;
 //Playlist manager service
 Result:=Result and Supports(CoreIntf, IAIMPServicePlaylistManager, APMService);
 APMService:=nil;
 //Menu service
 Result:=Result and Supports(CoreIntf, IAIMPServiceMenuManager, AMenuService);
 AMenuService:=nil;
 //Version info service
 Result:=Result and Supports(CoreIntf, IAIMPServiceVersionInfo, AVIService);
 AVIService:=nil;
end;

procedure TAIMPPlugin.SetplaylistInfoState(
  const NewState: TPlaylistInfoStateOnly);
begin
 with NewState do
  begin
   if Index<=High(FPlaylistsData) then
    begin
     FPlaylistsData[Index].State:=NewState.State;
    end;
  end;
end;

procedure TAIMPPlugin.SetShuffle(const NewShuffle: LongBool);
begin
 isShuffle:=NewShuffle;
 UpdateFrameHeader;
end;

procedure TAIMPPlugin.SettingsChanged(const OldSettings,
  NewSettings: TSettings);
begin
 if NewSettings.TrackRandom<rtList then
   ClearTracksList;
 if NewSettings.GroupRandom<rtList then
   ClearGroupsList;
 if NewSettings.PlaylistRandom<rtList then
   ClearPlaylistsList;
 //menu
 CheckMenuItem(NewSettings.Enabled);
 //playlist data
 if Assigned(FFrame) then
   if Assigned(FFrame.Frame) then
     CopyPlaylistInfoArray(FFrame.Frame.PlaylistInfo, FPlaylistsData, ciByID);
 //
 Randomize;
end;

function TAIMPPlugin.Shuffle(Current: IAIMPPlaylistItem = nil): IAIMPPlaylistItem;
 var
  pl: IAIMPPlaylist;
  gr: IAIMPPlaylistGroup;
begin
 {$IFDEF LOG}
 FLog.Add('- New shuffle -');
 {$ENDIF}
 with mySettings do
  begin
   if PlaylistRandom>rtNone then
    begin
     //any playlist
     pl:=nil;
     if GroupRandom in [rtList, rtOrder] then
      begin
       //group list
       gr:=nil;
       if TrackRandom in [rtList, rtOrder] then
        begin
         //track list
         if not Assigned(FTracksList) or (FTracksList.GetCount=0) then
          begin
           //track list end - can change group
           if not Assigned(FGroupsList) or (FGroupsList.GetCount=0) then
            begin
             //group list end - can change playlist
             pl:=GetRandomPlaylist(GetCurrentPlaylist);
            end
           else
            begin
             pl:=GetCurrentPlaylist;
            end;
           gr:=GetRandomGroup(pl, GetCurrentGroup);
          end;
        end
       else
        begin
         //track simple/none
         if not Assigned(FGroupsList) or (FGroupsList.GetCount=0) then
          begin
           //group list end - can change playlist
           pl:=GetRandomPlaylist(GetCurrentPlaylist);
          end
         else
          begin
           pl:=GetCurrentPlaylist;
          end;
         gr:=GetRandomGroup(pl, GetCurrentGroup);
        end;
       Result:=GetRandomTrack(pl, gr, Current);
       gr:=nil;
       pl:=nil;
      end
     else
      begin
       //group simple/none - any playlist change
       gr:=nil;
       if TrackRandom in [rtList, rtOrder] then
        begin
         //track list
         pl:=GetCurrentPlaylist;
         if not Assigned(FTracksList) or (FTracksList.GetCount=0) then
          begin
           //track list end - can change playlist and group
           pl:=GetRandomPlaylist(GetCurrentPlaylist);
           if GroupRandom>rtNone then
             gr:=GetRandomGroup(pl, GetCurrentGroup);
          end;
        end
       else
        begin
         //track simple/none - any playlist change
         pl:=GetRandomPlaylist(GetCurrentPlaylist);
         if GroupRandom>rtNone then
           gr:=GetRandomGroup(pl, GetCurrentGroup);
        end;
       Result:=GetRandomTrack(pl, gr, Current);
       gr:=nil;
       pl:=nil;
      end;
    end
   else
    begin
     //no playlist
     if GroupRandom>rtNone then
      begin
       //any group
       pl:=GetCurrentPlaylist;
       gr:=nil;
       if TrackRandom in [rtList, rtOrder] then
        begin
         //track list
         if not Assigned(FTracksList) or (FTracksList.GetCount=0) then
          begin
           //track list end - can change group
           gr:=GetRandomGroup(pl, GetCurrentGroup);
          end;
        end
       else
        begin
         //track simple/none - any group change
         gr:=GetRandomGroup(pl, GetCurrentGroup);
        end;
       Result:=GetRandomTrack(pl, gr, Current);
       gr:=nil;
       pl:=nil;
      end
     else
      begin
       //no group
       if TrackRandom>rtNone then
         //track simple
         Result:=GetRandomTrack(GetCurrentPlaylist, nil, Current)
       else
         //no track
         Result:=Current;
      end;
    end;
  end;
 {$IFDEF LOG}
 try
  FLog.SaveToFile(FPluginsPath+myPluginLogName);
 finally

 end;
 {$ENDIF}
end;

procedure TAIMPPlugin.Switch;
begin
 mySettings.Enabled:=not mySettings.Enabled;
 SaveSettings(Self, myPluginDLLName, mySettings);
 //menu
 CheckMenuItem(mySettings.Enabled);
 //frame
 if Assigned(FFrame) then
  begin
   if Assigned(FFrame.Frame) then
    begin
     FFrame.Frame.AOCB_Enabled.Checked:=mySettings.Enabled;
    end;
  end;
end;

function TAIMPPlugin.TrackIndexInGroup(const Track: IAIMPPlaylistItem;
  const Group: IAIMPPlaylistGroup): Integer;
 var
  tg: IAIMPPlaylistGroup;
  gi: IAIMPPlaylistItem;
begin
 if Assigned(Track) and Assigned(Group) then
  begin
   CheckResult(Track.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_GROUP, IID_IAIMPPlaylistGroup, tg));
   if Assigned(tg) and (Group=tg) then
    begin
     Result:=Group.GetItemCount-1;
     repeat
      CheckResult(Group.GetItem(Result, IID_IAIMPPlaylistItem, gi));
      if gi=Track then
        Break
      else
        Dec(Result);
     until Result<0;
     gi:=nil;
    end
   else
     Result:=-1;
   tg:=nil;
  end
 else
   Result:=-2;
end;

procedure TAIMPPlugin.UpdateFrameHeader;
begin
 if Assigned(FFrame) then
  begin
   if Assigned(FFrame.Frame) then
     FFrame.Frame.UpdateFrameCaption;
  end;
end;

procedure TAIMPPlugin.UpdatePlaylistList(const Playlist: IAIMPPlaylist;
  Add: Boolean);
begin
 if Add then
   AddNewPlaylist(Playlist)
 else
   RemovePlaylist(Playlist);
end;

procedure TAIMPPlugin.UpdatePlaylistsInfo;
begin
   if Assigned(FFrame.Frame) then
     //FFrame.Frame.BuildPlaylistsData(FPlaylistsData);
     FFrame.Frame.PlaylistInfo:=FPlaylistsData;
end;

{ TAIMPHook }

procedure TAIMPHook.CoreMessage(Message: DWORD; Param1: Integer;
  Param2: Pointer; var Result: HRESULT);
begin
 case Message of
  AIMP_MSG_EVENT_PROPERTY_VALUE:
   begin
    case Param1 of
     AIMP_MSG_PROPERTY_SHUFFLE:
      begin
       TAIMPPlugin(Plugin).SetShuffle(LongBool(Param2^));
      end;
    end;
   end;
 end;
end;

destructor TAIMPHook.Destroy;
begin
  FPlugin:=nil;
  inherited;
end;

{ TAIMPExtensionPlaybackQueue }

constructor TAIMPExtensionPlaybackQueue.Create(const Plugin: TAIMPPlugin);
begin
 inherited Create;
 FPlugin:=Plugin;
 FCurrent:=nil;
 FResult:=nil;
end;

destructor TAIMPExtensionPlaybackQueue.Destroy;
begin
 FCurrent:=nil;
 FResult:=nil;
 FPlugin:=nil;
 inherited;
end;

function TAIMPExtensionPlaybackQueue.GetNext(Current: IInterface; Flags: DWORD;
  QueueItem: IAIMPPlaybackQueueItem): LongBool;
begin
 if not isShuffle and mySettings.Enabled and SomeShuffle(mySettings) then
  begin
   GetResult(Current, QueueItem);
   Result:=Assigned(QueueItem);
  end
 else
   Result:=false;
end;

function TAIMPExtensionPlaybackQueue.GetPrev(Current: IInterface; Flags: DWORD;
  QueueItem: IAIMPPlaybackQueueItem): LongBool;
begin
 Result:=GetNext(Current, Flags, QueueItem);
end;

procedure TAIMPExtensionPlaybackQueue.GetResult(const inCurrent: IInterface;
  outResult: IAIMPPlaybackQueueItem);
 var
  CurrentTrack: IAIMPPlaylistItem;
begin
 if not isShuffle and Assigned(FPlugin) and mySettings.Enabled then
  begin
   //MessageBox(0, 'Select begins...', myPluginName, MB_OK); //debug
   if {inCurrent<>FCurrent} not Assigned(FResult) then
    begin
     FCurrent:=inCurrent;
     if Supports(inCurrent, IID_IAIMPPlaylistItem, CurrentTrack) then
      begin
       //MessageBox(0, 'Selecting from current...', myPluginName, MB_OK); //debug
       FResult:=FPlugin.Shuffle(CurrentTrack);
      end
     else
      begin
       //MessageBox(0, 'Selecting from none...', myPluginName, MB_OK); //debug
       FResult:=FPlugin.Shuffle;
      end;
     //MessageBox(0, 'Selected', myPluginName, MB_OK); //debug
    end;
   //MessageBox(0, 'Select ended', myPluginName, MB_OK); //debug
  end;
 if not mySettings.Enabled or isShuffle then
   FResult:=nil;
 outResult.SetValueAsObject(AIMP_PLAYBACKQUEUEITEM_PROPID_CUSTOM, nil);
 outResult.SetValueAsObject(AIMP_PLAYBACKQUEUEITEM_PROPID_PLAYLISTITEM, FResult);
end;

procedure TAIMPExtensionPlaybackQueue.OnSelect(Item: IAIMPPlaylistItem;
  QueueItem: IAIMPPlaybackQueueItem);
begin
 //do nothing
 if Item=FResult then
   FResult:=nil;
end;

{ TAIMPActionEventHandler }

constructor TAIMPActionEventHandler.Create(const Plugin: TAIMPPlugin);
begin
 inherited Create;
 FPlugin:=Plugin;
end;

destructor TAIMPActionEventHandler.Destroy;
begin
 FPlugin:=nil;
 inherited;
end;

procedure TAIMPActionEventHandler.OnExecute(Data: IInterface);
begin
 FPlugin.Switch;
end;

{ TAdvancedShuffleCustomService }

constructor TAdvancedShuffleCustomService.Create(const Plugin: TAIMPPlugin);
begin
 inherited Create;
 FPlugin:=Plugin;
end;

destructor TAdvancedShuffleCustomService.Destroy;
begin
 FPlugin:=nil;
 inherited;
end;

function TAdvancedShuffleCustomService.AddPlaylistID(PlaylistID: IAIMPString;
  out Index: Integer): HRESULT;
begin
 if Assigned(FPlugin) then
  begin
   Index:=FPlugin.ExcludePlaylistID(IAIMPStringToString(PlaylistID), true);
   Result:=S_OK;
  end
 else
   Result:=E_NOTIMPL;
end;

function TAdvancedShuffleCustomService.RemovePlaylistID(PlaylistID: IAIMPString;
  out Index: Integer): HRESULT;
begin
 if Assigned(FPlugin) then
  begin
   Index:=FPlugin.ExcludePlaylistID(IAIMPStringToString(PlaylistID), false);
   Result:=S_OK;
  end
 else
   Result:=E_NOTIMPL;
end;

{ TAIMPPluginExtensionPlaylistManagerListener }

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistActivated(
  Playlist: IAIMPPlaylist);
begin
  //do nothing
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistAdded(
  Playlist: IAIMPPlaylist);
begin
 if Assigned(FPlugin) then
   TAIMPPlugin(FPlugin).UpdatePlaylistList(Playlist, true);
end;

procedure TAIMPPluginExtensionPlaylistManagerListener.PlaylistRemoved(
  Playlist: IAIMPPlaylist);
begin
 if Assigned(FPlugin) then
   TAIMPPlugin(FPlugin).UpdatePlaylistList(Playlist);
end;

end.
