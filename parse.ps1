# �������� ���� � �������� � ������� ������
$sourceFolder = "W:\LOGS\"
$destinationFolder = "W:\test2"

# �������� ������� �����, ���� ��� �� ����������
if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

# ��������� ������ ���� ������ .txt � �������� ����� � �� ���������
$txtFiles = Get-ChildItem -Path $sourceFolder -Recurse -Filter *.txt

# ����������� �������, ������� ����� ���������� ����� � ���������� �������
$copyScript = {
    param($sourceFile, $destinationFolder)
    
    # ��������� ���������� ����� �����
    $randomName = [System.IO.Path]::GetRandomFileName() -replace '\.', ''
    $randomFileName = "$randomName.txt"

    # ������ ���� � �������� �����
    $destinationFilePath = Join-Path -Path $destinationFolder -ChildPath $randomFileName

    # ����������� ����� � ������� ����� � ����� ������
    Copy-Item -Path $using:sourceFile.FullName -Destination $using:destinationFilePath -Force
}

# ������ ����������� ������ � ������������ ������� � ������������ �� ����� �������
$txtFiles | ForEach-Object -Parallel {
    $copyScript.Invoke($_, $using:destinationFolder)
} -ThrottleLimit 30
