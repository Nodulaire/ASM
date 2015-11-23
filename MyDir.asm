.386					; x86 instructions
.model flat,stdcall
option casemap:none 	;Case sensitivity

; Function prototypes 
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD
	
; 	Includes
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


.DATA
	lengthPathMax 		equ 	1024
	currentDir			db 		"C:\Users\",0
	ClassName 			db 		"MyDIr",0
	AppName  			db 		"MyDir_v1.2",0
	ButtonClassName 	db 		"button",0
	EditClassName 		db 		"edit",0
	ButtonText 			db 		"List",0
	path    			db      lengthPathMax dup (?)
	endLine 			db      13,10,0
	masqueToApply		db   	"*.*", 0
	slash   			db      "\",0
	dot     			db      ".",0
	dotDot  			db      "..",0


.DATA?
	hInstance 			HINSTANCE 	?
	CommandLine 		LPSTR 		?
	hwndButton 			HWND 		?
	hwndEdit 			HWND 		?
	hwndPrint 			HWND 		?
	buffer 				db 			1024	 dup(?)
	buff_endline		db 			?

.CONST
	; for a more readable code there is code equivalent
	ButtonID 			equ 		1
	EditID 				equ 		2
	IDM_GETTEXT 		equ 		3
	IDM_EXIT 			equ 		4

.CODE
start:
	;;invoke GetModuleHandle, NULL
	push 	NULL
	call 	GetModuleHandle
	mov     hInstance,eax
	;;invoke GetCommandLine
	call 	GetCommandLine
	mov 	CommandLine,eax

;----------------------------------------------------------------------------;
;							WinMain function call							 ;
;----------------------------------------------------------------------------;
	;;invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
	push 	SW_SHOWDEFAULT
	push 	CommandLine
	push 	NULL
	push 	hInstance
	call 	WinMain

;----------------------------------------------------------------------------;
;							Kill the process and leave						 ;
;----------------------------------------------------------------------------;
;	invoke ExitProcess,eax
	push 	eax
	call 	ExitProcess

;----------------------------------------------------------------------------;
;							WinMain function entry							 ;
;----------------------------------------------------------------------------;
	WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
		LOCAL 	wc:WNDCLASSEX
		LOCAL 	msg:MSG
		LOCAL 	hwnd:HWND
		mov   	wc.cbSize,SIZEOF WNDCLASSEX
		mov   	wc.style, CS_HREDRAW or CS_VREDRAW
		mov   	wc.lpfnWndProc, OFFSET WndProc
		mov   	wc.cbClsExtra,NULL
		mov   	wc.cbWndExtra,NULL
		push  	hInst
		pop   	wc.hInstance
		mov   	wc.hbrBackground,COLOR_BTNFACE+1
		mov   	wc.lpszMenuName,NULL
		mov   	wc.lpszClassName,OFFSET ClassName
		
		;;invoke LoadIcon,NULL,IDI_APPLICATION
		push 	IDI_APPLICATION
		push 	NULL
		call 	LoadIcon


		mov   	wc.hIcon,eax
		mov   	wc.hIconSm,eax
		;;invoke LoadCursor,NULL,IDC_ARROW
		push 	IDC_ARROW
		push 	NULL
		call 	LoadCursor
	
		mov   	wc.hCursor,eax

		;;invoke RegisterClassEx, addr wc
		lea 	ebx,	wc
		push 	ebx
		call 	RegisterClassEx

;----------------------------------------------------------------------------;
;					Create the main windows 								 ;
;----------------------------------------------------------------------------;
	;Invoke original :
		;INVOKE CreateWindowEx,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,\
	    ;      WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
	    ;     CW_USEDEFAULT,800,500,NULL,NULL,\
	    ;    hInst,NULL
	; Call version  
	    push 	NULL
	    push 	hInst
	    push 	NULL
	    push 	NULL
	    push 	500	; x length
	    push 	800	; y length 
	    push 	CW_USEDEFAULT 
	    push 	CW_USEDEFAULT
	    push 	WS_SYSMENU
	    push 	offset AppName
	    push 	offset ClassName
	    push 	WS_EX_CLIENTEDGE
	    call 	CreateWindowEx
		mov  	hwnd,	eax ; Store the unique windows ID 
;----------------------------------------------------------------------------;
;								ShowWindow									 ;
;----------------------------------------------------------------------------;

		;INVOKE ShowWindow, hwnd,SW_SHOWNORMAL
		push 	SW_SHOWNORMAL
		push 	hwnd
		call 	ShowWindow

;----------------------------------------------------------------------------;
;								UpdateWindow								 ;
;----------------------------------------------------------------------------;
		;INVOKE UpdateWindow, hwnd
		push 	hwnd 
		call 	UpdateWindow

;----------------------------------------------------------------------------;
;				           	Event handler			 						 ;
;----------------------------------------------------------------------------;
; This loop wait for the child windows to send states changement  			 ;
;----------------------------------------------------------------------------;
																			 
		;.WHILE TRUE 														 
		whileLoop:														     
	        ;INVOKE GetMessage, ADDR msg,NULL,0,0				
	        push 	0															 
	        push 	0
	        push 	NULL
	        lea 	eax,	msg
	        push 	eax
	        call 	GetMessage
	      
	        ; .BREAK .IF (!eax)
	        cmp 	eax,	NULL ;exit boucle condition
	        jz 		endTrueLoop
			; INVOKE TranslateMessage, ADDR msg
	        lea 	eax,	msg
	        push 	eax
	        call 	TranslateMessage
	       
	        ;INVOKE DispatchMessage, ADDR msg
	        lea 	eax,	msg
	        push 	eax
	        call 	DispatchMessage
	       	jmp 	whileLoop
        endTrueLoop:
;---------------------------END LOOP-----------------------------------------;

		;.ENDW
		mov 	eax,	msg.wParam
		ret
	WinMain endp


;----------------------------------------------------------------------------;
;							WinProcfunction entry							 ;
;----------------------------------------------------------------------------;

	WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
		;.IF uMsg==WM_DESTROY
		cmp 	uMsg,	WM_DESTROY
		jnz 	doNotquit
			push 	NULL
			call 	PostQuitMessage
		doNotquit:
		;.ELSEIF uMsg==WM_CREATE
		cmp 	uMsg,	WM_CREATE
		jnz 	doNotCreate
		;----------------------------------------------------------------------------;
		;							Create user input windows						 ;
		;----------------------------------------------------------------------------;
			;invoke CreateWindowEx,WS_EX_CLIENTEDGE, ADDR EditClassName, ADDR currentDir,\
	        ;                WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
	        ;                ES_AUTOHSCROLL,\
	        ;                20,35,735,25,hWnd,EditID,hInstance,NULL
	        push 	NULL
	        push 	hInstance
	        push 	EditID
	        push 	hWnd
	        push 	25
	        push 	735
	        push 	35
	        push 	20
	        push 	ES_AUTOHSCROLL or ES_LEFT or WS_BORDER or WS_VISIBLE \
	        		or WS_CHILD

	        push 	offset 	currentDir
	        push 	offset 	EditClassName
	        push 	WS_EX_CLIENTEDGE
	        call 	CreateWindowEx

	        ;invoke SetFocus, hwndEdit
			mov  	hwndEdit,	eax
			push 	hwndEdit
			call 	SetFocus

		;----------------------------------------------------------------------------;
		;							Create launch Button   							 ;
		;----------------------------------------------------------------------------;			
			;invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText,\
	        ;                WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\
	        ;    	            20,70,140,25,hWnd,ButtonID,hInstance,NULL
			push 	NULL
			push 	hInstance
			push 	ButtonID
			push 	hWnd
			push 	25
			push 	140
			push 	70
			push 	20
			push 	WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON
			push 	offset ButtonText
			push 	offset ButtonClassName
			push 	offset NULL
			call 	CreateWindowEx
			mov  	hwndButton,	eax ; Save unique window ID

		;----------------------------------------------------------------------------;
		;							Create dir listing windows						 ;
		;----------------------------------------------------------------------------;
			;invoke CreateWindowEx,WS_EX_CLIENTEDGE, NULL,NULL,\
	        ;                WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
	        ;                ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or \
	        ;                ES_MULTILINE or ES_READONLY ,\
	        ;                20,100,735,305,hWnd,EditID,hInstance,NULL
	        push 	NULL
	        push 	hInstance
	        push 	EditID
	        push 	hWnd
	        push 	305
	        push 	735
	        push 	100
	        push 	20
	        push 	WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or\
	             	ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or \
	             	ES_MULTILINE or ES_READONLY 
	        push 	NULL
	        push 	offset EditClassName
	        push 	WS_EX_CLIENTEDGE
	        call 	CreateWindowEx
			mov  	hwndPrint,	eax ; Save unique window ID

		doNotCreate:


		;.ELSEIF uMsg==WM_COMMAND
		cmp 	uMsg,	WM_COMMAND
		jnz 	doNotCommandMe
			mov 	eax,	wParam
			;.IF lParam==0
			cmp 	lParam, 0
			jnz 	lParamNotZero
				;.IF  ax==IDM_GETTEXT
				cmp 	ax, 	IDM_GETTEXT
				jnz 	notIDM_GETTEXT
					;invoke GetWindowText,hwndEdit,ADDR buffer,512
					push 	512
					push 	offset buffer
					push 	hwndEdit
					call 	GetWindowText

					;invoke MessageBox,NULL,ADDR buffer,ADDR AppName,MB_OK
					;;;;; PUSH Les data nécéssaires
					; Set the given path as rootDir
				    ; invoke  crt_strcpy, addr path,addr rootDir
				    ;; On recupère la longueur de la chaine pour 
				    ;;\ savoir si le user a rajouté ou non un \ à la fin
				    push 	offset 	buffer
				    call 	lstrlen
				    ;sub eax,1
				    cmp byte ptr buffer[eax-1],'\' ;; if the user input lastchat is \
				    jz 		slashAlrdyHere
				     push 	offset slash
			         push 	offset buffer
			         call 	lstrcat

			        slashAlrdyHere:
					push 	offset buffer
					push 	offset path
					call 	lstrcpy

					; Get strlen of path
					; invoke  crt_strlen, addr path
					push 	offset 	path
					call 	lstrlen
				    
				    ; Mov effective addr of path 
				    lea     eax,[path + eax]
				    ; invoke  Find, eax
				    push 	eax
				    ;; Call core function
				    call 	Find
				    
				jmp 	notElse
				notIDM_GETTEXT:
					;invoke DestroyWindow,hqWnd
					push 	hWnd
					call 	DestroyWindow
				notElse:
			;.ELSE
			jmp 	elseOne
			lParamNotZero:
				;.IF ax==ButtonID
				cmp 	ax, ButtonID
				jnz 	notButtonId
					shr eax,16

					;.IF ax==BN_CLICKED
					cmp ax,  BN_CLICKED
					jnz notBN_CLICKED
						;invoke SendMessage,hWnd,WM_COMMAND,IDM_GETTEXT,0
						push 	0
						push 	IDM_GETTEXT
						push 	WM_COMMAND
						push 	hWnd
						call 	SendMessage
					;.ENDIF
					notBN_CLICKED:
				;.ENDIF
				notButtonId:
			;.ENDIF
			elseOne:
		;.ELSE
		doNotCommandMe:
			;invoke DefWindowProc,hWnd,uMsg,wParam,lParam
			push 	lParam
			push 	wParam
			push 	uMsg
			push 	hWnd
			call 	DefWindowProc
			ret
		;.ENDIF
		xor    eax,eax ;; sanitize data
		ret
	WndProc endp
; Programm core
;----------------------------------------------------------------------------;
;							Find function entry								 ;
;----------------------------------------------------------------------------;
; This recursive function is the core of this program. It take in entry the  ;
; ptr of the path to browse													 ;
;----------------------------------------------------------------------------;
	Find    proc    myPath:PTR BYTE

			; Local WFD structure 
	        LOCAL structFindData : WIN32_FIND_DATA

	        push    esi ; used for myPath
	        push    edi ; used for hFile HANDLE

	        mov     esi, myPath ; push myPath into the stack 
	       	

	        ;;invoke  crt_strcpy, esi, addr masqueToApply
	     	push 	offset masqueToApply
	        push 	esi
	        call 	lstrcpy

	        ; First case, find the first file of the given path
			;;invoke  FindFirstFile, addr path, addr structFindData
			lea  	ebx, 	structFindData
	        push 	ebx
	        push 	offset path
	        call 	FindFirstFile	        

	        mov     edi,	eax ; save hFile 

	        ; error gestion
	        cmp     eax, INVALID_HANDLE_VALUE
	        jz      funError

	funEntry:
	        cmp    [structFindData.dwFileAttributes], FILE_ATTRIBUTE_DIRECTORY
	        jnz    funPrintName ; is not a dir

			; Directory listing
			; Is the dir "." or ".."
	        cmp     byte ptr structFindData.cFileName[0],'.'
	        jnz     funGoDeeper ; don't start with a dot
	        
	        ;;invoke  crt_strcmp, addr dot, addr structFindData.cFileName
	        lea 	eax, structFindData.cFileName
	        push 	eax
	        push 	offset dot
	        call 	lstrcmp

	        cmp     eax,NULL
	        jz      funNextItem ; skip if eax == "."

	        ;;invoke  crt_strcmp, addr dotDot, addr structFindData.cFileName
	        lea 	eax, structFindData.cFileName
	        push 	eax
	        push 	offset dotDot
	        call 	lstrcmp

	        cmp     eax,NULL
	        jz      funNextItem ; skip if eax == ".."

	funGoDeeper:	
			; Concatenation of myPath and the new dir 
	        ;;invoke  crt_strcpy, esi, addr structFindData.cFileName
	        lea  	eax, structFindData.cFileName
	        push 	eax
	        push 	esi
	        call 	lstrcpy

	        ;;invoke  crt_strcat, esi, addr slash
	        push 	offset slash
	        push 	esi
	        call 	lstrcat
	        
	        ;;invoke  crt_strlen, esi ; myPath length
	        push 	esi
	        call 	lstrlen
	        lea     eax,[esi + eax] ; myPath + strlen(myPath)
	        ; Recursive loop 
	        ;; invoke  Find, eax
	        push 	eax
	        call 	Find      

	        jmp     funNextItem

	funPrintName:
			; Concatene path and next file name
	       ;;invoke  crt_strcpy, esi, addr structFindData.cFileName
	        lea  	eax, structFindData.cFileName
	        push 	eax
	        push 	esi
	        call 	lstrcpy

	      	;invoke SetWindowText,hwndPrint,offset path
	      	push 	offset path
	      	call 	print_text
	      	push 	offset endLine
	      	call 	print_text

	; Next File/Directory
	funNextItem:
	        ;invoke FindNextFile, edi, addr structFindData
			lea  	ebx, structFindData
	        push 	ebx
	        push 	edi
	        call 	FindNextFile	

	        or      eax,eax
	        jnz     funEntry

	        ;;invoke  FindClose, edi
	        push 	edi
	        call 	FindClose
	; Exit and error routine 
	funError:
			; free register and leave the current loop
	        pop     edi
	        pop     esi
	        ret
	Find    endp
;----------------------------------------------------------------------------;
;							print_text function entry						 ;
;----------------------------------------------------------------------------;
; This function use the function SendMessage to write into the textbox buff  ;
;----------------------------------------------------------------------------;
	print_text proc buff:DWORD
		LOCAL 	wparam:WPARAM
		LOCAL 	lparam:LPARAM
		
		push 	hwndPrint
		call 	GetWindowTextLength
		mov  	wparam, eax
		mov  	lparam, eax
		push 	hwndPrint
		call 	SetFocus

		push 	wparam
		push 	lparam
		push 	EM_SETSEL
		push 	hwndPrint
		call 	SendMessage

		push 	buff 
		push 	NULL
		push 	EM_REPLACESEL
		push 	hwndPrint
		call 	SendMessage

		ret
	print_text endp
end start