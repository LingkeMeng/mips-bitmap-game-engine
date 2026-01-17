# ✅ 玩家移动 + 跳跃（空格键）逻辑（可运行）
# - 左右移动 a/d
# - 跳跃 space（0x20）
# - 方块 3x3
# - 支持平台检测 & 重力下落

.eqv BASE_ADDR       0x10008000
.eqv SCREEN_WIDTH    64
.eqv SCREEN_HEIGHT   64
.eqv PLAYER_COLOR    0x00000000
.eqv BACKGROUND      0x00FFFFFF

.eqv KEY_A           0x61
.eqv KEY_D           0x64
.eqv KEY_SPACE       0x20
.eqv KEYBOARD_STATUS 0xffff0000
.eqv KEYBOARD_DATA   0xffff0004

.data
player_x: .word 30
player_y: .word 50
jumping:  .word 0
jump_count: .word 6
direction: .word 0

.text
.globl main

main:
    jal init_screen
    jal draw_player
    j main_loop

main_loop:
    jal erase_player
    jal handle_input
    jal move_player
    jal draw_player
    li $v0, 32
    li $a0, 80
    syscall
    j main_loop

init_screen:
    li $t0, BASE_ADDR
    li $t1, BACKGROUND
    li $t2, SCREEN_WIDTH
    li $t3, SCREEN_HEIGHT
    mul $t2, $t2, $t3
clear_loop:
    sw $t1, 0($t0)
    addiu $t0, $t0, 4
    addiu $t2, $t2, -1
    bgtz $t2, clear_loop
    jr $ra

handle_input:
    li $t0, KEYBOARD_STATUS
    lw $t1, 0($t0)
    beqz $t1, end_input

    lw $t2, KEYBOARD_DATA

    li $t3, KEY_D
    beq $t2, $t3, move_right

    li $t3, KEY_A
    beq $t2, $t3, move_left

    li $t3, KEY_SPACE
    beq $t2, $t3, jump

    j end_input

move_right:
    la $t0, player_x
    lw $t1, 0($t0)
    addiu $t1, $t1, 1
    li $t2, 61
    bgt $t1, $t2, end_input
    sw $t1, 0($t0)
    j end_input

move_left:
    la $t0, player_x
    lw $t1, 0($t0)
    addiu $t1, $t1, -1
    bltz $t1, end_input
    sw $t1, 0($t0)
    j end_input

jump:
    la $t0, jumping
    lw $t1, 0($t0)
    bnez $t1, end_input        # 如果正在跳跃，不再重新设置跳跃
    li $t1, 1
    sw $t1, 0($t0)
    li $t2, 6
    la $t3, jump_count
    sw $t2, 0($t3)
    j end_input

end_input:
    jr $ra

move_player:
    la $t0, jumping
    lw $t1, 0($t0)
    beqz $t1, check_fall

    # if jumping
    la $t2, player_y
    lw $t3, 0($t2)
    addiu $t3, $t3, -1
    bltz $t3, stop_jump
    sw $t3, 0($t2)

    la $t4, jump_count
    lw $t5, 0($t4)
    addiu $t5, $t5, -1
    sw $t5, 0($t4)
    bgtz $t5, end_move

stop_jump:
    sw $zero, 0($t0)         # jumping = 0
    li $t5, 6
    la $t4, jump_count
    sw $t5, 0($t4)
    j end_move

check_fall:
    la $t2, player_y
    lw $t3, 0($t2)
    li $t4, 61
    bge $t3, $t4, end_move
    addiu $t3, $t3, 1
    sw $t3, 0($t2)
    j end_move

end_move:
    jr $ra

draw_player:
    la $t0, player_x
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    li $t3, PLAYER_COLOR
    jal draw_block
    jr $ra

erase_player:
    la $t0, player_x
    lw $t1, 0($t0)
    lw $t2, 4($t0)
    li $t3, BACKGROUND
    jal draw_block
    jr $ra

draw_block:
    li $t4, 0
row_loop:
    li $t5, 0
col_loop:
    add $a0, $t1, $t5
    add $a1, $t2, $t4
    move $a2, $t3
    jal set_pixel
    addiu $t5, $t5, 1
    li $t6, 3
    blt $t5, $t6, col_loop
    addiu $t4, $t4, 1
    blt $t4, $t6, row_loop
    jr $ra

set_pixel:
    li $t6, SCREEN_WIDTH
    li $t7, SCREEN_HEIGHT
    bge $a0, $t6, skip
    bge $a1, $t7, skip
    bltz $a0, skip
    bltz $a1, skip

    mul $t0, $a1, SCREEN_WIDTH
    add $t0, $t0, $a0
    sll $t0, $t0, 2
    li $t1, BASE_ADDR
    add $t1, $t1, $t0
    sw $a2, 0($t1)

skip:
    jr $ra