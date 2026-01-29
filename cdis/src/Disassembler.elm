module Disassembler exposing (disassemble, disassembleRange, formatOperand)

import Array exposing (Array)
import Dict exposing (Dict)
import Opcodes exposing (getOpcode, opcodeBytes)
import Symbols exposing (getSymbol)
import Types exposing (AddressingMode(..), Line, OpcodeInfo)


{-| Disassemble a range of bytes starting at a given offset
    Returns a list of disassembled lines
-}
disassembleRange : Int -> Int -> Int -> Array Int -> Dict Int String -> List Line
disassembleRange loadAddress startOffset count bytes comments =
    disassembleHelper loadAddress startOffset count bytes comments []


disassembleHelper : Int -> Int -> Int -> Array Int -> Dict Int String -> List Line -> List Line
disassembleHelper loadAddress offset remaining bytes comments acc =
    if remaining <= 0 || offset >= Array.length bytes then
        List.reverse acc

    else
        let
            line =
                disassembleLine loadAddress offset bytes comments

            newOffset =
                offset + List.length line.bytes

            newRemaining =
                remaining - 1
        in
        disassembleHelper loadAddress newOffset newRemaining bytes comments (line :: acc)


{-| Disassemble a single instruction at the given offset
-}
disassemble : Int -> Int -> Array Int -> Dict Int String -> Line
disassemble loadAddress offset bytes comments =
    disassembleLine loadAddress offset bytes comments


disassembleLine : Int -> Int -> Array Int -> Dict Int String -> Line
disassembleLine loadAddress offset bytes comments =
    case Array.get offset bytes of
        Nothing ->
            { offset = offset
            , address = loadAddress + offset
            , bytes = []
            , disassembly = "; end of file"
            , comment = Dict.get offset comments
            }

        Just opcodeByte ->
            let
                info =
                    getOpcode opcodeByte

                instrBytes =
                    getInstructionBytes offset info.bytes bytes

                address =
                    loadAddress + offset

                operandValue =
                    getOperandValue instrBytes

                disasm =
                    formatInstruction info operandValue address
            in
            { offset = offset
            , address = address
            , bytes = instrBytes
            , disassembly = disasm
            , comment = Dict.get offset comments
            }


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
