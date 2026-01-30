module Types exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Set exposing (Set)


type alias DataRegion =
    { start : Int -- Byte offset
    , end : Int -- Byte offset (inclusive)
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
    , dataRegions : List DataRegion
    }


type alias Line =
    { offset : Int
    , address : Int
    , bytes : List Int
    , disassembly : String
    , comment : Maybe String
    , targetAddress : Maybe Int
    , isData : Bool
    , label : Maybe String
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
    , dataRegions = []
    }
