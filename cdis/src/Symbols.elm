module Symbols exposing (getSymbol, getSymbolInfo, allSymbols, SymbolInfo)

import Dict exposing (Dict)


type alias SymbolInfo =
    { name : String
    , description : String
    }


{-| Look up a symbol name for a memory address
-}
getSymbol : Int -> Maybe String
getSymbol addr =
    Dict.get addr symbolTable
        |> Maybe.map .name


{-| Look up full symbol info (name + description) for a memory address
-}
getSymbolInfo : Int -> Maybe SymbolInfo
getSymbolInfo addr =
    Dict.get addr symbolTable


{-| All defined symbols as a list
-}
allSymbols : List ( Int, String )
allSymbols =
    Dict.toList symbolTable
        |> List.map (\( addr, info ) -> ( addr, info.name ))


{-| C64 memory map symbols with descriptions
-}
symbolTable : Dict Int SymbolInfo
symbolTable =
    Dict.fromList
        [ -- Zero Page - Common locations
          ( 0x01, { name = "CPU_PORT", description = "Processor port data direction and data registers" } )
        , ( 0x03, { name = "ADRAY1", description = "Vector to convert FAC to integer" } )
        , ( 0x05, { name = "ADRAY2", description = "Vector to convert integer to FAC" } )
        , ( 0x14, { name = "TXTPTR", description = "Pointer to current BASIC text character" } )
        , ( 0x2B, { name = "TXTTAB", description = "Pointer to start of BASIC program" } )
        , ( 0x2D, { name = "VARTAB", description = "Pointer to start of BASIC variables" } )
        , ( 0x31, { name = "STRTAB", description = "Pointer to start of string storage" } )
        , ( 0x33, { name = "FRETOP", description = "Pointer to top of string free space" } )
        , ( 0x37, { name = "MEMSIZ", description = "Pointer to highest BASIC RAM address" } )
        , ( 0x39, { name = "CURLIN", description = "Current BASIC line number" } )
        , ( 0x3D, { name = "FORPNT", description = "Pointer to current FOR/NEXT variable" } )
        , ( 0x61, { name = "FAC1", description = "Floating point accumulator 1" } )
        , ( 0x69, { name = "FAC2", description = "Floating point accumulator 2" } )
        , ( 0x7A, { name = "CHRGET", description = "Get next BASIC character subroutine" } )
        , ( 0x8B, { name = "CHRGOT", description = "Get current BASIC character subroutine" } )
        , ( 0x90, { name = "STATUS", description = "I/O operation status byte" } )
        , ( 0x91, { name = "STKEY", description = "STOP key flag" } )
        , ( 0x93, { name = "VERCK", description = "Load/verify flag (0=load, 1=verify)" } )
        , ( 0x94, { name = "C3PO", description = "IEEE output character buffer flag" } )
        , ( 0x97, { name = "XSAV", description = "Temp storage for X register" } )
        , ( 0x9D, { name = "MSGFLG", description = "Direct mode flag (bit 7) / error msg flag (bit 6)" } )
        , ( 0xA0, { name = "JIFFY_CLOCK", description = "60Hz jiffy clock (3 bytes, approx 24hr)" } )
        , ( 0xA3, { name = "BESSION", description = "Bit count for serial I/O" } )
        , ( 0xA4, { name = "TLNIDX", description = "Physical line number" } )
        , ( 0xB2, { name = "EAL", description = "End address (low byte) for load/save" } )
        , ( 0xB7, { name = "FNLEN", description = "Length of current filename" } )
        , ( 0xBA, { name = "FA", description = "Current device number" } )
        , ( 0xBB, { name = "FNADR", description = "Pointer to current filename" } )
        , ( 0xC5, { name = "LSTX", description = "Matrix coordinate of last keypress" } )
        , ( 0xC6, { name = "NDX", description = "Number of characters in keyboard buffer" } )
        , ( 0xCB, { name = "SFDX", description = "Current key pressed (matrix value)" } )
        , ( 0xCC, { name = "BLNSW", description = "Cursor blink enable (0=blink)" } )
        , ( 0xCE, { name = "GDBLN", description = "Character under cursor" } )
        , ( 0xD3, { name = "PNTR", description = "Cursor column position" } )
        , ( 0xD6, { name = "LNMX", description = "Max columns on current line" } )

        -- Screen RAM
        , ( 0x0400, { name = "SCREEN_RAM", description = "Default screen memory (1000 bytes)" } )

        -- BASIC ROM entry points
        , ( 0xA000, { name = "BASIC_COLD_START", description = "BASIC cold start entry point" } )
        , ( 0xA00C, { name = "BASIC_WARM_START", description = "BASIC warm start entry point" } )
        , ( 0xA533, { name = "BASIC_PRINT", description = "Print string routine" } )
        , ( 0xA560, { name = "BASIC_PRINT_INT", description = "Print integer routine" } )
        , ( 0xA8F8, { name = "BASIC_GETBYT", description = "Get byte value from BASIC expression" } )
        , ( 0xAD9E, { name = "BASIC_FRMNUM", description = "Evaluate numeric expression" } )
        , ( 0xAE83, { name = "BASIC_GETADR", description = "Get 16-bit address from FAC" } )
        , ( 0xB7F7, { name = "BASIC_MOVMF", description = "Move FAC to memory" } )
        , ( 0xBDCD, { name = "BASIC_PRINTSTR", description = "Print string from (Y,A)" } )

        -- KERNAL ROM entry points
        , ( 0xE500, { name = "CINT", description = "Initialize screen editor" } )
        , ( 0xE518, { name = "IOINIT_SCREEN", description = "Initialize I/O and screen" } )
        , ( 0xE544, { name = "CLEAR_SCREEN", description = "Clear screen" } )
        , ( 0xE566, { name = "HOME", description = "Move cursor to home position" } )
        , ( 0xE5A0, { name = "SET_CURSOR", description = "Set cursor position" } )
        , ( 0xE8EA, { name = "SCROLL_UP", description = "Scroll screen up" } )
        , ( 0xEA31, { name = "IRQ_HANDLER", description = "Default IRQ handler" } )
        , ( 0xEA87, { name = "SCNKEY", description = "Scan keyboard" } )
        , ( 0xF49E, { name = "LOAD_RAM", description = "Load file to RAM" } )
        , ( 0xF5ED, { name = "SAVE", description = "Save memory to file" } )
        , ( 0xF69B, { name = "SETHDR", description = "Set tape header" } )
        , ( 0xFD15, { name = "RESTOR", description = "Restore I/O vectors to default" } )
        , ( 0xFD50, { name = "RAMTAS", description = "RAM test and set" } )
        , ( 0xFDA3, { name = "IOINIT", description = "Initialize I/O devices" } )
        , ( 0xFDF9, { name = "SETMSG", description = "Set kernel message control" } )
        , ( 0xFE25, { name = "NMI_HANDLER", description = "Default NMI handler" } )
        , ( 0xFF43, { name = "IRQ_ENTRY", description = "IRQ entry point (after push)" } )
        , ( 0xFF48, { name = "NMI_ENTRY", description = "NMI entry point" } )

        -- KERNAL jump table
        , ( 0xFF81, { name = "CINT_JUMP", description = "Initialize screen editor" } )
        , ( 0xFF84, { name = "IOINIT_JUMP", description = "Initialize I/O devices" } )
        , ( 0xFF87, { name = "RAMTAS_JUMP", description = "RAM test and set pointers" } )
        , ( 0xFF8A, { name = "RESTOR_JUMP", description = "Restore default I/O vectors" } )
        , ( 0xFF8D, { name = "VECTOR", description = "Read/set I/O vector table" } )
        , ( 0xFF90, { name = "SETMSG_JUMP", description = "Control OS messages" } )
        , ( 0xFF93, { name = "SECOND", description = "Send secondary address after LISTEN" } )
        , ( 0xFF96, { name = "TKSA", description = "Send secondary address after TALK" } )
        , ( 0xFF99, { name = "MEMTOP", description = "Read/set top of memory" } )
        , ( 0xFF9C, { name = "MEMBOT", description = "Read/set bottom of memory" } )
        , ( 0xFF9F, { name = "SCNKEY_JUMP", description = "Scan keyboard" } )
        , ( 0xFFA2, { name = "SETTMO", description = "Set IEEE timeout" } )
        , ( 0xFFA5, { name = "ACPTR", description = "Input byte from serial bus" } )
        , ( 0xFFA8, { name = "CIOUT", description = "Output byte to serial bus" } )
        , ( 0xFFAB, { name = "UNTLK", description = "Command serial bus device to stop talking" } )
        , ( 0xFFAE, { name = "UNLSN", description = "Command serial bus device to stop listening" } )
        , ( 0xFFB1, { name = "LISTEN", description = "Command device to listen" } )
        , ( 0xFFB4, { name = "TALK", description = "Command device to talk" } )
        , ( 0xFFB7, { name = "READST", description = "Read I/O status byte" } )
        , ( 0xFFBA, { name = "SETLFS", description = "Set file parameters (logical/device/secondary)" } )
        , ( 0xFFBD, { name = "SETNAM", description = "Set filename" } )
        , ( 0xFFC0, { name = "OPEN", description = "Open logical file" } )
        , ( 0xFFC3, { name = "CLOSE", description = "Close logical file" } )
        , ( 0xFFC6, { name = "CHKIN", description = "Set input channel" } )
        , ( 0xFFC9, { name = "CHKOUT", description = "Set output channel" } )
        , ( 0xFFCC, { name = "CLRCHN", description = "Restore default I/O channels" } )
        , ( 0xFFCF, { name = "CHRIN", description = "Input character from channel" } )
        , ( 0xFFD2, { name = "CHROUT", description = "Output character to channel" } )
        , ( 0xFFD5, { name = "LOAD", description = "Load RAM from device" } )
        , ( 0xFFD8, { name = "SAVE", description = "Save RAM to device" } )
        , ( 0xFFDB, { name = "SETTIM", description = "Set jiffy clock" } )
        , ( 0xFFDE, { name = "RDTIM", description = "Read jiffy clock" } )
        , ( 0xFFE1, { name = "STOP", description = "Check STOP key" } )
        , ( 0xFFE4, { name = "GETIN", description = "Get character from keyboard buffer" } )
        , ( 0xFFE7, { name = "CLALL", description = "Close all files" } )
        , ( 0xFFEA, { name = "UDTIM", description = "Update jiffy clock" } )
        , ( 0xFFED, { name = "SCREEN", description = "Get screen size (columns/rows)" } )
        , ( 0xFFF0, { name = "PLOT", description = "Read/set cursor position" } )
        , ( 0xFFF3, { name = "IOBASE", description = "Get I/O base address" } )

        -- Hardware vectors
        , ( 0xFFFA, { name = "NMI_VECTOR", description = "Non-maskable interrupt vector" } )
        , ( 0xFFFC, { name = "RESET_VECTOR", description = "Reset vector" } )
        , ( 0xFFFE, { name = "IRQ_VECTOR", description = "Interrupt request vector" } )

        -- VIC-II Registers
        , ( 0xD000, { name = "VIC_SPRITE0_X", description = "Sprite 0 X position (bits 0-7)" } )
        , ( 0xD001, { name = "VIC_SPRITE0_Y", description = "Sprite 0 Y position" } )
        , ( 0xD002, { name = "VIC_SPRITE1_X", description = "Sprite 1 X position (bits 0-7)" } )
        , ( 0xD003, { name = "VIC_SPRITE1_Y", description = "Sprite 1 Y position" } )
        , ( 0xD004, { name = "VIC_SPRITE2_X", description = "Sprite 2 X position (bits 0-7)" } )
        , ( 0xD005, { name = "VIC_SPRITE2_Y", description = "Sprite 2 Y position" } )
        , ( 0xD006, { name = "VIC_SPRITE3_X", description = "Sprite 3 X position (bits 0-7)" } )
        , ( 0xD007, { name = "VIC_SPRITE3_Y", description = "Sprite 3 Y position" } )
        , ( 0xD008, { name = "VIC_SPRITE4_X", description = "Sprite 4 X position (bits 0-7)" } )
        , ( 0xD009, { name = "VIC_SPRITE4_Y", description = "Sprite 4 Y position" } )
        , ( 0xD00A, { name = "VIC_SPRITE5_X", description = "Sprite 5 X position (bits 0-7)" } )
        , ( 0xD00B, { name = "VIC_SPRITE5_Y", description = "Sprite 5 Y position" } )
        , ( 0xD00C, { name = "VIC_SPRITE6_X", description = "Sprite 6 X position (bits 0-7)" } )
        , ( 0xD00D, { name = "VIC_SPRITE6_Y", description = "Sprite 6 Y position" } )
        , ( 0xD00E, { name = "VIC_SPRITE7_X", description = "Sprite 7 X position (bits 0-7)" } )
        , ( 0xD00F, { name = "VIC_SPRITE7_Y", description = "Sprite 7 Y position" } )
        , ( 0xD010, { name = "VIC_SPRITES_X_MSB", description = "Sprites 0-7 X position bit 8" } )
        , ( 0xD011, { name = "VIC_CONTROL1", description = "Screen control: Y scroll, screen height, mode, raster bit 8" } )
        , ( 0xD012, { name = "VIC_RASTER", description = "Raster line (bits 0-7, read) / IRQ trigger line (write)" } )
        , ( 0xD013, { name = "VIC_LIGHT_PEN_X", description = "Light pen X position" } )
        , ( 0xD014, { name = "VIC_LIGHT_PEN_Y", description = "Light pen Y position" } )
        , ( 0xD015, { name = "VIC_SPRITE_ENABLE", description = "Sprite enable bits (1=enabled)" } )
        , ( 0xD016, { name = "VIC_CONTROL2", description = "Screen control: X scroll, screen width, multicolor mode" } )
        , ( 0xD017, { name = "VIC_SPRITE_EXPAND_Y", description = "Sprite Y expansion (1=double height)" } )
        , ( 0xD018, { name = "VIC_MEMORY_SETUP", description = "Screen and character memory pointers" } )
        , ( 0xD019, { name = "VIC_IRQ_STATUS", description = "Interrupt status (raster, sprite collision, etc.)" } )
        , ( 0xD01A, { name = "VIC_IRQ_ENABLE", description = "Interrupt enable mask" } )
        , ( 0xD01B, { name = "VIC_SPRITE_PRIORITY", description = "Sprite-to-background priority (0=sprite in front)" } )
        , ( 0xD01C, { name = "VIC_SPRITE_MULTICOLOR", description = "Sprite multicolor mode (1=multicolor)" } )
        , ( 0xD01D, { name = "VIC_SPRITE_EXPAND_X", description = "Sprite X expansion (1=double width)" } )
        , ( 0xD01E, { name = "VIC_SPRITE_COLLISION", description = "Sprite-sprite collision (read to clear)" } )
        , ( 0xD01F, { name = "VIC_SPRITE_BG_COLLISION", description = "Sprite-background collision (read to clear)" } )
        , ( 0xD020, { name = "VIC_BORDER_COLOR", description = "Border color (0-15)" } )
        , ( 0xD021, { name = "VIC_BG_COLOR0", description = "Background color 0 (0-15)" } )
        , ( 0xD022, { name = "VIC_BG_COLOR1", description = "Background color 1 for multicolor (0-15)" } )
        , ( 0xD023, { name = "VIC_BG_COLOR2", description = "Background color 2 for multicolor (0-15)" } )
        , ( 0xD024, { name = "VIC_BG_COLOR3", description = "Background color 3 for ECM mode (0-15)" } )
        , ( 0xD025, { name = "VIC_SPRITE_MC0", description = "Sprite multicolor 0 (shared color 1)" } )
        , ( 0xD026, { name = "VIC_SPRITE_MC1", description = "Sprite multicolor 1 (shared color 3)" } )
        , ( 0xD027, { name = "VIC_SPRITE0_COLOR", description = "Sprite 0 color" } )
        , ( 0xD028, { name = "VIC_SPRITE1_COLOR", description = "Sprite 1 color" } )
        , ( 0xD029, { name = "VIC_SPRITE2_COLOR", description = "Sprite 2 color" } )
        , ( 0xD02A, { name = "VIC_SPRITE3_COLOR", description = "Sprite 3 color" } )
        , ( 0xD02B, { name = "VIC_SPRITE4_COLOR", description = "Sprite 4 color" } )
        , ( 0xD02C, { name = "VIC_SPRITE5_COLOR", description = "Sprite 5 color" } )
        , ( 0xD02D, { name = "VIC_SPRITE6_COLOR", description = "Sprite 6 color" } )
        , ( 0xD02E, { name = "VIC_SPRITE7_COLOR", description = "Sprite 7 color" } )

        -- SID Registers
        , ( 0xD400, { name = "SID_V1_FREQ_LO", description = "Voice 1 frequency low byte" } )
        , ( 0xD401, { name = "SID_V1_FREQ_HI", description = "Voice 1 frequency high byte" } )
        , ( 0xD402, { name = "SID_V1_PW_LO", description = "Voice 1 pulse width low byte" } )
        , ( 0xD403, { name = "SID_V1_PW_HI", description = "Voice 1 pulse width high nybble (bits 0-3)" } )
        , ( 0xD404, { name = "SID_V1_CONTROL", description = "Voice 1 control: gate, sync, ring, waveform" } )
        , ( 0xD405, { name = "SID_V1_ATTACK_DECAY", description = "Voice 1 attack (hi nybble) / decay (lo nybble)" } )
        , ( 0xD406, { name = "SID_V1_SUSTAIN_RELEASE", description = "Voice 1 sustain (hi nybble) / release (lo nybble)" } )
        , ( 0xD407, { name = "SID_V2_FREQ_LO", description = "Voice 2 frequency low byte" } )
        , ( 0xD408, { name = "SID_V2_FREQ_HI", description = "Voice 2 frequency high byte" } )
        , ( 0xD409, { name = "SID_V2_PW_LO", description = "Voice 2 pulse width low byte" } )
        , ( 0xD40A, { name = "SID_V2_PW_HI", description = "Voice 2 pulse width high nybble (bits 0-3)" } )
        , ( 0xD40B, { name = "SID_V2_CONTROL", description = "Voice 2 control: gate, sync, ring, waveform" } )
        , ( 0xD40C, { name = "SID_V2_ATTACK_DECAY", description = "Voice 2 attack (hi nybble) / decay (lo nybble)" } )
        , ( 0xD40D, { name = "SID_V2_SUSTAIN_RELEASE", description = "Voice 2 sustain (hi nybble) / release (lo nybble)" } )
        , ( 0xD40E, { name = "SID_V3_FREQ_LO", description = "Voice 3 frequency low byte" } )
        , ( 0xD40F, { name = "SID_V3_FREQ_HI", description = "Voice 3 frequency high byte" } )
        , ( 0xD410, { name = "SID_V3_PW_LO", description = "Voice 3 pulse width low byte" } )
        , ( 0xD411, { name = "SID_V3_PW_HI", description = "Voice 3 pulse width high nybble (bits 0-3)" } )
        , ( 0xD412, { name = "SID_V3_CONTROL", description = "Voice 3 control: gate, sync, ring, waveform" } )
        , ( 0xD413, { name = "SID_V3_ATTACK_DECAY", description = "Voice 3 attack (hi nybble) / decay (lo nybble)" } )
        , ( 0xD414, { name = "SID_V3_SUSTAIN_RELEASE", description = "Voice 3 sustain (hi nybble) / release (lo nybble)" } )
        , ( 0xD415, { name = "SID_FILTER_FREQ_LO", description = "Filter cutoff frequency low byte (bits 0-2)" } )
        , ( 0xD416, { name = "SID_FILTER_FREQ_HI", description = "Filter cutoff frequency high byte" } )
        , ( 0xD417, { name = "SID_FILTER_RESONANCE", description = "Filter resonance / voice routing" } )
        , ( 0xD418, { name = "SID_VOLUME_FILTER", description = "Master volume (lo nybble) / filter mode (hi nybble)" } )
        , ( 0xD419, { name = "SID_POT_X", description = "Paddle X position (active joystick port)" } )
        , ( 0xD41A, { name = "SID_POT_Y", description = "Paddle Y position (active joystick port)" } )
        , ( 0xD41B, { name = "SID_OSC3_RANDOM", description = "Voice 3 oscillator output / random number" } )
        , ( 0xD41C, { name = "SID_ENV3", description = "Voice 3 envelope output" } )

        -- CIA 1
        , ( 0xDC00, { name = "CIA1_PORT_A", description = "Port A: keyboard column / joystick 2" } )
        , ( 0xDC01, { name = "CIA1_PORT_B", description = "Port B: keyboard row / joystick 1" } )
        , ( 0xDC02, { name = "CIA1_DDR_A", description = "Port A data direction (1=output)" } )
        , ( 0xDC03, { name = "CIA1_DDR_B", description = "Port B data direction (1=output)" } )
        , ( 0xDC04, { name = "CIA1_TIMER_A_LO", description = "Timer A low byte" } )
        , ( 0xDC05, { name = "CIA1_TIMER_A_HI", description = "Timer A high byte" } )
        , ( 0xDC06, { name = "CIA1_TIMER_B_LO", description = "Timer B low byte" } )
        , ( 0xDC07, { name = "CIA1_TIMER_B_HI", description = "Timer B high byte" } )
        , ( 0xDC08, { name = "CIA1_TOD_TENTHS", description = "Time of day: tenths of seconds" } )
        , ( 0xDC09, { name = "CIA1_TOD_SEC", description = "Time of day: seconds (BCD)" } )
        , ( 0xDC0A, { name = "CIA1_TOD_MIN", description = "Time of day: minutes (BCD)" } )
        , ( 0xDC0B, { name = "CIA1_TOD_HR", description = "Time of day: hours (BCD, bit 7=PM)" } )
        , ( 0xDC0C, { name = "CIA1_SERIAL", description = "Serial shift register" } )
        , ( 0xDC0D, { name = "CIA1_IRQ_CONTROL", description = "Interrupt control/status (timer, TOD, serial)" } )
        , ( 0xDC0E, { name = "CIA1_CONTROL_A", description = "Timer A control (start, mode, etc.)" } )
        , ( 0xDC0F, { name = "CIA1_CONTROL_B", description = "Timer B control (start, mode, etc.)" } )

        -- CIA 2
        , ( 0xDD00, { name = "CIA2_PORT_A", description = "Port A: VIC bank, serial bus, RS-232" } )
        , ( 0xDD01, { name = "CIA2_PORT_B", description = "Port B: user port" } )
        , ( 0xDD02, { name = "CIA2_DDR_A", description = "Port A data direction (1=output)" } )
        , ( 0xDD03, { name = "CIA2_DDR_B", description = "Port B data direction (1=output)" } )
        , ( 0xDD04, { name = "CIA2_TIMER_A_LO", description = "Timer A low byte" } )
        , ( 0xDD05, { name = "CIA2_TIMER_A_HI", description = "Timer A high byte" } )
        , ( 0xDD06, { name = "CIA2_TIMER_B_LO", description = "Timer B low byte" } )
        , ( 0xDD07, { name = "CIA2_TIMER_B_HI", description = "Timer B high byte" } )
        , ( 0xDD08, { name = "CIA2_TOD_TENTHS", description = "Time of day: tenths of seconds" } )
        , ( 0xDD09, { name = "CIA2_TOD_SEC", description = "Time of day: seconds (BCD)" } )
        , ( 0xDD0A, { name = "CIA2_TOD_MIN", description = "Time of day: minutes (BCD)" } )
        , ( 0xDD0B, { name = "CIA2_TOD_HR", description = "Time of day: hours (BCD, bit 7=PM)" } )
        , ( 0xDD0C, { name = "CIA2_SERIAL", description = "Serial shift register" } )
        , ( 0xDD0D, { name = "CIA2_NMI_CONTROL", description = "NMI control/status (timer, TOD, serial)" } )
        , ( 0xDD0E, { name = "CIA2_CONTROL_A", description = "Timer A control (start, mode, etc.)" } )
        , ( 0xDD0F, { name = "CIA2_CONTROL_B", description = "Timer B control (start, mode, etc.)" } )

        -- Color RAM
        , ( 0xD800, { name = "COLOR_RAM", description = "Color memory (1000 nybbles, bits 0-3)" } )
        ]
