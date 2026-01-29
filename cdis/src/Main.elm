module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Events as Events
import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Dict exposing (Dict)
import Disassembler exposing (disassembleRange)
import Opcodes exposing (opcodeBytes)
import File exposing (File)
import File.Download as Download
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD
import Json.Encode as JE
import Project
import Task
import Types exposing (..)


type alias KeyEvent =
    { key : String
    , ctrl : Bool
    , alt : Bool
    , shift : Bool
    }



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel, Cmd.none )



-- MESSAGES


type Msg
    = FileRequested
    | FileSelected File
    | FileLoaded Bytes
    | Scroll Int
    | JumpToAddress
    | JumpToInputChanged String
    | SelectLine Int
    | StartEditComment Int
    | UpdateEditComment String
    | SaveComment
    | CancelEditComment
    | SetRestartPoint Int
    | KeyPressed KeyEvent
    | SelectSegment (Maybe Int)
    | NextSegment
    | PrevSegment
    | MarkSegmentStart
    | CreateSegment
    | UpdateSegmentName String
    | CancelSegmentCreate
    | DeleteSegment Int
    | ToggleHelp
    | SelectNextLine
    | SelectPrevLine
    | SaveProject
    | LoadProjectRequested
    | LoadProjectSelected File
    | LoadProjectLoaded String
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FileRequested ->
            ( model
            , Select.file [ "application/octet-stream", ".prg" ] FileSelected
            )

        FileSelected file ->
            ( { model | fileName = File.name file }
            , Task.perform FileLoaded (File.toBytes file)
            )

        FileLoaded bytes ->
            let
                decoded =
                    decodeBytes bytes

                loadAddr =
                    Maybe.withDefault 0 (List.head decoded)
                        + (Maybe.withDefault 0 (List.head (List.drop 1 decoded)) * 256)

                -- Skip the 2-byte load address header
                programBytes =
                    List.drop 2 decoded
            in
            ( { model
                | bytes = Array.fromList programBytes
                , loadAddress = loadAddr
                , viewStart = 0
                , selectedOffset = Just 0
              }
            , Cmd.none
            )

        Scroll delta ->
            let
                maxOffset =
                    Basics.max 0 (Array.length model.bytes - model.viewLines)

                newStart =
                    clamp 0 maxOffset (model.viewStart + delta)
            in
            ( { model | viewStart = newStart }, Cmd.none )

        JumpToAddress ->
            case parseHex model.jumpToInput of
                Just addr ->
                    let
                        offset =
                            addr - model.loadAddress
                    in
                    if offset >= 0 && offset < Array.length model.bytes then
                        ( { model | viewStart = offset, jumpToInput = "" }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        JumpToInputChanged str ->
            ( { model | jumpToInput = str }, Cmd.none )

        SelectLine offset ->
            ( { model | selectedOffset = Just offset }, Cmd.none )

        StartEditComment offset ->
            let
                existingComment =
                    Dict.get offset model.comments |> Maybe.withDefault ""
            in
            ( { model | editingComment = Just ( offset, existingComment ) }, Cmd.none )

        UpdateEditComment text ->
            case model.editingComment of
                Just ( offset, _ ) ->
                    ( { model | editingComment = Just ( offset, text ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveComment ->
            case model.editingComment of
                Just ( offset, text ) ->
                    let
                        newComments =
                            if String.isEmpty (String.trim text) then
                                Dict.remove offset model.comments

                            else
                                Dict.insert offset text model.comments
                    in
                    ( { model
                        | comments = newComments
                        , editingComment = Nothing
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditComment ->
            ( { model | editingComment = Nothing }, Cmd.none )

        SetRestartPoint offset ->
            ( model, Cmd.none )

        KeyPressed event ->
            -- Ignore keypresses while editing a comment or naming a segment
            if model.editingComment /= Nothing || model.markingSegmentStart /= Nothing then
                ( model, Cmd.none )

            else
                case event.key of
                    "l" ->
                        -- l: center selected line on screen
                        centerSelectedLine model

                    "[" ->
                        -- [: previous segment
                        update PrevSegment model

                    "]" ->
                        -- ]: next segment
                        update NextSegment model

                    "s" ->
                        -- s: mark segment start at selected line
                        update MarkSegmentStart model

                    "Escape" ->
                        -- Escape: clear segment marking
                        ( { model | markingSegmentStart = Nothing }, Cmd.none )

                    "?" ->
                        -- ?: toggle help
                        update ToggleHelp model

                    "o" ->
                        -- o: open PRG file
                        update FileRequested model

                    "j" ->
                        -- j: next line
                        update SelectNextLine model

                    "k" ->
                        -- k: previous line
                        update SelectPrevLine model

                    _ ->
                        ( model, Cmd.none )

        SelectSegment maybeIndex ->
            case maybeIndex of
                Just index ->
                    case List.drop index model.segments |> List.head of
                        Just segment ->
                            ( { model
                                | activeSegment = maybeIndex
                                , viewStart = segment.start
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    -- "All" selected
                    ( { model | activeSegment = Nothing }, Cmd.none )

        NextSegment ->
            let
                nextIndex =
                    case model.activeSegment of
                        Nothing ->
                            if List.isEmpty model.segments then
                                Nothing
                            else
                                Just 0

                        Just i ->
                            if i + 1 < List.length model.segments then
                                Just (i + 1)
                            else
                                Just i
            in
            update (SelectSegment nextIndex) model

        PrevSegment ->
            let
                prevIndex =
                    case model.activeSegment of
                        Nothing ->
                            Nothing

                        Just i ->
                            if i > 0 then
                                Just (i - 1)
                            else
                                Nothing
            in
            update (SelectSegment prevIndex) model

        MarkSegmentStart ->
            case model.selectedOffset of
                Just offset ->
                    ( { model | markingSegmentStart = Just offset }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        CreateSegment ->
            case ( model.markingSegmentStart, model.selectedOffset ) of
                ( Just startOffset, Just endOffset ) ->
                    let
                        ( actualStart, actualEnd ) =
                            if startOffset <= endOffset then
                                ( startOffset, endOffset )
                            else
                                ( endOffset, startOffset )

                        segmentName =
                            if String.isEmpty model.segmentNameInput then
                                "$" ++ toHex 4 (model.loadAddress + actualStart)
                            else
                                model.segmentNameInput

                        newSegment =
                            { name = segmentName
                            , start = actualStart
                            , end = actualEnd
                            , segType = Code
                            }

                        newSegments =
                            model.segments
                                ++ [ newSegment ]
                                |> List.sortBy .start
                    in
                    ( { model
                        | segments = newSegments
                        , markingSegmentStart = Nothing
                        , segmentNameInput = ""
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        UpdateSegmentName name ->
            ( { model | segmentNameInput = name }, Cmd.none )

        CancelSegmentCreate ->
            ( { model | markingSegmentStart = Nothing, segmentNameInput = "" }, Cmd.none )

        DeleteSegment index ->
            let
                newSegments =
                    List.indexedMap Tuple.pair model.segments
                        |> List.filter (\( i, _ ) -> i /= index)
                        |> List.map Tuple.second

                newActiveSegment =
                    case model.activeSegment of
                        Just i ->
                            if i == index then
                                Nothing
                            else if i > index then
                                Just (i - 1)
                            else
                                Just i

                        Nothing ->
                            Nothing
            in
            ( { model | segments = newSegments, activeSegment = newActiveSegment }, Cmd.none )

        ToggleHelp ->
            ( { model | helpExpanded = not model.helpExpanded }, Cmd.none )

        SelectNextLine ->
            case model.selectedOffset of
                Just offset ->
                    let
                        -- Get instruction length at current offset
                        instrLen =
                            Array.get offset model.bytes
                                |> Maybe.map opcodeBytes
                                |> Maybe.withDefault 1

                        newOffset =
                            offset + instrLen

                        maxOffset =
                            Array.length model.bytes - 1
                    in
                    if newOffset <= maxOffset then
                        let
                            -- Auto-scroll if selection goes below visible area
                            newViewStart =
                                if newOffset >= model.viewStart + model.viewLines - 2 then
                                    Basics.min (maxOffset - model.viewLines + 1) (model.viewStart + 3)
                                else
                                    model.viewStart
                        in
                        ( { model
                            | selectedOffset = Just newOffset
                            , viewStart = Basics.max 0 newViewStart
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( { model | selectedOffset = Just 0 }, Cmd.none )

        SelectPrevLine ->
            case model.selectedOffset of
                Just offset ->
                    if offset > 0 then
                        let
                            -- Find previous instruction start by scanning backwards
                            -- This is approximate - scan back and find an instruction that lands here
                            newOffset =
                                findPrevInstructionStart model.bytes (offset - 1)

                            -- Auto-scroll if selection goes above visible area
                            newViewStart =
                                if newOffset < model.viewStart + 2 then
                                    Basics.max 0 (model.viewStart - 3)
                                else
                                    model.viewStart
                        in
                        ( { model
                            | selectedOffset = Just newOffset
                            , viewStart = newViewStart
                          }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( { model | selectedOffset = Just 0 }, Cmd.none )

        SaveProject ->
            let
                saveData =
                    Project.fromModel model

                json =
                    Project.encode saveData
                        |> JE.encode 2

                fileName =
                    if String.isEmpty model.fileName then
                        "untitled.cdis"

                    else
                        String.replace ".prg" ".cdis" model.fileName
                            |> (\n ->
                                    if String.endsWith ".cdis" n then
                                        n

                                    else
                                        n ++ ".cdis"
                               )
            in
            ( model, Download.string fileName "application/json" json )

        LoadProjectRequested ->
            ( model, Select.file [ "application/json", ".cdis" ] LoadProjectSelected )

        LoadProjectSelected file ->
            ( model, Task.perform LoadProjectLoaded (File.toString file) )

        LoadProjectLoaded jsonString ->
            case JD.decodeString Project.decoder jsonString of
                Ok saveData ->
                    let
                        newModel =
                            Project.toModel saveData model

                        -- Ensure selection exists if we have bytes
                        withSelection =
                            if Array.isEmpty newModel.bytes then
                                newModel
                            else
                                case newModel.selectedOffset of
                                    Nothing ->
                                        { newModel | selectedOffset = Just 0 }

                                    Just _ ->
                                        newModel
                    in
                    ( withSelection, Cmd.none )

                Err _ ->
                    -- TODO: show error to user
                    ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


centerSelectedLine : Model -> ( Model, Cmd Msg )
centerSelectedLine model =
    case model.selectedOffset of
        Just offset ->
            let
                targetStart =
                    offset - (model.viewLines // 2)

                maxOffset =
                    Basics.max 0 (Array.length model.bytes - model.viewLines)

                newStart =
                    clamp 0 maxOffset targetStart
            in
            ( { model | viewStart = newStart }, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


{-| Find the start of the previous instruction.
    We scan backwards trying offsets until we find one whose instruction length
    would land us at or past the target. This is imperfect but works for linear code.
-}
findPrevInstructionStart : Array Int -> Int -> Int
findPrevInstructionStart bytes targetOffset =
    -- Try 1, 2, 3 bytes back and see which one's instruction ends at target
    let
        try1 =
            targetOffset

        try2 =
            targetOffset - 1

        try3 =
            targetOffset - 2

        lenAt off =
            Array.get off bytes
                |> Maybe.map opcodeBytes
                |> Maybe.withDefault 1
    in
    if try3 >= 0 && lenAt try3 == 3 then
        try3

    else if try2 >= 0 && lenAt try2 == 2 then
        try2

    else if try1 >= 0 then
        try1

    else
        0



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Events.onKeyDown keyDecoder


keyDecoder : JD.Decoder Msg
keyDecoder =
    JD.map4 KeyEvent
        (JD.field "key" JD.string)
        (JD.field "ctrlKey" JD.bool)
        (JD.field "altKey" JD.bool)
        (JD.field "shiftKey" JD.bool)
        |> JD.map KeyPressed



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "cdis-app" ]
        [ viewHeader model
        , viewToolbar model
        , viewSegmentBar model
        , viewSegmentCreateBar model
        , viewDisassembly model
        , viewFooter model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    header [ class "cdis-header" ]
        [ h1 [] [ text "CDis" ]
        , span [ class "subtitle" ] [ text "C64 Disassembler" ]
        , if String.isEmpty model.fileName then
            text ""

          else
            span [ class "filename" ] [ text (" - " ++ model.fileName) ]
        ]


viewToolbar : Model -> Html Msg
viewToolbar model =
    div [ class "toolbar" ]
        [ button [ onClick FileRequested ] [ text "Open PRG" ]
        , button
            [ onClick SaveProject
            , disabled (Array.isEmpty model.bytes)
            ]
            [ text "Save" ]
        , button [ onClick LoadProjectRequested ] [ text "Open" ]
        , span [ class "separator" ] []
        , label []
            [ text "Go to: $"
            , input
                [ type_ "text"
                , placeholder "0800"
                , value model.jumpToInput
                , onInput JumpToInputChanged
                , onKeyDown JumpToAddress
                , maxlength 4
                , class "address-input"
                ]
                []
            ]
        , button [ onClick JumpToAddress ] [ text "Go" ]
        , span [ class "separator" ] []
        , span [ class "info" ]
            [ text ("Load: $" ++ toHex 4 model.loadAddress)
            , text (" | Size: " ++ String.fromInt (Array.length model.bytes) ++ " bytes")
            ]
        ]


viewSegmentBar : Model -> Html Msg
viewSegmentBar model =
    if Array.isEmpty model.bytes then
        text ""

    else
        div [ class "segment-bar" ]
            ([ button
                [ class
                    (if model.activeSegment == Nothing then
                        "segment-tab active"

                     else
                        "segment-tab"
                    )
                , onClick (SelectSegment Nothing)
                ]
                [ text "All" ]
             ]
                ++ List.indexedMap (viewSegmentTab model) model.segments
            )


viewSegmentTab : Model -> Int -> Segment -> Html Msg
viewSegmentTab model index segment =
    let
        isActive =
            model.activeSegment == Just index

        addrStr =
            "$" ++ toHex 4 (model.loadAddress + segment.start)
    in
    span [ class "segment-tab-wrapper" ]
        [ button
            [ class
                (if isActive then
                    "segment-tab active"

                 else
                    "segment-tab"
                )
            , onClick (SelectSegment (Just index))
            ]
            [ text (segment.name ++ " " ++ addrStr) ]
        , button
            [ class "segment-delete"
            , onClick (DeleteSegment index)
            , title "Delete segment"
            ]
            [ text "x" ]
        ]


viewSegmentCreateBar : Model -> Html Msg
viewSegmentCreateBar model =
    case model.markingSegmentStart of
        Nothing ->
            text ""

        Just startOffset ->
            let
                startAddr =
                    "$" ++ toHex 4 (model.loadAddress + startOffset)

                endAddr =
                    case model.selectedOffset of
                        Just endOffset ->
                            "$" ++ toHex 4 (model.loadAddress + endOffset)

                        Nothing ->
                            "..."
            in
            div [ class "segment-create-bar" ]
                [ span [] [ text ("Creating segment: " ++ startAddr ++ " to " ++ endAddr) ]
                , input
                    [ type_ "text"
                    , placeholder "Segment name"
                    , value model.segmentNameInput
                    , onInput UpdateSegmentName
                    , class "segment-name-input"
                    ]
                    []
                , button [ onClick CreateSegment ] [ text "Create" ]
                , button [ onClick CancelSegmentCreate ] [ text "Cancel" ]
                , span [ class "hint" ] [ text "(select end line, then click Create)" ]
                ]


viewDisassembly : Model -> Html Msg
viewDisassembly model =
    if Array.isEmpty model.bytes then
        div [ class "disassembly empty" ]
            [ p [] [ text "No file loaded." ]
            , p [] [ text "Click 'Open PRG' or press O to open a C64 program file." ]
            ]

    else
        let
            lines =
                disassembleRange
                    model.loadAddress
                    model.viewStart
                    model.viewLines
                    model.bytes
                    model.comments
        in
        div
            [ class "disassembly"
            , onWheel Scroll
            ]
            [ viewDisassemblyHeader
            , div [ class "lines" ] (List.map (viewLine model) lines)
            ]


viewDisassemblyHeader : Html Msg
viewDisassemblyHeader =
    div [ class "disasm-header" ]
        [ span [ class "col-address" ] [ text "Address" ]
        , span [ class "col-bytes" ] [ text "Bytes" ]
        , span [ class "col-disasm" ] [ text "Disassembly" ]
        , span [ class "col-comment" ] [ text "Comment" ]
        ]


viewLine : Model -> Line -> Html Msg
viewLine model line =
    let
        isSelected =
            model.selectedOffset == Just line.offset

        lineClass =
            if isSelected then
                "line selected"

            else
                "line"
    in
    div
        [ class lineClass
        , onClick (SelectLine line.offset)
        , onDoubleClick (StartEditComment line.offset)
        ]
        [ span [ class "col-address" ] [ text ("$" ++ toHex 4 line.address) ]
        , span [ class "col-bytes" ] [ text (formatBytes line.bytes) ]
        , span [ class "col-disasm" ] [ text line.disassembly ]
        , viewComment model line
        ]


viewComment : Model -> Line -> Html Msg
viewComment model line =
    case model.editingComment of
        Just ( offset, text_ ) ->
            if offset == line.offset then
                span [ class "col-comment editing" ]
                    [ input
                        [ type_ "text"
                        , value text_
                        , onInput UpdateEditComment
                        , onBlur SaveComment
                        , onKeyDownComment
                        , id "comment-input"
                        , autofocus True
                        ]
                        []
                    ]

            else
                viewCommentText line.comment

        Nothing ->
            viewCommentText line.comment


viewCommentText : Maybe String -> Html Msg
viewCommentText maybeComment =
    span [ class "col-comment" ]
        [ text (maybeComment |> Maybe.map (\c -> "; " ++ c) |> Maybe.withDefault "") ]


viewFooter : Model -> Html Msg
viewFooter model =
    if model.helpExpanded then
        footer [ class "cdis-footer expanded" ]
            [ div [ class "help-grid" ]
                [ div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Navigation" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "J / K" ], text "Next/Prev line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Mouse wheel" ], text "Scroll" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "L" ], text "Center selected line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "[ ]" ], text "Prev/Next segment" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Selection" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Click" ], text "Select line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Double-click" ], text "Edit comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Enter" ], text "Save comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Escape" ], text "Cancel" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Segments" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "S" ], text "Mark segment start" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Escape" ], text "Cancel segment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Tab click" ], text "Jump to segment" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Other" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "O" ], text "Open PRG file" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "?" ], text "Toggle this help" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Go to $" ], text "Jump to address" ]
                    ]
                ]
            ]

    else
        footer [ class "cdis-footer" ]
            [ span []
                [ text "?: Help | "
                , text "Scroll: Wheel | "
                , text "L: Center | "
                , text "S: Segment | "
                , text "[ ]: Nav"
                ]
            ]



-- HELPERS


formatBytes : List Int -> String
formatBytes bytes =
    bytes
        |> List.map (toHex 2)
        |> String.join " "


toHex : Int -> Int -> String
toHex width n =
    let
        hex =
            toHexHelper n ""

        padded =
            String.padLeft width '0' hex
    in
    String.toUpper padded


toHexHelper : Int -> String -> String
toHexHelper n acc =
    if n == 0 && not (String.isEmpty acc) then
        acc

    else if n == 0 then
        "0"

    else
        let
            digit =
                modBy 16 n

            char =
                case digit of
                    10 ->
                        "A"

                    11 ->
                        "B"

                    12 ->
                        "C"

                    13 ->
                        "D"

                    14 ->
                        "E"

                    15 ->
                        "F"

                    _ ->
                        String.fromInt digit
        in
        toHexHelper (n // 16) (char ++ acc)


parseHex : String -> Maybe Int
parseHex str =
    let
        cleaned =
            str
                |> String.trim
                |> String.toUpper
                |> String.replace "$" ""
                |> String.replace "0X" ""
    in
    parseHexHelper (String.toList cleaned) 0


parseHexHelper : List Char -> Int -> Maybe Int
parseHexHelper chars acc =
    case chars of
        [] ->
            if acc > 0 then
                Just acc

            else
                Nothing

        c :: rest ->
            case hexDigitValue c of
                Just v ->
                    parseHexHelper rest (acc * 16 + v)

                Nothing ->
                    Nothing


hexDigitValue : Char -> Maybe Int
hexDigitValue c =
    case c of
        '0' ->
            Just 0

        '1' ->
            Just 1

        '2' ->
            Just 2

        '3' ->
            Just 3

        '4' ->
            Just 4

        '5' ->
            Just 5

        '6' ->
            Just 6

        '7' ->
            Just 7

        '8' ->
            Just 8

        '9' ->
            Just 9

        'A' ->
            Just 10

        'B' ->
            Just 11

        'C' ->
            Just 12

        'D' ->
            Just 13

        'E' ->
            Just 14

        'F' ->
            Just 15

        _ ->
            Nothing


decodeBytes : Bytes -> List Int
decodeBytes bytes =
    let
        len =
            Bytes.width bytes

        decoder =
            Decode.loop ( len, [] ) bytesStep
    in
    Decode.decode decoder bytes
        |> Maybe.withDefault []
        |> List.reverse


bytesStep : ( Int, List Int ) -> Decode.Decoder (Decode.Step ( Int, List Int ) (List Int))
bytesStep ( remaining, acc ) =
    if remaining <= 0 then
        Decode.succeed (Decode.Done acc)

    else
        Decode.unsignedInt8
            |> Decode.map (\b -> Decode.Loop ( remaining - 1, b :: acc ))



-- EVENT HELPERS


onWheel : (Int -> Msg) -> Attribute Msg
onWheel toMsg =
    Html.Events.on "wheel"
        (JD.field "deltaY" JD.float
            |> JD.map
                (\dy ->
                    if dy > 0 then
                        toMsg 3

                    else
                        toMsg -3
                )
        )


onKeyDown : Msg -> Attribute Msg
onKeyDown msg =
    Html.Events.on "keydown"
        (JD.field "key" JD.string
            |> JD.andThen
                (\key ->
                    if key == "Enter" then
                        JD.succeed msg

                    else
                        JD.fail "not enter"
                )
        )


onKeyDownComment : Attribute Msg
onKeyDownComment =
    Html.Events.on "keydown"
        (JD.field "key" JD.string
            |> JD.andThen
                (\key ->
                    if key == "Enter" then
                        JD.succeed SaveComment

                    else if key == "Escape" then
                        JD.succeed CancelEditComment

                    else
                        JD.fail "not enter or escape"
                )
        )
