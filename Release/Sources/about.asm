;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      about.asm 
; Описание:  диалоговое окно "О программе"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

title  About

.386
.model flat,stdcall
option casemap:none

include ..\..\Masm32\include\windows.inc
include ..\..\Masm32\include\user32.inc
include ..\..\Masm32\include\gdi32.inc
include ..\..\Masm32\include\shell32.inc

include res.inc
include global.inc
include about.inc

.data
    szMailTo db 'mailto:', 0
    
.data?
    UrlParam sUrlParam <?>
    UrlBuffer db 256 dup(?)

.code
;------------------------------------------------------------------------------
; AboutDialogFunc - Процедура диалогового окна О Программе
;   - hWnd - хэндл окна
;   - uMsg - сообщение
;   - wParam - первый параметр сообщения
;   - lParam - второй параметр сообщения 
;------------------------------------------------------------------------------
AboutDialogFunc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg==WM_INITDIALOG
        invoke PrepareUrlParam, addr UrlParam, addr MailToWndProc
        invoke GetDlgItem, hWnd, IDC_ABOUT_DEVMAIL
        invoke SetHyperLink, eax, addr UrlParam

        xor eax, eax
        inc eax
        ret
    .elseif uMsg== WM_CTLCOLORSTATIC
        invoke SendMessage, lParam, uMsg, wParam, lParam
        ret
    .elseif uMsg== WM_CLOSE
        invoke ClearUrlParam, addr UrlParam
        invoke EndDialog, hWnd, IDC_CANCEL
    .elseif uMsg== WM_COMMAND
        .if (wParam == IDC_OK)
            invoke ClearUrlParam, addr UrlParam
            invoke EndDialog, hWnd, IDC_OK
        .endif
    .endif

    xor eax, eax
    ret
AboutDialogFunc endp

;------------------------------------------------------------------------------
;  Функция PrepareUrlParam подготавливает структуру для работы с Url
;    - pParam - структура с данными Url
;    - pNewProc - новая оконная процедура
;------------------------------------------------------------------------------
PrepareUrlParam proc pParam:DWORD, pNewProc:DWORD
    push ebx
    
    mov ebx, pParam
    push pNewProc
    pop (sUrlParam ptr [ebx]).pNewProc
    invoke LoadCursor, NULL, IDC_HAND
    mov (sUrlParam ptr [ebx]).hCursor, eax
    
    pop ebx
    ret
PrepareUrlParam endp

;------------------------------------------------------------------------------
;  Функция ClearUrlParam отчищает блок парамеров Url
;    - pParam - структура с данными Url
;------------------------------------------------------------------------------
ClearUrlParam proc pParam:DWORD
    mov eax, pParam
    invoke DeleteObject, (sUrlParam ptr [eax]).hCursor
    ret
ClearUrlParam endp

;------------------------------------------------------------------------------
;  Функция SetHyperLink изменяет элемент текста для функционирования в качестве Url
;    - hWnd - хендл текстового элемента
;    - pParam - структура с данными Url
;------------------------------------------------------------------------------
SetHyperLink proc hWnd:HWND, pParam:DWORD
    push ebx
    
    mov ebx, pParam
    invoke SetWindowLong, hWnd, GWL_WNDPROC, (sUrlParam ptr [ebx]).pNewProc
    mov (sUrlParam ptr [ebx]).pOldProc, eax
    invoke SetWindowLong, hWnd, GWL_USERDATA, pParam
    
    pop ebx
    ret
SetHyperLink endp

;------------------------------------------------------------------------------
;  Функция MailToWndProc - оконная процедура Url
;------------------------------------------------------------------------------
MailToWndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL lFont: LOGFONT
    LOCAL hFont: HFONT
    
    .if uMsg==WM_CTLCOLORSTATIC
        invoke SendMessage, hWnd, WM_GETFONT, 0, 0
        mov hFont, eax
        invoke GetObject, hFont, sizeof(LOGFONT), addr lFont
        xor eax, eax
        inc eax
        mov lFont.lfUnderline, al
        invoke CreateFontIndirect, addr lFont
        push eax
        invoke SelectObject, wParam, eax
        invoke SetTextColor, wParam, Blue
        invoke GetSysColor, COLOR_MENU
        invoke SetBkColor, wParam, eax
        pop eax
        invoke DeleteObject, eax
        invoke GetStockObject, HOLLOW_BRUSH
        ret
    .elseif uMsg==WM_NCHITTEST
        xor eax, eax
        inc eax
        ret
    .elseif uMsg==WM_LBUTTONDOWN
        ; открыть    почтовый   клиент  по умолчанию
        push esi
        push edi
        push ecx
        
        mov esi, offset szMailTo
        mov edi, offset UrlBuffer
        mov ecx, sizeof szMailTo
        dec ecx
        push ecx
        rep movsb
        pop ecx
        mov eax, sizeof UrlBuffer
        sub eax, ecx
        
        invoke GetWindowText, hWnd, edi, eax
        invoke ShellExecute, NULL, addr szOpen, addr UrlBuffer, NULL, NULL, SW_SHOWNORMAL
        
        pop ecx
        pop edi
        pop esi
    .elseif uMsg==WM_SETCURSOR
        ; установить курсор
        invoke GetWindowLong, hWnd, GWL_USERDATA
        invoke SetCursor, (sUrlParam ptr [eax]).hCursor
    .else
        invoke GetWindowLong, hWnd, GWL_USERDATA
        invoke CallWindowProc, (sUrlParam ptr [eax]).pOldProc, hWnd, uMsg, wParam, lParam
        ret
    .endif
    
    xor eax, eax
    ret
MailToWndProc endp

end
