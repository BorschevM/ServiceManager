;------------------------------------------------------------------------------
; Менеджер сервисов Windows
;
; Файл:      memory.inc
; Описание:  функции для работы с памятью
; Автор:     Иванцов Илья Сергеевич, YormLokison@yandex.ru
;------------------------------------------------------------------------------

malloc proto dwSize: DWORD
realloc proto lpMemBlock:LPVOID, dwSize: DWORD
mfree proto lpMemBlock:LPVOID
