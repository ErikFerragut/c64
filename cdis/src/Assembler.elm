module Assembler exposing (assemble, AssembleResult, AssembleError(..))

import Array exposing (Array)
import Dict exposing (Dict)
import Types exposing (AddressingMode(..))


type alias AssembleResult =
    { bytes : List Int
    , size : Int
    }


type AssembleError
    = UnknownMnemonic String
    | InvalidOperand String
    | InvalidAddressingMode String AddressingMode
    | OperandOutOfRange Int
    | BranchOutOfRange Int


{-| Assemble an instruction string into bytes.
    Takes the current address (for relative branch calculation).
    Returns either the assembled bytes or an error.
-}
assemble : Int -> String -> Result AssembleError AssembleResult
assemble currentAddress input =
    let
        cleaned =
            input
                |> String.trim
                |> String.toUpper
    in
    case parseInstruction cleaned of
        Err err ->
            Err err

        Ok ( mnemonic, mode, operand ) ->
            case lookupOpcode mnemonic mode of
                Nothing ->
                    -- Try alternative modes (e.g., ZeroPage vs Absolute)
                    tryAlternativeModes currentAddress mnemonic mode operand

                Just opcode ->
                    encodeInstruction currentAddress opcode mode operand


{-| Try alternative addressing modes when exact match fails.
    E.g., user types "LDA $80" - could be ZeroPage or Absolute.
-}
tryAlternativeModes : Int -> String -> AddressingMode -> Int -> Result AssembleError AssembleResult
tryAlternativeModes currentAddress mnemonic mode operand =
    let
        alternatives =
            case mode of
                ZeroPage ->
                    [ Absolute ]

                Absolute ->
                    if operand < 256 then
                        [ ZeroPage ]
                    else
                        []

                ZeroPageX ->
                    [ AbsoluteX ]

                AbsoluteX ->
                    if operand < 256 then
                        [ ZeroPageX ]
                    else
                        []

                ZeroPageY ->
                    [ AbsoluteY ]

                AbsoluteY ->
                    if operand < 256 then
                        [ ZeroPageY ]
                    else
                        []

                _ ->
                    []

        tryMode m =
            lookupOpcode mnemonic m
                |> Maybe.andThen (\op -> encodeInstruction currentAddress op m operand |> Result.toMaybe)
    in
    case List.filterMap tryMode alternatives of
        result :: _ ->
            Ok result

        [] ->
            -- Check if mnemonic exists at all
            if mnemonicExists mnemonic then
                Err (InvalidAddressingMode mnemonic mode)
            else
                Err (UnknownMnemonic mnemonic)


{-| Check if a mnemonic exists in any addressing mode
-}
mnemonicExists : String -> Bool
mnemonicExists mnemonic =
    List.any (\( m, _ ) -> m == mnemonic) opcodeList


{-| Parse an instruction string into (mnemonic, addressing mode, operand value)
-}
parseInstruction : String -> Result AssembleError ( String, AddressingMode, Int )
parseInstruction input =
    let
        parts =
            String.words input
    in
    case parts of
        [] ->
            Err (UnknownMnemonic "")

        [ mnemonic ] ->
            -- Implied mode (NOP, RTS, etc.)
            Ok ( mnemonic, Implied, 0 )

        [ mnemonic, operandStr ] ->
            parseOperand mnemonic operandStr

        _ ->
            -- Try joining with space removed (handles "LDA $40 , X" edge cases)
            parseOperand (List.head parts |> Maybe.withDefault "")
                (List.drop 1 parts |> String.join "")


{-| Parse the operand and determine addressing mode
-}
parseOperand : String -> String -> Result AssembleError ( String, AddressingMode, Int )
parseOperand mnemonic operandStr =
    let
        operand =
            String.trim operandStr
    in
    if operand == "A" then
        -- Accumulator mode
        Ok ( mnemonic, Accumulator, 0 )

    else if String.startsWith "#" operand then
        -- Immediate mode: #$xx or #xx
        parseImmediate mnemonic (String.dropLeft 1 operand)

    else if String.startsWith "(" operand then
        -- Indirect modes
        parseIndirect mnemonic operand

    else if String.contains "," operand then
        -- Indexed modes
        parseIndexed mnemonic operand

    else
        -- Direct addressing (zero page or absolute)
        parseDirect mnemonic operand


parseImmediate : String -> String -> Result AssembleError ( String, AddressingMode, Int )
parseImmediate mnemonic valueStr =
    case parseValue valueStr of
        Just value ->
            if value < 256 then
                Ok ( mnemonic, Immediate, value )
            else
                Err (OperandOutOfRange value)

        Nothing ->
            Err (InvalidOperand valueStr)


parseIndirect : String -> String -> Result AssembleError ( String, AddressingMode, Int )
parseIndirect mnemonic operand =
    if String.endsWith ",X)" operand then
        -- Indirect,X: ($xx,X)
        let
            valueStr =
                operand
                    |> String.dropLeft 1
                    |> String.dropRight 3
                    |> String.trim
        in
        case parseValue valueStr of
            Just value ->
                if value < 256 then
                    Ok ( mnemonic, IndirectX, value )
                else
                    Err (OperandOutOfRange value)

            Nothing ->
                Err (InvalidOperand valueStr)

    else if String.endsWith "),Y" operand then
        -- Indirect,Y: ($xx),Y
        let
            valueStr =
                operand
                    |> String.dropLeft 1
                    |> String.dropRight 3
                    |> String.trim
        in
        case parseValue valueStr of
            Just value ->
                if value < 256 then
                    Ok ( mnemonic, IndirectY, value )
                else
                    Err (OperandOutOfRange value)

            Nothing ->
                Err (InvalidOperand valueStr)

    else if String.endsWith ")" operand then
        -- Indirect: ($xxxx)
        let
            valueStr =
                operand
                    |> String.dropLeft 1
                    |> String.dropRight 1
                    |> String.trim
        in
        case parseValue valueStr of
            Just value ->
                Ok ( mnemonic, Indirect, value )

            Nothing ->
                Err (InvalidOperand valueStr)

    else
        Err (InvalidOperand operand)


parseIndexed : String -> String -> Result AssembleError ( String, AddressingMode, Int )
parseIndexed mnemonic operand =
    let
        parts =
            String.split "," operand
                |> List.map String.trim
    in
    case parts of
        [ valueStr, "X" ] ->
            case parseValue valueStr of
                Just value ->
                    if value < 256 then
                        Ok ( mnemonic, ZeroPageX, value )
                    else
                        Ok ( mnemonic, AbsoluteX, value )

                Nothing ->
                    Err (InvalidOperand valueStr)

        [ valueStr, "Y" ] ->
            case parseValue valueStr of
                Just value ->
                    if value < 256 then
                        Ok ( mnemonic, ZeroPageY, value )
                    else
                        Ok ( mnemonic, AbsoluteY, value )

                Nothing ->
                    Err (InvalidOperand valueStr)

        _ ->
            Err (InvalidOperand operand)


parseDirect : String -> String -> Result AssembleError ( String, AddressingMode, Int )
parseDirect mnemonic valueStr =
    case parseValue valueStr of
        Just value ->
            -- Check if this is a branch instruction
            if isBranchMnemonic mnemonic then
                Ok ( mnemonic, Relative, value )
            else if value < 256 && String.length (String.filter Char.isHexDigit valueStr) <= 2 then
                -- Prefer zero page for small values with <= 2 hex digits
                Ok ( mnemonic, ZeroPage, value )
            else
                Ok ( mnemonic, Absolute, value )

        Nothing ->
            Err (InvalidOperand valueStr)


{-| Parse a numeric value (supports $hex and decimal)
-}
parseValue : String -> Maybe Int
parseValue str =
    let
        cleaned =
            String.trim str
    in
    if String.startsWith "$" cleaned then
        parseHex (String.dropLeft 1 cleaned)
    else
        String.toInt cleaned


parseHex : String -> Maybe Int
parseHex str =
    let
        hexChars =
            String.toList (String.toUpper str)

        toDigit c =
            case c of
                '0' -> Just 0
                '1' -> Just 1
                '2' -> Just 2
                '3' -> Just 3
                '4' -> Just 4
                '5' -> Just 5
                '6' -> Just 6
                '7' -> Just 7
                '8' -> Just 8
                '9' -> Just 9
                'A' -> Just 10
                'B' -> Just 11
                'C' -> Just 12
                'D' -> Just 13
                'E' -> Just 14
                'F' -> Just 15
                _ -> Nothing

        folder c acc =
            case ( acc, toDigit c ) of
                ( Just n, Just d ) ->
                    Just (n * 16 + d)

                _ ->
                    Nothing
    in
    if String.isEmpty str then
        Nothing
    else
        List.foldl folder (Just 0) hexChars


isBranchMnemonic : String -> Bool
isBranchMnemonic mnemonic =
    List.member mnemonic
        [ "BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS" ]


{-| Encode an instruction to bytes
-}
encodeInstruction : Int -> Int -> AddressingMode -> Int -> Result AssembleError AssembleResult
encodeInstruction currentAddress opcode mode operand =
    case mode of
        Implied ->
            Ok { bytes = [ opcode ], size = 1 }

        Accumulator ->
            Ok { bytes = [ opcode ], size = 1 }

        Immediate ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        ZeroPage ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        ZeroPageX ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        ZeroPageY ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        Absolute ->
            let
                lo = modBy 256 operand
                hi = operand // 256
            in
            Ok { bytes = [ opcode, lo, hi ], size = 3 }

        AbsoluteX ->
            let
                lo = modBy 256 operand
                hi = operand // 256
            in
            Ok { bytes = [ opcode, lo, hi ], size = 3 }

        AbsoluteY ->
            let
                lo = modBy 256 operand
                hi = operand // 256
            in
            Ok { bytes = [ opcode, lo, hi ], size = 3 }

        Indirect ->
            let
                lo = modBy 256 operand
                hi = operand // 256
            in
            Ok { bytes = [ opcode, lo, hi ], size = 3 }

        IndirectX ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        IndirectY ->
            Ok { bytes = [ opcode, operand ], size = 2 }

        Relative ->
            let
                -- Target address is the operand
                -- Offset is relative to the NEXT instruction (currentAddress + 2)
                nextAddr = currentAddress + 2
                offset = operand - nextAddr
            in
            if offset < -128 || offset > 127 then
                Err (BranchOutOfRange offset)
            else
                let
                    signedByte =
                        if offset < 0 then
                            256 + offset
                        else
                            offset
                in
                Ok { bytes = [ opcode, signedByte ], size = 2 }


{-| Look up opcode byte for (mnemonic, mode) combination
-}
lookupOpcode : String -> AddressingMode -> Maybe Int
lookupOpcode mnemonic mode =
    Dict.get ( mnemonic, addressingModeToInt mode ) opcodeDict


{-| Convert addressing mode to int for Dict key
-}
addressingModeToInt : AddressingMode -> Int
addressingModeToInt mode =
    case mode of
        Implied -> 0
        Accumulator -> 1
        Immediate -> 2
        ZeroPage -> 3
        ZeroPageX -> 4
        ZeroPageY -> 5
        Absolute -> 6
        AbsoluteX -> 7
        AbsoluteY -> 8
        Indirect -> 9
        IndirectX -> 10
        IndirectY -> 11
        Relative -> 12


{-| Reverse lookup table: (mnemonic, mode) -> opcode byte
    Built from the opcode table at module load time.
-}
opcodeDict : Dict ( String, Int ) Int
opcodeDict =
    List.indexedMap Tuple.pair opcodeList
        |> List.filterMap
            (\( byte, ( mnemonic, mode ) ) ->
                if mnemonic /= "???" && mnemonic /= "JAM" then
                    Just ( ( mnemonic, addressingModeToInt mode ), byte )
                else
                    Nothing
            )
        |> Dict.fromList


{-| List of (mnemonic, mode) for each opcode 0-255
-}
opcodeList : List ( String, AddressingMode )
opcodeList =
    [ -- $00-$0F
      ( "BRK", Implied )
    , ( "ORA", IndirectX )
    , ( "JAM", Implied )
    , ( "SLO", IndirectX )
    , ( "NOP", ZeroPage )
    , ( "ORA", ZeroPage )
    , ( "ASL", ZeroPage )
    , ( "SLO", ZeroPage )
    , ( "PHP", Implied )
    , ( "ORA", Immediate )
    , ( "ASL", Accumulator )
    , ( "ANC", Immediate )
    , ( "NOP", Absolute )
    , ( "ORA", Absolute )
    , ( "ASL", Absolute )
    , ( "SLO", Absolute )
      -- $10-$1F
    , ( "BPL", Relative )
    , ( "ORA", IndirectY )
    , ( "JAM", Implied )
    , ( "SLO", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "ORA", ZeroPageX )
    , ( "ASL", ZeroPageX )
    , ( "SLO", ZeroPageX )
    , ( "CLC", Implied )
    , ( "ORA", AbsoluteY )
    , ( "NOP", Implied )
    , ( "SLO", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "ORA", AbsoluteX )
    , ( "ASL", AbsoluteX )
    , ( "SLO", AbsoluteX )
      -- $20-$2F
    , ( "JSR", Absolute )
    , ( "AND", IndirectX )
    , ( "JAM", Implied )
    , ( "RLA", IndirectX )
    , ( "BIT", ZeroPage )
    , ( "AND", ZeroPage )
    , ( "ROL", ZeroPage )
    , ( "RLA", ZeroPage )
    , ( "PLP", Implied )
    , ( "AND", Immediate )
    , ( "ROL", Accumulator )
    , ( "ANC", Immediate )
    , ( "BIT", Absolute )
    , ( "AND", Absolute )
    , ( "ROL", Absolute )
    , ( "RLA", Absolute )
      -- $30-$3F
    , ( "BMI", Relative )
    , ( "AND", IndirectY )
    , ( "JAM", Implied )
    , ( "RLA", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "AND", ZeroPageX )
    , ( "ROL", ZeroPageX )
    , ( "RLA", ZeroPageX )
    , ( "SEC", Implied )
    , ( "AND", AbsoluteY )
    , ( "NOP", Implied )
    , ( "RLA", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "AND", AbsoluteX )
    , ( "ROL", AbsoluteX )
    , ( "RLA", AbsoluteX )
      -- $40-$4F
    , ( "RTI", Implied )
    , ( "EOR", IndirectX )
    , ( "JAM", Implied )
    , ( "SRE", IndirectX )
    , ( "NOP", ZeroPage )
    , ( "EOR", ZeroPage )
    , ( "LSR", ZeroPage )
    , ( "SRE", ZeroPage )
    , ( "PHA", Implied )
    , ( "EOR", Immediate )
    , ( "LSR", Accumulator )
    , ( "ALR", Immediate )
    , ( "JMP", Absolute )
    , ( "EOR", Absolute )
    , ( "LSR", Absolute )
    , ( "SRE", Absolute )
      -- $50-$5F
    , ( "BVC", Relative )
    , ( "EOR", IndirectY )
    , ( "JAM", Implied )
    , ( "SRE", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "EOR", ZeroPageX )
    , ( "LSR", ZeroPageX )
    , ( "SRE", ZeroPageX )
    , ( "CLI", Implied )
    , ( "EOR", AbsoluteY )
    , ( "NOP", Implied )
    , ( "SRE", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "EOR", AbsoluteX )
    , ( "LSR", AbsoluteX )
    , ( "SRE", AbsoluteX )
      -- $60-$6F
    , ( "RTS", Implied )
    , ( "ADC", IndirectX )
    , ( "JAM", Implied )
    , ( "RRA", IndirectX )
    , ( "NOP", ZeroPage )
    , ( "ADC", ZeroPage )
    , ( "ROR", ZeroPage )
    , ( "RRA", ZeroPage )
    , ( "PLA", Implied )
    , ( "ADC", Immediate )
    , ( "ROR", Accumulator )
    , ( "ARR", Immediate )
    , ( "JMP", Indirect )
    , ( "ADC", Absolute )
    , ( "ROR", Absolute )
    , ( "RRA", Absolute )
      -- $70-$7F
    , ( "BVS", Relative )
    , ( "ADC", IndirectY )
    , ( "JAM", Implied )
    , ( "RRA", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "ADC", ZeroPageX )
    , ( "ROR", ZeroPageX )
    , ( "RRA", ZeroPageX )
    , ( "SEI", Implied )
    , ( "ADC", AbsoluteY )
    , ( "NOP", Implied )
    , ( "RRA", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "ADC", AbsoluteX )
    , ( "ROR", AbsoluteX )
    , ( "RRA", AbsoluteX )
      -- $80-$8F
    , ( "NOP", Immediate )
    , ( "STA", IndirectX )
    , ( "NOP", Immediate )
    , ( "SAX", IndirectX )
    , ( "STY", ZeroPage )
    , ( "STA", ZeroPage )
    , ( "STX", ZeroPage )
    , ( "SAX", ZeroPage )
    , ( "DEY", Implied )
    , ( "NOP", Immediate )
    , ( "TXA", Implied )
    , ( "ANE", Immediate )
    , ( "STY", Absolute )
    , ( "STA", Absolute )
    , ( "STX", Absolute )
    , ( "SAX", Absolute )
      -- $90-$9F
    , ( "BCC", Relative )
    , ( "STA", IndirectY )
    , ( "JAM", Implied )
    , ( "SHA", IndirectY )
    , ( "STY", ZeroPageX )
    , ( "STA", ZeroPageX )
    , ( "STX", ZeroPageY )
    , ( "SAX", ZeroPageY )
    , ( "TYA", Implied )
    , ( "STA", AbsoluteY )
    , ( "TXS", Implied )
    , ( "TAS", AbsoluteY )
    , ( "SHY", AbsoluteX )
    , ( "STA", AbsoluteX )
    , ( "SHX", AbsoluteY )
    , ( "SHA", AbsoluteY )
      -- $A0-$AF
    , ( "LDY", Immediate )
    , ( "LDA", IndirectX )
    , ( "LDX", Immediate )
    , ( "LAX", IndirectX )
    , ( "LDY", ZeroPage )
    , ( "LDA", ZeroPage )
    , ( "LDX", ZeroPage )
    , ( "LAX", ZeroPage )
    , ( "TAY", Implied )
    , ( "LDA", Immediate )
    , ( "TAX", Implied )
    , ( "LXA", Immediate )
    , ( "LDY", Absolute )
    , ( "LDA", Absolute )
    , ( "LDX", Absolute )
    , ( "LAX", Absolute )
      -- $B0-$BF
    , ( "BCS", Relative )
    , ( "LDA", IndirectY )
    , ( "JAM", Implied )
    , ( "LAX", IndirectY )
    , ( "LDY", ZeroPageX )
    , ( "LDA", ZeroPageX )
    , ( "LDX", ZeroPageY )
    , ( "LAX", ZeroPageY )
    , ( "CLV", Implied )
    , ( "LDA", AbsoluteY )
    , ( "TSX", Implied )
    , ( "LAS", AbsoluteY )
    , ( "LDY", AbsoluteX )
    , ( "LDA", AbsoluteX )
    , ( "LDX", AbsoluteY )
    , ( "LAX", AbsoluteY )
      -- $C0-$CF
    , ( "CPY", Immediate )
    , ( "CMP", IndirectX )
    , ( "NOP", Immediate )
    , ( "DCP", IndirectX )
    , ( "CPY", ZeroPage )
    , ( "CMP", ZeroPage )
    , ( "DEC", ZeroPage )
    , ( "DCP", ZeroPage )
    , ( "INY", Implied )
    , ( "CMP", Immediate )
    , ( "DEX", Implied )
    , ( "SBX", Immediate )
    , ( "CPY", Absolute )
    , ( "CMP", Absolute )
    , ( "DEC", Absolute )
    , ( "DCP", Absolute )
      -- $D0-$DF
    , ( "BNE", Relative )
    , ( "CMP", IndirectY )
    , ( "JAM", Implied )
    , ( "DCP", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "CMP", ZeroPageX )
    , ( "DEC", ZeroPageX )
    , ( "DCP", ZeroPageX )
    , ( "CLD", Implied )
    , ( "CMP", AbsoluteY )
    , ( "NOP", Implied )
    , ( "DCP", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "CMP", AbsoluteX )
    , ( "DEC", AbsoluteX )
    , ( "DCP", AbsoluteX )
      -- $E0-$EF
    , ( "CPX", Immediate )
    , ( "SBC", IndirectX )
    , ( "NOP", Immediate )
    , ( "ISC", IndirectX )
    , ( "CPX", ZeroPage )
    , ( "SBC", ZeroPage )
    , ( "INC", ZeroPage )
    , ( "ISC", ZeroPage )
    , ( "INX", Implied )
    , ( "SBC", Immediate )
    , ( "NOP", Implied )
    , ( "SBC", Immediate )
    , ( "CPX", Absolute )
    , ( "SBC", Absolute )
    , ( "INC", Absolute )
    , ( "ISC", Absolute )
      -- $F0-$FF
    , ( "BEQ", Relative )
    , ( "SBC", IndirectY )
    , ( "JAM", Implied )
    , ( "ISC", IndirectY )
    , ( "NOP", ZeroPageX )
    , ( "SBC", ZeroPageX )
    , ( "INC", ZeroPageX )
    , ( "ISC", ZeroPageX )
    , ( "SED", Implied )
    , ( "SBC", AbsoluteY )
    , ( "NOP", Implied )
    , ( "ISC", AbsoluteY )
    , ( "NOP", AbsoluteX )
    , ( "SBC", AbsoluteX )
    , ( "INC", AbsoluteX )
    , ( "ISC", AbsoluteX )
    ]
