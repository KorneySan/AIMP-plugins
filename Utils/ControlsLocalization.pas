unit ControlsLocalization;

interface

uses Classes, Controls;

const
 lciwKeyName = 0;
 lciwDefaultText = 1;

type
 TLocalizedText = function (const Key: WideString): WideString of object;

 TLocalizedControl = class(TCollectionItem)
  private
   FKeyName: ShortString;
   FDefaultText: WideString;
   FControl: TControl;
  public
   constructor Create(Collection: TCollection); override;
   procedure Assign(Source: TPersistent); override;
  published
   property KeyName: ShortString read FKeyName write FKeyName;
   property DefaultText: WideString read FDefaultText write FDefaultText;
   property Control: TControl read FControl write FControl;
 end;

 TLocalizedControls = class(TCollection)
  private
   FLocalizedText: TLocalizedText;
   function GetItem(Index: Integer): TLocalizedControl;
   procedure SetItem(Index: Integer; const Value: TLocalizedControl);
  public
   function Add: TLocalizedControl;
   function Insert(Index: Integer): TLocalizedControl;
   property Items[Index: Integer]: TLocalizedControl read GetItem write SetItem; default;
   //
   function IndexOfText(const ID: ShortString; What: Integer = lciwKeyName): Integer;
   function AddControl(const AControl: TControl; const ADefaultText: WideString; AKeyName: ShortString = ''): Integer; overload;
   function AddControl(const ADefaultText, APrefix: WideString; const AControl: TControl): Integer; overload;
   procedure SaveToFile(const Filename, Section: string);
   property LocalizedText: TLocalizedText read FLocalizedText write FLocalizedText default nil;
   procedure LocalizeControls;
 end;

implementation

uses
 SysUtils, IniFiles, TypInfo;

 { TLocalizedControl }

constructor TLocalizedControl.Create(Collection: TCollection);
begin
 inherited Create(Collection);
 FKeyName:='';
 FDefaultText:='';
 FControl:=nil;
end;

procedure TLocalizedControl.Assign(Source: TPersistent);
begin
 if Assigned(Source) then
  begin
   if Source.ClassNameIs(Self.ClassName) then
    begin
     Self.KeyName:=(Source as TLocalizedControl).KeyName;
     Self.DefaultText:=(Source as TLocalizedControl).DefaultText;
     Self.Control:=(Source as TLocalizedControl).Control;
    end
   else
     inherited Assign(Source);
  end;
end;

 { TLocalizedControls }

function TLocalizedControls.Add: TLocalizedControl;
begin
 Result := TLocalizedControl(inherited Add);
end;

function TLocalizedControls.AddControl(const ADefaultText, APrefix: WideString;
  const AControl: TControl): Integer;
 var
  lci: TLocalizedControl;
begin
 if (ADefaultText<>'') and Assigned(AControl) then
  begin
   lci:=Add;
   lci.KeyName:=APrefix+AControl.Name;
   lci.DefaultText:=ADefaultText;
   lci.Control:=AControl;
   Result:=lci.Index;
  end
 else
   Result:=-1;
end;

function TLocalizedControls.GetItem(Index: Integer): TLocalizedControl;
begin
 Result := TLocalizedControl(inherited Items[Index]);
end;

function TLocalizedControls.Insert(Index: Integer): TLocalizedControl;
begin
 Result := TLocalizedControl(inherited Insert(Index));
end;

procedure TLocalizedControls.SetItem(Index: Integer; const Value: TLocalizedControl);
begin
 Items[Index].Assign(Value);
end;

function TLocalizedControls.IndexOfText(const ID: ShortString; What: Integer = lciwKeyName): Integer;
 var
  b: Boolean;
begin
 if What in [lciwKeyName..lciwDefaultText] then
  begin
   Result:=Self.Count-1;
   repeat
    if Result>=0 then
     begin
      case What of
       lciwKeyName: b:=SameStr(Items[Result].KeyName, ID);
       lciwDefaultText: b:=SameStr(Items[Result].DefaultText, ID);
       else b:=false;
      end;
      if b then
        Break
      else
        Dec(Result);
     end;
   until Result<0;
  end
 else
   Result:=-2;
end;

function TLocalizedControls.AddControl(const AControl: TControl; const ADefaultText: WideString; AKeyName: ShortString = ''): Integer;
 var
  lci: TLocalizedControl;
begin
 if (ADefaultText<>'') and Assigned(AControl) then
  begin
   lci:=Add;
   lci.KeyName:=AKeyName;
   lci.DefaultText:=ADefaultText;
   lci.Control:=AControl;
   Result:=lci.Index;
  end
 else
   Result:=-1;
end;

procedure TLocalizedControls.SaveToFile(const Filename, Section: string);
 var
  i: Integer;
  Ini: TIniFile;
  lci: TLocalizedControl;
begin
 if (Filename<>'') and (Section<>'') then
  begin
   Ini:=TIniFile.Create(Filename);
   for i := 0 to Count-1 do
    begin
     lci:=Items[i];
     if lci.KeyName='' then
       Ini.WriteString(Section, lci.DefaultText, lci.DefaultText)
     else
       Ini.WriteString(Section, lci.KeyName, lci.DefaultText);
    end;
   Ini.UpdateFile;
   FreeAndNil(Ini);
   lci:=nil;
  end;
end;

procedure TLocalizedControls.LocalizeControls;
 var
  i: Integer;
  pi: PPropInfo;
  lci: TLocalizedControl;
  s: WideString;
begin
 if Assigned(FLocalizedText) then
  begin
   for i := 0 to Count-1 do
    begin
     lci:=Items[i];
     if Assigned(lci.Control) then
      begin
       if lci.KeyName='' then
         s:=LocalizedText(lci.DefaultText)
       else
         s:=LocalizedText(lci.KeyName);
       if s='' then
         s:=lci.DefaultText;
       pi:=GetPropInfo(lci.Control.ClassInfo, 'Caption');
       if Assigned(pi) then
         SetPropValue(lci.Control, 'Caption', s)
       else
        begin
         pi:=GetPropInfo(lci.Control.ClassInfo, 'LabelCaption');
         if Assigned(pi) then
           SetPropValue(lci.Control, 'LabelCaption', s)
         else
          begin
           pi:=GetPropInfo(lci.Control.ClassInfo, 'Hint');
           if Assigned(pi) then
             SetPropValue(lci.Control, 'Hint', s)
          end;
        end;
      end;
    end;
   pi:=nil;
   lci:=nil;
  end;
end;

end.
