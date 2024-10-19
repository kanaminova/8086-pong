STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

;data segment v
DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h
	WINDOW_HEIGHT DW 0C8h
	WINDOW_BOUNDS DW 6

	TIME_AUX DB 0

	BALL_ORIGINAL_X DW 0A0h
	BALL_ORIGINAL_Y DW 64h
	BALL_X DW 160
	BALL_Y DW 100
	BALL_SIZE DW 04h
	
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	
	PADDLE_LEFT_X DW 0Ah
	PADDLE_LEFT_Y DW 0Ah
	
	PADDLE_RIGHT_X DW 132h
	PADDLE_RIGHT_Y DW 0Ah
	
	PADDLE_WIDTH DW 04h
	PADDLE_HEIGHT DW 19h
	
	PADDLE_VELOCITY_Y DW 05h

DATA ENDS

;code segment v
CODE SEGMENT PARA 'CODE'

;main function
	MAIN PROC FAR
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
			
			jmp CHECK_TIME
	
		RET
	MAIN ENDP
	
;function for reseting the ball position
	RESET_BALL_POSITION PROC NEAR
		
			mov AX,BALL_ORIGINAL_X
			sub AX,BALL_SIZE
			mov BALL_X,AX
			
			mov AX,BALL_ORIGINAL_Y
			sub AX,BALL_SIZE
			mov BALL_Y,AX
		
		RET
	RESET_BALL_POSITION ENDP
	
;function for moving the ball
	MOVE_BALL PROC NEAR
	
		mov AX,BALL_VELOCITY_X
		add BALL_X,AX
		
		mov AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jl RESET_POSITION
		
		mov AX,WINDOW_WIDTH
		sub AX,BALL_SIZE
		sub AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jg RESET_POSITION
		
		mov AX,BALL_VELOCITY_Y
		add BALL_Y,AX
	
		mov AX,WINDOW_BOUNDS
		cmp BALL_Y,AX
		jl NEG_VELOCITY_Y
		
		mov AX,WINDOW_HEIGHT
		sub AX,BALL_SIZE
		sub AX,WINDOW_BOUNDS
		cmp BALL_Y,AX
		jg NEG_VELOCITY_Y
		
		RET
		
		RESET_POSITION:
			call RESET_BALL_POSITION
		ret
		
		NEG_VELOCITY_Y:
			neg BALL_VELOCITY_Y
		ret
		
	MOVE_BALL ENDP
	
;function for moving the paddles
	MOVE_PADDLES PROC NEAR
	
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
	SET_SCREEN PROC NEAR
		mov AH,00h ;this thingy basically puts 00 into the AH which basically means that now the int will now what to do
		mov AL,0Dh ;this thingy here tells the int which video mode to choose :3
		int 10h
	
		mov AH,0Bh ;this thingy here and the BH thingy below it tell the int that we wanna set a bg colour 
		mov BH,00h
		mov BL,01h ;and this thingy here sends the hexadecimal number for the colour black to the BL so the int can read it later :3
		int 10h

		RET
	SET_SCREEN ENDP
	
;function for drawing the ball
	DRAW_BALL PROC NEAR	
	
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
	DRAW_LEFT_PADDLE PROC NEAR
	
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
	DRAW_RIGHT_PADDLE PROC NEAR
		
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
	
;end of the code
CODE ENDS
END