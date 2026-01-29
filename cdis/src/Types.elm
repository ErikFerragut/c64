module Types exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Set exposing (Set)


type alias Model =
    { bytes : Array Int
    , loadAddress : Int
    , comments : Dict Int String
    , labels : Dict Int String
    , segments : List Segment
    , activeSegment : Maybe Int
    , segmentNameInput : String
    , viewStart : Int
    , viewLines : Int
    , selectedOffset : Maybe Int
    , restartPoints : Set Int
    , fileName : String
    , jumpToInput : String
    , editingComment : Maybe ( Int, String )
    , markingSegmentStart : Maybe Int
    }


type alias Segment =
    { name : String
    , start : Int
    , end : Int
    , segType : SegmentType
    }


type SegmentType
    = Code
    | Data
    | Unknown


type alias Line =
    { offset : Int
    , address : Int
    , bytes : List Int
    , disassembly : String
    , comment : Maybe String
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
    , segments = []
    , activeSegment = Nothing
    , segmentNameInput = ""
    , viewStart = 0
    , viewLines = 40
    , selectedOffset = Nothing
    , restartPoints = Set.empty
    , fileName = ""
    , jumpToInput = ""
    , editingComment = Nothing
    , markingSegmentStart = Nothing
    }
