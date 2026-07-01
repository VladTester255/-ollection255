param(
    [Parameter(Mandatory=$true)]
    [string]$DocxPath
)
# Убираем кавычки в начале и конце пути, если они есть
$DocxPath = $DocxPath.Trim('"', "'")

if (-not (Test-Path $DocxPath)) {
    Write-Error "Файл не найден: $DocxPath"
    exit 1
}

$tempFolder = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempFolder | Out-Null

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($DocxPath, $tempFolder)

    $stylesPath = Join-Path $tempFolder "word\styles.xml"
    if (-not (Test-Path $stylesPath)) {
        throw "Файл styles.xml не найден в архиве"
    }

    # Загружаем XML с помощью XmlDocument
    $xml = New-Object System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true  # важно сохранить форматирование
    $xml.Load($stylesPath)

    # Удаляем все элементы <w:qFormat/> и атрибуты w:qFormat="1"
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $namespaceManager.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")

    # Удаляем все <w:qFormat/> элементы
    $qFormatNodes = $xml.SelectNodes("//w:qFormat", $namespaceManager)
    foreach ($node in $qFormatNodes) {
        $parent = $node.ParentNode
        $parent.RemoveChild($node) | Out-Null
    }

    # Удаляем атрибуты w:qFormat="1" у всех элементов
    $nodesWithAttr = $xml.SelectNodes("//*[@w:qFormat='1']", $namespaceManager)
    foreach ($node in $nodesWithAttr) {
        $node.RemoveAttribute("qFormat", $namespaceManager.LookupNamespace("w"))
    }

    # Сохраняем XML обратно с UTF-8 без BOM
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $stream = [System.IO.File]::Open($stylesPath, [System.IO.FileMode]::Create)
    $writer = New-Object System.Xml.XmlTextWriter($stream, $utf8NoBom)
    $writer.Formatting = "Indented"
    $xml.WriteContentTo($writer)
    $writer.Flush()
    $writer.Close()
    $stream.Close()

    # Формируем имя нового файла
    $dir = Split-Path $DocxPath
    $file = Split-Path $DocxPath -Leaf
    $newFile = Join-Path $dir ("!" + $file)

    if (Test-Path $newFile) { Remove-Item $newFile -Force }

    # Запаковываем обратно
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempFolder, $newFile)

    Write-Output "Обработанный файл сохранён: $newFile"
}
catch {
    Write-Error "Произошла ошибка: $_"
}
finally {
    if (Test-Path $tempFolder) {
        Remove-Item $tempFolder -Recurse -Force
    }
}

# В конце скрипта
Read-Host -Prompt "Нажмите Enter для выхода"
