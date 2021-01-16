unit AdvancedShuffle_Intf;

interface

uses
 apiObjects;

const
  SID_IAdvancedShuffleCustomService = '{B327DB47-170D-465F-B9B5-E0FB3CFE4A64}';
  IID_IAdvancedShuffleService: TGUID = SID_IAdvancedShuffleCustomService;

type
  { IAdvancedShuffleCustomService }

  IAdvancedShuffleCustomService = interface
  [SID_IAdvancedShuffleCustomService]
    function AddPlaylistID(PlaylistID: IAIMPString; out Index: Integer): HRESULT; stdcall;
    function RemovePlaylistID(PlaylistID: IAIMPString; out Index: Integer): HRESULT; stdcall;
  end;
  (*
  Index is a result of operation.
  Index>=0 - playlist with specified ID was found and added as non-randomizable
  Index<0 - playlist with specified ID was not found
  *)

implementation

end.
