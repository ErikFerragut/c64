module Opcodes exposing (getOpcode, opcodeBytes)

import Array exposing (Array)
import Types exposing (AddressingMode(..), OpcodeInfo)


{-| Get opcode info for a given byte value
-}
getOpcode : Int -> OpcodeInfo
getOpcode byte =
    Array.get byte opcodeTable
        |> Maybe.withDefault unknownOpcode


{-| Get the number of bytes for an opcode
-}
opcodeBytes : Int -> Int
opcodeBytes byte =
    (getOpcode byte).bytes


unknownOpcode : OpcodeInfo
unknownOpcode =
    OpcodeInfo "???" Implied 1 2 True


{-| Complete 6502 opcode table (256 entries)
    Includes undocumented opcodes marked as such
-}
opcodeTable : Array OpcodeInfo
opcodeTable =
    Array.fromList
        [ -- $00-$0F
          OpcodeInfo "BRK" Implied 1 7 False
        , OpcodeInfo "ORA" IndirectX 2 6 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "SLO" IndirectX 2 8 True
        , OpcodeInfo "NOP" ZeroPage 2 3 True
        , OpcodeInfo "ORA" ZeroPage 2 3 False
        , OpcodeInfo "ASL" ZeroPage 2 5 False
        , OpcodeInfo "SLO" ZeroPage 2 5 True
        , OpcodeInfo "PHP" Implied 1 3 False
        , OpcodeInfo "ORA" Immediate 2 2 False
        , OpcodeInfo "ASL" Accumulator 1 2 False
        , OpcodeInfo "ANC" Immediate 2 2 True
        , OpcodeInfo "NOP" Absolute 3 4 True
        , OpcodeInfo "ORA" Absolute 3 4 False
        , OpcodeInfo "ASL" Absolute 3 6 False
        , OpcodeInfo "SLO" Absolute 3 6 True
          -- $10-$1F
        , OpcodeInfo "BPL" Relative 2 2 False
        , OpcodeInfo "ORA" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "SLO" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "ORA" ZeroPageX 2 4 False
        , OpcodeInfo "ASL" ZeroPageX 2 6 False
        , OpcodeInfo "SLO" ZeroPageX 2 6 True
        , OpcodeInfo "CLC" Implied 1 2 False
        , OpcodeInfo "ORA" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "SLO" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "ORA" AbsoluteX 3 4 False
        , OpcodeInfo "ASL" AbsoluteX 3 7 False
        , OpcodeInfo "SLO" AbsoluteX 3 7 True
          -- $20-$2F
        , OpcodeInfo "JSR" Absolute 3 6 False
        , OpcodeInfo "AND" IndirectX 2 6 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "RLA" IndirectX 2 8 True
        , OpcodeInfo "BIT" ZeroPage 2 3 False
        , OpcodeInfo "AND" ZeroPage 2 3 False
        , OpcodeInfo "ROL" ZeroPage 2 5 False
        , OpcodeInfo "RLA" ZeroPage 2 5 True
        , OpcodeInfo "PLP" Implied 1 4 False
        , OpcodeInfo "AND" Immediate 2 2 False
        , OpcodeInfo "ROL" Accumulator 1 2 False
        , OpcodeInfo "ANC" Immediate 2 2 True
        , OpcodeInfo "BIT" Absolute 3 4 False
        , OpcodeInfo "AND" Absolute 3 4 False
        , OpcodeInfo "ROL" Absolute 3 6 False
        , OpcodeInfo "RLA" Absolute 3 6 True
          -- $30-$3F
        , OpcodeInfo "BMI" Relative 2 2 False
        , OpcodeInfo "AND" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "RLA" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "AND" ZeroPageX 2 4 False
        , OpcodeInfo "ROL" ZeroPageX 2 6 False
        , OpcodeInfo "RLA" ZeroPageX 2 6 True
        , OpcodeInfo "SEC" Implied 1 2 False
        , OpcodeInfo "AND" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "RLA" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "AND" AbsoluteX 3 4 False
        , OpcodeInfo "ROL" AbsoluteX 3 7 False
        , OpcodeInfo "RLA" AbsoluteX 3 7 True
          -- $40-$4F
        , OpcodeInfo "RTI" Implied 1 6 False
        , OpcodeInfo "EOR" IndirectX 2 6 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "SRE" IndirectX 2 8 True
        , OpcodeInfo "NOP" ZeroPage 2 3 True
        , OpcodeInfo "EOR" ZeroPage 2 3 False
        , OpcodeInfo "LSR" ZeroPage 2 5 False
        , OpcodeInfo "SRE" ZeroPage 2 5 True
        , OpcodeInfo "PHA" Implied 1 3 False
        , OpcodeInfo "EOR" Immediate 2 2 False
        , OpcodeInfo "LSR" Accumulator 1 2 False
        , OpcodeInfo "ALR" Immediate 2 2 True
        , OpcodeInfo "JMP" Absolute 3 3 False
        , OpcodeInfo "EOR" Absolute 3 4 False
        , OpcodeInfo "LSR" Absolute 3 6 False
        , OpcodeInfo "SRE" Absolute 3 6 True
          -- $50-$5F
        , OpcodeInfo "BVC" Relative 2 2 False
        , OpcodeInfo "EOR" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "SRE" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "EOR" ZeroPageX 2 4 False
        , OpcodeInfo "LSR" ZeroPageX 2 6 False
        , OpcodeInfo "SRE" ZeroPageX 2 6 True
        , OpcodeInfo "CLI" Implied 1 2 False
        , OpcodeInfo "EOR" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "SRE" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "EOR" AbsoluteX 3 4 False
        , OpcodeInfo "LSR" AbsoluteX 3 7 False
        , OpcodeInfo "SRE" AbsoluteX 3 7 True
          -- $60-$6F
        , OpcodeInfo "RTS" Implied 1 6 False
        , OpcodeInfo "ADC" IndirectX 2 6 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "RRA" IndirectX 2 8 True
        , OpcodeInfo "NOP" ZeroPage 2 3 True
        , OpcodeInfo "ADC" ZeroPage 2 3 False
        , OpcodeInfo "ROR" ZeroPage 2 5 False
        , OpcodeInfo "RRA" ZeroPage 2 5 True
        , OpcodeInfo "PLA" Implied 1 4 False
        , OpcodeInfo "ADC" Immediate 2 2 False
        , OpcodeInfo "ROR" Accumulator 1 2 False
        , OpcodeInfo "ARR" Immediate 2 2 True
        , OpcodeInfo "JMP" Indirect 3 5 False
        , OpcodeInfo "ADC" Absolute 3 4 False
        , OpcodeInfo "ROR" Absolute 3 6 False
        , OpcodeInfo "RRA" Absolute 3 6 True
          -- $70-$7F
        , OpcodeInfo "BVS" Relative 2 2 False
        , OpcodeInfo "ADC" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "RRA" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "ADC" ZeroPageX 2 4 False
        , OpcodeInfo "ROR" ZeroPageX 2 6 False
        , OpcodeInfo "RRA" ZeroPageX 2 6 True
        , OpcodeInfo "SEI" Implied 1 2 False
        , OpcodeInfo "ADC" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "RRA" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "ADC" AbsoluteX 3 4 False
        , OpcodeInfo "ROR" AbsoluteX 3 7 False
        , OpcodeInfo "RRA" AbsoluteX 3 7 True
          -- $80-$8F
        , OpcodeInfo "NOP" Immediate 2 2 True
        , OpcodeInfo "STA" IndirectX 2 6 False
        , OpcodeInfo "NOP" Immediate 2 2 True
        , OpcodeInfo "SAX" IndirectX 2 6 True
        , OpcodeInfo "STY" ZeroPage 2 3 False
        , OpcodeInfo "STA" ZeroPage 2 3 False
        , OpcodeInfo "STX" ZeroPage 2 3 False
        , OpcodeInfo "SAX" ZeroPage 2 3 True
        , OpcodeInfo "DEY" Implied 1 2 False
        , OpcodeInfo "NOP" Immediate 2 2 True
        , OpcodeInfo "TXA" Implied 1 2 False
        , OpcodeInfo "ANE" Immediate 2 2 True
        , OpcodeInfo "STY" Absolute 3 4 False
        , OpcodeInfo "STA" Absolute 3 4 False
        , OpcodeInfo "STX" Absolute 3 4 False
        , OpcodeInfo "SAX" Absolute 3 4 True
          -- $90-$9F
        , OpcodeInfo "BCC" Relative 2 2 False
        , OpcodeInfo "STA" IndirectY 2 6 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "SHA" IndirectY 2 6 True
        , OpcodeInfo "STY" ZeroPageX 2 4 False
        , OpcodeInfo "STA" ZeroPageX 2 4 False
        , OpcodeInfo "STX" ZeroPageY 2 4 False
        , OpcodeInfo "SAX" ZeroPageY 2 4 True
        , OpcodeInfo "TYA" Implied 1 2 False
        , OpcodeInfo "STA" AbsoluteY 3 5 False
        , OpcodeInfo "TXS" Implied 1 2 False
        , OpcodeInfo "TAS" AbsoluteY 3 5 True
        , OpcodeInfo "SHY" AbsoluteX 3 5 True
        , OpcodeInfo "STA" AbsoluteX 3 5 False
        , OpcodeInfo "SHX" AbsoluteY 3 5 True
        , OpcodeInfo "SHA" AbsoluteY 3 5 True
          -- $A0-$AF
        , OpcodeInfo "LDY" Immediate 2 2 False
        , OpcodeInfo "LDA" IndirectX 2 6 False
        , OpcodeInfo "LDX" Immediate 2 2 False
        , OpcodeInfo "LAX" IndirectX 2 6 True
        , OpcodeInfo "LDY" ZeroPage 2 3 False
        , OpcodeInfo "LDA" ZeroPage 2 3 False
        , OpcodeInfo "LDX" ZeroPage 2 3 False
        , OpcodeInfo "LAX" ZeroPage 2 3 True
        , OpcodeInfo "TAY" Implied 1 2 False
        , OpcodeInfo "LDA" Immediate 2 2 False
        , OpcodeInfo "TAX" Implied 1 2 False
        , OpcodeInfo "LXA" Immediate 2 2 True
        , OpcodeInfo "LDY" Absolute 3 4 False
        , OpcodeInfo "LDA" Absolute 3 4 False
        , OpcodeInfo "LDX" Absolute 3 4 False
        , OpcodeInfo "LAX" Absolute 3 4 True
          -- $B0-$BF
        , OpcodeInfo "BCS" Relative 2 2 False
        , OpcodeInfo "LDA" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "LAX" IndirectY 2 5 True
        , OpcodeInfo "LDY" ZeroPageX 2 4 False
        , OpcodeInfo "LDA" ZeroPageX 2 4 False
        , OpcodeInfo "LDX" ZeroPageY 2 4 False
        , OpcodeInfo "LAX" ZeroPageY 2 4 True
        , OpcodeInfo "CLV" Implied 1 2 False
        , OpcodeInfo "LDA" AbsoluteY 3 4 False
        , OpcodeInfo "TSX" Implied 1 2 False
        , OpcodeInfo "LAS" AbsoluteY 3 4 True
        , OpcodeInfo "LDY" AbsoluteX 3 4 False
        , OpcodeInfo "LDA" AbsoluteX 3 4 False
        , OpcodeInfo "LDX" AbsoluteY 3 4 False
        , OpcodeInfo "LAX" AbsoluteY 3 4 True
          -- $C0-$CF
        , OpcodeInfo "CPY" Immediate 2 2 False
        , OpcodeInfo "CMP" IndirectX 2 6 False
        , OpcodeInfo "NOP" Immediate 2 2 True
        , OpcodeInfo "DCP" IndirectX 2 8 True
        , OpcodeInfo "CPY" ZeroPage 2 3 False
        , OpcodeInfo "CMP" ZeroPage 2 3 False
        , OpcodeInfo "DEC" ZeroPage 2 5 False
        , OpcodeInfo "DCP" ZeroPage 2 5 True
        , OpcodeInfo "INY" Implied 1 2 False
        , OpcodeInfo "CMP" Immediate 2 2 False
        , OpcodeInfo "DEX" Implied 1 2 False
        , OpcodeInfo "SBX" Immediate 2 2 True
        , OpcodeInfo "CPY" Absolute 3 4 False
        , OpcodeInfo "CMP" Absolute 3 4 False
        , OpcodeInfo "DEC" Absolute 3 6 False
        , OpcodeInfo "DCP" Absolute 3 6 True
          -- $D0-$DF
        , OpcodeInfo "BNE" Relative 2 2 False
        , OpcodeInfo "CMP" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "DCP" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "CMP" ZeroPageX 2 4 False
        , OpcodeInfo "DEC" ZeroPageX 2 6 False
        , OpcodeInfo "DCP" ZeroPageX 2 6 True
        , OpcodeInfo "CLD" Implied 1 2 False
        , OpcodeInfo "CMP" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "DCP" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "CMP" AbsoluteX 3 4 False
        , OpcodeInfo "DEC" AbsoluteX 3 7 False
        , OpcodeInfo "DCP" AbsoluteX 3 7 True
          -- $E0-$EF
        , OpcodeInfo "CPX" Immediate 2 2 False
        , OpcodeInfo "SBC" IndirectX 2 6 False
        , OpcodeInfo "NOP" Immediate 2 2 True
        , OpcodeInfo "ISC" IndirectX 2 8 True
        , OpcodeInfo "CPX" ZeroPage 2 3 False
        , OpcodeInfo "SBC" ZeroPage 2 3 False
        , OpcodeInfo "INC" ZeroPage 2 5 False
        , OpcodeInfo "ISC" ZeroPage 2 5 True
        , OpcodeInfo "INX" Implied 1 2 False
        , OpcodeInfo "SBC" Immediate 2 2 False
        , OpcodeInfo "NOP" Implied 1 2 False
        , OpcodeInfo "SBC" Immediate 2 2 True
        , OpcodeInfo "CPX" Absolute 3 4 False
        , OpcodeInfo "SBC" Absolute 3 4 False
        , OpcodeInfo "INC" Absolute 3 6 False
        , OpcodeInfo "ISC" Absolute 3 6 True
          -- $F0-$FF
        , OpcodeInfo "BEQ" Relative 2 2 False
        , OpcodeInfo "SBC" IndirectY 2 5 False
        , OpcodeInfo "JAM" Implied 1 2 True
        , OpcodeInfo "ISC" IndirectY 2 8 True
        , OpcodeInfo "NOP" ZeroPageX 2 4 True
        , OpcodeInfo "SBC" ZeroPageX 2 4 False
        , OpcodeInfo "INC" ZeroPageX 2 6 False
        , OpcodeInfo "ISC" ZeroPageX 2 6 True
        , OpcodeInfo "SED" Implied 1 2 False
        , OpcodeInfo "SBC" AbsoluteY 3 4 False
        , OpcodeInfo "NOP" Implied 1 2 True
        , OpcodeInfo "ISC" AbsoluteY 3 7 True
        , OpcodeInfo "NOP" AbsoluteX 3 4 True
        , OpcodeInfo "SBC" AbsoluteX 3 4 False
        , OpcodeInfo "INC" AbsoluteX 3 7 False
        , OpcodeInfo "ISC" AbsoluteX 3 7 True
        ]
