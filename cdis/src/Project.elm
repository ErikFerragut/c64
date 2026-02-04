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
import Types exposing (Model, Region, RegionType(..), Segment, initModel)


currentVersion : Int
currentVersion =
    6


type alias SaveData =
    { version : Int
    , fileName : String
    , loadAddress : Int
    , comments : List ( Int, String )
    , labels : List ( Int, String )
    , regions : List { start : Int, end : Int, regionType : String }
    , segments : List { start : Int, end : Int }
    , majorComments : List ( Int, String )
    , patches : List ( Int, Int ) -- (offset, newByte) for byte modifications
    , symbols : List ( Int, String ) -- (address, name) for user-defined symbols
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
        , ( "regions", JE.list encodeRegion data.regions )
        , ( "segments", JE.list encodeSegment data.segments )
        , ( "majorComments", JE.list encodeMajorComment data.majorComments )
        , ( "patches", JE.list encodePatch data.patches )
        , ( "symbols", JE.list encodeSymbol data.symbols )
        ]


encodeSymbol : ( Int, String ) -> JE.Value
encodeSymbol ( addr, name ) =
    JE.object
        [ ( "address", JE.int addr )
        , ( "name", JE.string name )
        ]


encodePatch : ( Int, Int ) -> JE.Value
encodePatch ( offset, byte ) =
    JE.object
        [ ( "offset", JE.int offset )
        , ( "byte", JE.int byte )
        ]


encodeRegion : { start : Int, end : Int, regionType : String } -> JE.Value
encodeRegion region =
    JE.object
        [ ( "start", JE.int region.start )
        , ( "end", JE.int region.end )
        , ( "regionType", JE.string region.regionType )
        ]


encodeSegment : { start : Int, end : Int } -> JE.Value
encodeSegment segment =
    JE.object
        [ ( "start", JE.int segment.start )
        , ( "end", JE.int segment.end )
        ]


encodeMajorComment : ( Int, String ) -> JE.Value
encodeMajorComment ( offset, text ) =
    JE.object
        [ ( "offset", JE.int offset )
        , ( "text", JE.string text )
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

        4 ->
            decodeV4

        5 ->
            decodeV5

        6 ->
            decodeV6

        _ ->
            JD.fail ("Unknown save file version: " ++ String.fromInt version)


decodeV1 : JD.Decoder SaveData
decodeV1 =
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (JD.succeed [])
        (JD.succeed [])
        (JD.succeed [])


toSaveDataWithPatches : Int -> String -> Int -> List ( Int, String ) -> List ( Int, String ) -> List { start : Int, end : Int, regionType : String } -> List { start : Int, end : Int } -> List ( Int, String ) -> SaveData
toSaveDataWithPatches version fileName loadAddress comments labels regions segments majorComments =
    { version = version
    , fileName = fileName
    , loadAddress = loadAddress
    , comments = comments
    , labels = labels
    , regions = regions
    , segments = segments
    , majorComments = majorComments
    , patches = []
    , symbols = []
    }


decodeV2 : JD.Decoder SaveData
decodeV2 =
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (JD.succeed [])
        (JD.succeed [])
        (JD.succeed [])


decodeV3 : JD.Decoder SaveData
decodeV3 =
    -- Backward compat: convert dataRegions to regions with type "byte"
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "dataRegions" (JD.list decodeDataRegionAsRegion) [])
        (JD.succeed [])
        (JD.succeed [])


decodeV4 : JD.Decoder SaveData
decodeV4 =
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "regions" (JD.list decodeRegion) [])
        (optionalField "segments" (JD.list decodeSegment) [])
        (optionalField "majorComments" (JD.list decodeMajorComment) [])


decodeV5 : JD.Decoder SaveData
decodeV5 =
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "regions" (JD.list decodeRegion) [])
        (optionalField "segments" (JD.list decodeSegment) [])
        (optionalField "majorComments" (JD.list decodeMajorComment) [])
        |> JD.andThen
            (\partial ->
                optionalField "patches" (JD.list decodePatch) []
                    |> JD.map (\p -> { partial | patches = p })
            )


decodeV6 : JD.Decoder SaveData
decodeV6 =
    JD.map8 toSaveDataWithPatches
        (JD.succeed currentVersion)
        (JD.field "fileName" JD.string)
        (JD.field "loadAddress" JD.int)
        (optionalField "comments" (JD.list decodeComment) [])
        (optionalField "labels" (JD.list decodeLabel) [])
        (optionalField "regions" (JD.list decodeRegion) [])
        (optionalField "segments" (JD.list decodeSegment) [])
        (optionalField "majorComments" (JD.list decodeMajorComment) [])
        |> JD.andThen
            (\partial ->
                optionalField "patches" (JD.list decodePatch) []
                    |> JD.map (\p -> { partial | patches = p })
            )
        |> JD.andThen
            (\partial ->
                optionalField "symbols" (JD.list decodeSymbol) []
                    |> JD.map (\s -> { partial | symbols = s })
            )


decodeSymbol : JD.Decoder ( Int, String )
decodeSymbol =
    JD.map2 Tuple.pair
        (JD.field "address" JD.int)
        (JD.field "name" JD.string)


decodePatch : JD.Decoder ( Int, Int )
decodePatch =
    JD.map2 Tuple.pair
        (JD.field "offset" JD.int)
        (JD.field "byte" JD.int)


decodeDataRegionAsRegion : JD.Decoder { start : Int, end : Int, regionType : String }
decodeDataRegionAsRegion =
    JD.map2 (\s e -> { start = s, end = e, regionType = "byte" })
        (JD.field "start" JD.int)
        (JD.field "end" JD.int)


decodeRegion : JD.Decoder { start : Int, end : Int, regionType : String }
decodeRegion =
    JD.map3 (\s e t -> { start = s, end = e, regionType = t })
        (JD.field "start" JD.int)
        (JD.field "end" JD.int)
        (JD.field "regionType" JD.string)


decodeSegment : JD.Decoder { start : Int, end : Int }
decodeSegment =
    JD.map2 (\s e -> { start = s, end = e })
        (JD.field "start" JD.int)
        (JD.field "end" JD.int)


decodeMajorComment : JD.Decoder ( Int, String )
decodeMajorComment =
    JD.map2 Tuple.pair
        (JD.field "offset" JD.int)
        (JD.field "text" JD.string)


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


regionTypeToString : RegionType -> String
regionTypeToString rt =
    case rt of
        ByteRegion ->
            "byte"

        TextRegion ->
            "text"


stringToRegionType : String -> RegionType
stringToRegionType s =
    case s of
        "text" ->
            TextRegion

        _ ->
            ByteRegion


fromModel : Model -> SaveData
fromModel model =
    { version = currentVersion
    , fileName = model.fileName
    , loadAddress = model.loadAddress
    , comments = Dict.toList model.comments
    , labels = Dict.toList model.labels
    , regions =
        List.map
            (\r ->
                { start = r.start
                , end = r.end
                , regionType = regionTypeToString r.regionType
                }
            )
            model.regions
    , segments = List.map (\s -> { start = s.start, end = s.end }) model.segments
    , majorComments = Dict.toList model.majorComments
    , patches = Dict.toList model.patches
    , symbols = Dict.toList model.symbols
    }


toModel : SaveData -> Model -> Model
toModel data model =
    let
        patchesDict =
            Dict.fromList data.patches

        -- Apply patches to bytes
        patchedBytes =
            List.foldl
                (\( offset, byte ) bytes -> Array.set offset byte bytes)
                model.bytes
                data.patches
    in
    { model
        | fileName = data.fileName
        , loadAddress = data.loadAddress
        , comments = Dict.fromList data.comments
        , labels = Dict.fromList data.labels
        , regions =
            List.map
                (\r ->
                    { start = r.start
                    , end = r.end
                    , regionType = stringToRegionType r.regionType
                    }
                )
                data.regions
        , segments = List.map (\s -> { start = s.start, end = s.end }) data.segments
        , majorComments = Dict.fromList data.majorComments
        , patches = patchesDict
        , bytes = patchedBytes
        , symbols = Dict.fromList data.symbols
    }
