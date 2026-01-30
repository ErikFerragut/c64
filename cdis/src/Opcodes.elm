module Opcodes exposing (getOpcode, opcodeBytes, getOpcodeDescription, getOpcodeFlags, addressingModeString)

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


{-| Get description of what an opcode does
-}
getOpcodeDescription : String -> String
getOpcodeDescription mnemonic =
    case String.toUpper mnemonic of
        -- Load/Store
        "LDA" -> "Load Accumulator from memory"
        "LDX" -> "Load X register from memory"
        "LDY" -> "Load Y register from memory"
        "STA" -> "Store Accumulator to memory"
        "STX" -> "Store X register to memory"
        "STY" -> "Store Y register to memory"
        -- Transfer
        "TAX" -> "Transfer Accumulator to X"
        "TAY" -> "Transfer Accumulator to Y"
        "TXA" -> "Transfer X to Accumulator"
        "TYA" -> "Transfer Y to Accumulator"
        "TSX" -> "Transfer Stack Pointer to X"
        "TXS" -> "Transfer X to Stack Pointer"
        -- Stack
        "PHA" -> "Push Accumulator to stack"
        "PHP" -> "Push Processor Status to stack"
        "PLA" -> "Pull Accumulator from stack"
        "PLP" -> "Pull Processor Status from stack"
        -- Arithmetic
        "ADC" -> "Add to Accumulator with Carry"
        "SBC" -> "Subtract from Accumulator with Borrow"
        "INC" -> "Increment memory by one"
        "INX" -> "Increment X by one"
        "INY" -> "Increment Y by one"
        "DEC" -> "Decrement memory by one"
        "DEX" -> "Decrement X by one"
        "DEY" -> "Decrement Y by one"
        -- Logic
        "AND" -> "Logical AND with Accumulator"
        "ORA" -> "Logical OR with Accumulator"
        "EOR" -> "Exclusive OR with Accumulator"
        "BIT" -> "Test bits in memory with Accumulator"
        -- Shift
        "ASL" -> "Arithmetic Shift Left (C <- [76543210] <- 0)"
        "LSR" -> "Logical Shift Right (0 -> [76543210] -> C)"
        "ROL" -> "Rotate Left (C <- [76543210] <- C)"
        "ROR" -> "Rotate Right (C -> [76543210] -> C)"
        -- Compare
        "CMP" -> "Compare Accumulator with memory"
        "CPX" -> "Compare X with memory"
        "CPY" -> "Compare Y with memory"
        -- Branch
        "BCC" -> "Branch if Carry Clear (C=0)"
        "BCS" -> "Branch if Carry Set (C=1)"
        "BEQ" -> "Branch if Equal (Z=1)"
        "BMI" -> "Branch if Minus (N=1)"
        "BNE" -> "Branch if Not Equal (Z=0)"
        "BPL" -> "Branch if Plus (N=0)"
        "BVC" -> "Branch if Overflow Clear (V=0)"
        "BVS" -> "Branch if Overflow Set (V=1)"
        -- Jump/Call
        "JMP" -> "Jump to address"
        "JSR" -> "Jump to Subroutine (push return address)"
        "RTS" -> "Return from Subroutine"
        "RTI" -> "Return from Interrupt"
        "BRK" -> "Force Break (software interrupt)"
        -- Flags
        "CLC" -> "Clear Carry flag"
        "CLD" -> "Clear Decimal mode"
        "CLI" -> "Clear Interrupt Disable"
        "CLV" -> "Clear Overflow flag"
        "SEC" -> "Set Carry flag"
        "SED" -> "Set Decimal mode"
        "SEI" -> "Set Interrupt Disable"
        -- Misc
        "NOP" -> "No Operation"
        -- Undocumented
        "LAX" -> "LDA + LDX (load A and X)"
        "SAX" -> "Store A AND X to memory"
        "DCP" -> "DEC + CMP (decrement then compare)"
        "ISC" -> "INC + SBC (increment then subtract)"
        "SLO" -> "ASL + ORA (shift left then OR)"
        "RLA" -> "ROL + AND (rotate left then AND)"
        "SRE" -> "LSR + EOR (shift right then XOR)"
        "RRA" -> "ROR + ADC (rotate right then add)"
        "ANC" -> "AND + set Carry from bit 7"
        "ALR" -> "AND + LSR (AND then shift right)"
        "ARR" -> "AND + ROR (AND then rotate right)"
        "SBX" -> "(A AND X) minus operand -> X"
        "ANE" -> "A = (A OR magic) AND X AND operand"
        "LXA" -> "A = X = (A OR magic) AND operand"
        "SHA" -> "Store A AND X AND (addr_hi + 1)"
        "SHX" -> "Store X AND (addr_hi + 1)"
        "SHY" -> "Store Y AND (addr_hi + 1)"
        "TAS" -> "S = A AND X; store S AND (addr_hi + 1)"
        "LAS" -> "A = X = S = memory AND S"
        "JAM" -> "Halt processor (freeze/crash)"
        _ -> "Unknown opcode"


{-| Get flags affected by an opcode
-}
getOpcodeFlags : String -> String
getOpcodeFlags mnemonic =
    case String.toUpper mnemonic of
        -- Load/Store
        "LDA" -> "N Z"
        "LDX" -> "N Z"
        "LDY" -> "N Z"
        "STA" -> "-"
        "STX" -> "-"
        "STY" -> "-"
        -- Transfer
        "TAX" -> "N Z"
        "TAY" -> "N Z"
        "TXA" -> "N Z"
        "TYA" -> "N Z"
        "TSX" -> "N Z"
        "TXS" -> "-"
        -- Stack
        "PHA" -> "-"
        "PHP" -> "-"
        "PLA" -> "N Z"
        "PLP" -> "all"
        -- Arithmetic
        "ADC" -> "N V Z C"
        "SBC" -> "N V Z C"
        "INC" -> "N Z"
        "INX" -> "N Z"
        "INY" -> "N Z"
        "DEC" -> "N Z"
        "DEX" -> "N Z"
        "DEY" -> "N Z"
        -- Logic
        "AND" -> "N Z"
        "ORA" -> "N Z"
        "EOR" -> "N Z"
        "BIT" -> "N V Z"
        -- Shift
        "ASL" -> "N Z C"
        "LSR" -> "N Z C"
        "ROL" -> "N Z C"
        "ROR" -> "N Z C"
        -- Compare
        "CMP" -> "N Z C"
        "CPX" -> "N Z C"
        "CPY" -> "N Z C"
        -- Branch
        "BCC" -> "-"
        "BCS" -> "-"
        "BEQ" -> "-"
        "BMI" -> "-"
        "BNE" -> "-"
        "BPL" -> "-"
        "BVC" -> "-"
        "BVS" -> "-"
        -- Jump/Call
        "JMP" -> "-"
        "JSR" -> "-"
        "RTS" -> "-"
        "RTI" -> "all"
        "BRK" -> "B I"
        -- Flags
        "CLC" -> "C"
        "CLD" -> "D"
        "CLI" -> "I"
        "CLV" -> "V"
        "SEC" -> "C"
        "SED" -> "D"
        "SEI" -> "I"
        -- Misc
        "NOP" -> "-"
        -- Undocumented (approximations)
        "LAX" -> "N Z"
        "SAX" -> "-"
        "DCP" -> "N Z C"
        "ISC" -> "N V Z C"
        "SLO" -> "N Z C"
        "RLA" -> "N Z C"
        "SRE" -> "N Z C"
        "RRA" -> "N V Z C"
        "ANC" -> "N Z C"
        "ALR" -> "N Z C"
        "ARR" -> "N V Z C"
        "SBX" -> "N Z C"
        "ANE" -> "N Z"
        "LXA" -> "N Z"
        "SHA" -> "-"
        "SHX" -> "-"
        "SHY" -> "-"
        "TAS" -> "-"
        "LAS" -> "N Z"
        "JAM" -> "-"
        _ -> "?"


{-| Get human-readable addressing mode string
-}
addressingModeString : AddressingMode -> String
addressingModeString mode =
    case mode of
        Implied -> "Implied"
        Accumulator -> "Accumulator"
        Immediate -> "Immediate"
        ZeroPage -> "Zero Page"
        ZeroPageX -> "Zero Page,X"
        ZeroPageY -> "Zero Page,Y"
        Absolute -> "Absolute"
        AbsoluteX -> "Absolute,X"
        AbsoluteY -> "Absolute,Y"
        Indirect -> "Indirect"
        IndirectX -> "Indirect,X"
        IndirectY -> "Indirect,Y"
        Relative -> "Relative"


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
