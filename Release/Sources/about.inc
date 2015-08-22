;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      about.inc
; Описание:  диалоговое окно "О программе"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

AboutDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

PrepareUrlParam proto pParam:DWORD, pNewProc:DWORD
ClearUrlParam proto pParam:DWORD
SetHyperLink proto hWnd:HWND, pParam:DWORD
MailToWndProc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
