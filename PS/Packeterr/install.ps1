# This Powershell script launches the install application (for SCCM applications)
# Created by EUC Seresco Team on July 2019. Last Update: November 2023
# Author: Olaya Conde Diaz, Carlos Joaquin Roza Lopez, Oscar Lopez Fernandez, Borja Gonzalez Pardo
# Version: 0.96
param (
    [string]$appArgs = ""
)

############################################### VALUES TO CHANGE ##############################################################
$installationArgs = "/q"
$uninstallArgs = "{CD444C9C-EFD2-4CB8-9480-1BC009C98C9F}"
$internalName = "TestP"
$activeSetup = 0
###############################################################################################################################

function MainLoop() {
    # Gets the application code and the install path
    $applicationCode, $installPath = Initialize-Vars

    # Initialize C:\IT\LOGS\{PACKAGE} and returns the path to the folder
    $logPath = Initialize-Loggin -ApplicationCode $applicationCode

    # Starts the logging
    Start-Transcript -Path ($logPath + "\" + $applicationCode + ".log") -Append

    # Gets the name of the installer, extension and version based on the LOCAL install path (MSI or EXE)
    $applicationToRun, $applicationVersion = Get-Details -localPath $installPath

    # Check available space, default 1GB
    Test-Space -spaceRequired 1

    # Copy inventory
    $inventory = Copy-Inventory -localPath ".\" -ApplicationCode $applicationCode
    # TODO: HACKY BIT
    $inventory = $inventory

    # Starts the installation of the packages based on the LOCAL path, name of the installer, arguments and extension
    $code = Install-Package -installPath $installPath -name $applicationToRun -installArgs $installationArgs -logPath $logPath
    Write-Host "$(Get-Date) Install code: $code"

    # Write here your own code! Defaults to 0
    $code = Install-Personalized
    Write-Host "$(Get-Date) Custom install exit code: $code"

    # Add the registry values based on the application code(SXXXXMVV) and version
    Add-Registry-Record -applicationCode $applicationCode -applicationName $internalName -applicationVersion $applicationVersion
    
    # Active setup
    Invoke-ActiveSetup -launchSetup $activeSetup -applicationCode $applicationCode -applicationName $internalName
    
    # Stops logging
    Stop-Transcript
}

function Uninstall {
    # Gets the application code and the install path
    $applicationCode, $installPath = Initialize-Vars

    # Initialize C:\IT\LOGS\{PACKAGE} and returns the path to the folder
    $logPath = Initialize-Loggin -ApplicationCode $applicationCode

    # Starts the logging
    Start-Transcript -Path ($logPath + "\" + $applicationCode + ".log") -Append

    # Gets the name of the installer, extension and version based on the LOCAL install path (MSI or EXE)
    $applicationToRun, $applicationVersion = Get-Details -localPath $installPath
	
    # Start standard uninstall
    $code = Install-Package -installPath $installPath -name $applicationToRun -installArgs $uninstallArgs -uninstall 1 -logPath $logPath
    Write-Host "$(Get-Date) Uninstall code: $code"

    # Write here your own code! Defaults to 0
    $code = Uninstall-Personalized
    Write-Host "$(Get-Date) Custom install exit code: $code"

    # Remove registry records
    Remove-RegistryRecord -applicationCode $applicationCode

    # Active setup uninstall
    Invoke-ActiveSetup -launchSetup $activeSetup -applicationCode $applicationCode -applicationName $internalName -uninstallActiveSetup 1
    
    # Remove inventory if active setup is not enabled
    Remove-Inventory -applicationCode $applicationCode -launchSetup $activeSetup
    
    # Stops logging
    Stop-Transcript
}

##############################################################################################################################
##                                                     FUNCTIONS                                                            ##
##############################################################################################################################
function Install-Personalized() {
    Write-Host "$(Get-Date) No personalized setup found. Skipping"
    return 0
}
function Uninstall-Personalized() {
    Write-Host "$(Get-Date) No personalized setup found. Skipping"
    return 0
}

function Invoke-ActiveSetup() {
    # This function creates the active setup record for the application
    # It does not return anything
    param (
        [int]$launchSetup,
        [string]$applicationCode,
        [string]$applicationName,
        [int]$uninstallActiveSetup = 0
    )
    # Checks the system architecture
    $architecture = $env:PROCESSOR_ARCHITECTURE
    Write-Host("$(Get-Date) System is $architecture")
	
    # Checks if the active setup is enabled
    if ($launchSetup -eq 1) {
        # Prepares the stub path for the active setup
        $stubPath = "CMD /C CSCRIPT.exe //nologo C:\IT\Soft\$applicationCode\IT_HKCU.vbs"
        # Checks if it is an uninstall
        if ($uninstallActiveSetup -eq 1) {
            # Removes the previous active setup record
            Remove-Item -Path HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\$applicationCode -ErrorAction SilentlyContinue
            Remove-Item -Path HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$applicationCode -ErrorAction SilentlyContinue
            
            # Prepares the new registry key for the uninstall active setup
            $applicationCode = $applicationCode + "-U"
            $stubPath = "CMD /C CSCRIPT.exe //nologo C:\IT\Soft\$applicationCode\IT_HKCU-uninst.vbs"
        }
        else {
            Write-Host "$(Get-Date) Injecting record for active setup"
            # If the system is x64, it creates the active setup record in the 64 bits registry
            if ($architecture = "x64") {
                Write-Host $((if ($null -ne (New-Item -Path HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\ -Name $applicationCode -ErrorAction SilentlyContinue)) { "$(Get-Date) Active setup key registered successfully" } else { "$(Get-Date) Active setup key could not be created" }))
                $result = & { $test = New-ItemProperty -path HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name ComponentID -value $applicationName -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                $result += & { $test = New-ItemProperty -path HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name IsInstalled -value 1 -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                $result += & { $test = New-ItemProperty -path HKLM\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name StubPath -value $stubPath -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                Write-Host $(if ($result -eq 0) { "$(Get-Date) Registry properties applied" } else { "$(Get-Date) Error applying properties" })
            }
            # If the system is x86, it creates the active setup record in the 32 bits registry
            else {
                Write-Host $((if ($null -ne (New-Item -Path HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\ -Name $applicationCode -ErrorAction SilentlyContinue)) { "$(Get-Date) Active setup key registered successfully" } else { "$(Get-Date) Active setup key could not be created" }))
                $result = & { $test = New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name ComponentID -value $applicationName -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name IsInstalled -value 1 -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$applicationCode -propertyType String -Name StubPath -value $stubPath -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
                Write-Host $(if ($result -eq 0) { "$(Get-Date) Registry properties applied" } else { "$(Get-Date) Error applying properties" })
            }
        }
    }
    else {
        Write-Host "$(Get-Date) No active setup component. Skipping..."
    }
}

function Test-Space {
    # This function checks if there is enough space in the disk to install the application
    # It does not return anything
    param (
        [int]$spaceRequired
    )
    try {
        # Gets the free space in the disk
        $spaceLeft = [math]::Round(((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID = 'C:'").FreeSpace ) / 1GB, 2)
        Write-Host ("$(Get-Date) Available space: " + $spaceLeft + "GB of " + $spaceRequired + "GB required")
        # If the space is less than the required space, it throws an error
        if ($spaceLeft -le $spaceRequired) {
            throw "Not enough space left in disk"
        }
        Write-Host "$(Get-Date) Free disk space OK."
    }
    catch {
        # Handles the error
        Exit-Gracefully($_)
    }
}
function Copy-Inventory {
    # This function copies the inventory folder to the local machine in the C:\IT\SOFT\ folder
    # It returns the object of the copied folder
    param (
        [string]$localPath,
        [string]$applicationCode
    )
    try {
        # Copies the inventory folder to the local machine 
        $object = Copy-Item -Path $localPath -Destination "C:\IT\SOFT\$applicationCode" -Recurse -PassThru -Force
        $pathToInventory = $object[0]
        # Checks if the folder was copied
        if ($null -ne $object) {
            Write-Host "$(Get-Date) Inventory copied to $pathToInventory"
        }
        else {
            # If the folder was not copied, it throws an error
            throw "Could not copy inventory, aborting"
        }
    }
    catch {
        # Handles the error
        Exit-Gracefully($_)
    }
    return $pathToInventory
}
function Remove-Inventory {
    # This function copies the inventory folder to the local machine in the C:\IT\SOFT\ folder
    # It returns the object of the copied folder
    param (
        [int]$activeSetup,
        [string]$applicationCode
    )
    # Checks if the active setup is enabled
    if ($activeSetup -eq 0) {
        Write-Host "$(Get-Date) Removing inventory folder $applicationCode"
        Remove-Item -Path "C:\IT\SOFT\$applicationCode" -Recurse
    }
    else {
        Write-Host "$(Get-Date) Active setup enabled, skipping inventory removal"
    }

}

function Add-Registry-Record() {
    # This function adds the registry record for the application acording to the application code (SXXXXMVV) and version
    # It doesnt return anything
    param (
        [string]$applicationCode,
        [string]$applicationName,        
        [string]$applicationVersion
    )
    # Gets the date
    $date = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    # Write to the 32 bits registry
    Write-Host "$(Get-Date) Writing 32 bits register"
    Write-Host $(if ($null -ne (New-Item -Path HKLM:\SOFTWARE\IT\INVENTORY -Name $applicationCode -ErrorAction SilentlyContinue)) { "Registry key created successfully" } else { "Failed to create the registry key" })

    # Write properties
    $result = & { $test = New-ItemProperty -path HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode -propertyType String -Name InstallDate -value $date -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode -propertyType String -Name ProductName -value $applicationName -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode -propertyType String -Name ProductVersion -value $applicationVersion -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    Write-Host $(if ($result -eq 0) { "$(Get-Date) Registry properties applied" } else { "$(Get-Date) Error applying properties" })

    # Write to the 32 bits registry
    Write-Host "$(Get-Date) Writing 32 bits register"
    Write-Host $(if ($null -ne (New-Item -Path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY -Name $applicationCode -ErrorAction SilentlyContinue)) { "$(Get-Date) Registry key created successfully" } else { "$(Get-Date) Failed to create the registry key" })

    # Write properties
    $result = & { $test = New-ItemProperty -path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode -propertyType String -Name InstallDate -value $date -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode -propertyType String -Name ProductName -value $applicationName -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    $result += & { $test = New-ItemProperty -path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode -propertyType String -Name ProductVersion -value $applicationVersion -ErrorAction SilentlyContinue; if ($null -ne $test) { 0 } else { 1 } }
    Write-Host $(if ($result -eq 0) { "$(Get-Date) Registry properties applied" } else { "$(Get-Date) Error applying properties" })
}

function Initialize-Vars() {
    # This function initializes the variables for the script
    # It returns the application code from the file name and the install path

    # Gets the application code
    $applicationCode = (Get-Item $MyInvocation.PSCommandPath).Name.Substring(5, (Get-Item $MyInvocation.PSCommandPath).Name.LastIndexOf('.') - 5)
    
    # Gets the install path
    $installPath = ".\$(Get-ChildItem -Path './' -Directory)"
    
    # Returns the application code and the install path
    return $applicationCode, $installPath
}

function Remove-RegistryRecord() {
    param (
        [string]$applicationCode
    )
    # Remove 32 registry entries
    Write-Host "$(Get-Date) Removing 32 bits registry entry -> HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode"
    Remove-Item -Path HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode -ErrorAction SilentlyContinue

    # Check if the registry was removed
    Write-Host $(if (Test-Path -Path HKLM:\SOFTWARE\IT\INVENTORY\$applicationCode) { "$(Get-Date) Registry could not be removed" } else { "$(Get-Date) Registry removed" })
    
    # Remove 64 registry entries
    Write-Host "$(Get-Date) Removing 64 bits registry entry -> HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode"
    Remove-Item -Path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode -ErrorAction SilentlyContinue
    
    # Check if the registry was removed
    Write-Host $(if (Test-Path -Path HKLM:\SOFTWARE\WOW6432Node\IT\INVENTORY\$applicationCode) { "$(Get-Date) Registry could not be removed" } else { "$(Get-Date) Registry removed" })
}
function Get-Details() {
    param (
        [string]$localPath
    )
    # Get the absolute path
    $absolutePath = Resolve-Path -Path $localPath
    Write-Host "$(Get-Date) Absolute path to the sources folder: $absolutePath"
    
    # Get the contents of the path
    $localPathContents = Get-ChildItem $absolutePath
    
    # Checks path contents and checks if the folder has an .exe or .msi file
    $appPath = $localPathContents | Where-Object { $_.Extension -eq ".exe" -or $_.Extension -eq ".msi" } | Select-Object -First 1
    
    # Checks if the folder has an .exe or .msi file
    if ($appPath) {
        if ($appPath.Extension -eq ".msi") {
            $windowsInstaller = New-Object -com WindowsInstaller.Installer
            $database = $windowsInstaller.GetType().InvokeMember(
                "OpenDatabase", "InvokeMethod", $Null,
                $windowsInstaller, @($appPath.FullName, 0)
            )
    
            $q = "SELECT Value FROM Property WHERE Property = 'ProductVersion'"
            $View = $database.GetType().InvokeMember(
                "OpenView", "InvokeMethod", $Null, $database, ($q)
            )
            
            # Get the details from the MSI
            $handle = $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)
            $record = ($View.GetType().InvokeMember( "Fetch", "InvokeMethod", $Null, $View, $Null ))
            # Get the version
            $version = $record.GetType().InvokeMember( "StringData", "GetProperty", $Null, $record, 1 )
            
            # Close the objects and records
            $handle = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($database)
            $handle = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($View)
            $handle = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($windowsInstaller)

            #TODO: HACKY BIT
            $handle = $handle

            return $appPath.Name, $version
        }

        # Get the version from the EXE
        $versionInfo = (Get-Item (Join-Path -Path $absolutePath -ChildPath $appPath)).VersionInfo.FileVersionRaw
        return $appPath.Name, $versionInfo.ToString()
    }
    
    # If the folder does not have an .exe or .msi file, it returns an empty string
    return "", ""
}

function Initialize-Loggin {
    # This function creates the folder structure for the logs
    # Returns the path to the folder in the format of C:\IT\Logs\{PACKAGE}
    param (
        [string]$applicationCode
    )
    # Gets the code of the application stripping the S and the MXX
    $logCode = $applicationCode.Substring(1, $applicationCode.Length - 3)
    # Check if the directory tree exists and creates it if it does not
    IF (-not (Test-Path C:\IT)) { New-Item -path C:\IT -ItemType Directory | Out-Null }
    IF (-not (test-path C:\IT\LOGS)) { New-Item -path C:\IT\Logs -ItemType Directory | Out-Null }
    IF (-not (test-path C:\IT\LOGS\$logCode)) { New-Item -path C:\IT\Logs\$logCode -ItemType Directory | Out-Null }

    $logPathReturn = "C:\IT\LOGS\" + $logCode
    return $logPathReturn
}

function Install-Package() {
    # This funtion installs the package based on the installer type (MSI or EXE)
    # It returns 0 if the installation was successful, 1 if it failed and -1 if the installer type is none
    param (
        [string]$installPath,
        [string]$name,
        [string]$installArgs,
        [string]$logPath,
        [int]$uninstall = 0
    )

    # Gets the extension of the installer
    $extension = $name.Substring($name.LastIndexOf('.')).ToLower()
    # Gets the absolute path of the installer
    if ($extension -ne "") {
        $absolutePath = Resolve-Path -Path $installPath
        $absolutePath = Join-Path -Path $absolutePath -ChildPath $name
    }

    # Executable process
    if ($extension -eq ".exe") {
        # Logging install arguments
        $installArgs = "$installArgs"
        Write-Host "$(Get-Date) Processing $absolutePath EXE using $installArgs"
        $process = Start-Process -FilePath $absolutePath -ArgumentList $installArgs -PassThru -Wait
    }

    if ($extension -eq ".msi" -and $uninstall -eq 0) {
        # Logging install arguments
        $installArgs = "/i $absolutePath $installArgs /L*V $logPath\$name-msi.log"
        Write-Host "$(Get-Date) Processing MSI $absolutePath using $installArgs"
        $process = Start-Process "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow -PassThru
    }

    if ($extension -eq ".msi" -and $uninstall -eq 1) {
        $installArgs = "/x$installArgs /QN /L*V $logPath\$name-msi.log"
        Write-Host "$(Get-Date) Uninstalling MSI $absolutePath using $installArgs"
        $process = Start-Process "msiexec.exe" -ArgumentList $installArgs -Wait -NoNewWindow -PassThru
    }

    return $process.ExitCode
}

function Get-MSIData() {

}

function Exit-Gracefully() {
    param (
        $optionalParameters
    )
    # Write the error to the file
    Write-Host "$(Get-Date) Error: $optionalParameters"
    # Stops logging
    Stop-Transcript
    # Exits the script with error code 1
    exit 1
}

##############################################################################################################################
##                                                     MAIN LOOP                                                            ##
##############################################################################################################################

# Checks if the script is being executed with arguments
# If it is, it launches the uninstall function
if (![string]::IsNullOrWhiteSpace($appArgs)) {
    Uninstall
}
else {
    # If it is not, it launches the main loop
    MainLoop
}