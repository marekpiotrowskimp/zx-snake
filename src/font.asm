;; ============================================
;; zxSnake - Font Data (8x8 characters)
;; Each character = 8 bytes
;; ============================================

;; --------------------------------------------
;; Character Set: 0-9, A-Z, punctuation
;; --------------------------------------------

font_data:

; Digits 0-9 (ASCII 48-57)
font_0: DB $3C,$66,$6E,$76,$66,$66,$3C,$00
font_1: DB $18,$38,$18,$18,$18,$18,$7E,$00
font_2: DB $3C,$66,$06,$0C,$18,$30,$7E,$00
font_3: DB $3C,$66,$06,$1C,$06,$66,$3C,$00
font_4: DB $0C,$1C,$3C,$6C,$7E,$0C,$0C,$00
font_5: DB $7E,$60,$7C,$06,$06,$66,$3C,$00
font_6: DB $1C,$30,$60,$7C,$66,$66,$3C,$00
font_7: DB $7E,$06,$0C,$18,$18,$18,$18,$00
font_8: DB $3C,$66,$66,$3C,$66,$66,$3C,$00
font_9: DB $3C,$66,$66,$3E,$06,$0C,$38,$00

; Letters A-Z (ASCII 65-90)
font_A: DB $18,$3C,$66,$66,$7E,$66,$66,$00
font_B: DB $7C,$66,$66,$7C,$66,$66,$7C,$00
font_C: DB $3C,$66,$60,$60,$60,$66,$3C,$00
font_D: DB $78,$6C,$66,$66,$66,$6C,$78,$00
font_E: DB $7E,$60,$60,$7C,$60,$60,$7E,$00
font_F: DB $7E,$60,$60,$7C,$60,$60,$60,$00
font_G: DB $3C,$66,$60,$6E,$66,$66,$3E,$00
font_H: DB $66,$66,$66,$7E,$66,$66,$66,$00
font_I: DB $3C,$18,$18,$18,$18,$18,$3C,$00
font_J: DB $06,$06,$06,$06,$06,$66,$3C,$00
font_K: DB $66,$6C,$78,$70,$78,$6C,$66,$00
font_L: DB $60,$60,$60,$60,$60,$60,$7E,$00
font_M: DB $63,$77,$7F,$6B,$63,$63,$63,$00
font_N: DB $66,$76,$7E,$7E,$6E,$66,$66,$00
font_O: DB $3C,$66,$66,$66,$66,$66,$3C,$00
font_P: DB $7C,$66,$66,$7C,$60,$60,$60,$00
font_Q: DB $3C,$66,$66,$66,$6A,$6C,$36,$00
font_R: DB $7C,$66,$66,$7C,$6C,$66,$66,$00
font_S: DB $3C,$66,$60,$3C,$06,$66,$3C,$00
font_T: DB $7E,$18,$18,$18,$18,$18,$18,$00
font_U: DB $66,$66,$66,$66,$66,$66,$3C,$00
font_V: DB $66,$66,$66,$66,$66,$3C,$18,$00
font_W: DB $63,$63,$63,$6B,$7F,$77,$63,$00
font_X: DB $66,$66,$3C,$18,$3C,$66,$66,$00
font_Y: DB $66,$66,$66,$3C,$18,$18,$18,$00
font_Z: DB $7E,$06,$0C,$18,$30,$60,$7E,$00

; Special characters
font_space: DB $00,$00,$00,$00,$00,$00,$00,$00
font_colon: DB $00,$18,$18,$00,$18,$18,$00,$00
font_dot:   DB $00,$00,$00,$00,$00,$18,$18,$00
font_excl:  DB $18,$18,$18,$18,$18,$00,$18,$00
font_quest: DB $3C,$66,$06,$0C,$18,$00,$18,$00
font_dash:  DB $00,$00,$00,$7E,$00,$00,$00,$00
font_slash: DB $06,$0C,$18,$30,$60,$C0,$80,$00
font_lpar:  DB $0C,$18,$30,$30,$30,$18,$0C,$00
font_rpar:  DB $30,$18,$0C,$0C,$0C,$18,$30,$00

;; --------------------------------------------
;; Big Font for title (16x16, 2x2 characters)
;; Each letter = 4 chars (TL, TR, BL, BR)
;; ============================================

; "ZXSNAKE" big letters - simplified 2x2 block style
; Each block character is 8x8

big_Z_tl: DB $FF,$FF,$03,$07,$0E,$1C,$38,$70
big_Z_tr: DB $FF,$FF,$C0,$80,$00,$00,$00,$00
big_Z_bl: DB $70,$38,$1C,$0E,$07,$03,$FF,$FF
big_Z_br: DB $00,$00,$00,$00,$80,$C0,$FF,$FF

big_X_tl: DB $E0,$F0,$78,$3C,$1E,$3C,$78,$F0
big_X_tr: DB $07,$0F,$1E,$3C,$78,$3C,$1E,$0F
big_X_bl: DB $F0,$78,$3C,$1E,$3C,$78,$F0,$E0
big_X_br: DB $0F,$1E,$3C,$78,$3C,$1E,$0F,$07

big_S_tl: DB $3F,$7F,$F0,$E0,$F0,$7E,$1F,$07
big_S_tr: DB $FE,$FF,$03,$00,$00,$00,$80,$E0
big_S_bl: DB $03,$01,$00,$00,$00,$60,$F0,$7F
big_S_br: DB $F8,$FC,$0E,$07,$0F,$FE,$FC,$F0

big_N_tl: DB $F0,$F8,$FC,$FC,$FE,$EE,$E6,$E6
big_N_tr: DB $0F,$0F,$0F,$1F,$1F,$3F,$7F,$7F
big_N_bl: DB $E3,$E3,$E1,$E1,$E0,$E0,$E0,$E0
big_N_br: DB $FF,$EF,$CF,$CF,$8F,$0F,$0F,$0F

big_A_tl: DB $0F,$1F,$3C,$78,$78,$7F,$7F,$78
big_A_tr: DB $F0,$F8,$3C,$1E,$1E,$FE,$FE,$1E
big_A_bl: DB $78,$78,$78,$78,$78,$78,$78,$78
big_A_br: DB $1E,$1E,$1E,$1E,$1E,$1E,$1E,$1E

big_K_tl: DB $E0,$E0,$E0,$E0,$F8,$FC,$FE,$EF
big_K_tr: DB $1E,$3C,$78,$F0,$E0,$C0,$E0,$F0
big_K_bl: DB $E7,$E3,$E1,$E0,$E0,$E1,$E3,$E7
big_K_br: DB $78,$3C,$1E,$0F,$07,$0F,$1E,$3C

big_E_tl: DB $FF,$FF,$E0,$E0,$FE,$FE,$E0,$E0
big_E_tr: DB $FF,$FF,$00,$00,$00,$00,$00,$00
big_E_bl: DB $E0,$E0,$E0,$E0,$E0,$E0,$FF,$FF
big_E_br: DB $00,$00,$00,$00,$00,$00,$FF,$FF

;; --------------------------------------------
;; Text strings (null-terminated)
;; --------------------------------------------

str_title:      DB "ZXSNAKE", 0
str_score:      DB "SCORE:", 0
str_level:      DB "LVL:", 0
str_hiscore:    DB "HI:", 0
str_gameover:   DB "GAME OVER!", 0
str_levelup:    DB "LEVEL UP!", 0
str_ready:      DB "GET READY!", 0
str_press:      DB "PRESS ANY KEY", 0
str_controls:   DB "SELECT CONTROLS:", 0
str_opt1:       DB "1. QAOP", 0
str_opt2:       DB "2. WASD", 0
str_opt3:       DB "3. KEMPSTON", 0
str_press123:   DB "PRESS 1, 2 OR 3", 0
str_menu_opts:  DB "1-QAOP  2-WASD  3-KEMP", 0
str_copyright:  DB "(C) 2026", 0
str_loading:    DB "LOADING...", 0
