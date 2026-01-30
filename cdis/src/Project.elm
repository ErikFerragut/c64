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
import Types exposing (DataRegion, Model, initModel)


currentVersion : Int
currentVersion =
    3


type alias SaveData =
    { version : Int
    , fileName : String
    , loadAddress : Int
    , comments : List ( Int, String )
    , labels : List ( Int, String )
    , dataRegions : List { start : Int, end : Int }
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
        , ( "dataRegions", JE.list encodeDataRegion data.dataRegions )
        ]


encodeDataRegion : { start : Int, end : Int } -> JE.Value
encodeDataRegion region =
    JE.object
        [ ( "start", JE.int region.start )
        , ( "end", JE.int region.end )
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

        2 ->
            decodeV2

        3 ->
            decodeV3

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
        (JD.succeed [])


decodeV2 : JD.Decoder SaveData
decodeV2 =
    JD.map6 SaveData
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (JD.succeed [])


decodeV3 : JD.Decoder SaveData
decodeV3 =
    JD.map6 SaveData
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "dataRegions" (JD.list decodeDataRegion) [])


decodeDataRegion : JD.Decoder { start : Int, end : Int }
decodeDataRegion =
    JD.map2 (\s e -> { start = s, end = e })
        (JD.field "start" JD.int)
        (JD.field "end" JD.int)


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
    , dataRegions = List.map (\r -> { start = r.start, end = r.end }) model.dataRegions
    }


toModel : SaveData -> Model -> Model
toModel data model =
    { model
        | fileName = data.fileName
        , loadAddress = data.loadAddress
        , comments = Dict.fromList data.comments
        , labels = Dict.fromList data.labels
        , dataRegions = List.map (\r -> { start = r.start, end = r.end }) data.dataRegions
    }
