port module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Dom as Dom
import Dict exposing (Dict)
import Disassembler exposing (disassemble, disassembleRange)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD
import Json.Encode as JE
import Opcodes exposing (addressingModeString, getOpcode, getOpcodeDescription, getOpcodeFlags, opcodeBytes)
import Project
import Task
import Types exposing (..)


{-| Merge a new data region into the list, combining overlapping/adjacent regions
-}
mergeDataRegion : Types.DataRegion -> List Types.DataRegion -> List Types.DataRegion
mergeDataRegion newRegion regions =
    let
        -- Check if two regions overlap or are adjacent (can be merged)
        canMerge r1 r2 =
            not (r1.end < r2.start - 1 || r2.end < r1.start - 1)

        -- Merge two regions into one
        merge r1 r2 =
            { start = Basics.min r1.start r2.start
            , end = Basics.max r1.end r2.end
            }

        -- Insert and merge the new region
        insertAndMerge region acc =
            case acc of
                [] ->
                    [ region ]

                r :: rest ->
                    if canMerge region r then
                        insertAndMerge (merge region r) rest

                    else
                        region :: r :: rest
    in
    regions
        |> List.sortBy .start
        |> insertAndMerge newRegion
        |> List.sortBy .start



-- PORTS


port requestPrgFile : () -> Cmd msg


port prgFileOpened : (JE.Value -> msg) -> Sub msg


port saveCdisFile : String -> Cmd msg


port cdisSaved : (() -> msg) -> Sub msg


port showError : (String -> msg) -> Sub msg


port quitApp : () -> Cmd msg


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
    | EnterGotoMode
    | UpdateGotoInput String
    | ExecuteGoto
    | CancelGoto
    | SelectLine Int
    | StartEditComment Int
    | UpdateEditComment String
    | SaveComment
    | CancelEditComment
    | StartEditLabel Int
    | UpdateEditLabel String
    | SaveLabel
    | CancelEditLabel
    | KeyPressed KeyEvent
    | ToggleHelp
    | SelectNextLine
    | SelectPrevLine
    | SaveProject
    | CdisSaved
    | ErrorOccurred String
    | FocusResult
    | ClickAddress Int
    | ToggleMark
    | MarkSelectionAsData
    | ClearDataRegion Int
    | RestartDisassembly
    | RequestQuit
    | ConfirmQuit
    | CancelQuit
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

        EnterGotoMode ->
            ( { model | gotoMode = True, gotoInput = "" }, Cmd.none )

        UpdateGotoInput str ->
            -- Only allow hex characters
            let
                filtered =
                    String.filter (\c -> Char.isHexDigit c) (String.toUpper str)
            in
            ( { model | gotoInput = String.left 4 filtered }, Cmd.none )

        ExecuteGoto ->
            case parseHex model.gotoInput of
                Just addr ->
                    let
                        offset =
                            addr - model.loadAddress
                    in
                    if offset >= 0 && offset < Array.length model.bytes then
                        ( ensureSelectionVisible
                            { model
                                | viewStart = offset
                                , selectedOffset = Just offset
                                , gotoMode = False
                                , gotoInput = ""
                                , gotoError = False
                            }
                        , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                        )

                    else
                        -- Invalid address - show error
                        ( { model | gotoError = True }, Cmd.none )

                Nothing ->
                    if String.isEmpty model.gotoInput then
                        -- Empty input - just cancel
                        ( { model | gotoMode = False, gotoInput = "", gotoError = False }
                        , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                        )

                    else
                        -- Invalid input - show error
                        ( { model | gotoError = True }, Cmd.none )

        CancelGoto ->
            ( { model | gotoMode = False, gotoInput = "", gotoError = False }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

        ClickAddress addr ->
            let
                offset =
                    addr - model.loadAddress
            in
            if offset >= 0 && offset < Array.length model.bytes then
                ( ensureSelectionVisible { model | viewStart = offset, selectedOffset = Just offset }, Cmd.none )

            else
                ( model, Cmd.none )

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
                    , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                    )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditComment ->
            ( { model | editingComment = Nothing }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

        StartEditLabel address ->
            let
                existingLabel =
                    Dict.get address model.labels |> Maybe.withDefault ""
            in
            ( { model | editingLabel = Just ( address, existingLabel ) }
            , Task.attempt (\_ -> NoOp) (Dom.focus "label-input")
            )

        UpdateEditLabel text ->
            case model.editingLabel of
                Just ( address, _ ) ->
                    ( { model | editingLabel = Just ( address, text ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveLabel ->
            case model.editingLabel of
                Just ( address, text ) ->
                    let
                        newLabels =
                            if String.isEmpty (String.trim text) then
                                Dict.remove address model.labels

                            else
                                Dict.insert address (String.trim text) model.labels
                    in
                    ( { model
                        | labels = newLabels
                        , editingLabel = Nothing
                        , dirty = True
                      }
                    , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                    )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditLabel ->
            ( { model | editingLabel = Nothing }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

        KeyPressed event ->
            if model.editingComment /= Nothing || model.editingLabel /= Nothing then
                ( model, Cmd.none )

            else if model.gotoMode then
                -- Handle goto mode input
                case event.key of
                    "Enter" ->
                        update ExecuteGoto model

                    "Escape" ->
                        update CancelGoto model

                    "Backspace" ->
                        ( { model | gotoInput = String.dropRight 1 model.gotoInput, gotoError = False }, Cmd.none )

                    key ->
                        if String.length key == 1 && String.length model.gotoInput < 4 then
                            let
                                char =
                                    String.toUpper key

                                isHex =
                                    String.all Char.isHexDigit char
                            in
                            if isHex then
                                ( { model | gotoInput = model.gotoInput ++ char, gotoError = False }, Cmd.none )

                            else
                                ( model, Cmd.none )

                        else
                            ( model, Cmd.none )

            else if model.confirmQuit then
                -- In quit confirmation mode
                if event.key == "q" then
                    update ConfirmQuit model

                else
                    update CancelQuit model

            else
                case event.key of
                    " " ->
                        if event.ctrl then
                            update ToggleMark model

                        else
                            ( model, Cmd.none )

                    "g" ->
                        update EnterGotoMode model

                    "l" ->
                        if event.ctrl then
                            centerSelectedLine model

                        else
                            ( model, Cmd.none )

                    ";" ->
                        case model.selectedOffset of
                            Just offset ->
                                update (StartEditComment offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    ":" ->
                        case model.selectedOffset of
                            Just offset ->
                                let
                                    address =
                                        model.loadAddress + offset
                                in
                                update (StartEditLabel address) model

                            Nothing ->
                                ( model, Cmd.none )

                    "s" ->
                        update SaveProject model

                    "q" ->
                        update RequestQuit model

                    "j" ->
                        case model.selectedOffset of
                            Just offset ->
                                let
                                    line =
                                        disassemble model.loadAddress offset model.bytes model.comments model.labels model.dataRegions
                                in
                                case line.targetAddress of
                                    Just addr ->
                                        update (ClickAddress addr) model

                                    Nothing ->
                                        ( model, Cmd.none )

                            Nothing ->
                                ( model, Cmd.none )

                    "d" ->
                        -- D: mark selection as data
                        update MarkSelectionAsData model

                    "D" ->
                        -- Shift+D: clear data region at cursor
                        case model.selectedOffset of
                            Just offset ->
                                update (ClearDataRegion offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    "r" ->
                        -- R: restart disassembly (peel off first byte as .byte)
                        update RestartDisassembly model

                    "Escape" ->
                        -- Escape clears the mark
                        ( { model | mark = Nothing }, Cmd.none )

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
                        -- In data region: move 1 byte; otherwise move by instruction length
                        inDataRegion =
                            List.any (\r -> offset >= r.start && offset <= r.end) model.dataRegions

                        instrLen =
                            if inDataRegion then
                                1

                            else
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
                            -- Find current instruction start and previous instruction start
                            ( currentStart, prevStart ) =
                                findInstructionBoundaries model.bytes model.dataRegions offset

                            -- If we're in the middle of an instruction, go to its start
                            -- Otherwise go to the previous instruction
                            newOffset =
                                if currentStart < offset then
                                    currentStart

                                else
                                    prevStart
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

        ToggleMark ->
            case model.selectedOffset of
                Just offset ->
                    if model.mark == Just offset then
                        -- Clear mark if setting at same position
                        ( { model | mark = Nothing }, Cmd.none )

                    else
                        ( { model | mark = Just offset }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        MarkSelectionAsData ->
            case ( model.mark, model.selectedOffset ) of
                ( Just markOffset, Just cursorOffset ) ->
                    let
                        startOff =
                            Basics.min markOffset cursorOffset

                        endOff =
                            Basics.max markOffset cursorOffset

                        newRegion =
                            { start = startOff, end = endOff }

                        newRegions =
                            mergeDataRegion newRegion model.dataRegions
                    in
                    ( { model
                        | dataRegions = newRegions
                        , mark = Nothing
                        , dirty = True
                      }
                    , Cmd.none
                    )

                _ ->
                    -- No selection active
                    ( model, Cmd.none )

        ClearDataRegion offset ->
            let
                newRegions =
                    List.filter
                        (\r -> not (offset >= r.start && offset <= r.end))
                        model.dataRegions
            in
            ( { model | dataRegions = newRegions, dirty = True }, Cmd.none )

        RestartDisassembly ->
            case model.selectedOffset of
                Just offset ->
                    if offset < Array.length model.bytes - 1 then
                        let
                            -- Add single-byte data region at current offset
                            newRegion =
                                { start = offset, end = offset }

                            newRegions =
                                mergeDataRegion newRegion model.dataRegions

                            -- Move selection to next byte
                            newOffset =
                                offset + 1
                        in
                        ( ensureSelectionVisible
                            { model
                                | dataRegions = newRegions
                                , selectedOffset = Just newOffset
                                , dirty = True
                            }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        RequestQuit ->
            if model.dirty then
                -- Need confirmation
                ( { model | confirmQuit = True }, Cmd.none )

            else
                -- No unsaved changes, quit immediately
                ( model, quitApp () )

        ConfirmQuit ->
            ( model, quitApp () )

        CancelQuit ->
            ( { model | confirmQuit = False }, Cmd.none )

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

                -- Snap a raw offset to a valid instruction boundary
                snapToInstructionStart rawOffset =
                    let
                        ( instrStart, _ ) =
                            findInstructionBoundaries model.bytes model.dataRegions rawOffset
                    in
                    instrStart
            in
            if tooHigh then
                let
                    rawStart =
                        Basics.max 0 (offset - margin)
                in
                { model | viewStart = snapToInstructionStart rawStart }

            else if tooLow then
                let
                    rawStart =
                        Basics.min maxViewStart (offset - model.viewLines + margin + 1)
                in
                { model | viewStart = snapToInstructionStart rawStart }

            else
                model

        Nothing ->
            model


{-| Find the start of the instruction containing the given offset,
    and the start of the previous instruction, by forward disassembly from 0.
    Returns (currentInstrStart, prevInstrStart)
-}
findInstructionBoundaries : Array Int -> List Types.DataRegion -> Int -> ( Int, Int )
findInstructionBoundaries bytes dataRegions targetOffset =
    findInstructionBoundariesHelper bytes dataRegions 0 0 0 targetOffset


findInstructionBoundariesHelper : Array Int -> List Types.DataRegion -> Int -> Int -> Int -> Int -> ( Int, Int )
findInstructionBoundariesHelper bytes dataRegions offset prevStart prevPrevStart targetOffset =
    if offset >= Array.length bytes then
        ( prevStart, prevPrevStart )

    else
        let
            inDataRegion =
                List.any (\r -> offset >= r.start && offset <= r.end) dataRegions

            instrLen =
                if inDataRegion then
                    1

                else
                    Array.get offset bytes
                        |> Maybe.map opcodeBytes
                        |> Maybe.withDefault 1

            nextOffset =
                offset + instrLen
        in
        if nextOffset > targetOffset then
            -- Current instruction contains or passes targetOffset
            ( offset, prevStart )

        else
            findInstructionBoundariesHelper bytes dataRegions nextOffset offset prevStart targetOffset



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
            JD.map4 KeyEvent
                (JD.field "key" JD.string)
                (JD.field "ctrlKey" JD.bool)
                (JD.field "altKey" JD.bool)
                (JD.field "shiftKey" JD.bool)
                |> JD.map
                    (\event ->
                        let
                            msg =
                                KeyPressed event

                            shouldPrevent =
                                List.member event.key [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight" ]
                                    || (event.key == " " && event.ctrl)
                        in
                        ( msg, shouldPrevent )
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
            , viewCheatsheet model
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
        [ span [ class "info" ]
            [ text ("Load: $" ++ toHex 4 model.loadAddress)
            , text (" | Size: " ++ String.fromInt (Array.length model.bytes) ++ " bytes")
            ]
        ]


viewCheatsheet : Model -> Html Msg
viewCheatsheet model =
    case model.selectedOffset of
        Nothing ->
            div [ class "cheatsheet" ]
                [ span [ class "cheatsheet-empty" ] [ text "Select a line to see opcode info" ]
                ]

        Just offset ->
            let
                -- Check if in data region
                inDataRegion =
                    List.any (\r -> offset >= r.start && offset <= r.end) model.dataRegions
            in
            if inDataRegion then
                div [ class "cheatsheet" ]
                    [ span [ class "cheatsheet-mnemonic" ] [ text ".byte" ]
                    , span [ class "cheatsheet-sep" ] [ text " | " ]
                    , span [ class "cheatsheet-desc" ] [ text "Data byte (not code)" ]
                    ]

            else
                case Array.get offset model.bytes of
                    Nothing ->
                        div [ class "cheatsheet" ]
                            [ span [ class "cheatsheet-empty" ] [ text "End of file" ]
                            ]

                    Just opcodeByte ->
                        let
                            info =
                                getOpcode opcodeByte

                            mnemonic =
                                if info.undocumented then
                                    "*" ++ info.mnemonic

                                else
                                    info.mnemonic

                            description =
                                getOpcodeDescription info.mnemonic

                            flags =
                                getOpcodeFlags info.mnemonic

                            mode =
                                addressingModeString info.mode

                            cycles =
                                String.fromInt info.cycles
                        in
                        div [ class "cheatsheet" ]
                            [ span [ class "cheatsheet-mnemonic" ] [ text mnemonic ]
                            , span [ class "cheatsheet-sep" ] [ text " | " ]
                            , span [ class "cheatsheet-mode" ] [ text mode ]
                            , span [ class "cheatsheet-sep" ] [ text " | " ]
                            , span [ class "cheatsheet-desc" ] [ text description ]
                            , span [ class "cheatsheet-sep" ] [ text " | " ]
                            , span [ class "cheatsheet-label" ] [ text "Flags: " ]
                            , span [ class "cheatsheet-flags" ] [ text flags ]
                            , span [ class "cheatsheet-sep" ] [ text " | " ]
                            , span [ class "cheatsheet-label" ] [ text "Cycles: " ]
                            , span [ class "cheatsheet-cycles" ] [ text cycles ]
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
                model.labels
                model.dataRegions
    in
    div
        [ class "disassembly"
        , onWheel Scroll
        ]
        [ viewDisassemblyHeader
        , div [ class "lines" ] (List.concatMap (viewLineWithLabel model) lines)
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

        isInSelection =
            case ( model.mark, model.selectedOffset ) of
                ( Just markOffset, Just cursorOffset ) ->
                    let
                        selStart =
                            Basics.min markOffset cursorOffset

                        selEnd =
                            Basics.max markOffset cursorOffset
                    in
                    line.offset >= selStart && line.offset <= selEnd

                _ ->
                    False

        lineClass =
            String.join " "
                (List.filter ((/=) "")
                    [ "line"
                    , if isSelected then
                        "selected"

                      else
                        ""
                    , if isInSelection then
                        "in-selection"

                      else
                        ""
                    , if line.isData then
                        "data-region"

                      else
                        ""
                    ]
                )
    in
    div
        [ class lineClass
        , onClick (SelectLine line.offset)
        , onDoubleClick (StartEditComment line.offset)
        ]
        [ span [ class "col-address" ] [ text ("$" ++ toHex 4 line.address) ]
        , span [ class "col-bytes" ] [ text (formatBytes line.bytes) ]
        , viewDisasm line model.labels
        , viewComment model line
        ]


{-| Render a line with its label (if any) above it
-}
viewLineWithLabel : Model -> Line -> List (Html Msg)
viewLineWithLabel model line =
    case ( line.label, model.editingLabel ) of
        ( _, Just ( editAddr, editText ) ) ->
            if editAddr == line.address then
                -- Editing this label
                [ viewLabelLineEditing editText line
                , viewLine model line
                ]

            else
                case line.label of
                    Just labelText ->
                        [ viewLabelLine labelText line
                        , viewLine model line
                        ]

                    Nothing ->
                        [ viewLine model line ]

        ( Just labelText, Nothing ) ->
            [ viewLabelLine labelText line
            , viewLine model line
            ]

        ( Nothing, Nothing ) ->
            [ viewLine model line ]


viewLabelLine : String -> Line -> Html Msg
viewLabelLine labelText line =
    div
        [ class "line label-line"
        , onClick (SelectLine line.offset)
        ]
        [ span [ class "label-text" ] [ text (labelText ++ ":") ]
        ]


viewLabelLineEditing : String -> Line -> Html Msg
viewLabelLineEditing currentText line =
    div
        [ class "line label-line editing" ]
        [ input
            [ type_ "text"
            , value currentText
            , onInput UpdateEditLabel
            , onBlur SaveLabel
            , onKeyDownLabel
            , id "label-input"
            , autofocus True
            , placeholder "label name"
            , class "label-input"
            ]
            []
        , span [ class "label-colon" ] [ text ":" ]
        ]


onKeyDownLabel : Attribute Msg
onKeyDownLabel =
    stopPropagationOn "keydown"
        (JD.field "key" JD.string
            |> JD.map
                (\key ->
                    if key == "Enter" then
                        ( SaveLabel, True )

                    else if key == "Escape" then
                        ( CancelEditLabel, True )

                    else
                        ( NoOp, True )
                )
        )


viewDisasm : Line -> Dict Int String -> Html Msg
viewDisasm line labels =
    case line.targetAddress of
        Nothing ->
            span [ class "col-disasm" ] [ text line.disassembly ]

        Just addr ->
            let
                parts =
                    String.words line.disassembly

                -- Use label if available, otherwise use the original operand
                labelName =
                    Dict.get addr labels
            in
            case parts of
                mnemonic :: operandParts ->
                    let
                        operand =
                            case labelName of
                                Just lbl ->
                                    lbl

                                Nothing ->
                                    String.join " " operandParts
                    in
                    span [ class "col-disasm" ]
                        [ text (mnemonic ++ " ")
                        , span
                            [ class "operand-link"
                            , stopPropagationOn "click" (JD.succeed ( ClickAddress addr, True ))
                            ]
                            [ text operand ]
                        ]

                _ ->
                    span [ class "col-disasm" ] [ text line.disassembly ]


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
    if model.confirmQuit then
        footer [ class "cdis-footer quit-confirm" ]
            [ span [ class "quit-warning" ] [ text "Unsaved changes! " ]
            , span [ class "quit-prompt" ] [ text "Press Q to quit, any other key to cancel" ]
            ]

    else if model.gotoMode then
        let
            footerClass =
                if model.gotoError then
                    "cdis-footer goto-mode goto-error"

                else
                    "cdis-footer goto-mode"

            hint =
                if model.gotoError then
                    span [ class "goto-error-msg" ] [ text "  Address out of range!" ]

                else
                    span [ class "goto-hint" ] [ text "  (Enter to jump, Esc to cancel)" ]
        in
        footer [ class footerClass ]
            [ span [ class "goto-prompt" ] [ text "GOTO: $" ]
            , span [ class "goto-input" ] [ text model.gotoInput ]
            , span [ class "goto-cursor" ] [ text "_" ]
            , hint
            ]

    else if model.helpExpanded then
        footer [ class "cdis-footer expanded" ]
            [ div [ class "help-grid" ]
                [ div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Navigation" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "↑ / ↓" ], text "Prev/Next line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Mouse wheel" ], text "Scroll" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "G" ], text "Go to address" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Ctrl+L" ], text "Center selected line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "J" ], text "Jump to operand address" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Editing" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Click" ], text "Select line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text ";" ], text "Edit comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text ":" ], text "Edit label" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Enter" ], text "Save" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Escape" ], text "Cancel / Clear mark" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Data Regions" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Ctrl+Space" ], text "Set/Clear mark" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "D" ], text "Mark selection as data" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Shift+D" ], text "Clear data region" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "R" ], text "Restart (peel byte)" ]
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
                , text "G: Goto | "
                , text "J: Jump | "
                , text ";/:: Comment/Label | "
                , text "D: Data | "
                , text "R: Restart | "
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
    stopPropagationOn "keydown"
        (JD.field "key" JD.string
            |> JD.map
                (\key ->
                    if key == "Enter" then
                        ( SaveComment, True )

                    else if key == "Escape" then
                        ( CancelEditComment, True )

                    else
                        ( NoOp, True )
                )
        )
