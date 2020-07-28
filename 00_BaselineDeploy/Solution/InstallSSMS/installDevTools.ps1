# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Software if it isn't already installed
$AppPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.exe" 
$IsAppInstalled = Test-Path $AppPath -PathType Leaf

if (-not($IsAppInstalled)) {
    choco install sql-server-management-studio -y
} 

$BrowserPath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$IsBrowserInstalled = Test-Path $BrowserPath -PathType Leaf

if (-not($IsBrowserInstalled)) {
    choco install microsoft-edge -y
} 

$GitPath = "C:\Program Files\Git\git-cmd.exe"
$IsGitInstalled = Test-Path $GitPath -PathType Leaf

if (-not($IsGitInstalled)){
    choco install git -y
}

$IDEPath = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe"
$IsIDEInstalled = Test-Path $IDEPath -PathType Leaf

if (-not($IsIDEInstalled)) {
    choco install visualstudio2019community -y 
}

Restart-Computer 