# Virtualized ArcelorMittal Geek Unit - Versión 1.0
# Creado por el equipo de EUC. Técnico: Daniel Martín Juárez

# Agregar el ensamblado de Windows Forms para trabajar con GUI
Add-Type -AssemblyName System.Windows.Forms

# Crear el formulario principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Virtualized ArcelorMittal Geek Unit"
$form.Size = New-Object System.Drawing.Size(800, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"

# Crear el cuadro de entrada de texto para el hostname
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 20)
$textBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($textBox)

# Crear el botón de ping
$pingButton = New-Object System.Windows.Forms.Button
$pingButton.Location = New-Object System.Drawing.Point(240, 20)
$pingButton.Size = New-Object System.Drawing.Size(100, 20)
$pingButton.Text = "Ping 3 veces"
$pingButton.Add_Click({
    $hostname = $textBox.Text
    $logTextBox.AppendText("Iniciando ping hacia $hostname`r`n")
    
    1..3 | ForEach-Object {
        $result = Test-Connection -ComputerName $hostname -Count 1 -ErrorAction SilentlyContinue
        if ($result) {
            $logTextBox.SelectionBackColor = 'Green'
            $logTextBox.AppendText("$hostname está reachable en el intento $_`r`n")
        } else {
            $logTextBox.SelectionBackColor = 'Red'
            $logTextBox.AppendText("$hostname no está reachable en el intento $_`r`n")
        }
        $logTextBox.SelectionBackColor = 'White'  # Restaurar el fondo blanco para las siguientes líneas
    }
})
$form.Controls.Add($pingButton)

# Crear el cuadro de texto para el log
$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Location = New-Object System.Drawing.Point(360, 20)
$logTextBox.Size = New-Object System.Drawing.Size(400, 300)
$logTextBox.ScrollBars = "Vertical"
$logTextBox.BackColor = 'White'
$form.Controls.Add($logTextBox)

# Crear el botón para ejecutar psexec
$psexecButton = New-Object System.Windows.Forms.Button
$psexecButton.Location = New-Object System.Drawing.Point(20, 60)
$psexecButton.Size = New-Object System.Drawing.Size(100, 20)
$psexecButton.Text = "Ejecutar psexec"
$psexecButton.Add_Click({
    $hostname = $textBox.Text
    $logTextBox.AppendText("Ejecutando psexec \\$hostname -s cmd`r`n")
    Start-Process "cmd.exe" -ArgumentList "/c psexec \\$hostname -s cmd"
})
$form.Controls.Add($psexecButton)

# Crear el botón para abrir el explorador de archivos
$explorerButton = New-Object System.Windows.Forms.Button
$explorerButton.Location = New-Object System.Drawing.Point(140, 60)
$explorerButton.Size = New-Object System.Drawing.Size(150, 20)
$explorerButton.Text = "Abrir Explorador en C$"
$explorerButton.Add_Click({
    $hostname = $textBox.Text
    $logTextBox.AppendText("Abriendo el Explorador de Windows en \\$hostname\c$`r`n")
    Invoke-Expression "start explorer \\$hostname\c$"
})
$form.Controls.Add($explorerButton)

# Crear el botón para ejecutar los comandos en PowerShell remoto
$powershellButton = New-Object System.Windows.Forms.Button
$powershellButton.Location = New-Object System.Drawing.Point(20, 100)
$powershellButton.Size = New-Object System.Drawing.Size(250, 20)
$powershellButton.Text = "Ejecutar PowerShell Remoto"
$powershellButton.Add_Click({
    $hostname = $textBox.Text
    $logTextBox.AppendText("Ejecutando PowerShell Remoto en $hostname`r`n")
    Start-Process "powershell.exe" -ArgumentList "-NoExit -Command Enter-PSSession -ComputerName $hostname"
})
$form.Controls.Add($powershellButton)

# Crear el botón para abrir el Explorador de Windows en la carpeta específica
$explorerLogsButton = New-Object System.Windows.Forms.Button
$explorerLogsButton.Location = New-Object System.Drawing.Point(20, 140)
$explorerLogsButton.Size = New-Object System.Drawing.Size(250, 20)
$explorerLogsButton.Text = "Abrir Explorador en CCM Logs"
$explorerLogsButton.Add_Click({
    $hostname = $textBox.Text
    $logsPath = "\\$hostname\c$\windows\ccm\logs"
    $logTextBox.AppendText("Abriendo el Explorador de Windows en $logsPath`r`n")
    Invoke-Expression "start explorer $logsPath"
})
$form.Controls.Add($explorerLogsButton)

# Crear el botón para abrir la carpeta ccmsetup
$ccmsetupButton = New-Object System.Windows.Forms.Button
$ccmsetupButton.Location = New-Object System.Drawing.Point(20, 180)
$ccmsetupButton.Size = New-Object System.Drawing.Size(250, 20)
$ccmsetupButton.Text = "Abrir ccmsetup Folder"
$ccmsetupButton.Add_Click({
    $hostname = $textBox.Text
    $ccmsetupPath = "\\$hostname\c$\windows\ccmsetup"
    $logTextBox.AppendText("Abriendo el Explorador de Windows en $ccmsetupPath`r`n")
    Invoke-Expression "start explorer $ccmsetupPath"
})
$form.Controls.Add($ccmsetupButton)

# Crear el botón para ejecutar psexec y mostrar políticas
$psexecPoliciesButton = New-Object System.Windows.Forms.Button
$psexecPoliciesButton.Location = New-Object System.Drawing.Point(20, 220)
$psexecPoliciesButton.Size = New-Object System.Drawing.Size(200, 20)
$psexecPoliciesButton.Text = "Mostrar Políticas con psexec"
$psexecPoliciesButton.Add_Click({
    $hostname = $textBox.Text
    $logTextBox.AppendText("Ejecutando psexec para mostrar políticas en \\$hostname`r`n")
    
    $psexecCommand = "gpresult /r /scope computer /v"
    $psexecCommand = "psexec \\$hostname -s cmd /c $psexecCommand"
    
    Start-Process "cmd.exe" -ArgumentList "/c $psexecCommand"
})
$form.Controls.Add($psexecPoliciesButton)

# Mostrar el formulario cuando esté listo
$form.Add_Shown({
    $form.Activate()
})

# Ejecutar la aplicación
[System.Windows.Forms.Application]::Run($form)
