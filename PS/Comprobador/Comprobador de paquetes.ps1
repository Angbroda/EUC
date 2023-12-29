# Cargar la Asamblea de Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Crear un formulario
$form = New-Object System.Windows.Forms.Form
$form.Text = "Verificador de Paquetes"
$form.Size = New-Object System.Drawing.Size(600,700)
$form.StartPosition = "CenterScreen"



# Crear etiquetas y cuadros de texto para hostnames y codigos de paquete
$labelHostnames = New-Object System.Windows.Forms.Label
$labelHostnames.Location = New-Object System.Drawing.Point(10,20)
$labelHostnames.Size = New-Object System.Drawing.Size(400,20)
$labelHostnames.Text = "Ingrese la lista de hostnames (separados por comas):"
$form.Controls.Add($labelHostnames)

$textboxHostnames = New-Object System.Windows.Forms.TextBox
$textboxHostnames.Location = New-Object System.Drawing.Point(10,40)
$textboxHostnames.Size = New-Object System.Drawing.Size(400,100)
$textboxHostnames.Multiline = $true
$form.Controls.Add($textboxHostnames)

$labelCodigosPaquete = New-Object System.Windows.Forms.Label
$labelCodigosPaquete.Location = New-Object System.Drawing.Point(10,170)
$labelCodigosPaquete.Size = New-Object System.Drawing.Size(450,20)
$labelCodigosPaquete.Text = "Ingrese la lista de codigos del paquete (en formato SxxxxExx, separados por comas):"
$form.Controls.Add($labelCodigosPaquete)

$textboxCodigosPaquete = New-Object System.Windows.Forms.TextBox
$textboxCodigosPaquete.Location = New-Object System.Drawing.Point(10,190)
$textboxCodigosPaquete.Size = New-Object System.Drawing.Size(400,100)
$textboxCodigosPaquete.Multiline = $true
$form.Controls.Add($textboxCodigosPaquete)



# Crear un cuadro de texto para mostrar los resultados
$textboxResultados = New-Object System.Windows.Forms.TextBox
$textboxResultados.Location = New-Object System.Drawing.Point(10,300)
$textboxResultados.Size = New-Object System.Drawing.Size(560,300)
$textboxResultados.Multiline = $true
$form.Controls.Add($textboxResultados)



# Crear un botón de ejecución
$buttonEjecutar = New-Object System.Windows.Forms.Button
$buttonEjecutar.Location = New-Object System.Drawing.Point(10,620)
$buttonEjecutar.Size = New-Object System.Drawing.Size(150,40)
$buttonEjecutar.Text = "Ejecutar Verificacion"
$buttonEjecutar.Add_Click({
    # Lógica de ejecución del script...
# Lógica de ejecución del script...
$listaHostnames = $textboxHostnames.Text -split ','
$listaCodigosPaquete = $textboxCodigosPaquete.Text -split ',' | ForEach-Object { $_.Trim() }

$hostnamesConAlgunPaquete = @()
$hostnamesSinPing = @()
$hostnamesSinCarpeta = @()
$hostnamesConCarpeta = @()
$archivosSinContenido = @()
$hostnamesConPaquetesCorrectos = @{} # Usar un hashtable para almacenar paquetes por hostname

foreach ($hostname in $listaHostnames) {
    # Eliminar espacios en blanco al inicio y al final de cada hostname
    $hostname = $hostname.Trim()

    # Realizar ping al host
    if (Test-Connection -ComputerName $hostname -Count 2 -Quiet) {
        $carpetasEncontradas = @()

        foreach ($codigoPaquete in $listaCodigosPaquete) {
            # Construir la ruta de la carpeta de archivos
            $logCode = $codigoPaquete.Substring(1, $codigoPaquete.Length - 3)
            $rutaCarpetaArchivos = "\\$hostname\c$\it\logs\$logCode"

            # Verificar si la carpeta existe
            if (Test-Path -Path $rutaCarpetaArchivos -PathType Container) {
                
                $hostnamesConCarpeta += "$hostname - $codigoPaquete"

                # Obtener la lista de archivos en la carpeta y filtrar por nombre y versión
                $archivos1 = @(Get-ChildItem -Path $rutaCarpetaArchivos -Filter "$codigoPaquete.txt")
                $archivos2 = @(Get-ChildItem -Path $rutaCarpetaArchivos -Filter "*launcher.log")
                $archivos3 = @(Get-ChildItem -Path $rutaCarpetaArchivos -Filter "*MSI*.log")

                $archivos = $archivos1 + $archivos2 + $archivos3

                foreach ($archivo in $archivos) {
                    if ($null -eq $archivo) {
                        $archivosSinContenido += "$hostname - $rutaCarpetaArchivos"
                        continue
                    }
					$archivo
                    # Obtener las cuatro últimas líneas de cada archivo
                    $ultimasLineasArchivo = Get-Content -Path $archivo.FullName | Select-Object -Last 4

                    # Verificar si el paquete está correctamente instalado
                    $instalacionCorrecta = $ultimasLineasArchivo -match 'Successful installation|MainEngineThread is returning 0|GlobalReturnCode : 0'
					
                    if ($instalacionCorrecta) {
                        # Agregar el paquete al hashtable con el hostname como clave
                        if ($hostnamesConPaquetesCorrectos.ContainsKey($hostname)) {
                            $hostnamesConPaquetesCorrectos[$hostname] += ", $codigoPaquete"
                        } else {
                            $hostnamesConPaquetesCorrectos[$hostname] = $codigoPaquete
                        }
						$carpetasEncontradas += $rutaCarpetaArchivos + "\$archivo"
						break
                    }
                }
            } else {
                $hostnamesSinCarpeta += "$hostname - $codigoPaquete"
            }
        }

        if ($carpetasEncontradas.Count -eq 0) {
            $hostnamesSinCarpeta += "$hostname - Sin carpetas para los codigos: $($listaCodigosPaquete -join ', ')"
        }

        if ($carpetasEncontradas.Count -gt 0) {
            $hostnamesConAlgunPaquete += "$hostname - Carpetas: $($carpetasEncontradas -join ', ')"
        }
    } else {
        $hostnamesSinPing += $hostname
    }
}


# Mostrar resultados en el cuadro de texto
$textboxResultados.Text = $mensaje

# Resumen final
$mensaje = "Resumen Final:`r`r`n"

if ($hostnamesConAlgunPaquete.Count -gt 0) {
    $mensaje += "Hostnames con algun paquete instalado:`r`r`n"
    $mensaje += $hostnamesConAlgunPaquete -join "`r`n"
    $mensaje += "`r`n"
} else {
    $mensaje += "No se encontraron hostnames con algun paquete instalado.`r`n"
    $mensaje += "`r`n"
}

if ($hostnamesSinPing.Count -gt 0) {
    $mensaje += "Hostnames sin respuesta al ping:`r`n"
    $mensaje += $hostnamesSinPing -join "`r`n"
    $mensaje += "`r`n"
} else {
    $mensaje += "Todos los hostnames respondieron al ping.`r`n"
    $mensaje += "`r`n"
}

if ($hostnamesSinCarpeta.Count -gt 0) {
    $mensaje += "Hostnames sin carpeta para los siguientes codigos:`r`n`r`n"
    $mensaje += $hostnamesSinCarpeta -join "`r`n"
    $mensaje += "`r`n"
}

if ($hostnamesConCarpeta.Count -gt 0) {
    $mensaje += "Hostnames con paquetes instalados correctamente:`r`n"
    foreach ($hostname in $hostnamesConPaquetesCorrectos.Keys) {
        $paquetesCorrectos = $hostnamesConPaquetesCorrectos[$hostname]
        $mensaje += "  - $hostname - Paquetes: $paquetesCorrectos`r`n"
    }
} else {
    $mensaje += "Ningún hostname tiene carpeta para los codigos especificados.`r`n"
}

    $textboxResultados.Text = $mensaje
})

$form.Controls.Add($buttonEjecutar)

# Mostrar el formulario
[Windows.Forms.Application]::Run($form)
