; set up addresses to hold test results

test_address_start = $E800
zero_page_compare_value                 =   test_address_start
alternating_counter                     =   test_address_start + 1
pass_count                              =   test_address_start + 2
flag_position_count                     =   test_address_start + 3
expected_value                          =   test_address_start + 4
temp_value                              =   test_address_start + 4

read_value                              =   test_address_start + 5

page_counter                            =   test_address_start + 6
byte_counter                            =   test_address_start + 7
fault_indicator_address                 =   test_address_start + 8
done_indicator_address                  =   test_address_start + 9
test_address_end                        =   test_address_start + 9

test_address_count                      =   test_address_end - test_address_start + 1

read_address_low_byte                   =   $FB
read_address_high_byte                  =   $FC

ram_space_start                         =   $01
ram_space_end                           =   $80

rom_space_start                         =   $90
rom_space_end                           =   $FF

ram_test_mismatch_marker                =   $BB
ram_test_complete_marker                =   $CC
done_marker                             =   $DD

.segment    "CODE"

; check from 0x0000 to 0x8000
; standard RAM

start:
    
    ldy     #$00    ; load zero page address
    sty     page_counter
    lda     #$FF    ; load flag value
    sta     zero_page_compare_value

init_flag_position:
    ; initialize flag position
    ; iterate through 3 offsets
    ldx     #$03
    stx     flag_position_count

begintestiteration:
    ldx     #$01
    stx     pass_count
    stx     alternating_counter

; write one page of memory
zeropagewrite:
    dex
    bne     zpcontinue  ; if not the right position, skip

    ; check what page we are on
    ; to determine addressing method
    ldx     page_counter
    bne     pagewriteflag

zpwriteflag:
    sta     $0000,Y
    jmp     writeflagend

pagewriteflag:
    sta     (read_address_low_byte),Y

writeflagend:
    ldx     alternating_counter

zpcontinue:
    iny
    bne     zeropagewrite

    ldx     pass_count
    beq     zeropagecomparestart
    dex
    stx     pass_count

    ; set up the flag position
    ldx     #$03
    stx     alternating_counter
    ldx     flag_position_count
    eor     #$FF
    jmp     zeropagewrite

zeropagecomparestart:
    lda     zero_page_compare_value     ; load the current value for comparison
    ldx     flag_position_count

zeropagecompare:
    ; compare each value
    dex                                 ; decrement alternating
    bne     no_flip
    eor     #$FF                        ;flip the flag
    
no_flip:
    sta     temp_value
    lda     page_counter
    beq     zpcompare

compare:
    lda     temp_value
    cmp     (read_address_low_byte),Y
    bne     fault
    jmp     donecompare

zpcompare:
    lda     temp_value
    cmp     $0000,Y
    bne     fault

donecompare:
    cpx     #$00
    bne     no_flip_2
    eor     #$FF
    ldx     alternating_counter

no_flip_2:
    jmp     nextzeropagecompare

nextzeropagecompare:
    iny
    bne     zeropagecompare

shiftflagposition:
    ldx     flag_position_count ; load current flag position
    dex
    beq     invert_flag
    stx     flag_position_count
    jmp     begintestiteration

invert_flag:
    lda     zero_page_compare_value
    beq     done ; if flag value is 0, we are done
    eor     #$FF
    sta     zero_page_compare_value
    jmp     init_flag_position

done:
    lda     #done_marker
    sta     done_indicator_address

doneloop:
    nop
    jmp     doneloop    ; wait here

fault:
    sta     expected_value
    lda     $0000,Y
    sta     read_value
    lda     #ram_test_mismatch_marker
    sta     fault_indicator_address
    sty     byte_counter
    jmp     done
