module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Events as Events
import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Dict exposing (Dict)
import Disassembler exposing (disassembleRange)
import File exposing (File)
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD
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
            -- Ignore keypresses while editing a comment
            if model.editingComment /= Nothing then
                ( model, Cmd.none )

            else
                case event.key of
                    "l" ->
                        -- l: center selected line on screen
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

                    _ ->
                        ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



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
        [ button [ onClick FileRequested ] [ text "Load PRG" ]
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


viewDisassembly : Model -> Html Msg
viewDisassembly model =
    if Array.isEmpty model.bytes then
        div [ class "disassembly empty" ]
            [ p [] [ text "No file loaded." ]
            , p [] [ text "Click 'Load PRG' to open a C64 program file." ]
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
    footer [ class "cdis-footer" ]
        [ span []
            [ text "Scroll: Mouse wheel | "
            , text "Select: Click | "
            , text "Comment: Double-click | "
            , text "L: Center selection"
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
