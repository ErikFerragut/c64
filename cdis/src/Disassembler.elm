module Disassembler exposing (disassemble, disassembleRange, formatOperand, toPetscii)

import Array exposing (Array)
import Dict exposing (Dict)
import Opcodes exposing (getOpcode, opcodeBytes)
import Symbols exposing (getSymbol)
import Types exposing (AddressingMode(..), Line, OpcodeInfo, Region, RegionType(..), Segment)


{-| Disassemble a range of bytes starting at a given offset
    Returns a list of disassembled lines
-}
disassembleRange : Int -> Int -> Int -> Array Int -> Dict Int String -> Dict Int String -> List Region -> List Segment -> Dict Int String -> List Line
disassembleRange loadAddress startOffset count bytes comments labels regions segments majorComments =
    disassembleHelper loadAddress startOffset count bytes comments labels regions segments majorComments []


disassembleHelper : Int -> Int -> Int -> Array Int -> Dict Int String -> Dict Int String -> List Region -> List Segment -> Dict Int String -> List Line -> List Line
disassembleHelper loadAddress offset remaining bytes comments labels regions segments majorComments acc =
    if remaining <= 0 || offset >= Array.length bytes then
        List.reverse acc

    else
        let
            line =
                disassembleLine loadAddress offset bytes comments labels regions segments majorComments

            newOffset =
                offset + List.length line.bytes

            newRemaining =
                remaining - 1
        in
        disassembleHelper loadAddress newOffset newRemaining bytes comments labels regions segments majorComments (line :: acc)


{-| Disassemble a single instruction at the given offset
-}
disassemble : Int -> Int -> Array Int -> Dict Int String -> Dict Int String -> List Region -> List Segment -> Dict Int String -> Line
disassemble loadAddress offset bytes comments labels regions segments majorComments =
    disassembleLine loadAddress offset bytes comments labels regions segments majorComments


{-| Check if an offset falls within a byte region
-}
isInByteRegion : Int -> List Region -> Bool
isInByteRegion offset regions =
    List.any (\r -> r.regionType == ByteRegion && offset >= r.start && offset <= r.end) regions


{-| Check if an offset falls within a text region
-}
isInTextRegion : Int -> List Region -> Bool
isInTextRegion offset regions =
    List.any (\r -> r.regionType == TextRegion && offset >= r.start && offset <= r.end) regions


{-| Check if an offset falls within any segment
-}
isInSegment : Int -> List Segment -> Bool
isInSegment offset segments =
    List.any (\s -> offset >= s.start && offset <= s.end) segments


{-| Convert a PETSCII byte to Unicode character for Pet Me 64 font.

    PETSCII layout:
    $00-$1F: Control codes -> middle dot
    $20-$3F: Space, numbers, punctuation (same as ASCII)
    $40-$5A: @, uppercase A-Z
    $5B-$5F: [\]^_
    $60-$7F: Graphics characters -> PUA 0xE040-0xE05F
    $80-$9F: Control codes -> middle dot
    $A0-$BF: Graphics characters -> PUA 0xE060-0xE07F
    $C0-$DA: Shifted graphics / uppercase A-Z (depending on mode)
    $C1-$DA: Lowercase a-z (in lowercase mode)
    $DB-$DF: More graphics
    $E0-$FF: Graphics -> PUA 0xE060-0xE07F

    Pet Me 64 font has C64 charset in Unicode PUA 0xE000-0xE1FF
    Screen code mapping: PUA base + screen_code
-}
toPetscii : Int -> Char
toPetscii byte =
    if byte >= 0x20 && byte <= 0x3F then
        -- Space, numbers, punctuation - direct ASCII
        Char.fromCode byte

    else if byte >= 0x40 && byte <= 0x5A then
        -- @ and uppercase A-Z - direct ASCII
        Char.fromCode byte

    else if byte >= 0x5B && byte <= 0x5F then
        -- [\]^_ - direct ASCII
        Char.fromCode byte

    else if byte >= 0x60 && byte <= 0x7F then
        -- Graphics set 1: map to PUA (screen codes $40-$5F)
        Char.fromCode (0xE040 + (byte - 0x60))

    else if byte >= 0xA0 && byte <= 0xBF then
        -- Graphics set 2: map to PUA (screen codes $60-$7F)
        Char.fromCode (0xE060 + (byte - 0xA0))

    else if byte >= 0xC1 && byte <= 0xDA then
        -- Lowercase a-z (PETSCII puts lowercase at $C1-$DA)
        -- Map to ASCII lowercase: $C1 -> 'a' ($61), $DA -> 'z' ($7A)
        Char.fromCode (0x61 + (byte - 0xC1))

    else if byte == 0xC0 then
        -- Shifted @
        Char.fromCode 0xE040

    else if byte >= 0xDB && byte <= 0xDF then
        -- Graphics (shifted [\]^_)
        Char.fromCode (0xE05B + (byte - 0xDB))

    else if byte >= 0xE0 && byte <= 0xFF then
        -- More graphics: map to PUA (screen codes $60-$7F)
        Char.fromCode (0xE060 + (byte - 0xE0))

    else
        -- Control codes ($00-$1F, $80-$9F): use middle dot
        '·'


{-| Convert bytes to a PETSCII string for .text display
-}
bytesToPetscii : List Int -> String
bytesToPetscii byteList =
    byteList
        |> List.map toPetscii
        |> String.fromList


disassembleLine : Int -> Int -> Array Int -> Dict Int String -> Dict Int String -> List Region -> List Segment -> Dict Int String -> Line
disassembleLine loadAddress offset bytes comments labels regions segments majorComments =
    let
        address =
            loadAddress + offset

        labelAtAddr =
            Dict.get address labels

        majorComment =
            Dict.get offset majorComments

        inSeg =
            isInSegment offset segments
    in
    case Array.get offset bytes of
        Nothing ->
            { offset = offset
            , address = address
            , bytes = []
            , disassembly = "; end of file"
            , comment = Dict.get offset comments
            , targetAddress = Nothing
            , isData = False
            , isText = False
            , label = labelAtAddr
            , majorComment = majorComment
            , inSegment = inSeg
            }

        Just byte ->
            if isInTextRegion offset regions then
                -- Render as text - collect consecutive bytes in text region
                let
                    textRegion =
                        List.filter (\r -> r.regionType == TextRegion && offset >= r.start && offset <= r.end) regions
                            |> List.head

                    regionEnd =
                        textRegion
                            |> Maybe.map .end
                            |> Maybe.withDefault offset

                    -- Collect all bytes from current offset to end of text region
                    textBytes =
                        collectTextBytes offset regionEnd bytes []

                    textStr =
                        bytesToPetscii textBytes
                in
                { offset = offset
                , address = address
                , bytes = textBytes
                , disassembly = ".text \"" ++ textStr ++ "\""
                , comment = Dict.get offset comments
                , targetAddress = Nothing
                , isData = False
                , isText = True
                , label = labelAtAddr
                , majorComment = majorComment
                , inSegment = inSeg
                }

            else if isInByteRegion offset regions then
                -- Render as data byte
                { offset = offset
                , address = address
                , bytes = [ byte ]
                , disassembly = ".byte " ++ formatByte byte
                , comment = Dict.get offset comments
                , targetAddress = Nothing
                , isData = True
                , isText = False
                , label = labelAtAddr
                , majorComment = majorComment
                , inSegment = inSeg
                }

            else
                -- Normal instruction disassembly
                let
                    info =
                        getOpcode byte

                    instrBytes =
                        getInstructionBytes offset info.bytes bytes

                    operandValue =
                        getOperandValue instrBytes

                    disasm =
                        formatInstruction info operandValue address

                    endAddress =
                        loadAddress + Array.length bytes

                    targetAddr =
                        computeTargetAddress info.mode operandValue address loadAddress endAddress
                in
                { offset = offset
                , address = address
                , bytes = instrBytes
                , disassembly = disasm
                , comment = Dict.get offset comments
                , targetAddress = targetAddr
                , isData = False
                , isText = False
                , label = labelAtAddr
                , majorComment = majorComment
                , inSegment = inSeg
                }


{-| Collect all bytes from start offset to end offset (inclusive)
-}
collectTextBytes : Int -> Int -> Array Int -> List Int -> List Int
collectTextBytes current end bytes acc =
    if current > end then
        List.reverse acc

    else
        case Array.get current bytes of
            Just byte ->
                collectTextBytes (current + 1) end bytes (byte :: acc)

            Nothing ->
                List.reverse acc


{-| Get the bytes for this instruction
-}
getInstructionBytes : Int -> Int -> Array Int -> List Int
getInstructionBytes offset numBytes bytes =
    List.range offset (offset + numBytes - 1)
        |> List.filterMap (\i -> Array.get i bytes)


{-| Get the operand value (for 2 or 3 byte instructions)
-}
getOperandValue : List Int -> Int
getOperandValue instrBytes =
    case instrBytes of
        [ _, lo ] ->
            lo

        [ _, lo, hi ] ->
            hi * 256 + lo

        _ ->
            0


{-| Format a complete instruction
-}
formatInstruction : OpcodeInfo -> Int -> Int -> String
formatInstruction info operand address =
    let
        mnemonic =
            if info.undocumented then
                "*" ++ info.mnemonic

            else
                info.mnemonic

        operandStr =
            formatOperand info.mode operand address
    in
    if String.isEmpty operandStr then
        mnemonic

    else
        mnemonic ++ " " ++ operandStr


{-| Format the operand based on addressing mode
-}
formatOperand : AddressingMode -> Int -> Int -> String
formatOperand mode operand instrAddress =
    case mode of
        Implied ->
            ""

        Accumulator ->
            "A"

        Immediate ->
            "#" ++ formatByte operand

        ZeroPage ->
            formatByteWithSymbol operand

        ZeroPageX ->
            formatByteWithSymbol operand ++ ",X"

        ZeroPageY ->
            formatByteWithSymbol operand ++ ",Y"

        Absolute ->
            formatWordWithSymbol operand

        AbsoluteX ->
            formatWordWithSymbol operand ++ ",X"

        AbsoluteY ->
            formatWordWithSymbol operand ++ ",Y"

        Indirect ->
            "(" ++ formatWordWithSymbol operand ++ ")"

        IndirectX ->
            "(" ++ formatByteWithSymbol operand ++ ",X)"

        IndirectY ->
            "(" ++ formatByteWithSymbol operand ++ "),Y"

        Relative ->
            let
                -- Calculate branch target
                -- Operand is signed byte, target is relative to next instruction
                signedOffset =
                    if operand > 127 then
                        operand - 256

                    else
                        operand

                target =
                    instrAddress + 2 + signedOffset
            in
            formatWordWithSymbol target


{-| Compute the target address for clickable operands
    Only returns Just if the address is within the loaded program range
-}
computeTargetAddress : AddressingMode -> Int -> Int -> Int -> Int -> Maybe Int
computeTargetAddress mode operand instrAddress loadAddress endAddress =
    let
        inRange addr =
            if addr >= loadAddress && addr < endAddress then
                Just addr

            else
                Nothing
    in
    case mode of
        Implied ->
            Nothing

        Accumulator ->
            Nothing

        Immediate ->
            Nothing

        ZeroPage ->
            inRange operand

        ZeroPageX ->
            inRange operand

        ZeroPageY ->
            inRange operand

        Absolute ->
            inRange operand

        AbsoluteX ->
            inRange operand

        AbsoluteY ->
            inRange operand

        Indirect ->
            inRange operand

        IndirectX ->
            inRange operand

        IndirectY ->
            inRange operand

        Relative ->
            let
                signedOffset =
                    if operand > 127 then
                        operand - 256

                    else
                        operand
            in
            inRange (instrAddress + 2 + signedOffset)


{-| Format a byte value as hex
-}
formatByte : Int -> String
formatByte n =
    "$" ++ toHex 2 n


{-| Format a word value as hex
-}
formatWord : Int -> String
formatWord n =
    "$" ++ toHex 4 n


{-| Format a byte, substituting symbol if available
-}
formatByteWithSymbol : Int -> String
formatByteWithSymbol addr =
    case getSymbol addr of
        Just sym ->
            sym

        Nothing ->
            formatByte addr


{-| Format a word, substituting symbol if available
-}
formatWordWithSymbol : Int -> String
formatWordWithSymbol addr =
    case getSymbol addr of
        Just sym ->
            sym

        Nothing ->
            formatWord addr


{-| Convert an integer to a hex string with specified width
-}
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
