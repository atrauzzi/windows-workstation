# Before running: `Set-ExecutionPolicy Unrestricted`
#                 or `Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser`

# Get the ID and security principal of the current user account
$myWindowsId=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsId)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole)) {

    # Style things up a lil'.
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
    $Host.UI.RawUI.BackgroundColor = "DarkCyan"
    $Host.UI.RawUI.ForegroundColor = "DarkBlue"
    clear-host

    ###
    # General Setup
    #

    Write-Host "🛠 Getting ready."

    $shouldRestart = $false
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    
    #
    ###

    ###
    # Enable Developer Mode
    #

    # Create AppModelUnlock if it doesn't exist, required for enabling Developer Mode
    $RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    if (-not(Test-Path -Path $RegistryKeyPath)) {
        New-Item -Path $RegistryKeyPath -ItemType Directory -Force
        New-ItemProperty -Path $RegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -PropertyType DWORD -Value 1
        Write-Host "🛠 Developer mode enabled."
    }
    else {
        Write-Host "🛠 Developer mode already enabled, skipping."
    }

    #
    ###

    ###
    # Make PowerShell Better
    #

    Install-PackageProvider -Force -Name NuGet
    Install-Module -Force PSReadline -SkipPublisherCheck
    Install-Module -Force posh-git
    Add-PoshGitToProfile
    
    #
    ###

    ###
    # Enable Features
    #

    $features = @(
        "Microsoft-Windows-Subsystem-Linux",
        "Microsoft-Hyper-V-All",
        "Microsoft-Hyper-V-Tools-All",
        "Microsoft-Hyper-V-Management-Clients",
        "Microsoft-Hyper-V-Management-PowerShell"
        "Microsoft-Hyper-V",
        "Microsoft-Hyper-V-Hypervisor",
        "Microsoft-Hyper-V-Services",
        "VirtualMachinePlatform"
    )

    $badFeatures = @(
        "Internet-Explorer-Optional-amd64"
    );

    $featureResults = @()

    Write-Host "🛠 Enabling Features"
    foreach($feature in $features) {
        $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -LimitAccess
        $featureResults += $result
    }

    Write-Host "🛠 Disabling Unwanted Features"
    foreach($badFeature in $badFeatures) {
        Disable-WindowsOptionalFeature -Online -FeatureName $feature
    }

    ###
    # Copy to Clipboard in Explorer
    #
    
    Write-Host "🛠 Enabling Copy to Clipboard for all files in explorer."

    # New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

    $allFilesShellConfig = Get-Item -LiteralPath "HKCR:\"
    $shellConfig = $allFilesShellConfig.OpenSubKey("*\shell", $true)
    $copyToClipboardConfig = $shellConfig.CreateSubKey("CopyToClipboard")

    $copyToClipboardConfig.SetValue($null, "Copy to Clipboard")
    $copyToClipboardConfig.SetValue('icon', 'DxpTaskSync.dll,-52')
    $copyToClipboardCommand = $copyToClipboardConfig.CreateSubKey("command")
    $copyToClipboardCommand.SetValue($null, 'cmd /c clip < "%1"')
    
    # (Modify to not require shift) http://www.howtogeek.com/howto/windows-vista/create-a-context-menu-item-to-copy-a-text-file-to-the-clipboard-in-windows-vista/
    
    #
    ###

    ###
    # Applications
    #

    Write-Host "🛠 Installing Applications."

    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    choco install git
    choco install 7zip
    choco install hackfont
    choco install vscode
    choco install azure-data-studio
    choco install microsoftazurestorageexplorer
    choco install nodejs
    choco install dotnetcore
    choco install openjdk
    choco install postman
    choco install transmission
    choco install windirstat
    choco install etcher
    choco install bfg-repo-cleaner

    #
    ###

    ###
    # ToDo.
    #

    # Visual Studio
    # Docker
   
    # Generate Key
    # Azure Storage Emulator
    #netsh interface portproxy add v4tov4 listenport=10000 listenaddress=127.0.0.1 connectport=10000 connectaddress=10.0.75.1
    #netsh interface portproxy add v4tov4 listenport=10001 listenaddress=127.0.0.1 connectport=10001 connectaddress=10.0.75.1
    #netsh interface portproxy add v4tov4 listenport=10002 listenaddress=127.0.0.1 connectport=10002 connectaddress=10.0.75.1
    # LINQpad?

    # git config core.autocrlf false

    #
    ###

    if($shouldRestart) {
        Write-Host "⚠️"
        Write-Host "⚠️ At least one operation has suggested that a restart be performed."
        Write-Host "⚠️"
        Restart-Computer -Confirm
    }
    else {
    }

    Read-Host -Prompt '📋 All done, press enter to close this window!'

}
else {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo 'PowerShell';
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = 'runas';
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   Write-Host
   Write-Host '🖥 A new Powershell window should have requested elevated access.'
   Write-Host
   Write-Host 'You can have this terminal back now!'

}
