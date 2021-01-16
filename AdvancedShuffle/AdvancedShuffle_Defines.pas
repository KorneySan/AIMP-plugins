unit AdvancedShuffle_Defines;

interface

uses
 Windows,
 AIMPCustomPlugin,
 apiWrappers,
 apiPlaylists;

type

  TSettings = record
   Enabled: Boolean;
   PlaylistRandom: Integer;
   GroupRandom: Integer;
   TrackRandom: Integer;
  end;

  TPlaylistInfo = record
    ID: WideString;
    Name: WideString;
    State: Integer;
  end;

  TPlaylistInfoArray = array of TPlaylistInfo;

  TPlaylistInfoStateOnly = record
    Index: Integer;
    State: Integer;
  end;

  TOnSettingsChange = procedure (const OldSettings, NewSettings: TSettings) of object;
  //TOnValueChange = procedure (const NewValue: Pointer) of object;
  TNotifyProcedure = procedure of object;
  TNotifyPlaylistInfoStateChange = procedure (const NewState: TPlaylistInfoStateOnly) of object;

const
 myPluginName = 'Advanced shuffle';
 myPluginAuthor = 'Korney San';
 myPluginShortDescription = 'Advanced shuffle of tracks.';
 myPluginFullDescription = '';

 myPluginDLLName = 'AdvancedShuffle';
 myPluginDLLName1 = myPluginDLLName+'\';
 myPluginLogName = myPluginDLLName1+myPluginDLLName+'.log';
 optFrameName = 'Plugin_FrameName';
 //settings
 optEnabled = 'Enabled';
 optPlaylistRandom = 'PlaylistRandom';
 optGroupRandom = 'GroupRandom';
 optTrackRandom = 'TrackRandom';
 //randomization type
 rtNone = 0;
 rtSimple = 1;
 rtList = 2;
 rtOrder = 3;
 rtNoneText = 'None';
 rtSimpleText = 'Simple';
 rtListText = 'List';
 rtOrderRext = 'Order';
 //randomizable
 irNone = -1;
 irOne = 0;
 irMany = 1;
 //playable
 DefaultPlayable = true;
 //actions and menus
 idActionSwitch = 'aimp.'+myPluginDLLName+'.action.switch';
 sActionSwitch = 'Switch state';
 idMenuSwitch = 'aimp.'+myPluginDLLName+'.menuitem.switch';
 //log
 sLogFormat = 'Selected %s "%s" (%d of %d)';
 sPlaylist = 'playlist';
 sGroup = 'group';
 sTrack = 'track';
 //state
 soNormal = 0;
 soInternal = 1;
 soExternal = 2;
 //copy info
 ciFull = 0;
 ciByIndex = 1;
 ciByID = 2;

var
  StaticWideString: array [0..MAX_PATH-1] of WideChar;
  mySettings: TSettings = (
  Enabled: false;
  PlaylistRandom: rtNone;
  GroupRandom: rtNone;
  TrackRandom: rtNone;
  );
  OnSettingsChange: TOnSettingsChange = nil;
  isShuffle: LongBool = false;
  OnNeedPlaylistsData: TNotifyProcedure = nil;
  OnPlaylistInfoStateChange: TNotifyPlaylistInfoStateChange = nil;

function SettingName(const Section, Value: WideString): WideString;
procedure LoadSettings(Plugin: TAIMPCustomPlugin; const Section: String; var Settings: TSettings; PlaylistData: TPlaylistInfoArray = nil);
procedure SaveSettings(Plugin: TAIMPCustomPlugin; const Section: String; const Settings: TSettings; Playlistdata: TPlaylistInfoArray = nil);
procedure SettingsChanged(const Settings: TSettings);
procedure FinalizeSettings;
function LocalizedFrameName: WideString;
procedure CheckRandomType(var Random: Integer);
function SomeShuffle(const Settings: TSettings): Boolean;
function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;
//
procedure ClearPlaylistInfo(var PlaylistInfo: TPlaylistInfo);
procedure ClearPlaylistInfoArray(var PlaylistInfoArray: TPlaylistInfoArray);
function GetIndexPlaylistInfoByID(const PlaylistInfoArray: TPlaylistInfoArray; const ID: WideString): Integer;
function AddPlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const PlaylistInfo: TPlaylistInfo): Integer; overload;
function AddPlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const AID, AName: WideString; AState: Integer = soNormal): Integer; overload;
procedure DeletePlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const Index: Integer);
procedure CopyPlaylistInfoArray(const Source: TPlaylistInfoArray; var Destination: TPlaylistInfoArray; CopyMode: Integer = ciFull);
procedure CheckPlaylistInfoState(var PlaylistInfo: TPlaylistInfo);
procedure LoadPlaylistInfoState(Plugin: TAIMPCustomPlugin; const Section: String; var PlaylistInfo: TPlaylistInfo); overload;
procedure LoadPlaylistInfoState(const Config: TAIMPServiceConfig; const Section: String; var PlaylistInfo: TPlaylistInfo); overload;
procedure SavePlaylistInfoState(Plugin: TAIMPCustomPlugin; const Section: String; const PlaylistInfo: TPlaylistInfo); overload;
procedure SavePlaylistInfoState(const Config: TAIMPServiceConfig; const Section: String; const PlaylistInfo: TPlaylistInfo); overload;
//
function GetPlaylistID(const Playlist: IAIMPPlaylist): WideString;
function IsPlaylistAllowed(const Data: TPlaylistInfoArray; const Playlist: IAIMPPlaylist): boolean;

implementation

uses
 SysUtils,
 apiObjects;

const
 sFormatSettingValueName = '%s\%s';

var
 myPlugin: TAIMPCustomPlugin = nil;

function SettingName(const Section, Value: WideString): WideString;
begin
 Result:=Format(sFormatSettingValueName, [Section, Value]);
end;

procedure CheckRandomType(var Random: Integer);
begin
 if Random<rtNone then
   Random:=rtNone
 else
 if Random>rtOrder then
   Random:=rtOrder;
end;

procedure LoadSettings(Plugin: TAIMPCustomPlugin; const Section: String; var Settings: TSettings; PlaylistData: TPlaylistInfoArray = nil);
 var
  AConfig: TAIMPServiceConfig;
  I: Integer;
begin
 if Assigned(Plugin) then
   myPlugin:=Plugin
 else
   Plugin:=myPlugin;
 if Assigned(Plugin) then
  begin
   AConfig:=Plugin.ServiceGetConfig;
   with AConfig, Settings do
      begin
       Enabled:=ReadBool(SettingName(myPluginDLLName, optEnabled), false);
       PlaylistRandom:=ReadInteger(SettingName(myPluginDLLName, optPlaylistRandom), rtNone);
       CheckRandomType(PlaylistRandom);
       GroupRandom:=ReadInteger(SettingName(myPluginDLLName, optGroupRandom), rtNone);
       CheckRandomType(GroupRandom);
       TrackRandom:=ReadInteger(SettingName(myPluginDLLName, optTrackRandom), rtNone);
       CheckRandomType(TrackRandom);
       if Assigned(PlaylistData) then
        begin
         for i := 0 to High(PlaylistData) do
           LoadPlaylistInfoState(AConfig, Section, PlaylistData[i]);
        end;
      end;
   FreeAndNil(AConfig);
  end;
end;

procedure SaveSettings(Plugin: TAIMPCustomPlugin; const Section: String; const Settings: TSettings; PlaylistData: TPlaylistInfoArray = nil);
 var
  AConfig: TAIMPServiceConfig;
  i: Integer;
begin
 if Assigned(Plugin) then
   myPlugin:=Plugin
 else
   Plugin:=myPlugin;
 if Assigned(Plugin) then
  begin
   AConfig:=Plugin.ServiceGetConfig;
   with AConfig, Settings do
      begin
       WriteBool(SettingName(myPluginDLLName, optEnabled), Enabled);
       WriteInteger(SettingName(myPluginDLLName, optPlaylistRandom), PlaylistRandom);
       WriteInteger(SettingName(myPluginDLLName, optGroupRandom), GroupRandom);
       WriteInteger(SettingName(myPluginDLLName, optTrackRandom), TrackRandom);
       if Assigned(PlaylistData) then
        begin
         for i := 0 to High(PlaylistData) do
           SavePlaylistInfoState(AConfig, Section, PlaylistData[i]);
        end;
      end;
   FreeAndNil(AConfig);
  end;
end;

procedure SettingsChanged(const Settings: TSettings);
begin
 if Assigned(OnSettingsChange) then
   OnSettingsChange(mySettings, Settings);
 mySettings:=Settings;
end;

procedure FinalizeSettings;
begin
 myPlugin:=nil;
end;

function LocalizedFrameName: WideString;
begin
 Result:=LangLoadString(SettingName(myPluginDLLName, optFrameName));
 if Result='' then
   Result:=myPluginName;
end;

function SomeShuffle(const Settings: TSettings): Boolean;
begin
 with Settings do
   Result:=(PlaylistRandom>rtNone) or (GroupRandom>rtNone) or (TrackRandom>rtNone);
end;

function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;
begin
 Result:=LangLoadString(SettingName(myPluginDLLName, Item));
 if Result='' then
  begin
   Result:=LangLoadString(SettingName('Common', Item));
   if Result='' then
     Result:=Default;
  end;
end;

procedure ClearPlaylistInfo(var PlaylistInfo: TPlaylistInfo);
begin
 with PlaylistInfo do
  begin
   ID:='';
   Name:='';
   State:=0;
  end;
end;

procedure ClearPlaylistInfoArray(var PlaylistInfoArray: TPlaylistInfoArray);
 var
  i: Integer;
begin
 for i := High(PlaylistInfoArray) downto 0 do
   ClearPlaylistInfo(PlaylistInfoArray[i]);
 SetLength(PlaylistInfoArray, 0);
end;

function GetIndexPlaylistInfoByID(const PlaylistInfoArray: TPlaylistInfoArray; const ID: WideString): Integer;
begin
 Result:=High(PlaylistInfoArray);
 while Result>=0 do
  begin
   if SameText(ID, PlaylistInfoArray[Result].ID) then
     Break
   else
     Dec(Result);
  end;
end;

function AddPlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const PlaylistInfo: TPlaylistInfo): Integer; overload;
begin
 SetLength(PlaylistInfoArray, Length(PlaylistInfoArray)+1);
 Result:=High(PlaylistInfoArray);
 PlaylistInfoArray[Result]:=PlaylistInfo;
end;

function AddPlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const AID, AName: WideString; AState: Integer = soNormal): Integer; overload;
begin
 SetLength(PlaylistInfoArray, Length(PlaylistInfoArray)+1);
 Result:=High(PlaylistInfoArray);
 with PlaylistInfoArray[Result] do
  begin
   ID:=AID;
   Name:=AName;
   State:=AState;
  end;
end;

procedure DeletePlaylistInfo(var PlaylistInfoArray: TPlaylistInfoArray; const Index: Integer);
 var
  h, i: Integer;
begin
 h:=High(PlaylistInfoArray);
 if (Index>=0) and (Index<=h) then
  begin
   for i := Index+1 to h do
     PlaylistInfoArray[i-1]:=PlaylistInfoArray[i];
   SetLength(PlaylistInfoArray, h);
  end;
end;

procedure CopyPlaylistInfoArray(const Source: TPlaylistInfoArray; var Destination: TPlaylistInfoArray; CopyMode: Integer = ciFull);
 var
  i, t, l: Integer;
begin
 l:=Length(Source);
 case CopyMode of
  ciByIndex:
   begin
    t:=Length(Destination);
    if t>l then
      t:=l;
    for i := 0 to t-1 do
      Destination[i]:=Source[i];
   end;
  ciByID:
   begin
    for i := 0 to l-1 do
     begin
      t:=GetIndexPlaylistInfoByID(Destination, Source[i].ID);
      if t>=0 then
        Destination[t]:=Source[i];
     end;
   end;
  else
   begin
    SetLength(Destination, l);
    for i := 0 to l-1 do
      Destination[i]:=Source[i];
   end;
 end;
end;

procedure CheckPlaylistInfoState(var PlaylistInfo: TPlaylistInfo);
begin
 with PlaylistInfo do
  begin
   if State<soNormal then
     State:=soNormal;
   if State>soExternal then
     State:=soNormal;
  end;
end;

procedure LoadPlaylistInfoState(Plugin: TAIMPCustomPlugin; const Section: String; var PlaylistInfo: TPlaylistInfo); overload;
 var
  Config: TAIMPServiceConfig;
begin
 if Assigned(Plugin) then
  begin
   Config:=Plugin.ServiceGetConfig;
   LoadPlaylistInfoState(Config, Section, PlaylistInfo);
   FreeAndNil(Config);
  end;
end;

procedure LoadPlaylistInfoState(const Config: TAIMPServiceConfig; const Section: String; var PlaylistInfo: TPlaylistInfo); overload;
begin
 if Assigned(Config) then
  begin
   PlaylistInfo.State:=Config.ReadInteger(SettingName(myPluginDLLName, PlaylistInfo.ID), soNormal);
   CheckPlaylistInfoState(PlaylistInfo);
  end;
end;

procedure SavePlaylistInfoState(Plugin: TAIMPCustomPlugin; const Section: String; const PlaylistInfo: TPlaylistInfo); overload;
 var
  Config: TAIMPServiceConfig;
begin
 if Assigned(Plugin) then
  begin
   Config:=Plugin.ServiceGetConfig;
   SavePlaylistInfoState(Config, Section, PlaylistInfo);
   FreeAndNil(Config);
  end;
end;

procedure SavePlaylistInfoState(const Config: TAIMPServiceConfig; const Section: String; const PlaylistInfo: TPlaylistInfo); overload;
begin
 if Assigned(Config) then
  begin
   if PlaylistInfo.State=soNormal then
     Config.Delete(SettingName(myPluginDLLName, PlaylistInfo.ID))
   else
     Config.WriteInteger(SettingName(myPluginDLLName, PlaylistInfo.ID), PlaylistInfo.State);
  end;
end;

function GetPlaylistID(const Playlist: IAIMPPlaylist): WideString;
 var
  APList: IAIMPPropertyList;
  AIMPString: IAIMPString;
begin
  if Assigned(Playlist) and Supports(Playlist, IID_IAIMPPropertyList, APList) then
   begin
    CheckResult(APList.GetValueAsObject(AIMP_PLAYLIST_PROPID_ID, IID_IAIMPString, AIMPString));
    Result:=IAIMPStringToString(AIMPString);
   end
  else Result:='';
  AIMPString:=nil;
  APList:=nil;
end;

function IsPlaylistAllowed(const Data: TPlaylistInfoArray; const Playlist: IAIMPPlaylist): boolean;
 var
  ID: WideString;
  Index: Integer;
begin
  if Assigned(Playlist) and Assigned(Data) then
   begin
    ID:=GetPlaylistID(Playlist);
    Index:=GetIndexPlaylistInfoByID(Data, ID);
    Result:=(Index<0) or (Data[Index].State=soNormal);
   end
  else Result:=False;
end;

end.
