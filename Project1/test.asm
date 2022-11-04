TITLE PaintingTool

.386 
.model flat,stdcall 
option casemap:none

WinMain proto :dword, :dword, :dword, :dword

include windows.inc 
include user32.inc 
include kernel32.inc 
include gdi32.inc
include msvcrt.inc
include comdlg32.inc
include comctl32.inc
include msvcrt.inc

includelib user32.lib 
includelib kernel32.lib 
includelib gdi32.lib
includelib msvcrt.lib
includelib comdlg32.lib
includelib comctl32.lib
includelib msvcrt.lib



.data

PenWidth DWORD 1
;Color
CurrentColor dd 000h
CustomColor dd 16 DUP(0)
testString byte "helloworld"

LogicFont				LOGFONT <> 
CurrentFont				HFONT	0

PenStyle DWORD PS_SOLID ;PS_SOLID == 0,ΪĬ��ֵ
EraserRadius DWORD 10
PainterRadius DWORD 1
NumberSides DWORD 0
SideCount DWORD 0
SideBias DWORD 0

IDM_OPEN dw 1012
IDM_SAVE dw 1013

IDM_DRAW  dw 1014
IDM_ERASE dw 1015
IDM_CLEAR dw 1020

IDM_DRAWSIZE dw 1016
IDM_ERASESIZE dw 1017

IDM_INPUTTEXT dw 1018
IDM_CHOOSEFONT dw 1019

IDM_STRAIGHTLINE dw 1021
IDM_RECTANGLE dw 1022
IDM_POLYGON dw 1023

IDD_DIALOG1 dw 101
IDD_DIALOG2 dw 104
IDD_DIALOG3 dw 107
IDD_DIALOG4 dw 110
IDC_CURSOR1 dw 103
IDC_CURSOR2 dw 106
IDC_CURSOR3 dw 109
IDC_EDIT1  dw 1001
IDC_EDIT2  dw 1002
IDC_EDIT3  dw 1003
IDC_EDIT4  dw 1004
IDI_ICON1  dw  102
IDI_ICON2  dw  104

IDM_COLOR dw 601
IDM_STYLESOLID dw 602
IDM_STYLEDASH dw 603
IDM_STYLEDOT dw 604
IDM_STYLEDASHDOT dw 605
IDM_STYLEDASHDOTDOT dw 606


fileMenuStr db "�ļ�", 0
loadMenuStr db "��", 0
saveMenuStr db "����", 0

fileMenuStr1 db "��ͼ", 0
drawMenuStr db "��ͼ", 0
eraseMenuStr db "����", 0
clearMenuStr db "����", 0

fileMenuStr2 db "��С", 0
drawSizeStr db "���ʴ�С", 0
eraseSizeStr db "��Ƥ��С", 0

fileMenuStr3 db "��ɫ", 0
colorStr db "ѡ����ɫ", 0

fileMenuStr4 db "����", 0
textStr db "��������", 0
fontStr db "ѡ������", 0

fileMenuStr5 db "������ʽ", 0
SolidStr db "solid", 0
dashStr db "dash", 0
dotStr db "dot", 0
dashdotStr db "dashdot", 0
dashdotdotStr db "dashdotdot", 0

fileMenuStr6 db "������״", 0
LineStr db "ֱ��", 0
RectangleStr db "����", 0
PolygonStr db "�����", 0

tmp_string db "%d", 0



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

pointsX DWORD 100 DUP(?)
pointsY DWORD 100 DUP(?)
PointsNum DWORD 0

drawingFlag db 0
erasingFlag db 0
textflag db 0
; ��ͼ/����ģʽ
mode db 0
shapeMode db 0

workRegion RECT <0, 0, 800, 600>

ShowString BYTE 100 dup(?)

; ����
bmpLength dw 541
bmpWidth dw 784

;�ļ����
bmpFile OPENFILENAME <>  ;bmp�ļ�
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

; �����˵�
createMenu PROC
	LOCAL topMenu1: HMENU
	LOCAL topMenu2: HMENU
	LOCAL topMenu3: HMENU
	LOCAL topMenu4: HMENU
	LOCAL topMenu5: HMENU
	LOCAL topMenu6: HMENU
	LOCAL topMenu7: HMENU

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

	INVOKE CreatePopupMenu       ;������Ŀ������������ɫ����
	mov topMenu5, eax

	INVOKE CreatePopupMenu       ;������Ŀ������������ɫ����
	mov topMenu6, eax

	INVOKE CreatePopupMenu
	mov topMenu7, eax




	
	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu1, ADDR fileMenuStr ;���ļ����ַŽ���Ӧλ��

	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_OPEN, ADDR loadMenuStr ;���ļ��Ĳ˵����¼ӡ��򿪡�
	INVOKE AppendMenu, topMenu1, MF_STRING, IDM_SAVE, ADDR saveMenuStr ;���ļ��Ĳ˵����¼ӡ����桱

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu2, ADDR fileMenuStr1 ;�ѻ�ͼ���ַŽ���Ӧλ��
	
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_DRAW, ADDR drawMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ���ͼ��
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_ERASE, ADDR eraseMenuStr ; �ڻ�ͼ�Ĳ˵����¼ӡ�������
	INVOKE AppendMenu, topMenu2, MF_STRING, IDM_CLEAR, ADDR clearMenuStr

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu3, ADDR fileMenuStr2 ;�Ѵ�С���ַŽ���Ӧλ��

	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_DRAWSIZE, ADDR drawSizeStr ; �ڴ�С�Ĳ˵����¼ӡ����ʴ�С��
	INVOKE AppendMenu, topMenu3, MF_STRING, IDM_ERASESIZE, ADDR eraseSizeStr ; �ڴ�С�Ĳ˵����¼ӡ���Ƥ��С��

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu4, ADDR fileMenuStr3 ; ����ɫ���ַŽ���Ӧλ��
	
	INVOKE AppendMenu, topMenu4, MF_STRING, IDM_COLOR, ADDR colorStr ;����ɫ�˵����¼ӡ�ѡ����ɫ��

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu5, ADDR fileMenuStr5
	INVOKE AppendMenu, topMenu5, MF_STRING, IDM_STYLESOLID, ADDR SolidStr
	INVOKE AppendMenu, topMenu5, MF_STRING, IDM_STYLEDASH, ADDR dashStr
	INVOKE AppendMenu, topMenu5, MF_STRING, IDM_STYLEDOT, ADDR dotStr
	INVOKE AppendMenu, topMenu5, MF_STRING, IDM_STYLEDASHDOT, ADDR dashdotStr
	INVOKE AppendMenu, topMenu5, MF_STRING, IDM_STYLEDASHDOTDOT, ADDR dashdotdotStr

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu6, ADDR fileMenuStr4 
	INVOKE AppendMenu, topMenu6, MF_STRING, IDM_INPUTTEXT, ADDR textStr
	INVOKE AppendMenu, topMenu6, MF_STRING, IDM_CHOOSEFONT, ADDR fontStr

	INVOKE AppendMenu, hMenu, MF_POPUP, topMenu7, ADDR fileMenuStr6
	INVOKE AppendMenu, topMenu7, MF_STRING, IDM_STRAIGHTLINE, ADDR LineStr
	INVOKE AppendMenu, topMenu7, MF_STRING, IDM_RECTANGLE, ADDR RectangleStr
	INVOKE AppendMenu, topMenu7, MF_STRING, IDM_POLYGON, ADDR PolygonStr



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

IHandleTextDialog PROC hWnd:HWND,wParam:WPARAM,lParam:LPARAM
    mov ebx,wParam
    and ebx,0ffffh
    .IF ebx == IDOK
        invoke GetDlgItemText,hWnd,IDC_EDIT3,addr ShowString, 500
        invoke EndDialog,hWnd,wParam
    .ELSEIF ebx == IDCANCEL
        invoke EndDialog,hWnd,wParam
        mov eax,TRUE
    .ENDIF
    ret
IHandleTextDialog ENDP

ICallTextDialog PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    mov ebx,uMsg
    .IF ebx == WM_COMMAND
        invoke IHandleTextDialog,hWnd,wParam,lParam
    .ELSE 
		;Ĭ�ϴ���
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor eax,eax 
    ret
ICallTextDialog endp


InputText PROC, hdc:HDC,hWnd:HWND
	;extern hInstance:HINSTANCE
	mov edx, curX
	mov ecx, curY
	push edx
	push ecx
	invoke DialogBoxParam, hInstance, IDD_DIALOG3 ,hWnd, OFFSET ICallTextDialog, 0

	invoke crt_strlen, OFFSET ShowString
	pop ecx
	pop edx
	INVOKE TextOutA, hdc, edx, ecx, ADDR ShowString, eax
	mov ShowString, 0
	ret
InputText ENDP

IAddPoint PROC, hdc:HDC, m_x:DWORD, m_y:DWORD
	mov eax, PointsNum
	imul eax, 4
	mov edx, m_x
	mov ecx, m_y
	mov [pointsX + eax], edx
	mov [pointsY + eax], ecx
	inc PointsNum
	ret
IAddPoint ENDP



IPaintLine PROC, hdc:HDC
	mov edx, DWORD PTR [pointsX]
	mov ecx, DWORD PTR [pointsY]
	INVOKE MoveToEx, hdc, edx, ecx, NULL
	mov edx, DWORD PTR [pointsX + 4]
	mov ecx, DWORD PTR [pointsY + 4]
	INVOKE LineTo, hdc, edx, ecx
	INVOKE MoveToEx, hdc, 0, 0, NULL
	mov PointsNum, 0
	ret
IPaintLine ENDP

GetNumberSides PROC hWnd:HWND,wParam:WPARAM,lParam:LPARAM
    mov ebx,wParam
    and ebx,0ffffh
    .IF ebx == IDOK
        invoke GetDlgItemInt,hWnd,IDC_EDIT4, NULL, 0
		.IF eax >= 3 && eax <= 10
			mov NumberSides, eax
		.ENDIF
        invoke EndDialog,hWnd,wParam
    .ELSEIF ebx == IDCANCEL
        invoke EndDialog,hWnd,wParam
        mov eax,TRUE
    .ENDIF

    ret

GetNumberSides ENDP

setNumberSidesDialog PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    mov ebx,uMsg
    .IF ebx == WM_COMMAND
        invoke GetNumberSides,hWnd,wParam,lParam
    .ELSE 
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam 
        ret 
    .ENDIF 
    xor eax,eax 
    ret
setNumberSidesDialog endp

setNumberSides PROC hWnd:HWND
	invoke DialogBoxParam, hInstance, IDD_DIALOG4 ,hWnd, OFFSET setNumberSidesDialog, 0
	ret
setNumberSides ENDP

IChooseFont PROC hWnd:HWND
    local cf:CHOOSEFONT
    mov cf.lStructSize,sizeof cf
    mov eax,hWnd
    mov cf.hwndOwner,eax
    mov cf.hDC, 0
    push offset LogicFont
    pop cf.lpLogFont
    mov cf.Flags, 0
    mov cf.rgbColors, 0
    mov cf.lCustData, 0
    mov cf.lpfnHook, 0
    mov cf.lpTemplateName, 0
    mov eax,hInstance
    mov cf.hInstance,eax
    mov cf.lpszStyle, 0
    mov cf.nFontType, 0
    mov cf.nSizeMin, 0
    mov cf.nSizeMax, 0
    
    invoke ChooseFont,addr cf
    invoke CreateFontIndirect, offset LogicFont
    mov CurrentFont, eax
    ret
IChooseFont endp

Paintevent PROC USES ecx,
	hWnd:HWND,wParam:WPARAM,lParam:LPARAM,ps:PAINTSTRUCT
	local hPen: HPEN
	push ecx
	.IF mode == 0

	INVOKE CreatePen, PS_SOLID, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 2
	INVOKE CreatePen, PS_SOLID, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 3
	INVOKE CreatePen, PS_DASH, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 4
	INVOKE CreatePen, PS_DOT, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 5
	INVOKE CreatePen, PS_DASHDOT, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 6
	INVOKE CreatePen, PS_DASHDOTDOT, PainterRadius, CurrentColor
	.ENDIF
	.IF mode == 7
		push ecx		
		INVOKE SelectObject,ps.hdc, CurrentFont
		pop ecx
		INVOKE InputText, ps.hdc, hWnd
		ret
	.ENDIF
	.IF shapeMode == 1 ; paint a straight line
		mov hPen, eax
		INVOKE SelectObject, ps.hdc, hPen
		mov edx, DWORD PTR [pointsX]
		mov ecx, DWORD PTR [pointsY]
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX + 4]
		mov ecx, DWORD PTR [pointsY + 4]
		INVOKE LineTo, ps.hdc, edx, ecx
		;INVOKE MoveToEx, hWnd, 0, 0, NULL
		mov PointsNum, 0
		INVOKE DeleteObject, hPen
		mov shapeMode, 0
		ret
	.ENDIF
	.IF shapeMode == 2 ; paint a straight line
		mov hPen, eax
		INVOKE SelectObject, ps.hdc, hPen
		;from (x1,y1)to(x2,y1)
		mov edx, DWORD PTR [pointsX] ; x1
		mov ecx, DWORD PTR [pointsY] ; y1
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX + 4] ; x2
		mov ecx, DWORD PTR [pointsY] ; y1
		INVOKE LineTo, ps.hdc, edx, ecx
		;from (x1,y1)to(x1,y2)
		mov edx, DWORD PTR [pointsX] ; x1
		mov ecx, DWORD PTR [pointsY] ; y1
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX] ; x1
		mov ecx, DWORD PTR [pointsY + 4] ; y2
		INVOKE LineTo, ps.hdc, edx, ecx
		;from (x2,y2)to(x1,y2)
		mov edx, DWORD PTR [pointsX + 4] ; x2
		mov ecx, DWORD PTR [pointsY + 4] ; y2
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX] ; x1
		mov ecx, DWORD PTR [pointsY + 4] ; y2
		INVOKE LineTo, ps.hdc, edx, ecx
		;from (x2,y2)to(x2,y1)
		mov edx, DWORD PTR [pointsX + 4] ; x2
		mov ecx, DWORD PTR [pointsY + 4] ; y2
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX + 4] ; x2
		mov ecx, DWORD PTR [pointsY] ; y1
		INVOKE LineTo, ps.hdc, edx, ecx
		;INVOKE MoveToEx, hWnd, 0, 0, NULL
		mov PointsNum, 0
		INVOKE DeleteObject, hPen
		mov shapeMode, 0
		ret
	.ENDIF
	.IF shapeMode == 3 ; polygon mode
		mov hPen, eax
		INVOKE SelectObject, ps.hdc, hPen

		mov eax, 0
		mov SideCount, eax ; sidecount == 0
		mov eax, 0
		mov SideBias, eax ; sideBias == 0
		mov ecx, NumberSides
	
		DRAW_LINE_LOOP:
			mov eax, NumberSides
			dec eax
			cmp SideCount, eax
			je DRAW_LAST_LINE
			mov eax, SideBias
			mov edx, DWORD PTR [pointsX + eax] 
			mov eax, SideBias
			mov ecx, DWORD PTR [pointsY + eax]

			INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
			mov eax, SideBias
			mov edx, DWORD PTR [pointsX + eax + 4] 
			mov eax, SideBias
			mov ecx, DWORD PTR [pointsY + eax + 4]
			INVOKE LineTo, ps.hdc, edx, ecx
			inc SideCount ; SideCount++
			add SideBias, 4 ; SideBias++
		loop DRAW_LINE_LOOP

		DRAW_LAST_LINE:
		mov eax, SideBias
		mov edx, DWORD PTR [pointsX + eax] 
		mov eax, SideBias
		mov ecx, DWORD PTR [pointsY + eax]
		INVOKE MoveToEx, ps.hdc, edx, ecx, NULL
		mov edx, DWORD PTR [pointsX] 
		mov eax, SideBias
		mov ecx, DWORD PTR [pointsY]
		INVOKE LineTo, ps.hdc, edx, ecx
		mov SideCount, 0
		mov SideBias, 0
		mov PointsNum, 0
		mov mode, 0
		INVOKE DeleteObject, hPen
		mov shapeMode, 0
		ret
	.ENDIF
	mov hPen, eax
	INVOKE SelectObject, ps.hdc, hPen

	INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
	INVOKE LineTo, ps.hdc, endX, endY
	;INVOKE MoveToEx, ps.hdc, 0, 0, NULL; to be decided

	INVOKE DeleteObject, hPen
	pop ecx
	ret
Paintevent ENDP

setEraserCursor PROC USES eax ebx,
	hWnd:HWND,wParam:WPARAM,lParam:LPARAM
	push eax
	push ebx
	mov eax,lParam
    and eax,0ffffh
    .IF eax!=HTCLIENT
        ret
    .ENDIF

    movzx eax,mode
    movzx ebx,IDC_CURSOR1
    invoke LoadCursor,hInstance,ebx
    invoke SetCursor,eax
	pop ebx
	pop eax
    ret
setEraserCursor ENDP

setPencilCursor PROC USES eax ebx,
	hWnd:HWND,wParam:WPARAM,lParam:LPARAM
	push eax
	push ebx
	mov eax,lParam
    and eax,0ffffh
    .IF eax!=HTCLIENT
        ret
    .ENDIF

    movzx eax,mode
    movzx ebx,IDC_CURSOR2
    invoke LoadCursor,hInstance,ebx
    invoke SetCursor,eax
	pop ebx
	pop eax
    ret
setPencilCursor ENDP

setTextCursor PROC USES eax ebx,
	hWnd:HWND,wParam:WPARAM,lParam:LPARAM
	push eax
	push ebx
	mov eax,lParam
    and eax,0ffffh
    .IF eax!=HTCLIENT
        ret
    .ENDIF

    movzx eax,mode
    movzx ebx,IDC_CURSOR3
    invoke LoadCursor,hInstance,ebx
    invoke SetCursor,eax
	pop ebx
	pop eax
    ret
setTextCursor ENDP


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
	LOCAL drawmode:DWORD

	;INVOKE setPencilCursor, hWnd, wParam, lParam


	.IF uMsg == WM_DESTROY ;�˳�����
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_COMMAND	; ��Ӧ�¼�
		mov ebx, wParam
		.IF bx == IDM_DRAW  ; ��ͼģʽ
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; ����ģʽ
			mov mode,1
		.ELSEIF bx == IDM_STYLESOLID ; ����ģʽ
			mov mode,2
		.ELSEIF bx == IDM_STYLEDASH ; ����ģʽ
			mov mode,3
		.ELSEIF bx == IDM_STYLEDOT ; ����ģʽ
			mov mode,4
		.ELSEIF bx == IDM_STYLEDASHDOT ; ����ģʽ
			mov mode,5
		.ELSEIF bx == IDM_STYLEDASHDOTDOT ; ����ģʽ
			mov mode,6
		.ELSEIF bx == IDM_INPUTTEXT ; textģʽ
			mov mode,7
		.ELSEIF bx == IDM_CLEAR; clear the window
			mov mode,8
			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
			INVOKE GetStockObject, NULL_PEN
			INVOKE SelectObject, hdc, eax; ps.hdc:handle to the display DC to be used for painting.
			INVOKE Rectangle, hdc, 0, 0, 800, 600
		.ELSEIF bx == IDM_STRAIGHTLINE
			mov PointsNum, 0
			mov shapeMode, 1 ; straightline mode
		.ELSEIF bx == IDM_RECTANGLE
			mov PointsNum, 0
			mov shapeMode, 2 ; straightline mode
		.ELSEIF bx == IDM_CHOOSEFONT ; textģʽ
			INVOKE IChooseFont, hWnd
		.ELSEIF bx == IDM_DRAWSIZE ; �Զ��廭�ʴ�С
			INVOKE setPainterSize, hWnd
		.ELSEIF bx == IDM_ERASESIZE; �Զ�����Ƥ��С
			INVOKE setEraserSize, hWnd
		.ELSEIF bx == IDM_POLYGON
			INVOKE setNumberSides, hWnd ; set the number of sides of the polygon
			mov PointsNum, 0
			mov shapeMode, 3 ; polygon modee
        .ELSEIF bx == IDM_OPEN     ;���ļ�
			push edx               ;����bmp�ļ���Ϣ�͸�ʽ
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
		.ELSEIF bx == IDM_SAVE        ;�����ļ�
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
			INVOKE GetDC, hWnd ;��ȡ��ǰ���ھ��
			
			mov hdc, eax
			INVOKE CreateCompatibleBitmap, hdc, bmpWidth, bmpLength
			mov hbm, eax
			INVOKE CreateCompatibleDC, hdc
			mov hdcMem, eax

			INVOKE SelectObject, hdcMem, hbm 
			INVOKE BitBlt, hdcMem, 0, 0, bmpWidth, bmpLength, hdc, 0, 0, SRCCOPY
			INVOKE CreateFile,ADDR bmpFileName,GENERIC_WRITE,0,	NULL,CREATE_ALWAYS,	FILE_ATTRIBUTE_NORMAL,NULL ;�����ļ�
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

			;ɫ��С�ڵ���8λ����ɫ����ɫ����2��ɫ��η�������8λ�޵�ɫ��
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
			INVOKE IChooseColor, hWnd; ������ɫ
		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		.IF mode == 0
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		.IF mode == 2
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		.IF mode == 3
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		.IF mode == 4
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		.IF mode == 5
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		.IF mode == 6
			mov eax, 1
			mov drawmode, eax
		.ENDIF
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��

		mov curX, edx
		mov curY, ebx

		.IF drawmode == 1  ;drawing mode
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
		.IF mode == 8 ; clear window
			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
		.ENDIF
	.ELSEIF uMsg == WM_LBUTTONDOWN
		.IF mode == 7 ; text mode
			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
		.ENDIF
		.IF shapeMode == 1 ; straight line mode
			.IF PointsNum == 0
				mov ebx, lParam
				mov edx, 0
				mov dx, bx
				sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��
				INVOKE IAddPoint, hWnd, edx, ebx
				ret
			.ENDIF
			.IF PointsNum == 1
				mov ebx, lParam
				mov edx, 0
				mov dx, bx
				sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��
				INVOKE IAddPoint, hWnd, edx, ebx
				INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
				ret
			.ENDIF
			ret
		.ENDIF
		.IF shapeMode == 2 ; straight line mode
			.IF PointsNum == 0
				mov ebx, lParam
				mov edx, 0
				mov dx, bx
				sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��
				INVOKE IAddPoint, hWnd, edx, ebx
				ret
			.ENDIF
			.IF PointsNum == 1
				mov ebx, lParam
				mov edx, 0
				mov dx, bx
				sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��
				INVOKE IAddPoint, hWnd, edx, ebx
				INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
				ret
			.ENDIF
			ret
		.ENDIF
		.IF shapeMode == 3 ; polygon mode
			mov ebx, lParam
			mov edx, 0
			mov dx, bx
			sar ebx, 16               ; edx and ebx�洢��ǰ���x��y��λ��

			INVOKE IAddPoint, hWnd, edx, ebx ; �����������һ��
			mov eax, PointsNum
			cmp eax, NumberSides
			je LASTSIDE
			ret

			LASTSIDE: 

			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
		ret
		.ENDIF
		mov drawingFlag, 1
		mov erasingFlag, 1
	.ELSEIF uMsg == WM_LBUTTONUP
		mov drawingFlag, 0
		mov erasingFlag, 0
		mov beginX, 0
		mov beginY, 0
		mov endX, 0
		mov endY, 0
	.ELSEIF uMsg == WM_SETCURSOR

		.IF mode == 0

			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 2
			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 3
			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 4
			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 5
			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 6
			INVOKE setPencilCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 1
			INVOKE setEraserCursor, hWnd, wParam, lParam
		.ENDIF
		.IF mode == 7
			INVOKE setTextCursor, hWnd, wParam, lParam
		.ENDIF
	.ELSEIF uMsg == WM_PAINT
		INVOKE BeginPaint, hWnd, ADDR ps ;LOCAL ps: PAINTSTRUCT
		.IF mode == 0 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 2 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 3 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 4 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 5 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 6 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 7 ; painting mode
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF mode == 8 ; clear the window
			INVOKE GetStockObject, NULL_PEN
			INVOKE SelectObject, ps.hdc, eax; ps.hdc:handle to the display DC to be used for painting.
			INVOKE Rectangle, ps.hdc, 0, 0, 800, 600
		.ENDIF
		.IF shapeMode == 1 ; paint a straightline
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF shapeMode == 2 ; paint a straightline
			INVOKE Paintevent, hWnd, wParam, lParam, ps
		.ENDIF
		.IF shapeMode == 3 ; paint a straightline
			INVOKE Paintevent, hWnd, wParam, lParam, ps
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