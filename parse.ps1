# Указание пути к исходной и целевой папкам
$sourceFolder = "W:\LOGS\"
$destinationFolder = "W:\test2"

# Создание целевой папки, если она не существует
if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# Получение списка всех файлов .txt в исходной папке и ее подпапках
$txtFiles = Get-ChildItem -Path $sourceFolder -Recurse -Filter *.txt

# Определение скрипта, который будет копировать файлы с рандомными именами
$copyScript = {
    param($sourceFile, $destinationFolder)
    
    # Генерация случайного имени файла
    $randomName = [System.IO.Path]::GetRandomFileName() -replace '\.', ''
    $randomFileName = "$randomName.txt"

    # Полный путь к целевому файлу
    $destinationFilePath = Join-Path -Path $destinationFolder -ChildPath $randomFileName

    # Копирование файла в целевую папку с новым именем
    Copy-Item -Path $using:sourceFile.FullName -Destination $using:destinationFilePath -Force
}

# Запуск копирования файлов в параллельных потоках с ограничением по числу потоков
$txtFiles | ForEach-Object -Parallel {
    $copyScript.Invoke($_, $using:destinationFolder)
} -ThrottleLimit 30
