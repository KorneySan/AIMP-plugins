unit NextGroup_Defines;

interface

type
 TGroupToPlay = (gtpNext, gtpPrev, gtpRandom);

const
 myPluginName = 'Next Group';
 myPluginVersion = '1.2.2';
 myPluginAuthor = 'Korney San';
 myPluginShortDescription = '"Next group" and "Prev group" actions.';
 myPluginFullDescription = '';
 //
 myPluginDLLName = 'NextGroup';
 myPluginDLLName1 = myPluginDLLName+'\';
 optFrameName = 'Plugin_FrameName';
 //
 idActionPrev = 'aimp.'+myPluginDLLName+'.action.prev';
 idActionNext = 'aimp.'+myPluginDLLName+'.action.next';
 idActionRandom = 'aimp.'+myPluginDLLName+'.action.random';
 sGroupName = 'Prev/Next group';

function GetLocalization(const Item: WideString; Default: WideString = ''): WideString;

implementation

uses
 SysUtils,
 apiWrappers;

const
 sFormatSettingValueName = '%s\%s';

function SettingName(const Section, Value: WideString): WideString;
begin
 Result:=Format(sFormatSettingValueName, [Section, Value]);
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

end.
