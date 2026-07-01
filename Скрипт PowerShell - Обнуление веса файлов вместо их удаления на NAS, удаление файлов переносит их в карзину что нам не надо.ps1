# Запрос путей у пользователя
$sourceDir = Read-Host "Введите путь к исходной папке (например, C:\Source)"
$targetDir = Read-Host "Введите путь к целевой папке (например, D:\Target)"

# Проверка, существует ли исходная папка
if (-not (Test-Path $sourceDir)) {
    Write-Error "Исходная папка не найдена! Проверьте путь и повторите попытку."
    Exit
}

# Получаем все файлы и папки из исходной директории
Get-ChildItem -Path $sourceDir -Recurse | ForEach-Object {
    # Вычисляем новый путь для целевого объекта
    $targetPath = $_.FullName.Replace($sourceDir, $targetDir)
    
    if ($_.PSIsContainer) {
        # Если это папка, создаем её, если еще не создана
        if (-not (Test-Path $targetPath)) {
            New-Item -ItemType Directory -Path $targetPath | Out-Null
        }
    } else {
        # Если это файл, создаем целевую папку для него (на случай пустых подпапок)
        $parentDir = Split-Path $targetPath
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir | Out-Null
        }
        
        # Создаем пустой файл (0 байт)
        New-Item -ItemType File -Path $targetPath -Force | Out-Null
        
        # Копируем абсолютно все временные метки оригинального файла
        (Get-Item $targetPath).CreationTime = $_.CreationTime
        (Get-Item $targetPath).LastWriteTime = $_.LastWriteTime
        (Get-Item $targetPath).LastAccessTime = $_.LastAccessTime
    }
}

Write-Host "Готово! Все файлы успешно скопированы с нулевым размером." -ForegroundColor Green
