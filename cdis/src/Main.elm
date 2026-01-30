port module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Dom as Dom
import Dict exposing (Dict)
import Disassembler exposing (disassembleRange)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD
import Json.Encode as JE
import Opcodes exposing (opcodeBytes)
import Project
import Task
import Types exposing (..)



-- PORTS


port requestPrgFile : () -> Cmd msg


port prgFileOpened : (JE.Value -> msg) -> Sub msg


port saveCdisFile : String -> Cmd msg


port cdisSaved : (() -> msg) -> Sub msg


port showError : (String -> msg) -> Sub msg


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
    = RequestFile
    | PrgFileOpened JE.Value
    | Scroll Int
    | JumpToAddress
    | JumpToInputChanged String
    | SelectLine Int
    | StartEditComment Int
    | UpdateEditComment String
    | SaveComment
    | CancelEditComment
    | KeyPressed KeyEvent
    | ToggleHelp
    | SelectNextLine
    | SelectPrevLine
    | SaveProject
    | CdisSaved
    | ErrorOccurred String
    | FocusResult
    | NoOp



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FocusResult ->
            ( model, Cmd.none )

        RequestFile ->
            ( model, requestPrgFile () )

        PrgFileOpened value ->
            case JD.decodeValue prgFileDecoder value of
                Ok data ->
                    let
                        loadAddr =
                            Maybe.withDefault 0 (List.head data.bytes)
                                + (Maybe.withDefault 0 (List.head (List.drop 1 data.bytes)) * 256)

                        programBytes =
                            List.drop 2 data.bytes

                        baseModel =
                            { initModel
                                | bytes = Array.fromList programBytes
                                , loadAddress = loadAddr
                                , fileName = data.fileName
                                , viewStart = 0
                                , selectedOffset = Just 0
                            }

                        finalModel =
                            case data.cdisContent of
                                Just jsonStr ->
                                    case JD.decodeString Project.decoder jsonStr of
                                        Ok saveData ->
                                            Project.toModel saveData baseModel

                                        Err _ ->
                                            baseModel

                                Nothing ->
                                    baseModel
                    in
                    ( ensureSelectionVisible finalModel
                    , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                    )

                Err _ ->
                    ( model, Cmd.none )

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
            ( ensureSelectionVisible { model | selectedOffset = Just offset }, Cmd.none )

        StartEditComment offset ->
            let
                existingComment =
                    Dict.get offset model.comments |> Maybe.withDefault ""
            in
            ( { model | editingComment = Just ( offset, existingComment ) }
            , Task.attempt (\_ -> NoOp) (Dom.focus "comment-input")
            )

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
                        , dirty = True
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditComment ->
            ( { model | editingComment = Nothing }, Cmd.none )

        KeyPressed event ->
            if model.editingComment /= Nothing then
                ( model, Cmd.none )

            else
                case event.key of
                    "l" ->
                        centerSelectedLine model

                    "c" ->
                        case model.selectedOffset of
                            Just offset ->
                                update (StartEditComment offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    "s" ->
                        update SaveProject model

                    "Escape" ->
                        ( model, Cmd.none )

                    "?" ->
                        update ToggleHelp model

                    "ArrowDown" ->
                        update SelectNextLine model

                    "ArrowUp" ->
                        update SelectPrevLine model

                    _ ->
                        ( model, Cmd.none )

        ToggleHelp ->
            ( { model | helpExpanded = not model.helpExpanded }, Cmd.none )

        SelectNextLine ->
            case model.selectedOffset of
                Just offset ->
                    let
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
                        ( ensureSelectionVisible { model | selectedOffset = Just newOffset }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( ensureSelectionVisible { model | selectedOffset = Just 0 }, Cmd.none )

        SelectPrevLine ->
            case model.selectedOffset of
                Just offset ->
                    if offset > 0 then
                        let
                            newOffset =
                                findPrevInstructionStart model.bytes (offset - 1)
                        in
                        ( ensureSelectionVisible { model | selectedOffset = Just newOffset }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( ensureSelectionVisible { model | selectedOffset = Just 0 }, Cmd.none )

        SaveProject ->
            if Array.isEmpty model.bytes then
                ( model, Cmd.none )

            else
                let
                    saveData =
                        Project.fromModel model

                    json =
                        Project.encode saveData
                            |> JE.encode 2
                in
                ( model, saveCdisFile json )

        CdisSaved ->
            ( { model | dirty = False }, Cmd.none )

        ErrorOccurred errorMsg ->
            -- For now just log to console via the port
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


type alias PrgFileData =
    { fileName : String
    , bytes : List Int
    , cdisContent : Maybe String
    }


prgFileDecoder : JD.Decoder PrgFileData
prgFileDecoder =
    JD.map3 PrgFileData
        (JD.field "fileName" JD.string)
        (JD.field "bytes" (JD.list JD.int))
        (JD.field "cdisContent" (JD.nullable JD.string))


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


ensureSelectionVisible : Model -> Model
ensureSelectionVisible model =
    case model.selectedOffset of
        Just offset ->
            let
                margin =
                    2

                tooHigh =
                    offset < model.viewStart + margin

                tooLow =
                    offset >= model.viewStart + model.viewLines - margin

                maxViewStart =
                    Basics.max 0 (Array.length model.bytes - model.viewLines)
            in
            if tooHigh then
                { model | viewStart = Basics.max 0 (offset - margin) }

            else if tooLow then
                { model | viewStart = Basics.min maxViewStart (offset - model.viewLines + margin + 1) }

            else
                model

        Nothing ->
            model


findPrevInstructionStart : Array Int -> Int -> Int
findPrevInstructionStart bytes targetOffset =
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
    Sub.batch
        [ prgFileOpened PrgFileOpened
        , cdisSaved (\_ -> CdisSaved)
        , showError ErrorOccurred
        ]


keyDecoder : JD.Decoder Msg
keyDecoder =
    JD.map4 KeyEvent
        (JD.field "key" JD.string)
        (JD.field "ctrlKey" JD.bool)
        (JD.field "altKey" JD.bool)
        (JD.field "shiftKey" JD.bool)
        |> JD.map KeyPressed


onKeyDownPreventDefault : Attribute Msg
onKeyDownPreventDefault =
    let
        decoder =
            keyDecoder
                |> JD.map
                    (\msg ->
                        case msg of
                            KeyPressed event ->
                                if List.member event.key [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight" ] then
                                    ( msg, True )

                                else
                                    ( msg, False )

                            _ ->
                                ( msg, False )
                    )
    in
    preventDefaultOn "keydown" decoder



-- VIEW


view : Model -> Html Msg
view model =
    if Array.isEmpty model.bytes then
        viewFilePrompt

    else
        div
            [ class "cdis-app"
            , tabindex 0
            , id "cdis-main"
            , onKeyDownPreventDefault
            ]
            [ viewHeader model
            , viewToolbar model
            , viewDisassembly model
            , viewFooter model
            ]


viewFilePrompt : Html Msg
viewFilePrompt =
    div [ class "cdis-app file-prompt" ]
        [ div [ class "prompt-content" ]
            [ h1 [] [ text "CDis" ]
            , p [] [ text "C64 Disassembler" ]
            , button [ class "load-button", onClick RequestFile ] [ text "Open PRG File" ]
            ]
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    let
        dirtyIndicator =
            if model.dirty then
                " *"

            else
                ""
    in
    header [ class "cdis-header" ]
        [ h1 [] [ text "CDis" ]
        , span [ class "subtitle" ] [ text "C64 Disassembler" ]
        , if String.isEmpty model.fileName then
            text ""

          else
            span [ class "filename" ] [ text (" - " ++ model.fileName ++ dirtyIndicator) ]
        ]


viewToolbar : Model -> Html Msg
viewToolbar model =
    div [ class "toolbar" ]
        [ label []
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


viewDisassembly : Model -> Html Msg
viewDisassembly model =
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
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "↑ / ↓" ], text "Prev/Next line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Mouse wheel" ], text "Scroll" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "L" ], text "Center selected line" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Editing" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Click" ], text "Select line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "C" ], text "Edit comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Double-click" ], text "Edit comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Enter" ], text "Save comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Escape" ], text "Cancel" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "File" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "S" ], text "Save project" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "?" ], text "Toggle this help" ]
                    ]
                ]
            ]

    else
        footer [ class "cdis-footer" ]
            [ span []
                [ text "?: Help | "
                , text "↑↓: Navigate | "
                , text "C: Comment | "
                , text "L: Center | "
                , text "S: Save"
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
