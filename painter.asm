TITLE PaintingTool

.386 
.model flat,stdcall 
option casemap:none

WinMain proto :dword, :dword, :dword, :dword

INCLUDE windows.inc
INCLUDE user32.inc
INCLUDE kernel32.inc
INCLUDE gdi32.inc
INCLUDE comdlg32.inc

INCLUDELIB user32.lib
INCLUDELIB kernel32.lib
INCLUDELIB gdi32.lib
INCLUDELIB comdlg32.lib



.data

PenWidth DWORD 1
;Color
CurrentColor dd 000h
CustomColor dd 16 DUP(0)

PenStyle DWORD PS_SOLID ;PS_SOLID == 0
EraserRadius DWORD 10
PainterRadius DWORD 1

IDM_OPEN dw 1012
IDM_SAVE dw 1013

IDM_DRAW  dw 1014
IDM_ERASE dw 1015

IDM_DRAWSIZE dw 1016
IDM_ERASESIZE dw 1017

IDD_DIALOG1 dw 101
IDD_DIALOG2 dw 103

IDC_EDIT1  dw 1001 ;erazersize
IDC_EDIT2  dw 1002 ;paintersize
IDI_ICON1  dw  102
IDI_ICON2  dw  104

IDM_COLOR dw 601

fileMenuStr db "文件", 0
loadMenuStr db "打开", 0
saveMenuStr db "保存", 0

fileMenuStr1 db "绘图", 0
drawMenuStr db "画图", 0
eraseMenuStr db "擦除", 0

fileMenuStr2 db "大小", 0
drawSizeStr db "画笔大小", 0
eraseSizeStr db "橡皮大小", 0

fileMenuStr3 db "颜色", 0
colorStr db "选择颜色", 0

; 类名以及程序名
className db "DrawingWinClass", 0
appName db "画图板", 0

;handle
hInstance HINSTANCE ?
hMenu HMENU ?
commandLine LPSTR ?

; 鼠标信息相关
beginX dd 0
beginY dd 0
endX dd 0
endY dd 0

curX dd 0
curY dd 0

drawingFlag db 0
erasingFlag db 0
; 画图/擦除模式
mode db 0

workRegion RECT <0, 0, 800, 600>

; 长宽
bmpLength dw 541
bmpWidth dw 784

;文件相关
bmpFile OPENFILENAME <>  ;bmp文件
fileOpenExtension byte "BMP(*.bmp)", 0, "*.bmp", 0, 0
fileSaveExtension byte "BMP(*.bmp)", 0, 0
fileName byte "bmp", 0
fileHandle dword ?
bmpFileName db MAX_PATH DUP(?)
bmpTitleName db MAX_PATH DUP(?)

.code

start:
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	INVOKE GetCommandLine
	mov commandLine, eax
	INVOKE WinMain, hInstance, NULL, commandLine, SW_SHOWDEFAULT
	INVOKE ExitProcess, eax

; 创建菜单
createMenu PROC
	LOCAL topMenu1: HMENU
	LOCAL topMenu2: HMENU
	LOCAL topMenu3: HMENU
	LOCAL topMenu4: HMENU

	INVOKE CreateMenu          ; initially empty,can be filled with menu items by using the InsertMenuItem, AppendMenu, and InsertMenu functions.
	.IF eax == 0
		ret
	.ENDIF
	mov hMenu, eax

	INVOKE CreatePopupMenu      ; Creates a drop-down menu, submenu, or shortcut menu
	mov topMenu1, eax           ; 顶部栏目第一个（“文件”）

	INVOKE CreatePopupMenu      ;顶部栏目第二个（"绘图"）
	mov topMenu2, eax

	INVOKE CreatePopupMenu      ;顶部栏目第二个（"大小"）
	mov topMenu3, eax

	INVOKE CreatePopupMenu       ;顶部栏目第三个（“颜色”）
	mov topMenu4, eax



	
	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu1, ADDR fileMenuStr ;把文件俩字放进对应位置

	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_OPEN, ADDR loadMenuStr ;在文件的菜单底下加“打开”
	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_SAVE, ADDR saveMenuStr ;在文件的菜单底下加“保存”

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu2, ADDR fileMenuStr1 ;把绘图俩字放进对应位置
	
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_DRAW, ADDR drawMenuStr ; 在绘图的菜单底下加“画图”
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_ERASE, ADDR eraseMenuStr ; 在绘图的菜单底下加“擦除”

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu3, ADDR fileMenuStr2 ;把大小俩字放进对应位置

	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_DRAWSIZE, ADDR drawSizeStr ; 在大小的菜单底下加“画笔大小”
	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_ERASESIZE, ADDR eraseSizeStr ; 在大小的菜单底下加“橡皮大小”

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu4, ADDR fileMenuStr3 ; 把颜色俩字放进对应位置
	
	INVOKE AppendMenu, topMenu4, MF_STRING, IDM_COLOR, ADDR colorStr ;在颜色菜单底下加“选择颜色”

	ret
createMenu ENDP

WinMain PROC,
	hInst: HINSTANCE, hPrevInst: HINSTANCE, CmdLine: LPSTR, CmdShow: DWORD
	LOCAL wc: WNDCLASSEX
	LOCAL msg: MSG
	LOCAL hwnd: HWND

	INVOKE createMenu


	;注册窗口的参数
	mov wc.cbSize, SIZEOF WNDCLASSEX ; 结构体大小
	mov wc.style, CS_HREDRAW or CS_VREDRAW 
							; CS_HREDRAW：一旦移动或尺寸调整使客户区的宽度发生变化，就重新绘制窗口;
							; CS_VREDRAW：一旦移动或尺寸调整使客户区的高度发生变化，就重新绘制窗口。 这里取两者兼并
	mov wc.lpfnWndProc, OFFSET WndProc ; 窗口处理函数的指针
	mov wc.cbClsExtra, NULL; 为窗口类的额外信息做记录，初始化为0。
	mov wc.cbWndExtra, NULL; 记录窗口实例的额外信息，系统初始为0
	push hInst
	pop wc.hInstance;本模块的实例句柄
	mov wc.hbrBackground, COLOR_WINDOW+1;窗口类的背景刷，为背景刷句柄
	mov wc.lpszMenuName, NULL;指向菜单的指针
	mov wc.lpszClassName, OFFSET className;指向类名称的指针
	;INVOKE LoadIcon, NULL, IDI_APPLICATION;从与应用程序实例关联的可执行文件 (.exe) 加载指定的图标资源。
	INVOKE LoadIcon, NULL, IDI_ICON2
	mov wc.hIcon, eax;窗口类的图标，为图标资源句柄
	mov wc.hIconSm, eax;小图标的句柄，在任务栏显示的图标
	INVOKE LoadCursor, NULL, IDC_ARROW;从与应用程序实例关联的可执行 (.EXE) 文件中加载指定的游标资源。
	mov wc.hCursor, eax;类游标的句柄

	INVOKE RegisterClassEx, ADDR wc        ;用wc注册窗口类(由于上面的参数已经注册完成了)
	INVOKE CreateWindowEx, NULL, ADDR className, ADDR appName, \
		WS_OVERLAPPEDWINDOW AND (NOT WS_SIZEBOX) AND (NOT WS_MAXIMIZEBOX) AND (NOT WS_MINIMIZEBOX), CW_USEDEFAULT, \
		CW_USEDEFAULT, 800, 600, NULL, hMenu, \
		hInst, NULL ;
	mov hwnd, eax
	INVOKE ShowWindow, hwnd, SW_SHOWNORMAL;创建窗口（也就是把画图的窗口弹出来）
	INVOKE UpdateWindow, hwnd;更新指定窗口的客户区
	.WHILE TRUE
		INVOKE GetMessage, ADDR msg, NULL, 0, 0
		.BREAK .IF (!eax)
			INVOKE TranslateMessage, ADDR msg
		INVOKE DispatchMessage, ADDR msg
	.ENDW
	mov eax, msg.wParam
	ret
WinMain ENDP

setEraserRadius PROC hWnd:HWND,wParam:WPARAM,lParam:LPARAM
    mov ebx,wParam
    and ebx,0ffffh
    .IF ebx == IDOK
        invoke GetDlgItemInt,hWnd,IDC_EDIT1, NULL, 0
		.IF eax >= 10 && eax <= 40
			mov EraserRadius, eax
		.ENDIF
        invoke EndDialog,hWnd,wParam
    .ELSEIF ebx == IDCANCEL
        invoke EndDialog,hWnd,wParam
        mov eax,TRUE
    .ENDIF
    ret
setEraserRadius ENDP

setEraserSizeDialog PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    mov ebx,uMsg
    .IF ebx == WM_COMMAND
        invoke setEraserRadius,hWnd,wParam,lParam
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor eax,eax 
    ret
setEraserSizeDialog endp

setEraserSize PROC, hWnd:HWND
	invoke DialogBoxParam, hInstance, IDD_DIALOG1 ,hWnd, OFFSET setEraserSizeDialog, 0
	ret
setEraserSize ENDP





setPainterRadius PROC hWnd:HWND,wParam:WPARAM,lParam:LPARAM
    mov ebx,wParam
    and ebx,0ffffh
    .IF ebx == IDOK
        invoke GetDlgItemInt,hWnd,IDC_EDIT2, NULL, 0
		.IF eax >= 1 && eax <= 10
			mov PainterRadius, eax
		.ENDIF
        invoke EndDialog,hWnd,wParam
    .ELSEIF ebx == IDCANCEL
        invoke EndDialog,hWnd,wParam
        mov eax,TRUE
    .ENDIF
    ret
setPainterRadius ENDP

setPainterSizeDialog PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    mov ebx,uMsg
    .IF ebx == WM_COMMAND
        invoke setPainterRadius,hWnd,wParam,lParam
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor eax,eax 
    ret
setPainterSizeDialog endp

setPainterSize PROC hWnd:HWND
	invoke DialogBoxParam, hInstance, IDD_DIALOG2 ,hWnd, OFFSET setPainterSizeDialog, 0
	ret
setPainterSize ENDP


IChooseColor PROC hWnd:HWND
	local cc:CHOOSECOLOR
	push eax
	push ecx
	invoke RtlZeroMemory, addr cc, sizeof cc
	mov	cc.lStructSize,sizeof cc
	push hWnd
	pop cc.hwndOwner
	push hInstance
	pop cc.hInstance
	mov cc.rgbResult,0
	push offset CustomColor
	pop cc.lpCustColors
	mov	cc.Flags, CC_RGBINIT or CC_FULLOPEN
	invoke	ChooseColor,addr cc
	.if	eax
	push cc.rgbResult
	pop	CurrentColor
	.endif
	pop ecx
	pop eax
	ret
IChooseColor ENDP

Paintevent PROC USES ecx,
	hWnd:HWND,wParam:WPARAM,lParam:LPARAM,ps:PAINTSTRUCT
	local hPen: HPEN
	;extern CurrentMode:DWORD ;供不同绘图模式使用，备用
	push ecx
	INVOKE CreatePen, PS_SOLID, PainterRadius, CurrentColor
	mov hPen, eax
	INVOKE SelectObject, ps.hdc, hPen

	INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
	INVOKE LineTo, ps.hdc, endX, endY
	;INVOKE MoveToEx, ps.hdc, 0, 0, NULL; to be decided

	INVOKE DeleteObject, hPen
	pop ecx
	ret
Paintevent ENDP

WndProc PROC USES ebx ecx edx,
	hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM
	LOCAL hdc: HDC
	LOCAL hdcMem: HDC
	LOCAL hbm: HBITMAP
	LOCAL bm: BITMAP
	LOCAL BMIH: BITMAPINFOHEADER
	LOCAL BMFH: BITMAPFILEHEADER
	LOCAL colorNum: DWORD
	LOCAL rgbQuadSize:DWORD
	LOCAL bmSize:DWORD
	LOCAL fileMem:HGLOBAL
	LOCAL lpbi:DWORD;
	LOCAL numWritten:DWORD
	LOCAL ps: PAINTSTRUCT


	.IF uMsg == WM_DESTROY ;退出程序
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_COMMAND	; 响应事件
		mov ebx, wParam
		.IF bx == IDM_DRAW  ; 画图模式
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; 擦除模式
			mov mode,1
		.ELSEIF bx == IDM_DRAWSIZE ; 自定义画笔大小
			INVOKE setPainterSize, hWnd
		.ELSEIF bx == IDM_ERASESIZE; 自定义橡皮大小
			INVOKE setEraserSize, hWnd
        .ELSEIF bx == IDM_OPEN     ;打开文件
			push edx               ;配置bmp文件信息和格式
			mov bmpFile.hwndOwner, NULL
			mov bmpFile.nFilterIndex, 1
			mov bmpFile.lpstrFileTitle, NULL
			mov bmpFile.nMaxFileTitle, 0
			mov bmpFile.lpstrInitialDir, NULL ;
			mov bmpFile.Flags,  OFN_PATHMUSTEXIST AND OFN_FILEMUSTEXIST

			mov edx, sizeof bmpFile
			mov bmpFile.lStructSize, edx
			mov bmpFile.lpstrFile, OFFSET bmpFileName;			
			mov edx, sizeof bmpFileName
			mov bmpFile.nMaxFile, edx
			mov bmpFile.lpstrFilter, OFFSET fileOpenExtension
			pop edx
			INVOKE GetOpenFileName, ADDR bmpFile
			INVOKE GetDC, hWnd
			mov hdc, eax
			invoke CreateCompatibleDC, hdc
			mov hdcMem, eax
			invoke LoadImage, NULL, ADDR bmpFileName, IMAGE_BITMAP, bmpWidth, bmpLength, LR_LOADFROMFILE
			mov hbm, eax
			invoke SelectObject, hdcMem, eax
			invoke BitBlt, hdc, 0, 0,  bmpWidth, bmpLength, hdcMem, 0, 0, SRCCOPY
			invoke DeleteObject, hbm
			invoke DeleteDC, hdcMem

		.ELSEIF bx == IDM_SAVE        ;保存文件
			push edx
			mov edx, sizeof bmpFile
			mov bmpFile.lStructSize, edx 
			mov bmpFile.lpstrFile, OFFSET bmpFileName 
			mov bmpFile.lpstrFileTitle, OFFSET bmpTitleName 
			mov edx, sizeof bmpFileName
			mov bmpFile.nMaxFile, edx
			mov bmpFile.lpstrFilter, OFFSET fileSaveExtension 
			mov bmpFile.lpstrDefExt, OFFSET fileName 
			mov bmpFile.Flags, OFN_OVERWRITEPROMPT
			pop edx
		
			INVOKE GetSaveFileName, ADDR bmpFile
			INVOKE GetDC, hWnd ;获取当前窗口句柄
			
			mov hdc, eax
			INVOKE CreateCompatibleBitmap, hdc, bmpWidth, bmpLength
			mov hbm, eax
			INVOKE CreateCompatibleDC, hdc
			mov hdcMem, eax

			INVOKE SelectObject, hdcMem, hbm 
			INVOKE BitBlt, hdcMem, 0, 0, bmpWidth, bmpLength, hdc, 0, 0, SRCCOPY
			INVOKE CreateFile,ADDR bmpFileName,GENERIC_WRITE,0,	NULL,CREATE_ALWAYS,	FILE_ATTRIBUTE_NORMAL,NULL ;创建文件
			mov fileHandle, eax
			INVOKE GetObject, hbm, (sizeof BITMAP), ADDR bm 

			push edx
			mov BMIH.biSize, (sizeof BMIH)
			mov edx, bm.bmWidth
			mov BMIH.biWidth, edx
			mov edx, bm.bmHeight
			mov BMIH.biHeight, edx
			mov BMIH.biPlanes, 1
			mov dx, bm.bmBitsPixel
			mov BMIH.biBitCount, dx
			mov BMIH.biCompression, BI_RGB
			mov BMIH.biSizeImage, 0
			mov BMIH.biXPelsPerMeter, 0
			mov BMIH.biYPelsPerMeter, 0
			mov BMIH.biClrUsed, 0 
			mov BMIH.biClrImportant, 0 
			pop edx

			pushad
			mov eax, bm.bmWidth
			mov edx, 0
			mov dx, BMIH.biBitCount
			imul eax, edx
			mov ebx, 32
			mov edx, 0
			add eax, 31
			idiv ebx
			imul eax, bm.bmHeight
			imul eax, 4
			mov bmSize, eax
			popad

			;色深小于等于8位，调色板颜色数是2的色深次方，大于8位无调色板
			pushad
			.IF bm.bmBitsPixel > 8
				push edx
				mov edx, 0
				mov colorNum, edx
				pop edx
			.ELSE
				pushad
				mov edx, 1
				mov ecx, 0
				mov cx, bm.bmBitsPixel
				shl edx, cl
				mov colorNum, edx
				popad
			.ENDIF
			mov edx, colorNum
			imul edx, sizeof RGBQUAD
			mov rgbQuadSize, edx
			popad

			pushad
			mov edx, bmSize
			add edx, sizeof BMIH
			add edx, rgbQuadSize
			INVOKE GlobalAlloc, GHND, edx
			mov fileMem, eax
			INVOKE GlobalLock, fileMem
			mov lpbi, eax

			mov ecx, sizeof BMIH
			lea ebx, BMIH
			mov edx, lpbi

		L1:
			mov eax, [ebx]
			mov [edx], eax
			add ebx, TYPE DWORD
			add edx, TYPE DWORD
			loop L1
			popad
	
			mov edx, lpbi
			add edx, sizeof BMIH
			add edx, rgbQuadSize
			INVOKE GetDIBits, hdc, hbm, 0, BMIH.biHeight, edx, lpbi, DIB_RGB_COLORS

			push edx
			mov BMFH.bfType, 4D42h
			mov edx, sizeof BMFH
			add edx, sizeof BMIH
			add edx, rgbQuadSize
			mov BMFH.bfOffBits, edx
			add edx, bmSize
			mov BMFH.bfSize, edx
			mov BMFH.bfReserved1, 0
			mov BMFH.bfReserved2, 0
			pop edx

			INVOKE WriteFile, fileHandle, ADDR BMFH, sizeof BMFH, ADDR numWritten, NULL
			push edx
			mov edx, BMFH.bfSize
			sub edx, sizeof BMFH
			INVOKE WriteFile, fileHandle, lpbi, edx, ADDR numWritten, NULL
			pop edx
			INVOKE GlobalFree, fileMem
			INVOKE CloseHandle, fileHandle

		.ELSEIF bx == IDM_COLOR;
			INVOKE IChooseColor, hWnd; 更改颜色
		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16               ; edx and ebx存储当前鼠标x和y的位置

		mov curX, edx
		mov curY, ebx
		.IF mode == 0    ;drawing mode
			.IF drawingFlag == 1; 鼠标左键按下会变成1。抬起会变成0
				.IF endX == 0
					mov beginX, edx ;鼠标还在原始位置
				.ELSE
					mov eax, endX
					mov beginX, eax ;鼠标移动到end位置
				.ENDIF

				.IF endY == 0
					mov beginY, ebx
				.ELSE
					mov eax, endY
					mov beginY, eax
				.ENDIF

				mov endX, edx
				mov endY, ebx ;鼠标位置更新
				INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
			.ENDIF
		.ENDIF

		.IF mode == 1 ; Erasing mode
			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0

		.ENDIF
		
	.ELSEIF uMsg == WM_LBUTTONDOWN
		mov drawingFlag, 1
		mov erasingFlag, 1
	.ELSEIF uMsg == WM_LBUTTONUP
		mov drawingFlag, 0
		mov erasingFlag, 0
		mov beginX, 0
		mov beginY, 0
		mov endX, 0
		mov endY, 0
	.ELSEIF uMsg == WM_PAINT
		INVOKE BeginPaint, hWnd, ADDR ps ;LOCAL ps: PAINTSTRUCT
		.IF mode == 0 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
			;INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
			;INVOKE LineTo, ps.hdc, endX, endY
		.ENDIF
		.IF mode == 1 ; erasing mode
			.IF erasingFlag == 1
				INVOKE GetStockObject, NULL_PEN
				INVOKE SelectObject, ps.hdc, eax; ps.hdc:handle to the display DC to be used for painting.
				; to create a rectangle space
				mov eax, EraserRadius
				sub curX, eax
				sub curY, eax
				mov ebx, curX
				mov edx, curY
				add ebx, eax
				add edx, eax
				add ebx, eax
				add edx, eax
				INVOKE Rectangle, ps.hdc, curX, curY, ebx, edx   ; use ps.hec to paint this rectangle
			.ENDIF
		.ENDIF

		INVOKE EndPaint, hWnd, ADDR ps                           ; marks the end of painting in the specified window
	.ELSE
		INVOKE DefWindowProc, hWnd, uMsg, wParam, lParam
		ret
	.ENDIF

	xor eax, eax
	ret
WndProc ENDP

end start