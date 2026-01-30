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
import Types exposing (Model, initModel)


currentVersion : Int
currentVersion =
    2


type alias SaveData =
    { version : Int
    , fileName : String
    , loadAddress : Int
    , comments : List ( Int, String )
    , labels : List ( Int, String )
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

        _ ->
            JD.fail ("Unknown save file version: " ++ String.fromInt version)


decodeV1 : JD.Decoder SaveData
decodeV1 =
    JD.map5 SaveData
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])


decodeV2 : JD.Decoder SaveData
decodeV2 =
    JD.map5 SaveData
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])


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
    }


toModel : SaveData -> Model -> Model
toModel data model =
    { model
        | fileName = data.fileName
        , loadAddress = data.loadAddress
        , comments = Dict.fromList data.comments
        , labels = Dict.fromList data.labels
    }
