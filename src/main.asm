;; ============================================
;; zxSnake v1.0 - Complete ZX Spectrum Game
;; With real graphics, menu, and animations
;; ============================================

        ORG 32768

;; ============================================
;; CONSTANTS
;; ============================================

; Screen
SCREEN          EQU $4000
SCREEN_ATTR     EQU $5800

; Colors
BLACK           EQU 0
BLUE            EQU 1
RED             EQU 2
MAGENTA         EQU 3
GREEN           EQU 4
CYAN            EQU 5
YELLOW          EQU 6
WHITE           EQU 7
BRIGHT          EQU $40
FLASH           EQU $80

; Board (16x11 tiles of 16x16 pixels = 256x176)
BOARD_W         EQU 16
BOARD_H         EQU 11
BOARD_SIZE      EQU BOARD_W * BOARD_H   ; 176

; Directions
DIR_UP          EQU 0
DIR_RIGHT       EQU 1  
DIR_DOWN        EQU 2
DIR_LEFT        EQU 3

; Cell types
CELL_EMPTY      EQU 0
CELL_WALL       EQU 1
CELL_SNAKE      EQU 2
CELL_FOOD       EQU 3

; Food types
FOOD_NONE       EQU 255
FOOD_APPLE      EQU 0
FOOD_BANANA     EQU 1
FOOD_GRAPES     EQU 2
FOOD_CHERRY     EQU 3

; States
ST_MENU         EQU 0
ST_PLAYING      EQU 1
ST_GAMEOVER     EQU 2
ST_LEVELUP      EQU 3
ST_PAUSED       EQU 4

; Control modes
CTRL_QAOP       EQU 0
CTRL_WASD       EQU 1
CTRL_KEMP       EQU 2

; Snake
MAX_SNAKE       EQU 64
INIT_LEN        EQU 3
INIT_SPEED      EQU 8

; ROM
ROM_BEEP        EQU $03B5

;; ============================================
;; ENTRY POINT
;; ============================================

start:
        DI
        LD SP, $FFFF
        IM 1
        EI
        
        ; Init variables
        XOR A
        LD (hiscore), A
        LD (hiscore+1), A
        
        LD A, ST_MENU
        LD (state), A
        
        ; Main loop
main:
        HALT                    ; 50Hz sync
        
        LD A, (state)
        CP ST_MENU
        JP Z, state_menu
        CP ST_PLAYING
        JP Z, state_play
        CP ST_GAMEOVER
        JP Z, state_over
        CP ST_LEVELUP
        JP Z, state_lvlup
        
        JP main

;; ============================================
;; STATE: MENU
;; ============================================

state_menu:
        ; Draw menu once
        LD A, (menu_drawn)
        OR A
        JR NZ, menu_input
        
        CALL cls_black
        CALL draw_menu
        
        LD A, 1
        LD (menu_drawn), A

menu_input:
        CALL play_menu_music
        
        ; Check which key was pressed
        LD A, $F7               ; Row 1-5
        IN A, ($FE)
        BIT 0, A                ; Key 1
        JR Z, sel_qaop
        BIT 1, A                ; Key 2
        JR Z, sel_wasd
        BIT 2, A                ; Key 3
        JR Z, sel_kemp
        
        ; Keep polling
        JP main

sel_qaop:
        LD A, CTRL_QAOP
        JR start_game
sel_wasd:
        LD A, CTRL_WASD
        JR start_game
sel_kemp:
        LD A, CTRL_KEMP

start_game:
        LD (ctrl_mode), A
        XOR A
        LD (menu_drawn), A
        
        ; Reset score
        LD (score), A
        LD (score+1), A
        
        ; Reset loop count for new game
        LD (loop_count), A
        
        ; Reset lives to 3
        LD A, 3
        LD (lives), A
        
        ; Level 1
        LD A, 1
        LD (level), A
        
        CALL init_level
        
        LD A, ST_PLAYING
        LD (state), A
        
        ; Clear screen and draw board
        CALL cls_black
        CALL draw_board_full
        CALL draw_hud
        
        ; GET READY sequence
        CALL show_get_ready
        CALL redraw_center
        
        JP main

;; ============================================
;; STATE: PLAYING
;; ============================================

state_play:
        ; ALWAYS read input every frame for responsive controls
        ; This ensures keypresses are detected at 50Hz, not just when snake moves
        CALL read_input
        CALL update_dir
        
        ; Frame counter for speed (controls when snake actually moves)
        LD HL, framecnt
        DEC (HL)
        JP NZ, main             ; Return but input already processed!
        
        ; Calculate speed based on level, loop_count, and snake length
        ; Base speed: 12 - level - loop_count
        LD A, (level)
        LD B, A
        LD A, 12
        SUB B                   ; A = 12 - level
        LD B, A
        LD A, (loop_count)
        LD C, A
        LD A, B
        SUB C                   ; A = 12 - level - loop_count
        
        ; Subtract length bonus (longer = faster = lower frame count)
        ; length / 4 gives 0,0,0,0,1,1,1,1,2,2,...
        LD C, A                 ; Save base
        LD A, (snk_len)
        SRL A                   ; / 2
        SRL A                   ; / 4
        LD B, A
        LD A, C
        SUB B                   ; base - length/4
        
        ; Minimum 2 frames between moves
        CP 2
        JR NC, sp_ok
        LD A, 2
sp_ok:
        LD (framecnt), A
        
        ; Animation frame toggle
        LD A, (anim_frame)
        XOR 1
        LD (anim_frame), A
        
        ; Move snake
        CALL move_snake
        
        ; Check state change
        LD A, (state)
        CP ST_PLAYING
        JP NZ, main
        
        ; Redraw changed tiles
        CALL draw_snake_gfx
        CALL draw_food_gfx
        CALL draw_hud
        
        JP main

;; ============================================
;; STATE: GAME OVER
;; ============================================

state_over:
        CALL draw_gameover
        CALL play_gameover_music
        CALL wait_key
        
        LD A, ST_MENU
        LD (state), A
        XOR A
        LD (menu_drawn), A
        
        JP main

;; ============================================
;; STATE: LEVEL UP
;; ============================================

state_lvlup:
        CALL draw_levelup
        CALL wait_key
        
        ; Next level
        LD A, (level)
        INC A
        CP 9                    ; 8 levels total
        JR C, lvl_ok
        ; Completed all 8 levels - increase difficulty loop
        LD HL, loop_count
        INC (HL)
        LD A, 1                 ; Wrap to level 1
lvl_ok:
        LD (level), A
        
        CALL init_level
        
        LD A, ST_PLAYING
        LD (state), A
        
        ; Clear screen and draw board first
        CALL cls_black
        CALL draw_board_full
        CALL draw_hud
        
        ; Show GET READY on top of the board
        CALL show_get_ready
        
        ; Redraw the area that GET READY covered
        CALL redraw_center
        
        JP main

;; ============================================
;; INIT LEVEL
;; ============================================

init_level:
        ; Save current score for level restart (lives system)
        LD HL, (score)
        LD (level_score), HL
        
        ; Clear board using LDIR (fast and correct)
        LD HL, board
        LD DE, board + 1
        LD BC, BOARD_SIZE - 1
        XOR A
        LD (HL), A              ; First byte = 0
        LDIR                    ; Copy 0 to rest of board
        
        ; Load level walls
        CALL load_level
        
        ; Get spawn position for this level
        LD A, (level)
        DEC A                   ; 0-based index
        LD C, A
        LD B, 0
        LD HL, level_spawns
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC              ; HL = level_spawns + level*3
        
        ; Read spawn data: head_x, head_y, direction
        LD A, (HL)
        LD (snk_x), A           ; Head X
        DEC A
        LD (snk_x+1), A         ; Body X = head-1
        DEC A
        LD (snk_x+2), A         ; Tail X = head-2
        
        INC HL
        LD A, (HL)
        LD (snk_y), A           ; Head Y
        LD (snk_y+1), A         ; Body Y (same)
        LD (snk_y+2), A         ; Tail Y (same)
        
        INC HL
        LD A, (HL)              ; Direction
        LD (snk_dir), A
        LD (snk_dir+1), A
        LD (snk_dir+2), A
        LD (cur_dir), A
        LD (new_dir), A
        
        LD A, $FF               ; No key pressed initially
        LD (inp_dir), A
        
        LD A, INIT_LEN
        LD (snk_len), A
        
        ; Mark snake on board
        LD B, INIT_LEN
        LD HL, snk_x
        LD DE, snk_y
mark_snk:
        PUSH BC
        PUSH HL
        PUSH DE
        LD B, (HL)
        EX DE, HL
        LD C, (HL)
        LD A, CELL_SNAKE
        CALL set_cell
        POP DE
        POP HL
        POP BC
        INC HL
        INC DE
        DJNZ mark_snk
        
        ; Initialize food slots as empty
        LD A, FOOD_NONE
        LD (food1_type), A
        LD (food2_type), A
        
        ; Spawn 2 foods
        CALL spawn_food
        CALL spawn_food
        
        ; Speed
        LD A, (level)
        LD B, A
        LD A, 11
        SUB B                   ; 10,9,8,7,6 for levels 1-5
        CP 4
        JR NC, spd_ok
        LD A, 4
spd_ok:
        LD (speed), A
        LD (framecnt), A
        
        ; Food target: level + 4 + (loop_count * 2)
        LD A, (level)
        ADD A, 4                ; base: 5,6,7...12
        LD B, A
        LD A, (loop_count)
        ADD A, A                ; loop_count * 2
        ADD A, B                ; + base
        LD (food_need), A
        XOR A
        LD (food_cnt), A
        LD (snake_grew), A      ; Reset growth flag
        
        RET

;; ============================================
;; LOAD LEVEL
;; ============================================

load_level:
        LD A, (level)
        DEC A
        
        ; Calc address: level * 176
        LD L, A
        LD H, 0
        ADD HL, HL              ; *2
        ADD HL, HL              ; *4
        ADD HL, HL              ; *8
        ADD HL, HL              ; *16
        LD D, H
        LD E, L                 ; DE = *16
        ADD HL, HL              ; *32
        ADD HL, HL              ; *64
        ADD HL, HL              ; *128
        ADD HL, DE              ; *144
        ADD HL, DE              ; *160
        ADD HL, DE              ; *176
        
        LD DE, levels
        ADD HL, DE
        
        LD DE, board
        LD BC, BOARD_SIZE
        LDIR
        RET

;; ============================================
;; SNAKE MOVEMENT
;; ============================================

move_snake:
        ; Apply new direction
        LD A, (new_dir)
        LD (cur_dir), A
        
        ; Get head position
        LD A, (snk_x)
        LD B, A
        LD A, (snk_y)
        LD C, A
        
        ; Calculate new head
        LD A, (cur_dir)
        CP DIR_UP
        JR NZ, mv_not_up
        DEC C
        JR mv_done
mv_not_up:
        CP DIR_DOWN
        JR NZ, mv_not_down
        INC C
        JR mv_done
mv_not_down:
        CP DIR_LEFT
        JR NZ, mv_not_left
        DEC B
        JR mv_done
mv_not_left:
        INC B
mv_done:
        ; Save new position
        LD A, B
        LD (new_x), A
        LD A, C
        LD (new_y), A
        
        ; Boundary check
        LD A, B
        CP BOARD_W
        JP NC, die
        LD A, C
        CP BOARD_H
        JP NC, die
        
        ; Cell check
        CALL get_cell
        CP CELL_WALL
        JP Z, die
        CP CELL_SNAKE
        JP Z, die
        CP CELL_FOOD
        JP Z, eat
        
        ; Normal move - clear tail
        CALL clear_tail
        CALL shift_body
        CALL set_head
        
        ; Add +1 score for surviving this move
        CALL add_time_score
        RET

clear_tail:
        ; Get tail position (16-bit safe addressing)
        LD A, (snk_len)
        DEC A
        LD C, A
        LD B, 0
        LD HL, snk_x
        ADD HL, BC
        LD D, (HL)              ; D = tail X
        
        LD HL, snk_y
        ADD HL, BC
        LD E, (HL)              ; E = tail Y
        
        ; Clear on board
        LD B, D
        LD C, E
        XOR A
        CALL set_cell
        
        ; Save for redraw
        LD A, D
        LD (tail_x), A
        LD A, E
        LD (tail_y), A
        RET

shift_body:
        LD A, (snk_len)
        DEC A
        LD B, A                 ; B = loop counter (len-1 down to 1)
shift_lp:
        PUSH BC
        
        ; X[i] = X[i-1] (16-bit safe)
        LD C, B
        LD B, 0
        LD HL, snk_x
        ADD HL, BC              ; HL = &snk_x[i]
        DEC HL                  ; HL = &snk_x[i-1]
        LD A, (HL)
        INC HL
        LD (HL), A
        
        ; Y[i] = Y[i-1]
        LD HL, snk_y
        ADD HL, BC
        DEC HL
        LD A, (HL)
        INC HL
        LD (HL), A
        
        ; Dir[i] = Dir[i-1]
        LD HL, snk_dir
        ADD HL, BC
        DEC HL
        LD A, (HL)
        INC HL
        LD (HL), A
        
        POP BC
        DEC B
        JR NZ, shift_lp
        RET

set_head:
        ; Set new head position
        LD A, (new_x)
        LD (snk_x), A
        LD B, A
        LD A, (new_y)
        LD (snk_y), A
        LD C, A
        
        ; Set direction
        LD A, (cur_dir)
        LD (snk_dir), A
        
        ; Mark on board
        LD A, CELL_SNAKE
        CALL set_cell
        RET

eat:
        ; Find which food slot was eaten
        ; B,C already contain the food position (new head pos)
        LD A, (new_x)
        LD B, A
        LD A, (new_y)
        LD C, A
        
        ; Check slot 1
        LD A, (food1_type)
        CP FOOD_NONE
        JR Z, eat_check2
        
        LD A, (food1_x)
        CP B
        JR NZ, eat_check2
        LD A, (food1_y)
        CP C
        JR NZ, eat_check2
        
        ; Eating from slot 1
        LD A, (food1_type)
        LD (eaten_type), A
        LD A, B
        LD (old_food_x), A
        LD A, C
        LD (old_food_y), A
        LD A, FOOD_NONE
        LD (food1_type), A      ; Clear slot 1
        JR eat_do
        
eat_check2:
        ; Must be slot 2
        LD A, (food2_type)
        LD (eaten_type), A
        LD A, B
        LD (old_food_x), A
        LD A, C
        LD (old_food_y), A
        LD A, FOOD_NONE
        LD (food2_type), A      ; Clear slot 2
        
eat_do:
        ; Set flag that snake grew (don't clear tail this frame)
        LD A, 1
        LD (snake_grew), A
        
        ; Sound
        CALL snd_eat
        
        ; Score based on fruit type:
        ; Apple = level * 10, Banana = level * 15, Grapes = level * 20
        LD A, (eaten_type)
        LD C, A                 ; C = fruit type (0,1,2)
        
        ; Base points: 10 + type * 5 = 10, 15, 20
        LD A, C
        ADD A, A                ; * 2
        ADD A, A                ; * 4
        ADD A, C                ; * 5
        ADD A, 10               ; + 10 = 10, 15, 20
        LD E, A
        LD D, 0                 ; DE = base points
        
        ; Multiply by level
        LD A, (level)
        LD B, A
        LD HL, 0
eat_score_lp:
        ADD HL, DE              ; Add base points for each level
        DJNZ eat_score_lp
        
        LD DE, (score)
        ADD HL, DE
        LD (score), HL
        
        ; Check hiscore
        LD DE, (hiscore)
        OR A
        SBC HL, DE
        JR C, no_hi
        LD HL, (score)
        LD (hiscore), HL
no_hi:
        ; Update score display
        CALL update_score_display
        ; Grow - shift first, then add head
        LD A, (snk_len)
        CP MAX_SNAKE
        JR NC, no_grow
        
        ; Shift with extra segment (16-bit safe)
        LD B, A                 ; B = snk_len (index to write to)
grow_lp:
        PUSH BC
        
        ; X[i] = X[i-1]
        LD C, B
        LD B, 0
        LD HL, snk_x
        ADD HL, BC
        DEC HL
        LD A, (HL)
        INC HL
        LD (HL), A
        
        ; Y[i] = Y[i-1]
        LD HL, snk_y
        ADD HL, BC
        DEC HL
        LD A, (HL)
        INC HL
        LD (HL), A
        
        ; Dir[i] = Dir[i-1]
        LD HL, snk_dir
        ADD HL, BC
        DEC HL
        LD A, (HL)
        INC HL
        LD (HL), A
        
        POP BC
        DEC B
        JR NZ, grow_lp
        
        LD A, (snk_len)
        INC A
        LD (snk_len), A

no_grow:
        CALL set_head
        CALL spawn_food         ; Spawn new food (to empty slot)
        
        ; Level complete?
        LD A, (food_cnt)
        INC A
        LD (food_cnt), A
        LD B, A
        LD A, (food_need)
        CP B
        RET NZ
        
        CALL snd_levelup
        LD A, ST_LEVELUP
        LD (state), A
        RET

eaten_type:     DEFS 1          ; Temp: type of fruit just eaten

die:
        CALL snd_die
        
        ; Check lives
        LD A, (lives)
        OR A
        JP Z, die_gameover      ; No lives left = GAME OVER
        
        ; Lose a life
        DEC A
        LD (lives), A
        
        ; Restore score to level start value
        LD HL, (level_score)
        LD (score), HL
        
        ; Short pause so player notices life lost (~1 sec = 50 frames)
        LD B, 50
        CALL delay_frames
        
        ; Restart current level (but don't save score again)
        ; We need to skip the score save in init_level
        ; Actually easier to just inline the level restart here
        
        ; Clear board
        LD HL, board
        LD DE, board + 1
        LD BC, BOARD_SIZE - 1
        XOR A
        LD (HL), A
        LDIR
        
        ; Load level walls
        CALL load_level
        
        ; Get spawn position for this level
        LD A, (level)
        DEC A
        LD C, A
        LD B, 0
        LD HL, level_spawns
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC
        
        LD A, (HL)
        LD (snk_x), A
        DEC A
        LD (snk_x+1), A
        DEC A
        LD (snk_x+2), A
        
        INC HL
        LD A, (HL)
        LD (snk_y), A
        LD (snk_y+1), A
        LD (snk_y+2), A
        
        INC HL
        LD A, (HL)
        LD (snk_dir), A
        LD (snk_dir+1), A
        LD (snk_dir+2), A
        LD (cur_dir), A
        LD (new_dir), A
        
        LD A, $FF
        LD (inp_dir), A
        
        LD A, INIT_LEN
        LD (snk_len), A
        
        ; Mark snake on board
        LD B, INIT_LEN
        LD HL, snk_x
        LD DE, snk_y
die_mark_snk:
        PUSH BC
        PUSH HL
        PUSH DE
        LD B, (HL)
        EX DE, HL
        LD C, (HL)
        LD A, CELL_SNAKE
        CALL set_cell
        POP DE
        POP HL
        POP BC
        INC HL
        INC DE
        DJNZ die_mark_snk
        
        ; Initialize food slots as empty
        LD A, FOOD_NONE
        LD (food1_type), A
        LD (food2_type), A
        
        ; Spawn 2 foods
        CALL spawn_food
        CALL spawn_food
        
        ; Speed
        LD A, (level)
        LD B, A
        LD A, 11
        SUB B
        CP 4
        JR NC, die_spd_ok
        LD A, 4
die_spd_ok:
        LD (speed), A
        LD (framecnt), A
        
        ; Reset food counter (keep same food_need)
        XOR A
        LD (food_cnt), A
        LD (snake_grew), A
        
        ; Redraw everything
        CALL cls_black
        CALL draw_board_full
        CALL draw_hud
        
        ; Show GET READY
        CALL show_get_ready
        CALL redraw_center
        
        ; Continue playing
        LD A, ST_PLAYING
        LD (state), A
        RET
        
die_gameover:
        LD A, ST_GAMEOVER
        LD (state), A
        RET

;; ============================================
;; SCORING
;; ============================================

; Add +1 score for time survived (called each move)
add_time_score:
        LD HL, (score)
        INC HL
        LD (score), HL
        
        ; Check hiscore
        LD DE, (hiscore)
        OR A
        SBC HL, DE
        JR C, ats_no_hi
        LD HL, (score)
        LD (hiscore), HL
ats_no_hi:
        ; Update display
        CALL update_score_display
        RET

;; ============================================
;; FOOD
;; ============================================

; Spawn food to an empty slot (tries both slots)
; Called at level start and after eating
; Rule: Apple and Cherry cannot appear together (both are red)
spawn_food:
        ; Check if slot 1 is empty
        LD A, (food1_type)
        CP FOOD_NONE
        JR Z, spawn_to_slot1
        
        ; Check if slot 2 is empty
        LD A, (food2_type)
        CP FOOD_NONE
        JR Z, spawn_to_slot2
        
        ; Both slots full - don't spawn
        RET

spawn_to_slot1:
        LD HL, food1_x
        ; Get other slot's type for conflict check
        LD A, (food2_type)
        LD (sf_other_type), A
        JR spawn_do
        
spawn_to_slot2:
        LD HL, food2_x
        ; Get other slot's type for conflict check
        LD A, (food1_type)
        LD (sf_other_type), A

spawn_do:
        ; HL points to food slot (x, y, type)
        PUSH HL
        
        ; Find empty cell
sf_find:
        LD A, R
        AND $0F
        LD B, A                 ; X
        LD A, R
        AND $0F
        CP BOARD_H
        JR NC, sf_find
        LD C, A                 ; Y
        
        CALL get_cell
        OR A
        JR NZ, sf_find          ; Cell not empty, try again
        
        ; Found empty cell at (B, C)
        POP HL
        
        ; Store position
        LD (HL), B              ; food_x
        INC HL
        LD (HL), C              ; food_y
        INC HL
        
        ; Choose random fruit type (0-3: apple, banana, grapes, cherry)
        ; But avoid apple+cherry conflict
sf_pick_type:
        LD A, R
        AND $03                 ; 0-3
        
        ; Check for apple/cherry conflict
        ; If we picked APPLE (0) and other is CHERRY (3) -> reroll
        ; If we picked CHERRY (3) and other is APPLE (0) -> reroll
        CP FOOD_APPLE
        JR NZ, sf_not_apple
        ; We picked apple - check if other is cherry
        PUSH AF
        LD A, (sf_other_type)
        CP FOOD_CHERRY
        JR NZ, sf_type_ok_pop
        ; Conflict! Reroll to banana or grapes (1 or 2)
        POP AF
        LD A, R
        AND $01                 ; 0 or 1
        INC A                   ; 1 or 2 (banana or grapes)
        JR sf_type_store
        
sf_not_apple:
        CP FOOD_CHERRY
        JR NZ, sf_type_store
        ; We picked cherry - check if other is apple
        PUSH AF
        LD A, (sf_other_type)
        CP FOOD_APPLE
        JR NZ, sf_type_ok_pop
        ; Conflict! Reroll to banana or grapes (1 or 2)
        POP AF
        LD A, R
        AND $01                 ; 0 or 1
        INC A                   ; 1 or 2 (banana or grapes)
        JR sf_type_store

sf_type_ok_pop:
        POP AF
sf_type_store:
        LD (HL), A              ; food_type
        
        ; Mark cell as food on board
        LD A, CELL_FOOD
        CALL set_cell
        RET

; Check if position (B,C) matches any food slot
; Returns: Z flag set if match, A = slot (1 or 2)
check_food_collision:
        ; Check slot 1
        LD A, (food1_type)
        CP FOOD_NONE
        JR Z, cfc_check2
        
        LD A, (food1_x)
        CP B
        JR NZ, cfc_check2
        LD A, (food1_y)
        CP C
        JR NZ, cfc_check2
        
        ; Match slot 1
        LD A, 1
        CP A                    ; Set Z flag
        RET
        
cfc_check2:
        ; Check slot 2
        LD A, (food2_type)
        CP FOOD_NONE
        JR Z, cfc_no_match
        
        LD A, (food2_x)
        CP B
        JR NZ, cfc_no_match
        LD A, (food2_y)
        CP C
        JR NZ, cfc_no_match
        
        ; Match slot 2
        LD A, 2
        CP A                    ; Set Z flag
        RET
        
cfc_no_match:
        XOR A
        INC A                   ; Clear Z flag (A=1, Z=0)
        RET

;; ============================================
;; INPUT
;; ============================================

read_input:
        ; Reset inp_dir to "no key pressed" state
        LD A, $FF
        LD (inp_dir), A
        
        LD A, (ctrl_mode)
        CP CTRL_KEMP
        JR Z, inp_kemp
        CP CTRL_WASD
        JR Z, inp_wasd
        ; else QAOP

inp_qaop:
        LD A, $FB               ; Q-T
        IN A, ($FE)
        BIT 0, A
        JR Z, key_up
        
        LD A, $FD               ; A-G
        IN A, ($FE)
        BIT 0, A
        JR Z, key_down
        
        LD A, $DF               ; Y-P
        IN A, ($FE)
        BIT 1, A
        JR Z, key_left
        BIT 0, A
        JR Z, key_right
        RET

inp_wasd:
        LD A, $FB               ; Q-T (W)
        IN A, ($FE)
        BIT 1, A
        JR Z, key_up
        
        LD A, $FD               ; A-G (S,A,D)
        IN A, ($FE)
        BIT 1, A
        JR Z, key_down
        BIT 0, A
        JR Z, key_left
        BIT 2, A
        JR Z, key_right
        RET

inp_kemp:
        IN A, ($1F)
        BIT 3, A
        JR NZ, key_up
        BIT 2, A
        JR NZ, key_down
        BIT 1, A
        JR NZ, key_left
        BIT 0, A
        JR NZ, key_right
        RET

key_up:
        LD A, DIR_UP
        JR save_dir
key_down:
        LD A, DIR_DOWN
        JR save_dir
key_left:
        LD A, DIR_LEFT
        JR save_dir
key_right:
        LD A, DIR_RIGHT
save_dir:
        LD (inp_dir), A
        RET

update_dir:
        LD A, (inp_dir)
        CP $FF                  ; No key pressed?
        RET Z                   ; Yes - keep current direction
        LD B, A
        LD A, (cur_dir)
        XOR 2                   ; Opposite direction
        CP B
        RET Z                   ; Can't reverse into yourself
        LD A, B
        LD (new_dir), A
        RET

;; ============================================
;; BOARD ACCESS
;; ============================================

; Get cell (B,C) -> A (16-bit safe)
get_cell:
        PUSH HL
        PUSH BC
        LD A, C
        RLCA
        RLCA
        RLCA
        RLCA                    ; A = Y * 16
        ADD A, B                ; A = Y * 16 + X (max 175)
        LD C, A
        LD B, 0
        LD HL, board
        ADD HL, BC
        LD A, (HL)
        POP BC
        POP HL
        RET

; Set cell (B,C) = A (16-bit safe)
set_cell:
        PUSH HL
        PUSH BC
        PUSH AF
        LD A, C
        RLCA
        RLCA
        RLCA
        RLCA                    ; A = Y * 16
        ADD A, B                ; A = Y * 16 + X
        LD C, A
        LD B, 0
        LD HL, board
        ADD HL, BC
        POP AF
        LD (HL), A
        POP BC
        POP HL
        RET

;; ============================================
;; GRAPHICS - Screen utilities
;; ============================================

cls_black:
        ; Clear bitmap
        LD HL, SCREEN
        LD DE, SCREEN + 1
        LD BC, 6143
        XOR A
        LD (HL), A
        LDIR
        
        ; Black attributes
        LD HL, SCREEN_ATTR
        LD DE, SCREEN_ATTR + 1
        LD BC, 767
        XOR A
        LD (HL), A
        LDIR
        
        ; Black border
        OUT ($FE), A
        RET

; Get screen address for pixel (D*8, E*8)
; D = char X (0-31), E = char Y (0-23)
; Returns HL = screen address
get_scr_addr:
        LD A, E
        RLCA
        RLCA
        RLCA                    ; E*8 = pixel Y
        LD C, A
        
        LD A, C
        AND $C0
        RRCA
        RRCA
        RRCA
        LD H, A
        
        LD A, C
        AND $07
        OR H
        OR $40
        LD H, A
        
        LD A, C
        AND $38
        RLCA
        RLCA
        OR D
        LD L, A
        RET

; Get attr address for char (D, E)
get_attr_addr:
        LD H, 0
        LD L, E
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL              ; E*32
        LD A, D
        ADD A, L
        LD L, A
        LD BC, SCREEN_ATTR
        ADD HL, BC
        RET

; Next screen row (HL)
next_row:
        INC H
        LD A, H
        AND $07
        RET NZ
        LD A, L
        ADD A, 32
        LD L, A
        RET C
        LD A, H
        SUB 8
        LD H, A
        RET

;; ============================================
;; GRAPHICS - Draw sprite 16x16
;; ============================================

; Draw sprite at tile position (B,C)
; IX = sprite address, A = attribute
draw_sprite:
        PUSH AF                 ; Save attribute
        
        ; Convert tile to char position
        LD A, B
        ADD A, A                ; *2
        LD D, A
        LD A, C
        ADD A, A                ; *2
        LD E, A
        
        ; Get screen address
        CALL get_scr_addr
        
        ; Draw 16 rows (2 bytes per row)
        LD B, 16
ds_row:
        PUSH BC
        
        ; Get sprite bytes
        LD A, (IX+0)
        LD (HL), A
        INC L
        LD A, (IX+1)
        LD (HL), A
        DEC L
        
        INC IX
        INC IX
        
        CALL next_row
        
        POP BC
        DJNZ ds_row
        
        ; Set attributes (2x2)
        POP AF                  ; Attribute
        PUSH AF
        
        LD A, B                 ; Restore tile X
        ; Actually need to recalculate D,E
        ; Let me fix this
        
        POP AF
        RET

; Better version - draw sprite with attr
; B = tile X, C = tile Y, HL = sprite addr, A = attr
draw_tile_spr:
        PUSH AF                 ; Save attr
        PUSH BC                 ; Save tile pos
        
        ; Char position
        LD A, B
        ADD A, A
        LD D, A                 ; D = char X
        LD A, C
        ADD A, A
        LD E, A                 ; E = char Y
        
        PUSH DE                 ; Save char pos
        
        ; Screen address
        CALL get_scr_addr       ; HL = screen addr
        
        EX DE, HL               ; DE = screen addr
        POP BC                  ; BC = char pos (saved DE)
        POP HL                  ; HL = sprite (was BC tile)
        ; Wait, this is messed up
        
        ; Let me rewrite cleaner
        POP AF
        RET

;; Draw 16x16 tile using lookup table
;; B = tile X (0-15), C = tile Y (0-10), HL = sprite data, A = color attr
;; Uses scr_line_addr lookup table for reliable screen addressing
draw_tile:
        PUSH AF                 ; Save color attr
        PUSH BC                 ; Save original tile pos for attrs
        PUSH HL                 ; Save sprite pointer
        
        ; Calculate pixel Y = tile_y * 16
        LD A, C
        RLCA
        RLCA
        RLCA
        RLCA                    ; A = tile_y * 16
        LD C, A                 ; C = pixel_y (starting row)
        
        ; Calculate byte X = tile_x * 2 (16 pixels = 2 bytes)
        LD A, B
        ADD A, A                ; A = tile_x * 2
        LD B, A                 ; B = byte offset X
        
        POP HL                  ; HL = sprite data
        
        ; Draw 16 rows
        LD A, 16                ; Row counter
dt_row:
        PUSH AF                 ; Save row counter
        PUSH BC                 ; Save pixel_y and byte_x
        
        ; Get screen address for line C from lookup table
        PUSH HL                 ; Save sprite pointer
        LD H, 0
        LD L, C                 ; L = pixel_y
        ADD HL, HL              ; HL = pixel_y * 2 (word offset)
        LD DE, scr_line_addr
        ADD HL, DE              ; HL = &scr_line_addr[pixel_y]
        LD E, (HL)
        INC HL
        LD D, (HL)              ; DE = screen addr for line start
        POP HL                  ; HL = sprite pointer
        
        ; Add X offset
        LD A, E
        ADD A, B                ; Add byte offset X
        LD E, A                 ; DE = final screen address
        
        ; Copy 2 bytes (16 pixels width)
        LD A, (HL)              ; First byte of sprite row
        LD (DE), A
        INC E
        INC HL
        LD A, (HL)              ; Second byte of sprite row
        LD (DE), A
        INC HL                  ; Point to next sprite row
        
        POP BC                  ; Restore pixel_y and byte_x
        INC C                   ; Next pixel row
        
        POP AF                  ; Restore row counter
        DEC A
        JR NZ, dt_row
        
        ; Set attributes
        ; Attr address = $5800 + (tile_y * 2) * 32 + (tile_x * 2)
        POP BC                  ; BC = original tile X, Y
        POP AF                  ; A = color attr
        PUSH AF
        PUSH BC
        
        ; Calculate: $5800 + tile_y * 64 + tile_x * 2
        LD H, 0
        LD L, C                 ; L = tile_y
        ADD HL, HL              ; *2
        ADD HL, HL              ; *4
        ADD HL, HL              ; *8
        ADD HL, HL              ; *16
        ADD HL, HL              ; *32
        ADD HL, HL              ; *64
        LD A, B
        ADD A, A                ; tile_x * 2
        ADD A, L
        LD L, A
        JR NC, dt_no_carry
        INC H
dt_no_carry:
        LD DE, SCREEN_ATTR
        ADD HL, DE
        
        POP BC                  ; Restore BC
        POP AF                  ; A = color
        
        ; Set 2x2 attribute block
        LD (HL), A
        INC HL
        LD (HL), A
        LD DE, 31
        ADD HL, DE
        LD (HL), A
        INC HL
        LD (HL), A
        
        RET

;; ============================================
;; GRAPHICS - Draw 8x8 character
;; ============================================

; Draw char at (D,E) from font, char code in A
; D = char X, E = char Y
draw_char:
        PUSH DE
        
        ; Get font address
        SUB 32                  ; ASCII offset
        LD L, A
        LD H, 0
        ADD HL, HL
        ADD HL, HL
        ADD HL, HL              ; *8
        LD BC, font_data - (32*8) ; Adjust for ASCII
        ADD HL, BC
        ; Actually simpler to have separate lookup
        
        POP DE
        RET

; Print string at (D,E), HL = string address
; Attr in A
print_str:
        PUSH AF                 ; Save attr
ps_loop:
        LD A, (HL)
        OR A
        JR Z, ps_done
        
        PUSH HL
        PUSH DE
        
        ; Draw character
        CALL draw_chr
        
        POP DE
        POP HL
        
        INC HL
        INC D                   ; Next char position
        JR ps_loop
ps_done:
        POP AF
        RET

; Draw single character A at (D,E)
draw_chr:
        ; First check for special characters
        CP ' '
        JR Z, dc_space
        CP ':'
        JR Z, dc_colon
        CP '.'
        JR Z, dc_dot
        CP '!'
        JR Z, dc_exclaim
        CP '-'
        JR Z, dc_dash
        
        ; Check for digit (0-9)
        CP '0'
        JR C, dc_use_space      ; < '0', use space
        CP '9'+1
        JR C, dc_digit          ; '0' <= A <= '9'
        
        ; Check for letter (A-Z)
        CP 'A'
        JR C, dc_use_space      ; < 'A', use space
        CP 'Z'+1
        JR C, dc_letter         ; 'A' <= A <= 'Z'
        
        ; Unknown character - use space
dc_use_space:
        LD HL, font_space
        JR dc_draw

dc_space:
        LD HL, font_space
        JR dc_draw
dc_colon:
        LD HL, font_colon
        JR dc_draw
dc_dot:
        LD HL, font_dot
        JR dc_draw
dc_exclaim:
        LD HL, font_excl
        JR dc_draw
dc_dash:
        LD HL, font_dash
        JR dc_draw

dc_digit:
        SUB '0'
        LD C, A
        LD B, 0
        LD HL, font_0
        JR dc_calc_offset

dc_letter:
        SUB 'A'
        LD C, A
        LD B, 0
        LD HL, font_A

dc_calc_offset:
        ; BC = char offset, need BC * 8
        SLA C
        RL B
        SLA C
        RL B
        SLA C
        RL B                    ; BC = offset * 8
        ADD HL, BC

dc_draw:
        ; HL = font data
        ; D = char X, E = char Y
        
        ; Get screen address
        PUSH HL
        CALL get_scr_addr       ; HL = screen
        EX DE, HL               ; DE = screen, HL = garbage
        POP HL                  ; HL = font
        
        ; Draw 8 rows
        LD B, 8
dc_row:
        LD A, (HL)
        LD (DE), A
        INC HL
        
        ; Next row
        INC D
        LD A, D
        AND $07
        JR NZ, dc_next
        LD A, E
        ADD A, 32
        LD E, A
        JR NC, dc_next
        LD A, D
        SUB 8
        LD D, A
dc_next:
        DJNZ dc_row
        RET

;; ============================================
;; GRAPHICS - Print number
;; ============================================

; Print 16-bit number HL at position (D,E), 5 digits
; Modifies: AF, BC, DE, HL
print_num:
        ; Store starting position
        LD A, D
        LD (pn_pos_x), A
        LD A, E
        LD (pn_pos_y), A
        
        ; Digit 1: 10000s
        LD BC, -10000
        CALL pn_digit
        
        ; Digit 2: 1000s
        LD BC, -1000
        CALL pn_digit
        
        ; Digit 3: 100s
        LD BC, -100
        CALL pn_digit
        
        ; Digit 4: 10s
        LD BC, -10
        CALL pn_digit
        
        ; Digit 5: 1s
        LD A, L
        ADD A, '0'
        PUSH AF
        LD A, (pn_pos_x)
        LD D, A
        LD A, (pn_pos_y)
        LD E, A
        POP AF
        CALL draw_chr
        RET

pn_digit:
        LD A, '0'-1
pn_d1:
        INC A
        ADD HL, BC
        JR C, pn_d1
        SBC HL, BC              ; Went one too far, restore
        
        ; A = digit char, print it
        PUSH HL
        PUSH AF
        LD A, (pn_pos_x)
        LD D, A
        LD A, (pn_pos_y)
        LD E, A
        POP AF
        CALL draw_chr
        
        ; Advance X position
        LD HL, pn_pos_x
        INC (HL)
        POP HL
        RET

; Simpler: print 2-digit number in A at (D,E)
print_2dig:
        PUSH DE
        PUSH AF
        
        ; Tens digit
        LD B, 0
p2_tens:
        CP 10
        JR C, p2_ones
        SUB 10
        INC B
        JR p2_tens
p2_ones:
        ; B = tens, A = ones
        PUSH AF
        LD A, B
        ADD A, '0'
        CALL draw_chr
        
        POP AF
        POP BC                  ; Original AF
        POP DE
        PUSH DE
        INC D
        ADD A, '0'
        CALL draw_chr
        
        POP DE
        RET

;; ============================================
;; DRAW GAME ELEMENTS  
;; ============================================

draw_board_full:
        LD C, 0
dbf_row:
        LD B, 0
dbf_col:
        PUSH BC
        CALL get_cell
        CALL draw_cell
        POP BC
        INC B
        LD A, B
        CP BOARD_W
        JR C, dbf_col
        INC C
        LD A, C
        CP BOARD_H
        JR C, dbf_row
        RET

; Draw cell at (B,C) with content A
draw_cell:
        CP CELL_EMPTY
        JR Z, dc_empty
        CP CELL_WALL
        JR Z, dc_wall
        CP CELL_SNAKE
        JR Z, dc_snake
        CP CELL_FOOD
        JR Z, dc_food
        JR dc_empty

dc_empty:
        LD HL, spr_empty
        LD A, BLACK
        JP draw_tile

dc_wall:
        LD HL, spr_wall
        LD A, BLUE + BRIGHT
        JP draw_tile

dc_snake:
        LD HL, spr_body_h       ; Default body
        LD A, GREEN + BRIGHT
        JP draw_tile

dc_food:
        ; Find which food slot matches position (B,C)
        ; Check slot 1
        LD A, (food1_type)
        CP FOOD_NONE
        JR Z, dc_food_check2
        
        LD A, (food1_x)
        CP B
        JR NZ, dc_food_check2
        LD A, (food1_y)
        CP C
        JR NZ, dc_food_check2
        
        ; Match slot 1
        LD A, (food1_type)
        JR dc_food_draw
        
dc_food_check2:
        ; Check slot 2
        LD A, (food2_type)
        CP FOOD_NONE
        JR Z, dc_food_default
        
        LD A, (food2_x)
        CP B
        JR NZ, dc_food_default
        LD A, (food2_y)
        CP C
        JR NZ, dc_food_default
        
        ; Match slot 2
        LD A, (food2_type)
        JR dc_food_draw
        
dc_food_default:
        ; No match found - default to apple
        LD A, FOOD_APPLE
        
dc_food_draw:
        ; A = fruit type (0=apple, 1=banana, 2=grapes)
        ; B,C = position
        PUSH BC
        
        ; Get sprite from fruit_sprites table (frame 1 only for full board draw)
        LD C, A
        PUSH BC                 ; Save type in C
        LD B, 0
        LD HL, fruit_sprites
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC              ; HL = fruit_sprites + type * 4
        LD E, (HL)
        INC HL
        LD D, (HL)              ; DE = sprite address (frame 1)
        EX DE, HL               ; HL = sprite
        POP BC                  ; C = type
        
        ; Get color based on type
        LD A, C
        CP FOOD_APPLE
        JR Z, dc_food_red
        CP FOOD_BANANA
        JR Z, dc_food_yellow
        CP FOOD_CHERRY
        JR Z, dc_food_red       ; Cherry is also red
        ; Grapes - magenta
        LD A, MAGENTA + BRIGHT
        JR dc_food_do
dc_food_red:
        LD A, RED + BRIGHT
        JR dc_food_do
dc_food_yellow:
        LD A, YELLOW + BRIGHT
dc_food_do:
        POP BC                  ; Restore position
        JP draw_tile

draw_snake_gfx:
        ; Check if snake grew (ate food)
        LD A, (snake_grew)
        OR A
        JR Z, dsg_clear_tail    ; No growth, clear old tail
        
        ; Snake grew - clear old food position instead of tail
        XOR A
        LD (snake_grew), A      ; Reset flag
        
        LD A, (old_food_x)
        LD B, A
        LD A, (old_food_y)
        LD C, A
        LD HL, spr_empty
        LD A, BLACK
        CALL draw_tile
        JR dsg_draw_head
        
dsg_clear_tail:
        ; Clear old tail position
        LD A, (tail_x)
        LD B, A
        LD A, (tail_y)
        LD C, A
        LD HL, spr_empty
        LD A, BLACK
        CALL draw_tile
        
dsg_draw_head:
        ; Draw HEAD (segment 0)
        LD A, (snk_x)
        LD B, A
        LD A, (snk_y)
        LD C, A
        
        ; Get head sprite by direction
        LD A, (cur_dir)
        ADD A, A                ; *2 for word table
        LD E, A
        LD D, 0
        LD HL, spr_head_table
        ADD HL, DE
        LD A, (HL)
        INC HL
        LD H, (HL)
        LD L, A                 ; HL = sprite address
        
        LD A, GREEN + BRIGHT
        CALL draw_tile
        
        ; Check if snake has body segments to draw
        LD A, (snk_len)
        CP 2
        JP C, dsg_done          ; Length < 2, no body/tail
        
        ; Draw BODY segments (1 to len-2)
        ; Each segment needs the right sprite based on direction change
        LD A, (snk_len)
        DEC A                   ; Last index (tail)
        LD (dsg_tail_idx), A
        
        LD A, 1                 ; Start from segment 1
        LD (dsg_idx), A
        
dsg_body_loop:
        LD A, (dsg_idx)
        LD B, A
        LD A, (dsg_tail_idx)
        CP B
        JR Z, dsg_draw_tail     ; Reached tail, draw it
        
        ; Get segment position
        LD A, (dsg_idx)
        LD E, A
        LD D, 0
        LD HL, snk_x
        ADD HL, DE
        LD B, (HL)              ; B = x
        LD HL, snk_y
        ADD HL, DE
        LD C, (HL)              ; C = y
        PUSH BC                 ; Save position
        
        ; Get direction INTO this segment (from previous segment)
        ; dir[idx-1] = direction the segment before was moving
        LD A, (dsg_idx)
        DEC A
        LD E, A
        LD D, 0
        LD HL, snk_dir
        ADD HL, DE
        LD A, (HL)
        LD (dsg_dir_in), A      ; Direction entering this segment
        
        ; Get direction OUT of this segment (this segment's stored dir)
        LD A, (dsg_idx)
        LD E, A
        LD D, 0
        LD HL, snk_dir
        ADD HL, DE
        LD A, (HL)
        LD (dsg_dir_out), A     ; Direction leaving this segment
        
        ; Determine sprite: corner or straight?
        LD A, (dsg_dir_in)
        LD B, A
        LD A, (dsg_dir_out)
        CP B
        JR NZ, dsg_corner       ; Different = corner
        
        ; Straight segment - horizontal or vertical?
        CP DIR_LEFT
        JR Z, dsg_horiz
        CP DIR_RIGHT
        JR Z, dsg_horiz
        ; Vertical
        LD HL, spr_body_v
        JR dsg_draw_body
dsg_horiz:
        LD HL, spr_body_h
        JR dsg_draw_body
        
dsg_corner:
        ; Look up corner sprite
        ; Index = dir_in * 4 + dir_out
        LD A, (dsg_dir_in)
        RLCA
        RLCA                    ; *4
        LD B, A
        LD A, (dsg_dir_out)
        ADD A, B                ; A = dir_in*4 + dir_out
        ADD A, A                ; *2 for word table
        LD E, A
        LD D, 0
        LD HL, spr_corner_table
        ADD HL, DE
        LD A, (HL)
        INC HL
        LD H, (HL)
        LD L, A
        
dsg_draw_body:
        POP BC                  ; Restore position
        LD A, GREEN + BRIGHT
        CALL draw_tile
        
        ; Next segment
        LD A, (dsg_idx)
        INC A
        LD (dsg_idx), A
        JR dsg_body_loop
        
dsg_draw_tail:
        ; Draw TAIL
        LD A, (dsg_tail_idx)
        LD E, A
        LD D, 0
        LD HL, snk_x
        ADD HL, DE
        LD B, (HL)
        LD HL, snk_y
        ADD HL, DE
        LD C, (HL)
        
        ; Get tail direction
        ; Tail sprite is selected based on direction the segment before it was moving
        ; tail_up = base at top (connects to body above), tip at bottom
        ; tail_down = tip at top, base at bottom (connects to body below)
        ; So if body moves UP, we use tail_up (base connects upward to body)
        LD A, (dsg_tail_idx)
        DEC A
        LD E, A
        LD D, 0
        LD HL, snk_dir
        ADD HL, DE
        LD A, (HL)
        
        ; Use direction directly - no reversal needed
        ; Direction matches sprite naming convention
        
        ; Get tail sprite
        ADD A, A                ; *2 for word table
        LD E, A
        LD D, 0
        LD HL, spr_tail_table
        ADD HL, DE
        LD A, (HL)
        INC HL
        LD H, (HL)
        LD L, A
        
        LD A, GREEN + BRIGHT
        CALL draw_tile
        
dsg_done:
        RET

; Temporary variables for draw_snake_gfx
dsg_idx:        DEFB 0
dsg_tail_idx:   DEFB 0
dsg_dir_in:     DEFB 0
dsg_dir_out:    DEFB 0

draw_food_gfx:
        ; Draw food slot 1 if active
        LD A, (food1_type)
        CP FOOD_NONE
        JR Z, dfg_slot2
        
        LD A, (food1_x)
        LD B, A
        LD A, (food1_y)
        LD C, A
        LD A, (food1_type)
        CALL draw_single_food
        
dfg_slot2:
        ; Draw food slot 2 if active
        LD A, (food2_type)
        CP FOOD_NONE
        RET Z
        
        LD A, (food2_x)
        LD B, A
        LD A, (food2_y)
        LD C, A
        LD A, (food2_type)
        CALL draw_single_food
        RET

; Draw single food at (B,C), type in A
; Selects sprite and color based on type and anim_frame
draw_single_food:
        ; Save type
        LD (dsf_type), A
        PUSH BC                 ; Save position
        
        ; Get sprite table address: fruit_sprites + type * 4
        LD C, A
        LD B, 0
        LD HL, fruit_sprites
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC
        ADD HL, BC              ; HL = fruit_sprites + type * 4
        
        ; Animate - choose frame 1 or 2
        LD A, (anim_frame)
        OR A
        JR Z, dsf_frame1
        ; Frame 2 - skip first sprite address
        INC HL
        INC HL
dsf_frame1:
        ; Get sprite address from table
        LD E, (HL)
        INC HL
        LD D, (HL)              ; DE = sprite address
        EX DE, HL               ; HL = sprite address
        
        ; Get color based on type
        LD A, (dsf_type)
        CP FOOD_APPLE
        JR Z, dsf_red
        CP FOOD_BANANA
        JR Z, dsf_yellow
        CP FOOD_CHERRY
        JR Z, dsf_red           ; Cherry is also red
        ; Grapes - magenta
        LD A, MAGENTA + BRIGHT
        JR dsf_draw
dsf_red:
        LD A, RED + BRIGHT
        JR dsf_draw
dsf_yellow:
        LD A, YELLOW + BRIGHT
dsf_draw:
        POP BC                  ; Restore position
        CALL draw_tile
        RET

dsf_type:       DEFB 0          ; Temp storage for type

; Sprite table for fruits: (sprite_frame1, sprite_frame2) per type
fruit_sprites:
        ; FOOD_APPLE (0)
        DW spr_apple, spr_apple2
        ; FOOD_BANANA (1)
        DW spr_banana, spr_banana2
        ; FOOD_GRAPES (2)
        DW spr_grapes, spr_grapes2
        ; FOOD_CHERRY (3)
        DW spr_cherry, spr_cherry2

;; ============================================
;; DRAW MENU
;; ============================================

draw_menu:
        ; Copy menu screen image to VRAM
        LD HL, menu_screen
        LD DE, SCREEN
        LD BC, 6912
        LDIR
        
        ; Draw control selection text at very bottom (row 23)
        ; Only one line: "1-QAOP  2-WASD  3-KEMP"
        LD D, 4
        LD E, 23
        LD HL, str_menu_opts
        CALL print_str_at
        
        ; Set attrs for row 23 - yellow text on black background
        ; PAPER=BLACK (0), INK=YELLOW (6), BRIGHT
        LD HL, SCREEN_ATTR + 23*32
        LD A, (BLACK * 8) + YELLOW + BRIGHT   ; paper=0, ink=6, bright
        LD B, 32
dm_attr:
        LD (HL), A
        INC HL
        DJNZ dm_attr
        
        ; Black border (matches the image)
        LD A, BLACK
        OUT ($FE), A
        
        RET

set_attr_row:
        LD (HL), A
        INC HL
        DJNZ set_attr_row
        RET

; Print string at (D,E), HL=string
print_str_at:
psa_lp:
        LD A, (HL)
        OR A
        RET Z
        PUSH HL
        PUSH DE
        CALL draw_chr
        POP DE
        POP HL
        INC HL
        INC D
        JR psa_lp

;; ============================================
;; DRAW HUD
;; ============================================

draw_hud:
        ; "SCORE:" at (0, 22)
        LD D, 0
        LD E, 22
        LD HL, str_score
        CALL print_str_at
        
        ; Score value at (6, 22) - 5 digits
        LD D, 6
        LD E, 22
        LD HL, (score)
        CALL print_num
        
        ; "LVL:" at (12, 22)
        LD D, 12
        LD E, 22
        LD HL, str_level
        CALL print_str_at
        
        ; Level number at (16, 22)
        LD D, 16
        LD E, 22
        LD A, (level)
        ADD A, '0'
        CALL draw_chr
        
        ; "HI:" at (19, 22)
        LD D, 19
        LD E, 22
        LD HL, str_hiscore
        CALL print_str_at
        
        ; HI score value at (22, 22) - 5 digits
        LD D, 22
        LD E, 22
        LD HL, (hiscore)
        CALL print_num
        
        ; "L:" at (28, 22) for lives
        LD D, 28
        LD E, 22
        LD A, 'L'
        CALL draw_chr
        LD D, 29
        LD A, ':'
        CALL draw_chr
        
        ; Lives value at (30, 22)
        LD D, 30
        LD E, 22
        LD A, (lives)
        ADD A, '0'
        CALL draw_chr
        
        ; Set HUD colors
        LD HL, SCREEN_ATTR + 22*32
        LD A, YELLOW
        LD B, 32
hud_attr:
        LD (HL), A
        INC HL
        DJNZ hud_attr
        
        RET

;; Update just the score numbers (faster than full HUD redraw)
update_score_display:
        ; Score value at (6, 22)
        LD D, 6
        LD E, 22
        LD HL, (score)
        CALL print_num
        
        ; HI score value at (22, 22)
        LD D, 22
        LD E, 22
        LD HL, (hiscore)
        CALL print_num
        RET

;; ============================================
;; DRAW GAME OVER / LEVEL UP
;; ============================================

; Clear rectangular area - both bitmap and attrs
; Fixed area for message box: chars (8,9) to (23,15) = 16x7 chars
clear_box:
        ; First clear bitmap
        ; Char rows 9-15 = pixel rows 72-127 (56 pixel rows)
        ; Char cols 8-23 = pixel cols 64-191 (16 bytes per row)
        
        LD A, 72                ; Start at pixel row 72 (char row 9 * 8)
        LD C, 56                ; 56 pixel rows (7 char rows * 8)
cb_pixel_row:
        PUSH AF
        PUSH BC
        
        ; Get screen address for this pixel row
        LD L, A
        LD H, 0
        ADD HL, HL              ; *2 for word table
        LD DE, scr_line_addr
        ADD HL, DE
        LD E, (HL)
        INC HL
        LD D, (HL)              ; DE = screen address for start of row
        
        ; Move to column 8 (byte 8)
        LD HL, 8
        ADD HL, DE              ; HL = address of column 8
        
        ; Clear 16 bytes (columns 8-23)
        LD B, 16
        XOR A
cb_clear_byte:
        LD (HL), A
        INC HL
        DJNZ cb_clear_byte
        
        POP BC
        POP AF
        INC A                   ; Next pixel row
        DEC C
        JR NZ, cb_pixel_row
        
        ; Now clear attrs from char (8,9) to (23,15) - 16x7 chars
        LD HL, SCREEN_ATTR + 9*32 + 8
        LD C, 7                 ; 7 rows
cb_attr_row:
        LD B, 16                ; 16 chars wide
cb_attr_col:
        LD A, BLACK             ; Black on black
        LD (HL), A
        INC HL
        DJNZ cb_attr_col
        ; Move to next row
        LD DE, 16               ; Skip to next row (32-16)
        ADD HL, DE
        DEC C
        JR NZ, cb_attr_row
        
        RET

draw_gameover:
        ; Clear center area first
        CALL clear_box
        
        ; "GAME OVER!" at center
        LD D, 10
        LD E, 10
        LD HL, str_gameover
        CALL print_str_at
        
        ; Red flashing attr
        LD HL, SCREEN_ATTR + 10*32 + 10
        LD A, RED + BRIGHT + FLASH
        LD B, 10
        CALL set_attr_row
        
        ; "PRESS ANY KEY"
        LD D, 9
        LD E, 14
        LD HL, str_press
        CALL print_str_at
        LD HL, SCREEN_ATTR + 14*32 + 9
        LD A, WHITE
        LD B, 13
        CALL set_attr_row
        
        RET

;; --------------------------------------------
;; SHOW GET READY - Display text and play countdown sound
;; --------------------------------------------

show_get_ready:
        ; Display "GET READY!" at center
        LD D, 11
        LD E, 10
        LD HL, str_ready
        CALL print_str_at
        
        ; Yellow bright attr
        LD HL, SCREEN_ATTR + 10*32 + 11
        LD A, YELLOW + BRIGHT
        LD B, 10
        CALL set_attr_row
        
        ; Play racing start sound (3 beeps + GO)
        CALL play_ready_sound
        
        ; No need to clear - redraw_center will be called after
        RET

; Redraw center area of board (where GET READY was displayed)
; Covers tiles around row 10, columns 5-10 (tiles, not chars)
redraw_center:
        ; GET READY is at char row 10, cols 11-20
        ; That's approximately tiles (5,5) to (10,5) - one row of tiles
        ; Tile row = char_row / 2 = 10/2 = 5
        ; Tile cols = char_col / 2 = 11/2=5 to 20/2=10
        
        LD C, 5                 ; Tile row 5
        LD B, 5                 ; Start at tile col 5
rc_loop:
        PUSH BC
        CALL get_cell
        CALL draw_cell
        POP BC
        INC B
        LD A, B
        CP 11                   ; End at tile col 10
        JR C, rc_loop
        RET

str_spaces:     DB "          ", 0     ; 10 spaces (kept for compatibility)

draw_levelup:
        ; Clear center area first
        CALL clear_box
        
        ; "LEVEL UP!" at center
        LD D, 11
        LD E, 10
        LD HL, str_levelup
        CALL print_str_at
        
        ; Green flashing attr
        LD HL, SCREEN_ATTR + 10*32 + 11
        LD A, GREEN + BRIGHT + FLASH
        LD B, 9
        CALL set_attr_row
        
        ; "GET READY!"
        LD D, 11
        LD E, 14
        LD HL, str_ready
        CALL print_str_at
        LD HL, SCREEN_ATTR + 14*32 + 11
        LD A, YELLOW + BRIGHT
        LD B, 10
        CALL set_attr_row
        
        RET

;; ============================================
;; INPUT HELPERS
;; ============================================

wait_key:
wk_rel:
        XOR A
        IN A, ($FE)
        CPL
        AND $1F
        JR NZ, wk_rel
wk_prs:
        XOR A
        IN A, ($FE)
        CPL
        AND $1F
        JR Z, wk_prs
        
        ; Small delay
        LD B, 20
wk_dly:
        HALT
        DJNZ wk_dly
        RET

;; ============================================
;; SOUND
;; ============================================

snd_eat:
        LD HL, 100
        LD DE, 2
        CALL ROM_BEEP
        XOR A
        OUT ($FE), A            ; Reset border to black
        RET

snd_die:
        LD B, 10
        LD HL, 200
sd_lp:
        PUSH BC
        PUSH HL
        LD DE, 1
        CALL ROM_BEEP
        POP HL
        LD DE, 30
        ADD HL, DE
        POP BC
        DJNZ sd_lp
        XOR A
        OUT ($FE), A            ; Reset border to black
        RET

snd_levelup:
        LD B, 5
        LD HL, 300
sl_lp:
        PUSH BC
        PUSH HL
        LD DE, 3
        CALL ROM_BEEP
        POP HL
        LD BC, 50
        OR A
        SBC HL, BC
        POP BC
        DJNZ sl_lp
        XOR A
        OUT ($FE), A            ; Reset border to black
        RET

;; ============================================
;; INCLUDE DATA FILES
;; ============================================

        INCLUDE "src/sprites.asm"
        INCLUDE "src/font.asm"

;; ============================================
;; MENU SCREEN DATA (6912 bytes)
;; ============================================

menu_screen:
        INCBIN "gfx/menu.scr"

;; ============================================
;; LEVEL DATA
;; ============================================

;; Spawn positions for each level
;; Format: head_x, head_y, direction (snake is 3 segments, placed horizontally)
;; Direction determines where body extends FROM head (opposite of movement)
level_spawns:
        ; Level 1: Empty - center, moving right
        DB 8, 5, DIR_RIGHT
        ; Level 2: Border - center, moving right
        DB 8, 5, DIR_RIGHT
        ; Level 3: Center block - left side, moving right
        DB 4, 5, DIR_RIGHT
        ; Level 4: Corners - center, moving right
        DB 8, 5, DIR_RIGHT
        ; Level 5: Cross - left side, moving right
        DB 4, 5, DIR_RIGHT
        ; Level 6: Diamonds - center, moving right
        DB 8, 5, DIR_RIGHT
        ; Level 7: Pillars - center, moving right
        DB 8, 5, DIR_RIGHT
        ; Level 8: Maze - center, moving right
        DB 8, 5, DIR_RIGHT

levels:
; Level 1: Empty
        DEFS 176, 0

; Level 2: Border
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 3: Center block
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,1,1,1,1,0,0,0,0,0,1
        DB 1,0,0,0,0,0,1,1,1,1,0,0,0,0,0,1
        DB 1,0,0,0,0,0,1,1,1,1,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 4: Corners
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1
        DB 1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1
        DB 1,0,1,1,0,0,0,0,0,0,0,0,1,1,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 5: Cross
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,0,0,0,0,0,0,0,0,0,0,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 6: Diamonds
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1
        DB 1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1
        DB 1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 7: Pillars
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,1,1,0,0,0,1,1,0,0,0,1,1,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1
        DB 1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1
        DB 1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,1,1,0,0,0,1,1,0,0,0,1,1,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

; Level 8: Maze
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
        DB 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1
        DB 1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,1,0,1,0,0,1,0,0,1,0,0,1,0,1,1
        DB 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
        DB 1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1
        DB 1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1
        DB 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

;; ============================================
;; SCREEN LINE ADDRESS LOOKUP TABLE
;; 192 entries (one for each pixel line)
;; Each entry is the screen address for start of that line
;; ============================================

scr_line_addr:
        ; Third 0: Lines 0-63 (base $4000)
        ; Lines 0-7 (char row 0)
        DW $4000, $4100, $4200, $4300, $4400, $4500, $4600, $4700
        ; Lines 8-15 (char row 1)
        DW $4020, $4120, $4220, $4320, $4420, $4520, $4620, $4720
        ; Lines 16-23 (char row 2)
        DW $4040, $4140, $4240, $4340, $4440, $4540, $4640, $4740
        ; Lines 24-31 (char row 3)
        DW $4060, $4160, $4260, $4360, $4460, $4560, $4660, $4760
        ; Lines 32-39 (char row 4)
        DW $4080, $4180, $4280, $4380, $4480, $4580, $4680, $4780
        ; Lines 40-47 (char row 5)
        DW $40A0, $41A0, $42A0, $43A0, $44A0, $45A0, $46A0, $47A0
        ; Lines 48-55 (char row 6)
        DW $40C0, $41C0, $42C0, $43C0, $44C0, $45C0, $46C0, $47C0
        ; Lines 56-63 (char row 7)
        DW $40E0, $41E0, $42E0, $43E0, $44E0, $45E0, $46E0, $47E0
        
        ; Third 1: Lines 64-127 (base $4800)
        ; Lines 64-71 (char row 8)
        DW $4800, $4900, $4A00, $4B00, $4C00, $4D00, $4E00, $4F00
        ; Lines 72-79 (char row 9)
        DW $4820, $4920, $4A20, $4B20, $4C20, $4D20, $4E20, $4F20
        ; Lines 80-87 (char row 10)
        DW $4840, $4940, $4A40, $4B40, $4C40, $4D40, $4E40, $4F40
        ; Lines 88-95 (char row 11)
        DW $4860, $4960, $4A60, $4B60, $4C60, $4D60, $4E60, $4F60
        ; Lines 96-103 (char row 12)
        DW $4880, $4980, $4A80, $4B80, $4C80, $4D80, $4E80, $4F80
        ; Lines 104-111 (char row 13)
        DW $48A0, $49A0, $4AA0, $4BA0, $4CA0, $4DA0, $4EA0, $4FA0
        ; Lines 112-119 (char row 14)
        DW $48C0, $49C0, $4AC0, $4BC0, $4CC0, $4DC0, $4EC0, $4FC0
        ; Lines 120-127 (char row 15)
        DW $48E0, $49E0, $4AE0, $4BE0, $4CE0, $4DE0, $4EE0, $4FE0
        
        ; Third 2: Lines 128-191 (base $5000)
        ; Lines 128-135 (char row 16)
        DW $5000, $5100, $5200, $5300, $5400, $5500, $5600, $5700
        ; Lines 136-143 (char row 17)
        DW $5020, $5120, $5220, $5320, $5420, $5520, $5620, $5720
        ; Lines 144-151 (char row 18)
        DW $5040, $5140, $5240, $5340, $5440, $5540, $5640, $5740
        ; Lines 152-159 (char row 19)
        DW $5060, $5160, $5260, $5360, $5460, $5560, $5660, $5760
        ; Lines 160-167 (char row 20)
        DW $5080, $5180, $5280, $5380, $5480, $5580, $5680, $5780
        ; Lines 168-175 (char row 21)
        DW $50A0, $51A0, $52A0, $53A0, $54A0, $55A0, $56A0, $57A0
        ; Lines 176-183 (char row 22)
        DW $50C0, $51C0, $52C0, $53C0, $54C0, $55C0, $56C0, $57C0
        ; Lines 184-191 (char row 23)
        DW $50E0, $51E0, $52E0, $53E0, $54E0, $55E0, $56E0, $57E0

;; ============================================
;; SOUND ROUTINES
;; ============================================

; play_note - Play a single note
; Input: DE = pitch (lower = higher note), B = duration
play_note:
        DI
pn_loop:
        PUSH BC
        
        ; Toggle speaker
        LD A, (pn_state)
        XOR $10                 ; Toggle bit 4 (speaker)
        LD (pn_state), A
        OUT ($FE), A
        
        ; Pitch delay - copy DE to BC
        PUSH DE
        POP BC
pn_delay:
        DEC BC
        LD A, B
        OR C
        JR NZ, pn_delay
        
        POP BC
        DJNZ pn_loop
        
        XOR A
        OUT ($FE), A            ; Reset border to black
        EI
        RET

pn_state: DB 0

; play_beep - Short beep with pitch and duration
; Input: HL = pitch, DE = duration count
play_beep:
        DI
pb_outer:
        PUSH DE
        
        ; Toggle speaker
        LD A, (pb_state)
        XOR $10
        LD (pb_state), A
        OUT ($FE), A
        
        ; Pitch delay
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
        OUT ($FE), A            ; Reset border to black
        EI
        RET

pb_state: DB 0

; delay_frames - Wait for N frames (1 frame = 20ms at 50Hz)
; Input: B = number of frames
delay_frames:
df_loop:
        HALT
        DJNZ df_loop
        RET

;; --------------------------------------------
;; MENU MUSIC - Plays during control selection
;; Returns immediately when key 1, 2, or 3 pressed
;; --------------------------------------------

play_menu_music:
        LD IX, melody_menu
pmm_loop:
        ; Check if end of melody (0,0)
        LD A, (IX+0)
        OR A
        JR Z, pmm_restart
        
        ; Get pitch (L, H)
        LD L, (IX+0)
        LD H, (IX+1)
        ; Get duration
        LD E, (IX+2)
        LD D, (IX+3)
        
        ; Play this note
        CALL play_beep_check_key
        
        ; If key pressed, return
        JR C, pmm_done
        
        ; Next note
        LD BC, 4
        ADD IX, BC
        JR pmm_loop
        
pmm_restart:
        LD IX, melody_menu
        JR pmm_loop
        
pmm_done:
        RET

; play_beep_check_key - Like play_beep but checks for key 1,2,3
; Returns: Carry set if key pressed
play_beep_check_key:
        DI
pbck_outer:
        PUSH DE
        
        ; Toggle speaker
        LD A, (pbck_state)
        XOR $10
        LD (pbck_state), A
        OUT ($FE), A
        
        ; Pitch delay with key check
        PUSH HL
        POP BC
pbck_delay:
        ; Check keys 1,2,3 every few cycles
        LD A, $F7               ; Row 1-5
        IN A, ($FE)
        AND $07                 ; Keys 1,2,3
        CP $07
        JR NZ, pbck_key_pressed ; If any bit is 0, key pressed
        
        DEC BC
        LD A, B
        OR C
        JR NZ, pbck_delay
        
        POP DE
        DEC DE
        LD A, D
        OR E
        JR NZ, pbck_outer
        
        ; No key pressed
        XOR A
        OUT ($FE), A            ; Reset border to black
        EI
        OR A                    ; Clear carry (A is already 0)
        RET
        
pbck_key_pressed:
        POP DE                  ; Balance stack
        XOR A
        OUT ($FE), A            ; Reset border to black
        EI
        SCF                     ; Set carry = key pressed
        RET

pbck_state: DB 0

;; --------------------------------------------
;; GET READY SOUND - Racing start style
;; 3 low beeps, 1 high GO beep
;; --------------------------------------------

play_ready_sound:
        ; 3 low beeps (0.4s apart)
        LD B, 3
prs_beep_loop:
        PUSH BC
        
        ; Low beep
        LD HL, 200              ; Pitch (lower = higher)
        LD DE, 150              ; Duration
        CALL play_beep
        
        ; Wait ~0.35s (17 frames)
        LD B, 17
        CALL delay_frames
        
        POP BC
        DJNZ prs_beep_loop
        
        ; High GO beep (longer)
        LD HL, 80               ; Higher pitch
        LD DE, 400              ; Longer duration
        CALL play_beep
        
        RET

;; --------------------------------------------
;; GAME OVER MUSIC - Sad descending melody
;; --------------------------------------------

play_gameover_music:
        LD IX, melody_gameover
pgm_loop:
        ; Check if end of melody (0,0)
        LD A, (IX+0)
        OR A
        RET Z                   ; End of melody
        
        ; Get pitch
        LD L, (IX+0)
        LD H, (IX+1)
        ; Get duration
        LD E, (IX+2)
        LD D, (IX+3)
        
        ; Play note
        CALL play_beep
        
        ; Small pause between notes
        LD B, 3
        CALL delay_frames
        
        ; Next note
        LD BC, 4
        ADD IX, BC
        JR pgm_loop

;; --------------------------------------------
;; MELODY DATA
;; Format: pitch_lo, pitch_hi, duration_lo, duration_hi
;; pitch: lower value = higher note
;; Terminated by 0,0,0,0
;; --------------------------------------------

; Menu melody - cheerful, looping tune
; Notes: C5, E5, G5, E5, F5, A5, G5, E5, D5, F5, E5, C5
melody_menu:
        ; C5
        DB $80, $00, $C0, $00
        ; E5
        DB $65, $00, $C0, $00
        ; G5
        DB $55, $00, $C0, $00
        ; E5
        DB $65, $00, $C0, $00
        ; F5
        DB $5D, $00, $C0, $00
        ; A5
        DB $48, $00, $C0, $00
        ; G5
        DB $55, $00, $C0, $00
        ; E5
        DB $65, $00, $C0, $00
        ; D5
        DB $72, $00, $C0, $00
        ; F5
        DB $5D, $00, $C0, $00
        ; E5
        DB $65, $00, $C0, $00
        ; C5 (longer)
        DB $80, $00, $80, $01
        ; End marker
        DB $00, $00, $00, $00

; Game over melody - sad, descending
; Notes: E4, D#4, D4, C#4, C4 (chromatic descent)
melody_gameover:
        ; E4 (long)
        DB $C8, $00, $00, $02
        ; Eb4
        DB $D5, $00, $80, $01
        ; D4
        DB $E2, $00, $80, $01
        ; Db4
        DB $F0, $00, $80, $01
        ; C4 (very long, low)
        DB $FF, $00, $00, $03
        ; End marker
        DB $00, $00, $00, $00

;; ============================================
;; VARIABLES
;; ============================================

state:          DEFS 1
menu_drawn:     DEFS 1
level:          DEFS 1
loop_count:     DEFS 1          ; Number of completed 8-level loops (for difficulty)
speed:          DEFS 1
framecnt:       DEFS 1
ctrl_mode:      DEFS 1
anim_frame:     DEFS 1

snk_x:          DEFS MAX_SNAKE
snk_y:          DEFS MAX_SNAKE
snk_dir:        DEFS MAX_SNAKE
snk_len:        DEFS 1
cur_dir:        DEFS 1
new_dir:        DEFS 1
inp_dir:        DEFS 1

new_x:          DEFS 1
new_y:          DEFS 1
tail_x:         DEFS 1
tail_y:         DEFS 1
snake_grew:     DEFS 1          ; Flag: 1 if snake just ate food
old_food_x:     DEFS 1          ; Position of eaten food to clear
old_food_y:     DEFS 1

; Food slot 1
food1_x:        DEFS 1
food1_y:        DEFS 1
food1_type:     DEFS 1          ; FOOD_NONE=empty, 0=apple, 1=banana, 2=grapes

; Food slot 2
food2_x:        DEFS 1
food2_y:        DEFS 1
food2_type:     DEFS 1

food_cnt:       DEFS 1
food_need:      DEFS 1
sf_other_type:  DEFS 1          ; Temp for spawn_food conflict check

score:          DEFS 2
hiscore:        DEFS 2
lives:          DEFS 1          ; Remaining lives (3,2,1,0)
level_score:    DEFS 2          ; Score at level start (for restart)

pn_pos_x:       DEFS 1          ; Temp for print_num
pn_pos_y:       DEFS 1

board:          DEFS BOARD_SIZE

        END start
