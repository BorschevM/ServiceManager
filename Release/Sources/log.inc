;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      log.inc
; Описание:  функции для работы с ошибками и сообщениями
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

ERROR_DESC_SIZE   EQU 513
ERROR_CODE_SIZE   EQU 33

EXTERNDEF szSCM: BYTE
EXTERNDEF szOperationOpen: BYTE
EXTERNDEF szOperationClose: BYTE
EXTERNDEF szOperationLock: BYTE
EXTERNDEF szOperationUnlock: BYTE
    
EXTERNDEF szOperationCrateService: BYTE
EXTERNDEF szOperationDeleteService: BYTE

EXTERNDEF szOperationOpenService: BYTE
EXTERNDEF szOperationCloseService: BYTE
EXTERNDEF szOperationPauseService: BYTE
EXTERNDEF szOperationResumeService: BYTE
EXTERNDEF szOperationControlService: BYTE

EXTERNDEF szOperationEnumServices: BYTE
EXTERNDEF szOperationQueryServiceConfig: BYTE
EXTERNDEF szOperationChangeServiceConfig: BYTE
EXTERNDEF szOperationEnumDependentServices: BYTE
EXTERNDEF szOperationQueryServiceStatus: BYTE
EXTERNDEF szOperationStart: BYTE
EXTERNDEF szOperationStop: BYTE
    
EXTERNDEF szOperationQuerySecurity: BYTE
EXTERNDEF szOperationSetSecurity: BYTE
    
EXTERNDEF szErrorDescription: BYTE
EXTERNDEF szErrorCode: BYTE

GetLastErrorString proto lpDescription: DWORD, nDescriptionSize:DWORD, lpCode:DWORD, nCodeSize: DWORD
LogMessage proto hList:DWORD,  lpSource: DWORD, lpOperation:DWORD, dwStatus: DWORD, lpCode: DWORD, lpDescription: DWORD 


