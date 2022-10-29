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

IDM_OPEN dw 1012
IDM_SAVE dw 1013

IDM_DRAW  dw 1014
IDM_ERASE dw 1015

IDM_DRAWSIZE dw 1016
IDM_ERASESIZE dw 1017

IDD_DIALOG1 dw 101
IDC_EDIT1  dw 1001
IDI_ICON1  dw  102
IDI_ICON2  dw  104

IDM_COLOR dw 601

fileMenuStr db "�ļ�", 0
loadMenuStr db "��", 0
saveMenuStr db "����", 0

fileMenuStr1 db "��ͼ", 0
drawMenuStr db "��ͼ", 0
eraseMenuStr db "����", 0

fileMenuStr2 db "��С", 0
drawSizeStr db "���ʴ�С", 0
eraseSizeStr db "��Ƥ��С", 0

fileMenuStr3 db "��ɫ", 0
colorStr db "ѡ����ɫ", 0

; �����Լ�������
className db "DrawingWinClass", 0
appName db "��ͼ��", 0

;handle
hInstance HINSTANCE ?
hMenu HMENU ?
commandLine LPSTR ?

; �����Ϣ���
beginX dd 0
beginY dd 0
endX dd 0
endY dd 0

curX dd 0
curY dd 0

drawingFlag db 0
erasingFlag db 0
; ��ͼ/����ģʽ
mode db 0

workRegion RECT <0, 0, 800, 600>

.code

start:
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	INVOKE GetCommandLine
	mov commandLine, eax
	INVOKE WinMain, hInstance, NULL, commandLine, SW_SHOWDEFAULT
	INVOKE ExitProcess, eax

; �����˵�
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
	mov topMenu1, eax           ; ������Ŀ��һ�������ļ�����

	INVOKE CreatePopupMenu      ;������Ŀ�ڶ�����"��ͼ"��
	mov topMenu2, eax

	INVOKE CreatePopupMenu      ;������Ŀ�ڶ�����"��С"��
	mov topMenu3, eax

	INVOKE CreatePopupMenu       ;������Ŀ������������ɫ����
	mov topMenu4, eax



	
	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu1, ADDR fileMenuStr ;���ļ����ַŽ���Ӧλ��

	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_OPEN, ADDR loadMenuStr ;���ļ��Ĳ˵����¼ӡ��򿪡�
	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_SAVE, ADDR saveMenuStr ;���ļ��Ĳ˵����¼ӡ����桱

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu2, ADDR fileMenuStr1 ;�ѻ�ͼ���ַŽ���Ӧλ��
	
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_DRAW, ADDR drawMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ���ͼ��
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_ERASE, ADDR eraseMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ�������

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu3, ADDR fileMenuStr2 ;�Ѵ�С���ַŽ���Ӧλ��

	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_DRAWSIZE, ADDR drawSizeStr ; �ڴ�С�Ĳ˵����¼ӡ����ʴ�С��
	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_ERASESIZE, ADDR eraseSizeStr ; �ڴ�С�Ĳ˵����¼ӡ���Ƥ��С��

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu4, ADDR fileMenuStr3 ; ����ɫ���ַŽ���Ӧλ��
	
	INVOKE AppendMenu, topMenu4, MF_STRING, IDM_COLOR, ADDR colorStr ;����ɫ�˵����¼ӡ�ѡ����ɫ��

	ret
createMenu ENDP

WinMain PROC,
	hInst: HINSTANCE, hPrevInst: HINSTANCE, CmdLine: LPSTR, CmdShow: DWORD
	LOCAL wc: WNDCLASSEX
	LOCAL msg: MSG
	LOCAL hwnd: HWND

	INVOKE createMenu


	;ע�ᴰ�ڵĲ���
	mov wc.cbSize, SIZEOF WNDCLASSEX ; �ṹ���С
	mov wc.style, CS_HREDRAW or CS_VREDRAW 
							; CS_HREDRAW��һ���ƶ���ߴ����ʹ�ͻ����Ŀ�ȷ����仯�������»��ƴ���;
							; CS_VREDRAW��һ���ƶ���ߴ����ʹ�ͻ����ĸ߶ȷ����仯�������»��ƴ��ڡ� ����ȡ���߼沢
	mov wc.lpfnWndProc, OFFSET WndProc ; ���ڴ�������ָ��
	mov wc.cbClsExtra, NULL; Ϊ������Ķ�����Ϣ����¼����ʼ��Ϊ0��
	mov wc.cbWndExtra, NULL; ��¼����ʵ���Ķ�����Ϣ��ϵͳ��ʼΪ0
	push hInst
	pop wc.hInstance;��ģ���ʵ�����
	mov wc.hbrBackground, COLOR_WINDOW+1;������ı���ˢ��Ϊ����ˢ���
	mov wc.lpszMenuName, NULL;ָ��˵���ָ��
	mov wc.lpszClassName, OFFSET className;ָ�������Ƶ�ָ��
	;INVOKE LoadIcon, NULL, IDI_APPLICATION;����Ӧ�ó���ʵ�������Ŀ�ִ���ļ� (.exe) ����ָ����ͼ����Դ��
	INVOKE LoadIcon, NULL, IDI_ICON2
	mov wc.hIcon, eax;�������ͼ�꣬Ϊͼ����Դ���
	mov wc.hIconSm, eax;Сͼ��ľ��������������ʾ��ͼ��
	INVOKE LoadCursor, NULL, IDC_ARROW;����Ӧ�ó���ʵ�������Ŀ�ִ�� (.EXE) �ļ��м���ָ�����α���Դ��
	mov wc.hCursor, eax;���α�ľ��

	INVOKE RegisterClassEx, ADDR wc        ;��wcע�ᴰ����(��������Ĳ����Ѿ�ע�������)
	INVOKE CreateWindowEx, NULL, ADDR className, ADDR appName, \
		WS_OVERLAPPEDWINDOW AND (NOT WS_SIZEBOX) AND (NOT WS_MAXIMIZEBOX) AND (NOT WS_MINIMIZEBOX), CW_USEDEFAULT, \
		CW_USEDEFAULT, 800, 600, NULL, hMenu, \
		hInst, NULL ;
	mov hwnd, eax
	INVOKE ShowWindow, hwnd, SW_SHOWNORMAL;�������ڣ�Ҳ���ǰѻ�ͼ�Ĵ��ڵ�������
	INVOKE UpdateWindow, hwnd;����ָ�����ڵĿͻ���
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
	;extern CurrentMode:DWORD ;����ͬ��ͼģʽʹ�ã�����
	push ecx
	INVOKE CreatePen, PS_SOLID, 1, CurrentColor
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
	LOCAL ps: PAINTSTRUCT


	.IF uMsg == WM_DESTROY ;�˳�����
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_COMMAND	; ��Ӧ�¼�
		mov ebx, wParam
		.IF bx == IDM_DRAW  ; ��ͼģʽ
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; ����ģʽ
			mov mode,1
		.ELSEIF bx == IDM_DRAWSIZE ; �Զ��廭�ʴ�С

		.ELSEIF bx == IDM_ERASESIZE; �Զ�����Ƥ��С
			INVOKE setEraserSize, hWnd
        .ELSEIF bx == IDM_OPEN ; ��bmp�ļ�

		.ELSEIF bx == IDM_SAVE; ����bmpͼƬ

		.ELSEIF bx == IDM_COLOR;
			INVOKE IChooseColor, hWnd; ������ɫ
		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��

		mov curX, edx
		mov curY, ebx
		.IF mode == 0    ;drawing mode
			.IF drawingFlag == 1; ���������»���1��̧�����0
				.IF endX == 0
					mov beginX, edx ;��껹��ԭʼλ��
				.ELSE
					mov eax, endX
					mov beginX, eax ;����ƶ���endλ��
				.ENDIF

				.IF endY == 0
					mov beginY, ebx
				.ELSE
					mov eax, endY
					mov beginY, eax
				.ENDIF

				mov endX, edx
				mov endY, ebx ;���λ�ø���
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