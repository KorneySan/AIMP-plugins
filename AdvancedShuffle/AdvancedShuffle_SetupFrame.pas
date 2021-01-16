unit AdvancedShuffle_SetupFrame;

interface

uses
  AIMPCustomPlugin,
  ControlsLocalization,
  AdvancedShuffle_Defines,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, AdvCombo,
  AdvOfficeButtons, Vcl.CheckLst;

type
  TAIMPOptionFrame = class(TForm)
    ACBX_PlaylistRandom: TAdvComboBox;
    ACBX_GroupRandom: TAdvComboBox;
    ACBX_TrackRandom: TAdvComboBox;
    AOCB_Enabled: TAdvOfficeCheckBox;
    lbl1: TLabel;
    CLB_Excluded: TCheckListBox;
    procedure FormDestroy(Sender: TObject);
    procedure ACBX_PlaylistRandomChange(Sender: TObject);
    procedure ACBX_GroupRandomChange(Sender: TObject);
    procedure ACBX_TrackRandomChange(Sender: TObject);
    procedure AOCB_EnabledClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure CLB_ExcludedClickCheck(Sender: TObject);
  private
    FOnModified: TNotifyEvent;
    FPlugin: TAIMPCustomPlugin;
    LC: TLocalizedControls;
    Settings: TSettings;
    FPlaylistInfo: TPlaylistInfoArray;
    procedure Localize;
    function LocalizeControls(const Key: WideString): WideString;
    procedure DoModified;
    procedure SetModes;
    procedure SetPlaylistInfo(const Data: TPlaylistInfoArray);
    procedure BuildPlaylistsData(const PlaylistsData: TPlaylistInfoArray);
  public
    constructor CreateParented(ParentWindow: HWnd);
    procedure ApplyLocalization;
    procedure ConfigLoad;
    procedure ConfigSave;
    //
    property OnModified: TNotifyEvent read FOnModified write FOnModified;
    property Plugin: TAIMPCustomPlugin read FPlugin write FPlugin default nil;
    procedure UpdateFrameCaption;
    //procedure BuildPlaylistsData(const PlaylistsData: TPlaylistInfoArray);
    property PlaylistInfo: TPlaylistInfoArray read FPlaylistInfo write SetPlaylistInfo;
  end;

var
  AIMPOptionFrame: TAIMPOptionFrame;

implementation

uses
 apiWrappers;

{$R *.dfm}

{ TAIMPOptionFrame }

procedure TAIMPOptionFrame.ACBX_GroupRandomChange(Sender: TObject);
begin
 Settings.GroupRandom:=ACBX_GroupRandom.ItemIndex;
 DoModified;
end;

procedure TAIMPOptionFrame.ACBX_PlaylistRandomChange(Sender: TObject);
begin
 Settings.PlaylistRandom:=ACBX_PlaylistRandom.ItemIndex;
 DoModified;
end;

procedure TAIMPOptionFrame.ACBX_TrackRandomChange(Sender: TObject);
begin
 Settings.TrackRandom:=ACBX_TrackRandom.ItemIndex;
 DoModified;
end;

procedure TAIMPOptionFrame.AOCB_EnabledClick(Sender: TObject);
begin
 Settings.Enabled:=AOCB_Enabled.Checked;
 DoModified;
end;

procedure TAIMPOptionFrame.ApplyLocalization;
begin
 Localize;
end;

procedure TAIMPOptionFrame.BuildPlaylistsData(const PlaylistsData: TPlaylistInfoArray);
 var
  i, t: Integer;
begin
 CLB_Excluded.Clear;
 for i := 0 to High(PlaylistsData) do
  begin
   with PlaylistsData[i] do
    begin
     t:=CLB_Excluded.Items.Add(Name);
     CLB_Excluded.Checked[t]:=State in [soInternal, soExternal];
     CLB_Excluded.ItemEnabled[t]:=State<>soExternal;
    end;
  end;
end;

procedure TAIMPOptionFrame.CLB_ExcludedClickCheck(Sender: TObject);
 var
  //PISO: TPlaylistInfoStateOnly;
  i: Integer;
begin
 if Assigned(OnPlaylistInfoStateChange) then
  begin
   i:=CLB_Excluded.ItemIndex;
   {
   PISO.Index:=i;
   if CLB_Excluded.Checked[i] then
     PISO.State:=soInternal
   else
     PISO.State:=soNormal;
   OnPlaylistInfoStateChange(PISO);
   }
   if CLB_Excluded.Checked[i] then
     FPlaylistInfo[i].State:=soInternal
   else
     FPlaylistInfo[i].State:=soNormal;
   DoModified;
  end;
end;

procedure TAIMPOptionFrame.ConfigLoad;
begin
 LoadSettings(Plugin, myPluginDLLName, Settings);
 //
 AOCB_Enabled.Checked:=Settings.Enabled;
 SetModes;
 if Assigned(OnNeedPlaylistsData) then
   OnNeedPlaylistsData;
end;

procedure TAIMPOptionFrame.ConfigSave;
begin
 SaveSettings(Plugin, myPluginDLLName, Settings, FPlaylistInfo);
 SettingsChanged(Settings);
end;

constructor TAIMPOptionFrame.CreateParented(ParentWindow: HWnd);
begin
 inherited CreateParented(ParentWindow);
 //
 LC:=TLocalizedControls.Create(TLocalizedControl);
 LC.LocalizedText:=LocalizeControls;
 LC.AddControl('Enabled', myPluginDLLName1, AOCB_Enabled);
 LC.AddControl('Playlist shuffle', myPluginDLLName1, ACBX_PlaylistRandom);
 LC.AddControl('Group shuffle', myPluginDLLName1, ACBX_GroupRandom);
 LC.AddControl('Track shuffle', myPluginDLLName1, ACBX_TrackRandom);
 LC.AddControl('Playlists excluded from shuffle', myPluginDLLName1, lbl1);
 //
 Localize;
end;

procedure TAIMPOptionFrame.DoModified;
begin
 if Assigned(OnModified) then
   OnModified(Self);
end;

procedure TAIMPOptionFrame.FormDestroy(Sender: TObject);
begin
 FPlugin:=nil;
 if Assigned(LC) then
   FreeAndNil(LC);
end;

procedure TAIMPOptionFrame.FormPaint(Sender: TObject);
const
  clAimpClient  = $00f0f0f0;
  clAimpBorder  = $00bcbcbc;
  clAimpCaption = $00fafafa;
  CBrushColor: array[Boolean] of TColor = (
    clLime,
    clRed);
  CBorderColor: array[Boolean] of TColor = (
    clMaroon,
    clBlack {clGreen});

var
  R: TRect;
  S: string;
begin
  R := ClientRect;
  Canvas.Brush.Color := clAimpBorder;
  Canvas.FrameRect(R);

  InflateRect(R, -1, -1);
  Canvas.Brush.Color := clWhite;
  Canvas.FrameRect(R);

  R.Bottom := 22;
  Canvas.Brush.Color := CBrushColor[isShuffle];
  Canvas.FillRect(R);


  S := LocalizedFrameName;
  Canvas.Font.Color := CBorderColor[isShuffle]; //clBlack;
  Canvas.Font.Style := [fsBold]; //CFontStyles[CheckBox1.Checked];

  R.Bottom := 21;
  Canvas.TextRect(R, S, [tfSingleLine, tfCenter, tfVerticalCenter, tfNoPrefix]);

  InflateRect(R, 1, 1);
  Canvas.Brush.Color := clAimpBorder;
  Canvas.FrameRect(R);
end;

procedure TAIMPOptionFrame.Localize;
 var
  s: WideString;
begin
 LC.LocalizeControls;
 //Here all non-controls text must be processed
 s:=LangLoadString(SettingName(myPluginDLLName, rtNoneText));
 if s='' then
   s:=rtNoneText;
 ACBX_PlaylistRandom.Items[0]:=s;
 ACBX_GroupRandom.Items[0]:=s;
 ACBX_TrackRandom.Items[0]:=s;
 s:=LangLoadString(SettingName(myPluginDLLName, rtSimpleText));
 if s='' then
   s:=rtSimpleText;
 ACBX_PlaylistRandom.Items[1]:=s;
 ACBX_GroupRandom.Items[1]:=s;
 ACBX_TrackRandom.Items[1]:=s;
 s:=LangLoadString(SettingName(myPluginDLLName, rtListText));
 if s='' then
   s:=rtListText;
 ACBX_PlaylistRandom.Items[2]:=s;
 ACBX_GroupRandom.Items[2]:=s;
 ACBX_TrackRandom.Items[2]:=s;
 SetModes;
 s:=LangLoadString(SettingName(myPluginDLLName, rtOrderRext));
 if s='' then
   s:=rtOrderRext;
 ACBX_PlaylistRandom.Items[3]:=s;
 ACBX_GroupRandom.Items[3]:=s;
 ACBX_TrackRandom.Items[3]:=s;
 SetModes;
 {
 s:=LangLoadString(SettingName(myPluginDLLName, 'Top'));
 if s='' then
   RG_CurrentTrack.Items[0]:='Top'
 else
   RG_CurrentTrack.Items[0]:=s;
 s:=LangLoadString(SettingName(myPluginDLLName, 'Bottom'));
 if s='' then
   RG_CurrentTrack.Items[1]:='Bottom'
 else
   RG_CurrentTrack.Items[1]:=s;
 s:=LangLoadString(SettingName(myPluginDLLName, 'RightButton_Hint'));
 if s='' then
   BE_Template.RightButton.Hint:='Show macroses'
 else
   BE_Template.RightButton.Hint:=s;
 }
end;

function TAIMPOptionFrame.LocalizeControls(const Key: WideString): WideString;
begin
 Result:=LangLoadString(Key);
end;

procedure TAIMPOptionFrame.SetModes;
begin
 with Settings do
  begin
   ACBX_PlaylistRandom.ItemIndex:=PlaylistRandom;
   ACBX_GroupRandom.ItemIndex:=GroupRandom;
   ACBX_TrackRandom.ItemIndex:=TrackRandom;
  end;
end;

procedure TAIMPOptionFrame.SetPlaylistInfo(const Data: TPlaylistInfoArray);
begin
 CopyPlaylistInfoArray(Data, FPlaylistInfo);
 BuildPlaylistsData(FPlaylistInfo);
end;

procedure TAIMPOptionFrame.UpdateFrameCaption;
begin
 Repaint;
end;

end.
