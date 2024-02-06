	DEVICE ZXSPECTRUM48


   ; +--------------------------------------------------+
   ; | ZX Spectrum Knight Lore Disassembly v1.00rc7     |
   ; |    - by tcdev (msmcdoug@gmail.com)               |
   ; +--------------------------------------------------+
   ;
   ; Original Memory Map:
   ;
   ; $4000-$57FF - spectrum video memory
   ; $5800-$5AFF - spectrum attribute memory
   ;       $5B9F - stack
   ; $5BA0-$6107 - variables
   ; $6108-$D8F2 - code and data
   ; $D8F3-$F0F2 - video buffer
   ; $F100-$FFFF - bit-shift & bit-reverse lookup tables
   ;             - (built at run-time)
   ; Processor       : z80 []
   ; Target assembler: ASxxxx by Alan R. Baldwin v1.5


; ===========================================================================
; Segment type: Regular
				ORG 0x4000
zx_vram:        DS 0x1800

; ===========================================================================
; Segment type: Regular
				ORG 0x5800
zx_aram:        DS 0x300

; Stack grows down from here
; Variables from here are zeroed at start of game
; ===========================================================================

							ORG 0x5BA0
clear_start:

seed_1:                     DS 2
seed_2:                     DS 2

; bit   3 : directional
; bit 2-1 : 00=keybd, 01=kempston, 10=cursor, 11=i/f-ii
user_input_method:          DS 1
seed_3:                     DS 1
old_input_method:           DS 1
							DS 1
;
; variables from here are zeroed each game
;
objs_wiped_cnt:             DS 1
tmp_SP:                     DS 2
room_size_X:                DS 1
room_size_Y:                DS 1
curr_room_attrib:           DS 1
room_size_Z:                DS 1
portcullis_moving:          DS 1
portcullis_move_cnt:        DS 1
transform_flag_graphic:     DS 1
not_1st_screen:             DS 1
pickup_drop_pressed:        DS 1
objects_carried_changed:    DS 1

; b5=???
; b4=pickup/drop
; b3=jump
; b2=forward
; b1=right
; b0=left
user_input:                 DS 1

tmp_attrib:                 DS 1
render_status_info:         DS 1
suppress_border:            DS 1
days:                       DS 1
lives:                      DS 1
objects_put_in_cauldron:    DS 1
fire_seed:                  DS 1
ball_bounce_height:         DS 1
rendered_objs_cnt:          DS 1
is_spike_ball_dropping:     DS 1
disable_spike_ball_drop:    DS 1
tmp_dZ:                     DS 1
tmp_bouncing_ball_dZ:       DS 1
all_objs_in_cauldron:       DS 1
obj_dropping_into_cauldron: DS 1
rising_blocks_z:            DS 1
num_scrns_visited:          DS 1
gfxbase_8x8:                DS 2
percent_msw:                DS 1
percent_lsw:                DS 1
tmp_objects_to_draw:        DS 2
render_obj_1:               DS 2
render_obj_2:               DS 2
audio_played:               DS 1
debounce_5:                 DS 1
cant_drop:                  DS 1
							DS 4
inventory:                  DS 4
objects_carried:            DS 7
unk_5BE3:                   DS 1
object_carried_2:           DS 1
							DS 2
end_of_objects_carried:     DS 1
;
; table of bits (flags) denoting room has been visited
; - used only in ratings calculations
;
scrn_visited:               DS 32
;
; table of objects (40 max)
; - 00,01 player sprites (00=bottom, 01=top)
; - 02,03 special object sprites
; - 04-39 background, then foreground
;
; +0 graphic_no.
; +1 x (center)
; +2 y (center)
; +3 z (bottom)
; +4 width (X radius)
; +5 depth (Y radius)
; +6 height
; +7 flags
;    - 7=vflip sprite
;    - 6=hflip sprite
;    - 5=wipe
;    - 4=draw
;    - 3=auto-adjust near arches (player only)
;    - 2=moveable
;    - 1=ignore in 3D calculations
;    - 0=is near arch (player only)
; +8 screen
; +9 dX
; +10 dY
; +11 dZ
; +12 counter and flags
;     - 7-4=counter when entering screen
;     - 3=jumping
;     - 2=Z out-of-bounds
;     - 1=Y out-of-bounds
;     - 0=X out-of-bounds
; +13 per-object info/flags
;     - direction and counters for looking, turning
;     - 7=deadly if object hits player
;     - 6=dead
;     - 5=deadly if player hits object
;     - 4=(not used)
;     - 3=triggered (dropping, collapsing blocks)
;     - 2=up (bouncing ball), dropping (spiked ball)
;     - 1=north (NS fire)
;     - 0=east (WE fire, EW guard), just dropped (spec objs)
; +14 d_x_adj
; +15 d_y_adj
; +16-17 ptr object table entry or tmp player graphic_no
; +18 pixel X adjustment
; +19 pixel Y adjustment
; +20-23 unused
; +24 sprite data width (bytes)
; +25 sprite data height (lines)
; +26 pixel X
; +27 pixel Y
; +28 old sprite data width (bytes)
; +29 old sprite data height (lines)
; +30 old pixel X
; +31 old pixel Y
;
graphic_objs_tbl:           DS 32
							DS 32
special_objs_here:          DS 32
special_objs_here_1:        DS 32
other_objs_here:            DS 32
							DS 1120
 
clear_end:

font:           DB 0x38, 0x6C, 0xD6, 0xD6, 0xD6, 0xD6, 0x6C, 0x38 ; '0'
				DB 0x18, 0x38, 0x58, 0x18, 0x18, 0x18, 0x18, 0x7C ; '1'
				DB 0x38, 0x4C, 0x0C, 0x3C, 0x60, 0xC2, 0xC2, 0xFE ; '2'
				DB 0x38, 0x4C, 0x0C, 0x3C, 0x0E, 0x86, 0x86, 0xFC ; '3'
				DB 0x18, 0x38, 0x58, 0x9A, 0xFE, 0x1A, 0x18, 0x7C ; '4'
				DB 0xFE, 0xC2, 0xC0, 0xFC, 0x06, 0x06, 0x86, 0x7C ; '5'
				DB 0x1E, 0x32, 0x60, 0x7C, 0xC6, 0xC6, 0xC6, 0x7C ; '6'
				DB 0x7E, 0x46, 0x4C, 0x0C, 0x18, 0x18, 0x30, 0xF8 ; '7'
				DB 0x38, 0x6C, 0x6C, 0x7C, 0xFE, 0xC6, 0xC6, 0x7C ; '8'
				DB 0x7C, 0xC6, 0xC6, 0xC6, 0x7C, 0x0C, 0x98, 0xF0 ; '9'
				DB 0x0C, 0x1C, 0x2E, 0x66, 0x46, 0xCE, 0xDB, 0x66 ; 'A'
				DB 0xF8, 0x6C, 0x6C, 0x78, 0x6C, 0x66, 0x66, 0xFC ; 'B'
				DB 0x0E, 0x32, 0x60, 0x40, 0xC0, 0xC2, 0xE6, 0x7C ; 'C'
				DB 0x60, 0x70, 0x68, 0x6C, 0x66, 0x66, 0x66, 0xFC ; 'D'
				DB 0xFE, 0x60, 0x64, 0x7C, 0x64, 0x60, 0x7A, 0xC6 ; 'E'
				DB 0xC6, 0x7A, 0x60, 0x64, 0x7C, 0x64, 0x60, 0x60 ; 'F'
				DB 0x0E, 0x30, 0x60, 0xC6, 0xCE, 0xF6, 0x66, 0x0E ; 'G'
				DB 0xEE, 0xC6, 0xC6, 0xFE, 0xC6, 0xC6, 0xC6, 0xEE ; 'H'
				DB 0x7C, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7C ; 'I'
				DB 0x1E, 0x06, 0x06, 0x86, 0x86, 0xC6, 0x7E, 0x1C ; 'J'
				DB 0xE4, 0x68, 0x70, 0x78, 0x6C, 0x64, 0x64, 0xF6 ; 'K'
				DB 0xE0, 0x60, 0x60, 0x60, 0x60, 0x60, 0x62, 0xFE ; 'L'
				DB 0xC6, 0xEE, 0xEE, 0xD6, 0xD6, 0xD6, 0xC6, 0xEE ; 'M'
				DB 0xCC, 0xD6, 0xD6, 0xE6, 0xE4, 0xC4, 0xC8, 0xDE ; 'N'
				DB 0x38, 0x6C, 0xC6, 0xC6, 0xC6, 0xC6, 0x6C, 0x38 ; 'O'
				DB 0xF8, 0x6C, 0x66, 0x76, 0x6E, 0x60, 0x60, 0xF0 ; 'P'
				DB 0x38, 0x6C, 0xC6, 0xC6, 0xC6, 0xD6, 0x6C, 0x3A ; 'Q'
				DB 0xF8, 0x6C, 0x66, 0x76, 0x7E, 0x78, 0x6C, 0xE6 ; 'R'
				DB 0x38, 0x64, 0x60, 0x3C, 0x06, 0x86, 0xC6, 0x7C ; 'S'
				DB 0xFE, 0x9A, 0x98, 0x18, 0x18, 0x18, 0x18, 0x18 ; 'T'
				DB 0xF6, 0x26, 0x46, 0x4E, 0xCE, 0xD6, 0xD6, 0x66 ; 'U'
				DB 0xE2, 0x62, 0x64, 0x64, 0x68, 0x68, 0x70, 0x60 ; 'V'
				DB 0xEE, 0xC6, 0xD6, 0xD6, 0xD6, 0xEE, 0xEE, 0xC6 ; 'W'
				DB 0xC6, 0xC6, 0x6C, 0x38, 0x38, 0x6C, 0xC6, 0xC6 ; 'X'
				DB 0x86, 0x66, 0x16, 0x0E, 0x06, 0x04, 0x4C, 0x38 ; 'Y'
				DB 0x7E, 0x46, 0x0C, 0x18, 0x30, 0x62, 0xC2, 0xFE ; 'Z'
				DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00 ; '.'
				DB 0x3C, 0x42, 0x99, 0xA1, 0xA1, 0x99, 0x42, 0x3C ; '(c)'
				DB 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ; ' '
				DB 0x00, 0x62, 0x64, 0x08, 0x10, 0x26, 0x46, 0x00 ; '%'

; ---------------------------------------------------------------------------
; colours
menu_colours:   DB 0x43, 0xC4, 0x44, 0x44, 0x44, 0x45, 0x47, 0x47
; XY positions
menu_xy:        DB 88, 159, 48, 143, 48, 127, 48, 111, 48, 95, 48, 79
				DB 48, 63, 80, 39

; "KNIGHT LORE"
menu_text:      DB 0x14, 0x17, 0x12, 0x10, 0x11, 0x1D, 0x26, 0x15, 0x18
				DB 0x1B, 0x8E

; "1 KEYBOARD"
				DB 1, 0x26, 0x14, 0xE, 0x22, 0xB, 0x18, 0xA, 0x1B, 0x8D

; "2 KEMPSTON JOYSTICK"
				DB 2, 0x26, 0x14, 0xE, 0x16, 0x19, 0x1C, 0x1D, 0x18, 0x17
				DB 0x26, 0x13, 0x18, 0x22, 0x1C, 0x1D, 0x12, 0xC, 0x94

; "3 CURSOR   JOYSTICK"
				DB 3, 0x26, 0xC, 0x1E, 0x1B, 0x1C, 0x18, 0x1B, 0x26, 0x26
				DB 0x26, 0x13, 0x18, 0x22, 0x1C, 0x1D, 0x12, 0xC, 0x94

; "4 INTERFACE II"
				DB 4, 0x26, 0x12, 0x17, 0x1D, 0xE, 0x1B, 0xF, 0xA, 0xC
				DB 0xE, 0x26, 0x12, 0x92

; "5 DIRECTIONAL CONTROL"
				DB 5, 0x26, 0xD, 0x12, 0x1B, 0xE, 0xC, 0x1D, 0x12, 0x18
				DB 0x17, 0xA, 0x15, 0x26, 0xC, 0x18, 0x17, 0x1D, 0x1B
				DB 0x18, 0x95

; "0 START GAME"
				DB 0, 0x26, 0x1C, 0x1D, 0xA, 0x1B, 0x1D, 0x26, 0x10, 0xA
				DB 0x16, 0x8E

; "(c) 1984 A.C.G."
				DB 0x25, 0x26, 1, 9, 8, 4, 0x26, 0xA, 0x24, 0xC, 0x24
				DB 0x10, 0xA4


complete_colours:DB 0x47, 0x46, 0x45, 0x44, 0x43, 0x42
complete_xy:    DB 0x40, 0x87, 0x40, 0x77, 0x30, 0x67, 0x30, 0x57, 0x50
				DB 0x47, 0x30, 0x37

; "THE POTION CASTS"
the_potion_casts:
				DB 0x1D, 0x11, 0xE, 0x26, 0x19, 0x18, 0x1D, 0x12, 0x18
				DB 0x17, 0x26, 0xC, 0xA, 0x1C, 0x1D, 0x9C

; "ITS MAGIC STRONG"
				DB 0x12, 0x1D, 0x1C, 0x26, 0x16, 0xA, 0x10, 0x12, 0xC
				DB 0x26, 0x1C, 0x1D, 0x1B, 0x18, 0x17, 0x90

; "ALL EVIL MUST BEWARE"
				DB 0xA, 0x15, 0x15, 0x26, 0xE, 0x1F, 0x12, 0x15, 0x26
				DB 0x16, 0x1E, 0x1C, 0x1D, 0x26, 0xB, 0xE, 0x20, 0xA
				DB 0x1B, 0x8E

; "THE SPELL HAS BROKEN"
				DB 0x1D, 0x11, 0xE, 0x26, 0x1C, 0x19, 0xE, 0x15, 0x15
				DB 0x26, 0x11, 0xA, 0x1C, 0x26, 0xB, 0x1B, 0x18, 0x14
				DB 0xE, 0x97

; "YOU ARE FREE"
				DB 0x22, 0x18, 0x1E, 0x26, 0xA, 0x1B, 0xE, 0x26, 0xF
				DB 0x1B, 0xE, 0x8E

; "GO FORTH TO MIRE MARE"
				DB 0x10, 0x18, 0x26, 0xF, 0x18, 0x1B, 0x1D, 0x11, 0x26
				DB 0x1D, 0x18, 0x26, 0x16, 0x12, 0x1B, 0xE, 0x16, 0xA
				DB 0x1B, 0x8E

; Game Over status screen
gameover_colours:
				DB 0x47, 0x46, 0x45, 0x45, 0x43, 0x44
gameover_xy:    DB 0x58, 0x9F, 0x50, 0x7F, 0x30, 0x6F, 0x40, 0x5F, 0x30
				DB 0x4F, 0x48, 0x37

; "GAME  OVER"
a_GAME_OVER:    DB 0x10, 0xA, 0x16, 0xE, 0x26, 0x26, 0x18, 0x1F, 0xE
				DB 0x9B

; "TIME    DAYS"
				DB 0x1D, 0x12, 0x16, 0xE, 0x26, 0x26, 0x26, 0x26, 0xD
				DB 0xA, 0x22, 0x9C

; "PERCENTAGE OF QUEST"
				DB 0x19, 0x0E, 0x1B, 0x0C, 0x0E, 0x17, 0x1D, 0x0A, 0x10, 0x0E
				DB 0x26, 0x18, 0x0F, 0x26, 0x1A, 0x1E, 0xE, 0x1C, 0x9D

; "COMPLETED     %"
				DB 0x0C, 0x18, 0x16, 0x19, 0x15, 0x0E, 0x1D, 0x0E, 0x0D, 0x26
				DB 0x26, 0x26, 0x26, 0x26, 0xA7

; "CHARMS COLLECTED"
				DB 0x0C, 0x11, 0xA, 0x1B, 0x16, 0x1C, 0x26, 0x0C, 0x18
				DB 0x15, 0x15, 0xE, 0x0C, 0x1D, 0x0E, 0xD, 0x26, 0x26, 0xA6

; "OVERALL RATING"
				DB 0x18, 0x1F, 0x0E, 0x1B, 0x0A, 0x15, 0x15, 0x26, 0x1B
				DB 0x0A, 0x1D, 0x12, 0x17, 0x90

rating_tbl:     DW a_POOR
				DW a_AVERAGE
				DW a_FAIR
				DW a_GOOD
				DW a_EXCELLENT
				DW a_MARVELLOUS
				DW a_HERO
				DW a_ADVENTURER

a_POOR:         DB 0x42, 0x26, 0x26, 0x26, 0x19, 0x18, 0x18, 0x9B
a_AVERAGE:      DB 0x42, 0x26, 0xA, 0x1F, 0xE, 0x1B, 0xA, 0x10, 0x8E
a_FAIR:         DB 0x42, 0x26, 0x26, 0x26, 0xF, 0xA, 0x12, 0x9B
a_GOOD:         DB 0x42, 0x26, 0x26, 0x26, 0x10, 0x18, 0x18, 0x8D
a_EXCELLENT:    DB 0x42, 0xE, 0x21, 0xC, 0xE, 0x15, 0x15, 0xE, 0x17, 0x9D
a_MARVELLOUS:   DB 0x42, 0x16, 0xA, 0x1B, 0x1F, 0xE, 0x15, 0x15, 0x18, 0x1E, 0x9C
a_HERO:         DB 0x42, 0x26, 0x26, 0x26, 0x11, 0xE, 0x1B, 0x98
a_ADVENTURER:   DB 0x42, 0xA, 0xD, 0x1F, 0xE, 0x17, 0x1D, 0x1E, 0x1B, 0xE, 0x9B

; sprite index, flags, X, Y
border_data:    DB 0x89, 0x00, 0, 0xA0
				DB 0x89, 0x40, 0xE0, 0xA0
				DB 0x89, 0xC0, 0xE0, 0
				DB 0x89, 0x80, 0, 0
				DB 0x8B, 0x00, 0x20, 0xA8
				DB 0x8B, 0x00, 0x20, 0
				DB 0x8A, 0x00, 0, 0x20
				DB 0x8A, 0x00, 0xE8, 0x20

; room size table
room_size_tbl:  DB 64, 64, 128                                 ; 0
				DB 32, 64, 128                                 ; 1
				DB 64, 32, 128                                 ; 2

; locations
location_tbl:   DB 0, 25, 3                                    ; id=0
				DB 0, 1, 0xC, 0xFF, 7, 0x10, 0x50, 0x90, 0x11, 0x51, 0x91
				DB 0xA, 0x4A, 6, 0x8A, 2, 0x42, 0x82, 0xC8, 0xC1, 0xC0
				
				DB 0xA8, 0xC9
				DB 1, 20, 20                                   ; id=1
				DB 1, 3, 0xD, 0xFF, 3, 0x2B, 0x2C, 0x13, 0x14, 0x23, 0x6B
				DB 0x6C, 0x53, 0x54, 0x40, 0x1C, 0x48, 0x28
				
				DB 2, 6, 3                                     ; id=2
				DB 0, 1, 3, 0xC
				
				DB 3, 26, 22                                   ; id=3
				DB 1, 3, 0xD, 0xFF, 3, 0x22, 0x1A, 0x25, 0x1D, 0x2B, 0x23
				DB 0x1B, 0x24, 0x1C, 0x93, 0x2B, 0x2C, 0x13, 0x14, 0xB3
				DB 0x63, 0x64, 0x5B, 0x5C
				
				DB 4, 19, 5                                    ; id=4
				DB 0, 3, 0xC, 0xFF, 0x2B, 0x23, 0x1A, 0x1C, 0x13, 0xB2
				DB 0x5A, 0x5C, 0x53, 2, 0x63, 0x9B, 0xDB

				DB 8, 26, 3                                    ; id=8
				DB 4, 5, 0xF, 0x10, 0xFF, 0x1B, 0x1B, 0x5B, 0x9B, 0xDB
				DB 0x2B, 0x23, 0x1A, 0x1C, 0x13, 0x93, 0x63, 0x5A, 0x5C
				DB 0x53, 0xB8, 9, 0x80, 0x49

				DB 9, 11, 6                                    ; id=9
				DB 5, 7, 0xF, 0x11, 9, 0xB, 0xFF, 0x48, 0x23
				
				DB 10, 25, 3                                   ; id=10
				DB 5, 7, 0xF, 0x11, 0xFF, 0x1D, 0x22, 0x62, 0xA2, 0x24
				DB 0x64, 0xA4, 0x2F, 0x2A, 0x2B, 0x6B, 0x2C, 0x1A, 0x1B
				DB 0x5B, 0x1C, 0x38, 0xE
				
				DB 11, 6, 6                                    ; id=11
				DB 5, 7, 0xF, 0x11
				
				DB 12, 23, 3                                   ; id=12
				DB 5, 7, 0xF, 0x11, 0xFF, 0x2F, 0x3D, 0x32, 0x28, 0x2C
				DB 0x2F, 0x22, 0x1C, 0x10, 0x2B, 0x12, 0x17, 0xD, 4, 0xB8
				DB 0x24
				
				DB 13, 6, 4                                    ; id=13
				DB 0, 1, 3, 0xC
				
				DB 14, 11, 21                                  ; id=14
				DB 1, 3, 0xD, 0xFF, 0x53, 0x12, 0x1D, 0x2C, 0x23
				
				DB 15, 28, 4                                   ; id=15
				DB 0, 3, 0xC, 0xFF, 7, 0x23, 0x25, 0x13, 0x15, 0x63, 0x64
				DB 0x65, 0x5B, 4, 0x5D, 0x53, 0x54, 0x55, 0x1C, 0x9B
				DB 0xA4, 0x9B, 0x9D, 0x94, 0xB0, 0x9C
				
				DB 16, 24, 13                                  ; id=16
				DB 0, 0x15, 0x17, 0xE, 0xFF, 1, 0xC3, 0xC4, 0x5B, 5, 0xC
				DB 0xB, 0xA, 0x9B, 0x45, 0x4C, 0x4B, 0x4A, 0xA8, 0xC2
				DB 0x50, 0x5A
				
				DB 18, 24, 12                                  ; id=18
				DB 0, 2, 0xE, 0xFF, 0x97, 0xFA, 0xFD, 0xF3, 0xF4, 0xEB
				DB 0xEC, 0xE3, 0xE4, 0x97, 0xDB, 0xDC, 0xD3, 0xD4, 0xCB
				DB 0xCC, 0xC2, 0xC5
				
				DB 20, 26, 14                                  ; id=20
				DB 0, 0x15, 0x17, 0xE, 0xFF, 1, 0xC3, 0xC4, 0xAD, 0xC2
				DB 0xCA, 0xD2, 0xDA, 0xDB, 0xDC, 0xAC, 0xDD, 0xE5, 0xAD
				DB 0x75, 0x3D, 0x29, 0xB, 0xC
				
				DB 24, 17, 13                                  ; id=24
				DB 0, 2, 0xE, 0xFF, 0x2F, 0x2A, 0x2B, 0x2C, 0x2D, 0x12
				DB 0x13, 0x14, 0x15, 0xB8, 0x1B
				
				DB 29, 27, 14                                  ; id=29
				DB 0, 0x15, 0x17, 0xE, 0xFF, 7, 0xC3, 0xC4, 0xC, 0x4C
				DB 0x8C, 0xCC, 0x24, 0x64, 2, 0x2C, 0x6C, 0x34, 0x29
				DB 0x14, 0x1C, 0x58, 0xC, 0x78, 0x54
				
				DB 31, 23, 11                                  ; id=31
				DB 0, 2, 0xE, 0xFF, 3, 0x12, 0x15, 0x2A, 0x2D, 0x2F, 0x52
				DB 0x13, 0x14, 0x55, 0x6A, 0x2B, 0x2C, 0x6D, 0xE1, 0x93
				DB 0x6B
				
				DB 32, 18, 3                                   ; id=32
				DB 0, 1, 0x15, 0x17, 0xC, 0xFF, 2, 0x18, 0xC3, 0xC4, 0xAA
				DB 0x50, 0x88, 0xC0, 0x28, 2
				
				DB 33, 28, 22                                  ; id=33
				DB 0x14, 0x16, 3, 0xD, 0xFF, 7, 0x21, 0x61, 0xA2, 0xA3
				DB 0x24, 0x64, 0x25, 0x65, 3, 0x26, 0x66, 0xE7, 0xDF
				DB 0x29, 0xA4, 0xA6, 0x30, 0xE2, 0xC0, 0xA5
				
				DB 34, 26, 3                                   ; id=34
				DB 2, 3, 0xC, 0xFF, 3, 0x30, 0x78, 0xB9, 0xFA, 0x2F, 0x39
				DB 0x3A, 0x3D, 0x3E, 0x3F, 0x33, 0x2B, 0x23, 0x2A, 0x34
				DB 0x2C, 0x24, 0xA8, 0xFB
				
				DB 36, 24, 3                                   ; id=36
				DB 0, 2, 0xC, 0xFF, 0x2F, 2, 5, 0xA, 0xF, 0x10, 0x15
				DB 0x19, 0x1B, 0x2F, 0x1C, 0x1F, 0x28, 0x2A, 0x2C, 0x2E
				DB 0x3A, 0x3D
				
				DB 39, 15, 6                                   ; id=39
				DB 0, 0xC, 0xFF, 3, 0x1B, 0x1C, 0x23, 0x24, 0x4B, 0x12
				DB 0x15, 0x2A, 0x2D
				
				DB 40, 16, 14                                  ; id=40
				DB 0, 0x15, 0xE, 0x17, 0xFF, 0x39, 0x23, 0x63, 0x29, 0xB
				DB 0xC, 1, 0xC3, 0xC4
				
				DB 45, 23, 4                                   ; id=45
				DB 0x14, 2, 0x16, 0xC, 0xFF, 7, 0xDF, 0xE7, 0x13, 0x1B
				DB 0x23, 0x5B, 0x63, 0xA3, 0x2B, 0x1E, 0x26, 0x22, 0x24
				DB 0x70, 0xE3
				
				DB 46, 17, 21                                  ; id=46
				DB 1, 3, 0xD, 0xFF, 0x2F, 0x2B, 0x2C, 0x22, 0x25, 0x1A
				DB 0x1D, 0x13, 0x14, 0x68, 0x23
				
				DB 47, 6, 4                                    ; id=47
				DB 0, 2, 3, 0xC
				
				DB 48, 22, 13                                  ; id=48
				DB 0, 2, 0xE, 0xFF, 0x2F, 0x33, 0x34, 0x2A, 0x2D, 0x22
				DB 0x25, 0x1A, 0x1D, 0x2B, 0x12, 0x15, 0xB, 0xC, 0xB8
				DB 0x1B
				
				DB 52, 24, 14                                  ; id=52
				DB 0, 2, 0xE, 0xFF, 0x3F, 0x1A, 0x1B, 0x1C, 0x1D, 0x5A
				DB 0x5B, 0x5C, 0x5D, 0x97, 0x9A, 0x9B, 0x9C, 0x9D, 0xDA
				DB 0xDB, 0xDC, 0xDD
				
				DB 55, 13, 13                                  ; id=55
				DB 0, 2, 0xE, 0xFF, 0x78, 0x14, 0, 0x2C, 0x49, 0x25, 0x1A
				
				DB 56, 25, 11                                  ; id=56
				DB 0, 0x15, 0x17, 0xE, 0xFF, 5, 0x7A, 0xF2, 0xDA, 0xC2
				DB 0xC3, 0xC4, 0xB3, 0xEA, 0xE2, 0xD2, 0xCA, 0x2C, 0x2A
				DB 0x22, 0x1A, 0x12, 0xA
				
				DB 63, 25, 3                                   ; id=63
				DB 4, 6, 0xF, 0x10, 0xFF, 0x1F, 0x18, 0x19, 0x1A, 0x5A
				DB 0x1D, 0x5D, 0x1E, 0x1F, 0x2D, 0x58, 0x59, 0x9A, 0x9D
				DB 0x5E, 0x5F, 0xD0, 0x1B
				
				DB 64, 19, 6                                   ; id=64
				DB 0x14, 0x15, 0x16, 0x17, 0xC, 0xFF, 5, 0x3F, 6, 0xC3
				DB 0xC4, 0xDF, 0xE7, 0x68, 0x38, 0x80, 0xB8
				
				DB 65, 23, 20                                  ; id=65
				DB 1, 3, 0xD, 0xFF, 5, 0x12, 0x14, 0x16, 0x2A, 0x2C, 0x2E
				DB 0x25, 0x52, 0x54, 0x56, 0x6A, 0x6C, 0x6E, 0x51, 0x15
				DB 0x2B
				
				DB 66, 21, 5                                   ; id=66
				DB 1, 3, 0xC, 0xFF, 1, 0x1B, 0xDC, 0xA9, 0x63, 0xA4, 0x2F
				DB 0x12, 0x1A, 0x22, 0x2B, 0x2C, 0x25, 0x1D, 0x14
				
				DB 67, 27, 22                                  ; id=67
				DB 1, 3, 0xD, 0xFF, 7, 0x1E, 0x26, 0x5D, 0x65, 0x19, 0x21
				DB 0x5A, 0x62, 3, 0x2B, 0x2C, 0x13, 0x14, 0x2B, 0x6B
				DB 0x6C, 0x53, 0x54, 0x60, 0x1B
				
				DB 68, 7, 4                                    ; id=68
				DB 0, 1, 2, 3, 0xC
				
				DB 69, 29, 5                                   ; id=69
				DB 1, 3, 0xC, 0xFF, 7, 0x23, 0x25, 0x13, 0x15, 0x63, 0x64
				DB 0x65, 0x5B, 3, 0x5D, 0x53, 0x54, 0x55, 0x9B, 0xA4
				DB 0x9B, 0x9D, 0x94, 0xB0, 0x9C, 0x28, 0x1C
				
				DB 70, 28, 22                                  ; id=70
				DB 1, 3, 0xD, 0xFF, 7, 0x23, 0x1B, 0x2C, 0x6C, 0x14, 0x54
				DB 0x25, 0x1D, 0x23, 0x65, 0x5D, 0x63, 0x5B, 0x91, 0x24
				DB 0x1C, 0xB3, 0xA4, 0xE4, 0x9C, 0xDC
				
				DB 71, 6, 3                                    ; id=71
				DB 0, 2, 3, 0xC
				
				DB 72, 23, 14                                  ; id=72
				DB 0, 0x15, 0x17, 0xE, 0xFF, 7, 0xC3, 0xC4, 0xCC, 0x2C
				DB 0x2D, 0x25, 0x6C, 0x6D, 0, 0xAC, 0x29, 0xB, 0x14, 0x78
				DB 0x8C
				
				DB 79, 21, 6                                   ; id=79
				DB 4, 6, 0xF, 0x10, 0xFF, 0x9F, 0xD8, 0xD9, 0xDA, 0xDB
				DB 0xDC, 0xDD, 0xDE, 0xDF, 0x9B, 0xC3, 0xC4, 0xFB, 0xFC
				
				DB 84, 22, 13                                  ; id=84
				DB 0, 2, 0xE, 0xFF, 1, 0xC, 0x33, 0x2B, 0x1A, 0x5A, 0x25
				DB 0x65, 0x93, 0x13, 0xB, 0x2C, 0x24, 0x79, 0x14, 0x23
				
				DB 87, 20, 13                                  ; id=87
				DB 0, 2, 0xE, 0xFF, 7, 0x2D, 0x6D, 0xAD, 0x24, 0x64, 0xA4
				DB 0x1B, 0x5B, 3, 0x9B, 0x12, 0x52, 0x92
				
				DB 88, 11, 13                                  ; id=88
				DB 0, 0x15, 0x17, 0xE, 0xFF, 0x48, 0x1D, 0x80, 0x5D
				
				DB 94, 18, 6                                   ; id=94
				DB 4, 5, 0xF, 0x10, 0xFF, 0x1F, 0x32, 0x35, 0x29, 0x2E
				DB 0x11, 0x16, 0xA, 0xD, 0xC8, 0x2D
				
				DB 95, 6, 3                                    ; id=95
				DB 4, 6, 7, 0xF
				
				DB 100, 18, 14                                 ; id=100
				DB 0, 0x15, 0x17, 0xE, 0xFF, 7, 3, 4, 0xB, 0xC, 0x23
				DB 0x24, 0x2B, 0x2C, 0x30, 0x63
				
				DB 103, 18, 12                                 ; id=103
				DB 0, 2, 0xE, 0xFF, 1, 0x2A, 0x2D, 0x2B, 0x6A, 0x6D, 0x1A
				DB 0x1D, 0xD0, 0x2B, 0x68, 0x25
				
				DB 104, 25, 11                                 ; id=104
				DB 0, 2, 0xE, 0xFF, 7, 0x3A, 0x7A, 0xBA, 0xFA, 0x3D, 0x7D
				DB 0xBD, 0xFD, 3, 0x32, 0x33, 0x34, 0x35, 0x29, 0x72
				DB 0x75, 0x60, 0xA3
				
				DB 106, 5, 6                                   ; id=106
				DB 0, 1, 0xC
				
				DB 107, 17, 20                                 ; id=107
				DB 0x14, 3, 0x16, 0xD, 0xFF, 5, 0x24, 0x1C, 0x64, 0x5C
				DB 0xE7, 0xDF, 0x51, 0xD6, 0xED
				
				DB 108, 24, 19                                 ; id=108
				DB 1, 3, 0xD, 0xFF, 0x37, 0x2B, 0x23, 0x1B, 0x13, 0x6B
				DB 0x63, 0x5B, 0x53, 0x9F, 0xAB, 0xA3, 0x9B, 0x93, 0xEB
				DB 0xE3, 0xDB, 0xD3
				
				DB 109, 23, 6                                  ; id=109
				DB 5, 7, 0xF, 0x11, 0xFF, 0x1F, 0x14, 0x2C, 0x54, 0x6C
				DB 0x94, 0x9C, 0xA4, 0xAC, 0x21, 0xD4, 0xEC, 0x38, 9
				DB 0x40, 0x1E
				
				DB 110, 7, 3                                   ; id=110
				DB 5, 6, 7, 0xF, 0x11
				
				DB 111, 20, 6                                  ; id=111
				DB 6, 7, 0xF, 0x11, 0xFF, 0x1A, 0x2D, 0x2E, 0x2F, 0x22
				DB 0x6D, 0x6E, 0x6F, 0x9B, 0x3D, 0x35, 0x7D, 0x75
				
				DB 116, 24, 4                                  ; id=116
				DB 1, 2, 0xC, 0xFF, 0x2A, 0x39, 0x30, 0x31, 7, 0x3A, 0x7A
				DB 0x32, 0x72, 0x28, 0x68, 0x29, 0x69, 0xB3, 0xB8, 0xB9
				DB 0xB0, 0xB1
				
				DB 117, 14, 19                                 ; id=117
				DB 1, 3, 0xD, 0xFF, 1, 0x23, 0x1C, 0x29, 0x24, 0x1B, 0xC8
				DB 0x2B
				
				DB 118, 22, 22                                 ; id=118
				DB 0x14, 3, 0x16, 0xD, 0xFF, 6, 0xDF, 0xE7, 0xEF, 0xAE
				DB 0x6D, 0x2C, 0xD7, 0x2D, 0x16, 0x1E, 0x26, 0x15, 0x1D
				DB 0x25
				
				DB 119, 7, 3                                   ; id=119
				DB 0, 1, 2, 3, 0xC
				
				DB 120, 25, 4                                  ; id=120
				DB 0, 1, 2, 3, 0xC, 0xFF, 0x2F, 0x39, 0x3F, 0x35, 0x28
				DB 0x2C, 0x2F, 0x23, 0x1D, 0x2C, 0x11, 0x13, 0xA, 0xD
				DB 0xE, 0x68, 0x17
				
				DB 121, 22, 19                                 ; id=121
				DB 1, 3, 0xD, 0xFF, 0xB3, 0x22, 0x1A, 0x25, 0x1D, 0x2F
				DB 0x2B, 0x2C, 0x23, 0x24, 0x1B, 0x1C, 0x13, 0x14, 0x60
				DB 0xDB
				
				DB 122, 22, 5                                  ; id=122
				DB 2, 3, 0xC, 0xFF, 4, 0x28, 0x70, 0xB8, 0xB9, 0xFF, 0x2D
				DB 0xBA, 0xBC, 0xBE, 0x37, 0x2F, 0x27, 0xA9, 0xFB, 0xFD
				
				DB 131, 5, 6                                   ; id=131
				DB 0, 1, 0xC
				
				DB 132, 23, 21                                 ; id=132
				DB 1, 3, 0xD, 0xFF, 7, 0x2A, 0x6A, 0x2D, 0x6D, 0x12, 0x52
				DB 0x15, 0x55, 0x23, 0xAA, 0xAD, 0x92, 0x95, 0x11, 0x1D
				DB 0x9A
				
				DB 133, 25, 20                                 ; id=133
				DB 0x14, 3, 0x16, 0xD, 0xFF, 5, 0x28, 0x69, 0xAA, 0xEB
				DB 0xE7, 0xDF, 0x2F, 0x1B, 0x23, 0x1C, 0x24, 0x1D, 0x25
				DB 0x1E, 0x26, 0x78, 0xDB
				
				DB 134, 11, 19                                 ; id=134
				DB 0x14, 3, 0x16, 0xD, 0xFF, 0x80, 0x63, 0xB8, 0x23
				
				DB 135, 24, 5                                  ; id=135
				DB 0, 1, 2, 3, 0xC, 0xFF, 3, 0x2A, 0x2D, 0x12, 0x15, 0x2B
				DB 0x6A, 0x6D, 0x52, 0x55, 0xD1, 0x2B, 0x13, 0xD9, 0x1A
				DB 0x1D
				
				DB 136, 19, 6                                  ; id=136
				DB 0, 1, 2, 3, 0x12, 0x13, 0xC, 0xFF, 7, 0x32, 0x29, 0x35
				DB 0x2E, 0x16, 0xD, 0x11, 0xA
				
				DB 137, 20, 21                                 ; id=137
				DB 1, 3, 0xD, 0xFF, 7, 0x2C, 0x6C, 0xAC, 0x24, 0x1C, 0x14
				DB 0x54, 0x94, 0x21, 0xEC, 0xD4, 0x50, 0x64
				
				DB 138, 24, 19                                 ; id=138
				DB 1, 3, 0xD, 0xFF, 0x5F, 0x2A, 0x22, 0x1A, 0x12, 0x2D
				DB 0x25, 0x1D, 0x15, 0x97, 0xEA, 0xE2, 0xDA, 0xD2, 0xED
				DB 0xE5, 0xDD, 0xD5
				
				DB 139, 6, 5                                   ; id=139
				DB 0, 1, 3, 0xC
				
				DB 140, 25, 20                                 ; id=140
				DB 1, 3, 0xD, 0xFF, 7, 0x2A, 0x6A, 0x2D, 0x6D, 0x12, 0x52
				DB 0x15, 0x55, 0x2B, 0xAA, 0xAD, 0x92, 0x95, 0xD9, 0x1A
				DB 0x1D, 0x40, 0x1B
				
				DB 141, 26, 5                                  ; id=141
				DB 1, 3, 0xC, 0xFF, 7, 0x34, 0x74, 0x6C, 0xB4, 0xBC, 0xFB
				DB 0xFD, 0xF3, 3, 0xFC, 0xF5, 0xEB, 0xED, 0x58, 0x3C
				DB 0x28, 0x24, 0x10, 0xE4
				
				DB 142, 12, 19                                 ; id=142
				DB 0x14, 3, 0x16, 0xD, 0xFF, 0x39, 0x23, 0x63, 0x48, 0x2B
				
				DB 143, 5, 6                                   ; id=143
				DB 0, 3, 0xC
				
				DB 147, 20, 12                                 ; id=147
				DB 0, 2, 0xE, 0xFF, 7, 0x1A, 0x1B, 0x1C, 0x1D, 0x5A, 0x9A
				DB 0x5D, 0x9D, 0x21, 0xDA, 0xDD, 0xA0, 0x5B
				
				DB 151, 16, 12                                 ; id=151
				DB 0, 2, 0xE, 0xFF, 3, 0x1A, 0x1B, 0x1C, 0x1D, 0x23, 0x5A
				DB 0x5B, 0x5C, 0x5D
				
				DB 152, 26, 11                                 ; id=152
				DB 0, 2, 0xE, 0xFF, 1, 0x33, 0xC, 0xA9, 0x6B, 0x54, 0x2F
				DB 0x22, 0x23, 0x24, 0x25, 0x1A, 0x1B, 0x1C, 0x1D, 0xB3
				DB 0xA3, 0xA4, 0x9B, 0x9C
				
				DB 155, 23, 11                                 ; id=155
				DB 0, 0x15, 0x17, 0xE, 0xFF, 7, 0x3D, 0x7D, 0x35, 0x75
				DB 0xB5, 0xF5, 0xC3, 0xC4, 0x78, 0xDD, 0x70, 0xDB, 0x29
				DB 0x1C, 0x1D
				
				DB 159, 24, 13                                 ; id=159
				DB 0, 2, 0xE, 0xFF, 7, 0x1A, 0x1B, 0x1C, 0x1D, 0x5A, 0x5B
				DB 0x5C, 0x5D, 3, 0x9A, 0x9B, 0x9C, 0x9D, 0x2A, 0xDB
				DB 0xDC, 0xDD
				
				DB 163, 28, 11                                 ; id=163
				DB 0, 0x15, 0x17, 0xE, 0xFF, 5, 0x3D, 0x7D, 0x34, 0x74
				DB 0xC3, 0xC4, 0x2B, 0x12, 0x14, 0x23, 0x25, 0x93, 0x52
				DB 0x54, 0x63, 0x65, 0xB8, 0x35, 0x80, 0x75
				
				DB 167, 5, 3                                   ; id=167
				DB 0, 2, 0xC
				
				DB 168, 24, 6                                  ; id=168
				DB 2, 0xC, 0xFF, 7, 0x2A, 0x6A, 0x32, 0x72, 0xB2, 0xF2
				DB 0x36, 0x76, 5, 0xB6, 0xF6, 0x16, 0x56, 0x96, 0xD6
				DB 0x29, 0x35, 0x1E
				
				DB 170, 24, 3                                  ; id=170
				DB 0, 1, 0xC, 0xFF, 7, 0, 0x48, 0x90, 0x18, 0x58, 0x98
				DB 0xD8, 0x21, 2, 0x61, 0x28, 0x68, 0x29, 0xA8, 0xA1
				DB 0xA8, 0xE0
				
				DB 171, 6, 4                                   ; id=171
				DB 0, 2, 3, 0xC
				
				DB 175, 14, 12                                 ; id=175
				DB 0, 0x15, 0x17, 0xE, 0xFF, 3, 0x1B, 0x1C, 0x33, 0x34
				DB 0x30, 0x74
				
				DB 179, 6, 6                                   ; id=179
				DB 0, 1, 2, 0xC
				
				DB 180, 19, 4                                  ; id=180
				DB 3, 0xC, 0xFF, 7, 0x13, 0x14, 0x15, 0x1B, 0x23, 0x63
				DB 0xA3, 0xE3, 0x30, 0x55, 0x39, 0x2E, 0x6E
				
				DB 183, 14, 12                                 ; id=183
				DB 0, 2, 0xE, 0xFF, 3, 0x33, 0x34, 0xB, 0xC, 0x49, 0x23
				DB 0x1C
				
				DB 186, 25, 5                                  ; id=186
				DB 1, 2, 0xC, 0xFF, 5, 0x2B, 0x6B, 0xAB, 0x1B, 0x5B, 0x9B
				DB 0x2F, 0x2A, 0x22, 0x62, 0xA2, 0x1A, 0x2C, 0x24, 0x64
				DB 0x29, 0xA4, 0x1C
				
				DB 187, 11, 6                                  ; id=187
				DB 2, 3, 0xC, 0xFF, 0x48, 0x24, 0x81, 0x64, 0xA4
				
				DB 191, 29, 3                                  ; id=191
				DB 0, 0x15, 0x17, 0xC, 0xFF, 4, 0x3D, 0x7E, 0xBE, 0xC3
				DB 0xC4, 0x2F, 0x3F, 0x37, 0x2F, 0x2E, 0x2D, 0x25, 0x1D
				DB 0x15, 0x29, 0x14, 0xC, 0xB8, 0x7F, 0x80, 0xBF
				
				DB 195, 20, 11                                 ; id=195
				DB 0, 2, 0xE, 0xFF, 7, 0x1A, 0x1B, 0x1C, 0x1D, 0x5A, 0x5B
				DB 0x5C, 0x5D, 3, 0x9A, 0x9B, 0x9C, 0x9D
				
				DB 199, 11, 5                                  ; id=199
				DB 0, 0x15, 0x17, 0xC, 0xFF, 0x80, 0x5B, 0x48, 0x1B
				
				DB 207, 10, 12                                 ; id=207
				DB 0, 2, 8, 0xA, 0xE, 0xFF, 0x48, 0x1C
				
				DB 208, 25, 5                                  ; id=208
				DB 0, 1, 0xC, 0xFF, 7, 3, 0x42, 0x81, 0xC0, 0xC8, 0xD0
				DB 0xD8, 0xE0, 3, 0x1C, 0x5C, 0x9C, 0xDC, 0x2B, 0x1B
				DB 0x24, 0x1D, 0x14
				
				DB 209, 17, 20                                 ; id=209
				DB 1, 3, 0xD, 0xFF, 0x68, 0x16, 0x2F, 0x1E, 0x26, 0x1B
				DB 0x1C, 0x23, 0x24, 0x19, 0x21
				
				DB 210, 21, 5                                  ; id=210
				DB 0, 3, 0xC, 0xFF, 7, 3, 0x27, 0x44, 0x5F, 0x85, 0x97
				DB 0xC6, 0xCF, 1, 0xCE, 0xC7, 0x99, 0xF, 6
				
				DB 211, 18, 13                                 ; id=211
				DB 0, 2, 0xE, 0xFF, 1, 0x2A, 0x2D, 0x2B, 0x6A, 0x6D, 0x1A
				DB 0x1D, 0xD0, 0x2B, 0x68, 0x25
				
				DB 214, 21, 6                                  ; id=214
				DB 4, 5, 0xF, 0x10, 0xFF, 0x1F, 0x2C, 0x6C, 0xAC, 0xEC
				DB 0x24, 0x1C, 0x14, 0x54, 0x18, 0x94, 0x11, 0x5D, 0x1B
				
				DB 215, 14, 3, 4                               ; id=215
				DB 5, 6, 7, 0xF, 0xFF, 0x51, 0x1B, 0x24, 0xA1, 0x23, 0x1C
				
				DB 216, 6, 3                                   ; id=216
				DB 4, 5, 7, 0xF
				
				DB 217, 5, 6                                   ; id=217
				DB 4, 7, 0xF, 0xDD, 0x14, 6, 0, 0x14, 0x16, 0xC, 0xFF
				DB 1, 0xE7, 0xDF, 0x5B, 0x2F, 0x26, 0x1E, 0x17, 0x3B
				DB 0x1A, 0x5A, 0x9A, 0xDA
				
				DB 222, 5, 19                                  ; id=222
				DB 1, 3, 0xD
				
				DB 223, 22, 6                                  ; id=223
				DB 0, 2, 3, 0xC, 0xFF, 4, 0x1B, 0x5B, 0x9B, 0xDB, 0xE2
				DB 0x2B, 0x13, 0x1C, 0x23, 0x1A, 0xB2, 0x12, 0x54, 0xA4
				
				DB 224, 17, 14                                 ; id=224
				DB 0, 2, 0xE, 0xFF, 0x2F, 0x3A, 0x3D, 0x2B, 0x2C, 0x13
				DB 0x14, 2, 5, 0xC8, 0x24
				
				DB 226, 22, 14                                 ; id=226
				DB 0, 2, 0xE, 0xFF, 0x97, 5, 0xA, 0xC, 0x13, 0x15, 0x1A
				DB 0x1C, 0x23, 0x95, 0x25, 0x2A, 0x2C, 0x33, 0x35, 0x3A
				
				DB 227, 27, 14                                 ; id=227
				DB 0, 2, 0xE, 0xFF, 0xAF, 2, 5, 0x4A, 0x4D, 0x92, 0x95
				DB 0xAA, 0xAD, 0xAB, 0x72, 0x75, 0x3A, 0x3D, 0xB3, 0xDA
				DB 0xDD, 0xE2, 0xE5, 0x60, 0x1B
				
				DB 230, 7, 3                                   ; id=230
				DB 4, 5, 6, 0xF, 0x10
				
				DB 231, 17, 6                                  ; id=231
				DB 4, 5, 6, 7, 0xF, 0xFF, 0x2F, 0x33, 0x34, 0x21, 0x19
				DB 0x26, 0x1E, 0xB, 0xC
				
				DB 232, 22, 6                                  ; id=232
				DB 4, 5, 6, 7, 0xF, 0xFF, 0x1F, 0x33, 0x21, 0x23, 0x63
				DB 0xA3, 0xE3, 0x25, 0x13, 0x2B, 0x2B, 0x24, 0x1B, 0x22
				
				DB 233, 6, 3                                   ; id=233
				DB 4, 6, 7, 0xF
				
				DB 237, 20, 12                                 ; id=237
				DB 0, 2, 0xE, 0xFF, 7, 0x1A, 0x1B, 0x1C, 0x1D, 0x5A, 0x5B
				DB 0x5C, 0x5D, 3, 0x9A, 0x9B, 0x9C, 0x9D
				
				DB 239, 5, 13                                  ; id=239
				DB 0, 2, 0xE
				
				DB 240, 27, 5                                  ; id=240
				DB 0x14, 0x15, 0x16, 0x17, 0xC, 0xFF, 7, 0xDF, 0xE7, 0xFF
				DB 0xFE, 0x78, 0xA8, 0xD0, 0xC0, 3, 0xC1, 0xC2, 0xC3
				DB 0xC4, 0x29, 0x39, 0x3B, 0x70, 0xFB
				
				DB 241, 10, 19                                 ; id=241
				DB 1, 3, 9, 0xB, 0xD, 0xFF, 0xB8, 0x23
				
				DB 242, 6, 5                                   ; id=242
				DB 1, 2, 3, 0xC
				
				DB 243, 23, 3                                  ; id=243
				DB 2, 3, 0xC, 0xFF, 7, 0x32, 0x3A, 0x72, 0x7A, 0x34, 0x3C
				DB 0x74, 0x7C, 1, 0xB3, 0xBB, 0x48, 0x33, 0x31, 0x2B
				DB 0x6B
				
				DB 246, 19, 6                                  ; id=246
				DB 5, 6, 0xF, 0x10, 0x11, 0xFF, 0x1B, 0x1B, 0x5B, 0x9B
				DB 0xDB, 0xB0, 0x1C, 0x30, 0x12, 0x38, 0x34
				
				DB 247, 21, 3                                  ; id=247
				DB 5, 6, 7, 0xF, 0x11, 0xFF, 0x1F, 0x22, 0x23, 0x24, 0x1A
				DB 0x1C, 0x12, 0x13, 0x14, 0xB8, 0x1B, 0x30, 0x5B
				
				DB 248, 7, 3                                   ; id=248
				DB 5, 6, 7, 0xF, 0x11
				
				DB 249, 19, 6                                  ; id=249
				DB 6, 7, 0xF, 0x11, 0xFF, 0x9F, 0xFF, 0xFE, 0xF6, 0xF7
				DB 0xFD, 0xEF, 0xC3, 0xC4, 0x99, 0xD8, 0xE0
				
				DB 253, 17, 6                                  ; id=253
				DB 1, 2, 0xC, 0xFF, 7, 0x28, 0x29, 0x2A, 0x32, 0x3A, 0x70
				DB 0x71, 0x79, 0, 0xB8
				
				DB 254, 18, 19                                 ; id=254
				DB 1, 3, 0xD, 0xFF, 0x2B, 0x25, 0x1D, 0x22, 0x1A, 0x23
				DB 0x2B, 0x2C, 0x13, 0x14, 0x60, 0x5B
				
				DB 255, 11, 6                                  ; id=255
				DB 2, 3, 0xC, 0xFF, 0x2B, 0x2E, 0x35, 0x37, 0x3E

; Block Types
block_type_tbl: DW block                                       ; 0 block 07 block
				DW fire                                        ; 1 sprite b0 (fire) (unused)
				DW ball_ud_y                                   ; 2 sprite b2 (ball) [up/down]
				DW rock                                        ; 3 block 06 rock
				DW gargoyle                                    ; 4 block 16 gargoyle
				DW spike                                       ; 5 block 17 spike
				DW chest                                       ; 6 sprite 55 (chest)
				DW table                                       ; 7 sprite 54 (table)
				DW guard_ew                                    ; 8 sprite 96/90 (guard) [west/east]
				DW ghost                                       ; 9 sprite 52 (ghost)
				DW fire_ns                                     ; a sprite b5 (fire) [north/south]
				DW block_high                                  ; b block 07 block high
				DW ball_ud_xy                                  ; c sprite b2 (ball) [up/down]
				DW guard_square                                ; d sprite 1e/90 (Guard) [square circuit]
				DW block_ew                                    ; e block 36 [west/east]
				DW block_ns                                    ; f block 37 [north/south]
				DW moveable_block                              ; 10 block 3e
				DW spike_high                                  ; 11 block Spike - high!!!
				DW spike_ball_fall                             ; 12 sprite 3f (Spike Ball)
				DW spike_ball_high_fall                        ; 13 sprite 3f (Spike Ball) [falling]
				DW fire_ew                                     ; 14 sprite 56 Fire [west/east]
				DW dropping_block                              ; 15 Block 5b
				DW collapsing_block                            ; 16 block 8f [Collapse]
				DW ball_bounce                                 ; 17 sprite b6 (Ball)
				DW ball_ud                                     ; 18 sprite b2 (Ball)
				DW repel_spell                                 ; 19 sprite a4 (Spell) [repel player]
				DW gate_ud_1                                   ; 1a sprite 8 (Gate) [up/down]
				DW gate_ud_2                                   ; 1b sprite 8 (Gate) [up/down]
				DW ball_ud_x                                   ; 1c sprite b2 (Ball)

; Block type data
; +0 = sprite
; +1 = width (x)
; +2 = depth (y)
; +3 = height (z)
; +4 = flags (see code)
; +5 = offsets (see code)
block:					DB 7, 8, 8, 0xC, 0x10, 0, 0
block_high:				DB 7, 8, 8, 0xC, 0x10, 0x30, 0
block_ew:				DB 0x36, 8, 8, 0xC, 0x10, 0, 0
block_ns:				DB 0x37, 8, 8, 0xC, 0x10, 0, 0
moveable_block:			DB 0x3E, 8, 8, 0xC, 0x14, 0, 0
dropping_block:			DB 0x5B, 8, 8, 0xC, 0x10, 0, 0
collapsing_block:		DB 0x8F, 8, 8, 0xC, 0x10, 0, 0
fire: 					DB 0xB0, 6, 6, 0xC, 0x10, 0, 0
ball_ud_y:				DB 0xB2, 7, 7, 0xC, 0x10, 2, 0
ball_ud_xy:				DB 0xB2, 7, 7, 0xC, 0x10, 3, 0
ball_ud:				DB 0xB2, 7, 7, 0xC, 0x10, 0, 0
ball_ud_x:				DB 0xB2, 7, 7, 0xC, 0x10, 1, 0
ball_bounce:			DB 0xB6, 7, 7, 0xC, 0x10, 0, 0
rock:					DB 6, 8, 8, 0xC, 0x10, 0, 0
gargoyle:				DB 0x16, 6, 6, 0xC, 0x10, 0, 0
spike:        			DB 0x17, 6, 6, 0xC, 0x50, 0, 0
spike_high:				DB 0x17, 6, 6, 0xC, 0x50, 0x30, 0
spike_ball_fall:        DB 0x3F, 6, 6, 0xC, 0x10, 0, 0
spike_ball_high_fall:   DB 0x3F, 6, 6, 0xC, 0x10, 0x30, 0
chest:          		DB 0x55, 9, 6, 0xC, 0x14, 0, 0
table:          		DB 0x54, 6, 0xA, 0xC, 0x14, 0, 0
guard_ew:       		DB 0x96, 6, 6, 0x18, 0x10, 2, 0x90, 6, 6, 0, 0x12, 2, 0
guard_square:   		DB 0x1E, 6, 6, 0x18, 0x10, 0, 0x90, 6, 6, 0, 0x12, 0, 0
ghost:					DB 0x52, 6, 6, 0xC, 0x10, 0, 0
fire_ns:				DB 0xB5, 6, 6, 0xC, 0x10, 0, 0
fire_ew:				DB 0x56, 6, 6, 0xC, 0x10, 0, 0
repel_spell:			DB 0xA4, 5, 5, 0xC, 0x10, 0, 0
gate_ud_1:				DB 8, 0xC, 1, 0x20, 0x50, 1, 0
gate_ud_2:				DB 8, 1, 0xC, 0x20, 0x10, 2, 0

; Background Types Pointers
background_type_tbl:	DW arch_n                                  ; 0 Arch north
						DW arch_e                                      ; 1 arch east
						DW arch_s                                      ; 2 arch south
						DW arch_w                                      ; 3 arch west
						DW tree_arch_n                                 ; 4 Tree arch north
						DW tree_arch_e                                 ; 5 Tree arch east
						DW tree_arch_s                                 ; 6 Tree arch south
						DW tree_arch_w                                 ; 7 Tree arch west
						DW gate_n                                      ; 8 Gate
						DW gate_e                                      ; 9 Gate
						DW gate_s                                      ; A Gate
						DW gate_w                                      ; B Gate
						DW wall_size_1                                 ; C walls size 0
						DW wall_size_2                                 ; D walls size 1
						DW wall_size_3                                 ; E walls size 2
						DW tree_room_size_1                            ; F trees size 0
						DW tree_filler_w                               ; 10 trees size 1
						DW tree_filler_n                               ; 11 trees size 2
						DW wizard                                      ; 12 Wizard
						DW cauldron                                    ; 13 Pot
						DW high_arch_e                                 ; 14 High Arch east
						DW high_arch_s                                 ; 15 High Arch south
						DW high_arch_e_base                            ; 16 High Arch east base
						DW high_arch_s_base                            ; 17 High Arch south base

; Background Type Makeup
; +0 = sprite
; +1 = x
; +2 = y
; +3 = z
; +4 = width (x)
; +5 = depth (y)
; +6 = height (z)
; +7 = flags (see code)
arch_n:         DB 2, 0x8D, 0xC4, 0x80, 3, 5, 0x28, 0x50
				DB 3, 0x73, 0xC4, 0x80, 3, 5, 0x28, 0x50
				DB 0

arch_e:         DB 2, 0xC4, 0x73, 0x80, 5, 3, 0x28, 0x10
				DB 3, 0xC4, 0x8D, 0x80, 5, 3, 0x28, 0x10
				DB 0

high_arch_e:    DB 2, 0xC4, 0x73, 0xB0, 5, 3, 0x28, 0x10
				DB 3, 0xC4, 0x8D, 0xB0, 5, 3, 0x28, 0x10
				DB 0

arch_s:         DB 2, 0x8D, 0x3B, 0x80, 3, 5, 0x28, 0x50
				DB 3, 0x73, 0x3B, 0x80, 3, 5, 0x28, 0x50
				DB 0

high_arch_s:    DB 2, 0x8D, 0x3B, 0xB0, 3, 5, 0x28, 0x50
				DB 3, 0x73, 0x3B, 0xB0, 3, 5, 0x28, 0x50
				DB 0

arch_w:         DB 2, 0x3B, 0x73, 0x80, 5, 3, 0x28, 0x10
				DB 3, 0x3B, 0x8D, 0x80, 5, 3, 0x28, 0x10
				DB 0

tree_arch_n:    DB 4, 0x8D, 0xC4, 0x80, 3, 5, 0x28, 0x50
				DB 5, 0x73, 0xC4, 0x80, 3, 5, 0x28, 0x50
				DB 0

tree_arch_e:    DB 4, 0xC4, 0x73, 0x80, 5, 3, 0x28, 0x10
				DB 5, 0xC4, 0x8D, 0x80, 5, 3, 0x28, 0x10
				DB 0

tree_arch_s:    DB 4, 0x8D, 0x3B, 0x80, 3, 5, 0x28, 0x50
				DB 5, 0x73, 0x3B, 0x80, 3, 5, 0x28, 0x50
				DB 0

tree_arch_w:    DB 4, 0x3B, 0x73, 0x80, 5, 3, 0x28, 0x10
				DB 5, 0x3B, 0x8D, 0x80, 5, 3, 0x28, 0x10
				DB 0

gate_n:         DB 8, 0x80, 0xBE, 0xA0, 0xC, 1, 0x20, 0x50
				DB 0

gate_e:         DB 8, 0xBE, 0x80, 0xA0, 1, 0xC, 0x20, 0x10
				DB 0

gate_s:         DB 8, 0x80, 0x41, 0xA0, 0xC, 1, 0x20, 0x50
				DB 0

gate_w:         DB 8, 0x41, 0x80, 0xA0, 1, 0xC, 0x20, 0x10
				DB 0

wall_size_1:    DB 0xD, 0x3F, 0xB8, 0x80, 0, 8, 0x28, 0x10
				DB 0xE, 0x47, 0xC0, 0x80, 8, 0, 0x28, 0x10
				DB 0xF, 0x3F, 0x49, 0x80, 0, 8, 0x2C, 0x10
				DB 0xF, 0xB8, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0xF, 0x3F, 0x49, 0xAC, 0, 8, 0x2C, 0x10
				DB 0xF, 0xB8, 0xC0, 0xAC, 8, 0, 0x2C, 0x50
				DB 0xA, 0x5C, 0xC0, 0x80, 0x14, 0, 0x14, 0x50
				DB 0xB, 0x3F, 0x5C, 0x98, 0, 0xC, 0x14, 0x10
				DB 0xC, 0x3F, 0xA0, 0x98, 0, 0xC, 0xC, 0x10
				DB 0xB, 0xA4, 0xC0, 0x98, 0xC, 0, 0x14, 0x50
				DB 0xA, 0x3F, 0x6D, 0xB1, 0, 0x14, 0x14, 0x10
				DB 0xC, 0x60, 0xC0, 0xA0, 0xC, 0, 0xC, 0x50
				DB 0xA, 0x90, 0xC0, 0xB0, 0x14, 0, 0x14, 0x50
				DB 0

wall_size_2:    DB 0xD, 0x3F, 0x98, 0x80, 0, 8, 0x28, 0x10
				DB 0xE, 0x47, 0xA0, 0x80, 8, 0, 0x28, 0x10
				DB 0xF, 0x3F, 0x63, 0x80, 0, 8, 0x2C, 0x10
				DB 0xF, 0xB8, 0xA0, 0x80, 8, 0, 0x2C, 0x50
				DB 0xF, 0x3F, 0x63, 0xAC, 0, 8, 0x2C, 0x10
				DB 0xF, 0xB8, 0xA0, 0xAC, 8, 0, 0x2C, 0x50
				DB 0xD, 0x3F, 0x98, 0xA8, 0, 8, 0x28, 0x10
				DB 0xE, 0x47, 0xA0, 0xA8, 8, 0, 0x28, 0x10
				DB 0xF, 0xB8, 0xA0, 0xD0, 8, 0, 0x2C, 0x50
				DB 0xA, 0x80, 0xA0, 0x80, 0x14, 0, 0x14, 0x50
				DB 0xA, 0x3F, 0x7E, 0xB0, 0, 0x14, 0x14, 0x10
				DB 0xB, 0x60, 0xA0, 0x90, 0xC, 0, 0x14, 0x50
				DB 0xA, 0x60, 0xA0, 0xB8, 0x14, 0, 0x14, 0x50
				DB 0xC, 0xA0, 0xA0, 0xB0, 0xC, 0, 0xC, 0x50
				DB 0

wall_size_3:    DB 0xD, 0x5F, 0xB8, 0x80, 0, 8, 0x28, 0x10
				DB 0xE, 0x67, 0xC0, 0x80, 8, 0, 0x28, 0x10
				DB 0xF, 0x5F, 0x48, 0x80, 0, 8, 0x2C, 0x10
				DB 0xF, 0x9D, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0xD, 0x5F, 0xB8, 0xA8, 0, 8, 0x28, 0x10
				DB 0xE, 0x67, 0xC0, 0xA8, 8, 0, 0x28, 0x10
				DB 0xF, 0x5F, 0x48, 0xAC, 0, 8, 0x2C, 0x10
				DB 0xF, 0x9D, 0xC0, 0xAC, 8, 0, 0x2C, 0x50
				DB 0xF, 0x5F, 0x48, 0xD0, 0, 8, 0x2C, 0x10
				DB 0xA, 0x5F, 0x90, 0x80, 0, 0x14, 0x14, 0x10
				DB 0xA, 0x84, 0xC0, 0xB0, 0x14, 0, 0x14, 0x50
				DB 0xB, 0x5F, 0x60, 0x90, 0, 0xC, 0x14, 0x10
				DB 0xA, 0x5F, 0x68, 0xB8, 0, 0x14, 0x14, 0x10
				DB 0xC, 0x5F, 0xA0, 0xB0, 0, 0xC, 0xC, 0x10
				DB 0

tree_room_size_1:DB 0x80, 0x3F, 0x49, 0x80, 0, 8, 0x2C, 0x10
				DB 0x81, 0x3F, 0x58, 0x80, 0, 8, 0x2C, 0x10
				DB 0x82, 0x3F, 0x68, 0x80, 0, 8, 0x2C, 0x10
				DB 0x80, 0x3F, 0x98, 0x80, 0, 8, 0x2C, 0x10
				DB 0x81, 0x3F, 0xA8, 0x80, 0, 8, 0x2C, 0x10
				DB 0x82, 0x3F, 0xB8, 0x80, 0, 8, 0x2C, 0x10
				DB 0x80, 0x48, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x81, 0x58, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x82, 0x68, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x80, 0x98, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x81, 0xA8, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x82, 0xB8, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0
				
tree_filler_w:  DB 0x80, 0x3F, 0x78, 0x80, 0, 8, 0x2C, 0x10
				DB 0x81, 0x3F, 0x88, 0x80, 0, 8, 0x2C, 0x10
				DB 0
				
tree_filler_n:  DB 0x80, 0x78, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0x81, 0x88, 0xC0, 0x80, 8, 0, 0x2C, 0x50
				DB 0
				
wizard:         DB 0x9E, 0x98, 0x68, 0x80, 5, 5, 0x18, 0x10
				DB 0x90, 0xA0, 0x60, 0x80, 5, 5, 0, 0x12
				DB 0

cauldron:       DB 0x8D, 0x80, 0x80, 0x80, 0xA, 0xA, 0x18, 0x10
				DB 0x8E, 0x80, 0x88, 0x80, 0, 0, 0, 0x12
				DB 0

high_arch_e_base:DB 7, 0xC8, 0x78, 0xA4, 8, 8, 0xC, 0x10
				DB 7, 0xC8, 0x88, 0xA4, 8, 8, 0xC, 0x10
				DB 0

high_arch_s_base:DB 7, 0x78, 0x38, 0xA4, 8, 8, 0xC, 0x10
				DB 7, 0x88, 0x38, 0xA4, 8, 8, 0xC, 0x10
				DB 0
; Objects
; +0 object graphic no (dynamic $60-$67)
; +1 start X position (0x46-0xba)
; +2 start Y position (0x40-0x70 +/-0x0c)
; +3 start Z position (0x46-0xba)
; +4 start screen
; +5 current X
; +6 current Y
; +7 current Z
; +8 current screen
special_objs_tbl:DB 0, 0x88, 0x80, 0xA4, 0x6D, 0, 0, 0, 0
				DB 0, 0x80, 0x80, 0x8C, 0x27, 0, 0, 0, 0
				DB 0, 0x88, 0x78, 0xB0, 0xD0, 0, 0, 0, 0
				DB 0, 0x78, 0x88, 0x80, 0xA, 0, 0, 0, 0
				DB 0, 0x78, 0x88, 0x80, 0xBA, 0, 0, 0, 0
				DB 0, 0x88, 0x78, 0xB0, 0x42, 0, 0, 0, 0
				DB 0, 0x88, 0xB8, 0xBC, 0x8D, 0, 0, 0, 0
				DB 0, 0xA8, 0xA8, 0x80, 0xFF, 0, 0, 0, 0
				DB 0, 0x80, 0x80, 0x80, 0x87, 0, 0, 0, 0
				DB 0, 0x78, 0xB8, 0x80, 0xF3, 0, 0, 0, 0
				DB 0, 0xA8, 0x68, 0xB0, 0xA8, 0, 0, 0, 0
				DB 0, 0xB8, 0x48, 0xB0, 0xD2, 0, 0, 0, 0
				DB 0, 0x48, 0x48, 0x80, 0, 0, 0, 0, 0
				DB 0, 0x88, 0xB8, 0x80, 0x22, 0, 0, 0, 0
				DB 0, 0xB8, 0xB8, 0xB0, 0x7A, 0, 0, 0, 0
				DB 0, 0xB8, 0xB8, 0x80, 0xF9, 0, 0, 0, 0
				DB 0, 0x88, 0x98, 0xB0, 0xD6, 0, 0, 0, 0
				DB 0, 0x78, 0x88, 0xB0, 0xE8, 0, 0, 0, 0
				DB 0, 0x78, 0x78, 0xB0, 0xF6, 0, 0, 0, 0
				DB 0, 0x88, 0x78, 0x8C, 0xF, 0, 0, 0, 0
				DB 0, 0xB8, 0xB8, 0x80, 0x6F, 0, 0, 0, 0
				DB 0, 0x48, 0xB8, 0xA4, 0xFD, 0, 0, 0, 0
				DB 0, 0x78, 0x78, 0xB0, 8, 0, 0, 0, 0
				DB 0, 0x88, 0x88, 0xA4, 0xBB, 0, 0, 0, 0
				DB 0, 0x78, 0x78, 0xB0, 0xDF, 0, 0, 0, 0
				DB 0, 0x80, 0x80, 0x80, 0x5E, 0, 0, 0, 0
				DB 0, 0x78, 0x88, 0xB0, 0xB4, 0, 0, 0, 0
				DB 0, 0x78, 0x78, 0xB0, 4, 0, 0, 0, 0
				DB 0, 0x48, 0xB8, 0x80, 0x74, 0, 0, 0, 0
				DB 0, 0x80, 0x80, 0x80, 0x40, 0, 0, 0, 0
				DB 0, 0x68, 0x78, 0xB0, 0x38, 0, 0, 0, 0
				DB 0, 0x48, 0xB8, 0x98, 0xF0, 0, 0, 0, 0
special_objs_tbl_end:

; ---------------------------------------------------------------------------
; Frequency Table?
freq_tbl:       DB 0, 0, 0
				DB 0xF4, 0xA, 8
				DB 0x65, 0xA, 9
				DB 0xDE, 9, 9
				DB 0x5E, 9, 0xA
				DB 0xE7, 8, 0xA
				DB 0x75, 8, 0xB
				DB 0xA, 8, 0xC
				DB 0xA5, 7, 0xC
				DB 0x45, 7, 0xD
				DB 0xEB, 6, 0xE
				DB 0x96, 6, 0xF
				DB 0x46, 6, 0xF
				DB 0xFA, 5, 0x10
				DB 0xB3, 5, 0x11
				DB 0x6F, 5, 0x12
				DB 0x2F, 5, 0x13
				DB 0xF3, 4, 0x15
				DB 0xF3, 4, 0x16
				DB 0x85, 4, 0x17
				DB 0x52, 4, 0x19
				DB 0x23, 4, 0x1A
				DB 0xF6, 3, 0x1C
				DB 0xCB, 3, 0x1D
				DB 0xA3, 3, 0x1F
				DB 0x7D, 3, 0x21
				DB 0x59, 3, 0x23
				DB 0x38, 3, 0x25
				DB 0x18, 3, 0x27
				DB 0xFA, 2, 0x29
				DB 0xDD, 2, 0x2C
				DB 0xC2, 2, 0x2E
				DB 0xA9, 2, 0x31
				DB 0x91, 2, 0x34
				DB 0x7B, 2, 0x37
				DB 0x66, 2, 0x3A
				DB 0x51, 2, 0x3E
				DB 0x3F, 2, 0x41
				DB 0x2D, 2, 0x45
				DB 0x1C, 2, 0x49
				DB 0xC, 2, 0x4E
				DB 0xFD, 1, 0x52
				DB 0xEF, 1, 0x57
				DB 0xE2, 1, 0x5D
				DB 0xD5, 1, 0x62
				DB 0xC9, 1, 0x68
				DB 0xBD, 1, 0x6E
				DB 0xB3, 1, 0x75
				DB 0xA9, 1, 0x7B
				DB 0x9F, 1, 0x83
				DB 0x96, 1, 0x8B
				DB 0x8E, 1, 0x93
				DB 0x86, 1, 0x9C
				DB 0x7E, 1, 0xA5
				DB 0x77, 1, 0xAF
				DB 0x71, 1, 0xB9
				DB 0x6A, 1, 0xC4
				DB 0x64, 1, 0xD0
				DB 0x5F, 1, 0xDC
				DB 0x59, 1, 0xE9
				DB 0x54, 1, 0xF7

;
; Audio Tunes
;
start_game_tune:
				DB 0x59, 0x5C, 0x5B, 0x54, 0x19, 0x17, 0x14, 0x17, 0xD9
				DB 0xFF

game_over_tune: DB 0x2E, 0x17, 0x27, 0x17, 0x2E, 0x17, 0x27, 0x17, 0x2C
				DB 0x19, 0x27, 0x19, 0x2C, 0x19, 0x27, 0x19, 0x2A, 0x1B
				DB 0x27, 0x1B, 0x2A, 0x1B, 0x27, 0x1B, 0x2A, 0x1B, 0x27
				DB 0x1B, 0x2A, 0x1B, 0x27, 0x1B, 0xFF

game_complete_tune:
				DB 0x1B, 0x1D, 0x1E, 0x1B, 0x1D, 0x1E, 0x20, 0x1D, 0x1E
				DB 0x20, 0x22, 0x1E, 0x1D, 0x1E, 0x20, 0x1D, 0x1B, 0x1D
				DB 0x1E, 0x1B, 0x1A, 0x1B, 0x1D, 0x1A, 0x9B, 0xFF

menu_tune:      DB 0x1B, 0x27, 0x1B, 0x27, 0x1B, 0x2A, 0x2E, 0x1B, 0x27
				DB 0x1B, 0x27, 0x1B, 0x2A, 0x1B, 0x2E, 0x16, 0x25, 0x16
				DB 0x24, 0x16, 0x22, 0x16, 0x22, 0x16, 0x25, 0x16, 0x24
				DB 0x16, 0x22, 0x16, 0x22, 0x16, 0x22, 0x1B, 0x27, 0x1B
				DB 0x27, 0x1B, 0x2A, 0x2E, 0x1B, 0x27, 0x1B, 0x27, 0x1B
				DB 0x2A, 0x1B, 0x2E, 0x16, 0x25, 0x16, 0x24, 0x16, 0x22
				DB 0x16, 0x22, 0x16, 0x25, 0x16, 0x24, 0x16, 0x22, 0x16
				DB 0x22, 0x16, 0x22, 0x17, 0x2E, 0x17, 0x2E, 0x17, 0x2E
				DB 0x17, 0x2E, 0x19, 0x2E, 0x19, 0x2E, 0x19, 0x2E, 0x19
				DB 0x2E, 0x1B, 0x2E, 0x1B, 0x2E, 0x1B, 0x2E, 0x1B, 0x2E
				DB 0x1B, 0x2E, 0x1B, 0x2E, 0x1B, 0x2E, 0x1B, 0x2E, 0xFF


game_over:
				ld      a, (all_objs_in_cauldron)
				and     a
				jp      NZ, game_complete_msg

loc_BA29:
				call    clear_scrn_buffer
				call    clear_scrn
				ld      de, gameover_colours                   	; game over status screen
				exx
				ld      hl, gameover_xy                        	; game over status screen
				ld      de, a_GAME_OVER
				ld      b, 6
				call    display_text_list
				ld      hl, vidbuf+0xFEF                      	; video buffer address
				ld      de, days
				ld      b, 1                                   	; 1 BCD digit pair
				call    print_BCD_number
				call    calc_and_display_percent
				ld      a, (num_scrns_visited)
				rlca
				and     0xC0 ; '�'
				ld      c, a
				ld      a, (all_objs_in_cauldron)
				and     1
				or      c
				rlca
				rlca
				rlca
				and     0xE
				ld      l, a
				ld      h, 0
				ld      bc, rating_tbl
				add     hl, bc                                  ; ptr to rating text entry
				ld      e, (hl)
				inc     hl
				ld      d, (hl)                                 ; DE=addr of rating string
				ld      hl, 0x2758
				call    print_text_std_font
				ld      de, objects_put_in_cauldron
				ld      a, (de)
				sub     10                                     	; less than 10?
				jr      C, loc_BA79                             ; yes, skip
				or      0x10                                   	; convert to BCD
				ld      (de), a                                 ; store BCD

loc_BA79:                                                       ; video buffer address
				ld      hl, vidbuf+0x9F7
				ld      b, 1                                   ; 1 BCD digit pair
				call    print_BCD_number
				call    print_border
				call    update_screen

loc_BA87:
				xor     a
				call    read_port
				jr      NZ, loc_BA87                            ; wait for key release
				ld      de, game_over_tune
				call    play_audio_until_keypress
				ld      b, 8                                   ; how long to wait
				call    wait_for_key_press
;
; the stack has at least 1 return address on it
; but the main game loop re-init's the stack each iteration
;
				jp      start_menu
; END OF FUNCTION CHUNK FOR lose_life

; =============== S U B R O U T I N E =======================================


wait_for_key_press:
				ld      hl, 0

loc_BA9E:
				xor     a
				call    read_port
				ret     NZ
				dec     hl
				ld      a, h
				or      l
				jr      NZ, loc_BA9E                            ; loop B times
				djnz    loc_BA9E
				ret
; End of function wait_for_key_press

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR lose_life

game_complete_msg:
				call    clear_scrn_buffer
				call    clear_scrn
				ld      de, complete_colours
				exx
				ld      hl, complete_xy
				ld      de, the_potion_casts
				ld      b, 6
				xor     a
				ld      (suppress_border), a
				call    display_text_list
				ld      de, game_complete_tune
				call    play_audio
				ld      b, 8
				call    wait_for_key_press
				jp      loc_BA29
; END OF FUNCTION CHUNK FOR lose_life
; ---------------------------------------------------------------------------

; =============== S U B R O U T I N E =======================================


calc_and_display_percent:
				ld      e, 0                                   ; zero room count
				ld      bc, 0x820                              ; B=8 bits/byte
				ld      hl, scrn_visited

count_screens:
				push    bc
				ld      a, (hl)
				inc     hl

loc_BC1B:
				rrca
				jr      NC, loc_BC1F
				inc     e                                       ; room count

loc_BC1F:
				djnz    loc_BC1B
				pop     bc
				dec     c                                       ; done all screens?
				jr      NZ, count_screens                       ; no, loop
				ld      a, e
				dec     a                                       ; -1? don't count 1st room?
				ld      (num_scrns_visited), a                  ; store for ratings calculations
				ld      a, (objects_put_in_cauldron)
				sla     a                                       ; x2
				add     a, e
				ld      e, a
				ld      bc, 0xA41A                             ; 0.64102 * (128 + 14*2) = 99.999%
				ld      hl, 0
				xor     a

loc_BC38:
				add     hl, bc
				adc     a, 0
				daa
				dec     e
				jr      NZ, loc_BC38                            ; calculate percentage complete (BCD)
				ld      bc, 0x28 ; '('                         ; $A410*156 = $63FFD8+$28 = $640000
				add     hl, bc
				adc     a, 0
				daa                                             ; fix rounding to 100%
				ld      (percent_lsw), a                        ; store least significant 2 BCD digits
				ld      a, 0
				adc     a, 0
				daa
				ld      (percent_msw), a                        ; store most significant BCD digit
				ld      hl, vidbuf+0xBF3
				ld      de, percent_msw
				ld      b, 1                                   ; 1 pair = 2 digits
				ld      a, (de)
				and     a                                       ; 100%?
				jr      Z, loc_BC61                             ; no, skip
				inc     b                                       ; 2 pair = 4 digits
				jp      print_BCD_lsd
; ---------------------------------------------------------------------------

loc_BC61:
				inc     hl
				inc     de                                      ; skip over leading zero
				jp      print_BCD_number
; End of function calc_and_display_percent



; Build a list of special objects in this room
; - traverses special object list
; - adds to special_objs_here
;
; IX=graphics object table
;    00=player sprite

; =============== S U B R O U T I N E =======================================


find_special_objs_here:
				ld      de, special_objs_here
				exx
				ld      iy, special_objs_tbl
				ld      b, (ix+8)                                ; current screen

loc_C530:                                                       ; get graphic no.
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, loc_C572                             ; yes, skip
				ld      a, (iy+8)                                ; object current screen
				cp      b                                       ; same as (player) current screen?
				jr      NZ, loc_C572                            ; no, skip
				push    iy
				exx
				pop     hl
				push    hl                                      ; ptr special_object_tbl entry
				ld      a, (hl)                                 ; get graphic no.
				inc     hl
				ld      (de), a                                 ; store in objs_here
				inc     de
				inc     hl
				inc     hl
				inc     hl
				inc     hl                                      ; ptr current X, Y, Z
				ld      bc, 3                                  ; 3 entries (bytes) to copy
				ldir                                            ; copy to objs_here
				ex      de, hl
				ld      (hl), 5                                ; width = 5
				inc     hl
				ld      (hl), 5                                ; depth = 5
				inc     hl
				ld      (hl), 12                               ; height = 12
				inc     hl
				ld      (hl), 0x14                             ; flag DRAW & MOVEABLE
				inc     hl
				ex      de, hl
				ld      a, (hl)                                 ; get current screen
				inc     hl
				ld      (de), a                                 ; store in objs_here
				inc     de
				ld      b, 7
				call    zero_DE
				pop     bc                                      ; ptr special_object_tbl entry
				ld      a, c
				ld      (de), a
				inc     de
				ld      a, b
				ld      (de), a                                 ; store
				inc     de
				ld      b, 14
				call    zero_DE
				exx

loc_C572:
				ld      de, 9
				add     iy, de                                  ; ptr next special_object_tbl entry
				push    iy
				pop     hl
				ld      de, special_objs_tbl_end                ; end of object table
				and     a
				sbc     hl, de                                  ; past end of table?
				jr      C, loc_C530                             ; no, loop
				exx                                             ; DE=objs_here entry

loc_C583:                                                       ; end of objects here table
				ld      hl, other_objs_here
				and     a
				sbc     hl, de                                  ; past end of table (max=2)
				ret     Z                                       ; yes, exit
				ld      b, 32
				call    zero_DE                                 ; zero next entry
				jr      loc_C583                                ; next entry
; End of function find_special_objs_here

; updates special objects table with current data (coords etc)
; - traverses special_objs_here table
; - writes to special_objs_tbl
;
; Another bug related to ptr special_objs_tbl
; - the cauldron bubbles are inserted in the object table
;   dynamically when you enter the room. This routine checks
;   the graphic_no for null, but (again) not the ptr
;   and (again) writes to ROM @$0000
; * VERIFIED on the ZX Spectrum emulator!
;

; =============== S U B R O U T I N E =======================================


update_special_objs:
				ld      iy, special_objs_here

loc_C595:                                                       ; get graphic no.
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, loc_C5B7                             ; yes, skip
				ld      e, (iy+16)
				ld      d, (iy+17)                               ; DE=ptr object table entry
				ld      a, (iy+0)                                ; get graphic no.
				ld      (de), a                                 ; store
				inc     de
				inc     de
				inc     de
				inc     de
				inc     de
				push    iy
				pop     hl                                      ; HL=object in 'here' table
				inc     hl                                      ; ptr x
				ld      bc, 3                                  ; 3 bytes
				ldir                                            ; copy x, y, z
				ld      a, (iy+8)                                ; screen
				ld      (de), a                                 ; store as current

loc_C5B7:
				ld      bc, 32
				add     iy, bc                                  ; next entry in 'here' table
				push    iy
				pop     hl
				ld      bc, other_objs_here                    ; end of table
				and     a
				sbc     hl, bc                                  ; past end of table?
				jr      C, loc_C595                             ; no, loop
				ret
; End of function update_special_objs




init_start_location:
				ld      hl, plyr_spr_init_data
				ld      de, plyr_spr_1_scratchpad
				ld      bc, 8
				ldir
				ld      de, plyr_spr_2_scratchpad
				ld      bc, 8
				ldir
				ld      a, 18                                  ; graphic_no (player top half)
				ld      (byte_D171), a                          ; plyr_spr_1_scratchpad (byte 16)
				ld      a, 34                                  ; graphic_no (player bottom half)
				ld      (byte_D191), a                          ; plyr_spr_2_scratchpad (byte 16)
				ld      a, (seed_1)
				and     3                                      ; random 0-3
				ld      l, a
				ld      h, 0
				ld      bc, start_locations
				add     hl, bc                                  ; offset to random entry
				ld      a, (hl)                                 ; start location
				ld      (start_loc_1), a
				ld      (start_loc_2), a
				ret
; End of function init_start_location

; ---------------------------------------------------------------------------
start_locations:
				DB 		0x2F, 0x44, 0xB3, 0x8F

; =============== S U B R O U T I N E =======================================


build_screen_objects:
				ld      a, (not_1st_screen)
				and     a                                       ; 1st screen of the game?
				jr      Z, loc_D1EF                             ; yes, skip updating special objects
				call    update_special_objs                     ; save state in special_objs_tbl

loc_D1EF:
				call    clear_scrn_buffer
				call    retrieve_screen
				call    find_special_objs_here                  ; find special objects in new room
				call    adjust_plyr_xyz_for_room_size
				xor     a                                       ; flag not moving
				ld      (portcullis_moving), a
				ld      (portcullis_move_cnt), a
				ld      (ball_bounce_height), a
				ld      (is_spike_ball_dropping), a
				ld      a, 1                                   ; flag rendering of status information
				ld      (render_status_info), a
				ld      a, (graphic_objs_tbl+8)                 ; plyr_spr_1 screen
				and     1
				ld      (disable_spike_ball_drop), a
				call    flag_room_visited
				ret
; End of function build_screen_objects

; ---------------------------------------------------------------------------

flag_room_visited:                                              ; plyr_spr_1_screen
				ld      a, (graphic_objs_tbl+8)
				ld      c, a
				rrca
				rrca
				rrca
				and     0x1F                                   ; /8 (byte offset)
				ld      l, a
				ld      h, 0
				ld      a, c
				rlca
				rlca
				rlca
				and     0x38 ; '8'
				or      0xC6 ; '�'                             ; SET 0,(HL)
				ld      (byte_D235), a                          ; self-modifying code
				ld      bc, scrn_visited
				add     hl, bc                                  ; offset to room flag
; ---------------------------------------------------------------------------
				DB 0xCB ; �                                    ; SET n,(HL)
byte_D235:      DB 0xC6                                        ; flag as visited?
; ---------------------------------------------------------------------------
				ret


; =============== S U B R O U T I N E =======================================

print_border:
				ld      ix, sprite_scratchpad
				ld      hl, border_data
				call    transfer_sprite_and_print
				call    transfer_sprite_and_print
				call    transfer_sprite_and_print
				call    transfer_sprite_and_print
				call    transfer_sprite
				ld      de, 8                                  ; X+=8, Y+=0
				ld      b, 24                                  ; 24 times
				call    multiple_print_sprite
				call    transfer_sprite
				ld      b, 24                                  ; 24 times
				call    multiple_print_sprite
				call    transfer_sprite
				ld      de, 0x100                              ; X+=0, Y+=1
				ld      b, 128                                 ; 128 times
				call    multiple_print_sprite
				call    transfer_sprite
				ld      b, 128                                 ; 128 times
				jp      multiple_print_sprite
; End of function print_border



display_menu:
				ld      de, menu_colours
				exx                                             ; select param set 2
				ld      hl, menu_xy
				ld      de, menu_text
				ld      b, 8                                   ; 8 lines to display
; End of function display_menu

; DE  = attributes
; HL' = coordinates
; DE' = text entries
;  B' = number to display

; =============== S U B R O U T I N E =======================================


display_text_list:
				exx                                             ; select param set 1
				ld      a, (de)                                 ; get attribute
				ld      (tmp_attrib), a                         ; store
				inc     de                                      ; next attribute
				exx                                             ; select param set 2
				push    bc                                      ; number to display
				ld      a, (hl)                                 ; get X
				inc     hl
				inc     hl
				push    hl
				dec     hl
				ld      h, (hl)                                 ; H = Y
				ld      l, a                                    ; L = X
				call    print_text_single_colour
				pop     hl
				pop     bc
				djnz    display_text_list                       ; loop through list of messages
				ld      a, (suppress_border)
				and     a                                       ; show border?
				ret     NZ                                      ; no, return
				inc     a
				ld      (suppress_border), a
				call    print_border
				jp      update_screen
; End of function display_text_list


do_menu_selection:
				xor     a
				ld      (suppress_border), a
				ld      hl, menu_colours
				ld      b, 8                                   ; # menu entries

loc_BD15:                                                       ; reset flashing attribute
				res     7, (hl)
				inc     hl                                      ; next menu colour entry
				djnz    loc_BD15                                ; loop until done
				call    clear_scrn_buffer
				call    display_menu
				call    flash_menu

menu_loop:
				call    display_menu
				ld      de, menu_tune
				call    play_audio_wait_key
				ld      a, 0xF7 ; '�'                          ; 1,2,3,4,5
				call    read_port
				ld      e, a                                    ; store keybd status
				ld      a, (user_input_method)
				ld      (old_input_method), a
				bit     0, e                                    ; '1' (keyboard)?
				jr      Z, check_for_kempston_joystick          ; no, skip
				and     0xF9 ; '�'                             ; mask off (bits 2,1)

check_for_kempston_joystick:                                    ; '2' (Kempston Joystick)?
				bit     1, e
				jr      Z, check_for_cursor_joystick            ; no, skip
				and     0xF9 ; '�'                             ; mask off (bits 2,1)
				or      2                                      ; set bit 1

check_for_cursor_joystick:                                      ; '3' (Cursor Joystick)?
				bit     2, e
				jr      Z, check_for_interface_ii               ; no, skip
				and     0xF9 ; '�'                             ; mask off (bits 2,1)
				or      4                                      ; set bit 2

check_for_interface_ii:                                         ; '4' (Interface II)?
				bit     3, e
				jr      Z, check_for_directional_control        ; no, skip
				or      6                                      ; set bits 1,2

check_for_directional_control:                                  ; store
				ld      (user_input_method), a
				ld      hl, debounce_5
				bit     4, e                                    ; '5' (directional control)?
				jr      Z, clr_debounce                         ; no, skip
				bit     0, (hl)                                 ; was pressed last time?
				jr      NZ, check_for_start_game                ; yes, skip
				set     0, (hl)                                 ; set debounce
				ld      a, (user_input_method)
				xor     8                                      ; toggle directional
				ld      (user_input_method), a

check_for_start_game:
				ld      hl, old_input_method
				cp      (hl)                                    ; changed input method?
				call    NZ, toggle_audio_hw_x16                 ; yes
				ld      a, 0xEF ; '�'                          ; 0,9,8,7,6
				call    read_port
				bit     0, a                                    ; '0' (Start Game)?
				ret     NZ                                      ; yes, exit
				ld      hl, seed_1
				inc     (hl)                                    ; remember when BASIC games did this?
				call    flash_menu
				jp      menu_loop
; ---------------------------------------------------------------------------

clr_debounce:
				res     0, (hl)
				jr      check_for_start_game                    ; continue
; End of function do_menu_selection


; =============== S U B R O U T I N E =======================================


flash_menu:
				ld      hl, menu_colours+1
				ld      a, (user_input_method)
				rrca
				and     3                                      ; keybd/joystick bits only
				ld      b, 4
				call    toggle_selected
				res     7, (hl)
				ld      a, (user_input_method)
				and     8                                      ; directional only
				ret     Z
				set     7, (hl)
				ret
; End of function flash_menu

; =============== S U B R O U T I N E =======================================


print_text_single_colour:
				push    hl                                      ; save Y,X
				ld      hl, font
				ld      (gfxbase_8x8), hl
				pop     bc                                      ; BC = Y,X
				push    bc
				call    vidbuf_calc_addr_in_hl
				ld      a, (tmp_attrib)
				ex      af, af'
				jr      loc_BE56
; End of function print_text_single_colour


; =============== S U B R O U T I N E =======================================


print_text_std_font:
				push    hl
				ld      hl, font
				ld      (gfxbase_8x8), hl

print_text:
				pop     bc
				push    bc
				call    vidbuf_calc_addr_in_hl
				ld      a, (de)                                 ; attribute
				ex      af, af'
				inc     de                                      ; ptr first character

loc_BE56:
				exx
				pop     hl                                      ; HL = Y,X
				push    de
				call    attrib_calc_addr_de
				ld      l, e
				ld      h, d                                    ; HL = attribute memory address
				pop     de

loc_BE5F:
				exx
				ld      a, (de)                                 ; next character
				bit     7, a                                    ; done?
				jr      NZ, loc_BE72                            ; yes, skip
				push    de
				call    print_8x8                               ; display a character
				pop     de
				inc     de
				exx
				ex      af, af'
				ld      (hl), a                                 ; store attribute
				inc     l                                       ; next attribute addrsess
				ex      af, af'
				jr      loc_BE5F                                ; loop until message done
; ---------------------------------------------------------------------------

loc_BE72:                                                       ; mask off end-of-message bit
				and     0x7F ; ''
				push    de
				call    print_8x8                               ; display a character
				pop     de
				inc     de
				exx
				ex      af, af'
				ld      (hl), a                                 ; store attribute
				exx
				ret
; End of function print_text_std_font

; =============== S U B R O U T I N E =======================================


cycle_colours_with_sound:
				ld      d, 16                                  ; cycle 16 times

loc_C2A7:                                                       ; attribute memory
				ld      hl, 0x5800
				ld      bc, 0x300                              ; size

cycle_attribute_mem:
				ld      a, (hl)
				and     0xF8 ; '�'
				ld      e, a
				ld      a, (hl)
				inc     a
				and     7
				or      e
				ld      (hl), a
				inc     hl
				dec     bc
				ld      a, b
				or      c
				jr      NZ, cycle_attribute_mem
				call    audio_B403
				ld      bc, 0x2000

loc_C2C3:
				dec     bc
				ld      a, b
				or      c
				jr      NZ, loc_C2C3
				dec     d
				jr      NZ, loc_C2A7

no_update:
				ret
; End of function cycle_colours_with_sound


; =============== S U B R O U T I N E =======================================


prepare_final_animation:
				ld      a, 1
				ld      (all_objs_in_cauldron), a
				push    ix
				ld      ix, special_objs_here_1                ; special_objs_here[1]
				ld      de, 32                                 ; entry size
				ld      b, 11                                  ; wipe 11 objects in the room
																; (1 special, 7 bg, 3 fg)

loc_C2DC:
				push    bc
				push    de
				call    set_wipe_and_draw_flags
				pop     de
				pop     bc
				ld      (ix+0), 1                               ; set graphic no. = INVALID
				add     ix, de                                  ; next entry
				djnz    loc_C2DC
				ld      bc, font

loc_C2EE:                                                       ; graphic no.
				ld      a, (ix+0)
				cp      7                                      ; block?
				jr      NZ, loc_C2F9                            ; no, skip
				ld      (ix+0), 131                             ; set to twinkly sprite

loc_C2F9:                                                       ; next entry
				add     ix, de
				push    ix
				pop     hl
				and     a
				sbc     hl, bc                                  ; end of table?
				jr      C, loc_C2EE                             ; no, loop
				pop     ix
				ret
; End of function prepare_final_animation



; Ideally from this point onwards shouldn't be in contended memory  (< 0x8000)

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR lose_life

start_menu:                                                     ; location to clear
				ld      hl, objs_wiped_cnt
				ld      bc, clear_end - objs_wiped_cnt          ; # bytes to clear
				call    clr_mem

main:                                                           ; for bit reversal & shifting
				call    build_lookup_tbls
				xor     a
				ld      (not_1st_screen), a
				ld      (flags12_1), a                          ; plyr_spr_1_scratchpad
				ld      a, 5                                   ; 5 lives to start
				ld      (lives), a
				ld      hl, seed_1
				ld      a, (seed_2)
				add     a, (hl)                                 ; seed_1 += seed_2
				ld      (hl), a                                 ; update seed
				call    clear_scrn                              ; colour is bright yellow on black
				call    do_menu_selection
				ld      de, start_game_tune
				call    play_audio                              ; play tune
				call    shuffle_objects_required                ; randomise order of required objects
				call    init_start_location                     ; randomise player start location
				call    init_sun
				call    init_special_objects                    ; randomise special object locations

player_dies:
				call    lose_life

game_loop:
				call    build_screen_objects

onscreen_loop:
				ld      a, (seed_2)
				ld      (fire_seed), a
				ld      ix, graphic_objs_tbl                   ; start of table

update_sprite_loop:                                             ; init stack
				ld      sp, seed_1
				ld      hl, fire_seed
				inc     (hl)
				ld      hl, ret_from_tbl_jp
				push    hl                                      ; set return address
				call    save_2d_info

jump_to_upd_object:                                             ; sprite graphic to render
				ld      l, (ix+0)
				ld      bc, upd_sprite_jmp_tbl

jump_to_tbl_entry:
				ld      h, 0
				add     hl, hl                                  ; word offset
				add     hl, bc                                  ; get ptr jump entry
				ld      a, (hl)
				inc     hl
				ld      h, (hl)
				ld      l, a                                    ; HL=jump address
				jp      (hl)                                    ; go
; END OF FUNCTION CHUNK FOR lose_life
; ---------------------------------------------------------------------------

ret_from_tbl_jp:
				ld      a, r
				ld      c, a
				ld      a, (seed_3)
				add     a, c
				ld      (seed_3), a                             ; update seed 3
				ld      bc, 32
				add     ix, bc                                  ; next sprite to render
				push    ix
				pop     hl
				ld      bc, font                               ; end of table
				and     a
				sbc     hl, bc                                  ; past end of table?
				jr      NC, loc_B000                            ; yes, exit
				jr      update_sprite_loop                      ; loop
; ---------------------------------------------------------------------------

loc_B000:
				ld      hl, (seed_2)
				inc     hl
				ld      (seed_2), hl
				ld      a, (seed_3)
				add     a, (hl)
				add     a, l
				add     a, h
				ld      (seed_3), a
				ld      hl, not_1st_screen
				set     0, (hl)                                 ; update special objects table next time
				call    handle_pause
				call    init_cauldron_bubbles
				call    list_objects_to_draw                    ; builds a list of screen objects
				call    render_dynamic_objects                  ; renders above list
				ld      a, (rising_blocks_z)
				and     a                                       ; any blocks rising?
				call    NZ, audio_B454                          ; yes, play audio
				ld      a, (rendered_objs_cnt)
				neg
				add     a, 6                                   ; calculate delay loop value
				ld      b, a
				jp      M, no_delay
				jr      Z, no_delay

game_delay:
				ld      hl, 0x500
delay_loop:
				dec     hl
				ld      a, l
				or      h
				jr      NZ, delay_loop
				djnz    game_delay

no_delay:
				ld      a, (render_status_info)
				and     a                                       ; rendered before?
				jr      Z, loc_B074                             ; yes, skip
				xor     a                                       ; reset flag
				ld      (render_status_info), a
				ld      a, (curr_room_attrib)                   ; attribute
				call    fill_attr                               ; set screen colour
				call    display_objects                         ; inventory
				call    colour_panel
				call    colour_sun_moon
				call    display_panel
				ld      ix, sun_moon_scratchpad
				call    display_sun_moon_frame
				call    display_day
				call    print_days
				call    print_lives_gfx
				call    print_lives
				call    update_screen                           ; copy to display
				call    reset_objs_wipe_flag

loc_B074:
				xor     a
				ld      (rising_blocks_z), a                    ; clear
				ld      ix, graphic_objs_tbl
				ld      a, (ix+0)                                ; player sprite half
				or      (ix+0x20)                                ; player other sprite half
				jp      Z, player_dies                          ; both null? yes, lose a life
				jp      onscreen_loop

; =============== S U B R O U T I N E =======================================


reset_objs_wipe_flag:
				ld      b, 40                                  ; max objects in draw table
				ld      de, 32                                 ; object size
				ld      hl, graphic_objs_tbl+7                ; offset to flags

loc_B090:                                                       ; reset flag=???
				res     5, (hl)
				add     hl, de                                  ; next entry
				djnz    loc_B090                                ; loop until done
				ret
; End of function reset_objs_wipe_flag

; ---------------------------------------------------------------------------
upd_sprite_jmp_tbl:DW no_update
				DW no_update                                   ; (unused)
				DW upd_2_4                                     ; stone arch (near side)
				DW upd_3_5                                     ; stone arch (far side)
				DW upd_2_4                                     ; tree arch (near side)
				DW upd_3_5                                     ; tree arch (far side)
				DW upd_6_7                                     ; rock
				DW upd_6_7                                     ; block
				DW upd_8                                       ; portcullis (stationary)
				DW upd_9                                       ; portcullis (moving)
				DW upd_10                                      ; bricks
				DW upd_11                                      ; more bricks
				DW upd_12_to_15                                ; even more bricks
				DW upd_12_to_15                                ;   "
				DW upd_12_to_15                                ;   "
				DW upd_12_to_15                                ;   "
				DW upd_16_to_21_24_to_29                       ; human legs
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_22                                      ; gargoyle
				DW upd_23                                      ; spikes
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_16_to_21_24_to_29
				DW upd_30_31_158_159                           ; guard (moving NSEW) (top half)
				DW upd_30_31_158_159                           ;   "
				DW upd_32_to_47                                ; player (top half)
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_32_to_47
				DW upd_48_to_53_56_to_61                       ;   wulf legs
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_54                                      ; block (moving EW)
				DW upd_55                                      ; block (moving NS)
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_48_to_53_56_to_61
				DW upd_62                                      ; another block
				DW upd_63                                      ; spiked ball
				DW upd_64_to_79                                ; player (wulf top half)
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_64_to_79
				DW upd_80_to_83                                ; ghost
				DW upd_80_to_83                                ;   "
				DW upd_80_to_83                                ;   "
				DW upd_80_to_83                                ;   "
				DW upd_84                                      ; table
				DW upd_85                                      ; chest
				DW upd_86_87                                   ; fire (EW)
				DW upd_86_87                                   ; fire (EW)
				DW upd_88_to_90                                ; sun
				DW upd_88_to_90                                ; moon
				DW upd_88_to_90                                ; frame (left)
				DW upd_91                                      ; block (dropping)
				DW upd_92_to_95                                ; human/wulf transform
				DW upd_92_to_95
				DW upd_92_to_95
				DW upd_92_to_95
				DW upd_96_to_102                               ; diamond
				DW upd_96_to_102                               ; poison
				DW upd_96_to_102                               ; boot
				DW upd_96_to_102                               ; chalice
				DW upd_96_to_102                               ; cup
				DW upd_96_to_102                               ; bottle
				DW upd_96_to_102                               ; crystal ball
				DW upd_103                                     ; extra life
				DW upd_104_to_110                              ; special object (diamond)
				DW upd_104_to_110                              ;   " (poison)
				DW upd_104_to_110                              ;   " (boot)
				DW upd_104_to_110                              ;   " (chalice)
				DW upd_104_to_110                              ;   " (cup)
				DW upd_104_to_110                              ;   " (bottle)
				DW upd_104_to_110                              ;   " (crytsal ball)
				DW upd_111                                     ; final sparkles in cauldron
				DW upd_112_to_118_184                          ; death sparkles
				DW upd_112_to_118_184                          ;   "
				DW upd_112_to_118_184                          ;   "
				DW upd_112_to_118_184                          ;   "
				DW upd_112_to_118_184                          ;   "
				DW upd_112_to_118_184                          ;   "
				DW upd_112_to_118_184                          ;   "
				DW upd_119                                     ; last death sparkle
				DW upd_120_to_126                              ; player appears sparkles
				DW upd_120_to_126                              ;   "
				DW upd_120_to_126                              ;   "
				DW upd_120_to_126                              ;   "
				DW upd_120_to_126                              ;   "
				DW upd_120_to_126                              ;   "
				DW upd_120_to_126                              ;   "
				DW upd_127                                     ; last player appears sparkle
				DW upd_128_to_130                              ; tree wall
				DW upd_128_to_130                              ;   "
				DW upd_128_to_130                              ;   "
				DW upd_131_to_133                              ; sparkles in the cauldron room at end of game
				DW upd_131_to_133                              ;   "
				DW upd_131_to_133                              ;   "
				DW no_update
				DW no_update
				DW no_update
				DW no_update
				DW no_update
				DW no_update
				DW no_update
				DW upd_141                                     ; cauldron (bottom)
				DW upd_142                                     ; cauldron (top)
				DW upd_143                                     ; block (collapsing)
				DW upd_144_to_149_152_to_157                   ; guard & wizard (bottom half)
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_150_151                                 ; guard (EW) (top half)
				DW upd_150_151                                 ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_144_to_149_152_to_157                   ;   "
				DW upd_30_31_158_159                           ; wizard (top half)
				DW upd_30_31_158_159                           ;   "
				DW upd_160_to_163                              ; cauldron bubbles
				DW upd_160_to_163                              ;   "
				DW upd_160_to_163                              ;   "
				DW upd_160_to_163                              ;   "
				DW upd_164_to_167                              ; repel spell
				DW upd_164_to_167                              ;   "
				DW upd_164_to_167                              ;   "
				DW upd_164_to_167                              ;   "
				DW upd_168_to_175                              ; diamond
				DW upd_168_to_175                              ; poison
				DW upd_168_to_175                              ; boot
				DW upd_168_to_175                              ; chalice
				DW upd_168_to_175                              ; cup
				DW upd_168_to_175                              ; bottle
				DW upd_168_to_175                              ; crystal ball
				DW upd_168_to_175                              ; extra life
				DW upd_176_177                                 ; fire (stationary) (not used)
				DW upd_176_177                                 ; fire (stationary) (not used)
				DW upd_178_179                                 ; ball up/down
				DW upd_178_179                                 ; ball up/down
				DW upd_180_181                                 ; fire (NS)
				DW upd_180_181                                 ; fire (NS)
				DW upd_182_183                                 ; ball (bouncing around)
				DW upd_182_183                                 ;   "
				DW upd_112_to_118_184                          ; death sparkles
				DW upd_185_187                                 ; last obj in cauldron sparkle
				DW no_update
				DW upd_185_187                                 ; last obj in cauldron sparkle

; =============== S U B R O U T I N E =======================================


play_audio_wait_key:
				ld      hl, audio_played
				ld      a, (hl)
				and     a
				ret     NZ
				set     0, (hl)
; End of function play_audio_wait_key


; =============== S U B R O U T I N E =======================================


play_audio_until_keypress:
				xor     a
				call    read_port
				jr      Z, loc_B2C5
				ret
; ---------------------------------------------------------------------------

loc_B2C5:                                                       ; audio data
				ld      a, (de)
				cp      0xFF                                   ; done?
				jr      Z, end_audio                            ; yes, exit
				call    play_note
				jr      play_audio_until_keypress
; End of function play_audio_until_keypress


; =============== S U B R O U T I N E =======================================


play_audio:
				ld      a, (de)                                 ; audio data byte
				cp      0xFF                                   ; done?
				jr      Z, end_audio                            ; yes, return
				call    play_note
				jr      play_audio
; ---------------------------------------------------------------------------

end_audio:
				ret
; End of function play_audio


; =============== S U B R O U T I N E =======================================


play_note:
				and     0x3F ; '?'                             ; note
				jr      Z, snd_delay
				ld      l, a
				ld      h, 0
				add     hl, hl                                  ; HL=2A
				call    add_HL_A                                ; HL=3A
				ld      bc, freq_tbl                           ; frequency table
				add     hl, bc                                  ; ptr to entry
				ld      b, (hl)                                 ; loop cnt LSB
				inc     hl
				ld      c, (hl)                                 ; loop cnt MSB
				inc     hl
				ld      l, (hl)                                 ; duration LSB
				ld      h, 0
				ld      a, (de)                                 ; note & duration MSB
				rlca
				rlca
				and     3
				inc     a                                       ; duration MSB
				push    de
				ld      e, l
				ld      d, h                                    ; HL,DE=duration LSB

calc_duration:
				dec     a
				jr      Z, loc_B2FF
				add     hl, de
				jr      calc_duration                           ; calc 16-bit duration (HL)
; ---------------------------------------------------------------------------

loc_B2FF:
				pop     de

loc_B300:
				push    bc
				xor     a
				out     (0xFE), a

loc_B304:
				djnz    loc_B304
				dec     c
				jr      NZ, loc_B304
				pop     bc
				push    bc
				ld      a, 0x10
				out     (0xFE), a

loc_B30F:
				djnz    loc_B30F
				dec     c
				jr      NZ, loc_B30F
				pop     bc
				dec     hl
				ld      a, h
				or      l
				jr      NZ, loc_B300
				inc     de
				ret
; ---------------------------------------------------------------------------

snd_delay:
				ld      a, (de)
				inc     de
				rlca
				rlca
				and     3
				inc     a
				ld      l, a
				ld      bc, 0x430B

loc_B327:
				push    bc

loc_B328:
				dec     bc
				ld      a, b
				or      c
				jr      NZ, loc_B328
				pop     bc
				dec     l
				jr      NZ, loc_B327
				ret
; End of function play_note

;
; block (62)

; =============== S U B R O U T I N E =======================================


audio_B3E9:
				ld      a, (seed_2)
				and     7
				ld      l, a
				ld      h, 0
				ld      bc, byte_B3FB                          ; ??? table
				add     hl, bc                                  ; ptr entry
				ld      b, (hl)
				ld      c, 4
				jp      toggle_audio_hw_xC
; End of function audio_B3E9

; ---------------------------------------------------------------------------
byte_B3FB:      DB 0xA0, 0xB0, 0xC0, 0x90, 0xA0, 0xE0, 0x80, 0x60
;
; eg. death sparkles

; =============== S U B R O U T I N E =======================================


audio_B403:
				ld      a, (ix+0)                                ; sprite index
				cpl
				and     0x1F
				ld      e, a
				ld      hl, 0x1234                             ; location in ROM

loc_B40D:
				ld      a, (hl)
				inc     hl
				ld      b, a
				ld      c, 2
				call    toggle_audio_hw_xC
				dec     e
				jr      NZ, loc_B40D
				ret
; End of function audio_B403

; eg. player appears sparkles

; =============== S U B R O U T I N E =======================================


audio_B419:
				ld      a, (ix+0)                                ; player sprite graphic no.
				rlca
				rlca
				and     0x1F
				or      3
				ld      c, a

loc_B423:                                                       ; bits 4:0 only
				ld      a, c
				rlca
				rlca                                            ; bits 6:2 only
				ld      b, a
				call    toggle_audio_hw
				dec     c
				jr      NZ, loc_B423
				ret
; End of function audio_B419

; ball bouncing around

; =============== S U B R O U T I N E =======================================


audio_B42E:
				ld      hl, 0
				ld      e, 4

loc_B433:
				ld      c, 3
				ld      a, (hl)
				inc     hl
				or      0xC0 ; '�'
				ld      b, a
				call    toggle_audio_hw_xC
				dec     e
				jr      NZ, loc_B433
				ret
; End of function audio_B42E

; jumping

; =============== S U B R O U T I N E =======================================


audio_B441:
				ld      c, 0x20 ; ' '

loc_B443:
				ld      a, c
				rrca
				rrca
				rrca
				rrca
				rrca
				ld      b, a
				call    toggle_audio_hw
				dec     c
				jr      NZ, loc_B443
				ret
; End of function audio_B441

; eg. dropping block, spiked ball drop, ball up/down

; =============== S U B R O U T I N E =======================================


audio_B451:
				ld      a, (ix+3)                                ; Z
; End of function audio_B451

; eg. rising blocks

; =============== S U B R O U T I N E =======================================


audio_B454:
				cpl
				rlca
				rlca
				ld      b, a
				ld      c, 6
				jp      toggle_audio_hw_xC
; End of function audio_B454

; block, fire movng (EW)

; =============== S U B R O U T I N E =======================================


audio_B45D:
				ld      a, (ix+1)                                ; X
				jr      audio_B454
; End of function audio_B45D

; fire, block moving (NS)

; =============== S U B R O U T I N E =======================================


audio_B462:
				ld      a, (ix+2)                                ; Y
				jr      audio_B454
; End of function audio_B462

; eg. special objects, ghost, portcullis (up)

; =============== S U B R O U T I N E =======================================


audio_B467:
				ld      a, (ix+1)
				add     a, (ix+2)
				add     a, (ix+3)
				jr      audio_B454
; End of function audio_B467

; human/wulf transform

; =============== S U B R O U T I N E =======================================


audio_B472:
				ld      a, (ix+0)
				rlca
				rlca
				rlca
				and     0x18
				add     a, 0x10
				ld      c, a

loc_B47D:
				ld      a, c
				xor     0x55 ; 'U'
				add     a, c
				ld      b, a
				call    toggle_audio_hw
				dec     c
				jr      NZ, loc_B47D
				ret
; End of function audio_B472

; portcullis

; =============== S U B R O U T I N E =======================================


audio_B489:
				ld      a, (seed_3)
				ld      l, a
				ld      a, (seed_2)
				and     0x1F
				ld      h, a
				ld      e, 0x10

loc_B495:
				ld      a, (hl)
				inc     hl
				and     0x7F ; ''
				ld      b, a
				ld      c, 2
				call    toggle_audio_hw_xC
				dec     e
				jr      NZ, loc_B495
				ret
; End of function audio_B489


; =============== S U B R O U T I N E =======================================


toggle_audio_hw_x16:
				ld      bc, 0x8010
				jr      toggle_audio_hw_xC
; ---------------------------------------------------------------------------

toggle_audio_hw_x24:
				ld      bc, 0x5018
				jr      toggle_audio_hw_xC
; ---------------------------------------------------------------------------

audio_guard_wizard:                                             ; graphic_no
				ld      a, (ix+0)
				and     1                                      ; even?
				ret     NZ                                      ; no, exit
				ld      b, 0x80 ; '�'
				ld      a, (seed_2)
				cpl
				jr      loc_B4C6
; ---------------------------------------------------------------------------
; eg. walking

audio_B4BB:                                                     ; graphic_no
				ld      a, (ix+0)
				and     1
				ret     NZ

audio_B4C1:
				ld      b, 0x60 ; '`'
				ld      a, (seed_2)

loc_B4C6:
				bit     1, a
				jr      Z, loc_B4D1
				ld      a, (ix+3)                                ; Z
				cpl
				srl     a
				ld      b, a

loc_B4D1:                                                       ; X
				ld      a, (ix+1)
				srl     a
				ld      c, a
				ld      a, (ix+2)                                ; Y
				neg
				srl     a
				add     a, c
				rrca
				rrca
				rrca
				rrca
				and     0xF
				ld      c, a

toggle_audio_hw_xC:
				call    toggle_audio_hw
				dec     c
				jr      NZ, toggle_audio_hw_xC
				ret
; End of function toggle_audio_hw_x16


; =============== S U B R O U T I N E =======================================


toggle_audio_hw:
				ld      a, 0x10                                ; EAR output
				out     (0xFE), a                               ; enable
				ld      a, b

loc_B4F2:
				djnz    loc_B4F2
				ld      b, a
				xor     a                                       ; MIC output
				out     (0xFE), a                               ; enable (disable EAR)
				ld      a, b

loc_B4F9:
				djnz    loc_B4F9
				ld      b, a
				ret
; End of function toggle_audio_hw

; returns C flag set if any other object
; intersects with this one

; =============== S U B R O U T I N E =======================================


do_any_objs_intersect:
				push    bc
				push    de
				push    hl
				push    iy
				ld      iy, graphic_objs_tbl
				ld      b, 40                                  ; max objects
				ld      c, 0                                   ; dX=0
				ld      l, c                                    ; dY=0
				ld      h, c                                    ; dZ=0
				set     1, (ix+7)                                ; ignore this object

loc_B510:
				call    is_object_not_ignored
				jr      Z, loc_B52E                             ; no, skip
				call    do_objs_intersect_on_x
				jr      NC, loc_B52E                            ; no, skip
				call    do_objs_intersect_on_y
				jr      NC, loc_B52E                            ; no, skip
				call    do_objs_intersect_on_z
				jr      NC, loc_B52E                            ; no, skip

loc_B524:
				pop     iy
				pop     hl
				pop     de
				pop     bc
				res     1, (ix+7)                                ; reset ignore flag
				ret                                             ; C flag set indicates intersection
; ---------------------------------------------------------------------------

loc_B52E:                                                       ; entry size
				ld      de, 32
				add     iy, de                                  ; next entry
				djnz    loc_B510                                ; loop through object table
				and     a
				jr      loc_B524
; End of function do_any_objs_intersect


; =============== S U B R O U T I N E =======================================


is_object_not_ignored:
				ld      a, (iy+0)                                ; graphic no.
				and     a                                       ; null?
				ret     Z                                       ; yes, exit
				ld      a, (iy+7)                                ; flags
				cpl
				and     2                                      ; test bit 1
				ret
; End of function is_object_not_ignored


; =============== S U B R O U T I N E =======================================


shuffle_objects_required:
				ld      a, (seed_1)
				and     3
				or      4
				ld      c, a                                    ; random 4-7

loc_B54C:                                                       ; 14 items (13 swaps)
				ld      b, 13
				ld      iy, objects_required
				ld      e, (iy+0)

loc_B555:
				ld      a, (iy+1)
				ld      (iy+0), a
				inc     iy
				djnz    loc_B555
				ld      (iy+0), e
				dec     c
				jr      NZ, loc_B54C
				ret
; End of function shuffle_objects_required

; ---------------------------------------------------------------------------
; sparkles from the blocks in the cauldron room
; at the end of the game

upd_131_to_133:
				call    adj_m4_m12
				ld      a, (ix+3)                                ; Z
				cp      164                                    ; <164?
				jr      NC, loc_B5C4                            ; no, go
				ld      (ix+11), 3                              ; dZ=3
				ld      a, (ix+1)                                ; X
				rlca
				and     1
				ld      l, a                                    ; X bit7->bit0
				ld      a, (ix+2)                                ; Y
				and     0x80 ; '�'                             ; Y bit7
				or      l
				rlca                                            ; bit0->bit1, bit7->bit1
				and     3
				ld      l, a
				ld      bc, dX_dY_tbl                          ; jump table
				jp      jump_to_tbl_entry
; ---------------------------------------------------------------------------
dX_dY_tbl:      DW 		p4_m4                                       ; +4, -4
				DW 		p4_p4                                       ; +4, +4
				DW 		m4_m4                                       ; -4, -4
				DW 		m4_p4                                       ; -4, +4
; ---------------------------------------------------------------------------

p4_m4:                                                          ; +4, -4
				ld      hl, 0x4FC

save_dX_dY:                                                     ; dX
				ld      (ix+9), l
				ld      (ix+10), h                               ; dY
				ld      a, (seed_3)
				and     3                                      ; rnd 0-3
				jr      NZ, loc_B5A4                            ; >0, skip
				inc     a                                       ; =1

loc_B5A4:                                                       ; rnd twinkly sprite
				add     a, 130
				ld      (ix+0), a                                ; set graphic no.

loc_B5A9:                                                       ; Z
				ld      a, (ix+3)
				ld      (rising_blocks_z), a

dec_dZ_wipe_and_draw:
				call    dec_dZ_and_update_XYZ
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

p4_p4:                                                          ; +4, +4
				ld      hl, 0x404
				jr      save_dX_dY
; ---------------------------------------------------------------------------

m4_m4:                                                          ; -4, -4
				ld      hl, 0xFCFC
				jr      save_dX_dY
; ---------------------------------------------------------------------------

m4_p4:                                                          ; -4, +4
				ld      hl, 0xFC04
				jr      save_dX_dY
; ---------------------------------------------------------------------------

loc_B5C4:                                                       ; plyr_spr_1 X
				ld      a, (graphic_objs_tbl+1)
				sub     (ix+1)                                  ; object X
				jp      P, loc_B5CF
				neg                                             ; abs(delta x)

loc_B5CF:                                                       ; less than 6?
				cp      6
				jr      NC, loc_B5E3                            ; no, skip
				ld      a, (graphic_objs_tbl+2)                 ; plyr_spr_1 Y
				sub     (ix+2)                                  ; object Y
				jp      P, loc_B5DE
				neg                                             ; abs(delta y)

loc_B5DE:                                                       ; less than 6?
				cp      6
				jp      C, game_over                            ; yes, exit

loc_B5E3:                                                       ; fatal if it hits player
				set     7, (ix+13)
				set     1, (ix+7)                               ; ignore object in 3D calculations
				ld      (ix+11), 1                              ; dZ=1
				ld      bc, 0x404                              	; dX,dY=4
				call    move_towards_plyr
				jr      loc_B5A9

; =============== S U B R O U T I N E =======================================


read_port:
				;out     (0xFD), a                               ; select upper address
				in      a, (0xFE)                               ; read status
				cpl                                             ; positive logic
				and     0x1F                                    ; mask off undefined bits
				ret
; End of function read_port

; ---------------------------------------------------------------------------
; ball (bouncing around)
; - bounces towards wulf
; - bounces away from sabreman

upd_182_183:                                                    ; adj(-4,-8)
				call    upd_12_to_15
				ld      l, (ix+9)                                ; dX
				ld      h, (ix+10)                               ; dY
				push    hl
				ld      a, (ix+11)                               ; dZ
				ld      (tmp_bouncing_ball_dZ), a               ; tmp store
				call    dec_dZ_and_update_XYZ
				pop     hl
				ld      (ix+9), l                                ; preserve old dX
				ld      (ix+10), h                               ; preserve old dY
				ld      a, (graphic_objs_tbl)                   ; plyr graphic_no
				sub     0x10
				cp      0x20 ; ' '                             ; wulf?
				ld      a, 0x30 ; '0'                          ; jr nc,___
				jr      NC, loc_B626                            ; yes, skip
				add     a, 8                                   ; jr,c___

loc_B626:                                                       ; self-modifying code
				ld      (loc_B65D), a
				ld      (loc_B676), a                           ; self-modifying code
				ld      a, (graphic_objs_tbl+8)                 ; plyr_spr_1 screen
				and     1
				ld      a, 4
				jr      Z, loc_B63C
				ld      b, a
				ld      a, (seed_3)
				and     3
				add     a, b

loc_B63C:                                                       ; Z OOB?
				bit     2, (ix+12)
				jr      Z, loc_B668                             ; no, skip
				ld      (ix+11), a                               ; new dZ
				ld      a, (tmp_bouncing_ball_dZ)               ; old dZ
				and     a                                       ; >=0?
				jp      P, loc_B64F                             ; yes, skip
				call    audio_B42E

loc_B64F:                                                       ; random
				ld      a, r
				and     1
				jr      Z, loc_B66E
				ld      a, (graphic_objs_tbl+2)                 ; plyr_spr_1 Y
				cp      (ix+2)                                   ; <objY?
				ld      a, 2

loc_B65D:                                                       ; no, skip
				jr      NC, loc_B661
				neg                                             ; towards player

loc_B661:                                                       ; new dY
				ld      (ix+10), a
				ld      (ix+9), 0                               ; new dX=0

loc_B668:
				call    toggle_next_prev_sprite
				jp      set_deadly_wipe_and_draw_flags
; ---------------------------------------------------------------------------

loc_B66E:                                                       ; plyr_spr_1 X
				ld      a, (graphic_objs_tbl+1)
				cp      (ix+1)                                   ; < objX?
				ld      a, 2

loc_B676:
				jr      NC, loc_B67A
				neg                                             ; towards player

loc_B67A:                                                       ; new dX
				ld      (ix+9), a
				ld      (ix+10), 0                              ; new dY=0
				jr      loc_B668
; ---------------------------------------------------------------------------
; block (dropping)

upd_91:
				call    upd_6_7
				bit     3, (ix+13)                               ; triggered?
				ret     Z                                       ; no, exit
				res     3, (ix+13)                               ; reset triggered
				ld      (ix+11), 0                              ; dZ=0
				call    dec_dZ_and_update_XYZ
				bit     2, (ix+12)                               ; Z OOB?
				jr      NZ, loc_B69F                            ; yes, skip
				call    audio_B451

loc_B69F:
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------
; collapsing block

upd_143:
				call    upd_6_7
				bit     3, (ix+13)                               ; triggered?
				ret     Z                                       ; no, return
				ld      (ix+0), 184                             ; graphic_no = sparkles
				jp      upd_112_to_118_184
; ---------------------------------------------------------------------------
; block (moving NS)

upd_55:
				call    audio_B462
				ld      hl, 0x20A                              ; IX+2,IX+10 (Y,dY)
				jr      loc_B6BF
; ---------------------------------------------------------------------------
; block (moving EW)

upd_54:
				call    audio_B45D
				ld      hl, 0x109                              ; IX+1,IX+9 (X,dX)

loc_B6BF:
				ld      a, h
				ld      (loc_B6DE+2), a                         ; IX+2/1
				ld      a, l
				ld      (loc_B6EF+2), a                         ; IX+10/9
				call    upd_6_7                                 ; adj(-8,-16)
				push    ix
				pop     bc
				ld      a, c
				rrca
				and     0x10
				ld      c, a
				ld      a, (seed_2)
				add     a, c
				bit     4, a
				jr      Z, loc_B6DB
				cpl

loc_B6DB:
				and     0xF
				ld      c, a

loc_B6DE:                                                       ; modified code - X/Y
				ld      a, (ix+1)
				add     a, 8
				and     0xF
				cp      c
				jp      Z, set_wipe_and_draw_flags
				ld      a, 1
				jr      C, loc_B6EF
				neg

loc_B6EF:                                                       ; modified code - dX/dY
				ld      (ix+9), a
				ld      (ix+11), 1                              ; pre-load dZ=1 (no falling)
				jp      dec_dZ_wipe_and_draw
; ---------------------------------------------------------------------------
; guard and wizard (bottom half)

upd_144_to_149_152_to_157:
				call    adj_m6_m12
				ld      a, (ix+9)                                ; dX
				or      (ix+10)                                  ; dX & dY both 0?
				ret     Z                                       ; yes, exit
				call    audio_guard_wizard
				ld      a, (ix+9)                                ; dX
				cp      (ix+10)                                  ; dX<dY?
				jr      C, loc_B726                             ; yes, go
				bit     7, a                                    ; dX<0?
				jr      NZ, loc_B720                            ; yes, go
				set     3, (ix+0)                                ; graphic_no

loc_B716:                                                       ; clr hflip
				res     6, (ix+7)

loc_B71A:
				call    animate_human_legs
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

loc_B720:                                                       ; graphic_no
				res     3, (ix+0)
				jr      loc_B716
; ---------------------------------------------------------------------------

loc_B726:                                                       ; dY<0?
				bit     7, (ix+10)
				jr      Z, loc_B736                             ; no, go
				set     3, (ix+0)                                ; graphic_no

loc_B730:                                                       ; set hflip
				set     6, (ix+7)
				jr      loc_B71A
; ---------------------------------------------------------------------------

loc_B736:                                                       ; graphic_no
				res     3, (ix+0)
				jr      loc_B730
; ---------------------------------------------------------------------------
; guard (EW)

upd_150_151:
				call    adj_p7_m12
				bit     0, (ix+13)                               ; E or W?
				ld      a, 2
				jr      NZ, loc_B749                            ; E, skip
				neg

loc_B749:                                                       ; dX=+/-2
				ld      (ix+9), a
				ld      (ix+0x29), a                             ; and for botton half
				call    set_guard_wizard_sprite
				call    dec_dZ_and_update_XYZ
				bit     0, (ix+12)                               ; X OOB?
				jr      Z, loc_B763                             ; no, skip
				ld      a, (ix+13)
				xor     1                                      ; toggle direction
				ld      (ix+13), a

loc_B763:                                                       ; X
				ld      a, (ix+1)
				ld      (ix+0x21), a                             ; copy to bottom half
				jp      set_deadly_wipe_and_draw_flags

; =============== S U B R O U T I N E =======================================


set_guard_wizard_sprite:
				ld      a, (ix+9)                                ; dX
				or      (ix+10)                                  ; dY - both zero?
				ret     Z                                       ; yes, exit
				ld      a, (ix+9)                                ; dX
				cp      (ix+10)                                  ; dX<dY?
				jr      C, loc_B78E                             ; yes, go
				bit     7, a                                    ; dX<0?
				jr      NZ, loc_B788                            ; yes, go
				set     0, (ix+0)                                ; sprite 31/159

loc_B783:                                                       ; clear hflip
				res     6, (ix+7)
				ret
; ---------------------------------------------------------------------------

loc_B788:                                                       ; sprite 30/158
				res     0, (ix+0)
				jr      loc_B783
; ---------------------------------------------------------------------------

loc_B78E:                                                       ; dY<0?
				bit     7, (ix+10)
				jr      Z, loc_B79D                             ; no, go
				set     0, (ix+0)                                ; sprite 31/139

loc_B798:                                                       ; set hflip
				set     6, (ix+7)
				ret
; ---------------------------------------------------------------------------

loc_B79D:                                                       ; sprite 30/158
				res     0, (ix+0)
				jr      loc_B798
; End of function set_guard_wizard_sprite

; ---------------------------------------------------------------------------
; gargoyle

upd_22:
				call    set_both_deadly_flags
				jp      adj_m7_m12                              ; adj(-7,-12)
; ---------------------------------------------------------------------------
; spiked ball

upd_63:
				call    set_both_deadly_flags
				call    upd_6_7
				ld      a, (disable_spike_ball_drop)
				and     a
				ret     NZ
				bit     2, (ix+13)                               ; is this one dropping?
				jr      NZ, spiked_ball_drop                    ; yes, go
				ld      hl, is_spike_ball_dropping
				ld      a, (hl)
				and     a                                       ; is another ball already dropping?
				ret     NZ                                      ; yes, exit
				ld      a, (seed_3)
				cp      16                                     ; 1-in-16 chance
				ret     NC
				set     2, (ix+13)                               ; flag this one as dropping
				ld      (hl), 1                                ; flag a spike ball dropping
				ret
; ---------------------------------------------------------------------------

spiked_ball_drop:
				call    dec_dZ_and_update_XYZ
				bit     2, (ix+12)                               ; Z OOB? (hit the floor?)
				jr      NZ, loc_B7DC                            ; yes, go
				call    audio_B451

draw_spiked_ball:
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

loc_B7DC:                                                       ; flag this no longer dropping
				res     2, (ix+13)
				ld      hl, is_spike_ball_dropping
				ld      (hl), 0                                ; flag no spiked balls dropping
				jr      draw_spiked_ball
; ---------------------------------------------------------------------------
; spikes

upd_23:
				call    set_both_deadly_flags
				jp      upd_6_7
; ---------------------------------------------------------------------------
; fire (moving EW)

upd_86_87:
				call    upd_12_to_15
				ld      (ix+11), 1                              ; pre-load dZ=1
				bit     0, (ix+13)                               ; moving east?
				ld      a, 2
				jr      NZ, loc_B7FE                            ; yes, skip
				neg

loc_B7FE:                                                       ; dX=+/-2
				ld      (ix+9), a
				call    audio_B45D
				call    dec_dZ_and_update_XYZ
				bit     0, (ix+12)                               ; X OOB?
				ld      a, 1
				jr      loc_B82F
; ---------------------------------------------------------------------------
; fire (moving NS)

upd_180_181:
				call    upd_12_to_15
				ld      (ix+11), 1                              ; dZ=1
				bit     1, (ix+13)                              ; moving north?
				ld      a, 2
				jr      NZ, loc_B820                            ; yes, skip
				neg

loc_B820:                                                       ; dY=+/-2
				ld      (ix+10), a
				call    audio_B462
				call    dec_dZ_and_update_XYZ
				bit     1, (ix+12)                              ; Y OOB?
				ld      a, 2

loc_B82F:
				jr      Z, loc_B83A
				xor     (ix+13)                                 ; toggle bit 1/2
				ld      (ix+13), a
				call    audio_B42E

loc_B83A:
				call    toggle_next_prev_sprite
				jr      set_deadly_wipe_and_draw_flags
; ---------------------------------------------------------------------------
; fire (stationary) (not used)

upd_176_177:
				call    upd_12_to_15
				ld      a, (fire_seed)
				and     1
				ret     Z
				ld      a, (seed_3)
				and     0x40 ; '@'
				xor     (ix+7)                                   ; randomise hflip
				ld      (ix+7), a
				call    toggle_next_prev_sprite

set_deadly_wipe_and_draw_flags:
				call    set_both_deadly_flags
				jp      set_wipe_and_draw_flags

; =============== S U B R O U T I N E =======================================


set_both_deadly_flags:
				ld      a, (ix+13)
				or      0xA0 ; '�'                             ; fatal if you hit it, it hits you
				ld      (ix+13), a
				ret
; End of function set_both_deadly_flags

; ---------------------------------------------------------------------------
; ball up/down

upd_178_179:                                                    ; adjust (-4,-8)
				call    upd_12_to_15
				ld      a, (ball_bounce_height)
				and     a                                       ; bouncing?
				jr      NZ, loc_B876                            ; yes, skip
				ld      a, (ix+3)                                ; Z
				add     a, 32                                  ; calc bounce height
				ld      (ball_bounce_height), a

loc_B876:                                                       ; toggle 178/179
				call    toggle_next_prev_sprite
				call    audio_B451
				bit     2, (ix+13)                               ; dir=up?
				jr      NZ, ball_up                             ; yes, skip
				call    dec_dZ_and_update_XYZ
				bit     2, (ix+12)                               ; Z OOB?
				jr      Z, loc_B892                             ; no, skip
				set     2, (ix+13)                               ; set dir=up
				call    audio_B42E

loc_B892:
				jr      set_deadly_wipe_and_draw_flags
; ---------------------------------------------------------------------------

ball_up:                                                        ; dZ=3
				ld      (ix+11), 3
				call    dec_dZ_and_update_XYZ
				ld      a, (ball_bounce_height)
				cp      (ix+3)                                	; Z < ball_bounce_height?
				jr      NC, loc_B892                            ; yes, go
				res     2, (ix+13)                            	; set dir=down
				jr      loc_B892

; =============== S U B R O U T I N E =======================================


init_cauldron_bubbles:
				ld      a, (graphic_objs_tbl+8)                 ; plyr_spr_1 screen
				cp      136                                    	; cauldron room?
				ret     NZ                                      ; no, exit
				ld      de, special_objs_here_1                	; special_objs_here[1]
				ld      a, (de)                                 ; graphic no.
				and     a                                       ; null?
				ret     NZ                                      ; no, return
				ld      a, (all_objs_in_cauldron)
				and     a
				ret     NZ
				ld      hl, cauldron_bubbles                	; source data
				ld      bc, 18                                 	; 18 bytes to copy
				push    de
				pop     ix                                      ; save destination
				ldir                                            ; copy
				jp      adj_m4_m12
; End of function init_cauldron_bubbles

; ---------------------------------------------------------------------------
cauldron_bubbles:
				DB 		0xA0, 0x80, 0x80, 0x80, 0x05, 0x05, 0x0C, 0x10, 0xB4, 0x00, 0x00
				DB 		0x00, 0x00, 0xA0, 0x00, 0x00, 0x00, 0x00
; ---------------------------------------------------------------------------
; even more sparkles (showing next object required)

upd_160_to_163:
				call    adj_m4_m12
				ld      a, (special_objs_here)
				and     a                                       ; null?
				jp      NZ, upd_111                             ; no, skip
				set     1, (ix+7)                               ; ignore in 3D calcs
				call    dec_dZ_and_update_XYZ
				call    next_graphic_no_mod_4
				ld      a, (ix+3)                               ; Z
				cp      160
				ld      (ix+11), 2                              ; dZ=2
				jr      C, loc_B916
				ld      (ix+11), 1                              ; dZ=1
				ld      a, (graphic_objs_tbl)                   ; plyr_spr_1 (legs) graphic_no
				sub     0x30 ; '0'
				cp      0x10                                   	; wulf?
				jr      C, loc_B919                             ; yes, go
				ld      a, (ix+0)                               ; graphic_no
				and     3
				jr      NZ, loc_B916
				call    ret_next_obj_required
				ld      a, (hl)
				or      168
				ld      (ix+0), a                               ; show next object required

loc_B916:
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------
; if wulf, no reveal of next object

loc_B919:                                                      	; graphic_no
				set     2, (ix+0)
				res     1, (ix+7)                               ; don't ignore in 3D calcs
				jr      loc_B916
; ---------------------------------------------------------------------------
; special objs when 1st being put into cauldron

upd_168_to_175:
				call    adj_m4_m12
				ld      (ix+0), 160                             ; graphic_no (sparkles)
				jr      loc_B916
; ---------------------------------------------------------------------------
; repel spell

upd_164_to_167:
				call    adj_m4_m12
				ld      a, (ix+8)                               ; object screen
				cp      136                                    	; cauldron room?
				jr      Z, loc_B942                             ; yes, go
				ld      a, (graphic_objs_tbl+7)
				bit     0, a                                    ; near arch?
				jr      Z, loc_B942                             ; no, go
				ld      bc, 0x101                              	; dX,dY=1
				jr      loc_B945
; ---------------------------------------------------------------------------

loc_B942:                                                       ; dX,dY=4
				ld      bc, 0x404

loc_B945:
				call    move_towards_plyr
				call    dec_dZ_and_update_XYZ
				call    next_graphic_no_mod_4
				ld      a, (ix+8)                               ; object screen
				cp      136                                    	; cauldron room?
				jr      NZ, loc_B962                            ; no, skip
				ld      a, (graphic_objs_tbl)                   ; plyr_spr_1 graphic_no
				sub     0x10
				cp      0x40 ; '@'
				jr      C, loc_B962
;
; final sparkles in cauldron

upd_111:                                                        ; invalid
				ld      (ix+0), 1

loc_B962:
				jp      audio_B467_wipe_and_draw

; =============== S U B R O U T I N E =======================================


move_towards_plyr:
				ld      hl, graphic_objs_tbl+1                	; plyr_spr_1 X
				ld      a, (ix+1)                               ; object X
				sub     (hl)                                    ; -plyrX
				inc     hl                                      ; plyr_spr_1 Y
				ld      a, c                                    ; 1or4
				jp      M, loc_B973                             ; plyr E? yes, go
				neg

loc_B973:                                                       ; dX (towards player)
				ld      (ix+9), a
				ld      a, (ix+2)                               ; object Y
				sub     (hl)                                    ; -plyrY
				inc     hl                                      ; plyrZ
				ld      a, b                                    ; 1or4
				jp      M, loc_B981                             ; plyr N? yes, go
				neg

loc_B981:                                                       ; dY (towards player)
				ld      (ix+10), a
				ret
; End of function move_towards_plyr


; =============== S U B R O U T I N E =======================================


toggle_next_prev_sprite:
				ld      a, (ix+0)                               ; graphic_no
				xor     1                                      	; toggle next/prev sprite
				jr      save_graphic_no
; ---------------------------------------------------------------------------

next_graphic_no_mod_4:                                          ; graphic no.
				ld      a, (ix+0)
				ld      c, a
				and     0xFC ; '�'                             ; mask off low 2 bits
				ld      b, a
				ld      a, c
				inc     a
				and     3                                      	; inc low 2 bits
				or      b                                       ; mask them back in

save_graphic_no:                                                ; store new graphic no
				ld      (ix+0), a
				ret
; End of function toggle_next_prev_sprite

; ---------------------------------------------------------------------------
; cauldron (bottom)

upd_141:
				jp      upd_88_to_90
; ---------------------------------------------------------------------------
; cauldron (top)

upd_142:                                                        ; +12, -24
				ld      hl, 0xCE8
				jp      set_pixel_adj
; ---------------------------------------------------------------------------
; guard and wizard (top half)

upd_30_31_158_159:
				call    adj_p3_m12
				call    dec_dZ_and_update_XYZ
				call    move_guard_wizard_NSEW
				ld      (ix+9), l                               ; dX
				ld      (ix+0x29), l                            ; next obj dX
				ld      (ix+10), h                              ; dY
				ld      (ix+0x2A), h                            ; next obj dY
				ld      a, (ix+1)                               ; X
				ld      (ix+0x21), a                            ; copy to next obj X
				ld      a, (ix+2)                               ; Y
				ld      (ix+0x22), a                          	; copy to next obj Y
				call    set_guard_wizard_sprite
				jp      set_deadly_wipe_and_draw_flags

; =============== S U B R O U T I N E =======================================


move_guard_wizard_NSEW:
				ld      bc, guard_NSEW_tbl                     	; jump table
				ld      a, (ix+13)
				and     3                                      	; direction (N/S/E/W)
				ld      l, a
				jp      jump_to_tbl_entry
; End of function move_guard_wizard_NSEW

; ---------------------------------------------------------------------------
guard_NSEW_tbl: DW guard_W
				DW guard_N
				DW guard_E
				DW guard_S
; ---------------------------------------------------------------------------

guard_W:                                                        ; dY=0, dX=-2
				ld      hl, 0xFE ; '�'
				bit     0, (ix+12)                              ; X OOB?
				ret     Z                                       ; no, exit
				ld      hl, 0x200                              	; dY=2, dX=0

next_guard_dir:                                                 ; direction
				ld      a, (ix+13)
				ld      c, a
				inc     a
				and     3                                      	; relevant bits
				ld      b, a
				ld      a, c
				and     0xFC ; '�'
				or      b                                       ; inc lowest 2 bits (mod 4)
				ld      (ix+13), a
				ret
; ---------------------------------------------------------------------------

guard_N:                                                        ; dY=+2, dX=0
				ld      hl, 0x200
				bit     1, (ix+12)                               ; Y OOB?
				ret     Z                                       ; no, exit
				ld      hl, 2                                  ; dY=0, dX=+2
				jr      next_guard_dir
; ---------------------------------------------------------------------------

guard_E:                                                        ; dY=0, dX=+2
				ld      hl, 2
				bit     0, (ix+12)                               ; X OOB?
				ret     Z                                       ; no, exit
				ld      hl, 0xFE00                             ; dY=-2, dX=0
				jr      next_guard_dir
; ---------------------------------------------------------------------------

guard_S:                                                        ; dY=-2, dX=0
				ld      hl, 0xFE00
				bit     1, (ix+12)                               ; Y OOB?
				ret     Z                                       ; no, exit
				ld      hl, 0xFE ; '�'                         ; dY=0, dX=-2
				jr      next_guard_dir
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR lose_life



; =============== S U B R O U T I N E =======================================


print_days:
				ld      hl, vidbuf+0xEF                       ; (120,7)
				ld      de, days
				ld      b, 1
				call    print_BCD_number
				ld      hl, zx_aram+0x2EF                     ; attribute memory
				ld      (hl), 0x47 ; 'G'
				inc     l
				ld      (hl), 0x47 ; 'G'
				ret
; End of function print_days


; =============== S U B R O U T I N E =======================================


print_lives_gfx:
				ld      ix, sprite_scratchpad
				ld      (ix+0), 0x8C ; '�'                      ; sprite index
				ld      (ix+7), 0                               ; clear flags
				ld      (ix+26), 16                             ; pixel X
				ld      (ix+27), 32                             ; pixel Y
				call    print_sprite
				ld      a, 0x47 ; 'G'
				ld      de, zx_aram+0x242
				ld      b, 2
				call    fill_DE
				ld      de, zx_aram+0x262
				ld      b, 4
				jp      fill_DE
; End of function print_lives_gfx


; =============== S U B R O U T I N E =======================================


print_lives:
				ld      de, lives                              ; ptr number
				ld      b, 1                                   ; 1 byte (2 BCD digits)
				ld      hl, vidbuf+0x4E4                      ; screen buffer location
				jp      print_BCD_number
; End of function print_lives

; HL = screen buffer address
; DE = ptr number to print (BCD)
; B  = number of bytes (BCD digit pairs)

; =============== S U B R O U T I N E =======================================


print_BCD_number:
				push    hl
				ld      hl, font
				ld      (gfxbase_8x8), hl
				pop     hl

loc_BCB6:                                                       ; get number
				ld      a, (de)
				rrca
				rrca
				rrca
				rrca
				and     0xF                                    ; high digit
				call    print_8x8

print_BCD_lsd:                                                  ; get number
				ld      a, (de)
				and     0xF                                    ; low digit
				call    print_8x8
				inc     de                                      ; next byte address
				djnz    loc_BCB6                                ; loop through all bytes
				ret
; End of function print_BCD_number


; =============== S U B R O U T I N E =======================================


display_day:
				ld      a, (curr_room_attrib)                   ; attribute
				cpl
				add     a, 2
				and     7
				or      0x40 ; '@'                             ; bright on
				ld      (day_txt), a
				ld      hl, day_font
				ld      (gfxbase_8x8), hl                       ; set print routine font
				ld      de, day_txt
				ld      hl, 0xF70                              ; screen location
				push    hl
				jp      print_text
; End of function display_day

; ---------------------------------------------------------------------------
day_txt:        DB 0, 0, 1, 2, 0x83
day_font:       DB 6, 7, 6, 6, 6, 6, 6, 0xF
				DB 0, 1, 0x82, 0xC6, 0x64, 0x6C, 0x6D, 0xC6
				DB 0xC8, 0xC6, 0xE1, 0x60, 0x60, 0xE0, 0x64, 0x63
				DB 0x60, 0x60, 0x60, 0xE0, 0x60, 0x40, 0xC0, 0x80

; =============== S U B R O U T I N E =======================================




; =============== S U B R O U T I N E =======================================


print_8x8:
				push    bc
				push    de
				push    hl
				ld      l, a
				ld      h, 0                                   ; HL = character
				add     hl, hl
				add     hl, hl
				add     hl, hl                                  ; calculate offset into font data
				ld      de, (gfxbase_8x8)
				add     hl, de                                  ; calculate address of font data
				ex      de, hl                                  ; DE = font data
				pop     hl
				ld      b, 8                                   ; # bytes (lines) to display

loc_BE91:                                                       ; get font data byte
				ld      a, (de)
				ld      (hl), a                                 ; store in video/buffer memory
				inc     de                                      ; next font data byte
				push    bc
				ld      bc, 0xFFE0                             ; next video/buffer line
				add     hl, bc
				pop     bc
				djnz    loc_BE91                                ; loop until done character
				pop     de
				ld      bc, 0x101
				add     hl, bc                                  ; video/buffer address for next character
				pop     bc
				ret
; End of function print_8x8


; =============== S U B R O U T I N E =======================================


toggle_selected:
				and     a
				jr      NZ, loc_BEAD

loc_BEA6:
				set     7, (hl)
				jr      loc_BEAF
; ---------------------------------------------------------------------------

loc_BEAA:
				dec     a
				jr      Z, loc_BEA6

loc_BEAD:
				res     7, (hl)

loc_BEAF:
				inc     hl
				djnz    loc_BEAA
				ret
; End of function toggle_selected




; =============== S U B R O U T I N E =======================================


multiple_print_sprite:
				push    bc
				push    de
				push    hl
				call    print_sprite
				pop     hl
				pop     de
				pop     bc
				ld      a, (ix+26)                               ; pixel X
				add     a, e                                    ; add offset
				ld      (ix+26), a                               ; store new pixel X
				ld      a, (ix+27)                               ; pixel Y
				add     a, d                                    ; add offset
				ld      (ix+27), a                               ; store new pixel Y
				djnz    multiple_print_sprite                   ; loop though all sprites
				ret
; End of function multiple_print_sprite

; ---------------------------------------------------------------------------
; player appear sparkles

upd_120_to_126:
				call    adj_m4_m12
				ld      a, (seed_2)
				cpl
				and     1
				ret     NZ
				inc     (ix+0)                                   ; next sprite
				call    audio_B419                              ; make a sound?
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------
; last player appears sparkle

upd_127:
				call    adj_m4_m12
				res     6, (ix+13)
				ld      a, (ix+16)                               ; player graphic_no
				ld      (ix+0), a                                ; set as object graphic_no
				jp      jump_to_upd_object
; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR chk_and_init_transform

init_death_sparkles:                                            ; twinkly transform
				ld      (ix+0), 112
				set     1, (ix+7)                                ; ignore in 3D calcs
				jr      loc_BF31
; END OF FUNCTION CHUNK FOR chk_and_init_transform
; ---------------------------------------------------------------------------
; death sparkles

upd_112_to_118_184:
				call    adj_m4_m12
				inc     (ix+0)                                   ; graphic_no
; START OF FUNCTION CHUNK FOR chk_and_init_transform

loc_BF31:
				call    audio_B403
				jp      set_wipe_and_draw_flags
; END OF FUNCTION CHUNK FOR chk_and_init_transform
; ---------------------------------------------------------------------------
; sparkles (object in cauldron)

upd_185_187:
				ld      l, (ix+16)
				ld      h, (ix+17)
;
;  BUG: this routine is primarily for special objects
;       when dropped into cauldron etc (disappear)
;  BUT: when the collapsing block disappears, the
;       graphic_no is set to 184, which is then
;       incremented to 185, and we end up here.
;  ONLY: there's no special object entry (HL=0)
;
;  So it zaps [$0000] which is ROM
;  - and harmless on the ZX Spectrum.
;
; BUG VERIFIED! on the Spectrum under MESS
;
				ld      (hl), 0                                ; zap graphic_no in special_objs_tbl
; last death sparkle

upd_119:
				call    adj_m4_m12
				jp      upd_111

; =============== S U B R O U T I N E =======================================


display_objects_carried:
				ld      a, (objects_carried_changed)
				and     a                                       ; anything changed?
				ret     Z                                       ; no, return
				xor     a                                       ; clear changed flag
				ld      (objects_carried_changed), a
; End of function display_objects_carried


; =============== S U B R O U T I N E =======================================


display_objects:
				push    ix
				ld      ix, sprite_scratchpad
				ld      b, 3                                   ; 3 objects max
				ld      hl, objects_carried

display_object:
				push    bc
				push    hl
				ld      a, b
				neg
				add     a, 3                                   ; (~b+3)
				sla     a
				sla     a
				sla     a                                       ; =(~b+3)*8
				ld      c, a
				sla     a                                       ; (~b+3)*16
				add     a, c                                    ; =(~b+3)*24
				add     a, 16                                  ; =(~b+3)*24+16
				ld      (ix+26), a                               ; pixel X
				ld      (ix+27), 0                              ; pixel Y
				ld      c, (ix+26)                               ; pixel X
				ld      b, (ix+27)                               ; pixel Y
				push    hl                                      ; ptr object
				call    vidbuf_calc_addr_in_hl
				ld      bc, 0x1803                              ; width=3, height=24
				xor		a
				call    vidbuf_fill_window                      ; wipe 24x24 pixel area
				pop     hl                                      ; ptr object
				ld      a, (hl)                                 ; object (sprite index)
				and     a                                       ; null?
				jr      Z, loc_BF91                             ; yes, skip
				ld      (ix+0), a                                ; sprite index
				call    print_sprite

loc_BF91:                                                       ; pixel X
				ld      c, (ix+26)
				ld      b, (ix+27)                               ; pixel Y
				call    screen_calc_addr_de
				call    vidbuf_calc_addr_in_hl
				ld      bc, 0x1803                             ; lines=24, bytes=3
				call    blit_to_screen
				pop     hl                                      ; ptr object
				pop     bc
				push    bc
				push    hl                                      ; ptr object
				ld      a, (hl)                                 ; object (sprite index)
				and     0xF
				ld      e, a
				ld      d, 0
				ld      hl, object_attributes
				add     hl, de
				ld      c, (hl)                                 ; get fill byte entry
				ld      l, (ix+26)                               ; pixel X
				ld      a, (ix+27)                               ; pixel Y
				add     a, 23
				ld      h, a
				call    attrib_calc_addr_de
				ex      de, hl
				ld      a, c                                    ; fill byte
				ld      bc,0x0303                           	; width=3, height=3
				call    vidbuf_fill_window
				pop     hl                                      ; ptr object
				pop     bc                                      ; object count
				inc     hl
				inc     hl
				inc     hl
				inc     hl                                      ; next entry (4 bytes)
				djnz    display_object                          ; loop through all objects
				pop     ix
				ret
; End of function display_objects

; ---------------------------------------------------------------------------
; diamond, poison, boot, challice, cup, bottle, globe, idol
; red, magenta, green, cyan, yellow, white, red, white
object_attributes:DB 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x42, 0x47
sprite_scratchpad:DB 0x8A, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 3, 1, 0xE8, 0xA0, 0, 0, 0
				DB 0

; =============== S U B R O U T I N E =======================================


chk_pickup_drop:
				ld      hl, user_input_method
				ld      a, (hl)
				and     6                                      ; keybd/joystick bits only
				ld      a, (user_input)
				jr      Z, loc_C00B                             ; keybd? yes, skip
				bit     3, (hl)                                 ; directional?
				jr      Z, loc_C00B
				rrca

loc_C00B:
				and     0x10
				ret
; End of function chk_pickup_drop


; =============== S U B R O U T I N E =======================================


handle_pickup_drop:
				ld      a, (pickup_drop_pressed)
				and     a                                       ; still registered as pressed?
				jp      NZ, loc_C0A9                            ; yes, go
				call    chk_pickup_drop                         ; actually pressed?
				ret     Z                                       ; no, exit
				call    chk_plyr_OOB                            ; out of bounds?
				ret     NC                                      ; yes, exit
				bit     3, (ix+12)                               ; jumping?
				ret     NZ                                      ; yes, exit
				bit     2, (ix+12)                               ; Z OOB?
				ret     Z                                       ; ???
				xor     a
				ld      (cant_drop), a
				ld      a, (ix+3)                                ; Z
				ld      b, a
				add     a, 12                                  ; Z+12
				ld      (ix+3), a
				call    do_any_objs_intersect
				ld      (ix+3), b                                ; restore original Z
				jr      NC, loc_C041
				ld      a, 1                                   ; we can't drop anything
				ld      (cant_drop), a

loc_C041:
				call    toggle_audio_hw_x16
				ld      a, 1
				ld      (pickup_drop_pressed), a
				ld      (objects_carried_changed), a
				ld      b, 2
				ld      l, (ix+4)                                ; width
				ld      a, l
				add     a, 4                                   ; width+4
				ld      (ix+4), a
				ld      h, (ix+5)                                ; depth
				ld      a, h
				add     a, 4                                   ; depth+4
				ld      (ix+5), a
				push    hl
				ld      l, (ix+6)                                ; height
				ld      a, l
				add     a, 4                                   ; height+4
				ld      (ix+6), a
				push    hl
				ld      iy, special_objs_here

loc_C06F:
				call    can_pickup_spec_obj
				jp      C, pickup_object                        ; yes, go
				ld      de, 32                                 ; entry size
				add     iy, de                                  ; next entry
				djnz    loc_C06F
				call    chk_pickup_drop
				jr      Z, done_pickup_drop
				ld      b, 2
				ld      a, (ix+8)                                ; plyr_spr_1 screen
				cp      136                                    ; cauldron room?
				jr      NZ, loc_C08C                            ; no, skip
				ld      b, 1                                   ; only check 1st special object

loc_C08C:
				ld      iy, special_objs_here
				ld      de, 32                                 ; entry size

loc_C093:                                                       ; graphic no.
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, room_to_drop                         ; yes, skip
				add     iy, de                                  ; next entry
				djnz    loc_C093                                ; loop

done_pickup_drop:
				pop     hl
				ld      (ix+6), l                                ; height
				pop     hl
				ld      (ix+4), l                                ; depth
				ld      (ix+5), h                                ; width
				ret
; ---------------------------------------------------------------------------

loc_C0A9:                                                       ; still held down?
				call    chk_pickup_drop
				ret     NZ                                      ; yes, exit
				xor     a                                       ; clear flag
				ld      (pickup_drop_pressed), a
				ret
; ---------------------------------------------------------------------------

room_to_drop:
				ld      hl, object_carried_2
				ld      a, (hl)
				inc     hl
				and     a
				jr      Z, adjust_carried
				ld      a, (cant_drop)
				and     a
				jr      NZ, done_pickup_drop
				dec     hl
				ld      a, (hl)
				inc     hl
				ld      (iy+0), a                                ; graphic_no
				ld      a, (ix+8)                                ; plyr_spr_1 screen
				cp      136                                    ; cauldron room?
				jr      NZ, loc_C0DD                            ; no, skip
				ld      a, (ix+3)                                ; plyr_spr_1 Z
				cp      152
				jr      C, loc_C0DD
				set     3, (iy+0)                                ; graphic_no
				ld      a, 1
				ld      (obj_dropping_into_cauldron), a

loc_C0DD:
				push    hl
				ld      bc, 3
				push    ix
				pop     hl
				push    iy
				pop     de
				inc     de
				inc     hl
				ldir                                            ; copy x,y,z coordinates of player
				ld      a, (ix+3)                                ; Z
				add     a, 12
				ld      (ix+3), a                                ; update Z
				ld      a, (ix+0x23)                             ; Z of next sprite
				add     a, 12
				ld      (ix+0x23), a                             ; update Z of next sprite
				push    ix
				push    iy
				pop     ix
				call    calc_pixel_XY
				pop     ix

drop_object:                                                    ; width=5
				ld      (iy+4), 5
				ld      (iy+5), 5                               ; depth=5
				ld      (iy+6), 12                              ; height=12
				pop     hl
				ld      a, (hl)
				inc     hl
				ld      (iy+7), a                                ; flags7
				ld      a, (ix+8)                                ; scrn
				ld      (iy+8), a
				ld      a, (hl)
				inc     hl
				ld      (iy+16), a
				ld      a, (hl)
				ld      (iy+17), a                               ; set ptr to obj_tbl entry
				set     0, (iy+13)                               ; flag just dropped

adjust_carried:                                                 ; 2nd-to-last entry
				ld      hl, unk_5BE3
				ld      de, end_of_objects_carried             ; 3 entries (@4 bytes) to shift
				ld      bc, 12
				lddr                                            ; shift down by 1 entry
				ld      de, inventory
				ld      b, 4
				call    zero_DE                                 ; zap extra slot
				jp      done_pickup_drop
; ---------------------------------------------------------------------------

pickup_object:
				ld      hl, inventory
				xor     a
				ld      (disable_spike_ball_drop), a
				ld      a, (iy+0)                                ; graphic_no
				ld      (hl), a
				inc     hl
				ld      a, (iy+7)                                ; flags7
				ld      (hl), a
				inc     hl
				ld      e, (iy+16)
				ld      d, (iy+17)                               ; ptr graphic object
				xor     a
				ld      (de), a                                 ; zap special_objs_tbl.graphic_no
				ld      (hl), e
				inc     hl
				ld      (hl), d                                 ; store ptr
				call    set_wipe_and_draw_IY
				ld      (iy+0), 1
				ld      hl, object_carried_2                   ; object_carried[2].graphic_no
				ld      a, (hl)
				inc     hl
				and     a                                       ; empty slot?
				jr      Z, adjust_carried
				ld      (iy+0), a
				push    hl
				jr      drop_object
; End of function handle_pickup_drop

; returns C flag set if special object
; and close enough to pick up

; =============== S U B R O U T I N E =======================================


can_pickup_spec_obj:
				ld      a, (iy+0)                                ; graphic no.
				sub     0x60 ; '`'                             ; special objects base no.
				cp      7                                      ; special object?
				ret     NC                                      ; no, exit

is_on_or_near_obj:
				push    bc
				ld      bc, 0
				ld      l, c
				ld      h, c
				call    do_objs_intersect_on_x
				jr      NC, loc_C19F
				call    do_objs_intersect_on_y
				jr      NC, loc_C19F
				ld      a, (ix+3)                                ; Z
				sub     4                                      ; Z-4
				ld      (ix+3), a
				call    do_objs_intersect_on_z
				push    af
				ld      a, (ix+3)
				add     a, 4
				ld      (ix+3), a
				pop     af

loc_C19F:
				pop     bc
				ret
; End of function can_pickup_spec_obj


; =============== S U B R O U T I N E =======================================


is_obj_moving:
				ld      a, (ix+9)                                ; dX
				or      (ix+10)                                  ; dY
				or      (ix+11)                                  ; dZ
				ret
; End of function is_obj_moving

; ---------------------------------------------------------------------------
; extra life

upd_103:
				call    upd_128_to_130
				push    ix
				pop     iy                                      ; iy=extra life object
				ld      ix, graphic_objs_tbl                   ; ix = player
				inc     (ix+4)                                   ; width
				inc     (ix+5)                                   ; depth
				call    is_on_or_near_obj
				dec     (ix+4)                                   ; restore width
				dec     (ix+5)                                   ; restore depth
				push    iy
				pop     ix                                      ; restore ix (extra life object)
				jr      NC, loc_C1EE                            ; not on/near, skip
				set     3, (ix+0)                                ; graphic_no
				call    adj_m4_m12
				ld      l, (ix+16)
				ld      h, (ix+17)
				ld      (hl), 0                                ; zap ptr object table entry
				ld      hl, lives
				inc     (hl)                                    ; extra life!
				xor     a
				ld      (disable_spike_ball_drop), a
				call    toggle_audio_hw_x16
				call    print_lives
				ld      bc, 0x2020
				call    blit_2x8

loc_C1EE:
				jp      dec_dZ_upd_XYZ_wipe_if_moving
; ---------------------------------------------------------------------------
; special objects being put in cauldron

upd_104_to_110:
				call    adj_m4_m12
				ld      a, (ix+1)                                ; X
				sub     128
				jr      Z, loc_C202
				ld      a, 1
				jp      M, loc_C202
				neg

loc_C202:                                                       ; dX towards centre of room
				ld      (ix+9), a
				ld      a, (ix+2)                                ; Y
				sub     128
				jr      Z, loc_C213
				ld      a, 1
				jp      M, loc_C213
				neg

loc_C213:                                                       ; dY towards cente of room
				ld      (ix+10), a
				ld      a, (ix+1)                                ; X
				cp      128                                    ; centre of X-axis?
				jr      NZ, loc_C222                            ; no, skip
				xor     (ix+2)                                   ; centre of Y-axis?
				jr      Z, centre_of_room                       ; yes, skip

loc_C222:                                                       ; Z
				ld      a, (ix+3)
				cp      152
				ld      a, 1
				jr      NC, loc_C22C
				inc     a

loc_C22C:                                                       ; dZ
				ld      (ix+11), a

loc_C22F:
				call    dec_dZ_and_update_XYZ

audio_B467_wipe_and_draw:                                       ; audio?
				call    audio_B467
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

centre_of_room:
				ld      a, 128
				cp      (ix+3)                                   ; Z
				jr      NC, add_obj_to_cauldron
				set     1, (ix+7)                                ; ignore in 3D calcs
				jr      loc_C22F
; ---------------------------------------------------------------------------

add_obj_to_cauldron:                                            ; Z
				ld      (ix+3), 128
				call    ret_next_obj_required
				ld      a, (ix+0)                                ; graphic no.
				and     7                                      ; convert to secial object index
				cp      (hl)                                    ; same as required?
				jr      NZ, loc_C265                            ; no, skip
				ld      hl, objects_put_in_cauldron
				inc     (hl)
				call    cycle_colours_with_sound
				ld      a, (objects_put_in_cauldron)
				cp      14                                     ; got all objects?
				jr      NZ, loc_C265                            ; no, skip
				call    prepare_final_animation

loc_C265:
				xor     a
				ld      (obj_dropping_into_cauldron), a
				ld      l, (ix+16)
				ld      h, (ix+17)                               ; ptr object table
				ld      (hl), 0                                ; zap graphic no.
				jp      upd_111

; =============== S U B R O U T I N E =======================================


ret_next_obj_required:
				ld      a, (objects_put_in_cauldron)
				ld      hl, objects_required
				jp      add_HL_A
; End of function ret_next_obj_required

; ---------------------------------------------------------------------------
objects_required:DB 0, 1, 2, 3, 4, 5, 6, 3
				DB 5, 0, 6, 1, 2, 4
; ---------------------------------------------------------------------------
; special objects

upd_96_to_102:
				call    adj_m4_m12
				call    dec_dZ_and_update_XYZ
				bit     0, (ix+13)                               ; just dropped?
				jr      NZ, loc_C29B                            ; no, skip
				call    is_obj_moving
				ret     Z

loc_C29B:                                                       ; clear just dropped flag
				res     0, (ix+13)
				call    clear_dX_dY
				jp      audio_B467_wipe_and_draw


; =============== S U B R O U T I N E =======================================


chk_and_init_transform:

; FUNCTION CHUNK AT RAM:BF21 SIZE 0000000A BYTES
; FUNCTION CHUNK AT RAM:BF31 SIZE 00000006 BYTES

				ld      a, (transform_flag_graphic)
				and     a
				ret     Z
				ld      a, (ix+12)
				and     0xF0 ; '�'
				ret     NZ
				bit     3, (ix+12)                               ; already jumping?
				ret     NZ                                      ; yes, exit
				inc     sp
				inc     sp
				ld      a, (ix+0)                                ; graphic_no
				ld      (transform_flag_graphic), a
				ld      (ix+16), 8                              ; transform count
				push    ix
				ld      de, 0x20 ; ' '
				add     ix, de
				ld      (ix+0), 1
				call    set_wipe_and_draw_flags
				pop     ix
				call    upd_11
				jr      rand_legs_sprite
; ---------------------------------------------------------------------------
; human/wulf transform

upd_92_to_95:
				call    upd_11
				bit     6, (ix+13)
				jr      Z, loc_C349
				ld      a, (all_objs_in_cauldron)
				and     a
				jr      NZ, loc_C349
				jp      init_death_sparkles
; ---------------------------------------------------------------------------

loc_C349:
				ld      a, (seed_2)
				and     3                                      ; 1-in-4 chance?
				ret     NZ                                      ; no, return
				call    audio_B472
				dec     (ix+16)                                  ; copy of graphic_no
				jr      Z, loc_C377

rand_legs_sprite:                                               ; RANDOM
				ld      a, r
				ld      c, a
				ld      a, (seed_3)
				add     a, c
				and     3
				or      92                                     ; leg sprite (92-95)
				cp      (ix+0)                                   ; same as current?
				jr      NZ, loc_C369                            ; no, skip
				xor     1                                      ; change

loc_C369:                                                       ; store new sprite
				ld      (ix+0), a
				ld      a, (ix+7)
				xor     0x40 ; '@'                             ; toggle hflip
				ld      (ix+7), a
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

loc_C377:
				ld      a, (transform_flag_graphic)
				xor     0x20 ; ' '
				ld      (ix+0), a                                ; graphic_no
				add     a, 0x10
				ld      (ix+0x20), a                             ; graphic_no (top half)
				xor     a
				ld      (transform_flag_graphic), a
				call    adj_m6_m12
				bit     5, (ix+0)
				jr      Z, loc_C394
				dec     (ix+19)                                  ; dY_adj

loc_C394:
				jp      set_wipe_and_draw_flags
; End of function chk_and_init_transform


; =============== S U B R O U T I N E =======================================


print_sun_moon:
				ld      a, (seed_2)
				and     7
				ret     NZ
				ld      ix, sun_moon_scratchpad
				inc     (ix+26)                                  ; pixel X
; End of function print_sun_moon


; =============== S U B R O U T I N E =======================================


display_sun_moon_frame:
				ld      a, (all_objs_in_cauldron)
				and     a
				ret     NZ
				ld      a, (ix+26)                               ; pixel X
				cp      225
				jr      Z, toggle_day_night
				ld      a, (ix+26)                               ; pixel X
				add     a, 16
				ld      hl, sun_moon_yoff
				rrca
				rrca
				and     0xF
				call    add_HL_A                                ; ptr entry
				ld      a, (hl)                                 ; get entry
				ld      (ix+27), a                               ; pixel Y

display_frame:                                                  
				ld      bc, 0x1F06								; 31 lines, 6 bytes (swapped below)
				ld      hl, vidbuf+0x17                       	; (184,0)
				xor		a
				call    vidbuf_fill_window
				call    print_sprite                            ; display sun/moon
				ld      ix, sprite_scratchpad
				ld      (ix+7), 0                               ; clear flags
				ld      (ix+0), 0x5A ; 'Z'                      ; sun/moon frame left
				ld      (ix+26), 184                            ; pixel X
				ld      (ix+27), 0                              ; pixel Y
				call    print_sprite
				ld      (ix+26), 208                            ; pixel X
				ld      (ix+0), 0xBA ; '�'                      ; sun/moon frame right
				call    print_sprite
				ld      bc, 0x1F06								; 31 lines, 6 bytes (swapped below)
				ld      hl, vidbuf+0x17                       	; (184,0)
				ld      de, zx_vram+0x17F7                    ; (184,0)
				jp      blit_to_screen
; ---------------------------------------------------------------------------

toggle_day_night:                                               ; index
				ld      a, (ix+0)
				xor     1                                      ; toggle sun/moon
				ld      (ix+0), a
				call    colour_sun_moon
				ld      (ix+26), 176                            ; pixel X
				ld      a, 1
				ld      (transform_flag_graphic), a
				ld      a, (sun_moon_scratchpad)
				and     1
				ret     NZ

inc_days:
				ld      hl, days
				ld      a, (hl)
				add     a, 1
				daa
				ld      (hl), a
				cp      64
				jp      Z, game_over
				call    print_days
				ld      bc, 0x78 ; 'x'                         ; (120,0)
				call    blit_2x8
				jp      display_frame
; End of function display_sun_moon_frame


; =============== S U B R O U T I N E =======================================


blit_2x8:
				call    screen_calc_addr_de
				call    vidbuf_calc_addr_in_hl
				ld      bc, 0x802
				jp      blit_to_screen
; End of function blit_2x8

; ---------------------------------------------------------------------------
sun_moon_yoff:  DB 5, 6, 7, 8, 9, 0xA, 0xA, 9, 8, 7, 6, 5, 5
sun_moon_scratchpad:DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; =============== S U B R O U T I N E =======================================


init_sun:
				ld      ix, sun_moon_scratchpad
				ld      (ix+0), 0x58 ; 'X'                      ; sprite index
				ld      (ix+26), 176                            ; pixel X
				ld      (ix+27), 9                              ; pixel Y
				ret
; End of function init_sun

; loops through the object table
; copying start X,Y,Z,screen to current

; =============== S U B R O U T I N E =======================================


init_special_objects:
				ld      hl, special_objs_tbl
				ld      a, (seed_1)
				ld      e, a
				ld      a, r
				add     a, e
				ld      e, a

init_obj_loop:
				ld      a, e
				and     7
				or      0x60 ; '`'
				ld      (hl), a                                 ; object graphic no.
				inc     hl                                      ; HL=ptr Start X position
				inc     e
				push    de
				ex      de, hl                                  ; DE=ptr Start X position
				ld      hl, 4
				add     hl, de                                  ; HL=ptr Current X
				ex      de, hl                                  ; DE = ptr Current X
				ld      bc, 4
				ldir                                            ; copy Start X,Y,Z,screen to Current
				ex      de, hl
				push    hl                                      ; save ptr next Current
				ld      bc, special_objs_tbl_end                ; end of object table
				and     a
				sbc     hl, bc                                  ; done table?
				pop     hl
				pop     de
				jr      C, init_obj_loop                        ; no, loop
				ret
; End of function init_special_objects

; ---------------------------------------------------------------------------
; block

upd_62:
				call    upd_6_7
				call    clear_dX_dY
				call    audio_B3E9
				jp      dec_dZ_wipe_and_draw
; ---------------------------------------------------------------------------
; chest

upd_85:
				call    upd_6_7
				call    dec_dZ_and_update_XYZ
				call    is_obj_moving
				ret     Z                                       ; no, return
				jp      audio_B467_wipe_and_draw
; ---------------------------------------------------------------------------
; table

upd_84:
				call    upd_6_7

dec_dZ_upd_XYZ_wipe_if_moving:
				call    dec_dZ_and_update_XYZ
				call    is_obj_moving
				ret     Z
				call    clear_dX_dY
				jp      audio_B467_wipe_and_draw
; tree wall

; =============== S U B R O U T I N E =======================================


upd_128_to_130:
				ld      hl, 0xFEF8                             ; -2, -8
				jr      jp_set_pixel_adj
; End of function upd_128_to_130


; =============== S U B R O U T I N E =======================================


adj_m4_m12:

; FUNCTION CHUNK AT RAM:C4E0 SIZE 00000003 BYTES

				ld      hl, 0xFCF4                             ; -4, -12
				jr      jp_set_pixel_adj
; End of function adj_m4_m12


; =============== S U B R O U T I N E =======================================


adj_m6_m12:
				ld      hl, 0xFAF4                             ; -6, -12
; End of function adj_m6_m12

; START OF FUNCTION CHUNK FOR adj_m4_m12

jp_set_pixel_adj:
				jp      set_pixel_adj
; END OF FUNCTION CHUNK FOR adj_m4_m12
; rock and block

; =============== S U B R O U T I N E =======================================


upd_6_7:
				ld      hl, 0xF8F0                             ; -8, -16
				jr      jp_set_pixel_adj
; End of function upd_6_7

; ---------------------------------------------------------------------------
; bricks

upd_10:                                                         ; -1, -20
				ld      hl, 0xFFEC
				jr      jp_set_pixel_adj
; bricks

; =============== S U B R O U T I N E =======================================


upd_11:
				ld      hl, 0xFEF4                             ; -2, -12
				jr      jp_set_pixel_adj
; End of function upd_11

; bricks

; =============== S U B R O U T I N E =======================================


upd_12_to_15:
				ld      hl, 0xFCF8                             ; -4, -8
				jr      jp_set_pixel_adj
; End of function upd_12_to_15


; =============== S U B R O U T I N E =======================================


adj_m8_m12:
				ld      hl, 0xF8F4                             ; -8, -12
				jr      jp_set_pixel_adj
; End of function adj_m8_m12


; =============== S U B R O U T I N E =======================================


adj_m7_m12:
				ld      hl, 0xF9F4                             ; -7, -12
				jr      jp_set_pixel_adj
; End of function adj_m7_m12


; =============== S U B R O U T I N E =======================================


adj_m12_m12:
				ld      hl, 0xF4F4                             ; -12, -12
				jr      jp_set_pixel_adj
; End of function adj_m12_m12

; ---------------------------------------------------------------------------

upd_88_to_90:                                                   ; -12, -16
				ld      hl, 0xF4F0
				jr      jp_set_pixel_adj

; =============== S U B R O U T I N E =======================================


adj_p7_m12:
				ld      hl, 0x7F4                              ; +7, -12
				jr      jp_set_pixel_adj
; End of function adj_p7_m12


; =============== S U B R O U T I N E =======================================


adj_p3_m12:
				ld      hl, 0x3F4                              ; +3, -12
				jr      jp_set_pixel_adj
; End of function adj_p3_m12


; =============== S U B R O U T I N E =======================================


; HL = starting location
; B = height (lines)
; C = width (bytes)
; A = value					
vidbuf_fill_window:
				; Modify LD below to restore
				ld		(.fill_value + 1), a
				
				; Update DJNZ jump to clear the required number of bytes
				ld		a, c
				inc		a
				add		a, a
				neg
				ld		(.fill_loop + 1), a

				; Calculate in DE the value to add to HL to move to next line
				ld		a, 33
				sub		c
				ld		e, a
				ld		d, 0

				; Account for the initial DJNZ 
				inc		b

				; Restore value in A
.fill_value:	ld		a, 0				; Modified

				; Jump to adjusted DJNZ
				jr		.fill_loop

				ld		(hl), a
				inc		l
				ld		(hl), a
				inc		l
				ld		(hl), a
				inc		l
				ld		(hl), a
				inc		l
				ld		(hl), a
				inc		l
				ld		(hl), a
				add		hl, de
.fill_loop:		djnz	$					; Modified
				ret

; B - Height in lines
; E - Width in bytes
vidbuf_clear_window:
				; Update DJNZ jump to clear the required number of bytes
				ld		a, e
				inc		a
				add		a,a
				neg
				ld		(.clear_loop + 1), a

				; Calculate in DE the value to add to HL to move to next line
				ld		a, 33
				sub		e
				ld		e, a
				ld		d, 0

				; Account for the initial DJNZ 
				inc		b

				; Jump to adjusted DJNZ
				jr		.clear_loop

				ld		(hl), d
				inc		l
				ld		(hl), d
				inc		l
				ld		(hl), d
				inc		l
				ld		(hl), d
				inc		l
				ld		(hl), d
				inc		l
				ld		(hl), d
				add		hl, de
.clear_loop:	djnz	$					; Modified
				ret



; ---------------------------------------------------------------------------
; ghost

upd_80_to_83:
				call    adj_m6_m12
				call    dec_dZ_and_update_XYZ
				ld      a, (ix+9)                                ; dX
				or      (ix+10)                                  ; moving X/Y?
				jr      Z, loc_C5DD                             ; no, skip
				ld      a, (ix+12)
				and     3                                      ; OOB X/Y?
				jr      Z, loc_C5FD                             ; no, continue as-is

loc_C5DD:
				ld      a, (seed_3)
				and     3
				add     a, 4                                   ; rnd(4-7)= +/-3or4
				call    get_delta_from_tbl
				ld      (ix+9), a                                ; set dX
				ld      a, (seed_2)
				and     3
				add     a, 4                                   ; rnd(4-7)= +/-3or4
				call    get_delta_from_tbl
				ld      (ix+10), a                               ; dY
				call    calc_ghost_sprite
				call    audio_B467

loc_C5FD:
				call    toggle_next_prev_sprite
				jp      set_deadly_wipe_and_draw_flags

; =============== S U B R O U T I N E =======================================


calc_ghost_sprite:
				ld      a, (ix+9)                                ; dX
				and     a
				jp      P, loc_C60C
				neg                                             ; abs()

loc_C60C:                                                       ; c=abs(dX)
				ld      c, a
				ld      a, (ix+10)                               ; dY
				and     a
				jp      P, loc_C616
				neg                                             ; abs()

loc_C616:                                                       ; abs(dX)<abs(dY)?
				cp      c
				jr      NC, loc_C62F                            ; yes, go
				ld      a, (ix+9)                                ; dX
				and     a                                       ; negative?
				jp      M, loc_C629                             ; yes, skip
				res     1, (ix+0)                                ; sprite=80/81

set_ghost_hflip:                                                ; hflip
				set     6, (ix+7)
				ret
; ---------------------------------------------------------------------------

loc_C629:                                                       ; sprite=82/83
				set     1, (ix+0)
				jr      set_ghost_hflip
; ---------------------------------------------------------------------------

loc_C62F:                                                       ; dY
				ld      a, (ix+10)
				and     a                                       ; negative?
				jp      M, loc_C63F                             ; yes, skip
				set     1, (ix+0)                                ; sprite=82/83

clr_ghost_hflip:                                                ; hflip
				res     6, (ix+7)
				ret
; ---------------------------------------------------------------------------

loc_C63F:                                                       ; sprite=80/81
				res     1, (ix+0)
				jr      clr_ghost_hflip
; End of function calc_ghost_sprite


; =============== S U B R O U T I N E =======================================


get_delta_from_tbl:
				ld      bc, delta_tbl
				ld      l, a
				ld      h, 0
				add     hl, bc                                  ; ptr entry
				ld      a, (hl)                                 ; get entry
				ret
; End of function get_delta_from_tbl

; ---------------------------------------------------------------------------
delta_tbl:      DB 0xFF, 1, 0xFE, 2, 0xFD, 3, 0xFC, 4, 0xFB, 5, 0xFA
				DB 6, 0xF9, 7, 0xF8, 8
; ---------------------------------------------------------------------------
; portcullis (static)

upd_8:
				call    adj_m6_m12
				ld      hl, portcullis_moving
				ld      a, (hl)
				and     a                                       ; moving?
				ret     NZ                                      ; yes, exit
				ld      a, (room_size_Z)
				cp      (ix+3)                                   ; objZ = room height?
				jr      Z, init_portcullis_up                   ; yes, skip
				add     a, 31
				cp      (ix+3)                                   ; objZ <= room height+31?
				jr      NC, init_portcullis_up                  ; yes, skip
				ld      a, (portcullis_move_cnt)
				cp      4                                      ; moved less than 4 times?
				jr      C, init_portcullis_down                 ; yes, move immediately
				ld      a, (seed_3)
				and     0x1F                                   ; 1in32 chance?
				ret     NZ                                      ; no, return
				or      0x80 ; '�'                             ; arbitrarily large count

init_portcullis_down:
				inc     a
				ld      (portcullis_move_cnt), a
				set     0, (ix+0)                                ; graphic_no=9
				ld      (ix+11), 0xFF                           ; dZ=-1 (down)

loc_C691:                                                       ; flag portculis moving
				inc     (hl)

; =============== S U B R O U T I N E =======================================


set_wipe_and_draw_flags:
				ld      a, (ix+7)                                ; flags
				or      0x30 ; '0'                             ; set WIPE & DRAW
				ld      (ix+7), a
				jp      set_draw_objs_overlapped
; End of function set_wipe_and_draw_flags


; =============== S U B R O U T I N E =======================================


set_wipe_and_draw_IY:
				push    iy
				push    ix
				push    iy
				pop     ix
				call    set_wipe_and_draw_flags
				pop     ix
				pop     iy
				ret
; End of function set_wipe_and_draw_IY

; ---------------------------------------------------------------------------

init_portcullis_up:
				ld      a, (seed_3)
				and     0x1F                                   ; 1in32 chance?
				ret     NZ                                      ; yes, exit
				set     0, (ix+0)                                ; graphic_no=9
				ld      (ix+11), 1                              ; dZ=1 (up)
				jr      loc_C691
; ---------------------------------------------------------------------------
; portcullis (moving)

upd_9:
				call    adj_m6_m12
				set     7, (ix+13)                               ; fatal if it hits player
				ld      a, (graphic_objs_tbl+0xC)
				and     0xF0 ; '�'                             ; entering screen?
				ret     NZ                                      ; yes, exit
				ld      a, (ix+11)                               ; dZ
				and     a                                       ; up?
				jp      P, move_portcullis_up                   ; yes, go
				dec     (ix+11)                                  ; accelerate speed?
				call    dec_dZ_and_update_XYZ
				bit     2, (ix+12)                               ; out of bounds?
				jr      Z, set_wipe_and_draw_flags              ; no, go
				call    audio_B489

stop_portcullis:                                                ; flag not moving
				xor     a
				ld      (portcullis_moving), a
				res     0, (ix+0)                                ; graphic_no=8
				jr      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------

move_portcullis_up:                                             ; dZ
				ld      (ix+11), 2
				call    audio_B467
				call    dec_dZ_and_update_XYZ
				ld      a, (room_size_Z)
				add     a, 31
				cp      (ix+3)                                   ; objZ < room height+31?
				jr      NC, set_wipe_and_draw_flags             ; yes, go
				jr      stop_portcullis

; =============== S U B R O U T I N E =======================================


dec_dZ_and_update_XYZ:
				dec     (ix+11)                                  ; dec dZ?
				call    adj_for_out_of_bounds

add_dXYZ:                                                       ; X
				ld      a, (ix+1)
				add     a, (ix+9)                                ; dX
				ld      (ix+1), a                                ; X+=dX
				ld      a, (ix+2)                                ; Y
				add     a, (ix+10)                               ; dY
				ld      (ix+2), a                                ; y+=dY
				ld      a, (ix+3)                                ; Z
				add     a, (ix+11)                               ; dZ
				ld      (ix+3), a                                ; Z+=dZ
				ret
; End of function dec_dZ_and_update_XYZ

; ---------------------------------------------------------------------------
; arch (far side)

upd_3_5:                                                        ; hflip?
				bit     6, (ix+7)
				jr      NZ, adj_3_5_hflip                       ; yes, go
				ld      hl, 0xFDF7                             ; -3, -9

; =============== S U B R O U T I N E =======================================


set_pixel_adj:
				ld      (ix+18), l                               ; pixel_x adjust
				ld      (ix+19), h                               ; pixel_y adjust
				ret
; End of function set_pixel_adj

; ---------------------------------------------------------------------------

adj_3_5_hflip:                                                  ; -2, -7
				ld      hl, 0xFEF9
				jr      set_pixel_adj
; ---------------------------------------------------------------------------

adj_m3_p1:                                                      ; -3, +1
				ld      hl, 0xFD01
				jr      loc_C74C
; ---------------------------------------------------------------------------
; arch (near side)

upd_2_4:                                                        ; hflip?
				bit     6, (ix+7)
				jr      NZ, adj_2_4_hflip                       ; yes, go
				ld      a, (ix+0)                                ; graphic no.
				cp      4                                      ; tree arch?
				jr      Z, adj_m3_p1                            ; yes, exit
				ld      hl, 0xFDF9                             ; -3, -7

loc_C74C:
				call    set_pixel_adj
				ld      a, (ix+2)                                ; Y
				add     a, 13                                  ; add 13
				ld      (ix+10), a                               ; dY?=Y+13
				ld      a, (ix+1)                                ; X
				ld      (ix+9), a                                ; dX?=X
				ld      hl, 0x60F                              ; +6, +15

loc_C760:                                                       ; Z
				ld      a, (ix+3)
				ld      (ix+11), a                               ; dZ?=Z
				call    chk_plyr_spec_near_arch
				jp      loc_C785
; ---------------------------------------------------------------------------

adj_2_4_hflip:                                                  ; -2, -17
				ld      hl, 0xFEEF
				call    set_pixel_adj
				ld      a, (ix+1)                                ; X
				sub     13
				ld      (ix+9), a                                ; dX
				ld      a, (ix+2)                                ; Y
				ld      (ix+10), a                               ; dY
				ld      hl, 0xF06                              ; +15, +6
				jr      loc_C760
; ---------------------------------------------------------------------------

loc_C785:                                                       ; +15, +15
				ld      hl, 0xF0F
				ld      iy, graphic_objs_tbl
				ld      de, 32                                 ; entry size
				ld      b, 4                                   ; player, special objects only

loc_C791:                                                       ; graphic no.
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, loc_C7D6                             ; yes, skip
				bit     3, (iy+7)
				jr      Z, loc_C7D6
				call    is_near_to
				jr      NC, loc_C7D6
				push    bc
				ld      bc, adj_arch_tbl
				jp      lookup_plyr_dXY                         ; index into table based on sprite dir
; ---------------------------------------------------------------------------
adj_arch_tbl:   DW adj_ew
				DW adj_ew
				DW adj_ns
				DW adj_ns
; ---------------------------------------------------------------------------

adj_ew:                                                         ; dY
				ld      a, (ix+10)
				cp      (iy+2)                                   ; Y
				jr      Z, loc_C7D5
				ld      a, 1
				jr      NC, loc_C7BF
				neg

loc_C7BF:
				ld      (iy+15), a
				jr      loc_C7D5
; ---------------------------------------------------------------------------

adj_ns:                                                         ; dX
				ld      a, (ix+9)
				cp      (iy+1)                                   ; X
				jr      Z, loc_C7D5
				ld      a, 1
				jr      NC, loc_C7D2
				neg

loc_C7D2:
				ld      (iy+14), a

loc_C7D5:
				pop     bc

loc_C7D6:
				add     iy, de
				djnz    loc_C791
				ret

; =============== S U B R O U T I N E =======================================


chk_plyr_spec_near_arch:
				ld      iy, graphic_objs_tbl
				ld      de, 32                                 ; entry size
				ld      b, 4                                   ; player and special objects only

loc_C7E4:                                                       ; graphic no
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, loc_C7F9                             ; yes, skip
				bit     3, (iy+7)                                ; auto-adjust?
				jr      Z, loc_C7F9                             ; no, skip
				call    is_near_to
				jr      NC, loc_C7F9                            ; no, skip
				set     0, (iy+7)                                ; flag near arch

loc_C7F9:                                                       ; next entry
				add     iy, de
				djnz    loc_C7E4                                ; loop through table
				ret
; End of function chk_plyr_spec_near_arch


; =============== S U B R O U T I N E =======================================


is_near_to:
				ld      a, (ix+9)                                ; centre_x
				sub     (iy+1)                                   ; sub X
				jr      NC, loc_C808
				neg

loc_C808:
				cp      l
				ret     NC
				ld      a, (ix+10)                               ; centre_y
				sub     (iy+2)                                   ; sub Y
				jr      NC, loc_C814
				neg

loc_C814:
				cp      h
				ret     NC
				ld      a, (ix+11)                               ; centre_z
				sub     (iy+3)                                   ; sub Z
				jr      NC, loc_C820
				neg

loc_C820:
				cp      4
				ret
; End of function is_near_to

; ---------------------------------------------------------------------------
; sabreman legs

upd_16_to_21_24_to_29:
				call    adj_m6_m12
				jr      upd_player_bottom
; ---------------------------------------------------------------------------
; wulf legs

upd_48_to_53_56_to_61:
				call    adj_m7_m12

upd_player_bottom:                                              ; dead?
				bit     6, (ix+13)
				jr      Z, loc_C83E                             ; no, skip
				ld      a, (all_objs_in_cauldron)
				and     a
				jr      NZ, loc_C83E
				set     6, (ix+0x2D)                             ; set dead top half
				jp      init_death_sparkles
; ---------------------------------------------------------------------------

loc_C83E:                                                       ; returns to caller if transforming
				call    chk_and_init_transform
				call    check_user_input
				call    handle_pickup_drop
				call    handle_left_right
				call    handle_jump
				call    handle_forward
				call    chk_plyr_OOB
				jr      NC, plyr_OOB

loc_C855:                                                       ; fudge near arch
				set     1, (ix+0x27)
				call    move_player                             ; does the moving
				res     1, (ix+0x27)                             ; reset fudge
				ld      a, (ix+12)                               ; flags12
				sub     0x10                                   ; entering room?
				jr      C, loc_C86A                             ; no, skip
				ld      (ix+12), a                               ; dec entering room counter

loc_C86A:
				jp      set_wipe_and_draw_flags
; ---------------------------------------------------------------------------
; when walking through arches

plyr_OOB:                                                       ; dZ
				ld      a, (ix+11)
				and     a                                       ; <0?
				jp      M, loc_C855                             ; yes, go
				xor     a
				ld      (ix+11), a                               ; dZ=0
				jr      loc_C855
;
; returns NC if out-of-bounds

; =============== S U B R O U T I N E =======================================


chk_plyr_OOB:
				ld      hl, (room_size_X)
				ld      a, l                                    ; room_size_X
				sub     (ix+4)                                   ; sub width
				ld      l, a
				ld      a, h                                    ; room_size_Y
				sub     (ix+5)                                   ; sub depth
				ld      h, a
				ld      a, (ix+1)                                ; X
				sub     128
				jp      P, loc_C891
				neg

loc_C891:
				cp      l
				ret     NC                                      ; OOB
				ld      a, (ix+2)                                ; Y
				sub     128
				jp      P, loc_C89D
				neg

loc_C89D:                                                       ; set/clr carry
				cp      h
				ret
; End of function chk_plyr_OOB


; =============== S U B R O U T I N E =======================================


handle_left_right:
				ld      hl, user_input_method
				ld      a, (hl)
				and     6                                      ; joystick/keyboard bits only
				jr      Z, left_right_rotational                ; keybd? yes, skip
				bit     3, (hl)                                 ; directional?
				jr      Z, left_right_rotational
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering screen?
				ret     NZ                                      ; yes, exit
				bit     2, (ix+12)                               ; Z OOB?
				ret     Z                                       ; no, exit
				bit     0, c                                    ; joystick left?
				jr      NZ, loc_C8BE                            ; yes, skip
				bit     2, c                                    ; joystick up?
				jr      NZ, chk_facing_N                        ; yes, skip

loc_C8BE:                                                       ; joystick right?
				bit     1, c
				jr      NZ, chk_facing_E                        ; yes, go
				bit     4, c                                    ; joystick down?
				jr      NZ, chk_facing_S                        ; yes, go
				bit     0, c                                    ; joystick left?
				jr      NZ, chk_facing_W                        ; yes, go
				res     2, c
				ret
; ---------------------------------------------------------------------------

chk_facing_N:
				call    get_sprite_dir
				cp      2                                      ; N?

loc_C8D2:
				jr      Z, flag_forward
				cpl

loc_C8D5:
				and     1
				jr      left_right_calc_sprite
; ---------------------------------------------------------------------------

chk_facing_E:
				call    get_sprite_dir
				cp      1                                      ; E?
				jr      loc_C8D2
; ---------------------------------------------------------------------------

chk_facing_S:
				call    get_sprite_dir
				cp      3                                      ; S?

loc_C8E5:
				jr      Z, flag_forward
				jr      loc_C8D5
; ---------------------------------------------------------------------------

chk_facing_W:
				call    get_sprite_dir
				and     a                                       ; W?
				jr      loc_C8E5
; ---------------------------------------------------------------------------

flag_forward:
				set     2, c
				ret
; ---------------------------------------------------------------------------

left_right_rotational:
				ld      a, (ix+13)
				and     7                                      ; too soon to turn again?
				jr      Z, loc_C8FD                             ; no, skip
				dec     (ix+13)                                  ; dec delay counter
				ret
; ---------------------------------------------------------------------------

loc_C8FD:                                                       ; user input
				ld      a, c
				and     3                                      ; left or right?
				ret     Z                                       ; no, return
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering screen?
				ret     NZ                                      ; yes, exit
				bit     3, (ix+12)                               ; already jumping?
				ret     NZ                                      ; yes, exit
				bit     2, c                                    ; forward?
				jr      NZ, loc_C915                            ; yes, skip
				push    bc
				call    audio_B4C1
				pop     bc

loc_C915:
				ld      a, (ix+13)
				or      2                                      ; init turning delay counter
				ld      (ix+13), a
				bit     1, c                                    ; right?

left_right_calc_sprite:                                         ; yes, skip
				jr      NZ, loc_C940
				bit     6, (ix+7)                                ; hflip?
				jr      NZ, loc_C92F                            ; yes, skip

loc_C927:                                                       ; graphic_no
				ld      a, (ix+0)
				xor     8
				ld      (ix+0), a

loc_C92F:
				ld      a, (ix+7)
				xor     0x40 ; '@'                             ; toggle hflip
				ld      (ix+7), a
				ld      a, (ix+0)                                ; graphic_no
				add     a, 0x10                                ; top half
				ld      (ix+0x20), a                             ; set sprite for top half
				ret
; ---------------------------------------------------------------------------

loc_C940:                                                       ; hflip?
				bit     6, (ix+7)
				jr      NZ, loc_C927                            ; yes, go
				jr      loc_C92F
; End of function handle_left_right


; =============== S U B R O U T I N E =======================================


handle_jump:
				bit     3, c                                    ; jump?
				ret     Z                                       ; no, exit
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering screen?
				ret     NZ                                      ; yes, exit
				bit     3, (ix+12)                               ; already jumping?
				ret     NZ                                      ; yes, exit
				ld      a, (ix+11)                               ; dZ
				inc     a
				ret     M                                       ; return if was <-1
				set     3, (ix+12)                               ; flag jumping
				ld      (ix+11), 8                              ; dZ=8?
				push    bc
				call    audio_B441
				pop     bc
				ret
; End of function handle_jump


; =============== S U B R O U T I N E =======================================


handle_forward:
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering sccreen?
				jr      NZ, loc_C97A                            ; yes, skip
				bit     3, (ix+12)                               ; already jumping?
				jr      NZ, loc_C97A                            ; yes, skip
				bit     2, c                                    ; forward?
				jr      Z, loc_C994                             ; no, go

loc_C97A:
				push    bc
				call    audio_B4BB
				pop     bc

animate_human_legs:                                             ; graphic_no
				ld      a, (ix+0)
				ld      e, a
				inc     a                                       ; next sprite
				and     7
				cp      6                                      ; wrap?
				jr      NZ, loc_C98B                            ; no, skip
				xor     a

loc_C98B:
				ld      d, a
				ld      a, e
				and     0xF8 ; '�'
				or      d
				ld      (ix+0), a                                ; update sprite
				ret
; ---------------------------------------------------------------------------

loc_C994:                                                       ; graphic_no
				ld      a, (ix+0)
				and     7
				cp      2
				ret     Z
				cp      4
				ret     Z
				jr      animate_human_legs
; End of function handle_forward


; =============== S U B R O U T I N E =======================================


move_player:
				ld      a, (obj_dropping_into_cauldron)
				and     a
				jr      Z, loc_C9AB
				ld      (ix+11), 2                              ; dZ=2

loc_C9AB:                                                       ; already jumping?
				bit     3, (ix+12)
				jr      NZ, loc_C9BC                            ; yes, skip
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering screen?
				jr      NZ, loc_C9BC                            ; yes, skip
				bit     2, c                                    ; forward?
				jr      Z, loc_C9C1                             ; no, skip

loc_C9BC:
				push    bc
				call    calc_plyr_dXY
				pop     bc

loc_C9C1:                                                       ; dZ
				ld      a, (ix+11)
				and     a
				jp      M, loc_C9CC
				bit     3, c                                    ; jump?
				jr      NZ, loc_C9CD                            ; yes, skip

loc_C9CC:
				dec     a

loc_C9CD:
				dec     a
				ld      (ix+11), a                               ; dZ
				ld      (tmp_dZ), a
				add     a, 2
				call    M, audio_B451
				call    adj_for_out_of_bounds
				call    handle_exit_screen
				call    add_dXYZ
				bit     2, (ix+12)                               ; Z OOB?
				jr      Z, clear_dX_dY                          ; no, go
				ld      a, (tmp_dZ)
				and     a
				jp      P, clear_dX_dY
				res     3, (ix+12)                               ; clear jumping flag

clear_dX_dY:
				xor     a
				ld      (ix+9), a                                ; dX=0
				ld      (ix+10), a                               ; dY=0
				ret
; End of function move_player


; =============== S U B R O U T I N E =======================================


calc_plyr_dXY:
				ld      a, (ix+9)                                ; dX
				add     a, (ix+14)                               ; dX_adjust
				ld      (ix+9), a
				ld      a, (ix+10)                               ; dY
				add     a, (ix+15)                               ; dY_adj
				ld      (ix+10), a
				xor     a
				ld      (ix+14), a                               ; zap adjustment
				ld      (ix+15), a                               ; zap adjustment
				ld      bc, off_CA32

lookup_plyr_dXY:
				call    get_sprite_dir
				ld      l, a
				jp      jump_to_tbl_entry
; End of function calc_plyr_dXY


; =============== S U B R O U T I N E =======================================


get_sprite_dir:
				ld      a, (ix+7)                                ; flags
				rrca
				rrca
				and     0x10                                   ; hflip
				ld      l, a
				ld      a, (ix+0)                                ; graphic no.
				and     8
				or      l                                       ; bits 4,3
				rrca
				rrca
				rrca
				and     3                                      ; 1=hflip, 0=graphic no & 8
				ret
; End of function get_sprite_dir

; ---------------------------------------------------------------------------
off_CA32:       DW move_plyr_W                                 ; dX -= 3
				DW move_plyr_E                                 ; dX += 3
				DW move_plyr_N                                 ; dY += 3
				DW move_plyr_S                                 ; dY -= 3
; ---------------------------------------------------------------------------

move_plyr_W:                                                    ; dX
				ld      a, (ix+9)
				add     a, 0xFD ; '�'                          ; -3

loc_CA3F:
				ld      (ix+9), a
				ret
; ---------------------------------------------------------------------------

move_plyr_E:                                                    ; dX
				ld      a, (ix+9)
				add     a, 3                                   ; +3
				jr      loc_CA3F
; ---------------------------------------------------------------------------

move_plyr_N:                                                    ; dY
				ld      a, (ix+10)
				add     a, 3                                   ; +3

loc_CA4F:
				ld      (ix+10), a
				ret
; ---------------------------------------------------------------------------

move_plyr_S:                                                    ; dY
				ld      a, (ix+10)
				add     a, 0xFD ; '�'                          ; -3
				jr      loc_CA4F

; =============== S U B R O U T I N E =======================================


adj_dZ_for_out_of_bounds:
				ld      a, (room_size_Z)
				ld      d, a

loc_CA5E:                                                       ; Z
				ld      a, (ix+3)
				add     a, h                                    ; Z+=dZ
				cp      d                                       ; >= room height?
				ret     NC                                      ; yes, return
				set     2, (ix+12)
				ld      a, h                                    ; Z+dZ
				call    adj_d_for_out_of_bounds
				ld      h, a                                    ; new dZ
				jr      NZ, loc_CA5E                            ; check again
				ret
; End of function adj_dZ_for_out_of_bounds


; =============== S U B R O U T I N E =======================================


handle_exit_screen:
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering room?
				ret     NZ                                      ; yes, exit
				bit     0, (ix+7)                                ; near an arch?
				ret     Z                                       ; no, return
				res     0, (ix+7)                                ; reset flag
				ld      bc, screen_move_tbl
				ld      hl, (room_size_X)
				push    hl
				jp      lookup_plyr_dXY
; End of function handle_exit_screen

; adjust dX/dY/dZ when out of bounds
; A = dX/dY/dZ

; =============== S U B R O U T I N E =======================================


adj_d_for_out_of_bounds:
				and     a                                       ; zero?
				ret     Z                                       ; yes, exit
				jp      P, loc_CA90                             ; skip if >0
				inc     a
				inc     a

loc_CA90:
				dec     a
				ret
; End of function adj_d_for_out_of_bounds

; ---------------------------------------------------------------------------
screen_move_tbl:DW screen_west
				DW screen_east
				DW screen_north
				DW screen_south
; ---------------------------------------------------------------------------

screen_west:
				pop     hl
				ld      a, 128
				sub     l                                       ; room_size_X
				ld      l, a
				ld      a, (ix+1)                                ; X
				add     a, (ix+9)                                ; +dX
				add     a, (ix+4)                                ; +width
				cp      l
				ret     NC
				ld      (ix+1), 0                               ; X
				ld      a, (ix+8)                                ; screen
				ld      l, a
				dec     a                                       ; screen to the west

screen_e_w:                                                     ; low nibble
				and     0xF
				ld      h, a
				ld      a, l
				and     0xF0 ; '�'                             ; high nibble - don't change row
				or      h                                       ; same row - wraps???

exit_screen:                                                    ; store new screen
				ld      (ix+8), a
				ld      a, (ix+12)                               ; flags12
				or      0x30 ; '0'                             ; init enter room counter
				ld      (ix+12), a                               ; save
				ld      a, (ix+0)                                ; graphic no.
				sub     0x10
				cp      0x40 ; '@'                             ; wulf?
				ret     NC                                      ; WHY is wulf handled differently???
				inc     sp
				inc     sp
				inc     sp
				inc     sp
				push    ix
				pop     hl
				ld      de, plyr_spr_1_scratchpad
				ld      bc, 64
				ldir
				ld      a, (plyr_spr_1_scratchpad)              ; graphic no.
				ld      (byte_D171), a
				ld      a, (plyr_spr_2_scratchpad)              ; graphic no.
				ld      (byte_D191), a
				ld      a, 120                                 ; sparkly transform 1
				ld      (plyr_spr_1_scratchpad), a              ; graphic no.
				ld      (plyr_spr_2_scratchpad), a              ; graphic no.
				jp      game_loop
; ---------------------------------------------------------------------------

screen_east:
				pop     hl
				ld      a, l
				add     a, 128
				ld      l, a                                    ; room_size_X + 128
				ld      a, (ix+1)                                ; X
				add     a, (ix+9)                                ; +dX
				sub     (ix+4)                                   ; -width
				cp      l
				ret     C
				ld      (ix+1), 0xFF                            ; X
				ld      a, (ix+8)                                ; screen
				ld      l, a
				inc     a                                       ; screen to the east
				jr      screen_e_w
; ---------------------------------------------------------------------------

screen_north:
				pop     hl
				ld      a, h                                    ; room_size_Y
				add     a, 128
				ld      h, a
				ld      a, (ix+2)                                ; Y
				add     a, (ix+10)                               ; +dY
				sub     (ix+5)                                   ; -depth
				cp      h
				ret     C
				ld      (ix+2), 0xFF                            ; Y
				ld      a, (ix+8)                                ; screen
				add     a, 16                                  ; screen to the north
				jr      exit_screen
; ---------------------------------------------------------------------------

screen_south:
				pop     hl
				ld      a, 128
				sub     h                                       ; room_size_Y
				ld      h, a
				ld      a, (ix+2)                                ; Y
				add     a, (ix+10)                               ; +dY
				add     a, (ix+5)                                ; +depth
				cp      h
				ret     NC
				ld      (ix+2), 0                               ; Y
				ld      a, (ix+8)                                ; screen
				sub     16                                     ; screen to the south
				jp      exit_screen

; =============== S U B R O U T I N E =======================================


adj_for_out_of_bounds:
				bit     1, (ix+7)
				ret     NZ
				set     1, (ix+7)
				ld      a, (ix+12)
				and     0xF8 ; '�'                             ; clear X,Y,Z OOB
				ld      (ix+12), a
				ld      l, 0
				ld      c, l
				ld      a, (ix+11)                               ; dZ
				and     a                                       ; zero?
				ld      h, a
				jr      Z, dZ_ok                                ; yes, skip
				call    adj_dZ_for_out_of_bounds
				ld      a, h                                    ; new dZ
				and     a                                       ; zero?
				jr      Z, dZ_ok                                ; yes, skip
				call    adj_dZ_for_obj_intersect

dZ_ok:                                                          ; dX
				ld      a, (ix+9)
				and     a                                       ; zero?
				ld      c, a
				jr      Z, loc_CB7B                             ; yes, skip
				call    adj_dX_for_out_of_bounds
				ld      a, c                                    ; new dX
				and     a                                       ; zero?
				jr      Z, loc_CB7B                             ; yes, skip
				call    adj_dX_for_obj_intersect

loc_CB7B:                                                       ; dY
				ld      a, (ix+10)
				and     a                                       ; zero?
				ld      l, a
				jr      Z, loc_CB8C                             ; yes, skip
				call    adj_dY_for_out_of_bounds
				ld      a, l                                    ; new dY
				and     a                                       ; zero?
				jr      Z, loc_CB8C                             ; yes, skip
				call    adj_dY_for_obj_intersect

loc_CB8C:                                                       ; new dX
				ld      (ix+9), c
				ld      (ix+10), l                               ; new dY
				ld      (ix+11), h                               ; new dZ
				res     1, (ix+7)
				ret
; End of function adj_for_out_of_bounds


; =============== S U B R O U T I N E =======================================


adj_dX_for_obj_intersect:
				ld      iy, graphic_objs_tbl
				ld      b, 40                                  ; max objects

loc_CBA0:
				call    is_object_not_ignored
				jr      Z, loc_CBE1                             ; ignored, skip
				call    do_objs_intersect_on_y
				jr      NC, loc_CBE1
				call    do_objs_intersect_on_z
				jr      NC, loc_CBE1

loc_CBAF:
				call    do_objs_intersect_on_x
				jr      NC, loc_CBE1
				set     0, (ix+12)                               ; set X OOB
				ld      a, (ix+13)
				rrca
				and     0x40 ; '@'                             ; bit 7->6
				or      (iy+13)                                  ; obj2 destroyed?
				ld      (iy+13), a
				rlca
				and     0x40 ; '@'                             ; bit 5->6
				or      (ix+13)                                  ; obj1 destroyed?
				ld      (ix+13), a
				bit     2, (iy+7)                                ; moveable?
				jr      Z, loc_CBD9                             ; no, skip
				ld      a, (ix+9)
				ld      (iy+9), a                                ; copy dX

loc_CBD9:
				ld      a, c
				call    adj_d_for_out_of_bounds
				ld      c, a
				ret     Z
				jr      loc_CBAF
; ---------------------------------------------------------------------------

loc_CBE1:                                                       ; entry size
				ld      de, 32
				add     iy, de                                  ; next entry
				djnz    loc_CBA0
				ret
; End of function adj_dX_for_obj_intersect


; =============== S U B R O U T I N E =======================================


adj_dY_for_obj_intersect:
				ld      iy, graphic_objs_tbl
				ld      b, 40                                  ; max objects

loc_CBEF:
				call    is_object_not_ignored
				jr      Z, loc_CC30                             ; next entry
				call    do_objs_intersect_on_x
				jr      NC, loc_CC30                            ; next entry
				call    do_objs_intersect_on_z
				jr      NC, loc_CC30                            ; next entry

loc_CBFE:
				call    do_objs_intersect_on_y
				jr      NC, loc_CC30                            ; next entry
				set     1, (ix+12)                               ; set Y OOB
				ld      a, (ix+13)
				rrca
				and     0x40 ; '@'                             ; bit 7->6
				or      (iy+13)                                  ; obj2 destroyed?
				ld      (iy+13), a
				rlca
				and     0x40 ; '@'                             ; bit 5->6
				or      (ix+13)                                  ; obj1 destroyed?
				ld      (ix+13), a
				bit     2, (iy+7)                                ; moveable?
				jr      Z, loc_CC28                             ; no, skip
				ld      a, (ix+10)
				ld      (iy+10), a                               ; copy dY

loc_CC28:
				ld      a, l
				call    adj_d_for_out_of_bounds
				ld      l, a
				ret     Z
				jr      loc_CBFE
; ---------------------------------------------------------------------------

loc_CC30:                                                       ; entry size
				ld      de, 32
				add     iy, de                                  ; next entry
				djnz    loc_CBEF                                ; loop through table
				ret
; End of function adj_dY_for_obj_intersect


; =============== S U B R O U T I N E =======================================


adj_dZ_for_obj_intersect:
				ld      iy, graphic_objs_tbl
				ld      b, 40                                  ; max objects

loc_CC3E:
				call    is_object_not_ignored
				jr      Z, loc_CC95                             ; next entry
				call    do_objs_intersect_on_x
				jr      NC, loc_CC95                            ; next entry
				call    do_objs_intersect_on_y
				jr      NC, loc_CC95                            ; next entry

loc_CC4D:
				call    do_objs_intersect_on_z
				jr      NC, loc_CC95                            ; next entry
				set     2, (ix+12)                               ; set Z OOB
				ld      a, (ix+13)
				rrca
				and     0x40 ; '@'                             ; bit 7->6
				or      (iy+13)                                  ; obj2 destroyed?
				ld      (iy+13), a
				rlca
				and     0x40 ; '@'                             ; bit 5->6
				or      (ix+13)                                  ; obj1 destroyed?
				ld      (ix+13), a
				set     3, (iy+13)                               ; triggered (falling, collapsing blocks)
				bit     2, (ix+7)                                ; moveable?
				jr      Z, loc_CC8D                             ; no, skip
				ld      a, (ix+9)                                ; dX
				and     a                                       ; zero?
				jr      NZ, loc_CC81                            ; no, skip
				ld      a, (iy+9)
				ld      (ix+9), a                                ; copy dX

loc_CC81:                                                       ; objdY
				ld      a, (ix+10)
				and     a                                       ; moving along Y?
				jr      NZ, loc_CC8D                            ; yes, skip
				ld      a, (iy+10)
				ld      (ix+10), a                               ; copy dY

loc_CC8D:
				ld      a, h
				call    adj_d_for_out_of_bounds
				ld      h, a
				ret     Z
				jr      loc_CC4D
; ---------------------------------------------------------------------------

loc_CC95:                                                       ; entry size
				ld      de, 32
				add     iy, de                                  ; next entry
				djnz    loc_CC3E                                ; loop through table
				ret
; End of function adj_dZ_for_obj_intersect


; =============== S U B R O U T I N E =======================================


do_objs_intersect_on_x:
				ld      a, (ix+4)                                ; objW (width)
				add     a, (iy+4)                                ; thisW
				ld      d, a                                    ; objW+thisW
				ld      a, (ix+1)                                ; obj X
				add     a, c                                    ; new dX
				sub     (iy+1)                                   ; objX + newdX - thisX
				jp      P, loc_CCB0
				neg                                             ; abs()

loc_CCB0:                                                       ; abs(objX+newdX-thisX)-(objW+thisW)
				sub     d
				ret                                             ; C flag set indicates intersection
; End of function do_objs_intersect_on_x


; =============== S U B R O U T I N E =======================================


do_objs_intersect_on_y:
				ld      a, (ix+5)                                ; objD (depth)
				add     a, (iy+5)                                ; thisD
				ld      d, a                                    ; (objD+thisD)
				ld      a, (ix+2)                                ; objY
				add     a, l
				sub     (iy+2)                                   ; (objY+new dY-thisY)
				jp      P, loc_CCC5
				neg                                             ; abs()

loc_CCC5:                                                       ; (objY+l+thisY)-(objD+thisD)
				sub     d
				ret                                             ; C flag set indicates intersection
; End of function do_objs_intersect_on_y


; =============== S U B R O U T I N E =======================================


do_objs_intersect_on_z:
				ld      a, (ix+3)                                ; objZ
				add     a, h
				sub     (iy+3)                                   ; (objZ+new dZ-thisZ)
				jp      P, loc_CCD8
				neg                                             ; abs()
				ld      d, (ix+6)                                ; objH (height)

loc_CCD6:                                                       ; (objZ+H-thisZ)-(objH or thisH)
				sub     d
				ret                                             ; C flag set indicates intersection
; ---------------------------------------------------------------------------

loc_CCD8:                                                       ; thisH (height)
				ld      d, (iy+6)
				jr      loc_CCD6
; End of function do_objs_intersect_on_z


; =============== S U B R O U T I N E =======================================


adj_dX_for_out_of_bounds:
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering room?
				ret     NZ                                      ; yes, exit
				bit     0, (ix+7)                                ; near an arch?
				ret     NZ                                      ; yes, exit
				ld      a, (room_size_X)
				ld      b, a

loc_CCEC:                                                       ; X
				ld      a, (ix+1)
				add     a, c                                    ; +dX
				sub     128
				jr      NC, loc_CCF6
				neg

loc_CCF6:                                                       ; X+dX+width
				add     a, (ix+4)
				cp      b                                       ; < room width?
				jr      C, dX_ok                                ; yes, skip
				set     0, (ix+12)                               ; set X OOB
				ld      a, c                                    ; dX
				call    adj_d_for_out_of_bounds
				ld      c, a                                    ; new dX
				jr      NZ, loc_CCEC                            ; check again

dX_ok:
				ret
; End of function adj_dX_for_out_of_bounds


; =============== S U B R O U T I N E =======================================


adj_dY_for_out_of_bounds:
				ld      a, (ix+12)                               ; flags12
				and     0xF0 ; '�'                             ; entering room?
				ret     NZ                                      ; yes, exit
				bit     0, (ix+7)                                ; near and arch?
				ret     NZ                                      ; yes, exit
				ld      a, (room_size_Y)
				ld      b, a

loc_CD17:                                                       ; Y
				ld      a, (ix+2)
				add     a, l                                    ; +dY
				sub     128
				jr      NC, loc_CD21
				neg

loc_CD21:                                                       ; Y+dY+depth
				add     a, (ix+5)
				cp      b                                       ; < room depth?
				jr      C, dY_ok                                ; yes, skip
				set     1, (ix+12)                               ; set Y OOB
				ld      a, l                                    ; dY
				call    adj_d_for_out_of_bounds
				ld      l, a                                    ; new dY
				jr      NZ, loc_CD17                            ; check again

dY_ok:
				ret
; End of function adj_dY_for_out_of_bounds


; =============== S U B R O U T I N E =======================================


calc_2d_info:
				call    calc_pixel_XY
				call    flip_sprite
				ld      a, (ix+26)                               ; pixel X
				and     7                                      ; bit offset
				ld      a, (de)                                 ; ptr sprite data (width)
				inc     de                                      ; ptr height
				jr      Z, loc_CD43
				inc     a

loc_CD43:
				and     0xF
				ld      (ix+24), a                               ; sprite data width (bytes)
				ld      a, (de)
				ld      (ix+25), a                               ; sprite data height
				ret
; End of function calc_2d_info


; =============== S U B R O U T I N E =======================================


set_draw_objs_overlapped:
				ld      iy, graphic_objs_tbl
				call    calc_2d_info
				ld      b, 40                                  ; max objects
				ld      a, (ix+26)                               ; pixelX
				rrca
				rrca
				rrca
				and     0x1F                                   ; byte address
				ld      l, a
				ld      a, (ix+30)                               ; old pixelX
				rrca
				rrca
				rrca
				and     0x1F                                   ; bytes address
				ld      h, a
				cp      l
				jr      C, loc_CD6C
				ld      a, l

loc_CD6C:                                                       ; left extremity (byte address)
				ld      e, a
				ld      a, l                                    ; byte address
				add     a, (ix+24)                               ; + data width (bytes)
				ld      l, a
				ld      a, h                                    ; old byte address
				add     a, (ix+28)                               ; + old data width bytes
				cp      l
				jr      NC, loc_CD7A
				ld      a, l

loc_CD7A:                                                       ; combined width old & new
				sub     e
				ld      d, a
				ld      a, (ix+27)                               ; pixel Y
				cp      (ix+31)                                  ; old pixelY
				jr      C, loc_CD87
				ld      a, (ix+31)                               ; old pixelY

loc_CD87:                                                       ; lowest Y
				ld      l, a
				ld      a, (ix+27)                               ; pixel Y
				add     a, (ix+25)                               ; + data height (lines)
				ld      h, a
				ld      a, (ix+31)                               ; old pixelY
				add     a, (ix+29)                               ; + old data height (lines)
				cp      h
				jr      NC, loc_CD99
				ld      a, h

loc_CD99:
				sub     l
				ld      h, a                                    ; combined height (lines)

test_overlap_obj:                                               ; graphic_no
				ld      a, (iy+0)
				and     a                                       ; null?
				jr      Z, next_overlap_obj                     ; yes, skip
				bit     4, (iy+7)                                ; DRAW flag already set?
				jr      NZ, next_overlap_obj                    ; yes, skip
				ld      a, (iy+26)                               ; pixel X
				rrca
				rrca
				rrca
				and     0x1F                                   ; byte address of pixel
				sub     e                                       ; < left extremity (to the left)?
				jr      C, loc_CDCC                             ; yes, go
				cp      d                                       ; < right extermity (overlapping)?

loc_CDB3:                                                       ; no, skip
				jr      NC, next_overlap_obj
				ld      a, (iy+27)                               ; pixel Y
				sub     l                                       ; < lowest Y (below)?
				jr      C, loc_CDD3                             ; yes, go
				cp      h                                       ; < height (overlapping)?

loc_CDBC:                                                       ; no, skip
				jr      NC, next_overlap_obj
				set     4, (iy+7)                                ; set DRAW flag

next_overlap_obj:
				exx
				ld      de, 32                                 ; entry size
				add     iy, de                                  ; next entry
				exx
				djnz    test_overlap_obj
				ret
; ---------------------------------------------------------------------------

loc_CDCC:
				neg
				cp      (iy+24)                                  ; data width (bytes)
				jr      loc_CDB3
; ---------------------------------------------------------------------------

loc_CDD3:
				neg
				cp      (iy+25)                                  ; data height (lines)
				jr      loc_CDBC
; End of function set_draw_objs_overlapped

; ---------------------------------------------------------------------------
; player (human top half)

upd_32_to_47:
				call    adj_m8_m12
				jr      upd_player_top
; ---------------------------------------------------------------------------
; player (wulf top half)

upd_64_to_79:
				call    adj_m12_m12
;
; copies most information from bottom half object
; handles randomly looking around

upd_player_top:
				ld      a, (all_objs_in_cauldron)
				and     a
				jr      NZ, loc_CDEF
				bit     6, (ix+13)
				jp      NZ, init_death_sparkles

loc_CDEF:
				push    ix
				pop     de                                      ; DE=top
				ld      hl, 0xFFE0                             ; -32
				add     hl, de
				push    hl                                      ; HL=bottom
				pop     iy                                      ; IY=player bottom half
				inc     de                                      ; DE=top+1
				inc     hl                                      ; HL=bottom+1
				ld      bc, 7
				ldir                                            ; copy x,y,z,w,d,h,flags
				ld      (ix+6), 0                               ; height (top)
				set     1, (ix+7)                                ; ignore in 3D calcs
				ld      a, (ix+13)                               ; flags13
				and     0xF                                    ; look around counter
				jr      Z, loc_CE14                             ; maybe look around again?
				dec     (ix+13)                                  ; dec look around counter
				jr      loc_CE27
; ---------------------------------------------------------------------------

loc_CE14:                                                       ; look in a random direction
				ld      a, (seed_3)
				cp      2                                      ; one way?
				jr      C, loc_CE33                             ; yes, go
				cp      0xFE ; '�'                             ; other way?
				jr      NC, loc_CE40                            ; yes, go
				ld      a, (iy+0)                                ; straight ahead

set_top_sprite:
				add     a, 16
				ld      (ix+0), a                                ; graphic_no (top half)

loc_CE27:                                                       ; Z (bottom half)
				ld      a, (iy+3)
				add     a, 12                                  ; directly above
				ld      (ix+3), a                                ; store in top half
				call    set_draw_objs_overlapped
				ret
; ---------------------------------------------------------------------------

loc_CE33:                                                       ; graphic_no (bottom half)
				ld      a, (iy+0)
				and     0xF8 ; '�'
				or      6                                      ; look one way

loc_CE3A:                                                       ; look for 8 iterations
				ld      (ix+13), 8
				jr      set_top_sprite
; ---------------------------------------------------------------------------

loc_CE40:
				ld      a, (iy+0)
				and     0xF8 ; '�'
				or      7                                      ; look the other way
				jr      loc_CE3A

; =============== S U B R O U T I N E =======================================


save_2d_info:
				ld      a, (ix+24)                               ; data width (bytes)
				ld      (ix+28), a
				ld      a, (ix+25)                               ; data height (lines)
				ld      (ix+29), a
				ld      a, (ix+26)                               ; pixel X
				ld      (ix+30), a
				ld      a, (ix+27)                               ; pixel Y
				ld      (ix+31), a
				ret
; End of function save_2d_info


; =============== S U B R O U T I N E =======================================


list_objects_to_draw:
				push    ix
				ld      b, 40                                  ; max 40 objects in list
				ld      de, 32                                 ; object size = 32 bytes
				ld      ix, graphic_objs_tbl                   ; base of object table
				ld      hl, objects_to_draw
				ld      c, 0                                   ; init object index

loc_CE72:                                                       ; graphic no.
				ld      a, (ix+0)
				and     a                                       ; null?
				jr      Z, loc_CE80                             ; yes, skip
				bit     4, (ix+7)                                ; draw flag set?
				jr      Z, loc_CE80                             ; no, skip
				ld      (hl), c                                 ; add object index to list
				inc     hl                                      ; ptr next list address

loc_CE80:                                                       ; next object index
				inc     c
				add     ix, de                                  ; ptr next object in table
				djnz    loc_CE72                                ; loop through all objects
				ld      a, 0xFF
				ld      (hl), a                                 ; flag end of list
				pop     ix
				ret
; End of function list_objects_to_draw

; ---------------------------------------------------------------------------
objects_to_draw:DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; =============== S U B R O U T I N E =======================================


calc_display_order_and_render:
				xor     a
				ld      (rendered_objs_cnt), a
				push    ix
				push    iy

process_remaining_objs:
				ld      de, objects_to_draw

loc_CEC6:                                                       ; graphic no.
				ld      a, (de)
				inc     de
				cp      0xFF                                   ; end of list?
				jp      Z, render_done                          ; yes, exit
				bit     7, a                                    ; already rendered?
				jr      NZ, loc_CEC6                            ; yes, skip
				call    get_ptr_object                          ; ret=HL
				ld      (render_obj_1), de
				push    hl
				pop     ix                                      ; IX=ptr graphic object table entry 1

loc_CEDB:                                                       ; next object graphic no.
				ld      a, (de)
				inc     de
				cp      0xFF                                   ; end of list?
				jp      Z, render_obj_no1
				bit     7, a
				jr      NZ, loc_CEDB
				call    get_ptr_object
				ld      (render_obj_2), de
				push    hl
				pop     iy                                      ; HL,IY=ptr graphic object table entry 2
				push    ix
				pop     bc                                      ; IX,BC=ptr graphic object table entry 1
				and     a
				sbc     hl, bc                                  ; same objects?
				jr      Z, loc_CEDB                             ; yes, loop
				ld      c, 0
				ld      a, (iy+3)                                ; Z2
				add     a, (iy+6)                                ; add height(H2)
				ld      l, a                                    ; Z2+H2
				ld      a, (ix+3)                                ; Z1
				sub     l                                       ; Z1-(Z2+H2)
				jr      NC, loc_CF16                            ; no overlap (C+=0)
				ld      a, (ix+3)                                ; Z1
				add     a, (ix+6)                                ; add H1
				ld      l, a
				ld      a, (iy+3)                                ; Z2
				sub     l                                       ; Z2-(Z1+H1)
				jr      C, loc_CF15                             ; overlap (C+=1)
				inc     c                                       ; no overlap (C+=2)

loc_CF15:
				inc     c

loc_CF16:                                                       ; Y2
				ld      a, (iy+2)
				add     a, (iy+5)                                ; add depth (D2)
				ld      l, a
				ld      a, (ix+2)                                ; Y1
				sub     (ix+5)                                   ; sub D1
				sub     l                                       ; Y1-D1-(Y2+d2)
				jr      NC, loc_CF3C                            ; no overlap (C+=0)
				ld      a, (ix+2)                                ; Y1
				add     a, (ix+5)                                ; add D1
				ld      l, a
				ld      a, (iy+2)                                ; Y2
				sub     (iy+5)                                   ; sub D2
				sub     l                                       ; Y2-D2-(Y1+D1)
				ld      a, c
				jr      C, loc_CF39                             ; overlap (C+=3)
				add     a, 3                                   ; no overlap (C+=6)

loc_CF39:
				add     a, 3
				ld      c, a

loc_CF3C:                                                       ; X2
				ld      a, (iy+1)
				add     a, (iy+4)                                ; add width (W2)
				ld      l, a
				ld      a, (ix+1)                                ; X1
				sub     (ix+4)                                   ; sub W1
				sub     l                                       ; X1-W1-(X2+W2)
				jr      NC, loc_CF62                            ; no overlap (C+=0)
				ld      a, (ix+1)                                ; X1
				add     a, (ix+4)                                ; add W1
				ld      l, a
				ld      a, (iy+1)                                ; X2
				sub     (iy+4)                                   ; sub W2
				sub     l                                       ; X2-W2-(X1+W1)
				ld      a, c
				jr      C, loc_CF5F                             ; overlap (C+=9)
				add     a, 9                                   ; no overlap (c+=18)

loc_CF5F:
				add     a, 9
				ld      c, a

loc_CF62:
				ld      l, c
				ld      bc, off_CF69                           ; jump table
				jp      jump_to_tbl_entry
; ---------------------------------------------------------------------------
off_CF69:       DW continue_1
				DW continue_1
				DW continue_1
				DW d_3467121516
				DW d_3467121516
				DW continue_1
				DW d_3467121516
				DW d_3467121516
				DW continue_1
				DW continue_1
				DW continue_2
				DW continue_2
				DW d_3467121516
				DW objs_coincide
				DW continue_2
				DW d_3467121516
				DW d_3467121516
				DW continue_1
				DW continue_1
				DW continue_2
				DW continue_2
				DW continue_1
				DW continue_2
				DW continue_2
				DW continue_1
				DW continue_1
				DW continue_1
; ---------------------------------------------------------------------------

continue_1:
				jp      loc_CEDB
; ---------------------------------------------------------------------------

continue_2:
				jp      loc_CEDB
; ---------------------------------------------------------------------------

d_3467121516:                                                   ; object following obj2
				ld      hl, (render_obj_2)
				dec     hl                                      ; ptr obj2
				ld      c, (hl)                                 ; index
				ld      de, render_list

loc_CFAD:
				ld      a, (de)
				cp      0xFF                                   ; empty entry?
				jr      Z, loc_CFB8                             ; yes, go
				cp      c                                       ; already listed?
				jr      Z, loc_CFCE                             ; yes, go
				inc     de                                      ; next entry
				jr      loc_CFAD                                ; loop
; ---------------------------------------------------------------------------

loc_CFB8:                                                       ; index
				ld      a, c
				ld      (de), a                                 ; add to list
				inc     de                                      ; next entry
				ld      a, 0xFF
				ld      (de), a                                 ; flag empty
				push    iy
				pop     ix                                      ; obj2=obj1
				ld      hl, (render_obj_2)                      ; object following obj2
				ld      (render_obj_1), hl                      ; set to object following 1
				ld      de, objects_to_draw
				jp      loc_CEDB                                ; go again
; ---------------------------------------------------------------------------

loc_CFCE:
				ld      hl, objects_to_draw

loc_CFD1:                                                       ; graphic_no
				ld      a, (hl)
				inc     hl
				cp      0xFF                                   ; end of list?
				jp      Z, process_remaining_objs               ; yes, exit
				cp      c                                       ; what we're looking for?
				jr      NZ, loc_CFD1                            ; no, loop
				push    iy
				pop     ix                                      ; obj2=obj1
				jr      render_obj
; ---------------------------------------------------------------------------

objs_coincide:                                                  ; obj1 graphic no.
				ld      a, (ix+0)
				sub     0x60 ; '`'
				cp      7                                      ; special object?
				jr      NC, loc_CFF0                            ; no, skip
				ld      (ix+0), 187                             ; set to twinkle sprite
				jr      loc_CFFD
; ---------------------------------------------------------------------------

loc_CFF0:                                                       ; object 2 graphic no.
				ld      a, (iy+0)
				sub     0x60 ; '`'
				cp      7                                      ; special object?
				jr      NC, loc_CFFD                            ; no, skip
				ld      (iy+0), 187                             ; set to twinkle sprite

loc_CFFD:                                                       ; continue
				jp      loc_CEDB
; ---------------------------------------------------------------------------

render_obj_no1:
				ld      hl, (render_obj_1)

render_obj:                                                     ; back to entry we're searching for
				dec     hl
				set     7, (hl)                                 ; flag as rendered
				ld      a, 0xFF
				ld      (render_list), a                        ; set entry to empty
				ld      hl, rendered_objs_cnt
				inc     (hl)
				call    calc_pixel_XY_and_render                ; render object to video buffer
				jp      process_remaining_objs                  ; restart processing again
; ---------------------------------------------------------------------------

render_done:
				pop     iy
				pop     ix
				ret
; End of function calc_display_order_and_render

; ---------------------------------------------------------------------------
render_list:    DB 0xFF
				DB 0xFF
				DB 0xFF
				DB 0xFF
				DB 0xFF
				DB 0xFF
				DB 0xFF
				DB 0xFF

; =============== S U B R O U T I N E =======================================


check_user_input:
				ld      a, (all_objs_in_cauldron)
				ld      c, a
				ld      a, (obj_dropping_into_cauldron)
				or      c
				ld      c, 0
				jp      NZ, finished_input
				ld      a, (user_input_method)
				rrca
				and     3                                      ; keybd/joystick bits only
				jp      Z, keyboard
				dec     a
				jr      Z, kempston
				dec     a
				jr      Z, cursor

interface_ii:                                                   ; address interface ii joystick
				ld      a, 0xF7 ; '�'
				call    read_port                               ; read joystick
				push    bc
				ld      b, 5                                   ; 5 bits to read

loc_D046:
				rra
				rl      c                                       ; reverse bit order
				djnz    loc_D046                                ; loop thru all bits
				ld      a, c
				pop     bc
				ld      c, a                                    ; store joystick reading
				ld      a, 0xEF ; '�'                          ; 0,9,8,7,6
				call    read_port
				or      c                                       ; add joystick bits
				ld      c, 0
				bit     0, a                                    ; 0/left???
				jr      Z, loc_D05C
				set     3, c

loc_D05C:
				bit     1, a
				jr      Z, loc_D062
				set     2, c

loc_D062:
				bit     2, a
				jr      Z, loc_D068
				set     4, c

loc_D068:
				bit     3, a
				jr      Z, loc_D06E
				set     1, c

loc_D06E:
				bit     4, a
				jr      Z, loc_D074
				set     0, c

loc_D074:
				jp      finished_input
; ---------------------------------------------------------------------------

kempston:
				in      a, (0x1F)
				ld      c, 0
				bit     0, a                                    ; right?
				jr      Z, loc_D081
				set     1, c                                    ; flag RIGHT

loc_D081:                                                       ; left?
				bit     1, a
				jr      Z, loc_D087
				set     0, c                                    ; flag LEFT

loc_D087:                                                       ; down?
				bit     2, a
				jr      Z, loc_D08D
				set     4, c                                    ; flag PICKUP/DROP

loc_D08D:                                                       ; up?
				bit     3, a
				jr      Z, loc_D093
				set     2, c                                    ; flag FORWARD

loc_D093:                                                       ; fire?
				bit     4, a
				jr      Z, loc_D099
				set     3, c                                    ; flag JUMP

loc_D099:
				jp      finished_input
; ---------------------------------------------------------------------------

cursor:
				ld      c, 0
				ld      a, 0xF7 ; '�'                          ; row 3
				call    read_port
				bit     4, a                                    ; '5'?
				jr      Z, loc_D0A9
				set     0, c

loc_D0A9:                                                       ; row 4
				ld      a, 0xEF ; '�'
				call    read_port
				bit     0, a                                    ; '0'?
				jr      Z, loc_D0B4
				set     3, c

loc_D0B4:                                                       ; '7'?
				bit     3, a
				jr      Z, loc_D0BA
				set     2, c

loc_D0BA:                                                       ; '8'?
				bit     2, a
				jr      Z, loc_D0C0
				set     1, c

loc_D0C0:                                                       ; '6'?
				bit     4, a
				jr      Z, finished_input
				set     4, c
				jr      finished_input
; ---------------------------------------------------------------------------

keyboard:                                                       ; row 0 (SHIFT,Z,X,C,V)
				ld      a, 0xFE ; '�'
				call    read_port
				rrca
				ld      c, a
				and     3
				srl     c
				srl     c
				or      c
				and     3
				ld      c, a
				ld      a, 0x7F ; ''                          ; row 7
				call    read_port
				bit     1, a                                    ; SYM SHIFT? (right)
				jr      Z, loc_D0E4                             ; no, skip
				set     1, c                                    ; flag RIGHT

loc_D0E4:                                                       ; 'M'? (left)
				bit     2, a
				jr      Z, loc_D0EA                             ; no, skip
				set     0, c                                    ; flag LEFT

loc_D0EA:                                                       ; 'N'? (right)
				bit     3, a
				jr      Z, loc_D0F0                             ; no, skip
				set     1, c                                    ; flag RIGHT

loc_D0F0:                                                       ; 'B'? (left)
				bit     4, a
				jr      Z, loc_D0F6
				set     0, c                                    ; flag LEFT

loc_D0F6:                                                       ; row 1,6 (2nd row) A,S,F,G,G,H,J,K,L,ENTER (FORWARD)
				ld      a, 0xBD ; '�'
				call    read_port
				jr      Z, loc_D0FF
				set     2, c                                    ; flag FORWARD

loc_D0FF:                                                       ; row 2,5 (1st row) QWERTYUIOP (JUMP)
				ld      a, 0xDB ; '�'
				call    read_port
				jr      Z, loc_D108
				set     3, c                                    ; flag JUMP

loc_D108:                                                       ; row 3,4 (0-9) (PICKUP/DROP)
				ld      a, 0xE7 ; '�'
				call    read_port
				jr      Z, finished_input
				set     4, c                                    ; flag PICKUP/DROP

finished_input:                                                 ; (3rd row) SHIFT,Z,X,C,V,SPACE,SYMSHIFT,M,N,B (LEFT/RIGHT)
				ld      a, 0x7E ; '~'
				call    read_port
				and     0x1E                                   ; Z,X,C,V,SYMSHIFT,M,N,B
				push    bc
				ld      b, a
				ld      a, 0x99 ; '�'
				call    read_port
				or      b
				pop     bc
				jr      Z, loc_D125
				set     5, c                                    ; flag PICKUP/DROP (directional)

loc_D125:
				ld      a, c
				ld      (user_input), a
				ret
; End of function check_user_input


; =============== S U B R O U T I N E =======================================


lose_life:

; FUNCTION CHUNK AT RAM:AF7F SIZE 00000065 BYTES
; FUNCTION CHUNK AT RAM:BA22 SIZE 00000079 BYTES
; FUNCTION CHUNK AT RAM:BAAB SIZE 00000027 BYTES

				ld      hl, plyr_spr_1_scratchpad
				ld      de, graphic_objs_tbl
				push    de
				pop     ix
				ld      bc, 64                                 ; 1st 2 entries
				ldir                                            ; copy scratchpad back to object table
				xor     a
				ld      (transform_flag_graphic), a
				ld      hl, lives
				dec     (hl)                                    ; decrement life
				jp      M, game_over                            ; any left? no, exit
				ld      a, (sun_moon_scratchpad)                ; sprite index
				rrca
				rrca
				rrca
				and     0x20 ; ' '                             ; day/night?
				ld      c, a
				ld      a, (ix+16)                               ; plyr graphic no
				and     0x1F
				add     a, c                                    ; legs human/wulf?
				ld      (ix+16), a
				ld      a, (ix+0x30)                             ; top half playr graphic no
				and     0xF
				add     a, c
				add     a, 32                                  ; top half human/wulf
				ld      (ix+0x30), a
				ret
; End of function lose_life

; ---------------------------------------------------------------------------
; scratchpad for player sprites/objects

plyr_spr_1_scratchpad:
				DB 0, 0, 0, 0, 0, 0, 0, 0
start_loc_1:    DB 0, 0, 0, 0
flags12_1:      DB 0, 0, 0, 0
byte_D171:      DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

plyr_spr_2_scratchpad:
				DB 0, 0, 0, 0, 0, 0, 0, 0
start_loc_2:    DB 0, 0, 0, 0, 0, 0, 0, 0
byte_D191:      DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

plyr_spr_init_data:
				DB 0x78, 0x80, 0x80, 0x80, 5, 5, 0x17, 0x1C
				DB 0x78, 0x80, 0x80, 0x8C, 5, 5, 0, 0x1E

; =============== S U B R O U T I N E =======================================

; =============== S U B R O U T I N E =======================================


transfer_sprite:
				ld      a, (hl)                                 ; sprite index
				inc     hl
				ld      (ix+0), a                                ; store sprite index
				ld      a, (hl)                                 ; flags
				inc     hl
				ld      (ix+7), a                                ; store flags
				ld      a, (hl)                                 ; X
				inc     hl
				ld      (ix+26), a                               ; pixel X
				ld      a, (hl)                                 ; Y
				inc     hl
				ld      (ix+27), a                               ; pixel Y
				ret
; End of function transfer_sprite


; =============== S U B R O U T I N E =======================================


transfer_sprite_and_print:
				call    transfer_sprite                         ; copy to scratchpad
				push    hl
				call    print_sprite
				pop     hl
				ret
; End of function transfer_sprite_and_print


; =============== S U B R O U T I N E =======================================


display_panel:
				ld      ix, sprite_scratchpad
				ld      hl, panel_data
				call    transfer_sprite
				ld      de, 0xF810                             ; x+=16,y-=8
				ld      b, 5                                   ; 5 sprites
				call    multiple_print_sprite
				call    transfer_sprite_and_print
				call    transfer_sprite_and_print
				call    transfer_sprite
				ld      de, 0x810                              ; x+=16,y+=8
				ld      b, 5                                   ; 5 sprites
				call    multiple_print_sprite
				call    transfer_sprite_and_print
				jp      transfer_sprite_and_print
; End of function display_panel

; ---------------------------------------------------------------------------
panel_data:     DB 0x86, 0, 0x10, 0x34
				DB 0x87, 0, 0xF0, 0
				DB 0x88, 0, 0x90, 4
				DB 0x86, 0x40, 0xA0, 0x14
				DB 0x87, 0x40, 0, 0
				DB 0x88, 0x40, 0x60, 4

; =============== S U B R O U T I N E =======================================



; =============== S U B R O U T I N E =======================================


colour_panel:
				xor		a
				ld      hl, zx_aram+0x2B6
				ld      bc, 0x0301                    		; 1 bytes, 3 lines
				call    vidbuf_fill_window
				ld      hl, zx_aram+0x2BD
				ld      bc, 0x0301							; 1 byte, 3 lines
				call    vidbuf_fill_window
				ld      a, 0x42 ; 'B'
				ld      hl, zx_aram+0x297
				ld      bc, 0x0406							; 6 bytes, 4 lines
				jp      vidbuf_fill_window
; End of function colour_panel


; =============== S U B R O U T I N E =======================================


colour_sun_moon:
				ld      a, (sun_moon_scratchpad)                ; graphic_no
				and     1                                      ; sun?
				ld      a, 0x46 ; 'F'                          ; attribute
				jr      Z, loc_D317                             ; yes, skip
				inc     a

loc_D317:                                                       ; attribute memory
				ld      hl, zx_aram+0x2B8
				ld      bc, 0x0204                              ; 4 bytes, 2 lines
				jp      vidbuf_fill_window
; End of function colour_sun_moon


; =============== S U B R O U T I N E =======================================


adjust_plyr_xyz_for_room_size:
				ld      a, (room_size_X)
				sub     2
				ld      l, a
				ld      a, (room_size_Y)
				sub     2
				ld      h, a
				ld      a, (ix+1)                                ; X
				and     a                                       ; 0?
				jr      Z, enter_arch_e                         ; yes, go
				inc     a                                       ; -1?
				jr      Z, enter_arch_w                         ; yes, go
				ld      a, (ix+2)                                ; Y
				and     a                                       ; 0?
				jr      Z, enter_arch_n                         ; yes, go
				inc     a                                       ; -1?
				jr      Z, enter_arch_s                         ; yes, go
				ret
; ---------------------------------------------------------------------------

enter_arch_s:
				ld      c, 200
				call    adjust_plyr_Z_for_arch
				ld      a, 128                                 ; 128
				sub     h                                       ; sub (room_size_Y-2)
				sub     (ix+5)                                   ; sub depth

adjust_plyr_y:                                                  ; plyr_spr_1 Y
				ld      (ix+2), a

copy_spr_1_xy_2:                                                ; set draw plyr_spr_1
				set     4, (ix+7)
				set     4, (ix+0x27)                             ; set draw_plyr_spr_2
				ld      a, (ix+1)                                ; plyr_spr_1 X
				ld      (ix+0x21), a                             ; set plyr_spr_2 X
				ld      a, (ix+2)                                ; plyr_spr_1 Y
				ld      (ix+0x22), a                             ; set plyr_spr_2 Y
				ret
; ---------------------------------------------------------------------------

enter_arch_n:
				ld      c, 81
				call    adjust_plyr_Z_for_arch
				ld      a, h                                    ; room_size_Y-2
				add     a, 128
				add     a, (ix+5)                                ; add depth
				jr      adjust_plyr_y
; ---------------------------------------------------------------------------

enter_arch_w:
				ld      c, 174
				call    adjust_plyr_Z_for_arch
				ld      a, 128
				sub     l                                       ; sub (room_size_X-2)
				sub     (ix+4)                                   ; sub width

adjust_plyr_x:
				ld      (ix+1), a
				jr      copy_spr_1_xy_2
; ---------------------------------------------------------------------------

enter_arch_e:
				ld      c, 55
				call    adjust_plyr_Z_for_arch
				ld      a, l                                    ; room_size_X-2
				add     a, 128                                 ; add 128
				add     a, (ix+4)                                ; add width
				jr      adjust_plyr_x
; End of function adjust_plyr_xyz_for_room_size


; =============== S U B R O U T I N E =======================================


adjust_plyr_Z_for_arch:
				ld      iy, other_objs_here
				ld      de, 0x40 ; '@'                         ; 2 object entries
				ld      b, 4                                   ; max 4 arches/location

loc_D395:                                                       ; graphic no.
				ld      a, (iy+0)
				cp      6                                      ; arch?
				ret     NC                                      ; no, return
				ld      a, (iy+1)                                ; X
				add     a, (iy+2)                                ; (X+Y)=pixelY
				cp      c                                       ; match?
				jr      Z, adj_plyr_Z                           ; yes, adjust player
				add     iy, de                                  ; next object sprite pair
				djnz    loc_D395                                ; loop through all arches
				ret
; ---------------------------------------------------------------------------

adj_plyr_Z:                                                     ; arch Z
				ld      a, (iy+3)
				ld      (ix+3), a                                ; set player_sprite_1 Z
				add     a, 12
				ld      (ix+0x23), a                             ; set player_sprite_2 Z
				ret
; End of function adjust_plyr_Z_for_arch


; =============== S U B R O U T I N E =======================================


get_ptr_object:
				push    bc
				and     0x7F ; ''
				ld      l, a
				ld      h, 0                                   ; HL=A
				add     hl, hl                                  ; x2
				add     hl, hl                                  ; x4
				add     hl, hl                                  ; x8
				add     hl, hl                                  ; x16
				add     hl, hl                                  ; x32
				ld      bc, graphic_objs_tbl                   ; base of graphical object table
				add     hl, bc                                  ; get table entry
				pop     bc
				ret
; End of function get_ptr_object

; Retrieves graphics objects to render screen
; - background object sprites, then
; - foreground object sprites
; Populates graphics_object_tbl
;
; IX=player object

; =============== S U B R O U T I N E =======================================


retrieve_screen:
				ld      de, other_objs_here
				ld      bc, block_type_tbl                     ; end of location table
				ld      hl, location_tbl

find_screen:                                                    ; get location ID
				ld      a, (hl)
				inc     hl
				cp      (ix+8)                                   ; same as player (current) screen?
				jr      Z, found_screen                         ; yes, exit
				ld      a, (hl)                                 ; get entry size
				call    add_HL_A                                ; ptr next entry
				and     a
				sbc     hl, bc                                  ; end of location table?
				jr      NC, zero_end_of_graphic_objs_tbl        ; yes, exit
				add     hl, bc
				jr      find_screen                             ; loop
; ---------------------------------------------------------------------------

zero_end_of_graphic_objs_tbl:                                   ; start of program data
				ld      hl, font
				and     a
				sbc     hl, de                                  ; done?
				ret     Z                                       ; yes, exit
				ld      b, 32                                  ; 32 bytes to clear
				call    zero_DE
				jr      zero_end_of_graphic_objs_tbl
; ---------------------------------------------------------------------------

found_screen:                                                   ; get entry size
				ld      b, (hl)
				inc     hl
				ld      a, (hl)                                 ; get attributes
				and     7                                      ; mask off unused bits
				or      0x40 ; '@'                             ; bright ON
				ld      (curr_room_attrib), a                   ; store
				push    de
				ex      de, hl                                  ; DE=attributes
				ld      a, (de)                                 ; get attributes
				inc     de                                      ; ptr background type
				rrca
				rrca
				rrca
				and     0x1F                                   ; get room size
				ld      c, a                                    ; C=room size
				add     a, a
				add     a, c                                    ; A=room size x3
				ld      hl, room_size_tbl
				call    add_HL_A                                ; ptr entry
				ld      a, (hl)                                 ; room size X
				inc     hl
				ld      (room_size_X), a
				ld      a, (hl)                                 ; room size Y
				inc     hl
				ld      (room_size_Y), a
				ld      a, (hl)                                 ; room size Z
				ld      (room_size_Z), a
				dec     b
				dec     b                                       ; adjust entry size
				ex      de, hl
				pop     de

next_bg_obj:                                                    ; get background type
				ld      a, (hl)
				inc     hl                                      ; next entry
				cp      0xFF                                   ; done all background types?
				jr      Z, find_fg_objs                         ; yes, exit
				push    bc
				push    hl
				ld      l, a
				ld      h, 0
				add     hl, hl                                  ; word offset
				ld      bc, background_type_tbl
				add     hl, bc                                  ; ptr entry
				ld      a, (hl)
				inc     hl
				ld      h, (hl)
				ld      l, a                                    ; HL=ptr to background object

next_bg_obj_sprite:                                             ; 8 bytes/entry
				ld      bc, 8
				ldir                                            ; copy to graphic_object_tbl
				ld      a, (ix+8)                                ; player (current) screen
				ld      (de), a                                 ; store
				inc     de
				ld      b, 23
				call    zero_DE                                 ; 8+1+23 = 32 bytes/entry
				ld      a, (hl)
				and     a                                       ; done object?
				jr      NZ, next_bg_obj_sprite                  ; no, loop
				pop     hl
				pop     bc
				djnz    next_bg_obj                             ; done location? no, loop
				jp      zero_end_of_graphic_objs_tbl
; ---------------------------------------------------------------------------

find_fg_objs:                                                   ; adjust bytes remaining
				dec     b
				push    iy
				push    de                                      ; graphic object table
				pop     iy                                      ; IY = graphic object table

next_fg_obj:                                                    ; block/count
				ld      a, (hl)
				and     7                                      ; count
				inc     a                                       ; adjust to 1-8
				ld      c, a                                    ; C = count
				ld      a, (hl)                                 ; block/count
				inc     hl
				dec     b                                       ; adjust bytes remaining
				ld      d, (hl)                                 ; location (x/y/z)
				inc     hl
				push    hl
				rrca
				rrca
				and     0x3E ; '>'                             ; block x2
				ld      hl, block_type_tbl
				call    add_HL_A                                ; ptr entry
				ld      a, (hl)
				inc     hl
				ld      h, (hl)
				ld      l, a                                    ; HL=ptr object

next_fg_obj_in_count:
				push    hl

next_fg_obj_sprite:                                             ; sprite
				ld      a, (hl)
				inc     hl
				ld      (iy+0), a
				ld      a, (hl)                                 ; width
				inc     hl
				ld      (iy+4), a
				ld      a, (hl)                                 ; depth
				inc     hl
				ld      (iy+5), a
				ld      a, (hl)                                 ; height
				inc     hl
				ld      (iy+6), a
				ld      a, (hl)                                 ; flags
				inc     hl
				ld      (iy+7), a
				ld      a, (ix+8)
				ld      (iy+8), a
				ld      a, (hl)                                 ; offsets
				rlca
				rlca
				rlca
				and     8                                      ; x1 in bit3
				ld      e, a                                    ; E=x1*8
				ld      a, d                                    ; location (x/y/z)
				rlca
				rlca
				rlca
				rlca
				and     0x70 ; 'p'                             ; x*16
				add     a, e                                    ; x*16+x1*8
				add     a, 72                                  ; x*16+x1*8+72
				ld      (iy+1), a                                ; store X
				ld      a, (hl)                                 ; offsets
				rlca
				rlca
				and     8                                      ; y1 in bit3
				ld      e, a                                    ; E=y1*8
				ld      a, d                                    ; location (x/y/z)
				rlca
				and     0x70 ; 'p'                             ; Y*16
				add     a, e                                    ; Y*16+Y1*8
				add     a, 72                                  ; Y*16+Y1*8+72
				ld      (iy+2), a                                ; store Y
				ld      a, d                                    ; location (x/y/z)
				rlca
				rlca
				and     3                                      ; z
				add     a, a
				add     a, a                                    ; z*4
				ld      e, a
				add     a, a                                    ; z*8
				add     a, e                                    ; z*12
				add     a, (hl)                                 ; z*12+z1*4+rubbish
				inc     hl
				and     0xFC ; '�'                             ; mask off rubbish bits
				ld      e, a
				ld      a, (room_size_Z)
				add     a, e                                    ; z*12+z1*4+room_size_Z
				ld      (iy+3), a                                ; store Z
				push    bc
				ld      bc, 9
				add     iy, bc
				ld      b, 23                                  ; 9+23=32 bytes/entry

loc_D4CD:                                                       ; zero byte
				ld      (iy+0), 0
				inc     iy
				djnz    loc_D4CD
				pop     bc
				ld      a, (hl)                                 ; next entry
				and     a                                       ; done?
				jr      NZ, next_fg_obj_sprite                  ; no, loop
				pop     de
				pop     hl
				dec     b
				jr      Z, loc_D4EA
				dec     c                                       ; done count blocks?
				jp      Z, next_fg_obj                          ; yes, exit loop
				ld      a, (hl)
				inc     hl
				push    hl
				ex      de, hl
				ld      d, a
				jr      next_fg_obj_in_count
; ---------------------------------------------------------------------------

loc_D4EA:
				push    iy
				pop     de
				pop     iy
				jp      zero_end_of_graphic_objs_tbl
; End of function retrieve_screen


; =============== S U B R O U T I N E =======================================


add_HL_A:
				add     a, l
				ld      l, a
				ld      a, h
				adc     a, 0
				ld      h, a
				ret
; End of function add_HL_A


; =============== S U B R O U T I N E =======================================


HL_equals_DE_x_A:
				push    bc
				ld      hl, 0
				ld      b, 8

loc_D4FF:
				add     hl, hl
				rlca
				jr      NC, loc_D504
				add     hl, de

loc_D504:
				djnz    loc_D4FF
				pop     bc
				ret
; End of function HL_equals_DE_x_A


; =============== S U B R O U T I N E =======================================


zero_DE:
				xor     a

fill_DE:
				ld      (de), a
				inc     de
				djnz    fill_DE
				ret
; End of function zero_DE


; =============== S U B R O U T I N E =======================================


handle_pause:
				ld      a, 0x7E ; '~'                          ; SPACE,SYMSHIFT,M,N,B
				call    read_port
				bit     0, a                                    ; SPACE?
				ret     Z                                       ; no, exit
				and     0x1E                                   ; any other key?
				ret     NZ                                      ; yes, exit

debounce_space_press:
				ld      a, 0x7E ; '~'
				call    read_port
				bit     0, a                                    ; SPACE?
				jr      NZ, debounce_space_press                ; yes, loop
				call    toggle_audio_hw_x24

wait_for_space:
				ld      a, 0x7E ; '~'
				call    read_port
				bit     0, a                                    ; SPACE?
				jr      Z, wait_for_space                       ; no, loop

debounce_space_release:
				ld      a, 0x7E ; '~'
				call    read_port
				bit     0, a                                    ; SPACE?
				jr      NZ, debounce_space_release              ; no, loop
				jp      toggle_audio_hw_x24
; End of function handle_pause


; =============== S U B R O U T I N E =======================================


clr_mem:
				ld      e, 0

clr_byte:                                                       ; zero location
				ld      (hl), e
				inc     hl                                      ; next location
				dec     bc
				ld      a, b
				or      c                                       ; done?
				jr      NZ, clr_byte                            ; no, loop
				ret
; End of function clr_mem

; ---------------------------------------------------------------------------
; START OF FUNCTION CHUNK FOR clear_scrn

clr_bitmap_memory:                                              ; screen memory
				ld      hl, zx_vram
				ld      bc, 0x1800                             ; # bytes to clear
				jr      clr_mem
; END OF FUNCTION CHUNK FOR clear_scrn

; =============== S U B R O U T I N E =======================================


clr_attribute_memory:
				ld      hl, zx_aram                            ; colour data
				ld      bc, 0x300                              ; # bytes to clear
				ld      e, 0x46 ; 'F'                          ; bright yellow on black
				jr      clr_byte
; End of function clr_attribute_memory


; =============== S U B R O U T I N E =======================================


fill_attr:
				ld      hl, zx_aram                            ; colour data
				ld      bc, 0x300                              ; # bytes to clear
				ld      e, a                                    ; attribute to set
				jr      clr_byte                                ; fill
; End of function fill_attr


; =============== S U B R O U T I N E =======================================


clear_scrn:

; FUNCTION CHUNK AT RAM:D544 SIZE 00000008 BYTES

				xor     a                                       ; border colour BLACK, activate MIC
				out     (0xFE), a                               ; ULA
				call    clr_attribute_memory
				jr      clr_bitmap_memory
; End of function clear_scrn


; =============== S U B R O U T I N E =======================================


clear_scrn_buffer:
				ld      bc, 0x1800                             ; # bytes to clear
				ld      hl, vidbuf                             ; screen buffer
				jr      clr_mem
; End of function clear_scrn_buffer

; copies from screen buffer to video memory

; =============== S U B R O U T I N E =======================================


update_screen:
				ld      hl, vidbuf                             ; screen buffer
				ld      de, zx_vram+0x17E0                    ; last line of attribute memory
				ld      bc, 0x20C0                             ; B=32 bytes, C=192 lines

loc_D578:
				push    bc
				ld		c, e
loc_D57B:                                                       
				ld      a, (hl)									; source byte
				ld      (de), a                                 ; copy to destination
				and		0x55
				ld      (hl), a                                 ; wipe source byte
				inc     l                                       ; next source location
				inc     e                                       ; next destination location
				djnz    loc_D57B                                ; loop for a line
				ld		e, c									; restore destination

				dec     d
				ld      a, d
				cpl
				and     7
				jr      NZ, loc_D59A
				
				inc		h
				ld      a, e
				sub     32
				ld      e, a
				jr      C, loc_D59A
				
				ld      a, d
				add     a, 8
				ld      d, a                                    ; add 2K

loc_D59A:                                                       ; byte, line counter
				pop     bc
				dec     c                                       ; dec line counter
				jr      NZ, loc_D578                            ; loop through all lines
				ret
; End of function update_screen


; =============== S U B R O U T I N E =======================================


render_dynamic_objects:
				xor     a
				ld      (objs_wiped_cnt), a                     ; zero count of wiped objects
				push    ix
				ld      a, (render_status_info)
				and     a                                       ; initial rendering?
				jp      NZ, loc_D653                            ; yes, no need to wipe anything

				ld      hl, objects_to_draw
				ld      (tmp_objects_to_draw), hl               ; temp storage

wipe_next_object:
				ld      hl, (tmp_objects_to_draw)
				ld      a, (hl)                                 ; object index
				inc     hl                                      ; next list entry
				ld      (tmp_objects_to_draw), hl               ; store
				cp      0xFF                                    ; end of list?
				jp      Z, loc_D653                             ; yes, skip
				call    get_ptr_object

				push    hl
				pop     ix

				bit     5, (ix+7)                                ; wipe flag?
				jr      Z, wipe_next_object                      ; no, go
				res     5, (ix+7)                                ; clear wipe flag
				ld      a, (ix+26)                               ; pixel X
				sub     (ix+30)                                  ; old pixel X
				jp      C, loc_D649
				ld      c, (ix+30)                               ; old pixel X

loc_D5DB:                                                       ; old pixel X
				ld      a, (ix+30)
				rrca
				rrca
				rrca
				and     0x1F                                   ; old pixel X byte address
				add     a, (ix+28)                               ; old data width (bytes)
				ld      e, a
				ld      a, (ix+26)                               ; pixel X
				rrca
				rrca
				rrca
				and     0x1F                                   ; pixel X byte address
				add     a, (ix+24)                               ; data width (bytes)
				cp      e
				jr      C, loc_D5F6
				ld      e, a

loc_D5F6:
				ld      a, c
				rrca
				rrca
				rrca
				and     0x1F                                   	; old/pixel X byte address
				ld      b, a
				ld      a, e
				sub     b
				ld      l, a                                    ; L=number of bytes to wipe
				
				ld      a, (ix+27)                             	; pixel Y
				sub     (ix+31)                                 ; pixel Y < old pixel Y?
				jr      C, loc_D64E                             ; yes, go
				ld      b, (ix+31)                              ; old pixel Y

loc_D60B:                                                       ; old pixel Y
				ld      a, (ix+31)
				add     a, (ix+29)                              ; old data height (lines)
				ld      e, a
				ld      a, (ix+27)                              ; pixel Y
				add     a, (ix+25)                              ; data height (lines)
				cp      e
				jr      NC, loc_D61C
				ld      a, e

loc_D61C:
				sub     b
				ld      h, a
				ld      a, b
				cp      192                                    	; off bottom of screen?
				jr      NC, wipe_next_object                    ; yes, go
				add     a, h
				sub     192
				jr      C, loc_D62C
				neg
				add     a, h
				ld      h, a  									; H=number of lines to wipe

loc_D62C:
				; BC - position
				; HL - height/width
				
				call    screen_calc_addr_de						; screen address in DE
				push	de										; save screen addr on stack
				ex		hl, de									; height/width from HL to DE
				call    vidbuf_calc_addr_in_hl		            ; video buffer address in HL
				push 	hl										; save buffer adress on stack
				push	de										; save height/width on stack

				; clear sprite area in video buffer.  HL = address, B = height, E = width
				ld		b, d
				call    vidbuf_clear_window

				ld		hl, objs_wiped_cnt
				inc		(hl)

				jp      wipe_next_object
; ---------------------------------------------------------------------------

loc_D649:                                                       ; pixel X
				ld      c, (ix+26)
				jr      loc_D5DB
; ---------------------------------------------------------------------------

loc_D64E:                                                       ; pixel Y
				ld      b, (ix+27)
				jr      loc_D60B
; ---------------------------------------------------------------------------


loc_D653:
				; render objects into video buffer
				call    calc_display_order_and_render

				call    print_sun_moon
				call    display_objects_carried

				ld      hl, objs_wiped_cnt
				ld      a, (rendered_objs_cnt)
				add     a, (hl)                                 ; add the number of wipes
				ld      (rendered_objs_cnt), a

				ld 		a, (hl)
				and		a
				jr		z, loc_D679

.copy_loop:		ex 		af, af'

				; get width/height, source and destination from stack
				pop     bc										; width/height
				pop     hl                                      ; source
				pop     de                                      ; destination

				; copy object from video buffer to screen
				call    blit_to_screen

				ex		af, af'
				dec		a
				jr      nz, .copy_loop
; ---------------------------------------------------------------------------

loc_D679:
				;call update_screen

				pop     ix
				ret
; End of function render_dynamic_objects

;


; =============== S U B R O U T I N E =======================================

; DE - Screen address
; HL - Video buffer address
; B - Height in lines
; C - Width in bytes

blit_to_screen:
				ld	a,c
				add a,a
				add 34
				neg
				ld	(.djnz + 1), a
				inc	b
				jr	.next_line

				ldi
				ldi
				ldi
				ldi
				ldi
				ldi				

				; Add constant to HL to move down to next line in video buffer
				ld		a, b
				ld		b, 0
				add		hl, bc
				ld		b, a

				; Restore DE
				ld		de, iy
				
				; Move DE up one line
				dec     d
				ld      a, d
				cpl
				and     7
				jr      NZ, .next_line
				ld      a, e
				sub     0x20
				ld      e, a
				jr      C, .next_line
				ld      a, d
				add     a, 8
				ld      d, a

.next_line:		ld		iy, de
				ld		c, 32

.djnz			djnz	$
				ret



	IF 0
blit_to_screen:
				push    bc
				push    de
				
				ld		a,l ;push    hl
				
				ld      b, 0
				ldir
				ld		l,a ;pop     hl
				
				ld      de, 32
				add     hl, de                                  ; next line
				
				pop     de

				dec     d
				ld      a, d
				cpl
				and     7
				jr      NZ, loc_D69A
				
				ld      a, e
				sub     0x20
				ld      e, a
				jr      C, loc_D69A

				ld      a, d
				add     a, 8
				ld      d, a

loc_D69A:                                                       ; done all lines?
				pop     bc
				djnz    blit_to_screen                          ; no, loop
;				ret
; End of function blit_to_screen
	ENDIF


; Calculate pixel X,Y position from object X,Y,Z
calc_pixel_XY:
				ld      a, (ix+1)                               ; X
				add     a, (ix+2)                               ; add Y
				sub     128
				add     a, (ix+18)                              ; add pixel_x_adj
				ld      (ix+26), a                              ; pixel X

				ld      a, (ix+2)                               ; Y
				sub     (ix+1)                                  ; subtract X
				add     128
				srl     a
				add     a, (ix+3)                               ; Z
				sub     104
				add     a, (ix+19)                              ; pixel_y_adj
				ld      (ix+27), a                              ; pixel Y
				cp      192                                    	; bottom line of screen?
				ret




; Flips sprite data (H,V) if required in-place
flip_sprite:
				ld      l, (ix+0)                               ; sprite index
				ld      h, 0
				add     hl, hl                                  ; word offset
				ld      bc, sprite_tbl
				add     hl, bc                                  ; sprite table entry
				ld      e, (hl)
				inc     hl
				ld      d, (hl)                                 ; DE = sprite address
				ld      a, (de)                                 ; width
				and     a                                       ; null sprite?
				jp      NZ, flip_sprite_data                    ; no, skip
				inc     sp
				inc     sp                                      ; exit from caller
				ret


; =============== S U B R O U T I N E =======================================


calc_pixel_XY_and_render:
				ld      a, (ix+0)                                ; graphic no.
				cp      1                                      ; flagged as ???
				jr      NZ, loc_D710                            ; no, continue
				ld      (ix+0), 0                               ; set to null
				ret
; ---------------------------------------------------------------------------

loc_D710:                                                       ; flag don't draw
				res     4, (ix+7)
				call    calc_pixel_XY
				ret     NC                                      ; off bottom of screen, skip
; End of function calc_pixel_XY_and_render


print_sprite:
				call    flip_sprite
				ld      a, (ix+26)                               ; pixel X
				and     7                                      ; bit offset?
				jr      Z, loc_D76F                             ; no, skip

				rlca
				and     0xE
				or      0xF0 ; '�'
				ld      h, a
				ld      a, (de)
				inc     de
				and     7
				inc     a
				ld      b, a
				ld      (ix+24), a                               ; width_bytes
				dec     a
				and     7
				add     a, a
				add     a, a
				add     a, a
				add     a, a
				neg
				add     a, 0x50 ; 'P'

loc_D73C:                                                       ; self-modifying code
				ld      (loc_D7AC+1), a
				ld      a, b
				cpl
				add     a, 0x22 ; '"'
				ld      (loc_D800+1), a
				ld      a, (de)
				inc     de
				ld      (ix+25), a                               ; height_lines
				add     a, (ix+27)
				sub     192                                    ; off bottom of screen?
				jr      C, loc_D75A                             ; no, skip
				neg
				add     a, (ix+25)                               ; +height_lines
				ld      (ix+25), a                               ; store height_lines

loc_D75A:                                                       ; pixel X
				ld      c, (ix+26)
				ld      b, (ix+27)                               ; pixel Y
				call    vidbuf_calc_addr_in_bc
				
				ld      (tmp_SP), sp
				ex      de, hl
				ld      sp, hl
				ex      de, hl
				ld      a, (ix+25)                               ; height_lines
				
				jr      loc_D7AA
; ---------------------------------------------------------------------------

loc_D76F:
				ld      a, (de)
				inc     de
				and     0xF
				ld      (ix+24), a                               ; width_bytes
				ld      b, a
				add     a, a
				add     a, a
				add     a, a
				neg
				sub     6
				jr      loc_D73C


; ---------------------------------------------------------------------------
				pop     de
				ld      a, (bc)
				cpl
				or      e
				cpl
				or      d
				ld      (bc), a
				inc     bc
				pop     de
				ld      a, (bc)
				cpl
				or      e
				cpl
				or      d
				ld      (bc), a
				inc     bc

loc_D790:
				pop     de
				ld      a, (bc)
				cpl
				or      e
				cpl
				or      d
				ld      (bc), a
				inc     bc
				pop     de
				ld      a, (bc)
				cpl
				or      e
				cpl
				or      d
				ld      (bc), a
				inc     bc
				pop     de
				ld      a, (bc)
				cpl
				or      e
				cpl
				or      d
				ld      (bc), a
				jp      loc_D7FF
; ---------------------------------------------------------------------------

loc_D7AA:
				ex      af, af'
				ld      a, (bc)

loc_D7AC:                                                       ; patched
				jr      loc_D790
; ---------------------------------------------------------------------------
				pop     de
				ld      l, e
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				ld      (bc), a
				inc     bc
				inc     h
				ld      l, e
				ld      a, (bc)
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				dec     h
				pop     de
				ld      l, e
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				ld      (bc), a
				inc     bc
				inc     h
				ld      l, e
				ld      a, (bc)
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				dec     h
				pop     de
				ld      l, e
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				ld      (bc), a
				inc     bc
				inc     h
				ld      l, e
				ld      a, (bc)
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				dec     h
				pop     de
				ld      l, e
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				ld      (bc), a
				inc     bc
				inc     h
				ld      l, e
				ld      a, (bc)
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				dec     h
				pop     de
				ld      l, e
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				ld      (bc), a
				inc     bc
				inc     h
				ld      l, e
				ld      a, (bc)
				and     (hl)
				ld      l, d
				xor     (hl)
				cpl
				dec     h
				ld      (bc), a

loc_D7FF:
				ld      a, c

loc_D800:                                                       ; patched
				add     a, 0x1E
				ld      c, a
				ld      a, b
				adc     a, 0
				ld      b, a
				ex      af, af'
				dec     a
				jp      NZ, loc_D7AA
				ld      sp, (tmp_SP)
				ret



; BC - Position
vidbuf_calc_addr_in_bc:
				ld		a, c
				srl     b
				rra      
				srl     b
				rra
				srl     b
				rra
				ld		c, a
				ld		a, high vidbuf
				add		a, b
				ld		b, a
				ret

; BC - Position
vidbuf_calc_addr_in_hl:
				ld		a, c
				srl     b
				rra      
				srl     b
				rra
				srl     b
				rra
				ld		l, a
				ld		a, high vidbuf
				add		a, b
				ld		h, a
				ret

; BC - Position
screen_calc_addr_de:
				ld      a, c
				rrca			; / 2
				rrca			; / 4
				rrca			; / 8
				and     0x1F	; 0 - 31 only
				ld      e, a
				ld      a, b
				cpl
				and     7
				ex      af, af'
				ld      a, b
				cpl
				rlca
				rlca
				and     0xE0 ; '�'
				or      e
				ld      e, a
				ld      a, b
				cpl
				rrca
				rrca
				rrca
				and     0x18
				ld      d, a
				ex      af, af'
				or      d
				add     a, 0x38 ; '8'
				ld      d, a
				ret

; HL = Y,X
attrib_calc_addr_de:
				ld		a, h
				cpl		
				rrca
				rrca
				rrca
				rrca
				ld		d, a
				ld		a, l
				rra
				srl		d
				rra
				srl		d
				rra
				ld		e, a 
				ld		a, d
				and		0x03
				add		high (zx_vram + 0x1700)
				ld		d, a
				ret

; End of function calc_attrib_addr

; ---------------------------------------------------------------------------
; DE = sprite data address
; START OF FUNCTION CHUNK FOR flip_sprite

flip_sprite_data:                                               ; sprite data address
				ld      a, (de)                                 ; width
				xor     (ix+7)                                  ; same H and V flip as stored?
				and		0xC0
				ret		Z										; exit if no flip required
				jp		P, hflip_sprite_data					; V flip the same, jump to check H flip
							
vflip_sprite_data:		
				push	de	

				ld      a, (de)                                 ; width
				xor     0x80 ; '�'                             ; toggle Vflip
				ld      (de), a                                 ; store updated flag
		
				rlca                                            ; *2
				and     0x1E
				ld      b, a                                    ; B = width x 2 (data+mask)
				inc     de
				ld      a, (de)                                 ; height
				ld      c, a
				inc     de                                      ; sprite data
				
				push    de
				ld      e, b
				ld      d, 0                                    ; DE = width x 2
				call    HL_equals_DE_x_A                        ; HL = width x 2 x height
				pop     de                                      ; sprite data
				
				add     hl, de                                  ; skip sprite data (including mask bytes)
				ex      de, hl                                  ; DE=end of sprite data, HL=sprite data
				ld      a, b                                    ; width x 2
				call    add_HL_A                                ; HL=sprite data + width x 2
				dec     de                                      ; last byte of sprite data
				dec     hl                                      ; (height+1) x width x 2 - 1
				srl     c                                       ; height / 2

.line_loop:                                                     ; B=widthx2, C=height/2
				push    bc
.pair_loop:				                                         
				ld      a, (de)									; sprite data byte from end
				ld      c, (hl)                                 ; sprite data from start
				ld      (hl), a                                 ; store end data at start
				ld      a, c
				ld      (de), a                                 ; store start data at end
				dec     hl                                      ; next start byte
				dec     de                                      ; next end byte
				djnz    .pair_loop				                ; flip sprite and mask data for line pair
				pop     bc

				ld      a, b
				call    add_HL_A
				ld      a, b
				call    add_HL_A                                ; next line
				
				dec     c                                       ; done all lines?
				jr      NZ, .line_loop                          ; no, loop

				pop		de

hflip_sprite_data:                                                  
				ld      a, (de)                                 ; width (bytes)
				xor     (ix+7)                                  ; same Hflip as stored?
				add		a,a
				ret		P

				push	de

				ld      a, (de)                                 ; width
				xor     0x40 ; '@'                              ; toggle Hflip flag
				ld      (de), a                                 ; store updated flag

				and     0xF                                     ; width
				ld      b, a
				ld      c, a
				inc     de
				ld      a, (de)                                 ; height
				ex      af, af'
				inc     de                                      ; sprite data
				ex      de, hl                                  ; HL=sprite data
				push    hl
				exx
				pop     hl                                      ; HL'=sprite data
				ld      b, high reverse_bits_table ; '�'
				exx

loc_D8BF:		exx
				ld      c, (hl)                                 ; sprite data byte
				ld      a, (bc)
				ld      e, a
				inc     hl
				ld      c, (hl)
				ld      a, (bc)
				ld      d, a
				inc     hl
				push    de
				exx
				
				djnz    loc_D8BF
				ld      b, c

loc_D8CD:		pop     de
				ld      (hl), e
				inc     hl
				ld      (hl), d
				inc     hl
				djnz    loc_D8CD

				ex      af, af'
				dec     a
				jr      Z, loc_D8DC
				ex      af, af'
				ld      b, c
				jr      loc_D8BF
loc_D8DC:		pop     de
				ret



Copyright1984A_c_g_:
				DC		'COPYRIGHT 1984 A.C.G.'

; Pointers to Sprite Graphics
sprite_tbl:     DW spr_nul, spr_nul, spr_071, spr_072, spr_023, spr_024
				DW spr_008, spr_020, spr_043, spr_043, spr_076, spr_077
				DW spr_078, spr_069, spr_070, spr_073, spr_055, spr_056
				DW spr_057, spr_058, spr_057, spr_056, spr_009, spr_002
				DW spr_059, spr_060, spr_061, spr_062, spr_061, spr_060
				DW spr_005, spr_004, spr_050, spr_051, spr_046, spr_049
				DW spr_046, spr_051, spr_048, spr_063, spr_052, spr_047
				DW spr_054, spr_053, spr_054, spr_047, spr_065, spr_064
				DW spr_079, spr_080, spr_081, spr_082, spr_081, spr_080
				DW spr_020, spr_020, spr_083, spr_084, spr_085, spr_086
				DW spr_085, spr_084, spr_020, spr_003, spr_087, spr_088
				DW spr_089, spr_090, spr_089, spr_088, spr_095, spr_096
				DW spr_094, spr_093, spr_092, spr_091, spr_092, spr_093
				DW spr_097, spr_098, spr_039, spr_040, spr_041, spr_042
				DW spr_045, spr_044, spr_010, spr_011, spr_037, spr_038
				DW spr_000, spr_020, spr_099, spr_100, spr_101, spr_102
				DW spr_031, spr_032, spr_022, spr_033, spr_034, spr_035
				DW spr_036, spr_021, spr_031, spr_032, spr_022, spr_033
				DW spr_034, spr_035, spr_036, spr_030, spr_030, spr_029
				DW spr_030, spr_029, spr_028, spr_027, spr_026, spr_025
				DW spr_025, spr_026, spr_027, spr_028, spr_029, spr_030
				DW spr_029, spr_030, spr_066, spr_067, spr_068, spr_030
				DW spr_029, spr_028, spr_019, spr_017, spr_018, spr_014
				DW spr_015, spr_016, spr_021, spr_074, spr_075, spr_020
				DW spr_055, spr_056, spr_057, spr_058, spr_057, spr_056
				DW spr_005, spr_004, spr_059, spr_060, spr_061, spr_062
				DW spr_061, spr_060, spr_013, spr_012, spr_030, spr_029
				DW spr_028, spr_029, spr_030, spr_029, spr_028, spr_029
				DW spr_031, spr_032, spr_022, spr_033, spr_034, spr_035
				DW spr_036, spr_021, spr_010, spr_011, spr_006, spr_007
				DW spr_010, spr_011, spr_006, spr_007, spr_030, spr_029
				DW spr_001, spr_030

; Sprite Graphics Data
; +0 width
; +1 height
; - size = (width*height)*2
; [ 0..height ]
; [ 0..width ]
; -   +0 mask
; -   +1 image
spr_nul:        DB 0, 0
spr_000:        DB 3, 31
				DB 0xFF, 0x1F, 0xFF, 0, 0xFF, 0, 0xFF, 0x31
				DB 0xFF, 0xC0, 0xFF, 0, 0xFF, 0x2F, 0xFF, 0xF0
				DB 0xFF, 0, 0xFF, 0x37, 0xFF, 0xFE, 0xFF, 0
				DB 0xFF, 0x1F, 0xFF, 0x3F, 0xFF, 0xE0, 0xFF, 7
				DB 0xBF, 0xF, 0xFF, 0xFF, 0xFF, 7, 0x8F, 3
				DB 0xFF, 0xFF, 0xFF, 7, 0x83, 0, 0xFF, 0x3F
				DB 0xFF, 7, 0x80, 0, 0x3F, 0, 0xFF, 0xF
				DB 0x80, 0, 0, 0, 0xFF, 0x1D, 0x80, 0
				DB 0, 0, 0xFF, 0x3F, 0x80, 0, 0, 0
				DB 0xFF, 0x27, 0x80, 0, 0, 0, 0xFF, 7
				DB 0x80, 0, 0, 0, 0xFF, 0x27, 0x80, 0
				DB 0, 0, 0xFF, 0x3F, 0x80, 0, 0, 0
				DB 0xFF, 0x1D, 0x80, 0, 0, 0, 0xFF, 0xF
				DB 0x80, 0, 0, 0, 0xFF, 7, 0x80, 0
				DB 0, 0, 0xFF, 7, 0x80, 0, 0, 0
				DB 0xFF, 0x1F, 0x80, 0, 0, 0, 0xFF, 0x33
				DB 0x80, 0, 0, 0, 0xFF, 0x2F, 0x80, 0
				DB 0, 0, 0xFF, 0x37, 0xC0, 0, 0, 0
				DB 0xFF, 0x19, 0xF0, 0xC0, 0, 0, 0xFF, 0xF
				DB 0xFE, 0xF0, 0, 0, 0xFF, 3, 0xFF, 0xFE
				DB 0xE0, 0, 0xFF, 0, 0xFF, 0xFF, 0xFF, 0xE0
				DB 0xFF, 0, 0xFF, 0x1F, 0xFF, 0xFF, 0xFF, 0
				DB 0xFF, 3, 0xFF, 0xFF, 0xFF, 0, 0xFF, 0
				DB 0xFF, 0x3F
spr_001:        DB 3, 31
				DB 0xFF, 0, 0xFF, 0, 0xFF, 0xF8, 0xFF, 0
				DB 0xFF, 3, 0xFF, 0x8C, 0xFF, 0, 0xFF, 0xF
				DB 0xFF, 0xF4, 0xFF, 0, 0xFF, 0x7F, 0xFF, 0xEC
				DB 0xFF, 7, 0xFF, 0xFC, 0xFF, 0xF8, 0xFF, 0xFF
				DB 0xFD, 0xF0, 0xFF, 0xE0, 0xFF, 0xFF, 0xF1, 0xC0
				DB 0xFF, 0xE0, 0xFF, 0xFC, 0xC1, 0, 0xFF, 0xE0
				DB 0xFC, 0, 1, 0, 0xFF, 0xE0, 0, 0
				DB 1, 0, 0xFF, 0xF0, 0, 0, 1, 0
				DB 0xFF, 0xD8, 0, 0, 1, 0, 0xFF, 0xFC
				DB 0, 0, 1, 0, 0xFF, 0xE4, 0, 0
				DB 1, 0, 0xFF, 0xE0, 0, 0, 1, 0
				DB 0xFF, 0xE4, 0, 0, 1, 0, 0xFF, 0xFC
				DB 0, 0, 1, 0, 0xFF, 0xD8, 0, 0
				DB 1, 0, 0xFF, 0xF0, 0, 0, 1, 0
				DB 0xFF, 0xE0, 0, 0, 1, 0, 0xFF, 0xE0
				DB 0, 0, 1, 0, 0xFF, 0xF8, 0, 0
				DB 1, 0, 0xFF, 0xCC, 0, 0, 1, 0
				DB 0xFF, 0xF4, 0, 0, 3, 0, 0xFF, 0xEC
				DB 0, 0, 0xF, 3, 0xFF, 0x98, 0, 0
				DB 0x7F, 0xF, 0xFF, 0xF0, 7, 0, 0xFF, 0x7F
				DB 0xFF, 0xC0, 0xFF, 7, 0xFF, 0xFF, 0xFF, 0
				DB 0xFF, 0xFF, 0xFF, 0xF8, 0xFF, 0, 0xFF, 0xFF
				DB 0xFF, 0xC0, 0xFF, 0, 0xFF, 0xFC, 0xFF, 0
				DB 0xFF, 0
spr_002:        DB 4, 28
				DB 0, 0, 1, 0, 0x80, 0, 0, 0
				DB 0, 0, 7, 1, 0xE0, 0x80, 0, 0
				DB 0, 0, 0x1F, 7, 0xF8, 0xE0, 0, 0
				DB 0, 0, 0x7F, 0x1E, 0xFE, 0x78, 0, 0
				DB 1, 0, 0xFF, 0x79, 0xFF, 0x9E, 0x80, 0
				DB 7, 1, 0xFF, 0xE7, 0xFF, 0xE7, 0xE0, 0x80
				DB 0x1F, 7, 0xFF, 0x9D, 0xFF, 0xF9, 0xF8, 0xE0
				DB 0x7F, 0x1E, 0xFF, 0x7D, 0xFF, 0xBE, 0xFE, 0x78
				DB 0xFF, 0x79, 0xFF, 0xED, 0xFF, 0xAD, 0xFF, 0x9E
				DB 0xFF, 0x67, 0xFF, 0x6D, 0xFF, 0xAD, 0xFF, 0xE6
				DB 0xFF, 0x1F, 0xFF, 0x6D, 0xFF, 0xAD, 0xFF, 0xF8
				DB 0xFF, 0x7F, 0xFF, 0xAD, 0xFF, 0x6B, 0xFF, 0xFE
				DB 0xFF, 0x5D, 0xFF, 0xAD, 0xFF, 0x6B, 0xFF, 0xBA
				DB 0x7F, 0x1D, 0xFF, 0xDD, 0xFF, 0x6B, 0xFE, 0xB8
				DB 0x1F, 0xD, 0xFF, 0xFD, 0xFF, 0x77, 0xF8, 0xB8
				DB 0x1F, 0xD, 0xFF, 0x6E, 0xFF, 0xFE, 0xF8, 0xB8
				DB 0x1F, 0xD, 0xFF, 0x6F, 0xFF, 0xFC, 0xF8, 0xB0
				DB 0x1D, 8, 0xFF, 0x6D, 0xFF, 0xB6, 0xF8, 0x30
				DB 0x1C, 8, 0xFF, 0x6D, 0xFF, 0xB6, 0x38, 0x10
				DB 0x1C, 8, 0xFF, 0x65, 0xFF, 0xA6, 0x38, 0x10
				DB 0x1C, 8, 0xE7, 0x41, 0xEF, 0x86, 0x38, 0x10
				DB 0x1C, 8, 0xE3, 0x41, 0xC7, 0x82, 0x10, 0
				DB 8, 0, 0xE1, 0x40, 0xC7, 0x82, 0, 0
				DB 0, 0, 0xE1, 0x40, 0xC7, 0x82, 0, 0
				DB 0, 0, 0x41, 0, 0xC2, 0x80, 0, 0
				DB 0, 0, 1, 0, 0xC0, 0x80, 0, 0
				DB 0, 0, 1, 0, 0xC0, 0x80, 0, 0
				DB 0, 0, 0, 0, 0x80, 0, 0, 0
spr_003:        DB 4, 25
				DB 0, 0, 0, 0, 0x80, 0, 0, 0
				DB 0, 0, 1, 0, 0xC0, 0x80, 0, 0
				DB 0, 0, 7, 0, 0xE2, 0x80, 0, 0
				DB 0, 0, 0x3F, 7, 0xF7, 0xE2, 0, 0
				DB 3, 0, 0x7F, 0x2F, 0xFF, 0xF4, 0, 0
				DB 7, 3, 0xFF, 0x13, 0xFE, 0xF4, 0, 0
				DB 3, 1, 0xFF, 0x6D, 0xFF, 0xEA, 0, 0
				DB 1, 0, 0xFF, 0xED, 0xFF, 0xF7, 0x80, 0
				DB 1, 0, 0xFF, 0xF3, 0xFF, 0xFF, 0xE0, 0
				DB 0xF, 0, 0xFF, 0x7F, 0xFF, 0xFC, 0xF0, 0x60
				DB 0x1F, 0xF, 0xFF, 0xBF, 0xFF, 0xFB, 0xE0, 0x80
				DB 0xF, 0, 0xFF, 0x7C, 0xFF, 0xF6, 0xC0, 0
				DB 3, 1, 0xFF, 0xFB, 0xFF, 0xF9, 0xF0, 0x80
				DB 3, 1, 0xFF, 0xFC, 0xFF, 0xFF, 0xF8, 0xF0
				DB 7, 1, 0xFF, 0xFF, 0xFF, 0xFF, 0xF0, 0x80
				DB 0xF, 6, 0xFF, 0xFF, 0xFF, 0xF7, 0x80, 0
				DB 0x1F, 8, 0xFF, 0xCF, 0xFF, 0xEB, 0x80, 0
				DB 8, 0, 0xFF, 0x37, 0xFF, 0xF4, 0, 0
				DB 0, 0, 0xFF, 0x6F, 0xFF, 0xFA, 0, 0
				DB 1, 0, 0xFF, 0x9E, 0xFF, 0xF9, 0x80, 0
				DB 0, 0, 0x9F, 5, 0xF9, 0x60, 0, 0
				DB 0, 0, 0x1F, 9, 0xF8, 0x10, 0, 0
				DB 0, 0, 0x1F, 9, 0x9C, 8, 0, 0
				DB 0, 0, 0xB, 1, 0x88, 0, 0, 0
				DB 0, 0, 1, 0, 0, 0, 0, 0
spr_004:        DB 3, 23
				DB 3, 0, 0x7F, 0, 0, 0, 7, 3
				DB 0xFF, 0x3F, 0xE0, 0, 0xF, 7, 0xFF, 0x7F
				DB 0xF0, 0xE0, 0xF, 3, 0xFF, 0x7F, 0xF8, 0xF0
				DB 0x1F, 0xB, 0xFF, 0x7F, 0xF8, 0xF0, 0x1F, 0xB
				DB 0xFF, 0x7F, 0xF0, 0xE0, 0xF, 5, 0xFF, 1
				DB 0xF0, 0xE0, 0xF, 6, 0xFF, 0x60, 0xF0, 0x20
				DB 0xF, 5, 0xFF, 0xF0, 0xF0, 0, 7, 3
				DB 0xFF, 0xB0, 0xF8, 0xC0, 7, 3, 0xFF, 0x32
				DB 0xFC, 0xC8, 0xF, 6, 0xFF, 0xBB, 0xFC, 0x28
				DB 0xF, 5, 0xFF, 0x5C, 0xFC, 0x68, 7, 3
				DB 0xFF, 0x2F, 0xF8, 0x90, 7, 3, 0xFF, 0x33
				DB 0xF8, 0xF0, 7, 3, 0xFF, 0x3C, 0xF0, 0x60
				DB 3, 1, 0xFF, 0xBF, 0xF0, 0xA0, 3, 1
				DB 0xFF, 0x9F, 0xE0, 0xC0, 1, 0, 0xFF, 0xDF
				DB 0xE0, 0xC0, 0, 0, 0xFF, 0x6F, 0xC0, 0x80
				DB 0, 0, 0x7F, 0x37, 0x80, 0, 0, 0
				DB 0x3F, 0x1C, 0, 0, 0, 0, 0x1C, 0
				DB 0, 0
spr_005:        DB 3, 23
				DB 1, 0, 0x80, 0, 0, 0, 3, 1
				DB 0xFF, 0x80, 0, 0, 7, 3, 0xFF, 0xBF
				DB 0xE0, 0, 0xF, 3, 0xFF, 0x7F, 0xF0, 0xE0
				DB 0x1F, 0xB, 0xFF, 0x7F, 0xF8, 0xF0, 0x1F, 0xB
				DB 0xFF, 0xBF, 0xF8, 0xF0, 0xF, 5, 0xFF, 0xBF
				DB 0xF0, 0xE0, 0xF, 5, 0xFF, 0x81, 0xF0, 0xE0
				DB 7, 0, 0xFF, 0x7E, 0xE0, 0x40, 0xF, 1
				DB 0xFF, 0xFF, 0xC0, 0x80, 0x1F, 0xD, 0xFF, 0xC2
				DB 0xE0, 0x40, 0x1F, 0xD, 0xFF, 0xBC, 0xF0, 0x60
				DB 0x1F, 0xD, 0xFF, 0xBC, 0xF0, 0x20, 0xF, 5
				DB 0xFF, 0xBE, 0xF0, 0x40, 7, 3, 0xFF, 0xBC
				DB 0xF0, 0xE0, 0xF, 7, 0xFF, 0x7C, 0xE0, 0xC0
				DB 0xF, 6, 0xFF, 0xFC, 0xE0, 0xC0, 7, 1
				DB 0xFF, 0xFD, 0xC0, 0x80, 3, 1, 0xFF, 0xF9
				DB 0xC0, 0x80, 1, 0, 0xFF, 0xFB, 0x80, 0
				DB 0, 0, 0xFF, 0x76, 0, 0, 0, 0
				DB 0x7E, 0x38, 0, 0, 0, 0, 0x38, 0
				DB 0, 0
spr_006:        DB 3, 19
				DB 0, 0, 0x3E, 0, 0, 0, 0, 0
				DB 0xFF, 0x3E, 0x80, 0, 1, 0, 0xFF, 0xFF
				DB 0xC0, 0x80, 3, 1, 0xFF, 0xFF, 0xE0, 0xC0
				DB 7, 3, 0xFF, 0xFF, 0xF0, 0xE0, 0xF, 7
				DB 0xFF, 0xFF, 0xF8, 0xF0, 0xF, 7, 0xFF, 0xFF
				DB 0xF8, 0xF0, 0x1F, 0xF, 0xFF, 0xFF, 0xFC, 0xF8
				DB 0x1F, 0xF, 0xFF, 0xFF, 0xFC, 0xF8, 0x1F, 0xC
				DB 0xFF, 0xFF, 0xFC, 0xF8, 0x1F, 0xC, 0xFF, 0xFF
				DB 0xFC, 0xF8, 0x1F, 0xC, 0xFF, 0x7F, 0xFC, 0xF8
				DB 0xF, 6, 0xFF, 0x3F, 0xF8, 0xF0, 0xF, 7
				DB 0xFF, 0x1F, 0xF8, 0xF0, 7, 3, 0xFF, 0x87
				DB 0xF0, 0xE0, 3, 1, 0xFF, 0xC7, 0xE0, 0xC0
				DB 1, 0, 0xFF, 0xFF, 0xC0, 0x80, 0, 0
				DB 0xFF, 0x3E, 0x80, 0, 0, 0, 0x3E, 0
				DB 0, 0
spr_007:        DB 3, 18
				DB 0, 0, 0x3E, 0, 0, 0, 1, 0
				DB 0xFF, 0x3E, 0xC0, 0, 3, 1, 0xFF, 0xFF
				DB 0xE0, 0xC0, 7, 3, 0xFF, 0xFF, 0xF0, 0xE0
				DB 0xF, 7, 0xFF, 0xFF, 0xF8, 0xF0, 0x1F, 0xF
				DB 0xFF, 0xFF, 0xFC, 0xF8, 0x1F, 0xF, 0xFF, 0xFF
				DB 0xFC, 0xF8, 0x3F, 0x1F, 0xFF, 0xFF, 0xFE, 0xFC
				DB 0x3F, 0x19, 0xFF, 0xFF, 0xFE, 0xFC, 0x3F, 0x19
				DB 0xFF, 0xFF, 0xFE, 0xFC, 0x3F, 0x1C, 0xFF, 0xFF
				DB 0xFE, 0xFC, 0x1F, 0xC, 0xFF, 0x7F, 0xFC, 0xF8
				DB 0x1F, 0xE, 0xFF, 0x3F, 0xFC, 0xF8, 0xF, 7
				DB 0xFF, 7, 0xF8, 0xF0, 7, 3, 0xFF, 0xC7
				DB 0xF0, 0xE0, 3, 1, 0xFF, 0xFF, 0xE0, 0xC0
				DB 1, 0, 0xFF, 0x3E, 0xC0, 0, 0, 0
				DB 0x3E, 0, 0, 0
spr_008:        DB 4, 29
				DB 0, 0, 0x38, 0, 0x70, 0, 0, 0
				DB 0, 0, 0x7F, 0x38, 0xFC, 0x70, 0, 0
				DB 0, 0, 0xFF, 4, 0xFE, 0xE4, 0, 0
				DB 1, 0, 0xFF, 0x87, 0xFF, 0xCE, 0, 0
				DB 1, 0, 0xFF, 0xE7, 0xFF, 0xCE, 0x80, 0
				DB 3, 1, 0xFF, 0x47, 0xFF, 0xCE, 0xE0, 0x80
				DB 7, 1, 0xFF, 0x66, 0xFF, 0x1A, 0xF8, 0x60
				DB 0x3F, 6, 0xFF, 0x66, 0xFF, 0x1B, 0xFC, 0x78
				DB 0x7F, 0x3C, 0xFF, 0x32, 0xFF, 0x3D, 0xFE, 0x3C
				DB 0x7F, 0x12, 0xFF, 0x73, 0xFF, 0x3C, 0xFE, 0x3C
				DB 0xFF, 0x62, 0xFF, 0xE7, 0xFF, 0x1C, 0xFF, 0x32
				DB 0xFF, 0x62, 0xFF, 0x6D, 0xFF, 0x1E, 0xFF, 0x32
				DB 0xFF, 0x76, 0xFF, 0x4D, 0xFF, 0xDE, 0xFF, 0x32
				DB 0xFF, 0x24, 0xFF, 0x4F, 0xFF, 0xFE, 0xFF, 0x66
				DB 0xFF, 0x6C, 0xFF, 0x7F, 0xFF, 0xFE, 0xFF, 0x66
				DB 0xFF, 0x6C, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x64
				DB 0xFF, 0x72, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xE4
				DB 0xFF, 0x73, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xF4
				DB 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFA
				DB 0x7F, 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFA
				DB 0x7F, 0x3F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE
				DB 0x3F, 0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xFC
				DB 0x1F, 0xF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xFC
				DB 0xF, 7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFC, 0xF8
				DB 7, 3, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8, 0xE0
				DB 3, 0, 0xFF, 0x7F, 0xFF, 0xFF, 0xE0, 0
				DB 0, 0, 0x7F, 0x37, 0xFF, 0xFE, 0, 0
				DB 0, 0, 0x37, 3, 0xFE, 0xC0, 0, 0
				DB 0, 0, 3, 0, 0xC0, 0, 0, 0
spr_009:        DB 3, 24
				DB 0, 0, 0x10, 0, 0, 0, 0, 0
				DB 0x7C, 0x10, 0, 0, 1, 0, 0xFF, 0x7C
				DB 0, 0, 7, 0, 0xFF, 0xFF, 0xC0, 0
				DB 0x1F, 7, 0xFF, 0xE7, 0xF0, 0xC0, 0x7F, 0x1F
				DB 0xFF, 0x99, 0xFC, 0xF0, 0xFF, 0x7E, 0xFF, 0x60
				DB 0xFE, 0x7C, 0x7F, 0x39, 0xFF, 0x9C, 0xFF, 0x1E
				DB 0x3F, 7, 0xFF, 0x7B, 0xFE, 0xA4, 0x1F, 0xE
				DB 0xFF, 0xF7, 0xFC, 0xB0, 0xF, 4, 0xFF, 0xFC
				DB 0xF0, 0x60, 7, 3, 0xFF, 0x3E, 0xE0, 0x80
				DB 0xF, 7, 0xFF, 0xDE, 0xC0, 0, 0xF, 7
				DB 0xFF, 0xFD, 0xE0, 0xC0, 7, 3, 0xFF, 0xF7
				DB 0xF0, 0x60, 3, 0, 0xFF, 0xFC, 0xF0, 0xA0
				DB 0, 0, 0xFF, 0x38, 0xF8, 0x90, 0, 0
				DB 0x7F, 0x37, 0xF8, 0xF0, 0, 0, 0x7F, 0x3F
				DB 0xF0, 0xE0, 0, 0, 0x7F, 0x33, 0xE0, 0xC0
				DB 0, 0, 0xFF, 0x73, 0xC0, 0x80, 0, 0
				DB 0xFF, 0x7F, 0xE0, 0xC0, 0, 0, 0xFF, 0x61
				DB 0xE0, 0xC0, 0, 0, 0x61, 0, 0xC0, 0
spr_010:        DB 2, 15
				DB 0x1F, 0xC, 0xF0, 0, 0x1F, 0xB, 0xF8, 0xF0
				DB 0xF, 7, 0xFC, 0xF8, 0x1F, 0xF, 0xFE, 0x7C
				DB 0x3F, 0xE, 0xFE, 0xFC, 0x7F, 0x2D, 0xFE, 0x7C
				DB 0x7F, 0x2D, 0xFE, 0x6C, 0x7F, 0x25, 0xFC, 0x68
				DB 0x3F, 0x15, 0xFC, 0x68, 0x3F, 0x12, 0xFE, 0xC4
				DB 0x1F, 2, 0xFC, 0x90, 0x1F, 8, 0xF8, 0x90
				DB 0x1D, 8, 0xF0, 0x20, 0xB, 1, 0xF0, 0x20
				DB 1, 0, 0x20, 0
spr_011:        DB 2, 16
				DB 3, 0, 0xC0, 0, 7, 3, 0xF8, 0xC0
				DB 0xF, 7, 0xFC, 0xF8, 0xF, 5, 0xFE, 0xFC
				DB 0x1F, 0xC, 0xFE, 0xDC, 0x5F, 0xC, 0xFE, 0x9C
				DB 0xFD, 0x48, 0xDE, 0x88, 0xEE, 0x44, 0xDF, 0x82
				DB 0xEE, 0x44, 0xFF, 0x26, 0x7F, 0x2F, 0x7E, 0x6C
				DB 0x3F, 0xE, 0x7E, 0x6C, 0x3F, 0x16, 0x7E, 0x64
				DB 0x3F, 0x12, 0x7E, 0x64, 0x3F, 0x12, 0xE7, 0x42
				DB 0x1F, 9, 0xE7, 0x42, 9, 0, 0x42, 0
spr_012:        DB 3, 39
				DB 0, 0, 0x80, 0, 0, 0, 1, 0
				DB 0xC0, 0x80, 0, 0, 3, 1, 0xC0, 0x80
				DB 4, 0, 7, 2, 0xC0, 0x80, 0xE0, 4
				DB 0xF, 6, 0xC0, 0x80, 0xE, 4, 0xF, 6
				DB 0xC0, 0x80, 0x1F, 0xA, 0x1F, 0xE, 0xFF, 0x40
				DB 0x1F, 0xA, 0x1F, 0xC, 0xFF, 0x5F, 0xBF, 0x1A
				DB 0x1F, 0xC, 0xFF, 0x5F, 0xFF, 0x92, 0x1F, 0xC
				DB 0xFF, 0x5F, 0xFF, 0xB2, 0x3F, 0x1E, 0xFF, 0x5F
				DB 0xFF, 0xB2, 0x3F, 0x1E, 0xFF, 0xBD, 0xFF, 0xB2
				DB 0x3F, 0x1F, 0xFF, 0x7A, 0xFF, 0xB2, 0x3F, 0x1E
				DB 0xFF, 0xF2, 0xFF, 0xB2, 0x3F, 0x1E, 0xFF, 0xEA
				DB 0xFE, 0xBC, 0x3F, 0x1E, 0xFF, 0xCA, 0xFC, 0xF8
				DB 0x1F, 0xF, 0xFF, 0xAF, 0xF8, 0x70, 0x1F, 0xF
				DB 0xFF, 0xAF, 0xF0, 0x60, 0xF, 7, 0xFF, 0xBF
				DB 0xF0, 0x60, 7, 3, 0xFF, 0xBF, 0xE0, 0
				DB 3, 1, 0xFF, 0x7F, 0xE0, 0x40, 7, 2
				DB 0xFF, 0x64, 0xF0, 0xA0, 7, 2, 0xFF, 0x40
				DB 0xF0, 0x20, 7, 2, 0xFF, 0x1B, 0xF0, 0x20
				DB 7, 3, 0xFF, 0x20, 0xF0, 0xA0, 7, 3
				DB 0xFF, 0xC0, 0xE0, 0x40, 7, 3, 0xFF, 0xFF
				DB 0xC0, 0x80, 7, 3, 0xFF, 0xFF, 0x80, 0
				DB 7, 3, 0xFF, 0x8F, 0x80, 0, 7, 3
				DB 0xFF, 0x16, 0, 0, 7, 3, 0xFE, 0x3C
				DB 0, 0, 3, 1, 0xFC, 0x78, 0, 0
				DB 3, 1, 0xF8, 0x70, 0, 0, 3, 1
				DB 0xF8, 0xF0, 0, 0, 3, 1, 0xF0, 0xE0
				DB 0, 0, 3, 1, 0xE0, 0xC0, 0, 0
				DB 3, 1, 0xC0, 0x80, 0, 0, 3, 1
				DB 0x80, 0, 0, 0, 1, 0, 0, 0
				DB 0, 0
spr_013:        DB 3, 33
				DB 0x20, 0, 0, 0, 0, 0, 0x70, 0x20
				DB 0, 0, 0, 0, 0x78, 0x30, 0, 0
				DB 0, 0, 0x7C, 0x38, 0x7F, 0, 0x10, 0
				DB 0x7E, 0x3C, 0xFF, 0x7F, 0xB8, 0x10, 0x7F, 0x3E
				DB 0xFF, 0xFF, 0xF8, 0xB0, 0xFF, 0x7F, 0xFF, 0x7F
				DB 0xFC, 0xB8, 0xFF, 0x7F, 0xFF, 0xBF, 0xFC, 0xB8
				DB 0xFF, 0x7F, 0xFF, 0xDF, 0xFE, 0xBC, 0xFF, 0x7F
				DB 0xFF, 0xDF, 0xFE, 0x7C, 0xFF, 0x7F, 0xFF, 0xEF
				DB 0xFE, 0x7C, 0xFF, 0x7F, 0xFF, 0xFF, 0xFE, 0xFC
				DB 0xFF, 0x7F, 0xFF, 0xFF, 0xFC, 0xF8, 0x7F, 7
				DB 0xFF, 0xFF, 0xF8, 0xF0, 7, 1, 0xFF, 0xFF
				DB 0xF0, 0xE0, 1, 0, 0xFF, 0x7C, 0xE0, 0
				DB 0, 0, 0xFF, 0x33, 0xF0, 0xE0, 1, 0
				DB 0xFF, 0xCF, 0xF8, 0xF0, 1, 0, 0xFF, 0xDF
				DB 0xF8, 0xF0, 0, 0, 0xFF, 0x3E, 0xF8, 0x70
				DB 0, 0, 0x7F, 0x3C, 0xF8, 0xF0, 0, 0
				DB 0xFF, 0x79, 0xFC, 0xF8, 0, 0, 0xFF, 0x79
				DB 0xFC, 0xF8, 0, 0, 0xFF, 0x78, 0xFC, 0xF8
				DB 0, 0, 0xFF, 0x78, 0xFC, 0xF8, 0, 0
				DB 0x7F, 0x3C, 0xFE, 0x7C, 0, 0, 0x3F, 0xF
				DB 0xFE, 0xFC, 0, 0, 0xF, 3, 0xFE, 0xFC
				DB 0, 0, 3, 0, 0xFE, 0xFC, 0, 0
				DB 0, 0, 0xFF, 0x3E, 0, 0, 0, 0
				DB 0x3F, 0xE, 0, 0, 0, 0, 0xF, 2
				DB 0, 0, 0, 0, 2, 0
spr_014:        DB 132, 32
				DB 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0x1F, 0x1F, 0, 0, 3, 3
				DB 0, 0, 0x3F, 0x3F, 0x80, 0x80, 7, 7
				DB 0, 0, 0x7F, 0x7F, 0xC0, 0xC0, 0xF, 0xF
				DB 0, 0, 0xFB, 0xFB, 0xE0, 0xE0, 0x1F, 0x1F
				DB 1, 1, 0xF1, 0xF1, 0xF0, 0xF0, 0x3E, 0x3E
				DB 3, 3, 0xE0, 0xE0, 0xF8, 0xF8, 0x7C, 0x7C
				DB 7, 7, 0xC0, 0xC0, 0x7C, 0x7C, 0xF8, 0xF8
				DB 0xF, 0xF, 0x80, 0x80, 0x3D, 0x3D, 0xF0, 0xF0
				DB 0x1F, 0x1F, 0, 0, 0x1B, 0x1B, 0xE0, 0xE0
				DB 0x3E, 0x3E, 0, 0, 7, 7, 0xC0, 0xC0
				DB 0x3C, 0x3C, 0, 0, 0xF, 0xF, 0x80, 0x80
				DB 0x38, 0x38, 0, 0, 0x1F, 0x1F, 0x60, 0x60
				DB 0x3C, 0x3C, 0, 0, 0x3E, 0x3E, 0xF0, 0xF0
				DB 0x3E, 0x3E, 0, 0, 0x7C, 0x7C, 0xF8, 0xF8
				DB 0x1F, 0x1F, 0, 0, 0xF8, 0xF8, 0x7C, 0x7C
				DB 0xF, 0xF, 0x81, 0x81, 0xF0, 0xF0, 0x3E, 0x3E
				DB 7, 7, 0xC3, 0xC3, 0xE0, 0xE0, 0x1F, 0x1F
				DB 3, 3, 0xE7, 0xE7, 0xC0, 0xC0, 0xF, 0xF
				DB 1, 1, 0xF7, 0xF7, 0x80, 0x80, 7, 7
				DB 0, 0, 0xFB, 0xFB, 0, 0, 3, 3
				DB 0, 0, 0x7C, 0x7C, 0, 0, 0, 0
				DB 0, 0, 0x3E, 0x3E, 0, 0, 0, 0
				DB 0, 0, 0xDF, 0xDF, 0, 0, 0, 0
				DB 1, 1, 0xEF, 0xEF, 0x80, 0x80, 0, 0
				DB 3, 3, 0xE7, 0xE7, 0xC0, 0xC0, 0, 0
				DB 7, 7, 0xC3, 0xC3, 0xE0, 0xE0, 0, 0
				DB 0xF, 0xF, 0x81, 0x81, 0xF0, 0xF0, 0, 0
				DB 0x1F, 0x1F, 0, 0, 0xF8, 0xF8, 0, 0
				DB 0x3E, 0x3E, 0, 0, 0x7C, 0x7C, 0, 0
				DB 0x3C, 0x3C, 0, 0, 0x3C, 0x3C, 0, 0
spr_015:        DB 3, 1
				DB 0x3C, 0x3C, 0, 0, 0x3C, 0x3C
spr_016:        DB 1, 24
				DB 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0
spr_017:        DB 2, 64
				DB 0x87, 0x87, 0xF0, 0xF0, 0x58, 0x58, 0xC, 0xC
				DB 0x20, 0x20, 2, 2, 0x40, 0x40, 1, 1
				DB 0x40, 0x40, 1, 1, 0x40, 0x40, 1, 1
				DB 0x40, 0x40, 1, 1, 0x20, 0x20, 2, 2
				DB 0x20, 0x20, 2, 2, 0x20, 0x20, 2, 2
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x10, 0x10, 4, 4, 0x10, 0x10, 4, 4
				DB 0x20, 0x20, 4, 4, 0x20, 0x20, 2, 2
				DB 0x20, 0x20, 2, 2, 0x20, 0x20, 2, 2
				DB 0x40, 0x40, 2, 2, 0x47, 0x47, 0x82, 0x82
				DB 0x58, 0x58, 0xF2, 0xF2, 0x60, 0x60, 0x89, 0x89
				DB 0x40, 0x40, 0x85, 0x85, 0x40, 0x40, 0x83, 0x83
				DB 0x20, 0x20, 0x81, 0x81, 0x18, 0x18, 0x81, 0x81
				DB 7, 7, 0x81, 0x81, 0xC0, 0xC0, 1, 1
				DB 0x60, 0x60, 2, 2, 0x10, 0x10, 4, 4
				DB 0xE, 0xE, 0x18, 0x18, 1, 1, 0xE0, 0xE0
filler:         DB 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0
spr_018:        DB 2, 16
				DB 3, 3, 0xC3, 0xC3, 4, 4, 0x2C, 0x2C
				DB 8, 8, 0x10, 0x10, 8, 8, 0x10, 0x10
				DB 4, 4, 0x10, 0x10, 7, 7, 0x90, 0x90
				DB 0xD, 0xD, 0x70, 0x70, 9, 9, 0x10, 0x10
				DB 9, 9, 0x10, 0x10, 9, 9, 0xE0, 0xE0
				DB 4, 4, 0, 0, 2, 2, 0, 0
				DB 1, 1, 0x80, 0x80, 0, 0, 0x70, 0x70
				DB 0, 0, 0xC, 0xC, 0, 0, 3, 3
spr_019:        DB 2, 8
				DB 0, 0, 3, 3, 0, 0, 0xC, 0xC
				DB 0, 0, 0x30, 0x30, 0, 0, 0xC0, 0xC0
				DB 3, 3, 0, 0, 0xC, 0xC, 0, 0
				DB 0x30, 0x30, 0, 0, 0xC0, 0xC0, 0, 0
spr_020:        DB 4, 28
				DB 0, 0, 1, 0, 0x80, 0, 0, 0, 0, 0, 7, 1, 0xE0, 0x80
				DB 0, 0, 0, 0, 0x1F, 6, 0xF8, 0xA0, 0, 0, 0, 0, 0x7F
				DB 0x1E, 0xFE, 0x50, 0, 0, 1, 0, 0xFF, 0x7E, 0xFF, 0xAA
				DB 0x80, 0, 7, 1, 0xFF, 0xFE, 0xFF, 0x55, 0xE0, 0, 0x1F
				DB 7, 0xFF, 0xFE, 0xFF, 0xAA, 0xF8, 0x80, 0x7F, 0x1F
				DB 0xFF, 0xFE, 0xFF, 0x55, 0xFE, 0x50, 0xFF, 0x7F, 0xFF
				DB 0xFE, 0xFF, 0xAA, 0xFF, 0xAA, 0xFF, 0x7F, 0xFF, 0xFE
				DB 0xFF, 0x55, 0xFF, 0x54, 0xFF, 0x7F, 0xFF, 0xFE, 0xFF
				DB 0xAA, 0xFF, 0xAA, 0xFF, 0x7F, 0xFF, 0xFE, 0xFF, 0x55
				DB 0xFF, 0x54, 0xFF, 0x7F, 0xFF, 0xF9, 0xFF, 0x8A, 0xFF
				DB 0xAA, 0xFF, 0x7F, 0xFF, 0xE7, 0xFF, 0xE5, 0xFF, 0x54
				DB 0xFF, 0x7F, 0xFF, 0x9F, 0xFF, 0xF8, 0xFF, 0xAA, 0xFF
				DB 0x7E, 0xFF, 0x7F, 0xFF, 0xFE, 0xFF, 0x54, 0xFF, 0x79
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x8A, 0xFF, 0x67, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0xE4, 0xFF, 0x5F, 0xFF, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFA, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF
				DB 0xFF, 0xFF, 0xFE, 0x7F, 0x1F, 0xFF, 0xFF, 0xFF, 0xFF
				DB 0xFE, 0xF8, 0x1F, 7, 0xFF, 0xFF, 0xFF, 0xFF, 0xF8
				DB 0xE0, 7, 1, 0xFF, 0xFF, 0xFF, 0xFF, 0xE0, 0x80, 1
				DB 0, 0xFF, 0x7F, 0xFF, 0xFE, 0x80, 0, 0, 0, 0x7F, 0x1F
				DB 0xFE, 0xF8, 0, 0, 0, 0, 0x1F, 7, 0xF8, 0xE0, 0, 0
				DB 0, 0, 7, 1, 0xE0, 0x80, 0, 0, 0, 0, 1, 0, 0x80, 0
				DB 0, 0
spr_021:        DB 2, 17
				DB 0xE, 0, 0x38, 0, 0x1F, 0xE, 0x7C, 0x38, 0x1F, 0xB
				DB 0xFC, 0x78, 0xF, 5, 0xF8, 0x70, 0xE, 3, 0xF0, 0x60
				DB 0xF, 3, 0xF8, 0xE0, 0x1F, 0xD, 0xFC, 0xF8, 0x1F, 0xD
				DB 0xFC, 0xF8, 0x1F, 0xD, 0xFC, 0xF8, 0x1F, 0xD, 0xFC
				DB 0xF8, 0x1F, 0xE, 0xFC, 0x38, 0xF, 5, 0xF8, 0xD0, 7
				DB 2, 0xF0, 0xE0, 7, 2, 0xF0, 0xE0, 7, 2, 0xF0, 0xE0
				DB 3, 1, 0xE0, 0x40, 1, 0, 0xC0, 0
spr_022:        DB 3, 21
				DB 3, 0, 0xE0, 0, 0, 0, 7, 3, 0xF0, 0xE0, 0, 0, 0xF, 7
				DB 0xF8, 0xF0, 0, 0, 0x1F, 0xC, 0xFC, 0x18, 0, 0, 0x1F
				DB 0xB, 0xFE, 0xE4, 0x70, 0, 0x1F, 7, 0xFF, 0xFA, 0xF8
				DB 0x70, 0x1F, 0xF, 0xFF, 0xFD, 0xFC, 0xF8, 0x1F, 9, 0xFF
				DB 0xFE, 0xFC, 0x18, 0x1F, 0xC, 0xFF, 0xEF, 0xFC, 0xE8
				DB 0xF, 6, 0xFF, 0xDF, 0xF8, 0x70, 7, 3, 0xFF, 0xBB, 0xFC
				DB 0xB8, 3, 0, 0xBF, 0x1F, 0xF8, 0xB0, 0, 0, 0x1F, 0xB
				DB 0xF8, 0xD0, 0, 0, 0x1F, 0xF, 0xF0, 0xE0, 0, 0, 0x1F
				DB 0xB, 0xF0, 0xE0, 0, 0, 0x1F, 0xC, 0xF8, 0x10, 0, 0
				DB 0x3F, 0x18, 0xFC, 8, 0, 0, 0x3F, 0x10, 0xFC, 8, 0
				DB 0, 0x1F, 8, 0xF8, 0x30, 0, 0, 0xF, 7, 0xF0, 0xC0, 0
				DB 0, 7, 0, 0xC0, 0
spr_023:        DB 2, 60
				DB 0xC0, 0, 0, 0, 0xF0, 0xC0, 0, 0, 0xF8, 0xF0, 0, 0
				DB 0xF0, 0xE0, 0, 0, 0xE0, 0x40, 0, 0, 0xF0, 0x60, 0
				DB 0, 0xF0, 0x60, 0, 0, 0xF0, 0x60, 0, 0, 0xF8, 0x70
				DB 0, 0, 0xF8, 0x30, 0, 0, 0xF8, 0x30, 0, 0, 0xF8, 0x70
				DB 0, 0, 0xF0, 0x60, 0, 0, 0xF0, 0x60, 0, 0, 0xE0, 0xC0
				DB 0, 0, 0xE0, 0xC0, 0, 0, 0xE0, 0xC0, 0, 0, 0xF0, 0xE0
				DB 0, 0, 0xF8, 0x70, 0, 0, 0xF8, 0x70, 0, 0, 0xFC, 0x78
				DB 0, 0, 0x7C, 0x38, 0, 0, 0x7C, 0x38, 0, 0, 0x7C, 0x38
				DB 0, 0, 0x3C, 0x18, 0, 0, 0x3C, 0x18, 0, 0, 0x3C, 0x18
				DB 0, 0, 0x1C, 8, 0, 0, 0x1E, 0xC, 0, 0, 0x3E, 0x1C, 0
				DB 0, 0x3E, 0x1C, 0, 0, 0x3C, 0x18, 0, 0, 0x7E, 0x38
				DB 0, 0, 0xFF, 0x5E, 0x80, 0, 0xFF, 0x4F, 0xC0, 0x80
				DB 0xFF, 0x67, 0xE0, 0x80, 0xFF, 0x63, 0xF0, 0xA0, 0xFF
				DB 0x77, 0xF0, 0x20, 0xFF, 0x37, 0xF8, 0x30, 0xFF, 0x6F
				DB 0xFD, 0x18, 0xFF, 0x6F, 0xFF, 0x1C, 0xFF, 0x5E, 0xFF
				DB 0x4E, 0xFF, 0x5E, 0xFF, 0x46, 0xFF, 0x5C, 0xFF, 0x66
				DB 0xFF, 0x5C, 0xFF, 0x23, 0xFF, 0x43, 0xFF, 0x33, 0x7F
				DB 0x2C, 0xFF, 0x11, 0x7F, 0x2C, 0xFF, 0x18, 0x7F, 0x2C
				DB 0xFF, 0x31, 0x7F, 0x24, 0xFF, 0x31, 0x3F, 4, 0x7F
				DB 0x30, 0x1E, 4, 0x7F, 0x30, 0xE, 4, 0x7B, 0x20, 6, 0
				DB 0x7B, 0x20, 0, 0, 0x79, 0x20, 0, 0, 0x38, 0x10, 0
				DB 0, 0x38, 0x10, 0, 0, 0x38, 0x10, 0, 0, 0x10, 0, 0
				DB 0, 0, 0
spr_024:        DB 2, 48
				DB 0, 0, 0x60, 0, 0, 0, 0xF8, 0x60, 3, 0, 0xF8, 0xD8
				DB 0xF, 3, 0xFF, 0x7E, 0x1F, 0xC, 0xFF, 0xCD, 0x1F, 0xA
				DB 0xFF, 0x8D, 0x1F, 0xA, 0xFF, 0xC5, 0x1F, 8, 0xFF, 0xCB
				DB 0x1F, 9, 0xFF, 0xE3, 0x1F, 0xD, 0xFF, 0xA6, 0xF, 5
				DB 0xFF, 0xA6, 0xF, 4, 0xFF, 0xAC, 0x1F, 8, 0xFF, 0xA6
				DB 0x1F, 0xC, 0xFF, 0xE2, 0xF, 5, 0xFF, 0xEA, 0xF, 5
				DB 0xFF, 0xEA, 0x1F, 0xC, 0xFF, 0xEB, 0x1F, 0xC, 0xFF
				DB 0x69, 0x1F, 0xE, 0xFF, 0x5A, 0x1F, 0xC, 0xFF, 0xD6
				DB 0x1F, 0xD, 0xFF, 0xC6, 0x1F, 0xD, 0xFF, 0x56, 0x3F
				DB 0x1D, 0xFF, 0x96, 0x3F, 0x19, 0xFF, 0xAE, 0x3F, 0x13
				DB 0xFF, 0x2E, 0x7F, 0x26, 0xFF, 0x46, 0xFF, 0x4C, 0xFF
				DB 0x86, 0xFF, 0x89, 0xFF, 0x86, 0xFF, 0x13, 0xFF, 0xE
				DB 0xFF, 0x67, 0xFF, 0xE, 0xFF, 0xC6, 0xFF, 0xE, 0xFF
				DB 0xCE, 0xFE, 0xC, 0xFF, 0x8E, 0xFE, 0x4C, 0xFF, 0x8E
				DB 0xFF, 0x4E, 0xFF, 0x8E, 0xFF, 0x4E, 0xFF, 0x8E, 0xFF
				DB 0x66, 0xFF, 0x8E, 0xFF, 0x66, 0xFF, 0x8E, 0xFF, 0x72
				DB 0xFF, 0x8F, 0xFF, 0x32, 0xFF, 0xC7, 0xFF, 0x1A, 0xFF
				DB 0xC7, 0xFF, 0x9A, 0xF7, 0x43, 0xFE, 0x98, 0xF3, 0x61
				DB 0xFC, 0xC8, 0xF1, 0x20, 0xFC, 0xC8, 0x70, 0, 0xFC
				DB 0x48, 0x20, 0, 0x7C, 0x28, 0, 0, 0x3C, 8, 0, 0, 8
				DB 0
spr_025:        DB 3, 20
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0
				DB 0, 0x1C, 8, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0x20, 0, 0, 0, 0, 0, 0x70, 0x20, 0, 0, 0, 0, 0x20
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x10, 0, 0
				DB 0, 0, 0, 0x38, 0x10, 0, 0, 0x80, 0, 0x10, 0, 0x11
				DB 0, 0xC0, 0x80, 0, 0, 0x38, 0x10, 0x80, 0, 0, 0, 0x7C
				DB 0x38, 0, 0, 0, 0, 0x38, 0x10, 0, 0, 0, 0, 0x10, 0
				DB 0, 0, 1, 0, 0, 0, 0, 0, 3, 1, 0x80, 0, 0, 0, 1, 0
				DB 0, 0, 0, 0
spr_026:        DB 3, 21
				DB 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0x1C, 8, 0, 0
				DB 0, 0, 0x3E, 0x1C, 0, 0, 0, 0, 0x1C, 8, 0, 0, 0, 0
				DB 8, 0, 0x1C, 8, 0x70, 0x20, 0, 0, 0x3E, 0x1C, 0xF8
				DB 0x70, 1, 0, 0x1C, 8, 0x70, 0x20, 3, 1, 0x88, 0, 0x20
				DB 0, 0x11, 0, 0, 0, 0, 0, 0x38, 0x10, 0, 0, 0x80, 0
				DB 0x7C, 0x38, 0x11, 0, 0xC0, 0x80, 0x38, 0x10, 0x3B
				DB 0x11, 0xE0, 0xC0, 0x10, 0, 0x7D, 0x38, 0xC0, 0x80
				DB 0, 0, 0xFE, 0x7C, 0x80, 0, 0, 0, 0x7C, 0x38, 0, 0
				DB 1, 0, 0x38, 0x10, 0, 0, 3, 1, 0x90, 0, 0, 0, 7, 3
				DB 0xC0, 0x80, 0, 0, 3, 1, 0x80, 0, 0, 0, 1, 0, 0, 0
				DB 0, 0
spr_027:        DB 3, 23
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0
				DB 0, 0x1C, 8, 8, 0, 0, 0, 8, 0, 0x1C, 8, 0, 0, 0, 0
				DB 0x3E, 0x1C, 0x20, 0, 1, 0, 0x7F, 0x3E, 0x70, 0x20
				DB 3, 1, 0xBE, 0x1C, 0x20, 0, 0x17, 3, 0xDC, 0x88, 0
				DB 0, 0x3B, 0x11, 0x88, 0, 0x80, 0, 0x7D, 0x38, 0x11
				DB 0, 0xC0, 0x80, 0xFE, 0x7C, 0x3B, 0x11, 0xE0, 0xC0
				DB 0x7C, 0x38, 0x7F, 0x3B, 0xF0, 0xE0, 0x38, 0x10, 0xFF
				DB 0x7D, 0xE0, 0xC0, 0x11, 0, 0xFF, 0xFE, 0xC0, 0x80
				DB 0, 0, 0xFE, 0x7C, 0x80, 0, 0, 0, 0x7C, 0x38, 0, 0
				DB 1, 0, 0x38, 0x10, 0, 0, 3, 1, 0x90, 0, 0, 0, 1, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0x80, 0, 0, 0, 1, 0, 0xC0
				DB 0x80, 0, 0, 0, 0, 0x80, 0
spr_028:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0x1C, 8, 8, 0
				DB 0, 0, 0x3E, 0x1C, 0x1C, 1, 0, 0, 0x1C, 8, 0x3E, 0x1C
				DB 0x20, 0, 9, 0, 0x7F, 0x3E, 0x70, 0x20, 3, 1, 0xFF
				DB 0x7F, 0xF8, 0x70, 0x17, 3, 0xFF, 0xBE, 0x70, 0x20
				DB 0x3F, 0x17, 0xFE, 0xDC, 0x20, 0, 0x7F, 0x3B, 0xDC
				DB 0x88, 0, 0, 0xFF, 0x7D, 0x88, 0, 0x80, 0, 0xFF, 0xFE
				DB 1, 0, 0xC0, 0x80, 0xFE, 0x7C, 0x13, 1, 0xE0, 0xC0
				DB 0x7C, 0x38, 0x39, 0x10, 0xC8, 0x80, 0x38, 0x10, 0x7C
				DB 0x38, 0x9C, 8, 0x10, 0, 0x38, 0x10, 8, 0, 1, 0, 0x10
				DB 0, 0, 0, 3, 0x10, 0x80, 0, 0, 0, 7, 3, 0xC0, 0x80
				DB 0, 0, 3, 0x10, 0x80, 0, 0x80, 0, 1, 0, 9, 0, 0xC0
				DB 0x80, 0, 0, 0x1F, 9, 0xE0, 0xC0, 0, 0, 9, 0, 0xC0
				DB 0x80, 0, 0, 0, 0, 0x80, 0
spr_029:        DB 3, 24
				DB 8, 0, 0x70, 0x20, 0, 0, 0x1C, 8, 0xF8, 0x70, 8, 0
				DB 0x3F, 0x1C, 0xFC, 0xF8, 0x3C, 8, 0x7F, 0x36, 0xF8
				DB 0x70, 0x78, 0x20, 0x3E, 0x1C, 0x78, 0x20, 0xF8, 0x70
				DB 0x1C, 8, 0x3D, 8, 0xFC, 0xF8, 8, 0, 0x3F, 0x1D, 0xFE
				DB 0xFC, 1, 0, 0x1D, 8, 0xFC, 0xF8, 0x13, 1, 0xC8, 0
				DB 0xF8, 0x70, 0x39, 0x10, 0xE0, 0x40, 0x70, 0x40, 0x7C
				DB 0x38, 0x50, 0, 0x20, 0, 0xFE, 0x7C, 0x38, 0x10, 0x80
				DB 0, 0x7F, 0x3A, 0x7D, 0x38, 0xC8, 0x80, 0x3A, 0x10
				DB 0xFE, 0x7C, 0x9C, 8, 0x11, 0, 0xFF, 0xFE, 0x3E, 0x1C
				DB 1, 0, 0xFF, 0x7C, 0x1C, 8, 3, 1, 0xFF, 0x39, 0x88
				DB 0, 7, 3, 0xF9, 0x90, 0, 0, 0xF, 7, 0xF0, 0xC0, 0x80
				DB 0, 7, 3, 0xC1, 0x80, 0xC0, 0x80, 3, 1, 0x8B, 1, 0xE0
				DB 0xC0, 1, 0, 0x1F, 0xB, 0xF0, 0xE0, 0, 0, 0xB, 1, 0xE0
				DB 0xC0, 0, 0, 1, 0, 0xC0, 0x80
spr_030:        DB 3, 24
				DB 0x1C, 8, 0, 0, 8, 0, 0x3E, 0x1C, 0x20, 0, 0x1C, 8
				DB 0x7F, 0x3E, 0x78, 0x20, 0x3E, 0x1C, 0xFF, 0x7F, 0xBC
				DB 8, 0x1C, 8, 0x7F, 0x3E, 0x3E, 0x1C, 0x28, 0, 0x3F
				DB 0x1C, 0x7F, 0x3E, 0x70, 0x20, 0x1F, 9, 0xFF, 0x7F
				DB 0xF8, 0x70, 0xF, 3, 0xFF, 0xBE, 0x70, 0x20, 0xF, 7
				DB 0xFE, 0xDC, 0xA0, 0, 7, 3, 0xDD, 0x88, 0xC0, 0x80
				DB 0x13, 1, 0x8B, 1, 0xE0, 0xC0, 0x3B, 0x10, 7, 3, 0xF8
				DB 0xE0, 0x17, 2, 0x13, 1, 0xFC, 0xC8, 0xF, 7, 0xB9, 0x10
				DB 0xFE, 0x9C, 7, 2, 0x7D, 0x38, 0xFF, 0x3E, 3, 1, 0xBB
				DB 0x11, 0xBE, 0x1C, 7, 3, 0xD7, 0x83, 0xDC, 0x11, 0xF
				DB 7, 0xE3, 0xC1, 0x88, 0, 0x1F, 0xF, 0xF9, 0xE0, 0, 0
				DB 0xF, 7, 0xFC, 0xC8, 0x80, 0, 7, 3, 0xFF, 0x9C, 0xC0
				DB 0x80, 3, 1, 0xFF, 0x3F, 0xE0, 0xC0, 1, 0, 0xBF, 0x1C
				DB 0xC0, 0x80, 0, 0, 0x1C, 8, 0x80, 0
spr_031:        DB 3, 19
				DB 0, 0, 0x7F, 8, 0, 0, 0, 0, 0xFF, 0x5D, 0x80, 0, 1
				DB 0, 0xFF, 0xDD, 0xC0, 0x80, 3, 1, 0xFF, 0xBE, 0xE0
				DB 0xC0, 3, 1, 0xFF, 0xBE, 0xE0, 0xC0, 7, 3, 0xFF, 0x7F
				DB 0xF0, 0x60, 0xF, 7, 0xFF, 0x7F, 0xF8, 0x70, 0xF, 6
				DB 0xFF, 0xFF, 0xF8, 0xB0, 0x1F, 0xE, 0xFF, 0xFF, 0xFC
				DB 0xB8, 0x3F, 0x1D, 0xFF, 0xFF, 0xFE, 0x5C, 0x3F, 0x1D
				DB 0xFF, 0, 0xFE, 0xAC, 0x7F, 0x37, 0xFF, 0x7F, 0xFF
				DB 0x76, 0x7F, 0x2F, 0xFF, 0x7F, 0xFF, 0x7A, 0x3F, 0x1E
				DB 0xFF, 0x80, 0xFE, 0xBC, 0x1F, 0xD, 0xFF, 0xFF, 0xFC
				DB 0xD8, 0xF, 3, 0xFF, 0xFF, 0xF8, 0xE0, 3, 1, 0xFF, 0xFF
				DB 0xE0, 0xC0, 1, 0, 0xFF, 0xFF, 0xC0, 0x80, 0, 0, 0xFF
				DB 0, 0x80, 0
spr_032:        DB 3, 22
				DB 0, 0, 0xFF, 0, 0, 0, 7, 0, 0xFF, 0xFF, 0xE0, 0, 0x1F
				DB 7, 0xFF, 0xFF, 0xF8, 0xE0, 0x3F, 0x1E, 0xFF, 0x7E
				DB 0xFC, 0x78, 0x7F, 0x3E, 0xFF, 0x99, 0xFE, 0x7C, 0x7F
				DB 0x3F, 0xFF, 0xE7, 0xF8, 0xFC, 0xFF, 0x7F, 0xFF, 0x99
				DB 0xFF, 0xFE, 0xFF, 0x7E, 0xFF, 0x66, 0xFF, 0x7E, 0xFF
				DB 0x7E, 0xFF, 0x66, 0xFF, 0x7E, 0xFF, 0x7F, 0xFF, 0xC3
				DB 0xFF, 0xFE, 0x7F, 0x3F, 0xFF, 0xC3, 0xFE, 0xFC, 0x7F
				DB 0x3E, 0xFF, 0xE7, 0xFE, 0x7C, 0x3F, 0x1F, 0xFF, 0x7E
				DB 0xFC, 0xF8, 0x1F, 7, 0xFF, 0x7E, 0xF8, 0xE0, 7, 0
				DB 0xFF, 0x7E, 0xE0, 0, 0, 0, 0xFF, 0x7E, 0, 0, 0, 0
				DB 0xFF, 0x7E, 0, 0, 0, 0, 0xFF, 0x42, 0, 0, 1, 0, 0xFF
				DB 0xBD, 0x80, 0, 0, 0, 0xFF, 0x7E, 0, 0, 0, 0, 0x7E
				DB 0x3C, 0, 0, 0, 0, 0x3C, 0, 0, 0
spr_033:        DB 3, 23
				DB 0, 0, 0x7E, 0, 0, 0, 3, 0, 0xFF, 0x7E, 0xC0, 0, 7
				DB 1, 0xFF, 0xFF, 0xE0, 0xC0, 0xF, 1, 0xFF, 0xE7, 0xF0
				DB 0xE0, 0x1F, 0xC, 0xFF, 0xDB, 0xF8, 0xF0, 0xF, 6, 0xFF
				DB 0x3D, 0xF0, 0xE0, 7, 3, 0xFF, 0x81, 0xE0, 0xC0, 1
				DB 0, 0xFF, 0x5E, 0x80, 0, 3, 3, 0xFF, 0xBF, 0xC0, 0xC0
				DB 7, 3, 0xFF, 0x7F, 0xE0, 0xC0, 0xF, 6, 0xFF, 0, 0xF0
				DB 0xE0, 0x1F, 8, 0xFF, 0xFF, 0xF8, 0x10, 0x1F, 5, 0xFF
				DB 0xFF, 0xF8, 0xE0, 0x1F, 9, 0xFF, 0, 0xFC, 0xF0, 0x3F
				DB 0x18, 0xFF, 0xFF, 0xFC, 0x18, 0x3F, 0x17, 0xFF, 0
				DB 0xFC, 0xE8, 0x3F, 8, 0xFF, 0, 0xFC, 0x10, 0x3F, 0x10
				DB 0xFF, 0, 0xFC, 8, 0x3F, 0x10, 0xFF, 0, 0xFC, 8, 0x1F
				DB 8, 0xFF, 0, 0xF8, 0x10, 0xF, 7, 0xFF, 0, 0xF0, 0xE0
				DB 7, 0, 0xFF, 0xFF, 0xE0, 0, 0, 0, 0xFF, 0, 0, 0
spr_034:        DB 3, 18
				DB 7, 0, 0xFC, 0, 0, 0, 0xF, 7, 0xFE, 0xFC, 0, 0, 0x1F
				DB 0xE, 0xFF, 0xE, 0, 0, 0x1F, 9, 0xFF, 0xF2, 0, 0, 0xF
				DB 7, 0xFF, 0xFC, 0xF8, 0, 0x1F, 0xF, 0xFF, 0xFE, 0xFC
				DB 0xF8, 0x3F, 0x1F, 0xFF, 0xFF, 0xFE, 0x7C, 0x7F, 0x3F
				DB 0xFF, 0xFF, 0xFE, 0x8C, 0x7F, 0x3E, 0xFF, 0xF, 0xFF
				DB 0x86, 0xFF, 0x71, 0xFF, 0xF1, 0xFF, 0xC6, 0xFF, 0x4E
				DB 0xFF, 0xE, 0xFF, 0x46, 0xFF, 0x30, 0xFF, 1, 0xFF, 0x86
				DB 0xFF, 0x40, 0xFF, 0, 0xFE, 0x5C, 0xFF, 0x40, 0xFF
				DB 0, 0xFC, 0x58, 0x7F, 0x30, 0xFF, 1, 0xD8, 0x80, 0x3F
				DB 0xE, 0xFF, 0xE, 0x80, 0, 0xF, 1, 0xFE, 0xF0, 0, 0
				DB 1, 0, 0xF0, 0, 0, 0
spr_035:        DB 3, 24
				DB 0, 0, 0xFE, 0, 0, 0, 3, 0, 0xFF, 0xFE, 0x80, 0, 7
				DB 2, 0xFF, 0xFF, 0xC0, 0x80, 0xF, 4, 0xFF, 3, 0xE0, 0xC0
				DB 0xF, 4, 0xFF, 0xFB, 0xE0, 0xC0, 0xF, 0, 0xFF, 0xFB
				DB 0xE0, 0xC0, 0xF, 4, 0xFF, 0xFB, 0xE0, 0xC0, 0xF, 4
				DB 0xFF, 0xFB, 0xE0, 0xC0, 0xF, 4, 0xFF, 0xFB, 0xE0, 0xC0
				DB 0xF, 4, 0xFF, 3, 0xE0, 0xC0, 0xF, 4, 0xFF, 0xFF, 0xE0
				DB 0xC0, 0xF, 2, 0xFF, 0xFF, 0xE0, 0xC0, 0xF, 6, 0xFF
				DB 0xFF, 0xE0, 0xC0, 7, 3, 0xFF, 0x7F, 0xC0, 0x80, 7
				DB 3, 0xFF, 0xBF, 0xC0, 0x80, 3, 1, 0xFF, 0xBF, 0x80
				DB 0, 1, 0, 0xFF, 0xDE, 0, 0, 0, 0, 0xFE, 0x5C, 0, 0
				DB 0, 0, 0xFE, 0x5C, 0, 0, 0, 0, 0xFE, 0x44, 0, 0, 1
				DB 0, 0xFF, 0xBA, 0, 0, 0, 0, 0xFE, 0x7C, 0, 0, 0, 0
				DB 0x7C, 0x38, 0, 0, 0, 0, 0x38, 0, 0, 0
spr_036:        DB 3, 21
				DB 0, 0, 0xFF, 0, 0, 0, 3, 0, 0xFF, 0xFF, 0xC0, 0, 7
				DB 3, 0xFF, 0xFF, 0xE0, 0xC0, 0xF, 7, 0xFF, 0x81, 0xF0
				DB 0xE0, 0x1F, 0xE, 0xFF, 0x7E, 0xF8, 0x70, 0xF, 5, 0xFF
				DB 0xFF, 0xF0, 0xA0, 7, 3, 0xFF, 0xFF, 0xE0, 0xC0, 0xF
				DB 7, 0xFF, 0xFF, 0xF0, 0xE0, 0xF, 7, 0xFF, 0xFF, 0xF0
				DB 0xE0, 0x1F, 0xF, 0xFF, 0xFF, 0xF8, 0xF0, 0x1F, 0xF
				DB 0xFF, 0xFF, 0xF8, 0xF0, 0x1F, 0xF, 0xFF, 0xFF, 0xF8
				DB 0xF0, 0x1F, 0xC, 0xFF, 0x7F, 0xF8, 0xF0, 0x1F, 0xC
				DB 0xFF, 0x7F, 0xF8, 0xF0, 0x1F, 0xC, 0xFF, 0x3F, 0xF8
				DB 0xF0, 0xF, 6, 0xFF, 0xF, 0xF0, 0xE0, 0xF, 7, 0xFF
				DB 0xF, 0xF0, 0xE0, 7, 3, 0xFF, 0x8F, 0xE0, 0xC0, 3, 1
				DB 0xFF, 0xFF, 0xC0, 0x80, 1, 0, 0xFF, 0x7E, 0x80, 0
				DB 0, 0, 0x7E, 0, 0, 0
spr_037:        DB 2, 16
				DB 3, 1, 0x80, 0, 0x23, 1, 0x84, 0, 0x77, 0x20, 0xCE
				DB 4, 0x3F, 0x13, 0xFC, 0xC8, 0x1F, 7, 0xF8, 0xE0, 0x1F
				DB 0xF, 0xF8, 0xF0, 0x3F, 0x1F, 0xFF, 0xF8, 0xFF, 0x1F
				DB 0xFF, 0xFB, 0xFF, 0xDF, 0xFF, 0xF8, 0xFF, 0x1F, 0xFC
				DB 0xF8, 0x3F, 0xF, 0xF8, 0xF0, 0x1F, 7, 0xF8, 0xE0, 0x3F
				DB 0x13, 0xFC, 0xC8, 0x73, 0x20, 0xCE, 4, 0x21, 0, 0xC4
				DB 0x80, 1, 0, 0xC0, 0x80
spr_038:        DB 2, 16
				DB 3, 0, 0xC0, 0, 0xF, 3, 0xF0, 0xC0, 0x1F, 0xF, 0xF8
				DB 0xD0, 0x3F, 0x1F, 0xFC, 0x38, 0x7F, 0x1E, 0xFE, 0xFC
				DB 0x7F, 0x3D, 0xFE, 0xFC, 0xFF, 0x7E, 0xFF, 0x3E, 0xFF
				DB 0x7F, 0xFF, 0xBE, 0xFF, 0x7F, 0xFF, 0xBE, 0xFF, 0x7E
				DB 0xFF, 0x7E, 0x7F, 0x35, 0xFE, 0xEC, 0x7F, 0x32, 0xFE
				DB 0xCC, 0x3F, 0x1E, 0xFC, 0xF8, 0x1F, 0xF, 0xF8, 0x30
				DB 0xF, 3, 0xF0, 0xC0, 3, 0, 0xC0, 0
spr_039:        DB 3, 20
				DB 0, 0, 0x1E, 0, 0, 0, 0, 0, 0x3F, 0x1E, 0, 0, 1, 0
				DB 0xFF, 0x3F, 0x80, 0, 3, 1, 0xFF, 0xFF, 0x80, 0, 3
				DB 1, 0xFF, 0xFE, 0xE6, 0, 0x7F, 3, 0xFF, 0xFF, 0xFF
				DB 0x66, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFE, 0xFF, 0x7F
				DB 0xFF, 0xFF, 0xFF, 0xFE, 0x7F, 0x3F, 0xFF, 0xFF, 0xFE
				DB 0xFC, 0x3F, 0x1F, 0xFF, 0xFF, 0xFE, 0xFC, 0x1F, 0xF
				DB 0xFF, 0xE7, 0xFC, 0xF8, 0xF, 7, 0xFF, 0xB, 0xF8, 0xF0
				DB 0xF, 6, 0xFF, 0x9B, 0xF8, 0xF0, 7, 2, 0xFF, 0xC7, 0xF0
				DB 0xE0, 7, 3, 0xFF, 0x3F, 0xF0, 0xE0, 3, 1, 0xFF, 0xFF
				DB 0xE0, 0xC0, 3, 1, 0xFF, 0xFF, 0xC0, 0x80, 1, 0, 0xFF
				DB 0xFF, 0x80, 0, 0, 0, 0xFF, 0x3C, 0, 0, 0, 0, 0x3C
				DB 0, 0, 0
spr_040:        DB 3, 19
				DB 0, 0, 0x1C, 0, 0, 0, 0, 0, 0x3E, 0x1C, 0, 0, 7, 0
				DB 0x3F, 0x1E, 0x38, 0, 0xF, 7, 0xFF, 0x3F, 0xFC, 0x38
				DB 0x1F, 0xF, 0xFF, 0xFF, 0xFC, 0xF8, 0xF, 7, 0xFF, 0xFF
				DB 0xFE, 0xF8, 0x7F, 7, 0xFF, 0xFF, 0xFF, 0xFE, 0xFF
				DB 0x7F, 0xFF, 0xFF, 0xFF, 0xFE, 0xFF, 0x7F, 0xFF, 0xFF
				DB 0xFF, 0xFE, 0x7F, 0x3F, 0xFF, 0xFF, 0xFE, 0xFC, 0x3F
				DB 0x1F, 0xFF, 0xE7, 0xFC, 0xF8, 0x1F, 0xF, 0xFF, 0xB
				DB 0xFC, 0xF8, 0xF, 6, 0xFF, 0x9B, 0xF8, 0xF0, 0xF, 6
				DB 0xFF, 0xC7, 0xF8, 0xF0, 0xF, 7, 0xFF, 0x3F, 0xF8, 0xF0
				DB 7, 3, 0xFF, 0xFF, 0xF0, 0xE0, 3, 1, 0xFF, 0xFF, 0xE0
				DB 0x80, 1, 0, 0xFF, 0x3C, 0x80, 0, 0, 0, 0x3C, 0, 0
				DB 0
spr_041:        DB 3, 20
				DB 0, 0, 6, 0, 0, 0, 3, 0, 0x1F, 6, 0, 0, 7, 3, 0xFF
				DB 0x1F, 0xF0, 0, 0xF, 7, 0xFF, 0xFF, 0xF8, 0xF0, 0x3F
				DB 0xF, 0xFF, 0xFF, 0xF8, 0xF0, 0x7F, 0x3F, 0xFF, 0xFF
				DB 0xFC, 0xF0, 0xFF, 0x7F, 0xFF, 0xFF, 0xFE, 0xFC, 0xFF
				DB 0x7F, 0xFF, 0xFF, 0xFF, 0xFE, 0x7F, 0x3F, 0xFF, 0xFF
				DB 0xFF, 0xFE, 0x3F, 0x1F, 0xFF, 0xFF, 0xFE, 0xFC, 0x1F
				DB 0xF, 0xFF, 0xFF, 0xFC, 0xF8, 0xF, 7, 0xFF, 0xFF, 0xFC
				DB 0x98, 0xF, 7, 0xFF, 0xFF, 0xF8, 0x50, 7, 3, 0xFF, 0xFF
				DB 0xF0, 0x20, 7, 3, 0xFF, 0xFF, 0xF0, 0x20, 3, 1, 0xFF
				DB 0xFF, 0xE0, 0xC0, 3, 1, 0xFF, 0xFF, 0xC0, 0x80, 1
				DB 0, 0xFF, 0xFF, 0x80, 0, 0, 0, 0xFF, 0x3C, 0, 0, 0
				DB 0, 0x3C, 0, 0, 0
spr_042:        DB 3, 20
				DB 0, 0, 0x1E, 0, 0, 0, 0, 0, 0x3F, 0x1E, 0, 0, 0x1E
				DB 0, 0x7F, 0x3F, 0xF0, 0, 0x3F, 0x1E, 0x7F, 0x3F, 0xF8
				DB 0x30, 0x1F, 0xF, 0xFF, 0x3F, 0xFC, 0xF8, 0x3F, 0xF
				DB 0xFF, 0xFF, 0xFC, 0xF8, 0x7F, 0x3F, 0xFF, 0xFF, 0xFE
				DB 0xFC, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFE, 0x7F, 0x3F
				DB 0xFF, 0xFF, 0xFF, 0xFE, 0x3F, 0x1F, 0xFF, 0xFF, 0xFE
				DB 0xFC, 0x1F, 0xF, 0xFF, 0xFF, 0xFC, 0xF8, 0xF, 7, 0xFF
				DB 0xFF, 0xFC, 0x98, 0xF, 7, 0xFF, 0xFF, 0xF8, 0x50, 7
				DB 3, 0xFF, 0xFF, 0xF0, 0x20, 7, 3, 0xFF, 0xFF, 0xF0
				DB 0x20, 3, 1, 0xFF, 0xFF, 0xE0, 0xC0, 3, 1, 0xFF, 0xFF
				DB 0xC0, 0x80, 1, 0, 0xFF, 0xFF, 0x80, 0, 0, 0, 0xFF
				DB 0x3C, 0, 0, 0, 0, 0x3C, 0, 0, 0
spr_043:        DB 3, 42
				DB 0x30, 0, 0, 0, 0, 0, 0x78, 0x30, 0, 0, 0, 0, 0xF8
				DB 0x70, 0, 0, 0, 0, 0x7C, 0x18, 0xC0, 0, 0, 0, 0x79
				DB 0x20, 0xE0, 0xC0, 0, 0, 0x7B, 0x31, 0xE0, 0xC0, 0
				DB 0, 0xF9, 0x70, 0xF3, 0x60, 0, 0, 0xFF, 0x78, 0xE7
				DB 0x83, 0x80, 0, 0x7F, 0x3E, 0xEF, 0xC7, 0x80, 0, 0x7F
				DB 0x37, 0xE7, 0xC1, 0xCC, 0x80, 0x7F, 0x31, 0xFF, 0xE2
				DB 0x9E, 0xC, 0xF9, 0x70, 0xFF, 0xFB, 0xBE, 0x1C, 0xFF
				DB 0x78, 0xFF, 0xDF, 0x9F, 6, 0x7F, 0x3E, 0xFF, 0xC7
				DB 0xFE, 0x88, 0x7F, 0x37, 0xE7, 0xC3, 0xFE, 0xEC, 0x7F
				DB 0x31, 0xFF, 0xE3, 0xFE, 0x7C, 0xF9, 0x70, 0xFF, 0xFB
				DB 0xFF, 0x1E, 0xFF, 0x78, 0xFF, 0xDF, 0x9F, 0xE, 0x7F
				DB 0x3E, 0xFF, 0xC7, 0xFE, 0x8C, 0x7F, 0x37, 0xE7, 0xC3
				DB 0xFE, 0xEC, 0x7F, 0x31, 0xFF, 0xE3, 0xFE, 0x7C, 0xF9
				DB 0x70, 0xFF, 0xFB, 0xFF, 0x1E, 0xFF, 0x78, 0xFF, 0xDF
				DB 0x9F, 0xE, 0x7F, 0x3E, 0xFF, 0xC7, 0xFE, 0x8C, 0x7F
				DB 0x37, 0xE7, 0xC3, 0xFE, 0xEC, 0x7F, 0x31, 0xFF, 0xE3
				DB 0xFE, 0x7C, 0xF9, 0x70, 0xFF, 0xFB, 0xFF, 0x1E, 0xFF
				DB 0x78, 0xFF, 0xDF, 0x9F, 0xE, 0x7F, 0x3E, 0xFF, 0xC7
				DB 0xFE, 0x8C, 0x7F, 0x37, 0xE7, 0xC3, 0xFE, 0xEC, 0x7F
				DB 0x31, 0xFF, 0xE3, 0xFE, 0x7C, 0x79, 0x30, 0xFF, 0xFB
				DB 0xFF, 0x1E, 0x39, 0x10, 0xFF, 0xDF, 0x9F, 0xE, 0x11
				DB 0, 0xFF, 0xC7, 0xFE, 0x8C, 1, 0, 0xE7, 0xC3, 0xFE
				DB 0xEC, 0, 0, 0xE7, 0x43, 0xFE, 0x7C, 0, 0, 0x47, 3
				DB 0xFF, 0x1E, 0, 0, 7, 3, 0x9F, 0xE, 0, 0, 3, 1, 0x9E
				DB 0xC, 0, 0, 1, 0, 0x1E, 0xC, 0, 0, 0, 0, 0xE, 4, 0
				DB 0, 0, 0, 4, 0
spr_044:        DB 4, 29
				DB 0, 0, 0, 0, 0x38, 0, 0, 0, 0, 0, 0, 0, 0xFE, 0x38
				DB 0, 0, 0, 0, 3, 0, 0xFF, 0xDA, 0x80, 0, 0, 0, 0xF, 3
				DB 0xFF, 0x57, 0xE0, 0x80, 0, 0, 0x3F, 0xF, 0xFF, 0x8F
				DB 0xF8, 0xE0, 0, 0, 0xFF, 0x33, 0xFF, 0xDF, 0xFE, 0xF8
				DB 3, 0, 0xFF, 0xF3, 0xFF, 0xDF, 0xFF, 0xF6, 0xF, 3, 0xFF
				DB 0xF3, 0xFF, 0xDF, 0xFF, 0xFA, 0x3F, 0xD, 0xFF, 0xF3
				DB 0xFF, 0xDF, 0xFF, 0xFC, 0x7F, 0x39, 0xFF, 0xF3, 0xFF
				DB 0xDF, 0xFF, 0xFE, 0xFF, 0x59, 0xFF, 0xF3, 0xFF, 0xDF
				DB 0xFF, 0xFE, 0xFF, 0x59, 0xFF, 0xB3, 0xFF, 0xDF, 0xFF
				DB 0xFE, 0xFF, 0x39, 0xFF, 0x93, 0xFF, 7, 0xFF, 0xFE
				DB 0xFF, 0x79, 0xFF, 0x1C, 0xFF, 0xB9, 0xFF, 0xFE, 0xFF
				DB 0x79, 0xFF, 0x73, 0xFF, 0xBE, 0xFF, 0x7E, 0xFF, 0x79
				DB 0xFF, 0xCF, 0xFF, 0xDF, 0xFF, 0x9E, 0xFF, 0x7B, 0xFF
				DB 0x33, 0xFF, 0x9F, 0xFF, 0xE6, 0xFF, 0x7C, 0xFF, 0xF0
				DB 0xFF, 0x6F, 0xFF, 0xFA, 0xFF, 0x73, 0xFF, 0xF9, 0xFF
				DB 0xC7, 0xFF, 0xFE, 0xFF, 0x4D, 0xFF, 0xE0, 0xFF, 0x39
				DB 0xFE, 0xFC, 0xFF, 0x38, 0xFF, 0x9C, 0xFF, 0x7E, 0xFC
				DB 0x30, 0x7F, 0x3C, 0xFF, 0xF2, 0xFF, 0x3F, 0xF0, 0xC0
				DB 0x7F, 0x38, 0xFF, 0xF, 0xFF, 0xF, 0xC0, 0, 0x3F, 0x16
				DB 0xFF, 0x3F, 0xFF, 0xC4, 0, 0, 0x3F, 0x1C, 0xFF, 0x1F
				DB 0xFC, 0xF0, 0, 0, 0x1F, 0xB, 0xFF, 0x87, 0xF0, 0xC0
				DB 0, 0, 0xF, 7, 0xFF, 0xE3, 0xC0, 0, 0, 0, 7, 1, 0xFF
				DB 0xFC, 0, 0, 0, 0, 1, 0, 0xFC, 0, 0, 0, 0, 0
spr_045:        DB 4, 31
				DB 0, 0, 0xC, 0, 0, 0, 0, 0, 0, 0, 0x1E, 0xC, 0, 0, 0
				DB 0, 0, 0, 0x3E, 0x14, 0, 0, 0, 0, 0, 0, 0x3E, 0x14
				DB 0, 0, 0, 0, 0, 0, 0x3E, 0x14, 0, 0, 0, 0, 0x18, 0
				DB 0x3E, 0x14, 0, 0, 0, 0, 0x3C, 0x18, 0x3E, 0x14, 0
				DB 0, 0, 0, 0x7C, 0x28, 0x3E, 0x14, 0, 0, 0xC, 0, 0x7C
				DB 0x28, 0x3E, 0x14, 0, 0, 0x1E, 0xC, 0x7C, 0x28, 0x3E
				DB 0x14, 0, 0, 0x3E, 0x14, 0x7C, 0x28, 0x3E, 0x14, 0
				DB 0, 0x3E, 0x14, 0x7C, 0x28, 0x3E, 4, 0, 0, 0x3E, 0x14
				DB 0x7C, 0x28, 0x7E, 0x18, 0x18, 0, 0x3E, 0x14, 0x7C
				DB 0x28, 0xFF, 0x66, 0xBC, 0x18, 0x3E, 0x14, 0x7F, 0x29
				DB 0xFF, 0x99, 0xFC, 0x88, 0x3E, 0x14, 0x7F, 0x26, 0xFF
				DB 0x7E, 0xFC, 0x60, 0x3E, 0x14, 0x7F, 0x19, 0xFF, 0xFF
				DB 0xFE, 0x98, 0x3E, 0x14, 0xFF, 0x67, 0xFF, 0xFF, 0xFF
				DB 0xE6, 0xBE, 0x14, 0xFF, 0x9F, 0xFF, 0xFF, 0xFF, 0xF9
				DB 0xFE, 0x94, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xFE
				DB 0x64, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x98
				DB 0xFF, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE6, 0x7F
				DB 0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xF9, 0x1F, 7
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 7, 1, 0xFF, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFF, 1, 0, 0xFF, 0x7F, 0xFF, 0xFF
				DB 0xFF, 0xFC, 0, 0, 0x7F, 0x1F, 0xFF, 0xFF, 0xFC, 0xF0
				DB 0, 0, 0x1F, 7, 0xFF, 0xFF, 0xF0, 0xC0, 0, 0, 7, 1
				DB 0xFF, 0xFF, 0xC0, 0, 0, 0, 1, 0, 0xFF, 0x7C, 0, 0
				DB 0, 0, 0, 0, 0x7C, 0x10, 0, 0
spr_046:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xE, 0, 0, 0, 0xE, 0, 0x3F
				DB 0xE, 0xF8, 0x20, 0x3F, 0xE, 0xFF, 0x3F, 0xFC, 0xB8
				DB 0x7F, 0x3D, 0xFF, 0xDF, 0xFC, 0x88, 0xFF, 0x7B, 0xFF
				DB 0xDF, 0xF8, 0xD0, 0xFF, 0x63, 0xFF, 0xFF, 0xFC, 0xF8
				DB 0x63, 1, 0xFF, 0xFF, 0xF8, 0x80, 1, 0, 0xFF, 0xFC
				DB 0xF8, 0x70, 0, 0, 0xFF, 0x73, 0xFC, 0xF8, 1, 0, 0xFF
				DB 0xCF, 0xFE, 0xFC, 1, 0, 0xFF, 0xDF, 0xFE, 0x8C, 0
				DB 0, 0xFF, 0x3E, 0xFC, 0x78, 0, 0, 0xFF, 0x79, 0xF8
				DB 0x70, 1, 0, 0xFF, 0xF7, 0xFC, 0xB8, 3, 1, 0xFF, 0xE7
				DB 0xF8, 0xB0, 3, 1, 0xFF, 0xEB, 0xF8, 0xA0, 1, 0, 0xFF
				DB 0xEC, 0xF8, 0x50, 0, 0, 0xFF, 0x6F, 0xF0, 0xA0, 0
				DB 0, 0x6F, 7, 0xE0, 0, 0, 0, 7, 0, 0, 0
spr_047:        DB 3, 25
				DB 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0, 0, 0, 0xF, 7, 0x80
				DB 0, 0, 0, 0xF, 7, 0x80, 0, 0, 0, 0x1F, 0xE, 0x38, 0
				DB 4, 0, 0x1F, 0xE, 0xFF, 0x38, 0xE, 4, 0x3F, 0x18, 0xFF
				DB 0xFF, 0x9F, 0xE, 0x3F, 0x17, 0xFF, 0x7F, 0xFE, 0x1C
				DB 0x1F, 0xF, 0xFF, 0x7E, 0xFC, 0xE8, 0x1F, 0xF, 0xFF
				DB 0xFE, 0xF8, 0xE0, 0xF, 7, 0xFF, 0xFF, 0xE0, 0xC0, 7
				DB 3, 0xFF, 0xF1, 0xE0, 0xC0, 0xF, 5, 0xFF, 0xC0, 0xC0
				DB 0x80, 0x1F, 8, 0xFF, 0x46, 0xE0, 0x40, 0x1F, 8, 0xFF
				DB 6, 0xF0, 0x20, 0xF, 4, 0xFF, 0x15, 0xF8, 0x10, 7, 2
				DB 0xFF, 0x1B, 0xFC, 8, 0xF, 5, 0xFF, 0x80, 0xFC, 8, 0xF
				DB 6, 0xFF, 0x60, 0xF8, 0x30, 7, 2, 0xFF, 0x9F, 0xF0
				DB 0xC0, 7, 2, 0xFF, 0xE0, 0xC0, 0, 3, 1, 0xFF, 0x77
				DB 0x80, 0, 1, 0, 0xFF, 0xAE, 0, 0, 0, 0, 0xFE, 0x58
				DB 0, 0, 0, 0, 0x78, 0, 0, 0
spr_048:        DB 3, 25
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0xF, 0, 0xE, 0, 0x20, 0, 0x3F
				DB 0xF, 0xBF, 0xE, 0xF0, 0x20, 0x7F, 0x3E, 0xFF, 0xBF
				DB 0xF0, 0xA0, 0x7F, 0x35, 0xFF, 0xDF, 0xF8, 0xB0, 0x3F
				DB 3, 0xFF, 0xDF, 0xFC, 0xC8, 7, 3, 0xFF, 0xFF, 0xF8
				DB 0xF0, 3, 0, 0xFF, 0xFF, 0xF8, 0xF0, 1, 0, 0xFF, 0x3F
				DB 0xFC, 0xE0, 3, 1, 0xFF, 0xC7, 0xFE, 0x9C, 3, 1, 0xFF
				DB 0xB0, 0xFF, 0x7E, 1, 0, 0xFF, 0x71, 0xFF, 0xFE, 0
				DB 0, 0xFF, 0x67, 0xFE, 0xC4, 0, 0, 0x7F, 0x1E, 0xFC
				DB 0x38, 0, 0, 0xFF, 0x79, 0xFE, 0xBC, 1, 0, 0xFF, 0xF7
				DB 0xFE, 0xBC, 3, 1, 0xFF, 0xEB, 0xFC, 0xB8, 3, 1, 0xFF
				DB 0xDC, 0xFC, 0xD8, 1, 0, 0xFF, 0xDE, 0xF8, 0x50, 0
				DB 0, 0xFF, 0x1F, 0xF0, 0xA0, 0, 0, 0x1F, 7, 0xE0, 0xC0
				DB 0, 0, 7, 0, 0xC0, 0
spr_049:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0x1C, 0, 0, 0, 0xE, 0, 0x7E, 0x1C, 0x18
				DB 0, 0x7F, 0xE, 0xFE, 0x7C, 0x3D, 0x18, 0xFF, 0x7F, 0xFE
				DB 0xA8, 0x3F, 0x1D, 0xFF, 0xBF, 0xFE, 0x84, 0x7F, 0x3B
				DB 0xFF, 0xDF, 0xFC, 0xD8, 0x7F, 0x37, 0xFF, 0xFF, 0xFC
				DB 0xF8, 0xF7, 0x63, 0xFF, 0xFF, 0xF8, 0x80, 0xF3, 0x61
				DB 0xFF, 0xFC, 0xF8, 0x70, 0x61, 0, 0xFF, 0x73, 0xFC
				DB 0xF8, 1, 0, 0xFF, 0xCF, 0xFE, 0xFC, 1, 0, 0xFF, 0xDF
				DB 0xFE, 0x8C, 0, 0, 0xFF, 0x3E, 0xFC, 0x78, 0, 0, 0xFF
				DB 0x79, 0xF8, 0x70, 1, 0, 0xFF, 0xF7, 0xFC, 0xB8, 3
				DB 1, 0xFF, 0xE7, 0xF8, 0xB0, 3, 1, 0xFF, 0xEB, 0xF8
				DB 0xA0, 1, 0, 0xFF, 0xEC, 0xF8, 0x50, 0, 0, 0xFF, 0x6F
				DB 0xF0, 0xA0, 0, 0, 0x6F, 7, 0xE0, 0, 0, 0, 7, 0, 0
				DB 0
spr_050:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 3, 0, 0x80, 0, 0, 0, 0xF, 3, 0xCE, 0x80, 0, 0, 0x1F
				DB 0xF, 0xFF, 0x8E, 0x80, 0, 0x3F, 0x1C, 0xFF, 0x6F, 0xC0
				DB 0x80, 0x3F, 0x11, 0xFF, 0xEF, 0xE0, 0xC0, 0x13, 1
				DB 0xFF, 0xEF, 0xF0, 0xE0, 1, 0, 0xFF, 0xFF, 0xF0, 0xE0
				DB 1, 0, 0xFF, 0xFF, 0xF0, 0x80, 0, 0, 0xFF, 0x7C, 0xF8
				DB 0x70, 0, 0, 0xFF, 0x73, 0xFC, 0xF8, 1, 0, 0xFF, 0xCF
				DB 0xFE, 0xFC, 1, 0, 0xFF, 0xDF, 0xFE, 0x8C, 0, 0, 0xFF
				DB 0x3E, 0xFC, 0x78, 0, 0, 0xFF, 0x79, 0xF8, 0x70, 1
				DB 0, 0xFF, 0xF7, 0xFC, 0xB8, 3, 1, 0xFF, 0xE7, 0xF8
				DB 0xB0, 3, 1, 0xFF, 0xEB, 0xF8, 0xA0, 1, 0, 0xFF, 0xEC
				DB 0xF8, 0x50, 0, 0, 0xFF, 0x6F, 0xF0, 0xA0, 0, 0, 0x6F
				DB 7, 0xE0, 0, 0, 0, 7, 0, 0, 0
spr_051:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 7, 0, 0xE, 0, 0x60, 0, 0x1F, 7
				DB 0xDF, 0xE, 0xF0, 0x60, 0x3F, 0x1E, 0xFF, 0x5F, 0xF0
				DB 0xA0, 0x7F, 0x39, 0xFF, 0xDF, 0xF8, 0x90, 0x7F, 0x23
				DB 0xFF, 0xDF, 0xF0, 0xE0, 0x23, 1, 0xFF, 0xFF, 0xF8
				DB 0xF0, 1, 0, 0xFF, 0xFF, 0xF0, 0x80, 1, 0, 0xFF, 0xFC
				DB 0xF8, 0x70, 0, 0, 0xFF, 0x73, 0xFC, 0xF8, 1, 0, 0xFF
				DB 0xCF, 0xFE, 0xFC, 1, 0, 0xFF, 0xDF, 0xFE, 0x9C, 0
				DB 0, 0xFF, 0x3E, 0xFC, 0x78, 0, 0, 0xFF, 0x79, 0xF8
				DB 0x70, 1, 0, 0xFF, 0xF7, 0xFC, 0xB8, 3, 1, 0xFF, 0xE7
				DB 0xF8, 0xB0, 3, 1, 0xFF, 0xEB, 0xF8, 0xA0, 1, 0, 0xFF
				DB 0xEC, 0xF8, 0x50, 0, 0, 0xFF, 0x6F, 0xF0, 0xA0, 0
				DB 0, 0x6F, 7, 0xE0, 0, 0, 0, 7, 0, 0, 0
spr_052:        DB 3, 25
				DB 1, 0, 0xC0, 0, 0, 0, 3, 1, 0xE0, 0xC0, 0, 0, 7, 3
				DB 0xC0, 0x80, 0, 0, 0xF, 7, 0x80, 0, 0, 0, 0xF, 7, 0xB8
				DB 0, 0, 0, 0x1F, 0xF, 0xFF, 0x38, 8, 0, 0x1F, 0xC, 0xFF
				DB 0x7F, 0x9C, 8, 0xF, 3, 0xFF, 0xBF, 0xBE, 0x1C, 0x1F
				DB 0xF, 0xFF, 0xBE, 0xFC, 0xB8, 0x1F, 0xF, 0xFF, 0xFE
				DB 0xF8, 0xD0, 0xF, 7, 0xFF, 0xFF, 0xF0, 0xC0, 7, 3, 0xFF
				DB 0xF1, 0xE0, 0xC0, 0xF, 5, 0xFF, 0xC0, 0xC0, 0x80, 0x1F
				DB 8, 0xFF, 0x46, 0xE0, 0x40, 0x1F, 8, 0xFF, 6, 0xF0
				DB 0x20, 0xF, 4, 0xFF, 0x15, 0xF8, 0x10, 7, 2, 0xFF, 0x1B
				DB 0xFC, 8, 0xF, 5, 0xFF, 0x80, 0xFC, 8, 0xF, 6, 0xFF
				DB 0x60, 0xF8, 0x30, 7, 2, 0xFF, 0x9F, 0xF0, 0xC0, 7
				DB 2, 0xFF, 0xE0, 0xC0, 0, 3, 1, 0xFF, 0x77, 0x80, 0
				DB 1, 0, 0xFF, 0xAE, 0, 0, 0, 0, 0xFE, 0x58, 0, 0, 0
				DB 0, 0x78, 0, 0, 0
spr_053:        DB 3, 25
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xC, 0, 0, 0, 0
				DB 0, 0x1E, 0xC, 0, 0, 6, 0, 0x3E, 0x1C, 0x38, 0, 0xF
				DB 6, 0x3E, 0x18, 0xFF, 0x38, 0x3F, 0xE, 0x7F, 0x38, 0xFF
				DB 0xFF, 0xFE, 0x3C, 0x7F, 0x37, 0xFF, 0xFF, 0xFC, 0x58
				DB 0x7F, 0x2F, 0xFF, 0x7E, 0xF8, 0xE0, 0x3F, 0x1F, 0xFF
				DB 0xFE, 0xF8, 0xF0, 0x3F, 0x1F, 0xFF, 0xFF, 0xF0, 0xE0
				DB 0x1F, 7, 0xFF, 0xF1, 0xE0, 0xC0, 0xF, 5, 0xFF, 0xC0
				DB 0xC0, 0x80, 0x1F, 8, 0xFF, 0x46, 0xE0, 0x40, 0x1F
				DB 8, 0xFF, 6, 0xF0, 0x20, 0xF, 4, 0xFF, 0x15, 0xF8, 0x10
				DB 7, 2, 0xFF, 0x1B, 0xFC, 8, 0xF, 5, 0xFF, 0x80, 0xFC
				DB 8, 0xF, 6, 0xFF, 0x60, 0xF8, 0x30, 7, 2, 0xFF, 0x9F
				DB 0xF0, 0xC0, 7, 2, 0xFF, 0xE0, 0xC0, 0, 3, 1, 0xFF
				DB 0x77, 0x80, 0, 1, 0, 0xFF, 0xAE, 0, 0, 0, 0, 0xFE
				DB 0x58, 0, 0, 0, 0, 0x78, 0, 0, 0
spr_054:        DB 3, 25
				DB 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0xF, 6, 0, 0, 0
				DB 0, 0x1F, 0xE, 0, 0, 6, 0, 0x3E, 0x1C, 0x38, 0, 0x1F
				DB 6, 0x3E, 0x1C, 0xFF, 0x38, 0x3F, 0x1E, 0x3F, 0x18
				DB 0xFF, 0xFF, 0xFF, 0x3C, 0x7F, 0x36, 0xFF, 0xFF, 0xFE
				DB 0x58, 0x3F, 0xF, 0xFF, 0x7E, 0xF8, 0xE0, 0x3F, 0x1F
				DB 0xFF, 0xFE, 0xF8, 0xF0, 0x1F, 0xF, 0xFF, 0xFF, 0xF0
				DB 0xE0, 0xF, 7, 0xFF, 0xF1, 0xE0, 0xC0, 0xF, 5, 0xFF
				DB 0xC0, 0xC0, 0x80, 0x1F, 8, 0xFF, 0x46, 0xE0, 0x40
				DB 0x1F, 8, 0xFF, 6, 0xF0, 0x20, 0xF, 4, 0xFF, 0x15, 0xF8
				DB 0x10, 7, 2, 0xFF, 0x1B, 0xFC, 8, 0xF, 5, 0xFF, 0x80
				DB 0xFC, 8, 0xF, 6, 0xFF, 0x60, 0xF8, 0x30, 7, 2, 0xFF
				DB 0x9F, 0xF0, 0xC0, 7, 2, 0xFF, 0xE0, 0xC0, 0, 3, 1
				DB 0xFF, 0x77, 0x80, 0, 1, 0, 0xFF, 0xAE, 0, 0, 0, 0
				DB 0xFE, 0x58, 0, 0, 0, 0, 0x78, 0, 0, 0
spr_055:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0xE0, 0, 0, 0, 3, 0, 0xF0, 0xE0, 6
				DB 0, 0xF, 3, 0xF0, 0xE0, 0x3F, 6, 0x1F, 0xF, 0xF0, 0xE0
				DB 0x7F, 0x3F, 0x9F, 0xE, 0xF0, 0, 0xFF, 0x7F, 0x9F, 0xD
				DB 0xE0, 0xC0, 0xFF, 0x78, 0x3F, 1, 0xC0, 0x80, 0x7F
				DB 0x36, 0x7B, 0x30, 0x80, 0, 0x3F, 6, 0xFF, 0x7B, 0xE0
				DB 0x80, 0xF, 6, 0xFF, 0xFD, 0xF0, 0xF0, 0xF, 5, 0xFF
				DB 0xFE, 0xF0, 0xE0, 7, 3, 0xFF, 0xFE, 0xE0, 0xC0, 3
				DB 0, 0xFF, 0xFF, 0xE0, 0xC0
spr_056:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0xC0, 0, 0, 0, 7, 0, 0xE3, 0xC0, 0x80, 0
				DB 0xF, 7, 0xFF, 0xE3, 0xC0, 0x80, 0x1F, 0xF, 0xFF, 0xEF
				DB 0xC0, 0x80, 0x1F, 0xF, 0xFF, 0x1F, 0xC0, 0x80, 0xF
				DB 6, 0xFF, 0xD7, 0x80, 0, 7, 0, 0xFF, 0xC9, 0x80, 0
				DB 1, 0, 0xFF, 0xDC, 0x80, 0, 1, 0, 0xFF, 0xBD, 0xC0
				DB 0x80, 1, 0, 0xFF, 0x7E, 0xE0, 0xC0, 3, 1, 0xFF, 0xFE
				DB 0xE0, 0xC0, 1, 0, 0xFF, 0xFE, 0xE0, 0xC0, 0, 0, 0xFF
				DB 0x7F, 0xE0, 0xC0
spr_057:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x18, 0
				DB 0, 0, 0, 0, 0xFC, 0x18, 0, 0, 1, 0, 0xFE, 0xFC, 0
				DB 0, 3, 1, 0xFE, 0xFC, 0, 0, 3, 1, 0xFF, 0xE2, 0, 0
				DB 1, 0, 0xFF, 0xDA, 0, 0, 1, 0, 0xFF, 0x36, 0, 0, 3
				DB 1, 0xFE, 0x60, 0, 0, 3, 1, 0xFF, 0x4E, 0x80, 0, 1
				DB 0, 0xFF, 0x3F, 0xC0, 0, 1, 0, 0xFF, 0x7F, 0xE0, 0x40
				DB 1, 0, 0xFF, 0xFF, 0xE0, 0x40, 0, 0, 0xFF, 0x7F, 0xE0
				DB 0x40, 0, 0, 0xFF, 0x7F, 0xE0, 0xC0
spr_058:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0x1F, 6
				DB 0, 0, 0, 0, 0x7F, 0x1F, 0x80, 0, 0, 0, 0xFF, 0x7B
				DB 0x80, 0, 0, 0, 0xFF, 0x70, 0, 0, 0, 0, 0x7F, 6, 0
				DB 0, 0, 0, 0xFE, 0xC, 0, 0, 3, 0, 0xFC, 0xD8, 0, 0, 7
				DB 3, 0xFF, 0xD0, 0, 0, 7, 3, 0xFF, 0x87, 0x80, 0, 3
				DB 0, 0xFF, 0x5F, 0xC0, 0, 1, 0, 0xFF, 0xBF, 0xE0, 0x40
				DB 1, 0, 0xFF, 0xFF, 0xE0, 0x40, 3, 1, 0xFF, 0x7F, 0xE0
				DB 0x40, 3, 1, 0xFF, 0x7F, 0xE0, 0x80
spr_059:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x38
				DB 0, 0, 0, 0, 0, 0xFC, 0x38, 7, 0, 3, 0, 0xFC, 0xF8
				DB 0x1F, 7, 0x87, 3, 0xFC, 0xF8, 0x3F, 0x1F, 0x8F, 7
				DB 0xF8, 0xD0, 0x7F, 0x3E, 7, 3, 0xD0, 0, 0xFF, 0x70
				DB 3, 1, 0xC0, 0x80, 0xFF, 0x6F, 0xFE, 0, 0xE0, 0xC0
				DB 0x7F, 0x1C, 0xFF, 0x6E, 0xF0, 0x20, 0x1F, 3, 0xFF
				DB 0xEF, 0xE0, 0xC0, 0x1F, 0xF, 0xFF, 0xF7, 0xE0, 0xC0
				DB 0xF, 7, 0xFF, 0xF7, 0xC0, 0x80, 0xF, 7, 0xFF, 0xF7
				DB 0xC0, 0x80, 7, 3, 0xFF, 0xFF, 0x80, 0
spr_060:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0xE0, 0, 0xE0, 0, 3, 0, 0xF3, 0xE0, 0xF0
				DB 0xE0, 7, 3, 0xFF, 0xE3, 0xF0, 0xE0, 0xF, 7, 0xFF, 0xCF
				DB 0xF0, 0xE0, 0x1F, 0xF, 0xDF, 0xF, 0xE0, 0, 0x1F, 0xC
				DB 0x8F, 0, 0, 0, 0xF, 3, 0xFF, 0x86, 0, 0, 3, 1, 0xFF
				DB 0x31, 0x80, 0, 7, 0, 0xFF, 0xF7, 0xC0, 0x80, 0xF, 7
				DB 0xFF, 0xF7, 0xC0, 0x80, 7, 3, 0xFF, 0xF7, 0x80, 0
				DB 7, 3, 0xFF, 0xF7, 0x80, 0, 3, 1, 0xFF, 0xFF, 0x80
				DB 0
spr_061:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x30, 0
				DB 0, 0, 0, 0, 0xF8, 0x30, 0, 0, 3, 0, 0xFF, 0xF8, 0x80
				DB 0, 7, 3, 0xFF, 0x8B, 0xC0, 0x80, 7, 3, 0xFF, 0xC7
				DB 0xC0, 0x80, 7, 2, 0xFF, 0x3D, 0xC0, 0x80, 3, 1, 0xFF
				DB 0xB8, 0x80, 0, 3, 1, 0xFE, 0x84, 0, 0, 1, 0, 0xFE
				DB 0x30, 0, 0, 3, 1, 0xFF, 0xF6, 0, 0, 7, 3, 0xFF, 0xF6
				DB 0, 0, 7, 3, 0xFF, 0xF7, 0x80, 0, 7, 3, 0xFF, 0xF7
				DB 0x80, 0, 3, 1, 0xFF, 0xFF, 0x80, 0
spr_062:        DB 3, 16
				DB 0, 0, 6, 0, 0, 0, 0, 0, 0x1F, 6, 0, 0, 0, 0, 0x7F
				DB 0x1F, 0x80, 0, 0, 0, 0xFF, 0x7F, 0x80, 0, 1, 0, 0xFF
				DB 0xFE, 0, 0, 1, 0, 0xFE, 0xE0, 0, 0, 0, 0, 0xF8, 0x50
				DB 0, 0, 3, 0, 0xFC, 0xB8, 0, 0, 7, 3, 0xFC, 0xD8, 0
				DB 0, 7, 3, 0xFE, 0xC, 0, 0, 7, 2, 0xFC, 0xF0, 0, 0, 3
				DB 1, 0xFE, 0xFC, 0, 0, 3, 1, 0xFF, 0xFA, 0, 0, 7, 3
				DB 0xFF, 0xFA, 0, 0, 7, 3, 0xFF, 0xF7, 0x80, 0, 7, 3
				DB 0xFF, 0xFF, 0x80, 0
spr_063:        DB 3, 24
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xE, 0, 0x20, 0, 0xE, 0
				DB 0xFF, 0xE, 0xF8, 0x20, 0x3F, 0xE, 0xFF, 0x3F, 0xFC
				DB 0xB8, 0x7F, 0x3D, 0xFF, 0xDF, 0xFC, 0x88, 0xFF, 0x7B
				DB 0xFF, 0xDF, 0xF8, 0xD0, 0xFF, 0x63, 0xFF, 0xC3, 0xFC
				DB 0xF8, 0x63, 1, 0xFF, 0x80, 0xF8, 0x30, 1, 0, 0xFF
				DB 0x7F, 0xF0, 0xA0, 1, 0, 0xFF, 0xC7, 0xE0, 0xC0, 1
				DB 0, 0xFF, 0xB1, 0xF0, 0xE0, 1, 0, 0xFF, 0x76, 0xF8
				DB 0xF0, 1, 0, 0xFF, 0xEF, 0xFC, 0x78, 1, 0, 0xFF, 0xDE
				DB 0xFC, 0xB8, 1, 0, 0xFF, 0xDD, 0xFE, 0xBC, 1, 0, 0xFF
				DB 0xFB, 0xFE, 0xDC, 0, 0, 0xFF, 0x57, 0xFE, 0xDC, 0
				DB 0, 0xFF, 0x4E, 0xFE, 0xDC, 0, 0, 0x7F, 0x29, 0xFC
				DB 0x38, 0, 0, 0x3F, 0x1E, 0xF8, 0xF0, 0, 0, 0x1F, 0
				DB 0xF0, 0
spr_064:        DB 3, 25
				DB 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0
				DB 0, 0, 0xF, 7, 0, 0, 0, 0, 0x1F, 0xE, 0x38, 0, 4, 0
				DB 0x1F, 0xE, 0xFF, 0x38, 0xE, 4, 0x3F, 0x19, 0xFF, 0xFF
				DB 0x9F, 0xE, 0x3F, 0x17, 0xFF, 0x7F, 0xFE, 0x1C, 0x1F
				DB 0xF, 0xFF, 0x7E, 0xFC, 0xE8, 0x1F, 0xF, 0xFF, 0xFE
				DB 0xF8, 0xE0, 0xF, 7, 0xFF, 0xFF, 0xF0, 0xC0, 7, 3, 0xFF
				DB 0xF1, 0xF8, 0xD0, 0xF, 5, 0xFF, 0xC0, 0xF8, 0x90, 0x1F
				DB 8, 0xFF, 0, 0xF8, 0x10, 0x3F, 0x10, 0xFF, 0x80, 0xF0
				DB 0x20, 0x7F, 0x22, 0xFF, 0xA0, 0xF8, 0x50, 0x7F, 0x23
				DB 0xFF, 0x60, 0xF8, 0xB0, 0x7F, 0x20, 0xFF, 3, 0xF8
				DB 0x70, 0x3F, 0x10, 0xFF, 0x1C, 0xF8, 0xB0, 0x1F, 0xF
				DB 0xFF, 0xE3, 0xF0, 0xA0, 0xF, 2, 0xFF, 0x1D, 0xE0, 0x40
				DB 3, 1, 0xFF, 0xCE, 0xC0, 0x80, 1, 0, 0xFF, 0xF3, 0x80
				DB 0, 0, 0, 0xFF, 0x3C, 0, 0, 0, 0, 0x3C, 0, 0, 0
spr_065:        DB 3, 25
				DB 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0
				DB 0, 0, 0xF, 7, 0x80, 0, 0, 0, 0x1F, 0xE, 0x38, 0, 0
				DB 0, 0x3F, 0x1E, 0xFF, 0x38, 0x18, 0, 0x3F, 0x11, 0xFF
				DB 0x7F, 0xFC, 0x18, 0x3F, 0xF, 0xFF, 0x7F, 0xFE, 0x7C
				DB 0x3F, 0x1F, 0xFF, 0xBE, 0xFC, 0xB8, 0x1F, 0xF, 0xFF
				DB 0xFE, 0xF8, 0xC0, 0xF, 3, 0xFF, 0xFF, 0xE0, 0xC0, 0x1F
				DB 9, 0xFF, 0xF1, 0xC0, 0x80, 0x1F, 8, 0xFF, 0xF0, 0xC0
				DB 0, 0xF, 4, 0xFF, 0x60, 0xF0, 0, 7, 2, 0xFF, 0, 0xF8
				DB 0x70, 0xF, 5, 0xFF, 0, 0xF8, 0xB0, 0xF, 6, 0xFF, 0xC0
				DB 0xFC, 0xC8, 0xF, 7, 0xFF, 0x38, 0xFC, 8, 0xF, 6, 0xFF
				DB 0xC7, 0xFC, 0x88, 7, 2, 0xFF, 0xE8, 0xF8, 0x70, 7
				DB 2, 0xFF, 0xDD, 0xF0, 0x80, 3, 1, 0xFF, 0x53, 0x80
				DB 0, 1, 0, 0xFF, 0x8E, 0, 0, 0, 0, 0xFE, 0x78, 0, 0
				DB 0, 0, 0x78, 0, 0, 0
spr_066:        DB 2, 48
				DB 0xFC, 0, 0, 0, 0xFE, 0x7C, 0, 0, 0xFF, 0x7E, 0x70
				DB 0, 0xFF, 0x3D, 0xF8, 0x70, 0xFF, 0x3C, 0xFC, 0xB0
				DB 0xFF, 0x3C, 0xFE, 0x3C, 0xFF, 0x3D, 0xFF, 0x1A, 0xFF
				DB 0x1D, 0xFF, 0x1B, 0xFF, 0x1D, 0xFF, 0x18, 0xFF, 0x1D
				DB 0xFF, 0x38, 0xFF, 0x1D, 0xFF, 0x3C, 0xFF, 0x19, 0xFF
				DB 0xB0, 0xFF, 0x39, 0xFF, 0xB0, 0xFF, 0x31, 0xFF, 0xA0
				DB 0xFF, 0x71, 0xFF, 0xF0, 0xFF, 0x70, 0xFF, 0xF0, 0xFF
				DB 0x70, 0xFF, 0xF0, 0xFF, 0x78, 0xFF, 0xF2, 0xFF, 0x6C
				DB 0xFF, 0x71, 0xFF, 0x74, 0xFF, 0x59, 0xFF, 0x72, 0xFF
				DB 0x75, 0xFF, 0x39, 0xFF, 0x71, 0xFF, 0x39, 0xFF, 0xA2
				DB 0xFF, 0x39, 0xFF, 0xC2, 0xFF, 0x38, 0xFF, 0x34, 0xFF
				DB 0x3C, 0xFF, 0xE4, 0xFF, 0x3C, 0xFF, 0xE6, 0xFF, 0x3C
				DB 0xFF, 0xE6, 0xFF, 0x1C, 0xFF, 0x66, 0xFF, 0x1C, 0xFF
				DB 0x72, 0xFF, 0x1C, 0xFF, 0x72, 0xFF, 0xE, 0xFF, 0x32
				DB 0xFF, 0xE, 0xFF, 0x32, 0xFF, 0xE, 0xFF, 0x3A, 0xFF
				DB 0xE, 0xFF, 0x1A, 0xFF, 0xE, 0xFF, 0x99, 0xFF, 0xC
				DB 0xFF, 0x59, 0xFF, 0xC, 0xFF, 0x58, 0xFF, 0x18, 0xFF
				DB 0x48, 0xFF, 0x18, 0xFF, 0x6C, 0xFF, 0x10, 0xFF, 0xC4
				DB 0xFF, 0x11, 0xFF, 0x84, 0xFF, 0x11, 0xFF, 0x84, 0xFF
				DB 0x23, 0xFF, 4, 0xFF, 0x23, 0xFF, 4, 0xFF, 2, 0xFF
				DB 2, 0xFF, 2, 0xFF, 2, 0xFF, 0, 0xFF, 2
spr_067:        DB 2, 48
				DB 0xF8, 0, 0, 0, 0xFE, 0x78, 0, 0, 0xFF, 0x7E, 0, 0
				DB 0xFF, 0x7D, 0x80, 0, 0xFF, 0x7C, 0xFC, 0x80, 0xFF
				DB 0x6C, 0xFE, 0xFC, 0xFF, 0x6C, 0xFF, 0x7C, 0xFF, 0x6C
				DB 0xFF, 0x7D, 0xFF, 0x5C, 0xFF, 0x3E, 0xFF, 0x5C, 0xFF
				DB 0x3E, 0xFF, 0x5C, 0xFF, 0x1F, 0xFF, 0x2C, 0xFF, 0x1F
				DB 0xFF, 0x1E, 0xFF, 0xF, 0xFF, 0x97, 0xFF, 0xF, 0xFF
				DB 0x57, 0xFF, 0xF, 0xFF, 0x57, 0xFF, 0xF, 0xFF, 0x4B
				DB 0xFF, 0x1E, 0xFF, 0x4B, 0xFF, 0x1E, 0xFF, 0xE7, 0xFF
				DB 0x9E, 0xFF, 0xE7, 0xFF, 0x9C, 0xFF, 0xE7, 0xFF, 0x9C
				DB 0xFF, 0xE7, 0xFF, 0x1C, 0xFF, 0x6F, 0xFF, 0x1C, 0xFF
				DB 0x4F, 0xFF, 0x1E, 0xFF, 0x4B, 0xFF, 0x3F, 0xFF, 0x13
				DB 0xFF, 0x5E, 0xFF, 0x26, 0xFF, 0x5E, 0xFF, 0x26, 0xFF
				DB 0x9C, 0xFF, 0x4C, 0xFF, 0x1C, 0xFF, 0x5C, 0xFF, 0x3C
				DB 0xFF, 0x58, 0xFF, 0x38, 0xFF, 0x28, 0xFF, 0x3E, 0xFF
				DB 0x28, 0xFF, 0x3F, 0xFF, 0x18, 0xFF, 0x1E, 0xFF, 0x18
				DB 0xFF, 0x1E, 0xFF, 0x14, 0xFF, 0x1C, 0xFF, 0x14, 0xFF
				DB 0x1C, 0xFF, 0x16, 0xFF, 0xC, 0xFF, 0x1E, 0xFF, 0xC
				DB 0xFF, 0x1C, 0xFF, 0xC, 0xFF, 0x14, 0xFF, 0x16, 0xFF
				DB 0x14, 0xFF, 0x16, 0xFF, 0x18, 0xFF, 0x24, 0xFF, 0x18
				DB 0xFF, 0x2C, 0xFF, 0x18, 0xFF, 0x48, 0xFF, 0x10, 0xFF
				DB 0x10, 0xFF, 0x10, 0xFF, 0, 0xFF, 0, 0xFF, 0
spr_068:        DB 2, 48
				DB 0xF8, 0xC0, 0, 0, 0xFF, 0x78, 0xF0, 0, 0xFF, 0x3F
				DB 0xF8, 0xF0, 0xFF, 0x1F, 0xFC, 0xE8, 0xFF, 0x1E, 0xFC
				DB 0xE8, 0xFF, 0xE, 0xFE, 0xC4, 0xFF, 0xE, 0xFF, 0xC2
				DB 0xFF, 0x4E, 0xFF, 0xC1, 0xFF, 0x4E, 0xFF, 0xC0, 0xFF
				DB 0x4E, 0xFF, 0x40, 0xFF, 0x47, 0xFF, 0x40, 0xFF, 0x47
				DB 0xFF, 0xE0, 0xFF, 0x43, 0xFF, 0xE4, 0xFF, 0x69, 0xFF
				DB 0xE4, 0xFF, 0x68, 0xFF, 0xE4, 0xFF, 0x65, 0xFF, 0xEC
				DB 0xFF, 0x25, 0xFF, 0xEC, 0xFF, 0x25, 0xFF, 0xEC, 0xFF
				DB 0x39, 0xFF, 0xE4, 0xFF, 0x39, 0xFF, 0xF4, 0xFF, 0x31
				DB 0xFF, 0xF2, 0xFF, 0x31, 0xFF, 0xF2, 0xFF, 0x31, 0xFF
				DB 0xF0, 0xFF, 0x21, 0xFF, 0xE0, 0xFF, 0x21, 0xFF, 0xE0
				DB 0xFF, 0x41, 0xFF, 0xE1, 0xFF, 0x41, 0xFF, 0xF1, 0xFF
				DB 0x41, 0xFF, 0xF2, 0xFF, 1, 0xFF, 0xF2, 0xFF, 3, 0xFF
				DB 0xE2, 0xFF, 7, 0xFF, 0xC2, 0xFF, 7, 0xFF, 0x83, 0xFF
				DB 0xF, 0xFF, 3, 0xFF, 0xE, 0xFF, 3, 0xFF, 0x1C, 0xFF
				DB 7, 0xFF, 0x18, 0xFF, 6, 0xFF, 0x18, 0xFF, 6, 0xFF
				DB 0x18, 0xFF, 0xC, 0xFF, 0x18, 0xFF, 0x1C, 0xFF, 0x18
				DB 0xFF, 0x18, 0xFF, 8, 0xFF, 0x30, 0xFF, 8, 0xFF, 0x20
				DB 0xFF, 8, 0xFF, 0x40, 0xFF, 0x18, 0xFF, 0, 0xFF, 1
				DB 0xFF, 0, 0xFF, 1, 0xFF, 0, 0xFF, 0, 0xFF, 0, 0xFF
				DB 0, 0xFF, 0
spr_069:        DB 2, 48
				DB 0x40, 0, 0, 0, 0xF0, 0x40, 0, 0, 0xFC, 0x70, 0, 0
				DB 0xFE, 0x7C, 0, 0, 0xFF, 0x7E, 0xC0, 0, 0xFF, 0x7E
				DB 0xF0, 0xC0, 0xFF, 0x7E, 0xFC, 0xF0, 0xFF, 0x7E, 0xFF
				DB 0xFC, 0x7F, 0x36, 0xFF, 0xFE, 0x37, 0, 0xFF, 0xFE
				DB 0xF, 6, 0xFF, 0x3E, 0xF, 7, 0xFF, 0x8E, 0xF, 7, 0xFF
				DB 0xE2, 7, 3, 0xFF, 0xF8, 7, 3, 0xFF, 0xFE, 7, 3, 0xFF
				DB 0xFF, 7, 3, 0xFF, 0xFF, 0xF, 7, 0xFF, 0xFF, 0xF, 7
				DB 0xFF, 0xFF, 0xF, 7, 0xFF, 0xFF, 0x67, 1, 0xFF, 0xFF
				DB 0xF9, 0x60, 0xFF, 0x7F, 0xFE, 0x78, 0xFF, 0x1F, 0xFF
				DB 0x7E, 0xFF, 0x67, 0xFF, 0x7E, 0xFF, 0xF8, 0x7F, 0x1E
				DB 0xFF, 0xFE, 0x1F, 6, 0xFF, 0xFE, 7, 0, 0xFF, 0xFE
				DB 1, 0, 0xFF, 0xFE, 0, 0, 0xFF, 0x3E, 6, 0, 0x7F, 0xE
				DB 0xF, 6, 0x7F, 0x30, 0x1F, 0xE, 0xFF, 0x3C, 0x1F, 0xF
				DB 0xFF, 0x9E, 0xF, 7, 0xFF, 0xE6, 7, 1, 0xFF, 0xF8, 7
				DB 2, 0xFF, 0x7F, 7, 3, 0xFF, 0x9F, 7, 3, 0xFF, 0xE7
				DB 3, 1, 0xFF, 0xF9, 3, 0, 0xFF, 0xFE, 7, 3, 0xFF, 0x3F
				DB 7, 3, 0xFF, 0xCF, 7, 3, 0xFF, 0xF7, 3, 0, 0xFF, 0xF7
				DB 0, 0, 0xFF, 0x33, 0, 0, 0x3B, 0, 0, 0, 0, 0
spr_070:        DB 2, 48
				DB 0, 0, 2, 0, 0, 0, 0xF, 2, 0, 0, 0x1F, 0xE, 0, 0, 0xFF
				DB 0xE, 3, 0, 0xFF, 0xEE, 0xF, 3, 0xFF, 0xEE, 3, 0xF
				DB 0xFF, 0xEE, 0xFF, 0x3F, 0xFE, 0xE8, 0xFF, 0xFF, 0xF8
				DB 0xE0, 0xFF, 0xFF, 0xE0, 0xC0, 0xFF, 0xFF, 0xC0, 0
				DB 0xFF, 0xFC, 0xE0, 0xC0, 0xFF, 0xF3, 0xEC, 0xC0, 0xFF
				DB 0xCF, 0xFE, 0x8C, 0xFF, 0x3F, 0xFE, 0x3C, 0xFF, 0x7C
				DB 0xFE, 0xFC, 0xFF, 0x73, 0xFE, 0xFC, 0xFF, 0x4F, 0xFC
				DB 0xF0, 0xFF, 0x3F, 0xF0, 0xC0, 0xFF, 0x7F, 0xC0, 0
				DB 0xFF, 0x7C, 0xC0, 0x80, 0xFF, 0x73, 0xC0, 0x80, 0xFF
				DB 0x4F, 0xC0, 0x80, 0xFF, 0x3F, 0x80, 0, 0xFF, 0x7C
				DB 0x80, 0, 0xFF, 0xFB, 0x8F, 2, 0xFF, 0xE7, 0xFF, 0x8E
				DB 0xFF, 0x9F, 0xFF, 0xBE, 0xFF, 0x7F, 0xFE, 0xBC, 0xFF
				DB 0xFF, 0xFC, 0xB0, 0xFF, 0xFF, 0xF0, 0x80, 0xFF, 0xFF
				DB 0xF8, 0x30, 0xFF, 0xFC, 0xFC, 0x78, 0xFF, 0xF1, 0xFC
				DB 0xF8, 0xFF, 0x49, 0xFC, 0xF8, 0xFF, 0x3D, 0xF8, 0xF0
				DB 0xFF, 0x7D, 0xF0, 0xE0, 0xFF, 0x7D, 0xF0, 0x80, 0xFF
				DB 0x7C, 0xF0, 0x20, 0xFF, 0x78, 0xF8, 0xF0, 0xFF, 0x73
				DB 0xF8, 0xF0, 0xFF, 0x4F, 0xF8, 0xF0, 0xFF, 0x3F, 0xF0
				DB 0xE0, 0xFF, 0x7F, 0xE0, 0x80, 0xFF, 0x7E, 0x80, 0
				DB 0xFE, 0x78, 0, 0, 0xF8, 0x60, 0, 0, 0x60, 0, 0, 0
spr_071:        DB 3, 52
				DB 1, 0, 0xF0, 0xC0, 0, 0, 7, 1, 0xF8, 0x70, 0, 0, 0x1F
				DB 7, 0xFC, 0x78, 0, 0, 0x7F, 0x1F, 0xFC, 0x78, 0, 0
				DB 0xFF, 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7F, 0xFC, 0x78
				DB 0, 0, 0xFF, 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7E, 0xFC
				DB 0x38, 0, 0, 0xFF, 0x79, 0xFC, 0x48, 0, 0, 0xFF, 0x67
				DB 0xFC, 0x70, 0, 0, 0xFF, 0x1F, 0xFC, 0x78, 0, 0, 0xFF
				DB 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7F, 0xFC, 0x78, 0
				DB 0, 0xFF, 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7E, 0xFC
				DB 0x18, 0, 0, 0xFF, 0x79, 0xFC, 0x60, 0, 0, 0xFF, 0x67
				DB 0xFC, 0x78, 0, 0, 0xFF, 0x1F, 0xFC, 0x78, 0, 0, 0xFF
				DB 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7F, 0xFC, 0x78, 0
				DB 0, 0xFF, 0x7F, 0xFC, 0x78, 0, 0, 0xFF, 0x7F, 0xFC
				DB 0x18, 0, 0, 0xFF, 0x7C, 0xFC, 0xA0, 0, 0, 0xFF, 0x73
				DB 0xFE, 0xBC, 0, 0, 0x7F, 0xF, 0xFE, 0xBC, 0, 0, 0x7F
				DB 0x3F, 0xFE, 0xBC, 0, 0, 0x7F, 0x3F, 0xFF, 0xBE, 0
				DB 0, 0x7F, 0x3F, 0xFF, 0xDE, 0, 0, 0x7F, 0x3F, 0xFF
				DB 0x80, 0, 0, 0x7F, 0x3E, 0xFF, 0x5F, 0x80, 0, 0x3F
				DB 0x19, 0xFF, 0xEF, 0x80, 0, 0x3F, 7, 0xFF, 0xEF, 0x80
				DB 0, 0x3F, 0x1F, 0xFF, 0xEF, 0x80, 0, 0x1F, 0xF, 0xFF
				DB 0xF7, 0xC0, 0x80, 0x1F, 0xF, 0xFF, 0xF7, 0xE0, 0, 0x1F
				DB 0xF, 0xFF, 0xF8, 0xF0, 0xE0, 0xF, 7, 0xFF, 0xF3, 0xF0
				DB 0xE0, 0xF, 7, 0xFF, 0xCD, 0xF8, 0xF0, 7, 3, 0xFF, 0x3E
				DB 0xFC, 0xF8, 7, 0, 0xFF, 0xFE, 0xFE, 0xF4, 3, 1, 0xFF
				DB 0xFF, 0xFE, 0x6C, 1, 0, 0xFF, 0xFF, 0xFF, 0x9E, 1
				DB 0, 0xFF, 0xFE, 0xFF, 0x5F, 0, 0, 0xFF, 0x79, 0xFF
				DB 0xEF, 0, 0, 0x7F, 0x27, 0xFF, 0xF7, 0, 0, 0x3F, 0x1F
				DB 0xFF, 0xFB, 0, 0, 0x1F, 0xF, 0xFF, 0xFD, 0, 0, 0xF
				DB 7, 0xFF, 0xF8, 0, 0, 7, 3, 0xFF, 0xE3, 0, 0, 3, 1
				DB 0xFF, 0x8C, 0, 0, 1, 0, 0xFC, 0x30, 0, 0, 0, 0, 0x30
				DB 0
spr_072:        DB 2, 35
				DB 0, 0, 0x3C, 0, 0, 0, 0xFE, 0x2C, 3, 0, 0xFF, 0xEE
				DB 0xF, 3, 0xFF, 0xEE, 0x1F, 0xF, 0xFF, 0xEE, 0x1F, 0xF
				DB 0xFF, 0xEE, 0x1F, 0xF, 0xFF, 0xEE, 0x1F, 0xF, 0xFF
				DB 0xEE, 0x1F, 0xF, 0xFF, 0xC2, 0x1F, 0xF, 0xFF, 0x2D
				DB 0x1F, 0xC, 0xFF, 0xEE, 0x1F, 3, 0xFF, 0xEE, 0x1F, 0xF
				DB 0xFF, 0xEE, 0x1F, 0xF, 0xFF, 0xC2, 0x1F, 0xF, 0xFF
				DB 0x2C, 0x1F, 0xC, 0xFF, 0xEE, 0x1F, 3, 0xFF, 0xEE, 0x1F
				DB 0xF, 0xFF, 0xE6, 0x1F, 0xF, 0xFF, 0x18, 0x1F, 0xC
				DB 0xFF, 0xDE, 0x1F, 3, 0xFE, 0xDC, 0x3F, 0x1F, 0xFE
				DB 0xBC, 0x3F, 0x1F, 0xFE, 0xC, 0x3F, 0x1C, 0xFC, 0x70
				DB 0x7F, 0x33, 0xFC, 0x78, 0x7F, 0xE, 0xF8, 0xF0, 0xFF
				DB 0x7C, 0xF8, 0xF0, 0xFF, 0x73, 0xF0, 0x60, 0xFF, 0xCF
				DB 0xE0, 0x80, 0xFF, 0x37, 0xC0, 0x80, 0xFF, 0x77, 0x80
				DB 0, 0xFF, 0x7A, 0, 0, 0xFE, 0x78, 0, 0, 0xF8, 0x60
				DB 0, 0, 0xE0, 0, 0, 0
spr_073:        DB 2, 48
				DB 0xC0, 0, 0, 0, 0xF0, 0xC0, 0, 0, 0xFC, 0xF0, 0, 0
				DB 0xFF, 0xFC, 0, 0, 0xFF, 0xFF, 0xC0, 0, 0xFF, 0xFF
				DB 0xF0, 0xC0, 0xFF, 0xFF, 0xFC, 0xF0, 0xFF, 0xFF, 0xFE
				DB 0xFC, 0xFF, 0x3F, 0xFF, 0xFE, 0xFF, 0xCF, 0xFF, 0xFE
				DB 0xFF, 0xE3, 0xFF, 0xFE, 0xFF, 0xEC, 0xFF, 0xFE, 0xFF
				DB 0xEF, 0xFE, 0x3C, 0xFF, 0xEF, 0xFE, 0xCC, 0xFF, 0xF
				DB 0xFC, 0xE0, 0xFF, 0x67, 0xF0, 0xE0, 0xFF, 0xF9, 0xF0
				DB 0xE0, 0xFF, 0xFE, 0xF0, 0x60, 0xFF, 0xFF, 0xE0, 0x80
				DB 0xFF, 0xFF, 0xF0, 0xE0, 0xFF, 0xFF, 0xF8, 0xF0, 0xFF
				DB 0xFF, 0xF8, 0xF0, 0xFF, 0xFF, 0xF8, 0xF0, 0xFF, 0x7F
				DB 0xF8, 0xF0, 0xFF, 0x1F, 0xF8, 0xF0, 0xFF, 0x67, 0xF8
				DB 0xF0, 0xFF, 0x79, 0xFC, 0xF8, 0xFF, 0x7E, 0xFE, 0x7C
				DB 0xFF, 0x7F, 0xFE, 0x1C, 0xFF, 0x1F, 0x9E, 4, 0xFF
				DB 0xE7, 0x84, 0, 0xFF, 0xF9, 0x80, 0, 0xFF, 0xFE, 0
				DB 0, 0xFF, 0xFF, 0xE0, 0, 0xFF, 0xFF, 0xF8, 0xA0, 0xFF
				DB 0xFF, 0xFC, 0xB8, 0xFF, 0x3F, 0xFE, 0xDC, 0xFF, 0xCF
				DB 0xFE, 0xDC, 0xFF, 0xF3, 0xFE, 0xDC, 0xFF, 0xFC, 0xFF
				DB 0xDE, 0xFF, 0xFF, 0xFF, 0x1E, 0xFF, 0xFF, 0x9F, 0xE
				DB 0xFF, 0xFF, 0x8F, 2, 0xFF, 0xFF, 0x82, 0, 0xFF, 0x3F
				DB 0x80, 0, 0x3F, 0xF, 0x80, 0, 0xF, 3, 0x80, 0, 3, 0
				DB 0, 0
spr_074:        DB 4, 33
				DB 1, 0, 0xC0, 0, 0, 0, 0, 0, 3, 1, 0xE0, 0xC0, 0xC0
				DB 0, 0, 0, 7, 3, 0xF3, 0xE1, 0xE7, 0xC0, 0, 0, 7, 3
				DB 0xFF, 0xE3, 0xEF, 0xC7, 0x98, 0, 3, 1, 0xFF, 0xD3
				DB 0xFF, 0xCF, 0xFC, 0x8C, 0x3B, 1, 0xFF, 0x17, 0xFF
				DB 0x5F, 0xFE, 0xBC, 0x7F, 0x38, 0xFF, 0x98, 0xFF, 0xA7
				DB 0xFE, 0x7C, 0xFF, 0x7C, 0xFF, 0x51, 0xFF, 0x42, 0xFE
				DB 0xB8, 0xFF, 0x7E, 0xFF, 0, 0xFF, 5, 0xFF, 0x62, 0x7F
				DB 0x38, 0xFF, 0x7F, 0xFF, 0xFE, 0xFF, 0xE, 0x7F, 0x23
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xCE, 0x3F, 0xF, 0xFF
				DB 0xFF, 0xFF, 0xFF, 0xFF, 0xF6, 0x3F, 0x1F, 0xFF, 0x1F
				DB 0xFF, 0xFF, 0xFE, 0xF8, 0x7F, 0x3E, 0xFF, 0x1F, 0xFF
				DB 0xFF, 0xFE, 0xFC, 0x7F, 0x3C, 0xFF, 0x3F, 0xFF, 0xFF
				DB 0xFE, 0xFC, 0xFF, 0x7C, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF
				DB 0xFE, 0xFF, 0x78, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE
				DB 0xFF, 0x78, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xFF
				DB 0x78, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0x7F, 0x38
				DB 0xFF, 0xFF, 0xFF, 0xE0, 0xFE, 0x3C, 0x7F, 0x38, 0xFF
				DB 0x7F, 0xFF, 0x1F, 0xFE, 0xCC, 0x3F, 0x1C, 0xFF, 0x7C
				DB 0xFF, 0xFF, 0xFC, 0xF0, 0x3F, 0x1E, 0xFF, 0x7B, 0xFF
				DB 0xFF, 0xFE, 0xFC, 0x1F, 0xF, 0xFF, 0xF7, 0xFF, 0xFF
				DB 0xFE, 0xF4, 0xF, 7, 0xFF, 0xEF, 0xFF, 0xFF, 0xF7, 0xE2
				DB 7, 3, 0xFF, 0xDF, 0xFF, 0xFF, 0xE7, 0xC2, 7, 3, 0xFF
				DB 0x9F, 0xFF, 0xFF, 0xE7, 0xC2, 7, 3, 0xFF, 0x9F, 0xFF
				DB 0xFF, 0xE7, 0xC2, 7, 3, 0xF0, 0xF0, 0xF, 0xF, 0xEE
				DB 0xC2, 0xF, 7, 0, 0, 0, 0, 0xFE, 0xE4, 0x1C, 0xC, 0
				DB 0, 0, 0, 0x3C, 0x38, 0x18, 8, 0, 0, 0, 0, 0x18, 0x10
				DB 0x10, 0, 0, 0, 0, 0, 8, 0
spr_075:        DB 4, 11
				DB 0, 0, 0xF, 0, 0xF0, 0, 0, 0, 0, 0, 0xFF, 5, 0xFF, 0x50
				DB 0, 0, 3, 0, 0xFF, 0x6C, 0xFF, 0x21, 0xC0, 0, 7, 2
				DB 0xFF, 0x92, 0xFF, 0x91, 0xE0, 0x80, 0xF, 7, 0xFF, 0xFD
				DB 0xFF, 0x51, 0xF0, 0x60, 0x1F, 0xD, 0xFF, 0x35, 0xFF
				DB 0xE0, 0xF8, 0xF0, 0xF, 6, 0xFF, 0xFB, 0xFF, 0x78, 0xF0
				DB 0x60, 7, 3, 0xFF, 0xDD, 0xFF, 0xF8, 0xE0, 0xC0, 3
				DB 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xC0, 0, 0, 0, 0xFF, 0xF
				DB 0xFF, 0xF0, 0, 0, 0, 0, 0xF, 0, 0xF0, 0, 0, 0
spr_076:        DB 5, 25
				DB 0, 0, 0xC0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0xF1, 0xC0
				DB 0x80, 0, 0, 0, 0, 0, 1, 0, 0xFB, 0xF8, 0xE0, 0x80
				DB 0, 0, 0, 0, 1, 0, 0xFF, 0xF9, 0xF8, 0xE0, 0, 0, 0
				DB 0, 1, 0, 0xFF, 0xF9, 0xFE, 0xF8, 0x60, 0, 0, 0, 0x71
				DB 0, 0xFF, 0xF8, 0xFF, 0x7E, 0xF8, 0x60, 0, 0, 0xFD
				DB 0x70, 0xFF, 0xF9, 0xFF, 0x9F, 0xFE, 0x78, 0, 0, 0xFF
				DB 0x7C, 0xFF, 0xFB, 0xFF, 0xE7, 0xFF, 0x7E, 0x80, 0
				DB 0xFF, 0x7F, 0xFF, 0x3B, 0xFF, 0xF9, 0xFF, 0x7F, 0xE0
				DB 0x80, 0xFF, 0x7F, 0xFF, 0xCD, 0xFF, 0xFE, 0xFF, 0x7F
				DB 0xF8, 0xE0, 0x7F, 0x3F, 0xFF, 0xF3, 0xFF, 0xFF, 0xFF
				DB 0x9F, 0xFE, 0xF8, 0x3F, 0xF, 0xFF, 0xFC, 0xFF, 0xFF
				DB 0xFF, 0xC7, 0xFF, 0xFE, 0xF, 3, 0xFF, 0xFF, 0xFF, 0x3F
				DB 0xFF, 0xE9, 0xFF, 0xFE, 3, 0, 0xFF, 0xFF, 0xFF, 0x8F
				DB 0xFF, 0xEE, 0xFF, 0x7E, 0, 0, 0xFF, 0x3F, 0xCF, 0x83
				DB 0xFF, 0xEF, 0xFF, 0x9E, 0, 0, 0xFF, 0x4F, 0xC3, 0x80
				DB 0xFF, 0xEF, 0xFF, 0xC6, 0, 0, 0xFF, 0x73, 0xC0, 0x80
				DB 0xFF, 0x2F, 0xE6, 0xC0, 0, 0, 0xFF, 0x7C, 0xC0, 0x80
				DB 0x3F, 0xF, 0xE0, 0xC0, 0, 0, 0x7F, 0x3F, 0xC0, 0, 0x1F
				DB 0xF, 0xE0, 0xC0, 0, 0, 0x3F, 0xF, 0xF0, 0xC0, 0xF
				DB 0xF, 0xE0, 0xC0, 0, 0, 0xF, 3, 0xF8, 0xF0, 0xF, 7
				DB 0xE0, 0xC0, 0, 0, 3, 0, 0xFC, 0xF8, 7, 1, 0xE0, 0xC0
				DB 0, 0, 0, 0, 0xFC, 0x38, 1, 0, 0xE0, 0x40, 0, 0, 0
				DB 0, 0x3C, 8, 0, 0, 0x40, 0, 0, 0, 0, 0, 8, 0, 0, 0
				DB 0, 0
spr_077:        DB 3, 24
				DB 1, 0, 0x80, 0, 0, 0, 3, 1, 0xE0, 0x80, 0, 0, 3, 1
				DB 0xF8, 0xE0, 0, 0, 3, 1, 0xFE, 0xF8, 0, 0, 1, 0, 0xFF
				DB 0xFE, 0x80, 0, 0, 0, 0xFF, 0x7F, 0xC0, 0x80, 8, 0
				DB 0xFF, 0x7F, 0xE0, 0x80, 0x1E, 8, 0x7F, 0x3F, 0xF1
				DB 0xA0, 0x3F, 0x1E, 0xFF, 0x3F, 0xFC, 0xB8, 0x3F, 0x1F
				DB 0xFF, 0xBF, 0xFC, 0xB8, 0x1F, 0xF, 0xFF, 0xBF, 0xFC
				DB 0xB8, 0x1F, 0xF, 0xFF, 0x9F, 0xFC, 0xB8, 0x7F, 0xF
				DB 0xFF, 0xA7, 0xFC, 0x98, 0xFF, 0x67, 0xFF, 0xB9, 0xD8
				DB 0x80, 0xFF, 0x79, 0xFF, 0xBE, 0xC0, 0, 0xFF, 0x7E
				DB 0xFF, 0x3F, 0xE0, 0x80, 0x7F, 0x3F, 0xFF, 0x9F, 0xF8
				DB 0xE0, 0x3F, 0xF, 0xFF, 0xE7, 0xFE, 0xF8, 0xF, 3, 0xFF
				DB 0xF9, 0xFF, 0xFE, 3, 0, 0xFF, 0xFD, 0xFF, 0xFE, 0
				DB 0, 0xFF, 0x3D, 0xFF, 0xFE, 0, 0, 0x3F, 0xC, 0xFF, 0x7E
				DB 0, 0, 0xC, 0, 0x7E, 0x1C, 0, 0, 0, 0, 0x1C, 0
spr_078:        DB 3, 18
				DB 0x40, 0, 0, 0, 0, 0, 0xF0, 0x40, 0, 0, 0, 0, 0xFC
				DB 0x70, 0, 0, 0, 0, 0xFF, 0x7C, 0, 0, 0, 0, 0xFF, 0x7F
				DB 0xC3, 0, 0, 0, 0xFF, 0x7F, 0xF7, 0xC3, 0xC0, 0, 0x7F
				DB 0x33, 0xFF, 0xF3, 0xF0, 0xC0, 0x3F, 0x14, 0xFF, 0xFB
				DB 0xFC, 0xF0, 0x1F, 7, 0xFF, 0x3B, 0xFE, 0xFC, 0xF, 7
				DB 0xFF, 0xCB, 0xFF, 0xFE, 0xF, 7, 0xFF, 0xF3, 0xFF, 0xFE
				DB 7, 1, 0xFF, 0xFC, 0xFF, 0xFE, 1, 0, 0xFF, 0x7F, 0xFF
				DB 0x3E, 0, 0, 0x7F, 0x1F, 0xFF, 0xCE, 0, 0, 0x1F, 7
				DB 0xFF, 0xE2, 0, 0, 7, 1, 0xF2, 0xE0, 0, 0, 1, 0, 0xF0
				DB 0x60, 0, 0, 0, 0, 0x60, 0
spr_079:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x60, 0, 0, 0, 9
				DB 0, 0xF0, 0x60, 3, 0, 0x1F, 9, 0xF8, 0xF0, 0x27, 3
				DB 0x9F, 0xF, 0xF8, 0xF0, 0x7F, 0x27, 0xCF, 0x87, 0xF0
				DB 0x60, 0x7F, 0x3F, 0xC7, 0x80, 0xF0, 0xE0, 0x7F, 0x3D
				DB 0xC1, 0x80, 0xE0, 0xC0, 0x3F, 0x1B, 0x8D, 0, 0xE0
				DB 0xC0, 0x1F, 3, 0xBF, 0xD, 0xE0, 0xC0, 7, 3, 0xFF, 0x3E
				DB 0xF0, 0xE0, 7, 3, 0xFF, 0xFF, 0xF8, 0x60, 3, 1, 0xFF
				DB 0xFF, 0xF8, 0x60
spr_080:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xC0, 0, 0, 0, 9, 0, 0xE3
				DB 0xC0, 0x80, 0, 0x1F, 9, 0xFF, 0xE3, 0xC0, 0x80, 0x1F
				DB 0xF, 0xFF, 0xEF, 0xC0, 0x80, 0x1F, 0xF, 0xFF, 0x5F
				DB 0xC0, 0x80, 0xF, 6, 0xFF, 0xD9, 0x80, 0, 7, 0, 0xFF
				DB 0xC3, 0x80, 0, 1, 0, 0xFF, 0xFB, 0x80, 0, 1, 0, 0xFF
				DB 0xFD, 0xC0, 0x80, 1, 0, 0xFF, 0xFE, 0xE0, 0xC0, 1
				DB 0, 0xFF, 0xFE, 0xE0, 0xC0, 0, 0, 0xFF, 0x7E, 0xE0
				DB 0xC0
spr_081:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0x18, 0, 0, 0, 1, 0, 0x3C, 0x18, 0, 0, 3
				DB 1, 0xFE, 0x3C, 0, 0, 3, 1, 0xFE, 0xFC, 0, 0, 3, 1
				DB 0xFE, 0xEC, 0, 0, 1, 0, 0xFF, 0xDA, 0, 0, 3, 1, 0xFF
				DB 0x36, 0, 0, 3, 1, 0xFE, 0xB4, 0, 0, 3, 1, 0xFF, 0x7A
				DB 0, 0, 1, 0, 0xFF, 0x7C, 0, 0, 0, 0, 0xFF, 0x7E, 0
				DB 0, 0, 0, 0x7F, 0x3F, 0xC0, 0, 0, 0, 0xFF, 0x7F, 0xE0
				DB 0x40
spr_082:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0
				DB 0, 0, 0, 0x5F, 6, 0, 0, 0, 0, 0xFF, 0x5F, 0x80, 0
				DB 0, 0, 0xFF, 0x7B, 0x80, 0, 0, 0, 0x7F, 0x37, 0x80
				DB 0, 2, 0, 0x7F, 6, 0, 0, 7, 2, 0xFF, 0x6E, 0, 0, 7
				DB 3, 0xFE, 0xEC, 0, 0, 7, 3, 0xFE, 0xDC, 0, 0, 3, 0
				DB 0xFF, 0x5E, 0, 0, 0, 0, 0xFF, 0x5F, 0x80, 0, 1, 0
				DB 0xFF, 0xDF, 0x80, 0, 1, 0, 0xFF, 0xBF, 0xC0, 0x80
				DB 3, 1, 0xFF, 0xBF, 0xC0, 0x80
spr_083:        DB 3, 16
				DB 0, 0, 1, 0, 0, 0, 0, 0, 7, 1, 0x80, 0, 0, 0, 0x1F
				DB 7, 0x80, 0, 0, 0, 0x7F, 0x1F, 0x80, 0, 0, 0, 0xFF
				DB 0x7C, 0, 0, 1, 0, 0xFC, 0xF0, 0, 0, 0, 0, 0xFE, 0x64
				DB 0, 0, 0, 0, 0xFE, 0x74, 0, 0, 3, 0, 0xFC, 0xB8, 0
				DB 0, 7, 3, 0xFE, 0xBC, 0, 0, 7, 3, 0xFE, 0x7C, 0, 0
				DB 7, 2, 0xFE, 0xFC, 0, 0, 3, 1, 0xFF, 0xFA, 0, 0, 7
				DB 3, 0xFF, 0xFA, 0, 0, 7, 3, 0xFF, 0xF6, 0, 0, 7, 3
				DB 0xFF, 0xFF, 0x80, 0
spr_084:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0
				DB 0, 0, 0, 0x3C, 8, 0x80, 0, 0, 0, 0xFF, 0x38, 0xC0
				DB 0x80, 3, 0, 0xFF, 0xFB, 0xC0, 0x80, 7, 3, 0xFF, 0xF7
				DB 0xC0, 0x80, 0xF, 7, 0xFF, 0xC7, 0x80, 0, 7, 3, 0xFE
				DB 0x3C, 0, 0, 7, 3, 0xFC, 0xB8, 0, 0, 3, 1, 0xFC, 0xD8
				DB 0, 0, 3, 1, 0xFE, 0xEC, 0, 0, 1, 0, 0xFF, 0xEE, 0
				DB 0, 1, 0, 0xFF, 0xF7, 0x80, 0, 3, 1, 0xFF, 0xF7, 0x80
				DB 0, 3, 1, 0xFF, 0xFF, 0x80, 0
spr_085:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0, 0, 0x20, 0, 0x20, 0, 0, 0, 0xF1, 0x20, 0xF0
				DB 0x20, 3, 0, 0xF7, 0xE1, 0xF0, 0xE0, 0xF, 3, 0xFF, 0xE7
				DB 0xF0, 0xE0, 0x1F, 0xF, 0xFF, 0xDF, 0xE0, 0x80, 0x3F
				DB 0x1F, 0xFF, 0x1E, 0x80, 0, 0x1F, 0xE, 0x9E, 0xC, 0
				DB 0, 0xF, 7, 0xFF, 0x8E, 0, 0, 7, 1, 0xFF, 0xEF, 0x80
				DB 0, 1, 0, 0xFF, 0xF7, 0x80, 0, 1, 0, 0xFF, 0xF7, 0xC0
				DB 0x80, 3, 1, 0xFF, 0xF7, 0xC0, 0x80, 3, 1, 0xFF, 0xFF
				DB 0x80, 0
spr_086:        DB 3, 16
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8
				DB 0, 0, 0, 0, 0, 0x3C, 8, 1, 0, 0, 0, 0xFC, 0x38, 7
				DB 1, 0x83, 0, 0xFC, 0xF8, 0x1F, 7, 0x87, 3, 0xF8, 0xE0
				DB 0x3F, 0x1F, 0x8F, 7, 0xE0, 0x80, 0x7F, 0x3C, 7, 3
				DB 0x80, 0, 0xFF, 0x70, 3, 1, 0xC0, 0x80, 0xFF, 0x7F
				DB 0x83, 1, 0xE0, 0xC0, 0x7F, 0x3F, 0xC7, 0x83, 0xE0
				DB 0xC0, 0x3F, 7, 0xEF, 0xC7, 0xE0, 0xC0, 7, 3, 0xFF
				DB 0xEF, 0xE0, 0xC0, 7, 3, 0xFF, 0xEF, 0xC0, 0x80, 7
				DB 3, 0xFF, 0xFF, 0xC0, 0x80
spr_087:        DB 3, 29
				DB 0, 0, 0x18, 0, 0, 0, 0, 0, 0x3C, 0x18, 0, 0, 0, 0
				DB 0x7E, 0x34, 0, 0, 0, 0, 0x74, 0x20, 0, 0, 0, 0, 0xF0
				DB 0x60, 0, 0, 0, 0, 0xF8, 0x70, 0, 0, 0, 0, 0xF8, 0x70
				DB 0, 0, 0, 0, 0x7C, 0x38, 0, 0, 0, 0, 0x7E, 0x3C, 0
				DB 0, 0, 0, 0x3F, 0x1D, 0xE0, 0xC0, 0, 0, 0x7F, 0x3D
				DB 0xE0, 0xC0, 0, 0, 0xFF, 0x7B, 0xE0, 0xC0, 1, 0, 0xFF
				DB 0xF7, 0xF0, 0xC0, 1, 0, 0xFF, 0xEF, 0xF8, 0xD0, 3
				DB 1, 0xFF, 0xFF, 0xFC, 0xF8, 3, 1, 0xFF, 0xFF, 0xFC
				DB 0xF8, 1, 0, 0xFF, 0x7F, 0xFC, 0xF8, 1, 0, 0xFF, 0x8F
				DB 0xF8, 0xE0, 1, 0, 0xFF, 0x9F, 0xF8, 0xF0, 3, 1, 0xFF
				DB 0xF7, 0xF8, 0xF0, 3, 1, 0xFF, 0xD7, 0xF8, 0xF0, 1
				DB 0, 0xFF, 0xBB, 0xF8, 0xF0, 0, 0, 0xFF, 0x7B, 0xF8
				DB 0xF0, 0, 0, 0xFF, 0x77, 0xF8, 0xF0, 1, 0, 0xFF, 0xEF
				DB 0xF0, 0xE0, 1, 0, 0xEF, 0xC0, 0xF0, 0xE0, 0, 0, 0xC1
				DB 0, 0xE0, 0xC0, 0, 0, 1, 0, 0xC0, 0x80, 0, 0, 0, 0
				DB 0x80, 0
spr_088:        DB 3, 29
				DB 0, 0, 0x30, 0, 0, 0, 0, 0, 0x78, 0x30, 0, 0, 0, 0
				DB 0xFC, 0x68, 0, 0, 0, 0, 0xF8, 0x60, 0, 0, 1, 0, 0xF0
				DB 0xE0, 0, 0, 1, 0, 0xF0, 0xE0, 0, 0, 1, 0, 0xF8, 0xF0
				DB 0, 0, 0, 0, 0xF8, 0x70, 0, 0, 0, 0, 0xFC, 0x78, 0
				DB 0, 0, 0, 0xFF, 0x7B, 0xE0, 0xC0, 0, 0, 0xFF, 0x7B
				DB 0xF0, 0xC0, 0, 0, 0xFF, 0x77, 0xF8, 0xD0, 1, 0, 0xFF
				DB 0xEF, 0xF8, 0xD0, 1, 0, 0xFF, 0xFF, 0xFC, 0xD8, 3
				DB 1, 0xFF, 0xFF, 0xFC, 0xF8, 3, 1, 0xFF, 0xFF, 0xFC
				DB 0xF8, 1, 0, 0xFF, 0x7F, 0xFC, 0xF8, 1, 0, 0xFF, 0x8F
				DB 0xF8, 0xE0, 1, 0, 0xFF, 0x9F, 0xF8, 0xF0, 3, 1, 0xFF
				DB 0xF7, 0xF8, 0xF0, 3, 1, 0xFF, 0xD7, 0xF8, 0xF0, 1
				DB 0, 0xFF, 0xBB, 0xF8, 0xF0, 0, 0, 0xFF, 0x7B, 0xF8
				DB 0xF0, 0, 0, 0xFF, 0x77, 0xF8, 0xF0, 1, 0, 0xFF, 0xEF
				DB 0xF0, 0xE0, 1, 0, 0xEF, 0xC0, 0xF0, 0xE0, 0, 0, 0xC1
				DB 0, 0xE0, 0xC0, 0, 0, 1, 0, 0xC0, 0x80, 0, 0, 0, 0
				DB 0x80, 0
spr_089:        DB 3, 29
				DB 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0
				DB 0, 0, 0xF, 6, 0xC0, 0x80, 0, 0, 0xF, 6, 0x80, 0, 0
				DB 0, 0xF, 6, 0, 0, 0, 0, 0xF, 7, 0xC0, 0, 0, 0, 7, 3
				DB 0xE0, 0xC0, 0, 0, 3, 1, 0xF0, 0xE0, 0, 0, 1, 0, 0xFF
				DB 0xF7, 0xF8, 0xD0, 1, 0, 0xFF, 0xF7, 0xFC, 0xD8, 1
				DB 0, 0xFF, 0xEF, 0xFC, 0xD8, 1, 0, 0xFF, 0xEF, 0xFC
				DB 0xD8, 1, 0, 0xFF, 0xFF, 0xFC, 0xE8, 3, 1, 0xFF, 0xFF
				DB 0xFC, 0xF8, 3, 1, 0xFF, 0xFF, 0xFC, 0xF8, 1, 0, 0xFF
				DB 0x7F, 0xFC, 0xF8, 1, 0, 0xFF, 0x8F, 0xF8, 0xE0, 1
				DB 0, 0xFF, 0x9F, 0xF8, 0xF0, 3, 1, 0xFF, 0xF7, 0xF8
				DB 0xF0, 3, 1, 0xFF, 0xD7, 0xF8, 0xF0, 1, 0, 0xFF, 0xBB
				DB 0xF8, 0xF0, 0, 0, 0xFF, 0x7B, 0xF8, 0xF0, 0, 0, 0xFF
				DB 0x77, 0xF8, 0xF0, 1, 0, 0xFF, 0xEF, 0xF0, 0xE0, 1
				DB 0, 0xEF, 0xC0, 0xF0, 0xE0, 0, 0, 0xC1, 0, 0xE0, 0xC0
				DB 0, 0, 1, 0, 0xC0, 0x80, 0, 0, 0, 0, 0x80, 0
spr_090:        DB 3, 29
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 0x10, 0, 0, 0, 0, 0, 0x38, 0x10, 0, 0, 0, 0, 0x70
				DB 0x20, 0, 0, 0, 0, 0xFC, 0x60, 0, 0, 0, 0, 0xFF, 0x7C
				DB 0xC0, 0, 0xC, 0, 0x7F, 0x3F, 0xE0, 0xC0, 0xE, 0xC
				DB 0x3F, 0xF, 0xFF, 0xEF, 0xFF, 0xDE, 0xF, 1, 0xFF, 0xEF
				DB 0xFF, 0xD6, 3, 1, 0xFF, 0xDF, 0xFF, 0xC6, 3, 1, 0xFF
				DB 0xDF, 0xFF, 0xEE, 3, 1, 0xFF, 0xFF, 0xFE, 0xEC, 3
				DB 1, 0xFF, 0xFF, 0xFE, 0xFC, 3, 0, 0xFF, 0xFF, 0xFE
				DB 0xFC, 1, 0, 0xFF, 0x7F, 0xFC, 0xF8, 1, 0, 0xFF, 0x8F
				DB 0xF8, 0xE0, 1, 0, 0xFF, 0x9F, 0xF8, 0xF0, 3, 1, 0xFF
				DB 0xF7, 0xF8, 0xF0, 3, 1, 0xFF, 0xD7, 0xF8, 0xF0, 1
				DB 0, 0xFF, 0xBB, 0xF8, 0xF0, 0, 0, 0xFF, 0x7B, 0xF8
				DB 0xF0, 0, 0, 0xFF, 0x77, 0xF8, 0xF0, 1, 0, 0xFF, 0xEF
				DB 0xF0, 0xE0, 1, 0, 0xEF, 0xC0, 0xF0, 0xE0, 0, 0, 0xC1
				DB 0, 0xE0, 0xC0, 0, 0, 1, 0, 0xC0, 0x80, 0, 0, 0, 0
				DB 0x80, 0
spr_091:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0x20, 0, 0, 0, 0, 0, 0x70
				DB 0x20, 0, 0, 0, 0, 0x78, 0x30, 0, 0, 0, 0, 0xF8, 0x30
				DB 0, 0, 1, 0, 0xF8, 0xF0, 0, 0, 3, 1, 0xF0, 0xE0, 0x10
				DB 0, 7, 3, 0xE0, 0xC0, 0x38, 0x10, 0xF, 7, 0xC0, 0x80
				DB 0x3C, 0x18, 0x1F, 0xF, 0xFF, 0x7F, 0xFC, 0x98, 0x1F
				DB 0xF, 0xFF, 0x7F, 0xFC, 0xB8, 0x1F, 0xF, 0xFF, 0x7F
				DB 0xF8, 0xB0, 0xF, 7, 0xFF, 0x7F, 0xF0, 0xA0, 0xF, 7
				DB 0xFF, 0x7F, 0xE0, 0x80, 0xF, 7, 0xFF, 0xFE, 0xC0, 0
				DB 0xF, 7, 0xFF, 0xF1, 0xE0, 0xC0, 0xF, 7, 0xFF, 0xEA
				DB 0xE0, 0x80, 7, 2, 0xFF, 0x1A, 0xF0, 0x20, 3, 1, 0xFF
				DB 0xFB, 0xF0, 0xE0, 3, 1, 0xFF, 0xF6, 0xF0, 0xA0, 3
				DB 1, 0xFF, 0xFF, 0xF0, 0xE0, 3, 1, 0xFF, 0x7F, 0xE0
				DB 0xC0, 1, 0, 0xFF, 0xF7, 0xE0, 0x40, 1, 0, 0xFF, 0xF2
				DB 0xF0, 0x60, 3, 1, 0xFF, 0xFF, 0xF8, 0xD0, 3, 1, 0xFF
				DB 0xFF, 0xF8, 0xB0, 7, 3, 0xFF, 0xDF, 0xF8, 0xE0, 7
				DB 3, 0xDF, 0, 0x78, 0x30, 0xF, 4, 0, 0, 0x3C, 8, 4, 0
				DB 0, 0, 8, 0
spr_092:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0x80, 0, 0, 0, 1, 0, 0xC0
				DB 0x80, 0, 0, 0, 0, 0xE0, 0x40, 0, 0, 0, 0, 0xF0, 0x60
				DB 0, 0, 1, 0, 0xF0, 0xE0, 0, 0, 7, 1, 0xE0, 0xC0, 0x10
				DB 0, 0xF, 7, 0xC0, 0x80, 0x38, 0x10, 0x1F, 0xF, 0x80
				DB 0, 0x3C, 8, 0x3F, 0x1E, 0xFF, 0xFF, 0xFE, 0x8C, 0x7F
				DB 0x3E, 0xFF, 0xFF, 0xFE, 0x9C, 0x3F, 0x1E, 0xFF, 0xFF
				DB 0xFC, 0xB8, 0x3F, 0x1F, 0xFF, 0x7F, 0xF8, 0xB0, 0x3F
				DB 0x1F, 0xFF, 0x7F, 0xF0, 0x80, 0x1F, 0xF, 0xFF, 0xFE
				DB 0xC0, 0, 0x1F, 0xF, 0xFF, 0xF1, 0xE0, 0xC0, 0x1F, 0xF
				DB 0xFF, 0xEA, 0xE0, 0x80, 0xF, 6, 0xFF, 0x1A, 0xF0, 0x20
				DB 7, 1, 0xFF, 0xFB, 0xF0, 0xE0, 3, 1, 0xFF, 0xF6, 0xF0
				DB 0xA0, 3, 1, 0xFF, 0xFF, 0xF0, 0xE0, 3, 1, 0xFF, 0x7F
				DB 0xE0, 0xC0, 1, 0, 0xFF, 0xF7, 0xE0, 0x40, 1, 0, 0xFF
				DB 0xF2, 0xF0, 0x60, 3, 1, 0xFF, 0xFF, 0xF8, 0xD0, 3
				DB 1, 0xFF, 0xFF, 0xF8, 0xB0, 7, 3, 0xFF, 0xDF, 0xF8
				DB 0x70, 7, 3, 0xBF, 0, 0x78, 0x30, 0xF, 4, 0, 0, 0x3C
				DB 8, 4, 0, 0, 0, 8, 0
spr_093:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0
				DB 0, 7, 3, 0x80, 0, 0, 0, 3, 1, 0xC0, 0x80, 0, 0, 3
				DB 1, 0xC0, 0x80, 8, 0, 3, 1, 0xC0, 0x80, 0x1C, 8, 7
				DB 3, 0xC0, 0x80, 0xE, 4, 0xF, 7, 0x80, 0, 0xE, 4, 0x1F
				DB 0xE, 0xFF, 0xFF, 0xFE, 0x8C, 0x3F, 0x1C, 0xFF, 0xFF
				DB 0xFE, 0xBC, 0x7F, 0x3C, 0xFF, 0xFF, 0xFC, 0xB8, 0x7F
				DB 0x3E, 0xFF, 0x7F, 0xF8, 0xB0, 0x3F, 0x1F, 0xFF, 0x7F
				DB 0xF0, 0x80, 0x3F, 0x1F, 0xFF, 0xFE, 0xC0, 0, 0x1F
				DB 0xF, 0xFF, 0xF1, 0xE0, 0xC0, 0xF, 7, 0xFF, 0xEA, 0xE0
				DB 0x80, 7, 2, 0xFF, 0x1A, 0xF0, 0x20, 3, 1, 0xFF, 0xFB
				DB 0xF0, 0xE0, 3, 1, 0xFF, 0xF6, 0xF0, 0xA0, 3, 1, 0xFF
				DB 0xFF, 0xF0, 0xE0, 3, 1, 0xFF, 0x7F, 0xE0, 0xC0, 1
				DB 0, 0xFF, 0xF7, 0xE0, 0x60, 1, 0, 0xFF, 0xF2, 0xF0
				DB 0x40, 3, 1, 0xFF, 0xFF, 0xF8, 0xD0, 3, 1, 0xFF, 0xFF
				DB 0xF8, 0xB0, 7, 3, 0xFF, 0xDF, 0xF8, 0x70, 7, 3, 0xDF
				DB 0, 0x78, 0x30, 0xF, 4, 0, 0, 0x3C, 8, 4, 0, 0, 0, 8
				DB 0
spr_094:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				DB 0, 6, 0, 0, 0, 0xC, 0, 0xF, 6, 0, 0, 0x1E, 0xC, 7
				DB 3, 0x80, 0, 0xF, 6, 7, 3, 0x80, 0, 0xF, 6, 7, 3, 0x80
				DB 0, 0x1F, 0xE, 0xF, 6, 0, 0, 0x3E, 0x1C, 0xF, 6, 0xFF
				DB 0xFF, 0xFC, 0xB8, 0x1F, 0xD, 0xFF, 0xFF, 0xFC, 0xB8
				DB 0x1F, 0xD, 0xFF, 0xFF, 0xF8, 0xB0, 0x3F, 0x1E, 0xFF
				DB 0xFF, 0xF8, 0xB0, 0x3F, 0x1F, 0xFF, 0x7F, 0xF8, 0xB0
				DB 0x3F, 0x1F, 0xFF, 0xFE, 0xF0, 0x20, 0x1F, 0xF, 0xFF
				DB 0xF1, 0xE0, 0xC0, 0xF, 7, 0xFF, 0xEA, 0xE0, 0x80, 7
				DB 2, 0xFF, 0x1A, 0xF0, 0x20, 3, 1, 0xFF, 0xFB, 0xF0
				DB 0xE0, 3, 1, 0xFF, 0xF6, 0xF0, 0xA0, 3, 1, 0xFF, 0xFF
				DB 0xF0, 0xE0, 3, 1, 0xFF, 0x7F, 0xE0, 0xC0, 1, 0, 0xFF
				DB 0xF7, 0xE0, 0x40, 1, 0, 0xFF, 0xF2, 0xF0, 0x60, 3
				DB 1, 0xFF, 0xFF, 0xF8, 0xD0, 3, 1, 0xFF, 0xFF, 0xF8
				DB 0xB0, 7, 3, 0xFF, 0xDF, 0xF8, 0x70, 7, 3, 0xDF, 0
				DB 0x78, 0x30, 0xF, 4, 0, 0, 0x3C, 8, 4, 0, 0, 0, 8, 0
spr_095:        DB 3, 29
				DB 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0
				DB 0, 0, 0xF, 6, 0xC0, 0x80, 0, 0, 0xF, 6, 0x80, 0, 0
				DB 0, 0xF, 6, 0x80, 0, 0, 0, 7, 3, 0xE0, 0x80, 0, 0, 3
				DB 1, 0xF0, 0xE0, 0, 0, 1, 0, 0xF8, 0xF0, 0, 0, 0, 0
				DB 0xFF, 0x77, 0xF0, 0xC0, 0, 0, 0xFF, 0x77, 0xF8, 0xD0
				DB 1, 0, 0xFF, 0xF7, 0xF8, 0xD0, 1, 0, 0xFF, 0xF7, 0xFC
				DB 0xD8, 1, 0, 0xFF, 0xFF, 0xFC, 0xE8, 1, 0, 0xFF, 0xFF
				DB 0xFC, 0xF8, 3, 0, 0xFF, 0xFF, 0xFC, 0xF8, 7, 3, 0xFF
				DB 0x3F, 0xF8, 0xF0, 7, 3, 0xFF, 0xFF, 0xF0, 0xC0, 7
				DB 0, 0xFF, 0x3F, 0xF0, 0xE0, 0xE, 4, 0xFF, 0x7F, 0xF0
				DB 0xE0, 0xF, 6, 0xFF, 0xEF, 0xF0, 0xE0, 0x1F, 0xF, 0xFF
				DB 0xDF, 0xF0, 0xE0, 0x1F, 0xB, 0xFF, 0xDF, 0xF0, 0xE0
				DB 0xF, 6, 0xFF, 0x3F, 0xF0, 0xE0, 6, 0, 0x7F, 0x3F, 0xE0
				DB 0xC0, 0, 0, 0x7F, 0x33, 0xC0, 0x80, 0, 0, 0x77, 0x23
				DB 0xC0, 0x80, 0, 0, 0x27, 3, 0x80, 0, 0, 0, 3, 0, 0
				DB 0
spr_096:        DB 3, 29
				DB 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 7, 3, 0x80, 0
				DB 0, 0, 0xF, 6, 0xC0, 0x80, 0, 0, 0xF, 6, 0x80, 0, 0
				DB 0, 0xF, 6, 0, 0, 0, 0, 0xF, 6, 0, 0, 0, 0, 0xF, 7
				DB 0x80, 0, 0, 0, 0xF, 7, 0xC0, 0x80, 0, 0, 7, 3, 0xFF
				DB 0xDF, 0xF8, 0xD0, 3, 1, 0xFF, 0xDF, 0xFC, 0xD8, 3
				DB 1, 0xFF, 0xDF, 0xFC, 0xD8, 3, 1, 0xFF, 0xDF, 0xFE
				DB 0xDC, 3, 1, 0xFF, 0xDF, 0xFE, 0xFC, 3, 1, 0xFF, 0xFF
				DB 0xFE, 0xFC, 1, 0, 0xFF, 0xFF, 0xFE, 0xFC, 1, 0, 0xFF
				DB 0xFF, 0xFC, 0xF8, 0, 0, 0xFF, 0x1F, 0xFC, 0xE0, 0
				DB 0, 0x7F, 0x3F, 0xFE, 0xFC, 0, 0, 0x7F, 0x3F, 0xFF
				DB 0xFE, 0, 0, 0x7F, 0x3F, 0xFE, 0xF8, 0, 0, 0x7F, 0x3F
				DB 0xFF, 0xFE, 0, 0, 0x7F, 0x3F, 0xFF, 0xFE, 0, 0, 0x7F
				DB 0x3F, 0xFE, 0xF8, 0, 0, 0x7F, 0x3F, 0xF8, 0xF0, 0
				DB 0, 0x7F, 0x38, 0xF8, 0x70, 0, 0, 0x3C, 0x18, 0xF8
				DB 0x70, 0, 0, 0x1C, 8, 0x70, 0x20, 0, 0, 8, 0, 0x20
				DB 0
spr_097:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0x20, 0, 0, 0, 0, 0, 0x70
				DB 0x20, 0, 0, 0, 0, 0x78, 0x30, 0, 0, 0, 0, 0xF8, 0x30
				DB 0, 0, 1, 0, 0xF8, 0xF0, 0, 0, 3, 1, 0xF0, 0xE0, 0x10
				DB 0, 7, 3, 0xE0, 0xC0, 0x38, 0x10, 0xF, 7, 0xC0, 0, 0x3C
				DB 0x18, 0x1F, 0xF, 0xFF, 0x7F, 0xFC, 0x98, 0x1F, 0xF
				DB 0xFF, 0x7F, 0xFC, 0xB8, 0x1F, 0xF, 0xFF, 0x7F, 0xF8
				DB 0xB0, 0xF, 7, 0xFF, 0x7F, 0xF0, 0xE0, 0xF, 7, 0xFF
				DB 0xFF, 0xF0, 0xE0, 7, 3, 0xFF, 0xFF, 0xFC, 0x80, 7
				DB 3, 0xFF, 0xFF, 0xFE, 0x7C, 7, 3, 0xFF, 0xFC, 0xFE
				DB 0xC0, 3, 1, 0xFF, 3, 0xFF, 0x92, 1, 0, 0xFF, 0xFF
				DB 0xFF, 0x12, 1, 0, 0xFF, 0xFE, 0xFF, 0x7E, 1, 0, 0xFF
				DB 0xFF, 0xFF, 0xEA, 1, 0, 0xFF, 0xFF, 0xFE, 0xFC, 0
				DB 0, 0xFF, 0x7D, 0xFC, 0xF0, 0, 0, 0xFF, 0x7C, 0xF0
				DB 0xA0, 1, 0, 0xFF, 0xFF, 0xF0, 0xE0, 1, 0, 0xFF, 0xFF
				DB 0xF0, 0xE0, 1, 0, 0xFF, 0xF7, 0xF0, 0xE0, 1, 0, 0xFF
				DB 0xE0, 0xF0, 0xE0, 3, 1, 0xE0, 0x80, 0xF8, 0x30, 1
				DB 0, 0x80, 0, 0x30, 0
spr_098:        DB 3, 30
				DB 0, 0, 0, 0, 0, 0, 0, 0, 0x80, 0, 0, 0, 1, 0, 0xC0
				DB 0x80, 0, 0, 0, 0, 0xE0, 0x40, 0, 0, 0, 0, 0xE0, 0x40
				DB 0, 0, 1, 0, 0xE0, 0xC0, 0, 0, 3, 1, 0xE0, 0xC0, 0x10
				DB 0, 7, 3, 0xC0, 0x80, 0x38, 0x10, 0xF, 7, 0x80, 0, 0x3C
				DB 0x18, 0x1F, 0xE, 0xFF, 0xFF, 0xFC, 0xD8, 0x1F, 0xE
				DB 0xFF, 0xFF, 0xFC, 0xD8, 0x1F, 0xE, 0xFF, 0xFF, 0xFC
				DB 0xD8, 0x3F, 0x1E, 0xFF, 0xFF, 0xFC, 0xB8, 0x3F, 0x1F
				DB 0xFF, 0xFF, 0xFC, 0xF8, 0x3F, 0x1F, 0xFF, 0x3F, 0xF8
				DB 0xF0, 0x3F, 0x1C, 0xFF, 0xCF, 0xF8, 0xF0, 0x1F, 0xA
				DB 0xFF, 0x14, 0xF0, 0xE0, 0xF, 3, 0xFF, 0xF3, 0xE0, 0
				DB 7, 3, 0xFF, 0xFB, 0xE0, 0xC0, 7, 3, 0xFF, 0x5F, 0xE0
				DB 0xC0, 3, 1, 0xFF, 0xFF, 0xE0, 0xC0, 3, 1, 0xFF, 0xFF
				DB 0xE0, 0xC0, 1, 0, 0xFF, 0xBB, 0xE0, 0xC0, 1, 0, 0xFF
				DB 0x93, 0xE0, 0xC0, 1, 0, 0xFF, 0xFF, 0xC0, 0x80, 3
				DB 1, 0xFF, 0xFF, 0xE0, 0xC0, 3, 1, 0xFF, 0xFF, 0xE0
				DB 0xC0, 3, 1, 0xFF, 0xE1, 0xE0, 0xC0, 3, 1, 0xE1, 0x80
				DB 0xF0, 0x60, 1, 0, 0x80, 0, 0x60, 0
spr_099:        DB 3, 32
				DB 0, 0, 0, 0, 2, 0, 0x40, 0, 0, 0, 0xF, 2, 0xF0, 0x40
				DB 0, 0, 0x3F, 0xE, 0xFC, 0x70, 0, 0, 0xFF, 0x3E, 0xFF
				DB 0x7C, 1, 0, 0xFE, 0xF8, 0x7F, 0x3F, 0x81, 0, 0xF8
				DB 0xE0, 0x3F, 0xF, 0x81, 0, 0xF0, 0x60, 0xF, 6, 0xE7
				DB 0x81, 0xF8, 0x70, 0x1F, 0xE, 0xFF, 0xE7, 0xF8, 0x30
				DB 0x1F, 0xD, 0xFF, 0xFF, 0xFC, 0x98, 0x3F, 0x1D, 0xFF
				DB 0xFF, 0xFC, 0xB8, 0x3F, 0x1B, 0xFF, 0xFF, 0xFC, 0xD8
				DB 0x3F, 0x1B, 0xFF, 0xFF, 0xF8, 0xC0, 0x1F, 3, 0xFF
				DB 0, 0xE0, 0xC0, 0x1F, 0xC, 0xFF, 0x7F, 0xC0, 0, 0x1F
				DB 0xE, 0xFF, 0x7F, 0xC6, 0x80, 0x3F, 0x1D, 0xFF, 0xBF
				DB 0xCF, 0x86, 0x3F, 0x1D, 0xFF, 0xFF, 0xCF, 0x86, 0x7F
				DB 0x39, 0xFF, 0xFF, 0xEF, 0xC6, 0x7B, 0x31, 0xFF, 0xC3
				DB 0xFF, 0xEE, 0xFB, 0x71, 0xFF, 0x3C, 0xFE, 0xEC, 0xF3
				DB 0x60, 0xFF, 0xFF, 0xFE, 0x2C, 0x67, 3, 0xFF, 0xFF
				DB 0xFE, 0xDC, 0xF, 7, 0xFF, 0x81, 0xFE, 0xEC, 0x1F, 0xE
				DB 0xFF, 0x7E, 0xFC, 0x70, 0x1F, 0xD, 0xFF, 0xBD, 0xF8
				DB 0xB0, 0x1F, 0xD, 0xFF, 0xBD, 0xF8, 0xB0, 0xF, 5, 0xFF
				DB 0xBD, 0xF0, 0xA0, 7, 2, 0xFF, 0xDB, 0xE0, 0x40, 2
				DB 0, 0xFF, 0x5A, 0x40, 0, 0, 0, 0x7E, 0x24, 0, 0, 0
				DB 0, 0x3C, 0, 0, 0
spr_100:        DB 3, 33
				DB 0, 0, 7, 0, 0xF0, 0, 0x18, 0, 0xF, 7, 0xF8, 0xF0, 0x3C
				DB 0x18, 0xF, 3, 0xF8, 0xF0, 0x3E, 0x1C, 0x7F, 0, 0xFC
				DB 0x38, 0x1F, 0xE, 0xFD, 0x78, 0xFC, 0x38, 0x1F, 0xE
				DB 0xFF, 0xF1, 0xFE, 0xC, 0xF, 7, 0xFF, 0xCF, 0xFE, 0x70
				DB 0x37, 3, 0xFF, 0x3F, 0xFF, 0x7E, 0x7B, 0x30, 0x3F
				DB 0x1F, 0xFF, 0xFE, 0xFC, 0x78, 0x3F, 0x1F, 0xFE, 0xFC
				DB 0xFE, 0x5C, 0x1F, 0xF, 0xFF, 0xFA, 0x5F, 0xE, 0xBF
				DB 0x13, 0xFE, 0xF4, 0x1F, 0xD, 0xFF, 0x9C, 0xFC, 0xE8
				DB 0x1F, 0xB, 0xFF, 0xDF, 0xFE, 0x2C, 0xF, 7, 0xFF, 0xFF
				DB 0xFE, 0xCC, 0xF, 7, 0xFF, 0xFF, 0xFF, 0xE6, 7, 3, 0xFF
				DB 0xFF, 0xFF, 0xC6, 3, 1, 0xFF, 0x8F, 0xFF, 0xB6, 3
				DB 0, 0xFF, 1, 0xFF, 0xF6, 7, 3, 0xFF, 0x30, 0xFF, 0x7A
				DB 0xF, 4, 0xFF, 0x7C, 0xFE, 0x38, 0xF, 4, 0xFF, 0x2F
				DB 0xF8, 0x40, 0xF, 4, 0xFF, 3, 0xF0, 0x20, 0xF, 4, 0xFF
				DB 8, 0xF0, 0x20, 0xF, 4, 0xFF, 0x33, 0xF8, 0x10, 7, 2
				DB 0xFF, 0x37, 0xF8, 0x10, 7, 3, 0xFF, 7, 0xF8, 0x10
				DB 7, 2, 0xFF, 0x80, 0xF8, 0x10, 7, 3, 0xFF, 0x60, 0xF8
				DB 0x10, 3, 1, 0xFF, 0x9E, 0xF0, 0x60, 1, 0, 0xFF, 0xE5
				DB 0xE0, 0x80, 0, 0, 0xFF, 0x78, 0x80, 0, 0, 0, 0x78
				DB 0, 0, 0
spr_101:        DB 3, 38
				DB 0, 0, 7, 0, 0xE0, 0, 7, 0, 0xAF, 7, 0xF0, 0xE0, 0xF
				DB 6, 0xF7, 0xA3, 0xE0, 0, 0x1F, 0xF, 0xF7, 0x23, 0xC0
				DB 0x80, 0x1F, 0xB, 0xFB, 0x31, 0xF0, 0xC0, 0xF, 7, 0xF9
				DB 0x90, 0xF8, 0xF0, 0xF, 7, 0xF8, 0xD0, 0xF8, 0x70, 0x1F
				DB 0xF, 0xF9, 0xF0, 0xF0, 0xA0, 0x1F, 0xB, 0xFF, 0x69
				DB 0xF0, 0xC0, 0xF, 6, 0xFF, 0x7D, 0xF8, 0xF0, 0xF, 7
				DB 0xFF, 0xFD, 0xF8, 0xF0, 0xF, 7, 0xFF, 0xFB, 0xF0, 0xE0
				DB 0xF, 7, 0xFF, 0xF7, 0xE0, 0xC0, 0x1F, 0xF, 0xFF, 0xF7
				DB 0xC0, 0x80, 0x1F, 0xC, 0xFF, 0x6F, 0xE0, 0xC0, 0xF
				DB 3, 0xFF, 0x7F, 0xF0, 0xE0, 0x1F, 0xF, 0xFF, 0x5F, 0xF0
				DB 0xE0, 0x3F, 0x17, 0xFF, 0x5F, 0xF8, 0xF0, 0x3F, 0x1B
				DB 0xFF, 0x1F, 0xF0, 0xC0, 0x3F, 0x1A, 0x3F, 0x1E, 0xF8
				DB 0x30, 0x3E, 0x18, 0x1F, 1, 0xFC, 0xF8, 0x3C, 0x18
				DB 0x1F, 0xF, 0xFC, 0xF8, 0x3C, 0x18, 0x3F, 0x1F, 0xFE
				DB 0xFC, 0x18, 0, 0x3F, 0x1D, 0xFF, 0xFE, 3, 0, 0x7F
				DB 0x3D, 0xFF, 0xFE, 0xF, 3, 0xFF, 0x3E, 0xFE, 0xF8, 0x3F
				DB 0xF, 0xFF, 0x1E, 0xF8, 0xC0, 0x7F, 0x3F, 0xFF, 0xA6
				DB 0xF8, 0x30, 0xFF, 0x7E, 0xFF, 0xF8, 0xF8, 0x70, 0xFF
				DB 0x78, 0xFF, 0xF0, 0xF8, 0xF0, 0x78, 0, 0xFF, 1, 0xF0
				DB 0xE0, 0, 0, 0x3F, 0xD, 0xE0, 0xC0, 0, 0, 0x3F, 0x1C
				DB 0xC0, 0, 0, 0, 0x3C, 0x18, 0, 0, 0, 0, 0x7C, 0x38
				DB 0, 0, 0, 0, 0x78, 0x30, 0, 0, 0, 0, 0x78, 0x30, 0
				DB 0, 0, 0, 0x30, 0, 0, 0
spr_102:        DB 3, 35
				DB 3, 0, 0, 0, 0xC0, 0, 0xF, 3, 0x81, 0, 0xF0, 0xC0, 0x3F
				DB 0xF, 0xC1, 0x80, 0xFC, 0xF0, 0x7F, 0x3F, 0x80, 0, 0xFE
				DB 0x7C, 0xFF, 0x7C, 0, 0, 0x7F, 0x1E, 0xFC, 0x70, 0
				DB 0, 0x3F, 0xE, 0x7F, 0x3C, 0, 0, 0xFF, 0x3E, 0x3F, 0x1F
				DB 0xB3, 0, 0xFE, 0xF8, 0x1F, 0xF, 0xFF, 0x33, 0xF8, 0x20
				DB 0xF, 2, 0xFF, 0xF7, 0xF0, 0xC0, 3, 1, 0xFF, 0xF7, 0xF8
				DB 0xF0, 7, 3, 0xFF, 0xFF, 0xF8, 0xF0, 7, 3, 0xFF, 0xFF
				DB 0xF0, 0xE0, 3, 1, 0xFF, 0xFF, 0xE0, 0xC0, 1, 0, 0xFF
				DB 0xF, 0xC0, 0x80, 1, 0, 0xFF, 0xF0, 0x80, 0, 1, 0, 0xFF
				DB 0xFF, 0x80, 0, 3, 1, 0xFF, 0xFF, 0x80, 0, 3, 1, 0xFF
				DB 0xFF, 0x80, 0, 7, 1, 0xFF, 0xFF, 0x80, 0, 0xF, 7, 0xFF
				DB 0xFF, 0xC0, 0x80, 0x1F, 0xF, 0xFF, 0xC7, 0xF0, 0xC0
				DB 0x3F, 0x17, 0xFF, 0xBB, 0xF8, 0xF0, 0x7F, 0x13, 0xFF
				DB 0x3D, 0xF0, 0xE0, 0xFF, 0x58, 0xFF, 0xFE, 0xF8, 0xD0
				DB 0xFF, 0x5F, 0xFF, 0xFE, 0xFC, 0x58, 0xFF, 0x4E, 0xFF
				DB 0x7E, 0x7E, 0x3C, 0xFF, 0x60, 0xFF, 0xFE, 0x3E, 0xC
				DB 0xFF, 0x6B, 0xFF, 0xFE, 0x9E, 0xC, 0x7F, 0xF, 0xFF
				DB 0xBC, 0xDE, 0x8C, 0x3F, 0x1F, 0xFF, 0x3E, 0xDE, 0x8C
				DB 0x3F, 0x17, 0xFF, 0xEE, 0xEC, 0xC0, 0x1F, 0xC, 0xEF
				DB 6, 0xF0, 0xE0, 0xC, 0, 7, 2, 0xE0, 0, 0, 0, 2, 0, 0
				DB 0
; ---------------------------------------------------------------------------

 ; ===========================================================================
				DISPLAY "End of code ", $
				ASSERT $ < 0xD900	; Check code doesn't overflow into video buffer

 ; Segment type: Regular
				ORG 	0xD900
vidbuf:         

; This code will be overwritten by the video buffer

START:			ld		sp, 0x5B9f
				ld      hl, seed_1
				ld      bc, clear_end - clear_start            ; # bytes to clear
				ld      a, (0x5C78)                            ; FRAMES system variable (LSB)
				ex		af, af'
				call    clr_mem
				ex		af, af'
				ld      (seed_1), a
				jp      main

; Build a look-up table of values shifted left 1-7 bits
; $F200-$FFFF
build_lookup_tbls:
				ld      l, 0

loc_D6A0:
				ld      d, 0
				ld      e, l
				ld      h, high shift_bits_table + 0xD
				ld      b, 7

loc_D6A7:
				sla     e
				rl      d
				ld      a, e
				cpl
				ld      (hl), a
				dec     h
				ld      a, d
				cpl
				ld      (hl), a
				dec     h
				djnz    loc_D6A7
				inc     l
				jr      NZ, loc_D6A0

;
; Build a look-up table of bit-reversed bytes
;
				ld      hl, reverse_bits_table

loc_D6BB:                                                       ; byte offset from $F100
				ld      d, l
				ld      b, 8                                   ; 8 bits

loc_D6BE:
				srl     d
				rl      e                                       ; reverse bits
				djnz    loc_D6BE                                ; loop all bits
				ld      (hl), e                                 ; store
				inc     l                                       ; next index/location
				jr      NZ, loc_D6BB                            ; loop 256 bytes
				ret
; End of function build_lookup_tbls



				ORG		0xF100
reverse_bits_table:
				DS		0x100
shift_bits_table:
				DS		0xE00


				SAVESNA "knightlore.sna", START 
