module Project exposing
    ( SaveData
    , currentVersion
    , encode
    , decoder
    , fromModel
    , toModel
    )

import Array
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import Types exposing (Model, Segment, SegmentType(..), initModel)


currentVersion : Int
currentVersion =
    1


type alias SaveData =
    { version : Int
    , fileName : String
    , loadAddress : Int
    , comments : List ( Int, String )
    , labels : List ( Int, String )
    , segments : List SegmentSave
    }


type alias SegmentSave =
    { name : String
    , start : Int
    , end : Int
    , segType : String
    }



-- ENCODE


encode : SaveData -> JE.Value
encode data =
    JE.object
        [ ( "version", JE.int data.version )
        , ( "fileName", JE.string data.fileName )
        , ( "loadAddress", JE.int data.loadAddress )
        , ( "comments", JE.list encodeComment data.comments )
        , ( "labels", JE.list encodeLabel data.labels )
        , ( "segments", JE.list encodeSegment data.segments )
        ]


encodeComment : ( Int, String ) -> JE.Value
encodeComment ( offset, text ) =
    JE.object
        [ ( "offset", JE.int offset )
        , ( "text", JE.string text )
        ]


encodeLabel : ( Int, String ) -> JE.Value
encodeLabel ( addr, name ) =
    JE.object
        [ ( "address", JE.int addr )
        , ( "name", JE.string name )
        ]


encodeSegment : SegmentSave -> JE.Value
encodeSegment seg =
    JE.object
        [ ( "name", JE.string seg.name )
        , ( "start", JE.int seg.start )
        , ( "end", JE.int seg.end )
        , ( "type", JE.string seg.segType )
        ]



-- DECODE


decoder : JD.Decoder SaveData
decoder =
    JD.field "version" JD.int
        |> JD.andThen decoderForVersion


decoderForVersion : Int -> JD.Decoder SaveData
decoderForVersion version =
    case version of
        1 ->
            decodeV1

        _ ->
            JD.fail ("Unknown save file version: " ++ String.fromInt version)


decodeV1 : JD.Decoder SaveData
decodeV1 =
    JD.map6 SaveData
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "segments" (JD.list decodeSegment) [])


decodeComment : JD.Decoder ( Int, String )
decodeComment =
    JD.map2 Tuple.pair
        (JD.field "offset" JD.int)
        (JD.field "text" JD.string)


decodeLabel : JD.Decoder ( Int, String )
decodeLabel =
    JD.map2 Tuple.pair
        (JD.field "address" JD.int)
        (JD.field "name" JD.string)


decodeSegment : JD.Decoder SegmentSave
decodeSegment =
    JD.map4 SegmentSave
        (JD.field "name" JD.string)
        (JD.field "start" JD.int)
        (JD.field "end" JD.int)
        (optionalField "type" JD.string "code")


optionalField : String -> JD.Decoder a -> a -> JD.Decoder a
optionalField field dec default =
    JD.maybe (JD.field field dec)
        |> JD.map (Maybe.withDefault default)



-- CONVERT


fromModel : Model -> SaveData
fromModel model =
    { version = currentVersion
    , fileName = model.fileName
    , loadAddress = model.loadAddress
    , comments = Dict.toList model.comments
    , labels = Dict.toList model.labels
    , segments = List.map segmentToSave model.segments
    }


segmentToSave : Segment -> SegmentSave
segmentToSave seg =
    { name = seg.name
    , start = seg.start
    , end = seg.end
    , segType = segmentTypeToString seg.segType
    }


segmentTypeToString : SegmentType -> String
segmentTypeToString st =
    case st of
        Code ->
            "code"

        Data ->
            "data"

        Unknown ->
            "unknown"


toModel : SaveData -> Model -> Model
toModel data model =
    { model
        | fileName = data.fileName
        , loadAddress = data.loadAddress
        , comments = Dict.fromList data.comments
        , labels = Dict.fromList data.labels
        , segments = List.map segmentFromSave data.segments
    }


segmentFromSave : SegmentSave -> Segment
segmentFromSave seg =
    { name = seg.name
    , start = seg.start
    , end = seg.end
    , segType = stringToSegmentType seg.segType
    }


stringToSegmentType : String -> SegmentType
stringToSegmentType str =
    case str of
        "code" ->
            Code

        "data" ->
            Data

        _ ->
            Unknown
