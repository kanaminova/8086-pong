STACK SEGMENT PARA STACK
	DB 64 DUP (' ')
STACK ENDS

;data segment v
DATA SEGMENT PARA 'DATA'

	WINDOW_WIDTH DW 140h
	WINDOW_HEIGHT DW 0C8h
	WINDOW_BOUNDS DW 6

	TIME_AUX DB 0

	BALL_X DW 160
	BALL_Y DW 100
	BALL_SIZE DW 04h
	
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h

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
			
			jmp CHECK_TIME
	
		RET
	MAIN ENDP
	
;function for moving the ball
	MOVE_BALL PROC NEAR
	
		mov AX,BALL_VELOCITY_X
		add BALL_X,AX
		
		mov AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jl NEG_VELOCITY_X
		
		mov AX,WINDOW_WIDTH
		sub AX,BALL_SIZE
		sub AX,WINDOW_BOUNDS
		cmp BALL_X,AX
		jg NEG_VELOCITY_X
		
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
		
		NEG_VELOCITY_X:
			neg BALL_VELOCITY_X
		ret
		
		NEG_VELOCITY_Y:
			neg BALL_VELOCITY_Y
		ret
		
	MOVE_BALL ENDP
	
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

;end of the code
CODE ENDS
END