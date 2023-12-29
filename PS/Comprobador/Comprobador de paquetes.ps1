<#
    Script: PacFinder.exe
    Version: 2.0
    Creador: Daniel Martín Juárez
    Colaboradores: Carlos Joaquín Roza López, Pablo Fernández Echevarría, Borja González Pardo
    GitHub: https://github.com/Angbroda/EUC/tree/Comprobador/PS/Comprobador
    Creado por EUC-Team el 29 de diciembre de 2023

    Descripción:
    Este script proporciona una solución integral para la verificación de la instalación de paquetes en una lista de hostnames dentro de un entorno de red. La interfaz gráfica de usuario (GUI) permite a los usuarios finales interactuar fácilmente con el script y comprender visualmente los resultados.

    Instrucciones:
    - Antes de ejecutar el script, asegúrese de ingresar la lista de hostnames y códigos de paquete en los cuadros de texto correspondientes.
    - Es esencial contar con permisos adecuados en el dominio Armony y ejecutar el script con un usuario que posea estos permisos.
    - Para el dominio Armony, el script requiere que el usuario tenga permisos suficientes para ejecutar el script PacFinder.exe.
    - Haga clic en el botón "Ejecutar" para iniciar el proceso de verificación.

    Notas:
    - Asegúrese de contar con los permisos necesarios para realizar las operaciones en los hostnames especificados.
    - La interfaz gráfica simplifica la interacción y visualización de los resultados.

    Nota para el dominio Armony:
    - Ejecutar el script con un usuario que tenga los permisos necesarios en Armony para realizar las verificaciones.

    Estructura del Script:
    - El script sigue una estructura modular y orientada a objetos mediante el uso de la Asamblea de Windows Forms.
    - Cada componente de la interfaz, como etiquetas, cuadros de texto y botones, se crea y configura de manera programática.
    - La función principal del script se ejecuta al hacer clic en el botón "Ejecutar", realizando la verificación y actualizando la interfaz con los resultados.

    Explicación detallada del código:

    1. **Carga de la Asamblea de Windows Forms:**
        - Utilizamos la instrucción `Add-Type` para cargar la Asamblea de Windows Forms. Esto habilita la creación de elementos de interfaz gráfica.

    2. **Creación del Formulario:**
        - Creamos un objeto de formulario (`$form`) con propiedades como texto, tamaño y posición.

    3. **Creación de Etiquetas y Cuadros de Texto:**
        - Se crean etiquetas y cuadros de texto para ingresar la lista de hostnames y códigos de paquete. Estos elementos se agregan al formulario.

    4. **Cuadros de Texto Adicionales y Etiquetas:**
        - Creamos cuadros de texto adicionales para mostrar información específica, como hostnames sin ping, sin carpeta de log, etc.

    5. **Creación del Botón de Ejecución:**
        - Se crea un botón que, al hacer clic, ejecutará la lógica principal del script.

    6. **Manejo del Evento Click del Botón:**
        - Se define una función que se ejecuta cuando se hace clic en el botón. Esta función limpia las áreas de texto y realiza la verificación de paquetes.

    7. **Función Agregar-Mensaje:**
        - Se define una función (`Agregar-Mensaje`) para facilitar la inclusión de mensajes en el registro con fecha y hora.

    8. **Lógica Principal del Script:**
        - Se realiza la verificación de paquetes para cada hostname en la lista. Se ejecutan comprobaciones como ping, existencia de carpetas y análisis de archivos de log.

    9. **Actualización de la Interfaz:**
        - La interfaz se actualiza dinámicamente con los resultados de la verificación.

    10. **Registro de Mensajes:**
        - Se utilizan mensajes en el registro para proporcionar una traza detallada de la ejecución del script.

    11. **Mostrar el Formulario:**
        - Finalmente, se ejecuta la aplicación de Windows Forms para mostrar el formulario.

    Este script ha sido desarrollado por EUC-Team como parte de un esfuerzo colaborativo. Cualquier mejora o corrección puede ser discutida y sugerida en el repositorio de GitHub proporcionado.
#>
# Cargar la Asamblea de Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Crear un formulario
$form = New-Object System.Windows.Forms.Form
$form.Text = "Verificador de Paquetes"
$form.Size = New-Object System.Drawing.Size(1200, 700)
$form.StartPosition = "CenterScreen"

# Crear etiquetas y cuadros de texto para hostnames y códigos de paquete
$labelHostnames = New-Object System.Windows.Forms.Label
$labelHostnames.Location = New-Object System.Drawing.Point(10, 20)
$labelHostnames.Size = New-Object System.Drawing.Size(450, 20)
$labelHostnames.Text = "Ingrese la lista de hostnames:"
$form.Controls.Add($labelHostnames)

$textboxHostnames = New-Object System.Windows.Forms.TextBox
$textboxHostnames.Location = New-Object System.Drawing.Point(10, 40)
$textboxHostnames.Size = New-Object System.Drawing.Size(400, 100)
$textboxHostnames.Multiline = $true
$form.Controls.Add($textboxHostnames)
$textboxHostnames.ScrollBars = "Both"

$labelCodigosPaquete = New-Object System.Windows.Forms.Label
$labelCodigosPaquete.Location = New-Object System.Drawing.Point(420, 20)
$labelCodigosPaquete.Size = New-Object System.Drawing.Size(450, 20)
$labelCodigosPaquete.Text = "Ingrese la lista de codigos del paquete (en formato SxxxxExx):"
$form.Controls.Add($labelCodigosPaquete)

$textboxCodigosPaquete = New-Object System.Windows.Forms.TextBox
$textboxCodigosPaquete.Location = New-Object System.Drawing.Point(420, 40)
$textboxCodigosPaquete.Size = New-Object System.Drawing.Size(400, 100)
$textboxCodigosPaquete.Multiline = $true
$form.Controls.Add($textboxCodigosPaquete)
$textboxCodigosPaquete.ScrollBars = "Both"

# Crear cuadro de texto y etiquetas adicionales (fuera del botón de ejecución)
$textboxSinPing = New-Object System.Windows.Forms.RichTextBox
$textboxSinPing.Location = New-Object System.Drawing.Point(10, 180)
$textboxSinPing.Size = New-Object System.Drawing.Size(260, 200)
$form.Controls.Add($textboxSinPing)
$textboxSinPing.ScrollBars = "Both"

$labelSinPing = New-Object System.Windows.Forms.Label
$labelSinPing.Location = New-Object System.Drawing.Point(10, 160)
$labelSinPing.Size = New-Object System.Drawing.Size(250, 20)
$labelSinPing.Text = "No responden a Ping"
$form.Controls.Add($labelSinPing)

$textboxSinCarpeta = New-Object System.Windows.Forms.RichTextBox
$textboxSinCarpeta.Location = New-Object System.Drawing.Point(280, 180)
$textboxSinCarpeta.Size = New-Object System.Drawing.Size(260, 200)
$form.Controls.Add($textboxSinCarpeta)
$textboxSinCarpeta.ScrollBars = "Both"

$labelSinCarpeta = New-Object System.Windows.Forms.Label
$labelSinCarpeta.Location = New-Object System.Drawing.Point(280, 160)
$labelSinCarpeta.Size = New-Object System.Drawing.Size(250, 20)
$labelSinCarpeta.Text = "No se encuentra carpeta de log"
$form.Controls.Add($labelSinCarpeta)

$textboxConAlgunPaquete = New-Object System.Windows.Forms.RichTextBox
$textboxConAlgunPaquete.Location = New-Object System.Drawing.Point(10, 400)
$textboxConAlgunPaquete.Size = New-Object System.Drawing.Size(460, 200)
$form.Controls.Add($textboxConAlgunPaquete)
$textboxConAlgunPaquete.ScrollBars = "Both"

$labelConAlgunPaquete = New-Object System.Windows.Forms.Label
$labelConAlgunPaquete.Location = New-Object System.Drawing.Point(10, 380)
$labelConAlgunPaquete.Size = New-Object System.Drawing.Size(450, 20)
$labelConAlgunPaquete.Text = "Log de donde sacamos la informacion"
$form.Controls.Add($labelConAlgunPaquete)

$textboxPaquetesInstalados = New-Object System.Windows.Forms.RichTextBox
$textboxPaquetesInstalados.Location = New-Object System.Drawing.Point(550, 180)
$textboxPaquetesInstalados.Size = New-Object System.Drawing.Size(260, 200)
$form.Controls.Add($textboxPaquetesInstalados)
$textboxPaquetesInstalados.ScrollBars = "Both"

$labelPaquetesInstalados = New-Object System.Windows.Forms.Label
$labelPaquetesInstalados.Location = New-Object System.Drawing.Point(550, 160)
$labelPaquetesInstalados.Size = New-Object System.Drawing.Size(250, 20)
$labelPaquetesInstalados.Text = "Paquetes instalados correctamente"
$form.Controls.Add($labelPaquetesInstalados)

# Crear cuadro de texto para el registro
$textboxRegistro = New-Object System.Windows.Forms.RichTextBox
$textboxRegistro.Location = New-Object System.Drawing.Point(550, 400)
$textboxRegistro.Size = New-Object System.Drawing.Size(450, 200)
$form.Controls.Add($textboxRegistro)
$textboxRegistro.ScrollBars = "Both"

# Crear un botón de ejecución
$buttonEjecutar = New-Object System.Windows.Forms.Button
$buttonEjecutar.Location = New-Object System.Drawing.Point(1000, 60)
$buttonEjecutar.Size = New-Object System.Drawing.Size(150, 40)
$buttonEjecutar.Text = "Ejecutar"
$form.Controls.Add($buttonEjecutar)

# Manejar el evento Click del botón
$buttonEjecutar.Add_Click({
  # Limpiar listas y cuadros de texto
  if ($textboxSinPing) { $textboxSinPing.Text = "" }
  if ($textboxSinCarpeta) { $textboxSinCarpeta.Text = "" }
  if ($textboxConAlgunPaquete) { $textboxConAlgunPaquete.Text = "" }
  if ($textboxPaquetesInstalados) { $textboxPaquetesInstalados.Text = "" }
  if ($textboxRegistro) { $textboxRegistro.Text = "" }

  # Función para agregar mensajes al registro con fecha y hora
  function Agregar-Mensaje($mensaje) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $mensajeConTimestamp = "$timestamp - $mensaje"
    if ($textboxRegistro) { $textboxRegistro.AppendText("$mensajeConTimestamp`r`n") }
    $form.Refresh()
  }

  Agregar-Mensaje "Iniciando verificación de paquetes..."

  # Lógica de ejecución del script...
  $listaHostnames = $textboxHostnames.Text -split ',|\r?\n|\n'
  $listaCodigosPaquete = $textboxCodigosPaquete.Text -split ',|\r?\n|\n' | ForEach-Object { $_.Trim() }

  $hostnamesConAlgunPaquete = @()
  $hostnamesSinPing = @()
  $hostnamesSinCarpeta = @()
  $hostnamesConCarpeta = @()
  $archivosSinContenido = @()
  $hostnamesConPaquetesCorrectos = @{} # Usar un hashtable para almacenar paquetes por hostname

  foreach ($hostname in $listaHostnames) {
    # Eliminar espacios en blanco al inicio y al final de cada hostname
    $hostname = $hostname.Trim()

    Agregar-Mensaje "Verificando host: $hostname"

    # Realizar ping al host
    if ($hostname -and (Test-Connection -ComputerName $hostname -Count 2 -Quiet)) {
      Agregar-Mensaje "Ping exitoso a $hostname"
      $carpetasEncontradas = @()

      foreach ($codigoPaquete in $listaCodigosPaquete) {
        Agregar-Mensaje "Verificando paquete: $codigoPaquete"

        # Construir la ruta de la carpeta de archivos
		if ($codigoPaquete.Length -ge 3) {
			$logCode = $codigoPaquete.Substring(1, $codigoPaquete.Length - 3)
		} else {
			# Manejar el caso en que la cadena sea demasiado corta
			$logCode = $codigoPaquete
		}
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

      if ($carpetasEncontradas.Count -gt 0) {
        $hostnamesConAlgunPaquete += "$hostname - Carpeta: $($carpetasEncontradas -join ' ')"
        if ($textboxConAlgunPaquete) { $textboxConAlgunPaquete.Text = $hostnamesConAlgunPaquete -join "`r`n" }
        $form.Refresh()
        Agregar-Mensaje "Ping exitoso y carpetas encontradas para $hostname"
      }
    } else {
      $hostnamesSinPing += $hostname
      if ($textboxSinPing) { $textboxSinPing.Text = $hostnamesSinPing -join "`r`n" }
      $form.Refresh()
      Agregar-Mensaje "No se pudo hacer ping a $hostname"
    }
  }

  if ($hostnamesSinCarpeta.Count -gt 0) {
    if ($textboxSinCarpeta) { $textboxSinCarpeta.Text = $hostnamesSinCarpeta -join "`r`n" }
    $form.Refresh()
    Agregar-Mensaje "No se encontraron carpetas para algunos hostnames"
  }

  if ($hostnamesConCarpeta.Count -gt 0) {
    $mensajeConCarpeta = foreach ($hostname in $hostnamesConPaquetesCorrectos.Keys) {
      $paquetesCorrectos = $hostnamesConPaquetesCorrectos[$hostname]
      " - $hostname - Paquetes: $paquetesCorrectos"     
    }
    if ($textboxPaquetesInstalados) { $textboxPaquetesInstalados.Text = $mensajeConCarpeta -join "`r`n" }
    $form.Refresh()
    Agregar-Mensaje "Paquetes instalados correctamente en algunos hostnames"
  }

  Agregar-Mensaje "Verificación de paquetes completada."
})

# Mostrar el formulario
[Windows.Forms.Application]::Run($form)
