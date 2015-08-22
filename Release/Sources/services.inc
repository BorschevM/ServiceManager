;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      services.inc
; Описание:  функции для работы с сервисами
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

SERVICE_STATUS_SIZE  EQU (10*(512 + (sizeof SERVICE_STATUS)))
SERVICE_CONFIG_SIZE  EQU (4352 + (sizeof QUERY_SERVICE_CONFIG))
SERVICE_DESC_SIZE    EQU 1024
SERVICE_FAIL_SIZE    EQU 2048

SERVICE_TYPE_COUNT   EQU 5
SERVICE_STATE_COUNT  EQU 7

SERVICE_START_TYPE_COUNT     EQU 5
SERVICE_ERROR_CONTROL_COUNT  EQU 4
SERVICE_FAILURE_ACTION_COUNT EQU 4

; Переменные
EXTERNDEF pStatusInfo: DWORD
EXTERNDEF pConfigInfo: DWORD
EXTERNDEF pDescriptionInfo: DWORD
EXTERNDEF pFailureInfo: DWORD
EXTERNDEF pGroupInfo: DWORD

EXTERNDEF dwStatusInfoSize: DWORD
EXTERNDEF dwConfigInfoSize: DWORD
EXTERNDEF dwDescriptionInfoSize: DWORD
EXTERNDEF dwFailureInfoSize: DWORD
EXTERNDEF dwGroupInfoSize: DWORD

EXTERNDEF csServiceType: CodeString 
EXTERNDEF csServiceState: CodeString 
EXTERNDEF csServiceStartType: CodeString
EXTERNDEF csServiceErrorControl: CodeString
EXTERNDEF csSeviceFailureAcrion: CodeString

;Функции
FillServicesList proto hList:HWND, hLog:HWND, hSCManager: HANDLE, dwServiceType: DWORD, dwServiceState: DWORD
FillServicesCombo proto hCombo:HWND, hSCManager: HANDLE, dwServiceType: DWORD, dwServiceState: DWORD
FillOrderGroupCombo proto hCombo:HWND, lpCompName: LPCSTR
UpdateServiceRecord proto hList:HWND, dwIndex:DWORD, hSCManager: HANDLE

FillBufferFromFlag proto dwFlag: DWORD, lpBuffer: LPCSTR, dwBufferSize: DWORD, lpCodeString: LPVOID, dwArrSize: DWORD
FillBufferFromCode proto dwCode: DWORD, lpBuffer: LPCSTR, dwBufferSize: DWORD, lpCodeString: LPVOID, dwArrSize: DWORD

WaitForServiceState proto hService: HANDLE, dwState: DWORD, lpServiceStatus: LPVOID, dwMilliseconds:DWORD
GetServiceStatus proto hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD, lpServiceStatus: LPVOID

ServiceStartOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
ServiceStopOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
ServicePauseOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
ServiceResumeOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
ServiceRestartOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
ServiceControlOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD, dwCode: DWORD
ServiceDeleteOperation proto hLog: HWND, hSCManager: HANDLE, lpServiceName: LPCSTR, dwAccess: DWORD
