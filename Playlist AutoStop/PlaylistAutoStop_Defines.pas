unit PlaylistAutoStop_Defines;

interface

uses
  Windows, Classes,
  AIMPCustomPlugin,
  apiObjects;

type
  TSettings = record
    SwitchOff: Boolean;
    Playlists: TStrings;
  end;

  TOnSettingsChange = procedure(const OldSettings, NewSettings: TSettings) of object;

  TPlaylistType = (ptActive, ptPlaying);

const
  myPluginName = 'Playlist autostop';
  myPluginVersion = '1.2';
  myPluginAuthor = 'Korney San';
  myPluginShortDescription = 'Automatic stopping of selected playlist.';
  myPluginFullDescription = '';
  myPluginDLLName = 'PlaylistAutoStop';
  myPluginDLLName1 = myPluginDLLName + '\';
  myPluginLogName = myPluginDLLName1 + myPluginDLLName + '.log';
  myPluginIniName = myPluginDLLName + '.ini';
  //actions and menus
  idActionSelectPlaylist = 'aimp.' + myPluginDLLName + '.action.selectplaylist';
  sActionSelectPlaylist = 'Autostop current playlist';
  idMenuSelectPlaylist = 'aimp.' + myPluginDLLName + '.menuitem.selectplaylist';
  //ini
  sectionOptions = 'Options';
  sectionPlaylists = 'Playlists';
  optSwitchOff = 'SwitchOff';
  optSwitchOffDefault = True;

  //localization
  optFrameName = 'Plugin_FrameName';
  categoryAutostop = 'catAutostop';
  categoryAutostopDefault = 'Autostop settings';

var
  StaticWideString: array[0..MAX_PATH - 1] of WideChar;
  mySettings: TSettings;

procedure InitializeSettings(AUserProfilePath: string);

procedure LoadSettings(var Settings: TSettings);

procedure SaveSettings(const Settings: TSettings);

procedure UpdateSettings(var Settings: TSettings; const PID2Remove: string);

procedure FinalizeSettings;

function LocalizedFrameName: WideString;

function MakeSettingName(const Section, Value: WideString): WideString;
function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;
function GetLocalizationEx(const Section, Item: UnicodeString; Default: UnicodeString = ''; TryCommon: Boolean = true): IAIMPString; overload;

implementation

uses
  SysUtils, IniFiles, apiWrappers;

const
  sFormatSettingValueName = '%s\%s';

var
  myPlugin: TAIMPCustomPlugin = nil;
  myIniFile: TIniFile = nil;
  UserProfilePath: string = '';

function MakeSettingName(const Section, Value: WideString): WideString;
begin
  Result := Format(sFormatSettingValueName, [Section, Value]);
end;

procedure InitializeSettings(AUserProfilePath: string);
begin
  mySettings.Playlists := TStringList.Create;
  UserProfilePath := IncludeTrailingPathDelimiter(AUserProfilePath);
  myIniFile := TIniFile.Create(UserProfilePath + myPluginIniName);
end;

procedure LoadSettings(var Settings: TSettings);
begin
  with Settings, myIniFile do
  begin
    SwitchOff := ReadBool(sectionOptions, optSwitchOff, optSwitchOffDefault);
    Playlists.Clear;
    ReadSection(sectionPlaylists, Playlists);
  end;
end;

procedure SaveSettings(const Settings: TSettings);
var
  i: Integer;
begin
  with Settings, myIniFile do
  begin
    WriteBool(sectionOptions, optSwitchOff, SwitchOff);
    EraseSection(sectionPlaylists);
    for i := 0 to Playlists.Count - 1 do
      WriteString(sectionPlaylists, Playlists[i], '');
  end;
end;

procedure UpdateSettings(var Settings: TSettings; const PID2Remove: string);
var
  i: Integer;
begin
  with Settings, myIniFile do
  begin
    i := Playlists.IndexOf(PID2Remove);
    if i >= 0 then
    begin
      myIniFile.DeleteKey(sectionPlaylists, PID2Remove);
      Playlists.Delete(i);
    end;
  end;
end;

procedure FinalizeSettings;
begin
  if Assigned(myIniFile) then
  begin
    myIniFile.UpdateFile;
    FreeAndNil(myIniFile);
  end;
  if Assigned(mySettings.Playlists) then
    FreeAndNil(mySettings.Playlists);
  myPlugin := nil;
end;

function LocalizedFrameName: WideString;
begin
  Result := LangLoadString(MakeSettingName(myPluginDLLName, optFrameName));
  if Result = '' then
    Result := myPluginName;
end;

function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;
begin
  Result := LangLoadString(MakeSettingName(myPluginDLLName, Item));
  if Result = '' then
  begin
    Result := LangLoadString(MakeSettingName('Common', Item));
    if Result = '' then
      Result := Default;
  end;
end;

function GetLocalizationEx(const Section, Item: UnicodeString; Default: UnicodeString = ''; TryCommon: Boolean = true): IAIMPString; overload;
begin
 Result := LangLoadStringEx(MakeSettingName(Section, Item));
 if Result.GetLength = 0 then
  begin
   if TryCommon then
    begin
     Result := LangLoadStringEx(MakeSettingName('Common', Item));
     if Result.GetLength = 0 then
       Result := MakeString(Default);
    end
   else
     Result := MakeString(Default);
  end;
end;

end.

