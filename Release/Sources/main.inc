;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      main.inc
; Описание:  Описание типов  и функций используемых в работе с окном приложения
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

; константы
MIN_WIDTH       EQU 320
MIN_HEIGHT      EQU 200

BUTTONCOUNT     EQU 14
TVI_COUNT       EQU 3
TB_SIZE         EQU 16
TVI_SIZE        EQU 16
TREE_WIDTH      EQU 120
LOG_HEIGHT      EQU 100
SPLITTER_SIZE   EQU 4
MIN_SIZE        EQU 20

SEVR_COLUMN_COUNT  EQU 9
LOG_COLUMN_COUNT   EQU 5

;------------------------------------------------------------------------------
; Функции
;------------------------------------------------------------------------------
WinMain proto hInst:HINSTANCE, hPrevInst:HINSTANCE, lpCmdLine:LPSTR, nCmdShow:DWORD
MainWndProc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
OnCreate proto hWnd:HWND
OnSize proto hWnd:HWND
GetMinMaxInfo proto lParam:LPARAM
OnLButtonDown proto hWnd:HWND, wParam:WPARAM, lParam:LPARAM
OnLButtonUp proto hWnd:HWND, wParam:WPARAM, lParam:LPARAM
OnMouseMove proto hWnd:HWND, wParam:WPARAM, lParam:LPARAM
OnNotify proto hWnd:HWND, wParam:WPARAM, lParam:LPARAM
UpdateServControls proto hList:HWND, dwIndex: DWORD

CreateToolBar proto hParent:HWND, hInstance:HINSTANCE, pTBInfo:DWORD
SetBmpColor proto  hBitmap:HBITMAP
SetToolBarButton proto hToolBar: HWND, pTButton: DWORD, Id: DWORD
CreateTreeView proto hParent: HWND, hInstance: HINSTANCE, pTVInfo: DWORD

FreeResources proto

SCMConnectTo proto hWnd:HWND
ExportDataToFile proto hList: HWND
Exit proto hWnd:HWND

OpenSCMAccess proto hWnd:HWND

OpenSCMConnection proto
CloseSCMConnection proto
LockSCM proto
UnLockSCM proto

OpenServAccess proto hWnd:HWND
OpenServSecurity proto hWnd:HWND

AddServRecord proto hList: HWND
EditServRecord proto hList: HWND
DeleteServRecord proto hList: HWND

ServControl proto hList: HWND, lpControlFunction: DWORD
ServControlDlg proto hWnd:HWND, hList: HWND
RefreshData proto hList: HWND

OpenHelp proto hWnd:HWND
OpenAboutDlg proto hWnd:HWND

ExportListToFile proto hList: HWND, lpFileName: LPCSTR

ServiceListProc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
