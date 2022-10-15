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


; ���ֱ��
IDM_OPT2  dw 302
IDM_OPT3  dw 303

IDM_DRAW  dw 401
IDM_ERASE dw 402

IDM_DRAWSIZE dw 501
IDM_ERASESIZE dw 502

IDB_ONE   dw 3301

; �˵��ַ���
fileMenuStr db "�ļ�", 0
loadMenuStr db "��", 0
saveMenuStr db "����", 0

fileMenuStr1 db "��ͼ", 0
drawMenuStr db "��ͼ", 0
eraseMenuStr db "����", 0

fileMenuStr2 db "�Զ���", 0
drawSizeStr db "���ʴ�С", 0
eraseSizeStr db "��Ƥ��С", 0


; ��ť�ַ���
lineButtonStr db "ֱ��", 0

; �����Լ�������
className db "DrawingWinClass", 0
appName db "��ͼ", 0

; ����ȱ���
hInstance HINSTANCE ?
hMenu HMENU ?
commandLine LPSTR ?

; ����
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
; ��ͼ/����ģʽ
mode db 0

; ��������
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
	LOCAL popFile: HMENU
	LOCAL popFile1: HMENU
	LOCAL popFile2: HMENU

	INVOKE CreateMenu ; initially empty,can be filled with menu items by using the InsertMenuItem, AppendMenu, and InsertMenu functions.
	.IF eax == 0
		ret
	.ENDIF
	mov hMenu, eax

	INVOKE CreatePopupMenu; Creates a drop-down menu, submenu, or shortcut menu
	mov popFile, eax ; ������Ŀ��һ�������ļ�����

	INVOKE CreatePopupMenu;������Ŀ�ڶ�����"��ͼ"��
	mov popFile1, eax

	INVOKE CreatePopupMenu;������Ŀ�ڶ�����"�Զ���"��
	mov popFile2, eax


	
	INVOKE AppendMenu, hMenu, MF_POPUP, popFile, ADDR fileMenuStr ;���ļ����ַŽ���Ӧλ��

	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT2, ADDR loadMenuStr ;���ļ��Ĳ˵����¼ӡ��򿪡�
	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT3, ADDR saveMenuStr ;���ļ��Ĳ˵����¼ӡ����桱

	INVOKE AppendMenu, hMenu, MF_POPUP, popFile1, ADDR fileMenuStr1 ;�ѻ�ͼ���ַŽ���Ӧλ��
	
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_DRAW, ADDR drawMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ���ͼ��
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_ERASE, ADDR eraseMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ�������

	INVOKE AppendMenu, hMenu, MF_POPUP, popFile2, ADDR fileMenuStr2 ;�ѻ�ͼ���ַŽ���Ӧλ��

	INVOKE AppendMenu, popFile2, MF_STRING, IDM_DRAWSIZE, ADDR drawSizeStr ; �ڻ�ͼ�Ĳ˵����¼ӡ���ͼ��
	INVOKE AppendMenu, popFile2, MF_STRING, IDM_ERASESIZE, ADDR eraseSizeStr ; �ڻ�ͼ�Ĳ˵����¼ӡ�������

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
	mov wc.style, CS_HREDRAW or CS_VREDRAW ; CS_HREDRAW��һ���ƶ���ߴ����ʹ�ͻ����Ŀ�ȷ����仯�������»��ƴ���;
  ; ��CS_VREDRAW��һ���ƶ���ߴ����ʹ�ͻ����ĸ߶ȷ����仯�������»��ƴ��ڡ� ����ȡ���߼沢
	mov wc.lpfnWndProc, OFFSET WndProc ; ���ڴ�������ָ��
	mov wc.cbClsExtra, NULL; Ϊ������Ķ�����Ϣ����¼����ʼ��Ϊ0��
	mov wc.cbWndExtra, NULL; ��¼����ʵ���Ķ�����Ϣ��ϵͳ��ʼΪ0
	push hInst
	pop wc.hInstance;��ģ���ʵ�����
	mov wc.hbrBackground, COLOR_WINDOW+1;������ı���ˢ��Ϊ����ˢ���
	mov wc.lpszMenuName, NULL;ָ��˵���ָ��
	mov wc.lpszClassName, OFFSET className;ָ�������Ƶ�ָ��
	INVOKE LoadIcon, NULL, IDI_APPLICATION;����Ӧ�ó���ʵ�������Ŀ�ִ���ļ� (.exe) ����ָ����ͼ����Դ��
	mov wc.hIcon, eax;�������ͼ�꣬Ϊͼ����Դ���
	mov wc.hIconSm, eax;Сͼ��ľ��������������ʾ��ͼ��
	INVOKE LoadCursor, NULL, IDC_ARROW;����Ӧ�ó���ʵ�������Ŀ�ִ�� (.EXE) �ļ��м���ָ�����α���Դ��
	mov wc.hCursor, eax;���α�ľ��

	INVOKE RegisterClassEx, ADDR wc;��wcע�ᴰ����(��������Ĳ����Ѿ�ע�������)
	INVOKE CreateWindowEx, NULL, ADDR className, ADDR appName, \
		WS_OVERLAPPEDWINDOW AND (NOT WS_SIZEBOX) AND (NOT WS_MAXIMIZEBOX) AND (NOT WS_MINIMIZEBOX), CW_USEDEFAULT, \
		CW_USEDEFAULT, 800, 600, NULL, hMenu, \
		hInst, NULL ;Ӧ���Ǵ������ڣ�
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

	.IF uMsg == WM_DESTROY ;�˳�����
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_COMMAND	; ��Ӧ�¼�
		mov ebx, wParam
		.IF bx == IDB_ONE
			;INVOKE ShowWindow, hWnd, SW_HIDE
		.ELSEIF bx == IDM_DRAW  ; ��ͼģʽ
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; ����ģʽ
			mov mode,1
		.ELSEIF bx == IDM_DRAWSIZE ; �Զ��廭�ʴ�С
			;mov mode, 0
		.ELSEIF bx == IDM_ERASESIZE; �Զ�����Ƥ��С
			;mov mode, 1

		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16 ; edx and ebx�洢��ǰ���x��y��λ��

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
			; ebx = pen
			;INVOKE CreatePen, PS_SOLID, 1, 0
			;mov ebx, eax
			INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
			INVOKE LineTo, ps.hdc, endX, endY
			;INVOKE DeleteObject, ebx
		.ENDIF
		.IF mode == 1 ; erasing mode
			.IF erasingFlag == 1
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