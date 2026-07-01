# Получаем папку со скриптом
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Получаем все *.eml файлы в папке скрипта
Get-ChildItem -Path $scriptDir -Filter *.eml | ForEach-Object {
    $file = $_
    $name = $file.Name

    # Паттерн: " - YYYY-MM-DD HHmm" в конце имени файла перед расширением
    # Регулярное выражение для поиска даты и времени
    if ($name -match '- (\d{4})-(\d{2})-(\d{2}) (\d{2})(\d{2})') {
        $year = $matches[1]
        $month = $matches[2]
        $day = $matches[3]
        $hour = $matches[4]
        $minute = $matches[5]

        # Формируем объект DateTime
        try {
            $dt = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second 0

            # Смена дат файла
            # DateCreated изменить можно, но в некоторых системах нужны права администратора
            $file.CreationTime = $dt
            $file.LastWriteTime = $dt

            Write-Host "Даты изменены для файла:" $file.Name "->" $dt
        }
        catch {
            Write-Warning "Неверная дата в файле: $name"
        }
    }
    else {
        Write-Host "Дата в имени не найдена для файла:" $file.Name
    }
}
