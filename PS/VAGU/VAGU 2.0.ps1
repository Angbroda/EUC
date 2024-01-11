# Virtualized ArcelorMittal Geek Unit - Versión 1.0
# Creado por el equipo de EUC. Técnico: Daniel Martín Juárez

# Este script de PowerShell ha sido desarrollado por el equipo de End User Computing (EUC). 
# La versión actual es la 2.0 y fue creado por el técnico Daniel Martín Juárez. El script utiliza Windows Forms para proporcionar una interfaz
# gráfica de usuario (GUI) que facilita diversas operaciones de administración en sistemas y redes.

# El script incluye funciones para realizar operaciones como ping, ejecución de comandos remotos,
# apertura de exploradores de archivos, búsqueda de información en Active Directory, entre otras.
# Cada función está diseñada para realizar una tarea específica y mostrar resultados en un cuadro
# de texto dedicado.

# Variables:
#   - $form: Representa el formulario principal que contiene los controles de la interfaz gráfica.
#   - $textBox: Cuadro de texto para ingresar el nombre del host.
#   - $logTextBox: Cuadro de texto tipo RichTextBox para mostrar registros y mensajes.
#   - $adInfoTextBox: Cuadro de texto tipo RichTextBox para mostrar detalles de Active Directory.

# Funciones:
#   - Crear-RichTextBox: Crea un objeto RichTextBox con propiedades especificadas.
#   - Crear-Boton: Crea un objeto Button con propiedades especificadas, incluyendo una acción al hacer clic.
#   - Agregar-LogMessage: Agrega un mensaje al cuadro de registro con marca de tiempo y color de fondo.
#   - Ping-Host: Realiza un ping al host especificado y registra los resultados en el cuadro de registro.
#   - Run-PsExec: Ejecuta el comando psexec para abrir una ventana de la línea de comandos en el host.
#   - Open-ExplorerInFolder: Abre el Explorador de Windows en una carpeta específica del host.
#   - Open-CcmSetupFolder: Abre el Explorador de Windows en la carpeta ccmsetup del host.
#   - Search-ADInfo: Busca información en Active Directory para el host y muestra detalles en el cuadro de texto.
#   - Run-RemotePowerShell: Inicia una sesión de PowerShell remota en el host especificado.

# Nota: Este script asume la presencia de las herramientas necesarias como psexec y la configuración
# adecuada para la interacción con Active Directory. Asegúrese de que se cumplan estos requisitos antes
# de utilizar la aplicación.

# Para utilizar la aplicación, complete el nombre del host en el cuadro de texto y seleccione la operación
# deseada haciendo clic en los botones correspondientes. El cuadro de registro proporciona información
# detallada sobre las operaciones realizadas, mientras que el cuadro de texto de Active Directory muestra
# detalles específicos obtenidos de Active Directory.

# ¡Gracias por utilizar Virtualized ArcelorMittal Geek Unit!


# Agregar el ensamblado de Windows Forms para trabajar con GUI
Add-Type -AssemblyName System.Windows.Forms

# Función para crear RichTextBox
function Crear-RichTextBox {
    param (
        [System.Drawing.Point]$location,
        [System.Drawing.Size]$size,
        [string]$scrollBars,
        [string]$backColor
    )

    $richTextBox = New-Object System.Windows.Forms.RichTextBox
    $richTextBox.Location = $location
    $richTextBox.Size = $size
    $richTextBox.ScrollBars = $scrollBars
    $richTextBox.BackColor = $backColor

    return $richTextBox
}

# Función para crear Botón
function Crear-Boton {
    param (
        [System.Drawing.Point]$location,
        [System.Drawing.Size]$size,
        [string]$text,
        [scriptblock]$onClick
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Location = $location
    $button.Size = $size
    $button.Text = $text
    $button.Add_Click($onClick)

    return $button
}

# Función para agregar mensaje al log
function Agregar-LogMessage {
    param (
        [string]$message,
        [string]$color
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "$timestamp - $message`r`n"

    $logTextBox.SelectionStart = 0
    $logTextBox.SelectionLength = 0
    $logTextBox.SelectionBackColor = $color
    $logTextBox.SelectedText = $logMessage
    $logTextBox.SelectionBackColor = $logTextBox.BackColor  # Restaurar el fondo blanco para las siguientes líneas
}

# Función para ejecutar el ping
function Ping-Host {
    $hostname = $textBox.Text
	    Agregar-LogMessage "Iniciando ping hacia $hostname" 'White'

    1..3 | ForEach-Object {
        $result = Test-Connection -ComputerName $hostname -Count 1 -ErrorAction SilentlyContinue
        if ($result) {
            Agregar-LogMessage "$hostname está reachable en el intento $_ ($($result.IPV4Address.IPAddressToString))`r`n" 'Green'
        } else {
            Agregar-LogMessage "$hostname no está reachable en el intento $_ ($($result.IPV4Address.IPAddressToString))`r`n" 'Red'
        }
    }
}

# Función para ejecutar psexec
function Run-PsExec {
    $hostname = $textBox.Text
    Agregar-LogMessage "Ejecutando psexec \\$hostname -s cmd" 'White'
    Start-Process "cmd.exe" -ArgumentList "/c psexec \\$hostname -s cmd"
}

# Función para abrir el Explorador de Windows en una carpeta específica
function Open-ExplorerInFolder {
    $hostname = $textBox.Text
    $logsPath = "\\$hostname\c$\windows\ccm\logs"
    Agregar-LogMessage "Abriendo el Explorador de Windows en $logsPath" 'White'
    Invoke-Expression "start explorer $logsPath"
}

# Función para abrir la carpeta ccmsetup
function Open-CcmSetupFolder {
    $hostname = $textBox.Text
    $ccmsetupPath = "\\$hostname\c$\windows\ccmsetup"
    Agregar-LogMessage "Abriendo el Explorador de Windows en $ccmsetupPath" 'White'
    Invoke-Expression "start explorer $ccmsetupPath"
}

# Función para buscar información en Active Directory
function Search-ADInfo {
    $hostname = $textBox.Text
    Agregar-LogMessage "Buscando información en Active Directory para $hostname" 'White'

    try {
        $computer = Get-ADComputer -Filter {Name -eq $hostname} -Properties *
        
        $logTextBox.SelectionBackColor = 'White'  # Restaurar el fondo blanco para las siguientes líneas
        Agregar-LogMessage "AD Information for $($computer.Name):" 'White'
        Agregar-LogMessage "Name: $($computer.Name)" 'White'
        Agregar-LogMessage "Description: $($computer.Description)" 'White'
        Agregar-LogMessage "Distinguished Name: $($computer.DistinguishedName)" 'White'
        Agregar-LogMessage "Operating System: $($computer.OperatingSystem)" 'White'
        Agregar-LogMessage "OS Version: $($computer.OperatingSystemVersion)" 'White'
        Agregar-LogMessage "Last Logon: $($computer.LastLogon)" 'White'
        Agregar-LogMessage "Enabled: $($computer.Enabled)" 'White'
        Agregar-LogMessage "Creation Date: $($computer.Created)" 'White'
        Agregar-LogMessage "Modified Date: $($computer.Modified)" 'White'

        # Obtener y mostrar los grupos a los que pertenece
        $groups = Get-ADComputer -Identity $computer.DistinguishedName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        if ($groups) {
            Agregar-LogMessage "Member of Groups:" 'White'
            foreach ($group in $groups) {
                Agregar-LogMessage "  - $($group | Get-ADGroup | Select-Object -ExpandProperty Name)" 'White'
            }
        }

        # Mostrar la información de AD en el cuadro de texto dedicado
        $adInfoTextBox.Text = "AD Information for $($computer.Name):`r`n"
        $adInfoTextBox.AppendText("Name: $($computer.Name)`r`n")
        $adInfoTextBox.AppendText("Description: $($computer.Description)`r`n")
        $adInfoTextBox.AppendText("Distinguished Name: $($computer.DistinguishedName)`r`n")
        $adInfoTextBox.AppendText("Operating System: $($computer.OperatingSystem)`r`n")
        $adInfoTextBox.AppendText("OS Version: $($computer.OperatingSystemVersion)`r`n")
        $adInfoTextBox.AppendText("Last Logon: $($computer.LastLogon)`r`n")
        $adInfoTextBox.AppendText("Enabled: $($computer.Enabled)`r`n")
        $adInfoTextBox.AppendText("Creation Date: $($computer.Created)`r`n")
        $adInfoTextBox.AppendText("Modified Date: $($computer.Modified)`r`n")

        # Obtener y mostrar los grupos a los que pertenece en el cuadro de texto dedicado
        if ($groups) {
            $adInfoTextBox.AppendText("`r`nMember of Groups:`r`n")
            foreach ($group in $groups) {
                $adInfoTextBox.AppendText("  - $($group | Get-ADGroup | Select-Object -ExpandProperty Name)`r`n")
            }
        }
    } catch {
        Agregar-LogMessage "Error: $_" 'Red'
    }
}

# Función para ejecutar comandos en PowerShell remoto
function Run-RemotePowerShell {
    $hostname = $textBox.Text
    Agregar-LogMessage "Ejecutando PowerShell Remoto en $hostname" 'White'
    Start-Process "powershell.exe" -ArgumentList "-NoExit -Command Enter-PSSession -ComputerName $hostname"
}

# Crear el formulario principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Virtualized ArcelorMittal Geek Unit"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# Crear el cuadro de entrada de texto para el hostname
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Crear el botón de ping
$pingButton = Crear-Boton (New-Object System.Drawing.Point(240, 20)) (New-Object System.Drawing.Size(100, 20)) "Ping 3 veces" {
    Ping-Host
}
$form.Controls.Add($pingButton)

# Crear el cuadro de texto para el log
$logTextBox = Crear-RichTextBox (New-Object System.Drawing.Point(360, 20)) (New-Object System.Drawing.Size(400, 200)) "Vertical" 'White'
$form.Controls.Add($logTextBox)

# Crear el cuadro de texto para la información de Active Directory
$adInfoTextBox = Crear-RichTextBox (New-Object System.Drawing.Point(360, 240)) (New-Object System.Drawing.Size(400, 300)) "Vertical" 'White'
$form.Controls.Add($adInfoTextBox)

# Crear el botón para ejecutar psexec
$psexecButton = Crear-Boton (New-Object System.Drawing.Point(20, 60)) (New-Object System.Drawing.Size(100, 20)) "Ejecutar psexec" {
    Run-PsExec
}
$form.Controls.Add($psexecButton)

# Crear el botón para abrir el explorador de archivos
$explorerLogsButton = Crear-Boton (New-Object System.Drawing.Point(140, 60)) (New-Object System.Drawing.Size(150, 20)) "Abrir Explorador en C$" {
    Open-ExplorerInFolder
}
$form.Controls.Add($explorerLogsButton)

# Crear el botón para abrir la carpeta ccmsetup
$ccmsetupButton = Crear-Boton (New-Object System.Drawing.Point(20, 100)) (New-Object System.Drawing.Size(150, 20)) "Abrir ccmsetup Folder" {
    Open-CcmSetupFolder
}
$form.Controls.Add($ccmsetupButton)

# Crear el botón para buscar información en Active Directory
$searchADButton = Crear-Boton (New-Object System.Drawing.Point(200, 340)) (New-Object System.Drawing.Size(150, 20)) "Buscar Info en AD" {
    Search-ADInfo
}
$form.Controls.Add($searchADButton)

# Crear el botón para ejecutar los comandos en PowerShell remoto
$powershellButton = Crear-Boton (New-Object System.Drawing.Point(20, 140)) (New-Object System.Drawing.Size(250, 20)) "Ejecutar PowerShell Remoto" {
    Run-RemotePowerShell
}
$form.Controls.Add($powershellButton)

# Crear el botón para abrir el Explorador de Windows en la carpeta específica
$explorerLogsButton = Crear-Boton (New-Object System.Drawing.Point(20, 180)) (New-Object System.Drawing.Size(250, 20)) "Abrir Explorador en CCM Logs" {
    Open-ExplorerInFolder
}
$form.Controls.Add($explorerLogsButton)

# Mostrar el formulario cuando esté listo
$form.Add_Shown({
    $form.Activate()
})

# Ejecutar la aplicación
[System.Windows.Forms.Application]::Run($form)
