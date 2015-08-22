;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      servicedlg.inc
; Описание:  диалоговое окно "Свойства сервиса"
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

; Константы
TABPAGE_COUNT    EQU 4
SERV_DATA_SIZE   EQU 1024
LSA_NAME_LEN     EQU 11

RD_RESTARTCOMP   EQU 1
RD_RESTARTSERV   EQU 2
RD_RUNPROG       EQU 4

; Функции
ServicePropertiesDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

ServGeneralDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ServLogonDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ServRecoveryDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
ServDependenciesDialogFunc proto hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

ServicePropertiesClose proto hWnd: HWND, dwResult: DWORD
NumEditWndProc proto hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD

FillComboBox proto hCombo: HWND, lpCodeString: LPVOID, nSize: DWORD
FillDependenciesList proto hList:HWND, lpBuffer: LPCSTR, dwSize: DWORD
GetRecovereActionFromComboBox proto hCombo: HWND
SetFailureAction proto hWnd:HWND, dwControl: DWORD, dwType: DWORD, dwDelay: DWORD
GetFailureAction proto hWnd:HWND, lpParam: LPVOID, dwControl: DWORD, lpAction: LPVOID

LoadData proto hWnd: HWND, lpParam: LPVOID
SaveData proto hWnd: HWND, lpParam: LPVOID
CheckData proto hWnd: HWND

GetGeneralData proto lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
GetFailureData proto lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
GetDescriptionData proto lplpBuffer: LPVOID, lpdwBufferSize: LPDWORD
GetDwordFromString proto lpBuffer: LPCSTR, dwSize: DWORD
SetTokenPrivilege proto lpComp: LPSTR, lpTP: LPVOID, lpPrivilege: LPCSTR
