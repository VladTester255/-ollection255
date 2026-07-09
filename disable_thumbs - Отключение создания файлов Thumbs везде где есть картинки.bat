@echo off
chcp 65001 >nul

:: Проверка прав администратора
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ОШИБКА] Пожалуйста, запустите этот скрипт от имени Администратора!
    pause
    exit /b
)

echo Внесение изменений в реестр для отключения Thumbs.db...

:: 1. Глобальное отключение кэширования для текущего пользователя
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "NoThumbnailCache" /t REG_DWORD /d 1 /f

:: 2. Отключение кэширования в сетевых папках для текущего пользователя
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v "DisableThumbsDBOnNetworkFolders" /t REG_DWORD /d 1 /f

:: 3. Дублирование настроек на уровне всей системы (для всех пользователей)
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoThumbnailCache" /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "DisableThumbsDBOnNetworkFolders" /t REG_DWORD /d 1 /f

echo Настройки реестра успешно применены.

:: 4. Перезапуск Проводника для применения настроек без перезагрузки ПК
echo Перезапуск Проводника Windows...
taskkill /f /im explorer.exe >nul
start explorer.exe

echo Всё готово! Создание файлов Thumbs.db полностью отключено.
pause
