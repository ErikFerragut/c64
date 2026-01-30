port module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Dom as Dom
import Browser.Events
import Dict exposing (Dict)
import Assembler exposing (AssembleError(..), assemble)
import Disassembler exposing (disassemble, disassembleRange)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD
import Json.Encode as JE
import Opcodes exposing (addressingModeString, getOpcode, getOpcodeDescription, getOpcodeFlags, opcodeBytes)
import Symbols exposing (getSymbolInfo)
import Project
import Task
import Types exposing (..)


{-| Merge a new region into the list, combining overlapping/adjacent regions of the same type
-}
mergeRegion : Types.Region -> List Types.Region -> List Types.Region
mergeRegion newRegion regions =
    let
        -- Check if two regions can be merged (same type and overlapping/adjacent)
        canMerge r1 r2 =
            r1.regionType == r2.regionType && not (r1.end < r2.start - 1 || r2.end < r1.start - 1)

        -- Merge two regions into one
        merge r1 r2 =
            { start = Basics.min r1.start r2.start
            , end = Basics.max r1.end r2.end
            , regionType = r1.regionType
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


{-| Merge a new segment into the list, combining overlapping/adjacent segments
-}
mergeSegment : Types.Segment -> List Types.Segment -> List Types.Segment
mergeSegment newSegment segments =
    let
        canMerge s1 s2 =
            not (s1.end < s2.start - 1 || s2.end < s1.start - 1)

        merge s1 s2 =
            { start = Basics.min s1.start s2.start
            , end = Basics.max s1.end s2.end
            }

        insertAndMerge segment acc =
            case acc of
                [] ->
                    [ segment ]

                s :: rest ->
                    if canMerge segment s then
                        insertAndMerge (merge segment s) rest

                    else
                        segment :: s :: rest
    in
    segments
        |> List.sortBy .start
        |> insertAndMerge newSegment
        |> List.sortBy .start


{-| Get segment name from major comment at segment start (first word) or default
-}
getSegmentName : Model -> Types.Segment -> String
getSegmentName model segment =
    case Dict.get segment.start model.majorComments of
        Just comment ->
            comment
                |> String.words
                |> List.head
                |> Maybe.withDefault ("SEG_" ++ toHex 4 (model.loadAddress + segment.start))

        Nothing ->
            "SEG_" ++ toHex 4 (model.loadAddress + segment.start)



-- PORTS


port requestPrgFile : () -> Cmd msg


port prgFileOpened : (JE.Value -> msg) -> Sub msg


port saveCdisFile : String -> Cmd msg


port cdisSaved : (() -> msg) -> Sub msg


port showError : (String -> msg) -> Sub msg


port quitApp : () -> Cmd msg


port exportAsmFile : String -> Cmd msg


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
    ( initModel
    , Task.perform GotViewport Dom.getViewport
    )



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
    | MarkSelectionAsBytes
    | MarkSelectionAsText
    | ClearByteRegion Int
    | ClearTextRegion Int
    | MarkSelectionAsSegment
    | ClearSegment Int
    | StartEditMajorComment Int
    | UpdateEditMajorComment String
    | SaveMajorComment
    | CancelEditMajorComment
    | EnterOutlineMode
    | OutlineNext
    | OutlinePrev
    | OutlineSelect
    | CancelOutline
    | RestartDisassembly
    | JumpBack
    | PageUp
    | PageDown
    | NopCurrentByte
    | StartEditInstruction Int
    | UpdateEditInstruction String
    | SaveInstruction
    | CancelEditInstruction
    | RequestQuit
    | ConfirmQuit
    | CancelQuit
    | ExportAsm
    | WindowResized Int Int
    | GotViewport Dom.Viewport
    | GotLinesElement (Result Dom.Error Dom.Element)
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
                    , Cmd.batch
                        [ Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                        , Task.attempt GotLinesElement (Dom.getElement "lines-container")
                        ]
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

                -- Push current position to jump history before jumping
                newHistory =
                    case model.selectedOffset of
                        Just currentOffset ->
                            currentOffset :: model.jumpHistory |> List.take 50

                        Nothing ->
                            model.jumpHistory
            in
            if offset >= 0 && offset < Array.length model.bytes then
                ( ensureSelectionVisible
                    { model
                        | viewStart = offset
                        , selectedOffset = Just offset
                        , jumpHistory = newHistory
                    }
                , Cmd.none
                )

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
            if model.editingComment /= Nothing || model.editingLabel /= Nothing || model.editingMajorComment /= Nothing || model.editingInstruction /= Nothing then
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

            else if model.outlineMode then
                -- Handle outline mode input
                case event.key of
                    "ArrowLeft" ->
                        update OutlinePrev model

                    "ArrowRight" ->
                        update OutlineNext model

                    "Enter" ->
                        update OutlineSelect model

                    "Escape" ->
                        update CancelOutline model

                    _ ->
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

                    "\"" ->
                        -- " key: edit major comment
                        case model.selectedOffset of
                            Just offset ->
                                update (StartEditMajorComment offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    "s" ->
                        -- s: mark selection as segment
                        update MarkSelectionAsSegment model

                    "S" ->
                        -- Shift+S: clear segment at cursor (or save if no segment)
                        case model.selectedOffset of
                            Just offset ->
                                if List.any (\seg -> offset >= seg.start && offset <= seg.end) model.segments then
                                    update (ClearSegment offset) model

                                else
                                    update SaveProject model

                            Nothing ->
                                update SaveProject model

                    "a" ->
                        update ExportAsm model

                    "q" ->
                        update RequestQuit model

                    "o" ->
                        -- o: open outline picker
                        update EnterOutlineMode model

                    "j" ->
                        case model.selectedOffset of
                            Just offset ->
                                let
                                    line =
                                        disassemble model.loadAddress offset model.bytes model.comments model.labels model.regions model.segments model.majorComments
                                in
                                case line.targetAddress of
                                    Just addr ->
                                        update (ClickAddress addr) model

                                    Nothing ->
                                        ( model, Cmd.none )

                            Nothing ->
                                ( model, Cmd.none )

                    "b" ->
                        -- b: mark selection as bytes
                        update MarkSelectionAsBytes model

                    "B" ->
                        -- Shift+B: clear byte region at cursor
                        case model.selectedOffset of
                            Just offset ->
                                update (ClearByteRegion offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    "t" ->
                        -- t: mark selection as text
                        update MarkSelectionAsText model

                    "T" ->
                        -- Shift+T: clear text region at cursor
                        case model.selectedOffset of
                            Just offset ->
                                update (ClearTextRegion offset) model

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

                    "J" ->
                        -- Shift+J: jump back
                        update JumpBack model

                    "PageUp" ->
                        update PageUp model

                    "PageDown" ->
                        update PageDown model

                    "ArrowDown" ->
                        update SelectNextLine model

                    "ArrowUp" ->
                        update SelectPrevLine model

                    "n" ->
                        update NopCurrentByte model

                    "Enter" ->
                        -- Enter edit mode
                        case model.selectedOffset of
                            Just offset ->
                                update (StartEditInstruction offset) model

                            Nothing ->
                                ( model, Cmd.none )

                    _ ->
                        ( model, Cmd.none )

        ToggleHelp ->
            ( { model | helpExpanded = not model.helpExpanded }, Cmd.none )

        SelectNextLine ->
            case model.selectedOffset of
                Just offset ->
                    let
                        -- In byte region: move 1 byte
                        -- In text region: move to end of text region + 1
                        -- Otherwise: move by instruction length
                        inByteRegion =
                            List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) model.regions

                        textRegion =
                            List.filter (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) model.regions
                                |> List.head

                        instrLen =
                            case textRegion of
                                Just tr ->
                                    -- Jump past entire text region
                                    tr.end - offset + 1

                                Nothing ->
                                    if inByteRegion then
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
                                findInstructionBoundaries model.bytes model.regions offset

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

        MarkSelectionAsBytes ->
            case ( model.mark, model.selectedOffset ) of
                ( Just markOffset, Just cursorOffset ) ->
                    let
                        startOff =
                            Basics.min markOffset cursorOffset

                        endOff =
                            Basics.max markOffset cursorOffset

                        newRegion =
                            { start = startOff, end = endOff, regionType = Types.ByteRegion }

                        newRegions =
                            mergeRegion newRegion model.regions
                    in
                    ( { model
                        | regions = newRegions
                        , mark = Nothing
                        , dirty = True
                      }
                    , Cmd.none
                    )

                _ ->
                    -- No selection active
                    ( model, Cmd.none )

        MarkSelectionAsText ->
            case ( model.mark, model.selectedOffset ) of
                ( Just markOffset, Just cursorOffset ) ->
                    let
                        startOff =
                            Basics.min markOffset cursorOffset

                        endOff =
                            Basics.max markOffset cursorOffset

                        newRegion =
                            { start = startOff, end = endOff, regionType = Types.TextRegion }

                        newRegions =
                            mergeRegion newRegion model.regions
                    in
                    ( { model
                        | regions = newRegions
                        , mark = Nothing
                        , dirty = True
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClearByteRegion offset ->
            let
                newRegions =
                    List.filter
                        (\r -> not (r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end))
                        model.regions
            in
            ( { model | regions = newRegions, dirty = True }, Cmd.none )

        ClearTextRegion offset ->
            let
                newRegions =
                    List.filter
                        (\r -> not (r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end))
                        model.regions
            in
            ( { model | regions = newRegions, dirty = True }, Cmd.none )

        MarkSelectionAsSegment ->
            case ( model.mark, model.selectedOffset ) of
                ( Just markOffset, Just cursorOffset ) ->
                    let
                        startOff =
                            Basics.min markOffset cursorOffset

                        endOff =
                            Basics.max markOffset cursorOffset

                        newSegment =
                            { start = startOff, end = endOff }

                        newSegments =
                            mergeSegment newSegment model.segments
                    in
                    ( { model
                        | segments = newSegments
                        , mark = Nothing
                        , dirty = True
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClearSegment offset ->
            let
                newSegments =
                    List.filter
                        (\s -> not (offset >= s.start && offset <= s.end))
                        model.segments
            in
            ( { model | segments = newSegments, dirty = True }, Cmd.none )

        StartEditMajorComment offset ->
            let
                existingComment =
                    Dict.get offset model.majorComments |> Maybe.withDefault ""
            in
            ( { model | editingMajorComment = Just ( offset, existingComment ) }
            , Task.attempt (\_ -> NoOp) (Dom.focus "major-comment-input")
            )

        UpdateEditMajorComment text ->
            case model.editingMajorComment of
                Just ( offset, _ ) ->
                    ( { model | editingMajorComment = Just ( offset, text ) }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveMajorComment ->
            case model.editingMajorComment of
                Just ( offset, text ) ->
                    let
                        newMajorComments =
                            if String.isEmpty (String.trim text) then
                                Dict.remove offset model.majorComments

                            else
                                Dict.insert offset text model.majorComments
                    in
                    ( { model
                        | majorComments = newMajorComments
                        , editingMajorComment = Nothing
                        , dirty = True
                      }
                    , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                    )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditMajorComment ->
            ( { model | editingMajorComment = Nothing }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

        EnterOutlineMode ->
            if List.isEmpty model.segments then
                ( model, Cmd.none )

            else
                -- Find the segment containing current selection, or default to 0
                let
                    currentOffset =
                        model.selectedOffset |> Maybe.withDefault 0

                    segmentIndex =
                        model.segments
                            |> List.indexedMap Tuple.pair
                            |> List.filter (\( _, s ) -> currentOffset >= s.start && currentOffset <= s.end)
                            |> List.head
                            |> Maybe.map Tuple.first
                            |> Maybe.withDefault 0
                in
                ( { model | outlineMode = True, outlineSelection = segmentIndex }, Cmd.none )

        OutlineNext ->
            let
                maxIdx =
                    List.length model.segments - 1

                newIdx =
                    Basics.min maxIdx (model.outlineSelection + 1)
            in
            ( { model | outlineSelection = newIdx }, Cmd.none )

        OutlinePrev ->
            let
                newIdx =
                    Basics.max 0 (model.outlineSelection - 1)
            in
            ( { model | outlineSelection = newIdx }, Cmd.none )

        OutlineSelect ->
            let
                maybeSegment =
                    model.segments
                        |> List.drop model.outlineSelection
                        |> List.head
            in
            case maybeSegment of
                Just segment ->
                    ( ensureSelectionVisible
                        { model
                            | outlineMode = False
                            , selectedOffset = Just segment.start
                            , viewStart = segment.start
                        }
                    , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                    )

                Nothing ->
                    ( { model | outlineMode = False }, Cmd.none )

        CancelOutline ->
            ( { model | outlineMode = False }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

        RestartDisassembly ->
            case model.selectedOffset of
                Just offset ->
                    if offset < Array.length model.bytes - 1 then
                        let
                            -- Add single-byte byte region at current offset
                            newRegion =
                                { start = offset, end = offset, regionType = Types.ByteRegion }

                            newRegions =
                                mergeRegion newRegion model.regions

                            -- Move selection to next byte
                            newOffset =
                                offset + 1
                        in
                        ( ensureSelectionVisible
                            { model
                                | regions = newRegions
                                , selectedOffset = Just newOffset
                                , dirty = True
                            }
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        JumpBack ->
            case model.jumpHistory of
                prevOffset :: rest ->
                    ( ensureSelectionVisible
                        { model
                            | selectedOffset = Just prevOffset
                            , viewStart = prevOffset
                            , jumpHistory = rest
                        }
                    , Cmd.none
                    )

                [] ->
                    ( model, Cmd.none )

        PageUp ->
            let
                newViewStart =
                    Basics.max 0 (model.viewStart - model.viewLines)

                -- Find instruction boundary at new view start
                ( instrStart, _ ) =
                    findInstructionBoundaries model.bytes model.regions newViewStart
            in
            ( { model
                | viewStart = instrStart
                , selectedOffset = Just instrStart
              }
            , Cmd.none
            )

        PageDown ->
            let
                maxOffset =
                    Array.length model.bytes - 1

                newViewStart =
                    Basics.min maxOffset (model.viewStart + model.viewLines)

                -- Find instruction boundary at new view start
                ( instrStart, _ ) =
                    findInstructionBoundaries model.bytes model.regions newViewStart
            in
            ( { model
                | viewStart = instrStart
                , selectedOffset = Just instrStart
              }
            , Cmd.none
            )

        NopCurrentByte ->
            case model.selectedOffset of
                Just offset ->
                    case Array.get offset model.bytes of
                        Just currentByte ->
                            let
                                -- Get the instruction length before we NOP it
                                inByteRegion =
                                    List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) model.regions

                                inTextRegion =
                                    List.any (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) model.regions

                                instrLen =
                                    if inByteRegion || inTextRegion then
                                        1
                                    else
                                        opcodeBytes currentByte

                                -- Replace the byte with NOP ($EA = 234)
                                newBytes =
                                    Array.set offset 234 model.bytes

                                -- Record the patch for persistence
                                newPatches =
                                    Dict.insert offset 234 model.patches

                                -- If instruction was multi-byte, add remaining bytes as byte regions
                                newRegions =
                                    if instrLen > 1 && not inByteRegion && not inTextRegion then
                                        let
                                            leftoverStart =
                                                offset + 1

                                            leftoverEnd =
                                                offset + instrLen - 1

                                            leftoverRegion =
                                                { start = leftoverStart
                                                , end = leftoverEnd
                                                , regionType = Types.ByteRegion
                                                }
                                        in
                                        mergeRegion leftoverRegion model.regions
                                    else
                                        model.regions

                                -- Advance cursor by 1
                                newOffset =
                                    if offset + 1 < Array.length model.bytes then
                                        offset + 1
                                    else
                                        offset
                            in
                            ( ensureSelectionVisible
                                { model
                                    | bytes = newBytes
                                    , patches = newPatches
                                    , regions = newRegions
                                    , selectedOffset = Just newOffset
                                    , dirty = True
                                }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        StartEditInstruction offset ->
            let
                -- Get current disassembly text to pre-populate
                line =
                    disassemble model.loadAddress offset model.bytes model.comments model.labels model.regions model.segments model.majorComments

                -- Strip the leading * from undocumented opcodes for editing
                initialText =
                    if String.startsWith "*" line.disassembly then
                        String.dropLeft 1 line.disassembly
                    else
                        line.disassembly
            in
            ( { model
                | editingInstruction = Just ( offset, initialText )
                , editError = Nothing
              }
            , Task.attempt (\_ -> NoOp) (Dom.focus "instruction-input")
            )

        UpdateEditInstruction text ->
            case model.editingInstruction of
                Just ( offset, _ ) ->
                    ( { model | editingInstruction = Just ( offset, text ), editError = Nothing }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SaveInstruction ->
            case model.editingInstruction of
                Just ( offset, text ) ->
                    let
                        currentAddress =
                            model.loadAddress + offset

                        -- Get the size of the current instruction
                        inByteRegion =
                            List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) model.regions

                        inTextRegion =
                            List.any (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) model.regions

                        currentByte =
                            Array.get offset model.bytes |> Maybe.withDefault 0

                        oldSize =
                            if inByteRegion || inTextRegion then
                                1
                            else
                                opcodeBytes currentByte
                        fileSize =
                            Array.length model.bytes
                    in
                    case assemble currentAddress text of
                        Err err ->
                            ( { model | editError = Just (formatAssembleError err) }, Cmd.none )

                        Ok result ->
                            if offset + result.size > fileSize then
                                -- New instruction extends past end of file
                                ( { model | editError = Just ("Instruction extends past end of file") }
                                , Cmd.none
                                )

                            else
                                let
                                    -- Apply the new bytes
                                    ( newBytes, newPatches ) =
                                        List.foldl
                                            (\( idx, byte ) ( bytes, patches ) ->
                                                ( Array.set (offset + idx) byte bytes
                                                , Dict.insert (offset + idx) byte patches
                                                )
                                            )
                                            ( model.bytes, model.patches )
                                            (List.indexedMap Tuple.pair result.bytes)

                                    -- Remove any regions that overlap with the new instruction
                                    newEnd =
                                        offset + result.size - 1

                                    regionsWithoutOverlap =
                                        List.filter
                                            (\r -> r.end < offset || r.start > newEnd)
                                            model.regions

                                    -- If new instruction is smaller than old, leftover bytes become .byte regions
                                    newRegions =
                                        if result.size < oldSize then
                                            let
                                                leftoverStart =
                                                    offset + result.size

                                                leftoverEnd =
                                                    offset + oldSize - 1

                                                leftoverRegion =
                                                    { start = leftoverStart
                                                    , end = leftoverEnd
                                                    , regionType = Types.ByteRegion
                                                    }
                                            in
                                            mergeRegion leftoverRegion regionsWithoutOverlap
                                        else
                                            regionsWithoutOverlap
                                    -- Move to next instruction
                                    nextOffset =
                                        offset + result.size

                                    newSelectedOffset =
                                        if nextOffset < fileSize then
                                            Just nextOffset
                                        else
                                            Just offset
                                in
                                ( ensureSelectionVisible
                                    { model
                                        | bytes = newBytes
                                        , patches = newPatches
                                        , regions = newRegions
                                        , selectedOffset = newSelectedOffset
                                        , editingInstruction = Nothing
                                        , editError = Nothing
                                        , dirty = True
                                    }
                                , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
                                )

                Nothing ->
                    ( model, Cmd.none )

        CancelEditInstruction ->
            ( { model | editingInstruction = Nothing, editError = Nothing }
            , Task.attempt (\_ -> FocusResult) (Dom.focus "cdis-main")
            )

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

        ExportAsm ->
            if Array.isEmpty model.bytes then
                ( model, Cmd.none )

            else
                let
                    asmContent =
                        generateAsm model
                in
                ( model, exportAsmFile asmContent )

        WindowResized _ _ ->
            -- On resize, measure the lines container after a brief delay for layout
            ( model, Task.attempt GotLinesElement (Dom.getElement "lines-container") )

        GotViewport _ ->
            -- After getting viewport, measure the lines container
            ( model, Task.attempt GotLinesElement (Dom.getElement "lines-container") )

        GotLinesElement result ->
            case result of
                Ok element ->
                    let
                        -- Each line is approximately 24px (14px font + padding)
                        lineHeight =
                            24

                        availableHeight =
                            element.element.height

                        newViewLines =
                            Basics.max 5 (floor availableHeight // lineHeight)
                    in
                    ( { model | viewLines = newViewLines }, Cmd.none )

                Err _ ->
                    -- Element not found (file not loaded yet), keep default
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

                -- Snap a raw offset to a valid instruction boundary
                snapToInstructionStart rawOffset =
                    let
                        ( instrStart, _ ) =
                            findInstructionBoundaries model.bytes model.regions rawOffset
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
findInstructionBoundaries : Array Int -> List Types.Region -> Int -> ( Int, Int )
findInstructionBoundaries bytes regions targetOffset =
    findInstructionBoundariesHelper bytes regions 0 0 0 targetOffset


findInstructionBoundariesHelper : Array Int -> List Types.Region -> Int -> Int -> Int -> Int -> ( Int, Int )
findInstructionBoundariesHelper bytes regions offset prevStart prevPrevStart targetOffset =
    if offset >= Array.length bytes then
        ( prevStart, prevPrevStart )

    else
        let
            inByteRegion =
                List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) regions

            textRegion =
                List.filter (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) regions
                    |> List.head

            instrLen =
                case textRegion of
                    Just tr ->
                        -- Text region consumes all bytes at once
                        tr.end - offset + 1

                    Nothing ->
                        if inByteRegion then
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
            findInstructionBoundariesHelper bytes regions nextOffset offset prevStart targetOffset



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ prgFileOpened PrgFileOpened
        , cdisSaved (\_ -> CdisSaved)
        , showError ErrorOccurred
        , Browser.Events.onResize WindowResized
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
                                List.member event.key [ "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "PageUp", "PageDown" ]
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
            , viewDisassembly model
            , viewCheatsheet model
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
                -- Check if in byte or text region
                inByteRegion =
                    List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) model.regions

                inTextRegion =
                    List.any (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) model.regions
            in
            if inTextRegion then
                div [ class "cheatsheet" ]
                    [ span [ class "cheatsheet-mnemonic" ] [ text ".text" ]
                    , span [ class "cheatsheet-sep" ] [ text " | " ]
                    , span [ class "cheatsheet-desc" ] [ text "Text data (PETSCII)" ]
                    ]

            else if inByteRegion then
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

                            -- Get operand bytes to find the address being referenced
                            operandAddr =
                                getOperandAddress model offset info

                            -- Look up symbol info for the operand address
                            symbolInfoPart =
                                case operandAddr of
                                    Just addr ->
                                        case getSymbolInfo addr of
                                            Just symInfo ->
                                                [ span [ class "cheatsheet-sep" ] [ text " | " ]
                                                , span [ class "cheatsheet-symbol" ] [ text symInfo.name ]
                                                , span [ class "cheatsheet-sep" ] [ text ": " ]
                                                , span [ class "cheatsheet-symbol-desc" ] [ text symInfo.description ]
                                                ]

                                            Nothing ->
                                                []

                                    Nothing ->
                                        []
                        in
                        div [ class "cheatsheet" ]
                            ([ span [ class "cheatsheet-mnemonic" ] [ text mnemonic ]
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
                                ++ symbolInfoPart
                            )


{-| Extract the operand address from an instruction for symbol lookup
-}
getOperandAddress : Model -> Int -> Types.OpcodeInfo -> Maybe Int
getOperandAddress model offset info =
    let
        getByte off =
            Array.get off model.bytes

        lo =
            getByte (offset + 1)

        hi =
            getByte (offset + 2)
    in
    case info.mode of
        Types.ZeroPage ->
            lo

        Types.ZeroPageX ->
            lo

        Types.ZeroPageY ->
            lo

        Types.Absolute ->
            Maybe.map2 (\l h -> h * 256 + l) lo hi

        Types.AbsoluteX ->
            Maybe.map2 (\l h -> h * 256 + l) lo hi

        Types.AbsoluteY ->
            Maybe.map2 (\l h -> h * 256 + l) lo hi

        Types.Indirect ->
            Maybe.map2 (\l h -> h * 256 + l) lo hi

        Types.IndirectX ->
            lo

        Types.IndirectY ->
            lo

        Types.Relative ->
            -- Calculate branch target
            lo
                |> Maybe.map
                    (\byte ->
                        let
                            signedOffset =
                                if byte > 127 then
                                    byte - 256

                                else
                                    byte
                        in
                        model.loadAddress + offset + 2 + signedOffset
                    )

        _ ->
            Nothing


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
                model.regions
                model.segments
                model.majorComments

        originLine =
            if model.viewStart == 0 then
                [ div [ class "line origin-line" ]
                    [ span [ class "col-address" ] [ text "" ]
                    , span [ class "col-bytes" ] [ text "" ]
                    , span [ class "col-disasm origin" ] [ text ("*= $" ++ toHex 4 model.loadAddress) ]
                    , span [ class "col-comment" ] [ text "" ]
                    ]
                ]
            else
                []
    in
    div
        [ class "disassembly"
        , onWheel Scroll
        ]
        [ viewDisassemblyHeader
        , div [ class "lines", id "lines-container" ] (originLine ++ List.concatMap (viewLineWithLabel model) lines)
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
                    , if line.isText then
                        "text-region"

                      else
                        ""
                    , if line.inSegment then
                        "in-segment"

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
        , viewDisasmOrEdit model line
        , viewComment model line
        ]


viewDisasmOrEdit : Model -> Line -> Html Msg
viewDisasmOrEdit model line =
    case model.editingInstruction of
        Just ( editOffset, editText ) ->
            if editOffset == line.offset then
                span [ class "col-disasm editing" ]
                    [ input
                        [ type_ "text"
                        , value editText
                        , onInput UpdateEditInstruction
                        , onBlur SaveInstruction
                        , onKeyDownInstruction
                        , id "instruction-input"
                        , autofocus True
                        , class "instruction-input"
                        ]
                        []
                    , case model.editError of
                        Just err ->
                            span [ class "edit-error" ] [ text err ]

                        Nothing ->
                            text ""
                    ]

            else
                viewDisasm line model.labels

        Nothing ->
            viewDisasm line model.labels


onKeyDownInstruction : Attribute Msg
onKeyDownInstruction =
    stopPropagationOn "keydown"
        (JD.field "key" JD.string
            |> JD.map
                (\key ->
                    if key == "Enter" then
                        ( SaveInstruction, True )

                    else if key == "Escape" then
                        ( CancelEditInstruction, True )

                    else
                        ( NoOp, True )
                )
        )


{-| Render a line with its label (if any) above it, and major comment above label
-}
viewLineWithLabel : Model -> Line -> List (Html Msg)
viewLineWithLabel model line =
    let
        majorCommentLines =
            case model.editingMajorComment of
                Just ( editOffset, editText ) ->
                    if editOffset == line.offset then
                        [ viewMajorCommentEditing editText line ]

                    else
                        case line.majorComment of
                            Just mc ->
                                [ viewMajorCommentLine mc line ]

                            Nothing ->
                                []

                Nothing ->
                    case line.majorComment of
                        Just mc ->
                            [ viewMajorCommentLine mc line ]

                        Nothing ->
                            []

        labelLines =
            case ( line.label, model.editingLabel ) of
                ( _, Just ( editAddr, editText ) ) ->
                    if editAddr == line.address then
                        [ viewLabelLineEditing editText line ]

                    else
                        case line.label of
                            Just labelText ->
                                [ viewLabelLine labelText line ]

                            Nothing ->
                                []

                ( Just labelText, Nothing ) ->
                    [ viewLabelLine labelText line ]

                ( Nothing, Nothing ) ->
                    []
    in
    majorCommentLines ++ labelLines ++ [ viewLine model line ]


viewMajorCommentLine : String -> Line -> Html Msg
viewMajorCommentLine commentText line =
    let
        commentLines =
            String.lines commentText
    in
    div
        [ class "line major-comment-line"
        , onClick (SelectLine line.offset)
        ]
        (List.map (\l -> div [ class "major-comment-text" ] [ text (";; " ++ l) ]) commentLines)


viewMajorCommentEditing : String -> Line -> Html Msg
viewMajorCommentEditing currentText line =
    div
        [ class "line major-comment-line editing" ]
        [ textarea
            [ value currentText
            , onInput UpdateEditMajorComment
            , onBlur SaveMajorComment
            , onKeyDownMajorComment
            , id "major-comment-input"
            , autofocus True
            , placeholder "Major comment (first word = segment name)"
            , class "major-comment-input"
            , rows 3
            ]
            []
        ]


onKeyDownMajorComment : Attribute Msg
onKeyDownMajorComment =
    stopPropagationOn "keydown"
        (JD.map2 Tuple.pair
            (JD.field "key" JD.string)
            (JD.field "shiftKey" JD.bool)
            |> JD.map
                (\( key, shift ) ->
                    if key == "Enter" && not shift then
                        -- Enter (without Shift) saves
                        ( SaveMajorComment, True )

                    else if key == "Enter" && shift then
                        -- Shift+Enter inserts newline (don't prevent default)
                        ( NoOp, False )

                    else if key == "Escape" then
                        ( CancelEditMajorComment, True )

                    else
                        ( NoOp, False )
                )
        )


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

    else if model.outlineMode then
        let
            segmentCount =
                List.length model.segments

            segmentItems =
                model.segments
                    |> List.indexedMap
                        (\idx seg ->
                            let
                                segName =
                                    getSegmentName model seg

                                isSelected =
                                    idx == model.outlineSelection

                                itemClass =
                                    if isSelected then
                                        "outline-item selected"

                                    else
                                        "outline-item"
                            in
                            span [ class itemClass ] [ text segName ]
                        )

            separator =
                span [ class "outline-sep" ] [ text " | " ]

            itemsWithSeparators =
                segmentItems
                    |> List.intersperse separator
        in
        footer [ class "cdis-footer outline-mode" ]
            ([ span [ class "outline-label" ] [ text "OUTLINE: " ] ]
                ++ itemsWithSeparators
                ++ [ span [ class "outline-hint" ] [ text "  (←→ navigate, Enter select, Esc cancel)" ] ]
            )

    else if model.helpExpanded then
        footer [ class "cdis-footer expanded" ]
            [ div [ class "help-grid" ]
                [ div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Navigation" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "↑ / ↓" ], text "Prev/Next line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "PgUp / PgDn" ], text "Page up/down" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "G" ], text "Go to address" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "J / Shift+J" ], text "Jump to address / back" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "O" ], text "Outline (segment picker)" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Ctrl+L" ], text "Center selected line" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Editing" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Click" ], text "Select line" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text ";" ], text "Edit comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text ":" ], text "Edit label" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "\"" ], text "Edit major comment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Enter" ], text "Save (Ctrl+Enter for major)" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Escape" ], text "Cancel / Clear mark" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Regions & Segments" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Ctrl+Space" ], text "Set/Clear mark" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "B / Shift+B" ], text "Mark/Clear bytes" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "T / Shift+T" ], text "Mark/Clear text" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "S / Shift+S" ], text "Mark/Clear segment" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "R" ], text "Restart (peel byte)" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "N" ], text "NOP current byte" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Enter" ], text "Edit instruction" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "File" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "Shift+S" ], text "Save project" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "A" ], text "Export as .asm" ]
                    , div [ class "help-row" ] [ span [ class "key" ] [ text "?" ], text "Toggle this help" ]
                    ]
                , div [ class "help-section" ]
                    [ div [ class "help-title" ] [ text "Credits" ]
                    , div [ class "help-row" ] [ text "PETSCII font: Pet Me 64 by Kreative Software" ]
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
                , text "O: Outline | "
                , text ";/:/\": Comments | "
                , text "B/T/S: Regions | "
                , text "Shift+S: Save | "
                , text "A: Asm"
                ]
            ]



-- ASM EXPORT


{-| Generate ACME-compatible assembly from the disassembly
-}
generateAsm : Model -> String
generateAsm model =
    let
        header =
            [ "; Disassembly of " ++ model.fileName
            , "; Generated by CDis"
            , ""
            , "* = $" ++ toHex 4 model.loadAddress
            , ""
            ]

        -- Generate all lines
        asmLines =
            generateAsmLines model 0 []
    in
    String.join "\n" (header ++ asmLines)


{-| Generate ASM lines from offset to end
-}
generateAsmLines : Model -> Int -> List String -> List String
generateAsmLines model offset acc =
    if offset >= Array.length model.bytes then
        List.reverse acc

    else
        let
            address =
                model.loadAddress + offset

            -- Check if this is the start of a segment
            segmentStartLine =
                case List.filter (\s -> s.start == offset) model.segments of
                    seg :: _ ->
                        let
                            segName =
                                getSegmentName model seg
                        in
                        [ "", "; === " ++ segName ++ " ===" ]

                    [] ->
                        []

            -- Check for major comment at this offset
            majorCommentLines =
                case Dict.get offset model.majorComments of
                    Just mc ->
                        mc
                            |> String.lines
                            |> List.map (\l -> ";; " ++ l)

                    Nothing ->
                        []

            -- Check for label at this address
            labelLine =
                case Dict.get address model.labels of
                    Just labelName ->
                        [ labelName ++ ":" ]

                    Nothing ->
                        []

            -- Check region type
            inByteRegion =
                List.any (\r -> r.regionType == Types.ByteRegion && offset >= r.start && offset <= r.end) model.regions

            textRegion =
                List.filter (\r -> r.regionType == Types.TextRegion && offset >= r.start && offset <= r.end) model.regions
                    |> List.head

            -- Generate the instruction or data line
            ( lineText, bytesConsumed ) =
                case textRegion of
                    Just tr ->
                        generateTextLine model offset tr.end

                    Nothing ->
                        if inByteRegion then
                            generateDataLine model offset

                        else
                            generateCodeLine model offset

            -- Check for comment
            commentText =
                case Dict.get offset model.comments of
                    Just cmt ->
                        " ; " ++ cmt

                    Nothing ->
                        ""

            fullLine =
                "    " ++ lineText ++ commentText

            newAcc =
                (fullLine :: labelLine) ++ majorCommentLines ++ segmentStartLine ++ acc
        in
        generateAsmLines model (offset + bytesConsumed) newAcc


{-| Generate a data line (.byte)
-}
generateDataLine : Model -> Int -> ( String, Int )
generateDataLine model offset =
    case Array.get offset model.bytes of
        Just byte ->
            ( ".byte $" ++ toHex 2 byte, 1 )

        Nothing ->
            ( "; end of file", 1 )


{-| Generate a text line (.text "...")
-}
generateTextLine : Model -> Int -> Int -> ( String, Int )
generateTextLine model offset regionEnd =
    let
        -- Collect all bytes from offset to regionEnd
        collectBytes off endOff accBytes =
            if off > endOff then
                List.reverse accBytes

            else
                case Array.get off model.bytes of
                    Just b ->
                        collectBytes (off + 1) endOff (b :: accBytes)

                    Nothing ->
                        List.reverse accBytes

        textBytes =
            collectBytes offset regionEnd []

        -- Convert to PETSCII string
        textStr =
            textBytes
                |> List.map Disassembler.toPetscii
                |> String.fromList

        bytesConsumed =
            regionEnd - offset + 1
    in
    ( ".text \"" ++ textStr ++ "\"", bytesConsumed )


{-| Generate a code line (instruction)
-}
generateCodeLine : Model -> Int -> ( String, Int )
generateCodeLine model offset =
    case Array.get offset model.bytes of
        Nothing ->
            ( "; end of file", 1 )

        Just opcodeByte ->
            let
                info =
                    getOpcode opcodeByte

                mnemonic =
                    if info.undocumented then
                        "*" ++ info.mnemonic

                    else
                        info.mnemonic

                operandStr =
                    generateOperand model offset info
            in
            if String.isEmpty operandStr then
                ( mnemonic, info.bytes )

            else
                ( mnemonic ++ " " ++ operandStr, info.bytes )


{-| Generate the operand string, using labels where available
-}
generateOperand : Model -> Int -> OpcodeInfo -> String
generateOperand model offset info =
    let
        getByte off =
            Array.get off model.bytes |> Maybe.withDefault 0

        lo =
            getByte (offset + 1)

        hi =
            getByte (offset + 2)

        wordValue =
            hi * 256 + lo

        address =
            model.loadAddress + offset

        -- For relative branches, calculate target
        relativeTarget =
            let
                signedOffset =
                    if lo > 127 then
                        lo - 256

                    else
                        lo
            in
            address + 2 + signedOffset

        -- Look up label for an address
        labelOrHex addr width =
            case Dict.get addr model.labels of
                Just labelName ->
                    labelName

                Nothing ->
                    "$" ++ toHex width addr
    in
    case info.mode of
        Implied ->
            ""

        Accumulator ->
            ""

        Immediate ->
            "#$" ++ toHex 2 lo

        ZeroPage ->
            labelOrHex lo 2

        ZeroPageX ->
            labelOrHex lo 2 ++ ",X"

        ZeroPageY ->
            labelOrHex lo 2 ++ ",Y"

        Absolute ->
            labelOrHex wordValue 4

        AbsoluteX ->
            labelOrHex wordValue 4 ++ ",X"

        AbsoluteY ->
            labelOrHex wordValue 4 ++ ",Y"

        Indirect ->
            "(" ++ labelOrHex wordValue 4 ++ ")"

        IndirectX ->
            "(" ++ labelOrHex lo 2 ++ ",X)"

        IndirectY ->
            "(" ++ labelOrHex lo 2 ++ "),Y"

        Relative ->
            labelOrHex relativeTarget 4



-- HELPERS


formatAssembleError : AssembleError -> String
formatAssembleError err =
    case err of
        UnknownMnemonic m ->
            "Unknown mnemonic: " ++ m

        InvalidOperand o ->
            "Invalid operand: " ++ o

        InvalidAddressingMode m _ ->
            "Invalid addressing mode for " ++ m

        OperandOutOfRange v ->
            "Operand out of range: " ++ String.fromInt v

        BranchOutOfRange o ->
            "Branch out of range: " ++ String.fromInt o ++ " bytes"


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
