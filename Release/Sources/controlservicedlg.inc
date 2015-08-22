;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      controlservicedlg.inc
; Описание:  диалоговое окно "Управление сервиса"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

; Функции
ServiceControlDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
CloseDialog proto hWnd: HWND
UpdateStatusControls proto hWnd: HWND, lpStatus: LPVOID
