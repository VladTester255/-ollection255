@echo off
setlocal enabledelayedexpansion
chcp 1251 >nul

rem --- Ввод данных ---
set /p repoName=Введите имя репозитория: 
set /p revRange=Введите диапазон ревизий (пример: 100:200), или оставьте пустым для полного дампа: 
set /p savePath=Введите путь для сохранения дампа, или оставьте пустым для сохранения в папке репозитория: 

rem --- Пути ---
set reposBasePath=D:\Repositories

rem --- Поиск реального имени папки репозитория с правильным регистром ---
set foundRepoName=
for /d %%D in ("%reposBasePath%\*") do (
    set "folderName=%%~nxD"
    if /i "!folderName!"=="%repoName%" (
        set foundRepoName=!folderName!
        goto :foundRepo
    )
)
echo Репозиторий "%repoName%" не найден в папке "%reposBasePath%"
goto :eof

:foundRepo
set repoName=%foundRepoName%
set repoPath=%reposBasePath%\%repoName%

rem Если путь для сохранения дампа пустой, используем папку репозитория
if "%savePath%"=="" (
    set savePath=%repoPath%
)

rem Получаем дату-время для имени файла
for /f "tokens=2 delims==." %%I in ('wmic os get localdatetime /value ^| find "="') do set ldt=%%I
set year=%ldt:~0,4%
set month=%ldt:~4,2%
set day=%ldt:~6,2%
set hour=%ldt:~8,2%
set minute=%ldt:~10,2%
set second=%ldt:~12,2%
set datetime=%year%%month%%day%_%hour%%minute%%second%

rem --- Обработка revRange для имени файла ---
if "%revRange%"=="" (
    rem Если пусто, подставляем 0+0
    set revRangeForFile=0+0
) else (
    rem Заменяем двоеточие ':' на плюс '+' для имени файла
    set revRangeForFile=%revRange::=+%
)

rem Формируем имя файла дампа
set dumpFileName=%repoName%-%revRangeForFile%_%datetime%.dump
set dumpFile=%savePath%\%dumpFileName%

rem Создаём папку для дампа, если нет
if not exist "%savePath%" (
    mkdir "%savePath%"
)

rem Путь к svnadmin.exe
set svnadminPath=C:\Program Files\VisualSVN Server\bin\svnadmin.exe

rem --- Создание дампа ---
if "%revRange%"=="" (
    echo Выполняется: "%svnadminPath%" dump "%repoPath%" > "%dumpFile%"
    "%svnadminPath%" dump "%repoPath%" > "%dumpFile%"
) else (
    echo Выполняется: "%svnadminPath%" dump "%repoPath%" -r %revRange% --incremental > "%dumpFile%"
    "%svnadminPath%" dump "%repoPath%" -r %revRange% --incremental > "%dumpFile%"
)

if %ERRORLEVEL% neq 0 (
    echo Ошибка при создании дампа
    goto :eof
)

echo Дамп успешно создан: %dumpFile%

rem --- Создание нового репозитория с приставкой -DUMP и добавлением номера, если уже существует ---
set baseNewRepoName=%repoName%-DUMP
set newRepoName=%baseNewRepoName%
set newRepoPath=%reposBasePath%\%newRepoName%

set /a suffix=0
:checkRepoExists
if exist "%newRepoPath%" (
    set /a suffix+=1
    set newRepoName=%baseNewRepoName%%suffix%
    set newRepoPath=%reposBasePath%\%newRepoName%
    goto checkRepoExists
)

echo Создаём новый репозиторий "%newRepoName%"...
"%svnadminPath%" create "%newRepoPath%"
if %ERRORLEVEL% neq 0 (
    echo Ошибка при создании нового репозитория
    goto :eof
)

rem --- Загрузка дампа в новый репозиторий ---
echo Импортируем дамп в новый репозиторий...
"%svnadminPath%" load "%newRepoPath%" < "%dumpFile%"
if %ERRORLEVEL% neq 0 (
    echo Ошибка при загрузке дампа
    goto :eof
)

rem --- Копирование хуков ---
set hooksSource=%repoPath%\hooks
set hooksDest=%newRepoPath%\hooks

if exist "%hooksSource%" (
    echo Копирование хуков из "%hooksSource%" в "%hooksDest%"
    if not exist "%hooksDest%" mkdir "%hooksDest%"
    xcopy /E /I /Y "%hooksSource%\*" "%hooksDest%\"
    echo Копирование хуков завершено.
) else (
    echo Папка хуков не найдена в исходном репозитории, пропуск копирования хуков.
)

rem --- Копирование конфигурации ---
set confSource=%repoPath%\conf
set confDest=%newRepoPath%\conf

if exist "%confSource%" (
    echo Копирование конфигурации из "%confSource%" в "%confDest%"
    if not exist "%confDest%" mkdir "%confDest%"
    xcopy /E /I /Y "%confSource%\*" "%confDest%\"
    echo Копирование конфигурации завершено.
) else (
    echo Папка конфигурации не найдена в исходном репозитории, пропуск копирования конфигурации.
)

pause
endlocal
