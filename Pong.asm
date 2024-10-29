STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

;data segment v
DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h
	WINDOW_HEIGHT DW 0C8h
	WINDOW_BOUNDS DW 6

	TIME_AUX DB 0
	GAME_ACTIVE DB 1
	EXITING_GAME DB 0
	WINNER_INDEX DB 0
	CURRENT_SCENE DB 0
	
	TEXT_P1_POINTS DB '0','$'
	TEXT_P2_POINTS DB '0','$'
	TEXT_GAME_OVER_TITLE DB 'GAME OVER','$'
	TEXT_GAME_OVER_WINNER DB 'Player 0 won!','$'
	TEXT_GAME_OVER_RESET DB 'PLAY AGAIN -> PRESS SPACE','$'
	TEXT_GAME_OVER_MMENU DB 'MAIN MENU -> PRESS BACKSPACE','$'
	TEXT_MAIN_MENU DB '8086 PONG','$'
	TEXT_MAIN_MENU_SINGLE DB 'SINGLEPLAYER -> PRESS SPACE','$'
	TEXT_MAIN_MENU_MULTI DB 'MULTIPLAYER -> PRESS BACKSPACE','$'
	TEXT_MAIN_MENU_EXIT DB 'PRESS ESC TO EXIT THE GAME','$'

	BALL_ORIGINAL_X DW 0A0h
	BALL_ORIGINAL_Y DW 64h
	BALL_X DW 160
	BALL_Y DW 100
	BALL_SIZE DW 04h
	
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	
	PADDLE_LEFT_X DW 0Ah
	PADDLE_LEFT_Y DW 55h
	PADDLE_LEFT_ORG_Y DW 55h
	P1_POINTS DB 0
	
	PADDLE_RIGHT_X DW 132h
	PADDLE_RIGHT_Y DW 55h
	PADDLE_RIGHT_ORG_Y DW 55h
	P2_POINTS DB 0
	
	PADDLE_WIDTH DW 04h
	PADDLE_HEIGHT DW 1Eh
	
	PADDLE_VELOCITY_Y DW 05h

DATA ENDS

;code segment v
CODE SEGMENT PARA 'CODE'

;main function
	MAIN PROC FAR										;MAIN FUNCTION AND CLOCK
	ASSUME CS:CODE,DS:DATA,SS:STACK
	push DS
	sub AX,AX
	push AX
	mov AX,DATA
	mov DS,AX
	pop AX
	pop DX
		
	call SET_SCREEN
		
	;time check procedure
		CHECK_TIME:
			
			cmp EXITING_GAME,01h
			je START_EXIT
			cmp CURRENT_SCENE,00h
			je SHOW_MAIN_MENU
			cmp GAME_ACTIVE,00h
			je SHOW_GAME_OVER
			
			mov AH,2Ch
			int 21h
			
			cmp DL,TIME_AUX
			je CHECK_TIME
			
			mov TIME_AUX,DL
		
			call SET_SCREEN
			
			call MOVE_BALL
			call DRAW_BALL
			
			call MOVE_PADDLES
			call DRAW_LEFT_PADDLE
			call DRAW_RIGHT_PADDLE
			
			call DRAW_UI
			
			jmp CHECK_TIME
			
			SHOW_GAME_OVER:
				call DRAW_GAME_OVER_MENU
				jmp CHECK_TIME
				
			SHOW_MAIN_MENU:
				call DRAW_MAIN_MENU
				jmp CHECK_TIME
			
			START_EXIT:
				call FIN_EXIT_GAME
	
		RET
	MAIN ENDP
	
	DRAW_UI PROC NEAR									;USER INTERFACE
	
		mov AH,02h		;set cursor position
		mov BH,00h 		;set page number
		mov DH,04h 		;set row
		mov DL,1Dh 		;set column
		int 10h
		
		mov AH,09h		;write string
		lea DX,TEXT_P2_POINTS
		int 21h
		
		mov AH,02h
		mov BH,00h
		mov DH,04h
		mov DL,5Ah
		int 10h
		
		mov AH,09h
		lea DX,TEXT_P1_POINTS
		int 21h
	
		RET
	DRAW_UI ENDP
	
;function for reseting the ball position
	RESET_BALL_POSITION PROC NEAR						;BALL POSITION RESET
			
			neg BALL_VELOCITY_X
			mov AX,BALL_ORIGINAL_X
			sub AX,BALL_SIZE
			mov BALL_X,AX
			
			mov AX,BALL_ORIGINAL_Y
			sub AX,BALL_SIZE
			mov BALL_Y,AX
		
		RET
	RESET_BALL_POSITION ENDP
	
	RESET_PADDLE_POSITION PROC NEAR
	
		mov AX,PADDLE_LEFT_ORG_Y
		mov PADDLE_LEFT_Y,AX
		
		mov AX,PADDLE_RIGHT_ORG_Y
		mov PADDLE_RIGHT_Y,AX
	
		RET
	RESET_PADDLE_POSITION ENDP
	
;function for moving the ball
	MOVE_BALL PROC NEAR									;BALL MOVEMENT AND COLLISIONS
	
		mov AX,BALL_VELOCITY_X
		add BALL_X,AX
		
		mov AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jl GIVE_POINTS_P2
		
		mov AX,WINDOW_WIDTH
		sub AX,BALL_SIZE
		sub AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jg GIVE_POINTS_P1
		jmp MOVE_BALL_VERTICALLY
		
		GIVE_POINTS_P1:
			inc P1_POINTS
			call RESET_BALL_POSITION
			call UPDATE_TEXT_P1_POINTS
			cmp P1_POINTS,05h
			jge GAME_OVER
			RET
			
		GIVE_POINTS_P2:
			inc P2_POINTS
			call RESET_BALL_POSITION
			call UPDATE_TEXT_P2_POINTS
			cmp P2_POINTS,05h
			jge GAME_OVER
			RET
		
		GAME_OVER:
			cmp P1_POINTS,05h
			jnl WINNER_IS_P1
			jmp WINNER_IS_P2
			
			WINNER_IS_P1:
				mov WINNER_INDEX,01h
				jmp CONT_GAME_OVER
			WINNER_IS_P2:
				mov WINNER_INDEX,02h
				jmp CONT_GAME_OVER
		
			CONT_GAME_OVER:
			mov P1_POINTS,00h
			mov P2_POINTS,00h
			call UPDATE_TEXT_P1_POINTS
			call UPDATE_TEXT_P2_POINTS
			mov GAME_ACTIVE,00h
			RET
			
		MOVE_BALL_VERTICALLY:
			mov AX,BALL_VELOCITY_Y
			add BALL_Y,AX

;check if ball passed top
		mov AX,WINDOW_BOUNDS
		cmp BALL_Y,AX
		jl NEG_VELOCITY_Y
		
;check if ball passed bottom		
		mov AX,WINDOW_HEIGHT
		sub AX,BALL_SIZE
		sub AX,WINDOW_BOUNDS
		cmp BALL_Y,AX
		jg NEG_VELOCITY_Y
		jmp CHECK_COLLISION_WITH_RIGHT_PADDLE
		
		NEG_VELOCITY_Y:
			neg BALL_VELOCITY_Y
		ret
		
;check for right paddle collision
		CHECK_COLLISION_WITH_RIGHT_PADDLE:
		mov AX,BALL_X
		add AX,BALL_SIZE
		cmp AX,PADDLE_RIGHT_X
		jng CHECK_COLLISION_WITH_LEFT_PADDLE ;if no collision, check for the left paddle
		
		mov AX,PADDLE_RIGHT_X
		add AX,PADDLE_WIDTH
		cmp BALL_X,AX
		jnl CHECK_COLLISION_WITH_LEFT_PADDLE
		
		mov AX,BALL_Y
		add AX,BALL_SIZE
		cmp AX,PADDLE_RIGHT_Y
		jng CHECK_COLLISION_WITH_LEFT_PADDLE
		
		mov AX,PADDLE_RIGHT_Y
		add AX,PADDLE_HEIGHT
		cmp BALL_Y,AX
		jnl CHECK_COLLISION_WITH_LEFT_PADDLE
		
		neg BALL_VELOCITY_X
		RET
		
		
;check for left paddle collision
		CHECK_COLLISION_WITH_LEFT_PADDLE:
		mov AX,BALL_X
		add AX,BALL_SIZE
		cmp AX,PADDLE_LEFT_X
		jng EXIT_COLLISION_CHECK
		
		mov AX,PADDLE_LEFT_X
		add AX,PADDLE_WIDTH
		cmp BALL_X,AX
		jnl EXIT_COLLISION_CHECK
		
		mov AX,BALL_Y
		add AX,BALL_SIZE
		cmp AX,PADDLE_LEFT_Y
		jng EXIT_COLLISION_CHECK
		
		mov AX,PADDLE_LEFT_Y
		add AX,PADDLE_HEIGHT
		cmp BALL_Y,AX
		jnl EXIT_COLLISION_CHECK
		
		neg BALL_VELOCITY_X
		RET

		
		EXIT_COLLISION_CHECK:
			RET
	MOVE_BALL ENDP
	
;function for moving the paddles
	MOVE_PADDLES PROC NEAR								;PADDLE MOVEMENT
	
			;moving the left paddle
		
			;input check
			mov AH,01h
			int 16h
			jz CHECK_RIGHT_PADDLE_MOVEMENT
			;check key pressed
			mov AH,00h
			int 16h
			;check if 'w' or 'W' then move up
			cmp AL,77h
			je MOVE_LEFT_PADDLE_UP
			cmp AL,57h
			je MOVE_LEFT_PADDLE_UP
			;check if 's' or 'S' then move down
			cmp AL,73h
			je MOVE_LEFT_PADDLE_DOWN
			cmp AL,53h
			je MOVE_LEFT_PADDLE_DOWN
			jmp CHECK_RIGHT_PADDLE_MOVEMENT
			
			MOVE_LEFT_PADDLE_UP:
				mov AX,PADDLE_VELOCITY_Y
				sub PADDLE_LEFT_Y,AX
				
				mov AX,WINDOW_BOUNDS
				cmp PADDLE_LEFT_Y,AX
				jl FIX_PADDLE_LEFT_TOP_POSITION
				jmp CHECK_RIGHT_PADDLE_MOVEMENT
			
				FIX_PADDLE_LEFT_TOP_POSITION:
					mov AX,WINDOW_BOUNDS
					mov PADDLE_LEFT_Y,AX
					jmp CHECK_RIGHT_PADDLE_MOVEMENT
			
			MOVE_LEFT_PADDLE_DOWN:
				mov AX,PADDLE_VELOCITY_Y
				add PADDLE_LEFT_Y,AX
			
				mov AX,WINDOW_HEIGHT
				sub AX,WINDOW_BOUNDS
				sub AX,PADDLE_HEIGHT
				cmp PADDLE_LEFT_Y,AX
				jg FIX_PADDLE_LEFT_BTM_POSITION
				jmp CHECK_RIGHT_PADDLE_MOVEMENT
			
				FIX_PADDLE_LEFT_BTM_POSITION:
					mov PADDLE_LEFT_Y,AX
					jmp CHECK_RIGHT_PADDLE_MOVEMENT
			
		;moving the right paddle
		CHECK_RIGHT_PADDLE_MOVEMENT:
			;moving the right paddle
			
			;input check
			mov AH,01h
			int 16h
			jz EXIT_PADDLE_MOVEMENT
			;check key pressed
			mov AH,00h
			int 16h
			;check if 'o' or 'O' pressed then move up
			cmp AL,6Fh
			je MOVE_RIGHT_PADDLE_UP
			cmp AL,4Fh
			je MOVE_RIGHT_PADDLE_UP
			;check if 'l' or 'L' pressed then move down
			cmp AL,6Ch
			je MOVE_RIGHT_PADDLE_DOWN
			cmp AL,4Ch
			je MOVE_RIGHT_PADDLE_DOWN
			jmp EXIT_PADDLE_MOVEMENT
			
			MOVE_RIGHT_PADDLE_UP:
				mov AX,PADDLE_VELOCITY_Y
				sub PADDLE_RIGHT_Y,AX
				
				mov AX,WINDOW_BOUNDS
				cmp PADDLE_RIGHT_Y,AX
				jl FIX_PADDLE_RIGHT_TOP_POSITION
				jmp EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_TOP_POSITION:
					mov AX,WINDOW_BOUNDS
					mov PADDLE_RIGHT_Y,AX
					jmp EXIT_PADDLE_MOVEMENT
				
			MOVE_RIGHT_PADDLE_DOWN:
				mov AX,PADDLE_VELOCITY_Y
				add PADDLE_RIGHT_Y,AX
				
				mov AX,WINDOW_HEIGHT
				sub AX,WINDOW_BOUNDS
				sub AX,PADDLE_HEIGHT
				cmp PADDLE_RIGHT_Y,AX
				jg FIX_PADDLE_RIGHT_BTM_POSITION
				jmp EXIT_PADDLE_MOVEMENT
				
				FIX_PADDLE_RIGHT_BTM_POSITION:
					mov PADDLE_RIGHT_Y,AX
					jmp EXIT_PADDLE_MOVEMENT
					
		EXIT_PADDLE_MOVEMENT:
			RET
	MOVE_PADDLES ENDP
	
;function for setting the video mode
	SET_SCREEN PROC NEAR								;SCREEN SETTINGS
		mov AH,00h ;this thingy basically puts 00 into the AH which basically means that now the int will now what to do
		mov AL,0Dh ;this thingy here tells the int which video mode to choose :3
		int 10h
	
		mov AH,0Bh ;this thingy here and the BH thingy below it tell the int that we wanna set a bg colour 
		mov BH,00h
		mov BL,01h ;and this thingy here sends the hexadecimal number for the colour black to the BL so the int can read it later :3
		int 10h

		RET
	SET_SCREEN ENDP
	
	FIN_EXIT_GAME PROC NEAR
	
		mov AH,00h
		mov AL,03h
		int 10h
		
		mov AH,4Ch
		int 21h
		
		RET
	FIN_EXIT_GAME ENDP
	
;function for drawing the ball
	DRAW_BALL PROC NEAR									;DRAWING THE BALL
	
		mov CX,BALL_X
		mov DX,BALL_Y
		
		DRAW_BALL_HORIZONTAL:
			mov AH,0Ch
			mov AL,0Fh
			mov BH,00h
			int 10h
			
			inc CX
			mov AX,CX
			sub AX,BALL_X
			cmp AX,BALL_SIZE
			jng DRAW_BALL_HORIZONTAL
			
			mov CX,BALL_X
			inc DX
			
			mov AX,DX
			sub AX,BALL_Y
			cmp AX,BALL_SIZE
			jng DRAW_BALL_HORIZONTAL
			
		RET
	DRAW_BALL ENDP

;function for drawing the left paddle
	DRAW_LEFT_PADDLE PROC NEAR							;DRAWING THE LEFT PADDLE
	
		mov CX,PADDLE_LEFT_X
		mov DX,PADDLE_LEFT_Y
		
		DRAW_PADDLE_LEFT:
			mov AH,0Ch
			mov AL,0Fh
			mov BH,00h
			int 10h
			
			inc CX
			mov AX,CX
			sub AX,PADDLE_LEFT_X
			cmp AX,PADDLE_WIDTH
			jng DRAW_PADDLE_LEFT
			
			mov CX,PADDLE_LEFT_X
			inc DX
			
			mov AX,DX
			sub AX,PADDLE_LEFT_Y
			cmp AX,PADDLE_HEIGHT
			jng DRAW_PADDLE_LEFT
	
		RET
	DRAW_LEFT_PADDLE ENDP
	
;function for drawing the right paddle
	DRAW_RIGHT_PADDLE PROC NEAR							;DRAWING THE RIGHT PADDLE
		
		mov CX,PADDLE_RIGHT_X
		mov DX,PADDLE_RIGHT_Y
		
		DRAW_PADDLE_RIGHT:
			mov AH,0Ch
			mov AL,0Fh
			mov BH,00h
			int 10h
			
			inc CX
			mov AX,CX
			sub AX,PADDLE_RIGHT_X
			cmp AX,PADDLE_WIDTH
			jng DRAW_PADDLE_RIGHT
			
			mov CX,PADDLE_RIGHT_X
			inc DX
			
			mov AX,DX
			sub AX,PADDLE_RIGHT_Y
			cmp AX,PADDLE_HEIGHT
			jng DRAW_PADDLE_RIGHT
			
		RET
	DRAW_RIGHT_PADDLE ENDP
	
	UPDATE_TEXT_P1_POINTS PROC NEAR
		
		sub AX,AX
		mov AL,P1_POINTS
		add AL,30h
		mov [TEXT_P1_POINTS],AL
			
		RET
	UPDATE_TEXT_P1_POINTS ENDP
	
	UPDATE_TEXT_P2_POINTS PROC NEAR
	
		sub AX,AX
		mov AL,P2_POINTS
		add AL,30h
		mov [TEXT_P2_POINTS],AL
	
		RET
	UPDATE_TEXT_P2_POINTS ENDP
	
	DRAW_GAME_OVER_MENU PROC NEAR
		
		call RESET_PADDLE_POSITION
		call SET_SCREEN
		
		mov AH,02h
		mov BH,00h
		mov DH,04h
		mov DL,5Ah
		int 10h
		
		call UPDATE_WINNER_TEXT
		
		mov AH,09h
		lea DX,TEXT_GAME_OVER_TITLE
		int 21h
		
		mov AH,02h
		mov BH,00h
		mov DH,06h
		mov DL,5Ah
		int 10h
		
		mov AH,09h
		lea DX,TEXT_GAME_OVER_WINNER
		int 21h
		
		mov AH,02h
		mov BH,00h
		mov DH,08h
		mov DL,5Ah
		int 10h
		
		mov AH,09h
		lea DX,TEXT_GAME_OVER_RESET
 		int 21h
		
		mov AH,02h
		mov BH,00h
		mov DH,0Ah
		mov DL,5Ah
		int 10h
		
		mov AH,09h
		lea DX,TEXT_GAME_OVER_MMENU
 		int 21h
		
		mov AH,00h
		int 16h
		cmp AL,20h
		je GAME_RESTART
		cmp AL,08h
		je TO_MAIN_MENU
		
		GAME_RESTART:
			mov GAME_ACTIVE,01h
			RET
		TO_MAIN_MENU:
			mov GAME_ACTIVE,00h
			mov CURRENT_SCENE,00h
			RET
			
	DRAW_GAME_OVER_MENU ENDP
	
	UPDATE_WINNER_TEXT PROC NEAR
		mov AL,WINNER_INDEX
		add AL,30h
		mov [TEXT_GAME_OVER_WINNER+7],AL
		
		RET
	UPDATE_WINNER_TEXT ENDP
	
	DRAW_MAIN_MENU PROC NEAR
		
			call SET_SCREEN
			
			mov AH,02h
			mov BH,00h
			mov DH,06h
			mov DL,5Ah
			int 10h
			
			mov AH,09h
			lea DX,TEXT_MAIN_MENU
			int 21h
			
			mov AH,02h
			mov BH,00h
			mov DH,08h
			mov DL,5Ah
			int 10h
			
			mov AH,09h
			lea DX,TEXT_MAIN_MENU_SINGLE
			int 21h
			
			mov AH,02h
			mov BH,00h
			mov DH,0Ah
			mov DL,5Ah
			int 10h
			
			mov AH,09h
			lea DX,TEXT_MAIN_MENU_MULTI
			int 21h
			
			mov AH,02h
			mov BH,00h
			mov DH,0Ch
			mov DL,5Ah
			int 10h
			
			mov AH,09h
			lea DX,TEXT_MAIN_MENU_EXIT
			int 21h
			
			MAIN_MENU_WFK:
			mov AH,00h
			int 16h
			
			cmp AL,20h
			je ENTR_SINGLE
			cmp AL,08h
			je ENTR_MULTI
			cmp AL,1Bh
			je EXIT_GAME
			jmp MAIN_MENU_WFK
			
			ENTR_SINGLE:
				mov GAME_ACTIVE,01h
				mov CURRENT_SCENE,01h
				
			ENTR_MULTI:
				mov GAME_ACTIVE,01h
				mov CURRENT_SCENE,01h
				
			EXIT_GAME:
				mov EXITING_GAME,01h
		
		RET
	DRAW_MAIN_MENU ENDP
	
;end of the code
CODE ENDS
END														;FINITO :3