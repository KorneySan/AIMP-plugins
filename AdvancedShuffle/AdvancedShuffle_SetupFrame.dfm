object AIMPOptionFrame: TAIMPOptionFrame
  Left = 0
  Top = 0
  BorderStyle = bsNone
  ClientHeight = 240
  ClientWidth = 347
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Padding.Top = 23
  OldCreateOrder = False
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 13
  object lbl1: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 133
    Width = 341
    Height = 13
    Align = alTop
    Caption = 'Playlists excluded from shuffle'
    ExplicitWidth = 145
  end
  object ACBX_PlaylistRandom: TAdvComboBox
    AlignWithMargins = True
    Left = 76
    Top = 52
    Width = 268
    Height = 21
    Color = clWindow
    Version = '1.6.2.1'
    Visible = True
    Align = alTop
    ButtonWidth = 17
    Style = csDropDownList
    EmptyTextStyle = []
    DropWidth = 0
    Enabled = True
    ItemIndex = -1
    Items.Strings = (
      'None'
      'Simple'
      'List'
      'Order')
    LabelCaption = 'Playlist shuffle'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -11
    LabelFont.Name = 'Tahoma'
    LabelFont.Style = []
    TabOrder = 0
    OnChange = ACBX_PlaylistRandomChange
  end
  object ACBX_GroupRandom: TAdvComboBox
    AlignWithMargins = True
    Left = 72
    Top = 79
    Width = 272
    Height = 21
    Color = clWindow
    Version = '1.6.2.1'
    Visible = True
    Align = alTop
    ButtonWidth = 17
    Style = csDropDownList
    EmptyTextStyle = []
    DropWidth = 0
    Enabled = True
    ItemIndex = -1
    Items.Strings = (
      'None'
      'Simple'
      'List'
      'Order')
    LabelCaption = 'Group shuffle'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -11
    LabelFont.Name = 'Tahoma'
    LabelFont.Style = []
    TabOrder = 1
    OnChange = ACBX_GroupRandomChange
  end
  object ACBX_TrackRandom: TAdvComboBox
    AlignWithMargins = True
    Left = 69
    Top = 106
    Width = 275
    Height = 21
    Color = clWindow
    Version = '1.6.2.1'
    Visible = True
    Align = alTop
    ButtonWidth = 17
    Style = csDropDownList
    EmptyTextStyle = []
    DropWidth = 0
    Enabled = True
    ItemIndex = -1
    Items.Strings = (
      'None'
      'Simple'
      'List'
      'Order')
    LabelCaption = 'Track shuffle'
    LabelPosition = lpLeftCenter
    LabelFont.Charset = DEFAULT_CHARSET
    LabelFont.Color = clWindowText
    LabelFont.Height = -11
    LabelFont.Name = 'Tahoma'
    LabelFont.Style = []
    TabOrder = 2
    OnChange = ACBX_TrackRandomChange
  end
  object AOCB_Enabled: TAdvOfficeCheckBox
    AlignWithMargins = True
    Left = 3
    Top = 26
    Width = 341
    Height = 20
    Align = alTop
    TabOrder = 3
    OnClick = AOCB_EnabledClick
    Alignment = taLeftJustify
    Caption = 'Enabled'
    ReturnIsTab = False
    Version = '1.4.1.1'
  end
  object CLB_Excluded: TCheckListBox
    AlignWithMargins = True
    Left = 3
    Top = 152
    Width = 341
    Height = 85
    OnClickCheck = CLB_ExcludedClickCheck
    Align = alClient
    ItemHeight = 13
    TabOrder = 4
  end
end
