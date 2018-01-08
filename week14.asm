INCLUDE Irvine32.inc

judge PROTO, pstart: PTR BYTE, twidth: word, theight: word, curPos: DWORD, curType: BYTE

main	EQU start@0
BoxWidth = 15
BoxHeight = 9
blackDot = 0F9h
WhiteDot = 06Fh
 
.data
boxTop    BYTE 0DAh, (BoxWidth - 2) DUP(0C2h), 0BFh
boxBody1   BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h	;WhiteDot是實心點
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h ;body有七列
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h
			BYTE 0C3h, (BoxWidth - 2) DUP(0C5h), 0B4h
boxBottom BYTE 0C0h, (BoxWidth - 2) DUP(0C1h), 0D9h ;blackDot是空心點

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
curTypeHint BYTE "CURRENT TURN ?", 0

;;;;;;;;;;;;;;;;;;;turn;;;;;;;;;;;;;;;;;;;;;;;;
BorW WORD 1							;黑子為1, 白子為0
presentType BYTE WhiteDot
presentPos DWORD ?
winName BYTE "WINNER IS ?"


          
 
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
	
	
	;;銀幕上顯示next step, 以及現在該誰下棋了
	push edx
	mov edx, OFFSET nextStep
	call WriteString
	call crlf
	.IF BorW==1
		mov curTypeHint[13], blackDot
	.ENDIF
	.IF BorW==0
		mov curTypeHint[13], WhiteDot
	.ENDIF
	mov edx, OFFSET curTypeHint
	call WriteString
	pop edx
	
	
	
	;;設定游標位置的方法
	push eax
	mov ax, xyPosition.x
	mov CursorPos.x, ax
	mov ax, xyPosition.y
	mov CursorPos.y, ax
	pop eax
	
	
		
	 
	;;接下來要設定游標，讓user可以操控，week15_lab12內容
setCursor:
	INVOKE SetConsoleCursorPosition, outputHandle, Cursorpos
	call ReadChar
	.IF ax == 4800h ;UP
		push eax
		mov ax, xyPosition.y
		sub Cursorpos.y,1
		.IF	Cursorpos.y<ax
			ADD Cursorpos.y,1
			jmp setCursor
		.ENDIF
		pop eax
	.ENDIF
	.IF ax == 5000h ;DOWN
		push eax
		mov ax, xyPosition.y
		ADD ax, BoxHeight-1
		add Cursorpos.y,1
		.IF	Cursorpos.y>ax
			SUB Cursorpos.y,1
			jmp setCursor
		.ENDIF
		pop eax
	.ENDIF
	.IF ax == 4B00h ;LEFT
		push eax
		mov ax, xyPosition.x
		sub Cursorpos.x,1
		.IF	Cursorpos.x<ax
			ADD Cursorpos.x,1
			jmp setCursor
		.ENDIF
		pop eax
	.ENDIF
	.IF ax == 4D00h ;RIGHT
		push eax
		mov ax, xyPosition.x
		ADD ax, BoxWidth-1
		add Cursorpos.x,1
		.IF	Cursorpos.x>ax
			SUB Cursorpos.x,1
			jmp setCursor
		.ENDIF
		pop eax
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
		ADD ax, Temp			;;以上是為了算出當前cursor是在array(棋盤)的哪個位置
		
		.IF boxTop[eax]==blackDot
			jmp setCursor
		.ENDIF
		.IF boxTop[eax]==WhiteDot
			jmp setCursor
		.ENDIF

		.IF BorW==1				;;這回合是黑子
			push eax
			mov al, blackDot
			mov presentType, al
			pop eax
		.ENDIF
		
		.IF BorW==0				;;這回合是白子
			push eax
			mov al, WhiteDot
			mov presentType, al
			pop eax
		.ENDIF
		
		push eax				;;改變下一回合的下子顏色
		mov ax, BorW
		XOR ax, 1
		mov BorW, ax
		pop eax
		
		push ebx
		mov bl, presentType
		mov boxTop[eax], bl   ;改當前的位置變成這回合的子
		push ebx
		
		
		;;;;;;;;;勝負判斷;;;;;;;;;;
		mov presentPos, eax
		INVOKE judge, ADDR boxTop, BoxWidth, BoxHeight, presentPos, presentType
		
		.IF ebx==1				;;presentType的那個人贏了
			push eax
			push xyPosition.x
			push xyPosition.y
			mov al, presentType
			mov nextStep[ebx], al
			mov winName[10], al
			mov xyPosition.x, 0
			mov xyPosition.y, 2
			INVOKE SetConsoleCursorPosition, outputHandle, xyPosition
			mov edx, OFFSET winName
			call WriteString
			pop xyPosition.y
			pop xyPosition.x
			pop eax
			call crlf
			call WaitMsg
			jmp END_FUNC
			
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
