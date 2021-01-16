unit AIMP_Helpers;

interface

uses
 Classes,
 AIMPCustomPlugin,
 apiObjects,
 apiFileManager;

type

 TMyFileInfo = record
  FileInfo: IAIMPFileInfo;
  TimeRemaining: Double;
  PlayerState: Integer;
 end;

 TAIMPPluginSettings = class(TPersistent)
  protected
   FPlugin: TAIMPCustomPlugin;
   FSection: string;
   procedure AssignData(Source: TPersistent); virtual; abstract;
  public
   constructor Create(const APlugin: TAIMPCustomPlugin; const ASection: string);
   destructor Destroy; override;
   procedure Assign(Source: TPersistent); override;
   //
   procedure LoadSettings; virtual; abstract;
   procedure SaveSettings; virtual; abstract;
   property Plugin: TAIMPCustomPlugin read FPlugin;
   property Section: String read FSection;
 end;

const
 tagLastPlayDate = '%LastPlayDate';
 tagLastPlayTime = '%LastPlayTime';
 tagState = '%State';
 tagTimeRemaining = '%TimeRemaining';
 //
 mpPlayerStateStopped = 0;
 mpPlayerStateStoppedText = 'Stopped';
 mpPlayerStatePaused = 1;
 mpPlayerStatePausedText = 'Paused';
 mpPlayerStatePlaying = 2;
 mpPlayerStatePlayingText = 'Playing';

function MakeSettingName(const Section, Value: WideString; Prefix: WideString = ''): WideString;
function GetLocalization(const Section, Item: WideString; Default: WideString = ''; TryCommon: Boolean = true): WideString;
function GetGroupLocalization(const Section, Item: WideString; Default: WideString = ''; TryCommon: Boolean = true): WideString;
function FillLastPlayDate(const Template: WideString): WideString;
function FillLastPlayTime(const Template: WideString): WideString;
function FillState(const Template, Section: WideString; const APlayerState: Integer): WideString;
function FillTimeRemaining(const Template: WideString; const TimeRemaining: Double): WideString;
function FillTemplateWithInfo(const AFileInfo: TMyFileInfo; const Template: WideString; Section: WideString = ''): WideString;
function MakeActionID(const PluginDLLName, ActionName: WideString): WideString;
function MakeMenuItemID(const PluginDLLName, ActionName: WideString): WideString;
function ErrorToString(const Error: HRESULT): WideString;
procedure CheckResultDesc(R: HRESULT; const AMessage: string = '%s');
function GetPluginsPath: WideString;
function GetAIMPItemName(const Item: IInterface): WideString;
function GetAIMPItemIndex(const Item: IInterface): Integer;
function IIndexOf(const List: IAIMPObjectList; const Item: IInterface; const ItemType: TGUID): Integer;

implementation

uses
  Windows,
  SysUtils,
  apiCore,
  apiPlaylists,
  apiWrappers;

const
 sFormatSettingValueName = '%s\%s';
 sFormatSettingValueNameWithPrefix = '%s\%s%s';
 sFormatActionID = 'aimp.%s.action.%s';
 sFormatMenuItemID = 'aimp.%s.menuitem.%s';

function MakeSettingName(const Section, Value: WideString; Prefix: WideString = ''): WideString; overload;
begin
 if Prefix='' then
   Result:=Format(sFormatSettingValueName, [Section, Value])
 else
   Result:=Format(sFormatSettingValueNameWithPrefix, [Section, Prefix, Value]);
end;

function GetLocalization(const Section, Item: WideString; Default: WideString = ''; TryCommon: Boolean = true): WideString;
begin
 Result:=LangLoadString(MakeSettingName(Section, Item));
 if Result='' then
  begin
   if TryCommon then
    begin
     Result:=LangLoadString(MakeSettingName('Common', Item));
     if Result='' then
       Result:=Default;
    end
   else
     Result:=Default;
  end;
end;

function GetGroupLocalization(const Section, Item: WideString; Default: WideString = ''; TryCommon: Boolean = true): WideString;
begin
 Result:=LangLoadString(MakeSettingName(Section, Item+'.g'));
 if Result='' then
  begin
   if TryCommon then
    begin
     Result:=LangLoadString(MakeSettingName('Common', Item+'.g'));
     if Result='' then
       Result:=Default;
    end
   else
     Result:=Default;
  end;
end;

function FillLastPlayDate(const Template: WideString): WideString;
begin
 Result:=StringReplace(Template, tagLastPlayDate, DateToStr(Now), [rfReplaceAll]);
end;

function FillLastPlayTime(const Template: WideString): WideString;
begin
 Result:=StringReplace(Template, tagLastPlayTime, TimeToStr(Now), [rfReplaceAll]);
end;

function FillState(const Template, Section: WideString; const APlayerState: Integer): WideString;
 var
  StateText: WideString;
begin
 case APlayerState of
  mpPlayerStateStopped: StateText:=GetLocalization(Section, mpPlayerStateStoppedText, mpPlayerStateStoppedText);
  mpPlayerStatePaused: StateText:=GetLocalization(Section, mpPlayerStatePausedText, mpPlayerStatePausedText);
  mpPlayerStatePlaying: StateText:=GetLocalization(Section, mpPlayerStatePlayingText, mpPlayerStatePlayingText);
  else StateText:='';
 end;
 Result:=StringReplace(Template, tagState, StateText, [rfReplaceAll]);
end;

function SecondsToTimeSting(const Seconds: Integer): WideString;
 var
  hrs: Integer;
  min: Integer;
  sec: Integer;
begin
 hrs:=Seconds div 3600;
 min:=(Seconds mod 3600) div 60;
 sec:=Seconds mod 60;
 if hrs>0 then
   Result:=Format('%d:%2.2d:%2.2d', [hrs, min, sec])
 else
   Result:=Format('%2.2d:%2.2d', [min, sec]);
end;

function FillTimeRemaining(const Template: WideString; const TimeRemaining: Double): WideString;
 var
  Seconds: Integer;
begin
 Seconds:=Round(TimeRemaining);
 Result:=StringReplace(Template, tagTimeRemaining, SecondsToTimeSting(Seconds), [rfReplaceAll]);
end;

function FillTemplateWithInfo(const AFileInfo: TMyFileInfo; const Template: WideString; Section: WideString = ''): WideString;
 var
  AFIFService: IAIMPServiceFileInfoFormatter;
  AString: IAIMPString;
  LastPlayDate, LastPlayTime, myTemplate: string;
begin
 Result:='';
 with AFileInfo do
  begin
   if Assigned(AFileInfo.FileInfo) and CoreGetService(IAIMPServiceFileInfoFormatter, AFIFService) then
    begin
     //%LastPlayDate and %LastPlayTime workaround begin
     CheckResult(AFIFService.Format(MakeString(tagLastPlayDate), FileInfo, 0, nil, AString));
     LastPlayDate:=IAIMPStringToString(AString);
     CheckResult(AFIFService.Format(MakeString(tagLastPlayTime), FileInfo, 0, nil, AString));
     LastPlayTime:=IAIMPStringToString(AString);
     myTemplate:=Template;
     if (LastPlayDate='') or (LastPlayTime='') then
      begin
       myTemplate:=FillLastPlayDate(myTemplate);
       myTemplate:=FillLastPlayTime(myTemplate);
      end;
     //%LastPlayDate and %LastPlayTime workaround end
     CheckResult(AFIFService.Format(MakeString(myTemplate), FileInfo, 0, nil, AString), 'File info Format error %d');
     Result:=FillState(FillTimeRemaining(IAIMPStringToString(AString), TimeRemaining), Section, PlayerState);
     //
     AString:=nil;
     AFIFService:=nil;
    end;
  end;
end;

function MakeActionID(const PluginDLLName, ActionName: WideString): WideString;
begin
 Result:=Format(sFormatActionID, [PluginDLLName, ActionName]);
end;

function MakeMenuItemID(const PluginDLLName, ActionName: WideString): WideString;
begin
 Result:=Format(sFormatMenuItemID, [PluginDLLName, ActionName]);
end;

{ TAIMPPluginSettings }

procedure TAIMPPluginSettings.Assign(Source: TPersistent);
begin
 if Assigned(Source) then
  begin
   if Source is TAIMPPluginSettings then
     AssignData(Source)
   else
     inherited Assign(Source);
  end;
end;

constructor TAIMPPluginSettings.Create(const APlugin: TAIMPCustomPlugin;
  const ASection: string);
begin
 if Assigned(APlugin) then
   FPlugin:=APlugin
 else
   FPlugin:=nil;
 FSection:=ASection;
end;

destructor TAIMPPluginSettings.Destroy;
begin
 FPlugin:=nil;
 FSection:='';
 inherited;
end;

function ErrorToString(const Error: HRESULT): WideString;
begin
 case Error of
  S_OK: Result:='S_OK';
  E_ACCESSDENIED: Result:='E_ACCESSDENIED';
  E_INVALIDARG: Result:='E_INVALIDARG';
  E_NOTIMPL: Result:='E_NOTIMPL';
  E_UNEXPECTED: Result:='E_UNEXPECTED';
  E_FAIL: Result:='E_FAIL';
  else Result:=IntToStr(Error);
 end;
end;

procedure CheckResultDesc(R: HRESULT; const AMessage: string = '%s');
begin
  if Failed(R) then
    raise Exception.CreateFmt(AMessage, [ErrorToString(R)]);
end;

function GetPluginsPath: WideString;
 var
  AIMPString: IAIMPString;
begin
 CheckResult(CoreIntf.GetPath(AIMP_CORE_PATH_PLUGINS, AIMPString));
 Result:=IAIMPStringToString(AIMPString);
 AIMPString:=nil;
end;

function GetAIMPItemName(const Item: IInterface): WideString;
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
     CheckResultDesc(prl.GetValueAsObject(AIMP_PLAYLIST_PROPID_NAME, IID_IAIMPString, AIMPString), '%s error when getting playlist name');
     Result:=IAIMPStringToString(AIMPString);
     AIMPString:=nil;
     prl:=nil;
    end;
   pl:=nil;
  end
 else
 if Supports(Item, IID_IAIMPPlaylistGroup, gr) then
  begin
   CheckResultDesc(gr.GetValueAsObject(AIMP_PLAYLISTGROUP_PROPID_NAME, IID_IAIMPString, AIMPString), '%s error when getting group name');
   Result:=IAIMPStringToString(AIMPString);
   AIMPString:=nil;
   gr:=nil;
  end
 else
 if Supports(Item, IID_IAIMPPlaylistItem, tr) then
  begin
   CheckResultDesc(tr.GetValueAsObject(AIMP_PLAYLISTITEM_PROPID_DISPLAYTEXT, IID_IAIMPString, AIMPString), '%s error when getting playlist item text');
   Result:=IAIMPStringToString(AIMPString);
   AIMPString:=nil;
   tr:=nil;
  end;
end;

function GetAIMPItemIndex(const Item: IInterface): Integer;
 var
  gr: IAIMPPlaylistGroup;
  tr: IAIMPPlaylistItem;
begin
 Result:=-1;
 if Supports(Item, IID_IAIMPPlaylistGroup, gr) then
  begin
   CheckResultDesc(gr.GetValueAsInt32(AIMP_PLAYLISTGROUP_PROPID_INDEX, Result), '%s error when getting group index');
   gr:=nil;
  end
 else
 if Supports(Item, IID_IAIMPPlaylistItem, tr) then
  begin
   CheckResultDesc(tr.GetValueAsInt32(AIMP_PLAYLISTITEM_PROPID_INDEX, Result), '%s error when getting playlist item index');
   tr:=nil;
  end;
end;

function IIndexOf(const List: IAIMPObjectList; const Item: IInterface; const ItemType: TGUID): Integer;
 var
  ListItem: IInterface;
begin
 if Assigned(List) and Assigned(Item) then
  begin
   if Supports(Item, ItemType, ListItem) then
    begin
     ListItem:=nil;
     Result:=List.GetCount;
     while Result>=0 do
      begin
       CheckResultDesc(List.GetObject(Result, ItemType, ListItem), '%s error when getting item #'+IntToStr(Result)+' from list');
       if ListItem=Item then
         Break
       else
         Dec(Result);
      end;
     //
     ListItem:=nil;
    end
   else
     Result:=-2;
  end
 else
   Result:=-3;
end;

end.
