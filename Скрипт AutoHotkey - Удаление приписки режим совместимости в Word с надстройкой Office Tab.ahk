#Persistent
SetTimer, ChangeAllWordWindows, 2000
return

ChangeAllWordWindows:
{
; ѕолучаем список всех окон Word (класс OpusApp)
WinGet, idList, List, ahk_class OpusApp
Loop, %idList%
{
hWord := idList%A_Index%
; ѕолучаем дочерние окна с классом _WwB внутри каждого окна Word
WinGet, childList, ControlListHwnd, ahk_id %hWord%
Loop, Parse, childList, `n
{
hwnd := A_LoopField
WinGetClass, className, ahk_id %hwnd%
if (className = "_WwB")
{
WinGetTitle, currentText, ahk_id %hwnd%
if (currentText = "")
continue
            newText := currentText
            ; ”даление первой приписки
            if InStr(newText, "режим совместимости")
                newText := StrReplace(newText, "  -  режим совместимости", "")

            ; ”даление фраз, св€занных с "последнее сохранение пользователем" (несколько вариантов, регистронезависимо)
            ; ѕримеры: "ѕоследнее сохранение пользователем", "посл. сохранение: пользователь", "сохранено пользователем"
            ; »спользуем RegExReplace с (?i) дл€ регистронезависимого удалени€
            newText := RegExReplace(newText, "(?i)\s\*(последн(ее|а€|ий)?\s\*сохранен(ие|о|о:)?\s\*(пользовател(€|ем|ь))?)\s\*", " ")
            newText := RegExReplace(newText, "(?i)\s\*(посл(едн|дн)\\.?\s\*сохранен(ие|о))\s\*", " ")
            newText := RegExReplace(newText, "(?i)\s\*(сохранено\s\*пользователем)\s\*", " ")
            newText := RegExReplace(newText, "(?i)\s\*(последнее сохранение:.\*пользовател[^\s]\*)\s\*", " ")

            ; ”далим возможные двойные пробелы и крайние пробелы
            newText := RegExReplace(newText, "[\s]{2,}", " ")
            newText := Trim(newText)

            if (newText != currentText)
            {
                ; ¬ыдел€ем пам€ть дл€ строки
                VarSetCapacity(wText, (StrLen(newText) + 1) * 2, 0)
                StrPut(newText, &wText, "UTF-16")
                ; ќтправл€ем WM\_SETTEXT (0x000C) с указателем на строку
                DllCall("User32.dll\SendMessageW", "Ptr", hwnd, "UInt", 0x000C, "Ptr", 0, "Ptr", &wText)
            }
        }
    }
}
}
return