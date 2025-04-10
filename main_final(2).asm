##################################################################### #
# CSCB58 Winter 2025 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Jeong Yuseon, 1010280189, jeongyu6, official email # yuseon.jeong@mail.utoronto.ca
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 256 (update this as needed) 
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4 (choose the one the applies) #
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features) 
# 1. Moving objects : an enemy moving around
# 2. Moving platforms: platform that is moving in one of them
# 3. Double jump: player can jump twice in midair
#
# Link to video demonstration for final submission:
# - https://youtu.be/FnSj8IIOolY
# Are you OK with us sharing the video with people outside course staff?
# - yes https://github.com/jeongyu6/Assembly-Project.git, and please share this project github link as well! #
# Any additional information that the TA needs to know:
# - It seemed too hard for the player to win the game with the moving enemy. 
# So, what I did was that I only caused it to create a collision when it touches the enemies
# right and left corner. So, it can jump on top of its head and it will be okay and there will be
# no collision. This will be okay as long as it does not overlap with the obstacle in some way
# #####################################################################

# Bitmap Display Configuration
.eqv BASE_ADDRESS 0x10008000
.eqv WIDTH 128 #(512 / 4 pixels)
.eqv HEIGHT 64 #(256 / 4 pixels)

#Note: Used this website to help me fit which color I want : https://www.colorhexa.com/
#Background
.eqv SKY_COLOR 0x001A75FF 
.eqv LIGHT_GREEN 0x0000FF00
.eqv DARK_GREEN 0x00008000

#Obstacles
.eqv OBSTACLE_COLOR 0x00101090  

#enemy
.eqv ENEMY_COLOR 0x00FFAA00


#Bird(My character is called a bird)
.eqv COLOR_BLACK  0x00000000
.eqv COLOR_LGREEN 0x0000FF00  
.eqv COLOR_CYAN   0x0080FFFF  

#Spikeball
.eqv COLOR_SPIKE_CENTER 0x0080C0FF   # bright cyan-blue
.eqv COLOR_SPIKE_EDGE   0x001020A0   # deep blue 

#Snowflake as pickup
.eqv COLOR_SNOWFLAKE 0x00C0F8FF   # Light icy blue

.eqv BOX_SIZE 5
.eqv ENEMY_SIZE 3

#Gravity
.eqv JUMP_HEIGHT 5
.eqv MAX_JUMP_HEIGHT 45
.eqv MAX_JUMP_HEIGHT_2 35
.eqv GRAVITY 1
.eqv JUMPING 1
.eqv FALLING 0

.eqv JUMP_DY -5

.eqv KEY_READY 0xffff0000
.eqv KEY_VALUE 0xffff0004

.eqv ASCII_W 119
.eqv ASCII_S 115
.eqv ASCII_A 97
.eqv ASCII_D 100
.eqv ASCII_R 'r'
.eqv ASCII_Q 'q'

# floor is 4 pixels (60-63), so 
.eqv FLOOR_LIMIT 55

#####Changes made here
.eqv TYPE_BOX      0
.eqv TYPE_TRIANGLE 1
.eqv TYPE_STICK    2
.eqv TYPE_SPIKEBALL 3
.eqv TYPE_PICKUP  4
.eqv TYPE_DOOR 5
.eqv TYPE_ENEMY 6
.eqv TYPE_MOVING_BOX 7

# Heart
.eqv COLOR_HEART 0x00FF2244  # Red heart color
.eqv COLOR_NONE  0x00000000  # Transparent / background

.eqv HEART_WIDTH 5
.eqv HEART_HEIGHT 5


#####Changes made here
.eqv NUM_BOXES  11   #total number of platforms/boxes
.eqv NUM_MOVING_BOXES 1
.eqv NUM_PICKUPS 4
.eqv NUM_SPIKES 1
.eqv NUM_DOORS 1
.data

# For 1 moving platform
moving_plat_dir: .word 1  # 1 = right, -1 = left


collision_handled: .word 0

#####Changes made here
# objects (platforms and triangles)
# They are all in the format of (x, y, width, height, type)
objects: .word 
#1st row (from left to right)
60, 55, 10, 1, TYPE_BOX

#1st step
10, 48, 10, 1, TYPE_BOX
#1st step
20, 43 , 10, 1, TYPE_BOX
#2nd step
30, 38, 10, 1, TYPE_BOX
#3rd step
40, 35, 40, 1, TYPE_BOX 

#left one right below the first snowflake on the left
10, 30, 20, 1, TYPE_BOX

#the platform below the moving enemy
100, 30, 25, 1, TYPE_BOX

#the platform below the spikeball
90, 55, 25, 1, TYPE_BOX 

#the one on top of the moving platform
85, 20, 15, 1, TYPE_BOX

105, 30, 4, 1, TYPE_BOX

#this is the moving platform
70, 28, 10, 1, TYPE_MOVING_BOX


75, 30, 5, 5, TYPE_PICKUP  
105, 50, 5, 5, TYPE_PICKUP
15, 25, 5, 5, TYPE_PICKUP
35, 55, 5, 5, TYPE_PICKUP

98, 45, 3, 3, TYPE_SPIKEBALL   
127, 22, 1, 8, TYPE_DOOR

b_posx: .word 0
b_posy: .word 55
b_posx_old: .word 0
b_posy_old: .word 0
b_dy:   .word 0
on_plat: .word 0  # 0 false, 1 true
on_plat_old: .word 0
health: .word 1

# keep these 4 in exactly this sequence, treating it the same as an object
enemy:
enemy_x:      .word 105      # starting x position
enemy_y:      .word 25      # fixed y position
enemy_w:      .word 3
enemy_h:      .word 3
enemy_type:   .word TYPE_ENEMY

enemy_dir:    .word 1       # direction: 1 = right, -1 = left
enemy_speed:  .word 1       # speed (pixels per frame)


# Jump flag (0 = not jumping, 1 = 1st jump, 2 = falling, 3 = double jump)
jump_flag: .word 0


    
newline: .asciiz "\n"
#game_over_msg: .asciiz "Game Over: Collision detected!\n"



.text
.globl main

main:
	# TODO any reset values here

	li    $t0, 1
	sw    $t0, health

	# reset pickups
	la    $t0, objects
	li    $t1, NUM_BOXES
	mul   $t1, $t1, 20
	add   $t0, $t0, $t1
	li    $t2, 5    # width not actually used just non-0 for draw it or not

	li    $t3, 0
	li    $t4, NUM_PICKUPS
reset_pickups:
	sw    $t2, 8($t0)

	addi  $t0, $t0, 20
	addi  $t3, $t3, 1  # i++
	blt   $t3, $t4, reset_pickups  # while (i < NUM_PICKUPS)

lost_heart:
	sw    $0, b_posx
	li    $t0, 55
	sw    $t0, b_posy
	sw    $0, on_plat
	sw    $0, jump_flag

	jal    draw_background

#-------Game Loop--------#
game_loop:
	# Sleep 
	li     $v0, 32
	li     $a0, 30    # 30 ms = ~30 FPS
	syscall
	
	jal    draw_health

#================ LEVEL 1: Draw and Check Obstacles =================#

	#lw     $t0, on_plat
	#sw     $t0, on_plat_old   # save old state
	sw     $0, on_plat  # reset to false for each loop

	la     $s0, objects  # plat_ptr
	li     $s1, 0   # i = 0
	li     $s2, NUM_BOXES
	addi   $s3, $s2, -1   # moving platform is last of the boxes index num-1
	
	
box_loop:
	bne    $s1, $s3, normal_box      # if (i != moving index) skip update_moving
	move   $a0, $s0
	jal    update_moving_platform

normal_box:
	lw     $a0, 0($s0)
	sll    $a0, $a0, 16
	lw     $a1, 4($s0)
	or     $a0, $a0, $a1   # x in high 16, y in low 16 bits
	lw     $a1, 8($s0)     # width
	lw     $a2, 12($s0)    # height
	li     $a3, OBSTACLE_COLOR
	jal    draw_box

	lw     $s4, on_plat

	move   $a0, $s0
	jal    check_collision

	lw     $s5, on_plat

	bne    $s1, $s3, dont_move      # if (i != moving index) don't move bird
	beq    $s4, $s5, dont_move      # is not on moving platform

move_bird:
	# move the same direction as the moving platform to stay on it
	# or in front of it
	lw     $t1, b_posx
	lw     $t2, moving_plat_dir
	add    $t1, $t1, $t2
	sw     $t1, b_posx
	j      update_box_loop

dont_move:
	beq    $v0, $0, update_box_loop  # no collision
	


set_old_pos:
	lw     $t0, b_posx_old
	lw     $t1, b_posy_old
	sw     $t0, b_posx
	sw     $t1, b_posy

update_box_loop:
	####Change in here
	add    $s0, $s0, 20 # ptr++
	addi   $s1, $s1, 1  # i++
	blt    $s1, $s2, box_loop # while (i < NUM_PLATS)

	li     $s1, 0       # i = 0
	li     $s2, NUM_PICKUPS
pickup_loop:
	lw     $a0, 0($s0)
	lw     $a1, 4($s0)
	lw     $a2, 8($s0)
	beqz   $a2, pl_update   # if (!width) continue (we already picked it up)
	lw     $a3, 12($s0)
	jal    draw_pickup

	move   $a0, $s0
	jal    check_collision
	beqz   $v0, pl_update

	# erase the pickup
	lw     $a0, 0($s0)
	sll    $a0, $a0, 16
	lw     $a1, 4($s0)
	or     $a0, $a0, $a1   # x in high 16, y in low 16 bits
	lw     $a1, 8($s0)     # width
	lw     $a2, 12($s0)    # height
	li     $a3, SKY_COLOR
	jal    draw_box

	sw     $0, 8($s0)   # 0/false in 3rd member ("width") in flag for drawing
	lw     $t0, health
	addi   $t0, $t0, 1
	sw     $t0, health  # health++

pl_update:
	add    $s0, $s0, 20 # ptr++
	addi   $s1, $s1, 1  # i++
	blt    $s1, $s2, pickup_loop # while (i < NUM_PICKUPS)

	# appropriately named spikeball
	lw     $a0, 0($s0)
	lw     $a1, 4($s0)
	lw     $a2, 8($s0)
	lw     $a3, 12($s0)
	jal    draw_spikeball

	move   $a0, $s0
	jal    check_collision
	beqz   $v0, do_door

do_door:
	add    $s0, $s0, 20 # ptr++
	lw     $a0, 0($s0)
	lw     $a1, 4($s0)
	lw     $a2, 8($s0)
	lw     $a3, 12($s0)
	jal    draw_door
	move   $a0, $s0
	jal    check_collision
	beqz   $v0, not_over

	j      you_win

not_over:
	jal     update_enemy

	lw     $a0, enemy_x
	sll    $a0, $a0, 16
	lw     $a1, enemy_y
	or     $a0, $a0, $a1   # x in high 16, y in low 16 bits
	li     $a1, 3     # width
	li     $a2, 3     # height
	li     $a3, ENEMY_COLOR
	jal    draw_box

	# Do bird stuff
	lw     $t0, b_posx
	lw     $t1, b_posy
	lw     $t2, b_posx_old
	lw     $t3, b_posy_old

	bne    $t0, $t2, do_bird_movement
	bne    $t1, $t3, do_bird_movement

	j      check_enemy
do_bird_movement:
	# erase old bird pos
	move   $a0, $t2
	sll    $a0, $a0, 16
	or     $a0, $a0, $t3   # x in high 16, y in low 16 bits
	li     $a1, BOX_SIZE     # width
	li     $a2, BOX_SIZE    # height
	li     $a3, SKY_COLOR
	jal    draw_box

	jal     draw_bird

	# set old to new for next frame
	lw     $t0, b_posx
	lw     $t1, b_posy
	sw     $t0, b_posx_old
	sw     $t1, b_posy_old

check_enemy:
	#---Check collision with moving enemy---#
	la      $a0, enemy       # enemy "object"
	jal     check_collision
	beqz    $v0, get_input

	lw      $t0, health
	addi    $t0, $t0, -1
	sw      $t0, health
	bltz    $t0, you_lose

	j       lost_heart

get_input:
	jal     get_key

	
	# v0 is 0 if no key hit, so no problem here
	beq     $v0, ASCII_W, jump
	#beq     $v0, ASCII_S, move_down
	beq     $v0, ASCII_A, move_left
	beq     $v0, ASCII_D, move_right
	beq     $v0, ASCII_R, main     # restart the game
	beq     $v0, ASCII_Q, game_over

do_gravity:
	lw      $t0, on_plat
	bnez    $t0, skip_gravity

	lw      $t0, b_posy
	lw      $t1, b_dy
	addi    $t1, $t1, GRAVITY

	li      $t2, 1
	blt     $t1, $t2, no_clamp_dy   # if (dy < 1) no clamp if >= 1 dy = 1
	move    $t1, $t2   #  dy = 1  (terminal velocity is 1 (y increases down))
no_clamp_dy:
	sw      $t1, b_dy
	add     $t0, $t0, $t1  # y += dy
	sw      $t0, b_posy
#Debugging: When the bird goes off screen
	bltz    $t0, clamp_ceiling
	j       skip_clamp_ceiling

clamp_ceiling:
	li   $t0, 0
	sw   $t0, b_posy
	sw   $0, b_dy       # cancel upward velocity


skip_clamp_ceiling:
skip_gravity:
	# Check for ground collision (stop the bird at y = 54 (59-box_size)
	li      $t1, FLOOR_LIMIT      # Ground level (y = 54)
	blt     $t0, $t1, continue_game_loop  # if y < flool_limit continue

	sw      $0, jump_flag
	sw      $t1, b_posy  # Clamp the bird's position to standing on ground
	sw      $0, b_dy

continue_game_loop:
	j       game_loop

you_win:
    la    $a2, msg_you_win   # pointer to sprite array
    li    $a3, 17            # number of characters
    li    $a0, 10            # x position
    li    $a1, 20            # y position
    jal   draw_message
	j     quit

you_lose:
    la    $a2, msg_you_lose   # pointer to sprite array
    li    $a3, 18             # number of characters
    li    $a0, 10             # x position
    li    $a1, 20             # y position
    jal   draw_message
    j     quit

game_over:
    la    $a2, msg_game_over   # pointer to sprite array
    li    $a3, 9               # number of characters
    li    $a0, 36              # x position
    li    $a1, 20              # y position
    jal   draw_message

quit:
    li $v0, 10   # exit
    syscall


#------------Jump logic-------#
#State of the bird
# 0 = idle
# 1 = jumping
# 2 = jump in midair
#NOTE: ONLY one jump in midair
jump:
	li     $t1, 2
	lw     $t0, jump_flag
	blt    $t0, $t1, do_jump
	j      do_gravity

do_jump:
	lw     $t1, b_dy
	addi   $t1, $t1, JUMP_DY
	sw     $t1, b_dy
	addi   $t0, $t0, 1
	sw     $t0, jump_flag  # Add 1 to jump_flag
	lw     $t2, on_plat
	sw     $t2, on_plat_old   # save old state
	sw     $0, on_plat
	j      do_gravity

# --- Movement Controls --- #
# Note: the movement will not be allowed to go below the grass which is around at the point 59/60
# All logic here is good
move_down:
	addi $t0, $s1, BOX_SIZE 
	bge $t0, $s4, game_loop    #limit it when it goes below the grass
	addi $s1, $s1, 1   #allow it to go down if it is not below the grass
	j do_gravity

move_left:
	lw     $t0, b_posx
	blez   $t0, do_gravity   # if (pos_x <= 0) don't move left
	addi   $t0, $t0, -1      # movement to the left <-
	sw     $t0, b_posx
	j      do_gravity

move_right:
	lw     $t0, b_posx
	addi   $t1, $t0, BOX_SIZE  
	bge    $t1, WIDTH, do_gravity  # don't go past the right edge
	addi   $t0, $t0, 1  #movement to the right ->
	sw     $t0, b_posx
	j      do_gravity



	#--- Get Key ---#
get_key:
	li     $t1, KEY_READY
	li     $v0, 0    # default return 0
wait_key:
	lw     $t2, 0($t1)
	andi   $t2, $t2, 1
	beqz   $t2, exit_get_key  # if no key, just exit return 0
	li     $t1, KEY_VALUE
	lw     $v0, 0($t1)
exit_get_key:
	jr     $ra

#--------- DRAW THE BACKGROUND ---------#
# This is basically drawing it using inner for-loops to draw the entire thing 
# into background color that consists of grass and sky where grass is used alternatively
# with different colors of light and dark green
draw_background:
	li $t0, BASE_ADDRESS  # Load base address of display
    li $t4, 0              # y = 0

draw_rows:
    li $t5, 0              # x = 0

draw_cols:
    mul $t6, $t4, WIDTH    # t6 = y * WIDTH
    add $t6, $t6, $t5      # t6 = y * WIDTH + x
    sll $t6, $t6, 2        # t6 = (y * WIDTH + x) * 4
    add $t6, $t6, $t0      # t6 = address stated

    # Determine if we're in sky or grass region
    li $t7, HEIGHT
    addi $t7, $t7, -4      # t7 = HEIGHT - 4 (start of grass)

    blt $t4, $t7, draw_sky_pixel

    # --- Grass (checkerboard effect) --- #
    # The light or dark grass is determined by whether it is even or odd
    xor $t8, $t4, $t5
    andi $t8, $t8, 1
    beqz $t8, grass_light

#use dark green color
    li $t9, DARK_GREEN
    sw $t9, 0($t6)
    j next_pixel

#use light green color
grass_light:
    li $t9, LIGHT_GREEN
    sw $t9, 0($t6)
    j next_pixel

#use sky color
draw_sky_pixel:
    li $t9, SKY_COLOR
    sw $t9, 0($t6)

#update the width and the height of the pixel accordingly so it goes under the loops
next_pixel:
    addi $t5, $t5, 1
    blt $t5, WIDTH, draw_cols

    addi $t4, $t4, 1
    blt $t4, HEIGHT, draw_rows

    jr $ra


#------------- DRAW THE BIRD/ character (started out as a bird, ending up being a random square ---------------#
draw_bird:
    li $t0, 0  # dy loop
draw_bird_rows:
    bge $t0, BOX_SIZE, end_draw_bird
    li $t1, 0  # dx loop
draw_bird_cols:
    bge $t1, BOX_SIZE, next_bird_row

	lw     $a0, b_posx
	lw     $a1, b_posy
    add $t2, $a0, $t1      # x = birdX + dx
    add $t3, $a1, $t0      # y = birdY + dy
    mul $t4, $t3, WIDTH
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    addi $t4, $t4, BASE_ADDRESS      # screen address

    li $t5, COLOR_BLACK    # default to black (outer border)

    # Check if inside inner square: dx/dy in 
    li $t6, 1
    li $t7, 3

    blt $t1, $t6, store_bird_pixel
    bgt $t1, $t7, store_bird_pixel
    blt $t0, $t6, store_bird_pixel
    bgt $t0, $t7, store_bird_pixel

    # Inside inner 3x3, then make it green
    li $t5, COLOR_LGREEN

    # Check if center
    li $t8, 2
    bne $t0, $t8, store_bird_pixel
    bne $t1, $t8, store_bird_pixel

    # If center: make it cyan
    li $t5, COLOR_CYAN

store_bird_pixel:
    sw $t5, 0($t4)
    addi $t1, $t1, 1
    j draw_bird_cols

next_bird_row:
    addi $t0, $t0, 1
    j draw_bird_rows

end_draw_bird:
    jr $ra

#===========DRAWING OBSTACLES===========#
#Personal Notes: Ideas are triangle, stairs, simple stick platforms and more
#it is basically an inner for loop: I used C type of comments as I am most comfortable with it
#labeled all the inputs that will be used to run these loops as Arguments


#--------triangle obstacle------#
# Draws a triangle spiky obstacle for the bird
# Arguments:
# $a0 = x_start 
# $a1 = y_start 
# $a2 = width (base width, MUST BE ODD)
# $a3 = height
#--------------------------------#
# To improve this function
draw_pointy_triangle_obstacle:
    li $t0, 0              # dy = 0 (row index) to go from top to bottom row

triangle_row_loop:
    bge $t0, $a3, end_triangle  # while(dy < height) of the triangle

    sll $t1, $t0, 1           # $t1 =  2 * dy (number of pixels per row)
    addi $t1, $t1, 1           # $t1 = 2 * dy + 1
    
    # Clamp row_width if it exceeds total base width 
    bgt $t1, $a2, clamp_row_width
    j skip_clamp

clamp_row_width:
    move $t1, $a2      # $t1 = base_width (cap it)

skip_clamp:
    #Center the row horizontally in the bounding width $a2
    sub $t3, $a2, $t1         # $t3 represents the leftover space
    sra $t3, $t3, 1       # $t3 is the center offset
    add $t3, $a0, $t3         #$t3 represents the starting position of the x

#We now move on to coloring the rows
    li $t4, 0             # dx = 0
triangle_col_loop:
    bge $t4, $t1, next_triangle_row # while(dx <= width)

    add $t5, $t3, $t4         # x = start_x + dx
    add $t6, $a1, $t0         # y = start_y + dy

    # coloring each pixel in its respective address
    mul $t7, $t6, WIDTH
    add $t7, $t7, $t5
    sll $t7, $t7, 2
    add $t7, $t7, BASE_ADDRESS

    li $t8, OBSTACLE_COLOR
    sw $t8, 0($t7)


    addi $t4, $t4, 1     #dx++
    j triangle_col_loop

next_triangle_row:
    addi $t0, $t0, 1
    j triangle_row_loop

end_triangle:
    jr $ra

#--------box obstacle---------#
# TODO rename, add color parameter, merge x/y and w/h into single registers
# Draws a box obstacle for the bird
# Arguments:
# $a0 = x and y position
# $a1 = width
# $a2 = height
# $a3 = color
#------------------------------#
# TODO imrove this function
draw_box:
	li $t0, 0          # $t0 = 0 for dy

	# extract position
	andi    $t5, $a0, 0xFFFF   # y
	srl     $a0, $a0, 16       # x

box_row_loop:
	bge $t0, $a2, end_draw_box   #for($t0 = 0 ; $t0 < $a2; $t0 ++){

	li $t1, 0          # $t1 = 0 for dx

box_col_loop:
	bge $t1, $a1, next_box_row  #for($t1 = 0; $t1 < $a1 ; $t1 ++){

	add $t2, $a0, $t1      # $t2 = x position + $t1
	add $t3, $t5, $t0      # $t3 = y position + $t0

	#this is for the coloring portion formula
	mul $t4, $t3, WIDTH    
	add $t4, $t4, $t2
	sll $t4, $t4, 2
	addi $t4, $t4, BASE_ADDRESS

	#color it with color arg
	sw $a3, 0($t4)


	addi $t1, $t1, 1  #move to the next x value
	j box_col_loop

next_box_row:
	addi $t0, $t0, 1  #move to the next y value
	j box_row_loop

end_draw_box:
	jr $ra

#-----Stick platform----#
# Arguments:
# $a0 = x position
# $a1 = y position
# $a2 = width 
#------------------------#
draw_stick_platform:
    li $t0, 0          # $t0 = 0 for dy 
    
    li $t1, 0          # $t1 = 0 for dx 

draw_stick_col_loop:
    bge $t1, $a2, end_draw_stick_platform  # for($t1 = 0; $t1 < width ; $t1 ++){

    # $t2 = x_start + $t1
    add $t2, $a0, $t1

    # get the  y_position which stays constant throughout
    move $t3, $a1


#this is for the coloring the pixel formula
    mul $t4, $t3, WIDTH
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t4, $t4, BASE_ADDRESS

 # Set the color for the platform 
    li $t5, OBSTACLE_COLOR  # Based on the obstacle color
    sw $t5, 0($t4)

    addi $t1, $t1, 1  # $t1++
    j draw_stick_col_loop

end_draw_stick_platform:
    jr $ra             # Return from function
    
#------------Moving Platform--------------#
# Updates a horizontal moving platform's x position
# Arguments:
# $a0 = pointer to platform entry in objects
#-----------------------------------------#

update_moving_platform:
	addi   $sp, $sp, -8
	sw     $ra, 0($sp)
	sw     $s0, 4($sp)

	move   $s0, $a0

	# erase old position
	lw     $a0, 0($s0)
	sll    $a0, $a0, 16
	lw     $a1, 4($s0)
	or     $a0, $a0, $a1   # x in high 16, y in low 16 bits
	lw     $a1, 8($s0)     # width
	lw     $a2, 12($s0)    # height
	li     $a3, SKY_COLOR
	jal    draw_box

	move   $a0, $s0
	lw     $t0, 0($a0)     # x
	lw     $t2, 8($a0)     # width

	la     $t3, moving_plat_dir
	lw     $t4, 0($t3)     # direction (1 or -1)

	# Clamp movement between 65 and 100
	li     $t5, 65
	ble    $t0, $t5, reverse_moving_dir
	add    $t6, $t0, $t2
	li     $t7, 90
	bge    $t6, $t7, reverse_moving_dir

	j      update_plat_pos

reverse_moving_dir:
	neg    $t4, $t4
	sw     $t4, 0($t3)

update_plat_pos:
	add    $t1, $t0, $t4   # new x = x + dir

	sw     $t1, 0($a0)     # update x

exit_ump:
	lw     $ra, 0($sp)
	lw     $s0, 4($sp)
	addi   $sp, $sp, 8
	jr  $ra

#--------Spike Ball--------#
# Draws a spike ball that looks like a cute snowflake
# Arguments:
# $a0 = x
# $a1 = y
# $a2 = width (should be 3)
# $a3 = height (should be 3)
#--------------------------#
draw_spikeball:
    li $t0, 0  # dy = 0

spikeball_row_loop:
    bge $t0, 3, end_spikeball
    li $t1, 0  # dx = 0

spikeball_col_loop:
    bge $t1, 3, next_spikeball_row

    add $t2, $a0, $t1      # x = spikeX + dx
    add $t3, $a1, $t0      # y = spikeY + dy

    mul $t4, $t3, WIDTH
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    addi $t4, $t4, BASE_ADDRESS

    li $t5, COLOR_SPIKE_EDGE

    # Center pixel
    li $t6, 1
    beq $t0, $t6, check_center_col
    j store_spike_pixel

check_center_col:
    beq $t1, $t6, set_spike_center
    j store_spike_pixel

set_spike_center:
    li $t5, COLOR_SPIKE_CENTER

store_spike_pixel:
    sw $t5, 0($t4)
    addi $t1, $t1, 1
    j spikeball_col_loop

next_spikeball_row:
    addi $t0, $t0, 1
    j spikeball_row_loop

end_spikeball:
    jr $ra

#---- Draw enemy (simple square) ----#
draw_enemy:
    lw $t0, enemy_x
    lw $t1, enemy_y

    li $t2, 0  # dy
enemy_draw_yloop:
    bge $t2, 3, end_draw_enemy
    li $t3, 0  # dx
enemy_draw_xloop:
    bge $t3, 3, next_enemy_y

    add $t4, $t0, $t3
    add $t5, $t1, $t2

    mul $t6, $t5, WIDTH
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    addi $t6, $t6, BASE_ADDRESS

    li $t7, 0x00FFAA00  # bright green enemy
    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j enemy_draw_xloop
next_enemy_y:
    addi $t2, $t2, 1
    j enemy_draw_yloop
end_draw_enemy:
    jr $ra

#------Moving enemy-----#
# Moves the enemy left and right between two bounds
update_enemy:
	addi   $sp, $sp, -4
	sw     $ra, 0($sp)

	# erase old enemy position
	lw     $a0, enemy_x
	sll    $a0, $a0, 16
	lw     $a1, enemy_y
	or     $a0, $a0, $a1   # x in high 16, y in low 16 bits
	li     $a1, 3     # width
	li     $a2, 3     # height
	li     $a3, SKY_COLOR
	jal    draw_box

	la   $t0, enemy_x
	lw   $t1, 0($t0)        # current x
	la   $t2, enemy_dir
	lw   $t3, 0($t2)        # current dir
	la   $t4, enemy_speed
	lw   $t5, 0($t4)        # speed

	mul  $t6, $t3, $t5      # delta = dir * speed
	add  $t1, $t1, $t6      # new_x = x + delta

	# Clamp between 90 and 110 in terms of the x direction
	slti     $t8, $t1, 100     # t8 = t1 < 100
	li       $t7, 110
	slt      $t9, $t7, $t1     # t9 = 120 < t1
	or       $t8, $t8, $t9

	beqz     $t8, no_reverse
	neg      $t3, $t3          # reverse direction
	sw       $t3, 0($t2)

no_reverse:
	sw   $t1, 0($t0)        # store updated x

exit_ue:
	lw     $ra, 0($sp)
	addi   $sp, $sp, 4
    jr   $ra
  
#---------PICKUPS---------#
# Draws a 5x5 snowflake pickup
# Arguments
# $a0 = x
# $a1 = y
#-------------------------#
draw_pickup:
    li $t0, 0  # dy

pickup_row_loop:
    bge $t0, BOX_SIZE, end_draw_pickup
    li $t1, 0  # dx

pickup_col_loop:
    bge $t1, BOX_SIZE, next_pickup_row

    # Compute conditionally lit pixels
    # Use $t5 as flag (1 = draw, 0 = skip)
    li $t5, 0
    # Row 0 and 4: if (dx % 2 == 0)
    li $t6, 0
    beq $t0, $t6, check_even_col
    li $t6, 4
    beq $t0, $t6, check_even_col

    # Row 1 and 3: if dx = 1,2,3
    li $t6, 1
    beq $t0, $t6, check_mid_three
    li $t6, 3
    beq $t0, $t6, check_mid_three

    # Row 2: always draw
    li $t6, 2
    beq $t0, $t6, set_draw_pixel
    j skip_pixel_logic

check_even_col:
    andi $t6, $t1, 1
    beqz $t6, set_draw_pixel
    j skip_pixel_logic

check_mid_three:
    li $t6, 1
    beq $t1, $t6, set_draw_pixel
    li $t6, 2
    beq $t1, $t6, set_draw_pixel
    li $t6, 3
    beq $t1, $t6, set_draw_pixel
    j skip_pixel_logic

set_draw_pixel:
    li $t5, 1

skip_pixel_logic:
    beqz $t5, skip_draw_pickup_pixel

    # Compute pixel address
    add $t2, $a0, $t1   # x
    add $t3, $a1, $t0   # y
    mul $t4, $t3, WIDTH
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    addi $t4, $t4, BASE_ADDRESS

    li $t6, COLOR_SNOWFLAKE
    sw $t6, 0($t4)

skip_draw_pickup_pixel:
    addi $t1, $t1, 1
    j pickup_col_loop

next_pickup_row:
    addi $t0, $t0, 1
    j pickup_row_loop

end_draw_pickup:
    jr $ra


# Simple vertical stick door
draw_door:
    li $t0, 0        # dy
draw_door_loop:
    bge $t0, $a3, end_draw_door  # for dy in height
    li $t1, 0        # dx always 0 since width is 1

    add $t2, $a0, $t1     # x
    add $t3, $a1, $t0     # y

    mul $t4, $t3, WIDTH
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    addi $t4, $t4, BASE_ADDRESS

    li $t5, 0x00CCCCCC  # grayish color for door
    sw $t5, 0($t4)

    addi $t0, $t0, 1
    j draw_door_loop

end_draw_door:
    jr $ra
#===========CHECKING OF COLLISION ON THE FLOOR AND THE SIDES OF THE BIRD===========#
# This part includes checking of collision of the bird with obstacles
# It also includes the health condition of the bird represented by hearts.

#--------CHECK COLLISION-----------#	
# Arguments:
# $a0 = obstacle pointer

#then we set these
# $a0 = obstacle_x
# $a1 = obstacle_y
# $a2 = obstacle_width
# $a3 = obstacle_height

# Bird position is in:
# $t0 = bird_x
# $t1 = bird_y
# BIRD_SIZE = 5

# Return:
# $v0 0 is no collision non-zero is type of collision
#-----------------------------------#

check_collision:
	move   $t0, $a0
	lw     $a0, 0($t0)
	lw     $a1, 4($t0)
	lw     $a2, 8($t0)
	lw     $a3, 12($t0)
	lw     $t8, 16($t0)  # type

	li $v0, 0    # default no collision
	# Bird's box
	lw      $t0, b_posx         # bird_x
	lw      $t1, b_posy         # bird_y

	# Bird bounds
	addi    $t3, $t0, BOX_SIZE
	addi    $t4, $t1, BOX_SIZE
	addi    $t3, $t3, -1      # bird_right (x + width - 1)
	addi    $t4, $t4, -1      # bird_bottom (y + height - 1)

	# Obstacle bounds
	add     $t2, $a0, $a2
	add     $t5, $a1, $a3
	addi    $t2, $t2, -1         # obs_right
	addi    $t5, $t5, -1         # obs_bottom

	# Can add checks for other types you don't want to be able
	# to stand on
	li      $t9, TYPE_PICKUP
	beq     $t8, $t9, not_on_platform

	lw      $t6, on_plat
	addi    $t7, $a1, -1
	bne     $t4, $t7, not_on_platform

	blt     $t3, $a0, exit_collision  # bird_right < obs_left
	bgt     $t0, $t2, exit_collision  # bird_left > obs_right

	ori     $t6, $t6, 1
	sw      $t6, on_plat

	sw      $0, jump_flag  # reset jump flag when we land
	sw      $0, b_dy
	j       exit_collision

####
not_on_platform:
	# Check for NO overlap:
	blt     $t3, $a0, exit_collision  # bird_right < obs_left
	bgt     $t0, $t2, exit_collision  # bird_left > obs_right
	blt     $t4, $a1, exit_collision  # bird_bottom < obs_top
	bgt     $t1, $t5, exit_collision  # bird_top > obs_bottom

	# restore to old position pre-collision
	lw      $t0, b_posx_old
	lw      $t1, b_posy_old

	li      $a3, TYPE_MOVING_BOX
	bne     $t8, $a3, only_restore_old

	#sw      $0, b_dy   # set dy to 0 (if hitting side or bottom will fall)

	# add moving direction if colliding with moving platform in all directions
	lw      $t2, moving_plat_dir
	add     $t0, $t0, $t2
	lw      $t6, on_plat_old
	bnez    $t6, on_platform_cant_fall
	addi    $t1, $t1, GRAVITY
on_platform_cant_fall:
	sw      $t0, b_posx
	sw      $t1, b_posy
	j       exit_collision

only_restore_old:
	sw      $t0, b_posx
	sw      $t1, b_posy

# This is actually kind of nonsensical. To be useful it would really have to
# subtract against each other to see which one is the least overlapping direction
type_collisions:
	bge     $t4, $a1, hit_bottom    # bird_bottom >= obs_top
	ble     $t0, $t2, hit_left      # bird_left <= obs_right
	ble     $t1, $t5, hit_top       # bird_top <= obs_bottom
	bge     $t3, $a0, hit_right     # bird_right >= obs_left

hit_right:
	li   $v0, 1
	j    exit_collision
hit_left:
	li   $v0, 2
	j    exit_collision
hit_top:
	li   $v0, 3
	j    exit_collision
hit_bottom:
	li   $v0, 4

exit_collision:
    jr $ra


# void draw_health(void)
draw_health:
	addi   $sp, $sp, -16
	sw     $ra, 0($sp)
	sw     $s0, 4($sp)
	sw     $s1, 8($sp)
	sw     $s2, 12($sp)

	lw     $s0, health
	li     $s1, 0  # i = 0
	li     $s2, 120  # starting x position
	j      dh_check
dh_loop:
	move   $a0, $s2  # x
	li     $a1, 5    # y
	jal    draw_heart_sprite

	addi   $s2, $s2, -8  # x -= 8
	addi   $s1, $s1, 1  # i++
dh_check:
	blt    $s1, $s0, dh_loop  # while (i < health)

	lw     $ra, 0($sp)
	lw     $s0, 4($sp)
	lw     $s1, 8($sp)
	lw     $s2, 12($sp)
	addi   $sp, $sp, 16
	jr     $ra



#----Draw hearts----#
#Arguments: 
# $a0 = x position
# $a1 = y position
#-------------------#
draw_heart_sprite:
    la   $t0, heart_sprite       # sprite pointer
    li   $t1, 0                  # dy (row index)

heart_row_loop:
    bge  $t1, HEART_HEIGHT, end_draw_heart

    li   $t2, 0                  # dx (column index)

heart_col_loop:
    bge  $t2, HEART_WIDTH, next_heart_row

    # Calculate location on screen (x, y)
    add  $t3, $a0, $t2           # x = base_x + dx
    add  $t4, $a1, $t1           # y = base_y + dy

    # Calculate address of the point
    mul  $t5, $t4, WIDTH         # y * WIDTH
    add  $t5, $t5, $t3           # + x
    sll  $t5, $t5, 2             # * 4 (byte address)
    addi $t5, $t5, BASE_ADDRESS  # add base addr

    lw   $t6, 0($t0)             # load pixel color from sprite
    beq  $t6, COLOR_NONE, skip_store
    sw   $t6, 0($t5)             # store pixel to screen

skip_store:
    addi $t0, $t0, 4             # move to next sprite pixel
    addi $t2, $t2, 1
    j heart_col_loop

next_heart_row:
    addi $t1, $t1, 1
    j heart_row_loop

end_draw_heart:
    jr $ra
    


#--------FOR PRINTING EACH CHARACTER --------#
# Arguments:
# $a0 = base_x
# $a1 = base_y
# $a2 = address of sprite pointer array 
# $a3 = number of characters
draw_message:
    li $t0, 0                # index
draw_char_loop:
    bge $t0, $a3, end_draw_msg

    sll $t1, $t0, 2          # offset = i * 4 (word)
    add $t2, $a2, $t1        # ptr to current sprite
    lw  $t3, 0($t2)          # actual sprite address

    li  $t4, 0               # dy
draw_row:
    bge $t4, 5, next_char
    li  $t5, 0               # dx
draw_col:
    bge $t5, 5, next_row

    # calculate offset into 5x5 sprite
    mul $t6, $t4, 5
    add $t6, $t6, $t5
    sll $t6, $t6, 2          # convert to byte offset
    add $t6, $t6, $t3        # final pixel addr = sprite base + offset
    lw  $t7, 0($t6)          # load pixel color

    # Calculate screen x, y
    mul $t9, $t0, 6          # spacing between characters
    add $t9, $t9, $a0        # base_x + char offset
    add $t9, $t9, $t5        # add dx
    add $t8, $a1, $t4        # y = base_y + dy

    mul $t6, $t8, WIDTH
    add $t6, $t6, $t9
    sll $t6, $t6, 2
    addi $t6, $t6, BASE_ADDRESS

    beq $t7, COLOR_NONE, skip
    sw  $t7, 0($t6)

skip:
    addi $t5, $t5, 1
    j draw_col

next_row:
    addi $t4, $t4, 1
    j draw_row

next_char:
    addi $t0, $t0, 1
    j draw_char_loop

end_draw_msg:
    jr $ra



.data
# This is using pixel art idea but simplified it with the COLOR_NONE and COLOR_HEART 
# values to make it more organized instead of actual values of the colors
heart_sprite:
    .word COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART
    .word COLOR_NONE, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_NONE
    
#Store the spirite form of the characters so it can be reused to avoid any redundancy

    
# Deduplicated character sprite declarations
# Use labels for each sprite and reference them in arrays like msg_you_win / msg_you_lose

#-------Character Sprites-------#
# G
char_G:
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_HEART, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE

# A
char_A:
    .word COLOR_NONE, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE

# M
char_M:
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_HEART
    .word COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_HEART

# E
char_E:
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_HEART

# O
char_O:
    .word COLOR_NONE, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_NONE, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE

# V
char_V:
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_HEART
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_HEART
    .word COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_NONE

# R
char_R:
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE
    .word COLOR_HEART, COLOR_HEART, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_HEART, COLOR_NONE, COLOR_NONE
    .word COLOR_HEART, COLOR_NONE, COLOR_NONE, COLOR_HEART, COLOR_NONE

# Y
char_Y:
    .word COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN
    .word COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE

# U
char_U:
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE

# W
char_W:
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN

# I
char_I:
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_NONE
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN

# N
char_N:
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN

# L
char_L:
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN

# S
char_S:
    .word COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_LGREEN
    .word COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_LGREEN, COLOR_NONE

# SPACE
char_SPACE:
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE
    .word COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE, COLOR_NONE

# -------Message Sprite Pointer Arrays-------#
msg_you_win:
    .word char_G, char_A, char_M, char_E, char_SPACE
    .word char_O, char_V, char_E, char_R, char_SPACE
    .word char_Y, char_O, char_U, char_SPACE
    .word char_W, char_I, char_N

msg_game_over:
msg_you_lose:
    .word char_G, char_A, char_M, char_E, char_SPACE
    .word char_O, char_V, char_E, char_R, char_SPACE
    .word char_Y, char_O, char_U, char_SPACE
    .word char_L, char_O, char_S, char_E

