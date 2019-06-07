# Before running: `Set-ExecutionPolicy Unrestricted`

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

    Install-Module -Confirm PSReadline
    Install-Module -Confirm posh-git
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
        "Microsoft-Hyper-V-Services"
    )

    $featureResults = @()

    Write-Host "🛠 Enabling Features"
    foreach($feature in $features) {
        $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -LimitAccess
        $featureResults += $result
    }

    ###
    # Copy to Clipboard in Explorer
    #
    
    Write-Host "🛠 Enabling Copy to Clipboard for all files in explorer."
    
    $allFilesShellConfig = Get-Item -LiteralPath "HKCR:\*\shell"
    $allFilesConfig.CreateSubKey("CopyToClipboard")
    
    $copyToClipboardConfig = Get-Item -LiteralPath "HKCR:\*\shell\CopyToClipboard"

    New-Item -Path "HKCR:\*\shell\copytoclipboard" -Name "copytoclipboard" –Force
    New-ItemProperty -Path "HKCR:\*\shell\copytoclipboard" -Name "(default)" -Value "Copy to Clipboard"
    New-ItemProperty -Path "HKCR:\*\shell\copytoclipboard" -Name "Icon" -Value "📋"
    New-Item -Path "HKCR:\*\shell\copytoclipboard\command" -Name "command" –Force
    New-ItemProperty -Path "HKCR:\*\shell\copytoclipboard\command" -Name "(default)" -Value "cmd /c clip < \"%1\""
    
    # (Modify to not require shift) http://www.howtogeek.com/howto/windows-vista/create-a-context-menu-item-to-copy-a-text-file-to-the-clipboard-in-windows-vista/
    
    #
    ###

    # Docker
    # SQL Server 2016
    # SQL Server Management Studio
    # Visual Studio
    # Git
    
    # git config core.autocrlf false
    
    # Git Kraken
    # Generate Key
    # POSH-git
    # Azure Storage Client
    # Azure Storage Emulator
    #netsh interface portproxy add v4tov4 listenport=10000 listenaddress=127.0.0.1 connectport=10000 connectaddress=10.0.75.1
    #netsh interface portproxy add v4tov4 listenport=10001 listenaddress=127.0.0.1 connectport=10001 connectaddress=10.0.75.1
    #netsh interface portproxy add v4tov4 listenport=10002 listenaddress=127.0.0.1 connectport=10002 connectaddress=10.0.75.1
    # LINQpad?
    # Input font
    # 7zip
    # docker run -p 8079:80 -p 587:25 -d --restart always djfarrelly/maildev
    # tcp://localhost:2375 is the docker for windows local API endpoint
    # Ports can be forwarded using: http://stackoverflow.com/questions/11525703/port-forwarding-in-windows

    foreach($result in $featureResults) {
        
    }

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

    Read-Host -Prompt "📋 All done, press enter to close this window!"

}
else {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   Write-Host
   Write-Host "🖥 A new Powershell window should have requested elevated access."
   Write-Host
   Write-Host "You can have this terminal back now!"

}
