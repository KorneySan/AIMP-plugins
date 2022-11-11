unit AutoPause_Defines;

interface

uses
  Windows, Classes,

  apiWrappers,
  apiObjects;

type
  TAPAction = (apNothing, apPause, apStop);

  TSettingsActions = record
    PlayerAction: TAPAction;
    DoResume: Boolean;
    // internal use, don't save
    Armed: Boolean;
  end;

  TSettings = record
    PCLock, PCIdle, PCScreenSaver: TSettingsActions;
  end;

  TOnSettingsChange = procedure(const OldSettings, NewSettings: TSettings) of object;

const
  myPluginName = 'Auto pause';
  myPluginVersion = '0.8.2';
  myPluginAuthor = 'Korney San';
  myPluginShortDescription = 'Automatic pausing on PC lock, idle & screensaver.';
  myPluginFullDescription = 'Sponsored by Art¸m';
  myPluginDLLName = 'AutoPause';
  myPluginDLLName1 = myPluginDLLName + '\';

  myPluginIniName = myPluginDLLName + '.ini';
  // form & settings
  categoryAutopause = 'catAutopause';
  categoryAutopauseDefault = 'Auto pause settings';
  groupboxPCLock = 'gbPCLock';
  groupboxPCLockDefault = 'PC Lock';
  comboboxItems = myPluginDLLName + '.Actions';
  comboboxPCLock = 'cbxPCLock';
  comboboxCount = 3;
  checkboxPCLock = 'cbPCLock';
  checkboxPCLockDefault = 'Resume when PC is unlocked';
  groupboxPCIdle = 'gbPCIdle';
  groupboxPCIdleDefault = 'PC Idle';
  comboboxPCIdle = 'cbxPCIdle';
  checkboxPCIdle = 'cbPCIdle';
  checkboxPCIdleDefault = 'Resume when user activity is restored';
  groupboxPCScreenSaver = 'gbPCScreenSaver';
  groupboxPCScreenSaverDefault = 'Screensaver started';
  comboboxPCScreenSaver = 'cbxPCScreenSaver';
  checkboxPCScreenSaver = 'cbPCScreenSaver';
  checkboxPCScreenSaverDefault = 'Resume when screensaver is stopped';
  // default settings
  comboboxPCLockDefaultValue = apNothing;
  checkboxPCLockDefaultValue = True;
  comboboxPCIdleDefaultValue = apNothing;
  checkboxPCIdleDefaultValue = True;
  comboboxPCScreenSaverDefaultValue = apNothing;
  checkboxPCScreenSaverDefaultValue = True;

var
  StaticWideString: array[0..MAX_PATH - 1] of WideChar;
  mySettings: TSettings;

procedure InitializeSettings(AConfig: TAIMPServiceConfig);

procedure LoadSettings(var Settings: TSettings);

procedure SaveSettings(const Settings: TSettings);

procedure FinalizeSettings;

function MakeSettingName(const Section, Value: WideString): WideString;

function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;

function GetLocalizationEx(const Section, Item: UnicodeString; Default: UnicodeString = ''; TryCommon: Boolean = True): IAIMPString; overload;

implementation

uses
  SysUtils;

const
  sFormatSettingValueName = '%s\%s';

var
  myPluginConfig: TAIMPServiceConfig = nil;

function MakeSettingName(const Section, Value: WideString): WideString;
begin
  Result := Format(sFormatSettingValueName, [Section, Value]);
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

function GetLocalizationEx(const Section, Item: UnicodeString; Default: UnicodeString = ''; TryCommon: Boolean = True): IAIMPString; overload;
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

procedure InitializeSettings(AConfig: TAIMPServiceConfig);
begin
  myPluginConfig := AConfig;
end;

procedure LoadSettings(var Settings: TSettings);
begin
  with Settings, myPluginConfig do
  begin
   with PCLock do
    begin
     PlayerAction := TAPAction(ReadInteger(MakeSettingName(myPluginDLLName, comboboxPCLock), Integer(comboboxPCLockDefaultValue)));
     DoResume := ReadBool(MakeSettingName(myPluginDLLName, checkboxPCLock), checkboxPCLockDefaultValue);
    end;
   with PCIdle do
    begin
     PlayerAction := TAPAction(ReadInteger(MakeSettingName(myPluginDLLName, comboboxPCIdle), Integer(comboboxPCIdleDefaultValue)));
     DoResume := ReadBool(MakeSettingName(myPluginDLLName, checkboxPCIdle), checkboxPCIdleDefaultValue);
    end;
   with PCScreenSaver do
    begin
     PlayerAction := TAPAction(ReadInteger(MakeSettingName(myPluginDLLName, comboboxPCScreenSaver), Integer(comboboxPCScreenSaverDefaultValue)));
     DoResume := ReadBool(MakeSettingName(myPluginDLLName, checkboxPCScreenSaver), checkboxPCScreenSaverDefaultValue);
    end;
  end;
end;

procedure SaveSettings(const Settings: TSettings);
var
  i: Integer;
begin
  with Settings, myPluginConfig do
  begin
   with PCLock do
    begin
     WriteInteger(MakeSettingName(myPluginDLLName, comboboxPCLock), Ord(PlayerAction));
     WriteBool(MakeSettingName(myPluginDLLName, checkboxPCLock), DoResume);
    end;
   with PCIdle do
    begin
     WriteInteger(MakeSettingName(myPluginDLLName, comboboxPCIdle), Ord(PlayerAction));
     WriteBool(MakeSettingName(myPluginDLLName, checkboxPCIdle), DoResume);
    end;
   with PCScreenSaver do
    begin
     WriteInteger(MakeSettingName(myPluginDLLName, comboboxPCScreenSaver), Ord(PlayerAction));
     WriteBool(MakeSettingName(myPluginDLLName, checkboxPCScreenSaver), DoResume);
    end;
  end;
end;

procedure FinalizeSettings;
begin
  myPluginConfig := nil;
end;

end.

