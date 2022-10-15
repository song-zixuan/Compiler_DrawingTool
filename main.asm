; Author: Wang Zhao
; Create Time: 2016-03-20 20:31

TITLE DrawingTool Application

.386 
.model flat,stdcall 
option casemap:none

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

INCLUDE windows.inc
INCLUDE user32.inc
INCLUDE kernel32.inc
INCLUDE gdi32.inc
INCLUDE comdlg32.inc

INCLUDELIB user32.lib
INCLUDELIB kernel32.lib
INCLUDELIB gdi32.lib
INCLUDELIB comdlg32.lib



;======================== DATA ========================
.data


; 各种编号
IDM_OPT2  dw 302
IDM_OPT3  dw 303

IDM_DRAW  dw 401
IDM_ERASE dw 402

IDB_ONE   dw 3301

; 菜单字符串
fileMenuStr db "文件", 0
loadMenuStr db "打开", 0
saveMenuStr db "保存", 0

fileMenuStr1 db "绘图", 0
drawMenuStr db "画图", 0
eraseMenuStr db "擦除", 0

; 按钮字符串
lineButtonStr db "直线", 0

; 类名以及程序名
className db "DrawingWinClass", 0
appName db "画图", 0

; 句柄等变量
hInstance HINSTANCE ?
hMenu HMENU ?
commandLine LPSTR ?

; 杂项
buttonStr db "Button", 0
beginX dd 0
beginY dd 0
endX dd 0
endY dd 0

curX dd 0
curY dd 0

pointX dd 0
pointY dd 0
drawingFlag db 0
erasingFlag db 0
; 画图/擦除模式
mode db 0

; 工作区域
workRegion RECT <0, 0, 800, 600>

; 结构体定义
PAINTDATA STRUCT
	ptBeginX dd ?
	ptBeginY dd ?
	ptEndX   dd ?
	ptEndY   dd ?
	penStyle dd ?
PAINTDATA ENDS

; 保存有关
filetype1 byte "BMP(*.bmp)", 0 ,"*.bmp", 0, 0
filetype2 byte "BMP(*.bmp)", 0, 0
finalname byte "bmp", 0
fileHandle DWORD ?
; szFileName BYTE "painting.bmp", 0
szFileName	db	MAX_PATH DUP (?)
szTitleName	db	MAX_PATH DUP (?)
ofn OPENFILENAME <>
;======================== CODE ========================
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
	LOCAL popFile: HMENU
	LOCAL popFile1: HMENU

	INVOKE CreateMenu ; initially empty,can be filled with menu items by using the InsertMenuItem, AppendMenu, and InsertMenu functions.
	.IF eax == 0
		ret
	.ENDIF
	mov hMenu, eax

	INVOKE CreatePopupMenu; Creates a drop-down menu, submenu, or shortcut menu
	mov popFile, eax ; 顶部栏目第一个（“文件”）

	INVOKE CreatePopupMenu;顶部栏目第二个（"绘图"）
	mov popFile1, eax
	
	INVOKE AppendMenu, hMenu, MF_POPUP, popFile, ADDR fileMenuStr ;把文件俩字放进对应位置

	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT2, ADDR loadMenuStr ;在文件的菜单底下加“打开”
	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT3, ADDR saveMenuStr ;在文件的菜单底下加“保存”

	INVOKE AppendMenu, hMenu, MF_POPUP, popFile1, ADDR fileMenuStr1 ;把绘图俩字放进对应位置
	
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_DRAW, ADDR drawMenuStr ; 在绘图的菜单底下加“画图”
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_ERASE, ADDR eraseMenuStr ; 在绘图的菜单底下加“擦除”

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
	mov wc.style, CS_HREDRAW or CS_VREDRAW ; CS_HREDRAW：一旦移动或尺寸调整使客户区的宽度发生变化，就重新绘制窗口;
  ; ⑵CS_VREDRAW：一旦移动或尺寸调整使客户区的高度发生变化，就重新绘制窗口。 这里取两者兼并
	mov wc.lpfnWndProc, OFFSET WndProc ; 窗口处理函数的指针
	mov wc.cbClsExtra, NULL; 为窗口类的额外信息做记录，初始化为0。
	mov wc.cbWndExtra, NULL; 记录窗口实例的额外信息，系统初始为0
	push hInst
	pop wc.hInstance;本模块的实例句柄
	mov wc.hbrBackground, COLOR_WINDOW+1;窗口类的背景刷，为背景刷句柄
	mov wc.lpszMenuName, NULL;指向菜单的指针
	mov wc.lpszClassName, OFFSET className;指向类名称的指针
	INVOKE LoadIcon, NULL, IDI_APPLICATION;从与应用程序实例关联的可执行文件 (.exe) 加载指定的图标资源。
	mov wc.hIcon, eax;窗口类的图标，为图标资源句柄
	mov wc.hIconSm, eax;小图标的句柄，在任务栏显示的图标
	INVOKE LoadCursor, NULL, IDC_ARROW;从与应用程序实例关联的可执行 (.EXE) 文件中加载指定的游标资源。
	mov wc.hCursor, eax;类游标的句柄

	INVOKE RegisterClassEx, ADDR wc;用wc注册窗口类(由于上面的参数已经注册完成了)
	INVOKE CreateWindowEx, NULL, ADDR className, ADDR appName, \
		WS_OVERLAPPEDWINDOW AND (NOT WS_SIZEBOX) AND (NOT WS_MAXIMIZEBOX) AND (NOT WS_MINIMIZEBOX), CW_USEDEFAULT, \
		CW_USEDEFAULT, 800, 600, NULL, hMenu, \
		hInst, NULL ;应该是创建窗口？
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



WndProc PROC USES ebx ecx edx,
	hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM
	LOCAL hdc: HDC
	LOCAL hbuf: HDC
	LOCAL hdcMem: HDC
	LOCAL hBitmap: HBITMAP
	LOCAL ps: PAINTSTRUCT
	LOCAL rect: RECT
	LOCAL lowordWParam: WORD
	LOCAL p: POINT
	LOCAL bmfh: BITMAPFILEHEADER
	LOCAL bmih: BITMAPINFOHEADER
	LOCAL nColorLen: DWORD
    LOCAL dwRgbQuadSize: DWORD
    LOCAL dwBmSize: DWORD
    LOCAL hMem: HGLOBAL
    LOCAL lpbi: DWORD   
    LOCAL bm: BITMAP
    LOCAL hFile: HANDLE
    LOCAL dwWritten: DWORD

	.IF uMsg == WM_DESTROY ;退出程序
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_COMMAND	; 响应事件
		mov ebx, wParam
		.IF bx == IDB_ONE
			;INVOKE ShowWindow, hWnd, SW_HIDE
		.ELSEIF bx == IDM_DRAW  ; 画图模式
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; 擦除模式
			mov mode,1
		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16 ; edx and ebx存储当前鼠标x和y的位置

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
			; ebx = pen
			;INVOKE CreatePen, PS_SOLID, 1, 0
			;mov ebx, eax
			INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
			INVOKE LineTo, ps.hdc, endX, endY
			;INVOKE DeleteObject, ebx
		.ENDIF
		.IF mode == 1 ; erasing mode
			.IF erasingFlag == 1
				;INVOKE RGB,0,0,0
				;INVOKE SetDCBrushColor, ps.hdc, 0
				INVOKE GetStockObject, NULL_PEN
				INVOKE SelectObject, ps.hdc, eax; ps.hdc:handle to the display DC to be used for painting.

        ; to create a rectangle space
				sub curX, 10
				sub curY, 10
				mov ebx, curX
				mov edx, curY
				add ebx, 20
				add edx, 20
				
				INVOKE Rectangle, ps.hdc, curX, curY, ebx, edx ; use ps.hec to paint this rectangle
			.ENDIF
		.ENDIF

		INVOKE EndPaint, hWnd, ADDR ps;marks the end of painting in the specified window
	.ELSE
		INVOKE DefWindowProc, hWnd, uMsg, wParam, lParam
		ret
	.ENDIF

	xor eax, eax
	ret
WndProc ENDP

end start
