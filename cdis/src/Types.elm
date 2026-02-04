module Types exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Set exposing (Set)


type RegionType
    = ByteRegion -- .byte $XX
    | TextRegion -- .text "ABC" (PETSCII)


type EditType
    = EditByte
    | EditText
    | EditInstruction


type ConverterMode
    = DecToHex
    | HexToDec


type alias Region =
    { start : Int -- Byte offset
    , end : Int -- Byte offset (inclusive)
    , regionType : RegionType
    }


type alias Segment =
    { start : Int
    , end : Int
    }


type alias Model =
    { bytes : Array Int
    , loadAddress : Int
    , comments : Dict Int String
    , labels : Dict Int String
    , viewStart : Int
    , viewLines : Int
    , selectedOffset : Maybe Int
    , restartPoints : Set Int
    , fileName : String
    , gotoMode : Bool
    , gotoInput : String
    , gotoError : Bool
    , confirmQuit : Bool
    , editingComment : Maybe ( Int, String )
    , editingLabel : Maybe ( Int, String ) -- (address, label text)
    , helpExpanded : Bool
    , dirty : Bool
    , mark : Maybe Int -- Emacs-style mark position (offset)
    , regions : List Region
    , segments : List Segment
    , majorComments : Dict Int String -- offset -> multiline string
    , editingMajorComment : Maybe ( Int, String )
    , outlineMode : Bool
    , outlineSelection : Int -- Index in segment list
    , jumpHistory : List Int -- Stack of offsets to jump back to
    , patches : Dict Int Int -- offset -> new byte value (for persistence)
    , editingInstruction : Maybe ( Int, String ) -- (offset, current input text)
    , editError : Maybe String -- Error message from assembler
    , editType : Maybe EditType -- What type of value we're editing
    , converterMode : Maybe ConverterMode -- d: dec->hex, h: hex->dec
    , converterInput : String
    }


type alias Line =
    { offset : Int
    , address : Int
    , bytes : List Int
    , disassembly : String
    , comment : Maybe String
    , targetAddress : Maybe Int
    , isData : Bool -- For byte regions
    , isText : Bool -- For text regions
    , label : Maybe String
    , majorComment : Maybe String -- Major comment above this line
    , inSegment : Bool -- Whether this line is in a segment
    }


type AddressingMode
    = Implied
    | Accumulator
    | Immediate
    | ZeroPage
    | ZeroPageX
    | ZeroPageY
    | Absolute
    | AbsoluteX
    | AbsoluteY
    | Indirect
    | IndirectX
    | IndirectY
    | Relative


type alias OpcodeInfo =
    { mnemonic : String
    , mode : AddressingMode
    , bytes : Int
    , cycles : Int
    , undocumented : Bool
    }


initModel : Model
initModel =
    { bytes = Array.empty
    , loadAddress = 0
    , comments = Dict.empty
    , labels = Dict.empty
    , viewStart = 0
    , viewLines = 25
    , selectedOffset = Nothing
    , restartPoints = Set.empty
    , fileName = ""
    , gotoMode = False
    , gotoInput = ""
    , gotoError = False
    , confirmQuit = False
    , editingComment = Nothing
    , editingLabel = Nothing
    , helpExpanded = False
    , dirty = False
    , mark = Nothing
    , regions = []
    , segments = []
    , majorComments = Dict.empty
    , editingMajorComment = Nothing
    , outlineMode = False
    , outlineSelection = 0
    , jumpHistory = []
    , patches = Dict.empty
    , editingInstruction = Nothing
    , editError = Nothing
    , editType = Nothing
    , converterMode = Nothing
    , converterInput = ""
    }
