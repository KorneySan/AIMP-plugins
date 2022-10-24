unit NextGroup_Impl;

interface

uses
  Windows,
  AIMPCustomPlugin, apiCore, apiActions, apiPlaylists,
  NextGroup_Defines;

type

  TAIMPActionEventHandler = class;

  { TAIMPPlugin }

  TAIMPPlugin = class(TAIMPCustomPlugin)
  private
    FActionHandler: TAIMPActionEventHandler;
    NeedLocalization: Boolean;
    function ServiceTest: Boolean;
    //
    procedure GetVersionInfo;
    procedure CreateActions;
    function GetCurrentPlaylist: IAIMPPlaylist;
    function GetCurrentPlaylistItem: IAIMPPlaylistItem;
    function GetPlayableTrackInGroup(const Group: IAIMPPlaylistGroup; Ascending: Boolean = true): IAIMPPlaylistItem;
    procedure StartTrack(GroupToPlay: TGroupToPlay = gtpNext);
  protected
    function InfoGet(Index: Integer): PWideChar; override; stdcall;
    function InfoGetCategories: Cardinal; override; stdcall;
    function Initialize(Core: IAIMPCore): HRESULT; override; stdcall;
    procedure Finalize; override; stdcall;
  public
    procedure PrevGroup;
    procedure NextGroup;
    procedure RandomGroup;
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
  SysUtils,
  apiPlugin, apiPlayer, apiWrappers, apiObjects;

{ TAIMPPlugin }

procedure TAIMPPlugin.CreateActions;
var
  AAction: IAIMPAction;
begin
  // Create Action
  CheckResult(CoreIntf.CreateObject(IID_IAIMPAction, AAction));
  // Setup it
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionPrev)));
  if NeedLocalization then
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(GetLocalization(idActionPrev, 'Previous group'))));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(GetLocalization(sGroupName))));
    //MessageBox(0, 'Localized', myPluginName, MB_OK); //debug
   end
  else
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(idActionPrev)));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(sGroupName)));
    //MessageBox(0, 'Auto', myPluginName, MB_OK); //debug
   end;
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, FActionHandler));
  // Register the action in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceActionManager, AAction);
  AAction:=nil;
  // Create Action
  CheckResult(CoreIntf.CreateObject(IID_IAIMPAction, AAction));
  // Setup it
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionNext)));
  if NeedLocalization then
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(GetLocalization(idActionNext, 'Next group'))));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(GetLocalization(sGroupName))));
   end
  else
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(idActionNext)));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(sGroupName)));
   end;
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, FActionHandler));
  // Register the action in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceActionManager, AAction);
  AAction:=nil;
  // Create Action
  CheckResult(CoreIntf.CreateObject(IID_IAIMPAction, AAction));
  // Setup it
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_ID, MakeString(idActionRandom)));
  if NeedLocalization then
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(GetLocalization(idActionRandom, 'Random group'))));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(GetLocalization(sGroupName))));
   end
  else
   begin
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_NAME, MakeString(idActionRandom)));
    CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_GROUPNAME, MakeString(sGroupName)));
   end;
  CheckResult(AAction.SetValueAsObject(AIMP_ACTION_PROPID_EVENT, FActionHandler));
  // Register the action in manager
  CoreIntf.RegisterExtension(IID_IAIMPServiceActionManager, AAction);
  AAction:=nil;
end;

procedure TAIMPPlugin.Finalize;
begin
  if Assigned(FActionHandler) then
    FActionHandler:=nil;

  inherited;
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
     if not Succeeded(GetPlayingPlaylist(Result)) then
      begin
       pc:=GetLoadedPlaylistCount;
       //select playlist
       if pc=0 then
         Result:=nil
       else
         CheckResult(GetLoadedPlaylist(0, Result), 'GetLoadedPlaylist error %d');
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
       CheckResult(plpl.GetValueAsInt32(AIMP_PLAYLIST_PROPID_PLAYINGINDEX, pii), 'PlayingIndex error %d');
       if pii>=0 then
         CheckResult(pl.GetItem(pii, IAIMPPlaylistItem, Result), 'Playlist GetItem error %d');
       //MessageBox(0, 'Got at stop', myPluginName, MB_OK); //debug
      end;
     plpl:=nil;
    end;
   pl:=nil;
  end;
 APService:=nil;
end;

function TAIMPPlugin.GetPlayableTrackInGroup(
  const Group: IAIMPPlaylistGroup; Ascending: Boolean = true): IAIMPPlaylistItem;
 var
  Index, Count, p: Integer;
  b: Boolean;
  pl: IAIMPPropertyList;
begin
 Result:=nil;
 if Assigned(Group) then
  begin
   Count:=Group.GetItemCount;
   if Ascending then
    begin
     Index:=0;
     repeat
      CheckResult(Group.GetItem(Index, IAIMPPlaylistItem, Result), 'Group GetItem error %d');
      if Assigned(Result) then
       begin
        if Supports(Result, IAIMPPropertyList, pl) then
         begin
          CheckResult(pl.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_PLAYINGSWITCH, p));
          b:=p>0;
         end
        else
          b:=true;
        if b then
          Break
        else
         begin
          Result:=nil;
          Inc(Index);
         end;
       end
      else
        Inc(Index);
     until Index>=Count;
    end
   else
    begin
     Index:=Count-1;
     repeat
      CheckResult(Group.GetItem(Index, IAIMPPlaylistItem, Result), 'Group GetItem error %d');
      if Assigned(Result) then
       begin
        if Supports(Result, IAIMPPropertyList, pl) then
         begin
          CheckResult(pl.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_PLAYINGSWITCH, p));
          b:=p>0;
         end
        else
          b:=true;
        if b then
          Break
        else
         begin
          Result:=nil;
          Dec(Index);
         end;
       end
      else
        Dec(Index);
     until Index<0;
    end;
  end;
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
   if i>1678 then
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
        Result := myPluginName + ' v' + myPluginVersion;
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
begin
  Result := inherited Initialize(Core);
  if Succeeded(Result) then
   begin
    if not ServiceTest then
     begin
      Result:=E_UNEXPECTED;
      Exit;
     end;
    //Version info
    GetVersionInfo;
    //Action handler
    FActionHandler:=TAIMPActionEventHandler.Create(Self);
    //Actions
    CreateActions;
    //
    Randomize;
   end;
end;

procedure TAIMPPlugin.NextGroup;
begin
 StartTrack(gtpNext);
end;

procedure TAIMPPlugin.PrevGroup;
begin
 StartTrack(gtpPrev);
end;

procedure TAIMPPlugin.RandomGroup;
begin
 StartTrack(gtpRandom);
end;

function TAIMPPlugin.ServiceTest: Boolean;
 var
  APMService: IAIMPServicePlaylistManager;
  APService: IAIMPServicePlayer;
  AAction: IAIMPAction;
  AVIService: IAIMPServiceVersionInfo;
begin
 Result:=true;
 //Playlist manager service
 Result:=Result and Supports(CoreIntf, IAIMPServicePlaylistManager, APMService);
 APMService:=nil;
 //Player service
 Result:=Result and Supports(CoreIntf, IAIMPServicePlayer, APService);
 APService:=nil;
 //Actions service
 Result:=Result and Supports(CoreIntf, IAIMPServiceActionManager, AAction);
 AAction:=nil;
 //Version info service;
 Result:=Result and Supports(CoreIntf, IAIMPServiceVersionInfo, AVIService);
 AVIService:=nil;
end;

procedure TAIMPPlugin.StartTrack(GroupToPlay: TGroupToPlay = gtpNext);
 var
  APService: IAIMPServicePlayer;
  pl: IAIMPPlaylist;
  pli: IAIMPPlaylistItem;
  grp: IAIMPPlaylistGroup;
  grpc, grpi, grpi_: Integer;
begin
 pli:=GetCurrentPlaylistItem;
 if Assigned(pli) then
  begin
   //MessageBox(0, PWideChar('PLI begin'), myPluginName, MB_OK); //debug
   CheckResult(pli.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_PLAYLIST, IAIMPPlaylist, pl));
   //MessageBox(0, PWideChar('Got playlist'), myPluginName, MB_OK); //debug
   CheckResult(pli.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_GROUP, IAIMPPlaylistGroup, grp));
   //MessageBox(0, PWideChar('Got group'), myPluginName, MB_OK); //debug
   if Assigned(pl) and Assigned(grp) then
    begin
     grpc:=pl.GetGroupCount;
     //MessageBox(0, PWideChar('Count: '+IntToStr(grpc)), myPluginName, MB_OK); //debug
     CheckResult(grp.GetValueAsInt32(AIMP_PLAYLISTGROUP_PROPID_INDEX, grpi));
     grpi_:=grpi;
     //MessageBox(0, PWideChar('Index: '+IntToStr(grpi)), myPluginName, MB_OK); //debug
     repeat
      case GroupToPlay of
        gtpNext:
         begin
          Inc(grpi);
          if grpi>=grpc then
            grpi:=0;
         end;
        gtpPrev:
         begin
          Dec(grpi);
          if grpi<0 then
            grpi:=grpc-1;
         end;
        gtpRandom:
         begin
          grpi:=Random(grpc);
         end;
      end;
      //MessageBox(0, PWideChar('New: '+IntToStr(grpi)), myPluginName, MB_OK); //debug
      CheckResult(pl.GetGroup(grpi, IAIMPPlaylistGroup, grp));
      pli:=GetPlayableTrackInGroup(grp{, (GroupToPlay=gtpNext) or (GroupToPlay=gtpRandom)}); //all groups starts from begin
     until Assigned(pli) or (grpi=grpi_);
     if Assigned(pli) and Supports(CoreIntf, IAIMPServicePlayer, APService) then
       CheckResult(APService.Play2(pli));
     APService:=nil;
    end;
   grp:=nil;
   pl:=nil;
  end;
 pli:=nil;
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
var
  AAction: IAIMPAction;
  AIMPString: IAIMPString;
  s: WideString;
begin
 if Assigned(FPlugin) then
  begin
   if Supports(Data, IAIMPAction, AAction) then
    begin
     CoreIntf.CreateObject(IAIMPString, AIMPString);
     AAction.GetValueAsObject(AIMP_ACTION_PROPID_ID, IAIMPString, AIMPString);
     s:=IAIMPStringToString(AIMPString);
     //MessageBox(0, PWideChar(s), myPluginName, MB_OK); //debug
     if SameText(s, idActionPrev) then
      begin
       FPlugin.PrevGroup;
      end
     else
     if SameText(s, idActionNext) then
      begin
       FPlugin.NextGroup;
      end
     else
     if SameText(s, idActionRandom) then
      begin
       FPlugin.RandomGroup;
      end;
     AIMPString:=nil;
    end
   else
    begin
     MessageBox(0, 'No action support!', myPluginName, MB_OK); //debug
    end;
   AAction:=nil;
  end;
end;

end.
