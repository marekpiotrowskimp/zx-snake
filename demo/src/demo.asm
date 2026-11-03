;; zxSnake demo with splashscreen, animation and beeper music

        ORG 32768

SCREEN          EQU $4000
SCREEN_ATTR     EQU $5800
BLACK           EQU 0
GREEN           EQU 4
YELLOW          EQU 6
CYAN            EQU 5
WHITE           EQU 7
BRIGHT          EQU $40
ATTR_GREEN      EQU BRIGHT + GREEN
ATTR_YELLOW     EQU BRIGHT + YELLOW
ATTR_CYAN       EQU BRIGHT + CYAN
ATTR_WHITE      EQU BRIGHT + WHITE

start:
        DI
        LD SP, $FFFF
        IM 1
        EI
        CALL copy_splash_full
        CALL splash_pause
        CALL splash_show
        CALL flash_bars
        CALL phase_distort
        CALL copy_qr_full
        CALL qr_phase_blip
        CALL copy_qr_full
qr_loop:
        CALL play_melody_note
        JR qr_loop

splash_show:
        LD B, 48
splash_scroll_loop:
        PUSH BC
        CALL scroll_up_8
        CALL cycle_attrs
        CALL play_melody_note
        POP BC
        DJNZ splash_scroll_loop
        RET

splash_pause:
        LD B, 90
splash_wait:
        HALT
        DJNZ splash_wait
        RET

clear_screen:
        XOR A
        LD HL, SCREEN
        LD DE, SCREEN + 1
        LD BC, 6143
        LD (HL), A
        LDIR
        LD A, ATTR_GREEN
        LD HL, SCREEN_ATTR
        LD DE, SCREEN_ATTR + 1
        LD BC, 767
        LD (HL), A
        LDIR
        RET

draw_scene:
        LD B, 10
        LD C, 2
        LD HL, txt_title
        CALL print_string
        LD B, 6
        LD C, 4
        LD HL, txt_demo
        CALL print_string
        LD B, 5
        LD C, 20
        LD HL, txt_press
        CALL print_string

        LD B, 6
        LD C, 7
        LD HL, spr_apple
        CALL draw_sprite
        LD B, 24
        LD C, 7
        LD HL, spr_cherry
        CALL draw_sprite
        LD A, (fruit_frame)
        OR A
        JR Z, fruit_a
        LD HL, spr_grapes2
        JR fruit_draw
fruit_a:
        LD HL, spr_grapes
fruit_draw:
        LD B, 15
        LD C, 6
        CALL draw_sprite

        CALL draw_snake
        RET

draw_snake:
        LD A, (snake_x)
        LD B, A
        LD A, (snake_y)
        LD C, A
        LD HL, spr_head_right
        CALL draw_sprite

        LD A, (snake_x)
        DEC A
        LD B, A
        LD A, (snake_y)
        LD C, A
        LD HL, spr_body_h
        CALL draw_sprite

        LD A, (snake_x)
        DEC A
        DEC A
        LD B, A
        LD A, (snake_y)
        LD C, A
        LD HL, spr_body_h
        CALL draw_sprite

        LD A, (snake_x)
        DEC A
        DEC A
        DEC A
        LD B, A
        LD A, (snake_y)
        LD C, A
        LD HL, spr_body_h
        CALL draw_sprite

        LD A, (snake_x)
        DEC A
        DEC A
        DEC A
        DEC A
        LD B, A
        LD A, (snake_y)
        LD C, A
        LD HL, spr_tail_left
        CALL draw_sprite
        RET

draw_sprite:
        PUSH HL
        LD A, C
        CALL char_addr
        LD A, B
        ADD A, L
        LD L, A
        JR NC, ds_addr_ok
        INC H
ds_addr_ok:
        EX DE, HL
        POP HL
        LD B, 16
ds_row:
        LD A, (HL)
        LD (DE), A
        INC HL
        INC DE
        LD A, (HL)
        LD (DE), A
        INC HL
        DEC DE
        CALL next_screen_line
        DJNZ ds_row
        RET

draw_char:
        PUSH AF
        LD A, C
        CALL char_addr
        LD A, B
        ADD A, L
        LD L, A
        JR NC, dc_addr_ok
        INC H
dc_addr_ok:
        EX DE, HL
        POP AF
        CALL font_ptr
        LD B, 8
dc_row:
        LD A, (HL)
        LD (DE), A
        INC HL
        CALL next_screen_line
        DJNZ dc_row
        RET

print_string:
        LD A, (HL)
        OR A
        RET Z
        PUSH HL
        PUSH BC
        CALL draw_char
        POP BC
        POP HL
        INC HL
        INC B
        JR print_string

font_ptr:
        CP ' '
        JR NZ, fp_digit
        LD HL, font_space
        RET
fp_digit:
        CP '0'
        JR C, fp_dash
        CP '9' + 1
        JR NC, fp_alpha
        SUB '0'
        ADD A, A
        ADD A, A
        ADD A, A
        LD E, A
        LD D, 0
        LD HL, font_0
        ADD HL, DE
        RET
fp_alpha:
        CP 'A'
        JR C, fp_dash
        CP 'Z' + 1
        JR NC, fp_dash
        SUB 'A'
        ADD A, A
        ADD A, A
        ADD A, A
        LD E, A
        LD D, 0
        LD HL, font_A
        ADD HL, DE
        RET
fp_dash:
        CP '-'
        JR NZ, fp_excl
        LD HL, font_dash
        RET
fp_excl:
        CP '!'
        JR NZ, fp_space
        LD HL, font_excl
        RET
fp_space:
        LD HL, font_space
        RET

char_addr:
        LD L, A
        LD H, 0
        ADD HL, HL
        LD DE, char_rows
        ADD HL, DE
        LD E, (HL)
        INC HL
        LD D, (HL)
        EX DE, HL
        RET

next_screen_line:
        INC H
        LD A, H
        AND 7
        RET NZ
        LD A, H
        SUB 8
        LD H, A
        LD A, L
        ADD A, 32
        LD L, A
        RET NC
        LD A, H
        ADD A, 8
        LD H, A
        RET

check_key:
        LD A, $FE
        IN A, ($FE)
        CPL
        AND $1F
        RET NZ
        LD A, $FD
        IN A, ($FE)
        CPL
        AND $1F
        RET

play_melody_note:
        LD HL, melody_pos
        LD A, (HL)
        ADD A, A
        ADD A, A
        LD E, A
        LD D, 0
        LD HL, melody_demo
        ADD HL, DE
        LD A, (HL)
        OR A
        JR NZ, pdp_note
        XOR A
        LD (melody_pos), A
        JR play_melody_note
pdp_note:
        LD E, (HL)
        INC HL
        LD D, (HL)
        INC HL
        LD C, (HL)
        INC HL
        LD B, (HL)
        PUSH BC
        EX DE, HL
        POP DE
        CALL play_tone
        LD A, (melody_pos)
        INC A
        LD (melody_pos), A
        RET

play_tone:
        DI
pb_outer:
        PUSH DE
        LD A, (beep_state)
        XOR $10
        LD (beep_state), A
        LD A, (beep_state)
        BIT 4, A
        LD A, $02
        JR Z, pb_out
        OR $14
pb_out:
        OUT ($FE), A
        PUSH HL
        POP BC
pb_delay:
        DEC BC
        LD A, B
        OR C
        JR NZ, pb_delay
        POP DE
        DEC DE
        LD A, D
        OR E
        JR NZ, pb_outer
        XOR A
        OUT ($FE), A
        EI
        RET

scroll_up_8:
        XOR A
        CALL save_screen_row
        LD C, 0
scroll_move_loop:
        LD A, C
        INC A
        LD B, A
        LD A, C
        CALL copy_screen_row
        INC C
        LD A, C
        CP 23
        JR NZ, scroll_move_loop
        LD A, 23
        CALL restore_screen_row
        RET

save_screen_row:
        LD C, A
        CALL row_addr
        LD DE, row_buffer
        LD B, 8
save_row_line:
        PUSH BC
        PUSH HL
        LD BC, 32
        LDIR
        POP HL
        CALL next_screen_line
        POP BC
        DJNZ save_row_line
        RET

restore_screen_row:
        LD C, A
        CALL row_addr
        EX DE, HL
        LD HL, row_buffer
        LD B, 8
restore_row_line:
        PUSH BC
        PUSH DE
        LD BC, 32
        LDIR
        POP DE
        EX DE, HL
        CALL next_screen_line
        EX DE, HL
        POP BC
        DJNZ restore_row_line
        RET

copy_screen_row:
        PUSH AF
        LD A, B
        LD C, A
        CALL row_addr
        LD (src_ptr), HL
        POP AF
        LD C, A
        CALL row_addr
        LD (dst_ptr), HL
        LD B, 8
copy_screen_line:
        PUSH BC
        LD HL, (src_ptr)
        LD DE, (dst_ptr)
        LD BC, 32
        LDIR
        LD HL, (src_ptr)
        CALL next_screen_line
        LD (src_ptr), HL
        LD HL, (dst_ptr)
        CALL next_screen_line
        LD (dst_ptr), HL
        POP BC
        DJNZ copy_screen_line
        RET

copy_qr_row:
        PUSH AF
        CALL row_addr
        EX DE, HL
        POP AF
        CALL qr_row_addr
        LD B, 8
copy_qr_line:
        PUSH BC
        PUSH DE
        PUSH HL
        LD BC, 32
        LDIR
        POP HL
        CALL next_scr_data_line
        EX DE, HL
        POP HL
        CALL next_screen_line
        EX DE, HL
        POP BC
        DJNZ copy_qr_line
        PUSH DE
        LD A, C
        CALL copy_qr_attr_row
        POP DE
        RET

copy_qr_attr_row:
        LD L, A
        LD H, 0
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        LD DE, qr_screen + 6144
        ADD HL, DE
        LD D, H
        LD E, L
        LD L, A
        LD H, 0
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        LD BC, SCREEN_ATTR
        ADD HL, BC
        EX DE, HL
        LD BC, 32
        LDIR
        RET

cycle_attrs:
        LD A, (attr_phase)
        INC A
        AND 3
        LD (attr_phase), A
        LD E, A
        LD D, 0
        LD HL, attr_colors
        ADD HL, DE
        LD A, (HL)
        LD HL, SCREEN_ATTR
        LD DE, SCREEN_ATTR + 1
        LD BC, 767
        LD (HL), A
        LDIR
        RET

flash_bars:
        LD B, 12
flash_loop:
        PUSH BC
        LD HL, SCREEN_ATTR
        LD B, 24
        LD A, (attr_phase)
flash_row:
        PUSH BC
        LD C, 32
        XOR $42
flash_col:
        LD (HL), A
        INC HL
        DEC C
        JR NZ, flash_col
        POP BC
        DJNZ flash_row
        LD A, (attr_phase)
        INC A
        LD (attr_phase), A
        CALL play_melody_note
        POP BC
        DJNZ flash_loop
        RET

phase_distort:
        LD B, 14
pd_loop:
        PUSH BC
        LD C, 3
        CALL shift_row_right
        LD C, 6
        CALL shift_row_left
        LD C, 9
        CALL shift_row_right
        LD C, 12
        CALL shift_row_left
        LD C, 15
        CALL shift_row_right
        LD C, 18
        CALL shift_row_left
        CALL play_melody_note
        POP BC
        DJNZ pd_loop
        RET

qr_phase_blip:
        LD B, 3
qpb_loop:
        PUSH BC
        LD C, 7
        CALL shift_row_right
        LD C, 12
        CALL shift_row_left
        LD C, 17
        CALL shift_row_right
        CALL play_melody_note
        POP BC
        DJNZ qpb_loop
        RET

shift_row_right:
        CALL row_addr
        LD B, 8
srr_loop:
        PUSH BC
        PUSH HL
        CALL shift_line_right
        POP HL
        CALL next_screen_line
        POP BC
        DJNZ srr_loop
        RET

shift_row_left:
        CALL row_addr
        LD B, 8
srl_loop:
        PUSH BC
        PUSH HL
        CALL shift_line_left
        POP HL
        CALL next_screen_line
        POP BC
        DJNZ srl_loop
        RET

shift_line_right:
        PUSH HL
        LD DE, 31
        ADD HL, DE
        LD A, (HL)
        LD (tmp_byte), A
        LD D, H
        LD E, L
        DEC HL
        LD BC, 31
        LDDR
        POP HL
        LD A, (tmp_byte)
        LD (HL), A
        RET

shift_line_left:
        PUSH HL
        LD A, (HL)
        LD (tmp_byte), A
        LD D, H
        LD E, L
        INC HL
        LD BC, 31
        LDIR
        DEC DE
        LD A, (tmp_byte)
        LD (DE), A
        POP HL
        RET

copy_splash_full:
        LD HL, splash_screen
        LD DE, SCREEN
        LD BC, 6912
        LDIR
        RET

copy_qr_full:
        LD HL, qr_screen
        LD DE, SCREEN
        LD BC, 6912
        LDIR
        RET

qr_color_pulse:
        LD A, (attr_phase)
        INC A
        AND 3
        LD (attr_phase), A
        LD E, A
        LD D, 0
        LD HL, qr_colors
        ADD HL, DE
        LD A, (HL)
        LD HL, SCREEN_ATTR
        LD B, 24
qr_attr_rows:
        PUSH BC
        LD C, 32
qr_attr_cols:
        LD D, (HL)
        LD E, A
        LD A, D
        CP $47
        JR NZ, qr_attr_next
        LD (HL), E
qr_attr_next:
        LD A, E
        INC HL
        DEC C
        JR NZ, qr_attr_cols
        POP BC
        DJNZ qr_attr_rows
        RET

row_addr:
        LD A, C
        JP char_addr

qr_row_addr:
        LD C, A
        CALL char_addr
        LD DE, SCREEN
        OR A
        SBC HL, DE
        LD DE, qr_screen
        ADD HL, DE
        RET

next_scr_data_line:
        PUSH DE
        LD DE, qr_screen - SCREEN
        OR A
        SBC HL, DE
        CALL next_screen_line
        LD DE, qr_screen - SCREEN
        ADD HL, DE
        POP DE
        RET

char_rows:
        DW $4000,$4020,$4040,$4060,$4080,$40A0,$40C0,$40E0
        DW $4800,$4820,$4840,$4860,$4880,$48A0,$48C0,$48E0
        DW $5000,$5020,$5040,$5060,$5080,$50A0,$50C0,$50E0

snake_path:
        DB 7,12, 8,12, 9,12, 10,12, 11,12, 12,12, 13,12, 14,12
        DB 15,12, 16,12, 17,12, 18,12, 19,12, 20,12, 21,12, 22,12
        DB 23,12, 24,12, 25,12, 24,12, 23,12, 22,12, 21,12, 20,12
        DB 19,12, 18,12, 17,12, 16,12, 15,12, 14,12, 13,12, 12,12
        DB $FF,$FF

melody_demo:
        DB $20,$01,$70,$00
        DB $D8,$00,$70,$00
        DB $98,$00,$70,$00
        DB $D8,$00,$70,$00
        DB $80,$00,$70,$00
        DB $98,$00,$70,$00
        DB $B8,$00,$70,$00
        DB $F0,$00,$D0,$00
        DB $20,$01,$70,$00
        DB $D8,$00,$70,$00
        DB $68,$00,$70,$00
        DB $80,$00,$70,$00
        DB $98,$00,$70,$00
        DB $80,$00,$70,$00
        DB $B8,$00,$70,$00
        DB $D8,$00,$D0,$00
        DB $F0,$00,$70,$00
        DB $B8,$00,$70,$00
        DB $98,$00,$70,$00
        DB $80,$00,$70,$00
        DB $68,$00,$70,$00
        DB $80,$00,$70,$00
        DB $98,$00,$70,$00
        DB $B8,$00,$D0,$00
        DB $D8,$00,$70,$00
        DB $98,$00,$70,$00
        DB $80,$00,$70,$00
        DB $68,$00,$70,$00
        DB $80,$00,$70,$00
        DB $98,$00,$70,$00
        DB $D8,$00,$70,$00
        DB $20,$01,$20,$01
        DB $00,$00,$00,$00

txt_title: DB "ZXSNAKE",0
txt_demo:  DB "MUSIC DEMO",0
txt_press: DB "PRESS ANY KEY",0
txt_play:  DB "ZX SNAKE",0
txt_load:  DB "LOAD FULL GAME TO PLAY",0

snake_x: DB 0
snake_y: DB 0
fruit_frame: DB 0
melody_pos: DB 0
beep_state: DB 0
attr_phase: DB 0
src_ptr: DW 0
dst_ptr: DW 0
tmp_byte: DB 0

attr_colors: DB $44,$46,$45,$47
qr_colors:   DB $47,$46,$45,$42
row_buffer:  DEFS 256

splash_screen:
        INCBIN "gfx/splash.scr"

qr_screen:
        INCBIN "gfx/linkedin_qr.scr"

        INCLUDE "../src/sprites.asm"
        INCLUDE "../src/font.asm"

        END start
