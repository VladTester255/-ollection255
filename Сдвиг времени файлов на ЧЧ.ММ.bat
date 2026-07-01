@echo off
rem === НАСТРОЙКИ ===
rem Если нужно искать в подпапках, оставьте -Recurse. Если нет — удалите это слово.
set "RECURSE_FLAG=-Recurse"

rem Укажите количество часов и минут для прибавления
set "HOURS=-1"
set "MINS=-8"

echo Обработка файлов... Подождите.

rem Запуск PowerShell из CMD в одну строку, чтобы избежать ошибок синтаксиса
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -File %RECURSE_FLAG% | ForEach-Object { $_.LastWriteTime = $_.LastWriteTime.AddHours(%HOURS%).AddMinutes(%MINS%); $_.CreationTime = $_.LastWriteTime }"

echo.
echo Готово! Прибавлено: %HOURS% ч. %MINS% мин.
echo Опция подпапок: %RECURSE_FLAG%
pause