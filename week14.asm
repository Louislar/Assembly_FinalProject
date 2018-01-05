INCLUDE Irvine32.inc

judge PROTO, pstart: PTR BYTE, twidth: word, theight: word, curPos: DWORD, curType: BYTE

main	EQU start@0
BoxWidth = 15
BoxHeight = 9
 
.data
boxTop    BYTE 0DAh, (BoxWidth - 2) DUP(0C2h), 0BFh
boxBody1   BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h	;0F9h是實心點
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h ;body有七列
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h
			BYTE 0C3h, 0F9h, 0F9h, 0F8h, (BoxWidth - 5) DUP(0C5h), 0B4h
boxBottom BYTE 0C0h, (BoxWidth - 5) DUP(0C1h), 0F8h, 0F9h, 0F8h, 0D9h ;0F8h是空心點

Temp WORD 0
ColNum WORD ?
 
outputHandle DWORD 0
bytesWritten DWORD 0
count DWORD 0
xyPosition COORD <10,5>
 
cellsWritten DWORD ?
attributes0 WORD BoxWidth DUP(0Eh)
attributes1 WORD (BoxWidth-1) DUP(0Bh), 0Ch
attributes2 WORD BoxWidth DUP(0Ah)

;;;;;;;;;;;;;;;;;;;;cursor;;;;;;;;;;;;;;;;;;;;
CursorPos COORD <>					;游標目前位置
consoleInfo CONSOLE_SCREEN_BUFFER_INFO <>	;從GetConsoleScreenBufferInfo拿回來的值
nextStep BYTE "NEXT STEP, PRESS ESC TO QUIT PROGRAM", 0

;;;;;;;;;;;;;;;;;;;win;;;;;;;;;;;;;;;;;;;;;;;;
pathLength word 0

          
 
.code
main PROC
 

    INVOKE GetStdHandle, STD_OUTPUT_HANDLE ; Get the console ouput handle
    mov outputHandle, eax ; save console handle
START:
	push xyPosition.Y
	call Clrscr
    ; 畫出box的第一行
    INVOKE WriteConsoleOutputAttribute,
      outputHandle,
      ADDR attributes0,
      BoxWidth,
      xyPosition,
      ADDR cellsWritten
 
    INVOKE WriteConsoleOutputCharacter,
       outputHandle,   ; console output handle
       ADDR boxTop,   ; pointer to the top box line
       BoxWidth,   ; size of box line
       xyPosition,   ; coordinates of first char
       ADDR count    ; output count
 
    inc xyPosition.Y   ; 座標換到下一行位置
 
 
	;;draw boxBody
    mov ecx, (BoxHeight-2)    ; number of lines in body
	push edi
	mov edi, OFFSET boxBody1
   
L1: 
	push ecx
    INVOKE WriteConsoleOutputAttribute, ;;body1
      outputHandle,
      ADDR attributes1,
      BoxWidth,
      xyPosition,
      ADDR cellsWritten
   
	INVOKE WriteConsoleOutputCharacter,
       outputHandle,
       ADDR [edi],   ; pointer to the box body
       BoxWidth,
       xyPosition,
       ADDR cellsWritten 
 
    inc xyPosition.Y   ; next line
	ADD edi, BoxWidth
	pop ecx
	loop L1
	pop edi
	;;draw boxBody-end
	
 
    INVOKE WriteConsoleOutputAttribute, 
      outputHandle,
      ADDR attributes2,
      BoxWidth,
      xyPosition,
      ADDR cellsWritten
 
    ; draw bottom of the box
    INVOKE WriteConsoleOutputCharacter,
       outputHandle,
       ADDR boxBottom,   ; pointer to the bottom of the box
       BoxWidth,
       xyPosition,
       ADDR cellsWritten
	   
	 pop xyPosition.Y
	   
	   
	
	INVOKE GetConsoleScreenBufferInfo, 
		outputHandle, 
		ADDR consoleInfo
	
	;;得到目前游標位置的方法
	push eax
	mov ax, consoleInfo.dwCursorPosition.x
	mov CursorPos.x, ax
	mov ax, consoleInfo.dwCursorPosition.y
	mov CursorPos.y, ax
	pop eax
	
	
	;;銀幕上顯示next step
	push edx
	mov edx, OFFSET nextStep
	call WriteString
	pop edx
	
	
	
	;;設定游標位置的方法
	push eax
	mov ax, 10
	mov CursorPos.x, ax
	mov ax, 5
	mov CursorPos.y, ax
	pop eax
	
	
		
	 
	;;接下來要設定游標，讓user可以操控，week15_lab12內容
setCursor:
	INVOKE SetConsoleCursorPosition, outputHandle, Cursorpos
	call ReadChar
	.IF ax == 4800h ;UP
		sub Cursorpos.y,1
	.ENDIF
	.IF ax == 5000h ;DOWN
		add Cursorpos.y,1
	.ENDIF
	.IF ax == 4B00h ;LEFT
		sub Cursorpos.x,1
	.ENDIF
	.IF ax == 4D00h ;RIGHT
		add Cursorpos.x,1
	.ENDIF
	.IF ax == 011Bh ;ESC
		jmp END_FUNC
	.ENDIF
	.IF ax == 3920h ;SPACE
		INVOKE GetConsoleScreenBufferInfo, 
			outputHandle, 
			ADDR consoleInfo
		push eax
		push ebx
		push edx
		push ecx
		mov eax, 0
		mov ebx, 0
		mov edx, 0
		mov ecx, 0
		mov ax, consoleInfo.dwCursorPosition.x
		mov bx, consoleInfo.dwCursorPosition.y
		sub ax, xyPosition.x
		sub bx, xyPosition.y
		
		mov Temp, ax
		mov ax, BoxWidth
		MUL bx
		ADD ax, Temp


		
		mov boxTop[eax], 0F8h   ;改空心點, 少了判斷勝利的函式
								;以及少了判斷線在該誰落子的條件
		;;;;;;;;;勝負判斷;;;;;;;;;;
		INVOKE judge, ADDR boxTop, BoxWidth, BoxHeight, eax, 0F8h
		.IF ebx==1
			mov nextStep[ebx], 0F8h
		.ENDIF
		
		pop ecx
		pop edx
		pop ebx
		pop eax
		
		jmp START
	.ENDIF
	jmp setCursor
	
	

END_FUNC:
    call Clrscr ;清除銀幕
    exit
main ENDP



judge PROC USES eax ecx, pstart:PTR BYTE, twidth: word, theight: word, curPos: DWORD, curType: BYTE
	
	;;test;;
	push eax
	mov eax, 12h
	mov al, BYTE PTR [pstart]
	pop eax
	;;test-end;;
	
	push curPos
	mov ecx, 4 ;五子連線才獲勝
	mov eax, 0 ;紀錄幾子連線
upleft:
	DEC curPos
	push eax
	movzx eax, twidth
	SUB curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp upleftbreak
	.ENDIF
	pop ebx
	pop ecx
	loop upleft
upleftbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	
	
	
	push curPos
	mov ecx, 4 ;五子連線才獲勝
downright:
	INC curPos
	push eax
	movzx eax, twidth
	ADD curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp downrightbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop downright
downrightbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	;第一組左上-右下-情況結束
	
	
	;;;;;;;;;;;;;;;;;;第二組上-下-情況;;;;;;;;;;;;;;;;;;;;;;
	push curPos
	mov ecx, 4 ;五子連線才獲勝
	mov eax, 0 ;紀錄幾子連線, eax歸零
up:
	push eax
	movzx eax, twidth
	SUB curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp upbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop up
upbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	
	
	
	push curPos
	mov ecx, 4 ;五子連線才獲勝
down:
	push eax
	movzx eax, twidth
	ADD curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp downbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop down
downbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	;;;;;;;;;;;;;;;;;第二組上-下-情況結束;;;;;;;;;;;;;;
	

	;;;;;;;;;;;;;;;;;;第三組右上-左下-情況;;;;;;;;;;;;;;;;;;;;;;
	push curPos
	mov ecx, 4 ;五子連線才獲勝
	mov eax, 0 ;紀錄幾子連線, eax歸零
upright:
	INC curPos
	push eax
	movzx eax, twidth
	SUB curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp uprightbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop upright
uprightbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	
	
	
	push curPos
	mov ecx, 4 ;五子連線才獲勝
downleft:
	DEC curPos
	push eax
	movzx eax, twidth
	ADD curPos, eax
	pop eax
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp downleftbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop downleft
downleftbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	;;;;;;;;;;;;;;;;;第三組上-下-情況結束;;;;;;;;;;;;;;
	
	
	;;;;;;;;;;;;;;;;;;第四組左-右-情況;;;;;;;;;;;;;;;;;;;;;;
	push curPos
	mov ecx, 4 ;五子連線才獲勝
	mov eax, 0 ;紀錄幾子連線, eax歸零
left:
	DEC curPos
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp leftbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop left
leftbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	
	
	
	push curPos
	mov ecx, 4 ;五子連線才獲勝
right:
	INC curPos
	
	push ecx
	push ebx
	mov ecx, curPos
	mov ebx ,0
	mov bl, boxTop[ecx]
	.IF bl==curType ;ecx=curPos
		INC eax
	.ENDIF
	
	.IF bl!=curType
		pop ebx
		pop ecx
		jmp rightbreak
	.ENDIF
	pop ebx
	pop ecx
	
	loop right
rightbreak:
	pop curPos
	.IF eax==4
		jmp win
	.ENDIF
	;;;;;;;;;;;;;;;;;第四組左-右-情況結束;;;;;;;;;;;;;;
	
	jmp nwin
win:
	mov ebx, 1
	jmp FIN
nwin:
	mov ebx, 0
FIN:
	ret
judge ENDP

END main
