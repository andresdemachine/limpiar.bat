# Resumen final de la limpieza.
# Cada funcion Write-* produce las dos versiones a la vez, asi nunca se desincronizan:
#   - consola (texto de ancho fijo con colores; queda tambien en el log)
#   - HTML para el correo (tarjetas y filas que se adaptan al ancho del celular)
# Se carga con dot-sourcing desde limpiar.ps1.

$script:anchoResumen = 68
$script:resumenHtml = New-Object Text.StringBuilder
$script:tarjetaAbierta = $false
$script:avisosResumen = 0

# Estilo del correo: negro con rojo neon. El brillo (text-shadow) solo se ve en los clientes que
# lo soportan (Apple Mail, iOS); en el resto queda el rojo plano, que se lee igual.
$script:neon       = '#ff2a45'
$script:brilloNeon = 'text-shadow:0 0 6px rgba(255,42,69,.75),0 0 14px rgba(255,42,69,.45)'
$script:fondoHtml  = '#050506'
$script:lineaHtml  = '#232329'

# Colores de consola -> colores de texto del correo (fondo negro)
$script:coloresHtml = @{
    Cyan  = $script:neon; DarkCyan = $script:neon
    Green = '#4ade80'; Yellow   = '#facc15'; Red = '#ff5c6c'
    White = '#f4f4f5'; Gray     = '#f4f4f5'; DarkGray = '#8b8b94'
}
$script:fuenteHtml = "-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif"

# --- Piezas basicas ---

# Tamano legible: en GB desde 1000 MB, porque "1.010 MB" se confunde con 1 MB por el separador de miles
function Format-Tamano($bytes) {
    if ($bytes -ge 1000MB) { return '{0:N2} GB' -f ($bytes / 1GB) }
    return '{0:N0} MB' -f ($bytes / 1MB)
}
# Solo consola (y log). Siempre una linea completa de un solo color: el log de PowerShell 5.1
# corta la linea cada vez que se usa -NoNewline, asi que no se mezclan colores en una misma linea.
function Out-Resumen([string]$texto = '', $color = 'Gray') {
    Write-Host $texto -ForegroundColor $color
}

# Solo correo
function Add-Html([string]$html) { [void]$script:resumenHtml.Append($html) }
function Format-HtmlTexto([string]$texto) { [Net.WebUtility]::HtmlEncode($texto) }
function Get-ColorHtml($color) {
    $c = $script:coloresHtml[$color]
    if ($c) { $c } else { $script:coloresHtml['Gray'] }
}

function Close-Tarjeta {
    if ($script:tarjetaAbierta) {
        Add-Html '</td></tr></table></td></tr>'
        $script:tarjetaAbierta = $false
    }
}

# Recorta un texto a un ancho fijo para que las tablas de consola queden alineadas
# (siempre deja al menos un espacio de separacion con la columna siguiente)
function Format-Ancho($texto, $ancho) {
    $t = "$texto"
    if ($t.Length -gt $ancho - 1) { $t = $t.Substring(0, $ancho - 4) + '...' }
    return $t.PadRight($ancho)
}

# --- Bloques del resumen (consola + correo) ---

# Marco doble con un titulo centrado (solo consola; tambien lo usa el inicio de limpiar.ps1)
function Write-CajaConsola($titulo) {
    $interior = $script:anchoResumen - 2
    $izq = [math]::Floor(($interior - $titulo.Length) / 2)
    $h = [string][char]0x2550
    Out-Resumen ''
    Out-Resumen ('  ' + [char]0x2554 + ($h * $interior) + [char]0x2557) Cyan
    Out-Resumen ('  ' + [char]0x2551 + (' ' * $izq) + $titulo + (' ' * ($interior - $izq - $titulo.Length)) + [char]0x2551) Cyan
    Out-Resumen ('  ' + [char]0x255A + ($h * $interior) + [char]0x255D) Cyan
}

# Titulo de seccion con linea debajo (solo consola)
function Write-SeccionConsola($titulo) {
    Out-Resumen ''
    Out-Resumen "  $titulo" Cyan
    Out-Resumen ('  ' + ([string][char]0x2500 * ($script:anchoResumen - 2))) DarkCyan
}

function Write-Cabecera($titulo, $subtitulo) {
    Write-CajaConsola $titulo
    Out-Resumen "  $subtitulo" DarkGray

    Add-Html ('<tr><td style="background:#000000;border:1px solid ' + $script:neon + ';border-radius:12px;padding:20px 20px 18px">' +
        '<div style="font-size:20px;font-weight:800;letter-spacing:1px;line-height:1.3;color:' + $script:neon + ';' + $script:brilloNeon + '">' +
        (Format-HtmlTexto $titulo) + '</div>' +
        '<div style="font-size:13px;color:#a1a1aa;margin-top:4px">' + (Format-HtmlTexto $subtitulo) + '</div>' +
        '</td></tr>')
}

function Write-Seccion($titulo) {
    Write-SeccionConsola $titulo

    Close-Tarjeta
    Add-Html ('<tr><td style="padding-top:12px">' +
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" ' +
        'style="background:#111114;border:1px solid #3d0d17;border-left:3px solid ' + $script:neon + ';border-radius:12px">' +
        '<tr><td style="padding:14px 16px 10px">' +
        '<div style="font-size:12px;font-weight:700;letter-spacing:1px;color:' + $script:neon + ';' + $script:brilloNeon + ';padding-bottom:4px">' +
        (Format-HtmlTexto $titulo) + '</div>')
    $script:tarjetaAbierta = $true
}

# Dato "etiqueta ..... valor"; en el correo, etiqueta a la izquierda y valor a la derecha
function Write-Dato($etiqueta, $valor, $color = 'White') {
    Out-Resumen ('    ' + "$etiqueta ".PadRight(30, '.') + ' ' + $valor) $color

    Add-Html ('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid ' + $script:lineaHtml + '"><tr>' +
        '<td style="padding:8px 8px 8px 0;font-size:14px;color:#a1a1aa">' + (Format-HtmlTexto $etiqueta) + '</td>' +
        '<td align="right" style="padding:8px 0;font-size:14px;font-weight:600;color:' + (Get-ColorHtml $color) + '">' +
        (Format-HtmlTexto $valor).Replace(' -&gt; ', ' &rarr; ') + '</td></tr></table>')
}

# Linea con estado: OK (verde), AVISO (amarillo), INFO (gris claro, solo informa: no cuenta como aviso)
# o NA (gris, dato no disponible)
function Write-Estado($nivel, $etiqueta, $valor) {
    $marca, $color, $textoPastilla, $fondo, $tinta = switch ($nivel) {
        'OK'    { ' OK ', 'Green',    'OK',    '#0d2b19', '#4ade80' }
        'AVISO' { ' !! ', 'Yellow',   'AVISO', '#2e2606', '#facc15' }
        'INFO'  { ' i  ', 'Gray',     'INFO',  '#1c1c21', '#d4d4d8' }
        default { ' -- ', 'DarkGray', 'N/D',   '#1f1f24', '#8b8b94' }
    }
    if ($nivel -eq 'AVISO') { $script:avisosResumen++ }
    Out-Resumen ('    [' + $marca + '] ' + "$etiqueta ".PadRight(24, '.') + ' ' + $valor) $color

    # En el correo: pastilla de color + etiqueta, y el detalle debajo (se lee bien en pantallas angostas)
    Add-Html ('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid ' + $script:lineaHtml + '"><tr>' +
        '<td width="64" valign="top" style="padding:9px 0">' +
        '<span style="display:inline-block;min-width:44px;text-align:center;padding:2px 8px;border-radius:999px;' +
        'font-size:11px;font-weight:700;background:' + $fondo + ';color:' + $tinta + '">' + $textoPastilla + '</span></td>' +
        '<td style="padding:8px 0">' +
        '<div style="font-size:14px;font-weight:600;color:#f4f4f5">' + (Format-HtmlTexto $etiqueta) + '</div>' +
        '<div style="font-size:13px;color:#a1a1aa;margin-top:2px">' + (Format-HtmlTexto $valor) + '</div>' +
        '</td></tr></table>')
}

# Nota pequena al pie de una seccion
function Write-Nota($texto, $color = 'DarkGray') {
    Out-Resumen "    $texto" $color
    Add-Html ('<div style="font-size:13px;color:' + (Get-ColorHtml $color) + ';padding:8px 0 4px">' + (Format-HtmlTexto $texto) + '</div>')
}

# Lista de nombres: dos columnas en consola, etiquetas que se acomodan solas en el correo
function Write-Lista($nombres) {
    $nombres = @($nombres)
    for ($i = 0; $i -lt $nombres.Count; $i += 2) {
        $fila = '    - ' + (Format-Ancho $nombres[$i] 28)
        if ($i + 1 -lt $nombres.Count) { $fila += '  - ' + $nombres[$i + 1] }
        Out-Resumen $fila.TrimEnd() White
    }
    Add-Html '<div style="padding:6px 0 2px">'
    foreach ($n in $nombres) {
        Add-Html ('<span style="display:inline-block;margin:0 6px 6px 0;padding:4px 10px;border-radius:999px;' +
            'background:#1c1c21;border:1px solid #2e2e35;color:#f4f4f5;font-size:13px">' + (Format-HtmlTexto $n) + '</span>')
    }
    Add-Html '</div>'
}

# Nombres de la tabla de apps en consola: el nombre, recortado si no cabe. Solo si al recortar dos apps quedan
# iguales (ej. "Microsoft Visual C++ 2013 Redi..." x64 y x86) se usa el Id, que es unico. Antes se usaba el Id
# en cuanto el nombre no cabia, y la tabla mezclaba nombres e Ids (27/11/2026).
function Get-NombresTablaApps($apps, $ancho) {
    $apps = @($apps)
    $recortados = @($apps | ForEach-Object { (Format-Ancho $_.Nombre $ancho).TrimEnd() })
    $repetidos = @($recortados | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
    $nombres = for ($i = 0; $i -lt $apps.Count; $i++) {
        $id = $apps[$i].Id
        if ($recortados[$i] -in $repetidos -and $id -and $id.Length -lt $ancho) { $id } else { $recortados[$i] }
    }
    return , @($nombres)
}

# "45 min" o "3 h 21 min"
function Format-Duracion($segundos) {
    $min = [math]::Round($segundos / 60)
    if ($min -lt 60) { return "$([math]::Max(1, $min)) min" }
    return '{0} h {1:00} min' -f [math]::Floor($min / 60), ($min % 60)
}

# Por que un paso pudo tardar mas de 1 h (Get-PasosLargos)
function Get-NotaPasoLargo($paso) {
    switch ($paso) {
        10 { 'SFC y DISM suelen tardar 10-60 min: tanto tiempo apunta a un disco lento o muy ocupado (revisa el modelo y la temperatura del SSD)' }
        16 { 'Actualizar muchas aplicaciones puede tardar: el detalle de cada una esta en el log' }
        default { 'Un paso no deberia tardar mas de 1 h: el detalle esta en el log' }
    }
}

# Si el espacio libre bajo durante la limpieza, por que (o $null si no bajo). Bajar no es un error: los puntos de
# restauracion crecen mientras DISM, SFC y los instaladores cambian archivos, y las apps nuevas ocupan mas.
# "5.07 GB -> 2.07 GB" si lo que ocupan los puntos de restauracion cambio 100 MB o mas (en cualquier direccion),
# o $null. No se suma a "Liberado": es espacio que Windows administra, no lo borra la limpieza. Sin esta linea no
# se entendia la diferencia: el 28/11/2026 se liberaron 4,42 GB y el espacio libre subio 6,6 GB, porque el paso 15
# borro un punto viejo (5,07 -> 2,07 GB); el dato solo estaba en el log.
function Get-TextoPuntos($d) {
    if ($null -eq $d.PuntosInicio -or $null -eq $d.PuntosFin) { return $null }
    if ([math]::Abs($d.PuntosFin - $d.PuntosInicio) -lt 100MB) { return $null }
    return '{0} -> {1}' -f (Format-Tamano $d.PuntosInicio), (Format-Tamano $d.PuntosFin)
}

function Get-NotaEspacioBaja($d) {
    if ($d.LibreFin - $d.LibreInicio -gt -100MB) { return $null }
    $causas = @()
    if ($null -ne $d.PuntosInicio -and $null -ne $d.PuntosFin -and $d.PuntosFin - $d.PuntosInicio -ge 100MB) {
        $causas += 'los puntos de restauracion crecieron {0} (vuelve cuando se reemplazan)' -f (Format-Tamano ($d.PuntosFin - $d.PuntosInicio))
    }
    $actualizadas = @($d.AppsActualizadas).Where({ $_ }).Count
    if ($actualizadas) { $causas += "se actualizaron $actualizadas app(s)" }
    $causas += 'Windows Update pudo descargar archivos'
    return 'Bajo porque ' + ($causas -join ', ') + '. No es basura de la limpieza'
}

function Write-TablaApps($titulo, $apps, $color, [switch]$ConMotivo) {
    if (-not $apps) { return }
    $apps = @($apps)
    Out-Resumen ''
    Out-Resumen "    $titulo ($($apps.Count))" $color
    Add-Html ('<div style="font-size:14px;font-weight:700;color:' + (Get-ColorHtml $color) + ';padding:12px 0 2px">' +
        (Format-HtmlTexto "$titulo ($($apps.Count))") + '</div>')

    $nombres = Get-NombresTablaApps $apps 34
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $a = $apps[$i]
        Out-Resumen ('      ' + (Format-Ancho $nombres[$i] 34) + (Format-Ancho $a.Instalada 15) + '-> ' + $a.Disponible) $color
        if ($ConMotivo -and $a.Motivo) { Out-Resumen "        motivo: $($a.Motivo)" DarkGray }

        # Correo: nombre completo (el texto se ajusta solo) y las versiones debajo
        # El motivo va en rojo solo si es un error; si no (ej. "se actualiza sola"), en gris
        $motivo = ''
        if ($ConMotivo -and $a.Motivo) {
            $colorMotivo = if ($color -eq 'Red') { $script:coloresHtml['Red'] } else { $script:coloresHtml['DarkGray'] }
            $motivo = '<div style="font-size:12px;color:' + $colorMotivo + ';margin-top:2px">' + (Format-HtmlTexto $a.Motivo) + '</div>'
        }
        Add-Html ('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid ' + $script:lineaHtml + '"><tr>' +
            '<td style="padding:7px 0">' +
            '<div style="font-size:14px;color:#f4f4f5">' + (Format-HtmlTexto $a.Nombre) + '</div>' +
            '<div style="font-size:12px;color:#8b8b94;margin-top:1px">' + (Format-HtmlTexto $a.Instalada) + ' &rarr; ' +
            (Format-HtmlTexto $a.Disponible) + '</div>' + $motivo +
            '</td></tr></table>')
    }
}

# --- Resumen completo ---

# Muestra el resumen. $d es un hashtable con los datos que junta limpiar.ps1.
function Show-Resumen($d) {
    $salud = $d.Salud   # lo junta Get-SaludEquipo (lib\salud.ps1) en el paso 17

    $subtitulo = $env:COMPUTERNAME
    if ($salud.Version) { $subtitulo += " - $($salud.Version.Nombre)" }
    Write-Cabecera 'RESUMEN DE LA LIMPIEZA' ("$subtitulo - " + (Get-Date -Format 'dd/MM/yyyy HH:mm'))

    # --- Espacio ---
    Write-Seccion 'ESPACIO'
    $delta = ($d.LibreFin - $d.LibreInicio) / 1GB
    $signo = if ($delta -ge 0) { '+' } else { '' }
    # En GB desde 1000 MB: con separador de miles "15.823,82 MB" se lee como 15 MB
    $liberadoTexto = if ($d.Total -ge 1000) { '{0:N2} GB' -f ($d.Total / 1024) } else { '{0:N0} MB' -f $d.Total }
    Write-Dato 'Liberado por la limpieza' $liberadoTexto Green
    Write-Dato 'Espacio libre en C:' ('{0:N1} -> {1:N1} GB ({2}{3:N1} GB)' -f ($d.LibreInicio / 1GB), ($d.LibreFin / 1GB), $signo, $delta)
    $textoPuntos = Get-TextoPuntos $d
    if ($textoPuntos) { Write-Dato 'Puntos de restauracion' $textoPuntos White }
    $notaEspacio = Get-NotaEspacioBaja $d
    if ($notaEspacio) { Write-Nota $notaEspacio Yellow }
    # Cuanto tardo (sin contar las preguntas) y si algun paso que hace siempre lo mismo tardo el triple de lo normal
    if ($d.SegundosLimpieza) {
        $lento = @($d.PasosLentos)[0]
        $largo = @($d.PasosLargos)[0]
        if ($lento) {
            Write-Estado 'AVISO' 'Duracion' ('{0:N0} min; el paso {1} tardo {2:N0} min y lo normal es {3:N0} min (ver log)' -f ($d.SegundosLimpieza / 60), $lento.Paso, ($lento.Segundos / 60), [math]::Max(1, $lento.Normal / 60))
        } elseif ($largo) {
            # INFO y no AVISO: la primera vez no hay con que comparar, y a veces es esperable (muchas apps que actualizar)
            Write-Estado 'INFO' 'Duracion' ('{0}; el paso {1} tardo {2}' -f (Format-Duracion $d.SegundosLimpieza), $largo.Paso, (Format-Duracion $largo.Segundos))
            Write-Nota (Get-NotaPasoLargo $largo.Paso)
        } else {
            Write-Dato 'Duracion' ('{0:N0} min' -f [math]::Max(1, $d.SegundosLimpieza / 60)) White
        }
    }

    # Comparacion con la limpieza anterior (historial.csv)
    if ($d.Anterior) {
        $a = $d.Anterior
        $liberadoAntes = if ($a.LiberadoMB -ge 1024) { '{0:N2} GB' -f ($a.LiberadoMB / 1024) } else { '{0:N0} MB' -f $a.LiberadoMB }
        Write-Dato 'Limpieza anterior' ('{0} ({1:dd/MM HH:mm}), libero {2}' -f (Format-Hace $a.Fecha), $a.Fecha, $liberadoAntes) White
        # Cuanto se lleno el disco entre esa limpieza y esta (antes de limpiar hoy)
        $lleno = $a.LibreFinGB - ($d.LibreInicio / 1GB)
        $textoLleno = if ($lleno -ge 0.05) { 'se ocuparon {0:N1} GB' -f $lleno } elseif ($lleno -le -0.05) { 'se liberaron {0:N1} GB' -f (-$lleno) } else { 'casi sin cambios' }
        Write-Dato 'Desde entonces' $textoLleno White
    } else {
        Write-Dato 'Limpieza anterior' 'esta es la primera registrada' DarkGray
    }
    # A que ritmo se llena C: aunque se limpie (historial de los ultimos meses)
    $t = $d.Tendencia
    if ($t) {
        if ($t.GBPorMes -gt 0.1) {
            $textoTendencia = 'pierdes {0:N1} GB al mes' -f $t.GBPorMes
            if ($t.Meses) {
                $meses = [math]::Round($t.Meses)
                if ($meses -le 24) { $textoTendencia += "; bajaria del 15 % libre en ~$([math]::Max(1, $meses)) mes(es)" }
            }
            $colorTendencia = if ($t.Meses -and $t.Meses -le 3) { 'Yellow' } else { 'White' }
            Write-Dato 'Tendencia' $textoTendencia $colorTendencia
        } else {
            # Si el espacio libre sube es por archivos borrados a mano, no por una tendencia: no se da una cifra
            Write-Dato 'Tendencia' 'no se esta llenando' Green
        }
    }
    # Docker: lo que libera queda dentro de su disco virtual; vuelve a Windows al compactar
    if ($d.DockerInstalado -and $d.EsAdmin) {
        if ($d.DockerActivo) {
            Write-Dato 'Limpieza de Docker' ('{0:N2} MB' -f ($d.DockerLiberado / 1MB)) Green
            if ($d.DockerImagenes) { Write-Nota ('Imagenes de Docker borradas: ' + (@($d.DockerImagenes).Nombre -join ', ')) }
        } else {
            Write-Dato 'Limpieza de Docker' 'no estaba en marcha' DarkGray
        }
    }
    # apt-get clean en WSL (paso 12): tambien queda dentro del disco virtual de cada distro
    if ($d.ActualizacionesWsl) {
        $cacheApt = (@($d.ActualizacionesWsl) | Measure-Object CacheBytes -Sum).Sum
        Write-Dato 'Cache de apt en WSL' ('{0:N2} MB' -f ($cacheApt / 1MB)) Green
    }
    foreach ($c in $d.Compactados) {
        if ($c.Ok) { Write-Dato "Disco virtual $($c.Nombre)" ('{0:N2} GB -> {1:N2} GB' -f ($c.Antes / 1GB), ($c.Despues / 1GB)) Green }
        else { Write-Dato "Disco virtual $($c.Nombre)" 'no se pudo compactar (ver log)' Red }
    }
    # Espacio que el script no libera pero conviene conocer (solo informa)
    # node_modules viejos: solo desde 200 MB en total (menos no vale la pena; la lista siempre queda en el log)
    $nm = $d.NodeModulesViejos
    $proyectos = if ($nm) { @($nm.Proyectos) } else { @() }
    $bytesNm = [double]($proyectos | Measure-Object Bytes -Sum).Sum
    if ($bytesNm -ge 200MB) {
        $textoNm = '{0} en {1} proyecto(s)' -f (Format-Tamano $bytesNm), $proyectos.Count
        if ($nm.Incompleto) { $textoNm += ' o mas' }
        Write-Dato 'node_modules sin usar' $textoNm White
        $carpetaUsuario = [Environment]::GetFolderPath('UserProfile')
        $mayores = $proyectos | Select-Object -First 3 | ForEach-Object { "$($_.Proyecto -replace [regex]::Escape($carpetaUsuario), '~') ($(Format-Tamano $_.Bytes))" }
        Write-Nota ("Proyectos sin cambios en 90 dias: " + ($mayores -join '; ') + '. Se borran a mano y se recuperan con npm install (lista completa en el log)')
    }
    $hib = $d.Salud.Hibernacion
    if ($hib -and $hib.Bytes -gt 0) {
        Write-Dato 'Hibernacion (hiberfil.sys)' (Format-Tamano $hib.Bytes) White
        # Tipo completo: ~40 % de la RAM; reducido (solo para el Inicio rapido): ~20 %
        if ($hib.RamBytes -gt 0 -and $hib.Bytes -gt 0.3 * $hib.RamBytes) {
            Write-Nota "Si no usas Hibernar: 'powercfg /h /type reduced' como administrador lo reduce a la mitad y mantiene el Inicio rapido"
        }
    }

    # --- Salud del equipo (hardware) ---
    Write-Seccion 'SALUD DEL EQUIPO'
    $textoDisco = "$($d.DiscoC.HealthStatus)"
    $nivelDisco = if ($d.DiscoC.HealthStatus -eq 'Healthy') { 'OK' } else { 'AVISO' }
    $f = $salud.Fiabilidad
    if ($f -and $null -ne $f.Wear) {
        $textoDisco += " | vida usada $($f.Wear)%"
        if ($f.Wear -ge 80) { $nivelDisco = 'AVISO' }
    }
    if ($f -and $f.Temperature) {
        $textoDisco += " | $($f.Temperature) $([char]0xB0)C"
        # Un SSD NVMe trabaja normalmente a 60-75 C con carga (y se mide justo despues del TRIM);
        # empieza a protegerse cerca de 80 C. Con un umbral mas bajo habria avisos falsos.
        if ($f.Temperature -ge 80) { $nivelDisco = 'AVISO' }
    }
    if ($f -and $f.PowerOnHours) { $textoDisco += ' | {0:N0} h de uso' -f $f.PowerOnHours }
    # Errores de lectura que el disco no pudo corregir: la senal mas clara de que esta fallando
    if ($f -and $f.ReadErrorsUncorrected -gt 0) {
        $textoDisco += " | $($f.ReadErrorsUncorrected) error(es) de lectura: haz copia de tus archivos"
        $nivelDisco = 'AVISO'
    }
    Write-Estado $nivelDisco "Disco ($($d.DiscoC.MediaType))" $textoDisco

    # Revision en linea del sistema de archivos (Repair-Volume -Scan, solo administrador)
    if (-not $d.EsAdmin) { Write-Estado 'NA' 'Sistema de archivos' 'solo se revisa como administrador' }
    elseif (-not $salud.SistemaArchivos) { Write-Estado 'NA' 'Sistema de archivos' 'no se pudo revisar (ver log)' }
    elseif ($salud.SistemaArchivos -eq 'NoErrorsFound') { Write-Estado 'OK' 'Sistema de archivos' 'sin errores' }
    elseif ($salud.SistemaArchivos -match 'SpotFix') {
        # Lo que necesita SpotFix es por definicion menor (una entrada de indice, un vinculo): no es un fallo del
        # disco, que se vigila aparte con sus contadores. Solo informa, para no repetir un aviso que a veces no se
        # puede resolver enseguida (25/11/2026: chkdsk.exe no abria en una version de prueba de Windows)
        Write-Estado 'INFO' 'Sistema de archivos' "error menor pendiente; se repara a mano con 'chkdsk C: /spotfix' y reiniciando (pasos en el log y en el README, 'Reparar el disco')"
    }
    elseif ($salud.SistemaArchivos -match 'Fixed') { Write-Estado 'OK' 'Sistema de archivos' 'errores menores, ya corregidos en linea' }
    else { Write-Estado 'AVISO' 'Sistema de archivos' "errores ($($salud.SistemaArchivos)): se reparan a mano con 'chkdsk C: /f' y reiniciando (pasos en el log y en el README, 'Reparar el disco')" }
    # Solo si fallo: sin TRIM el SSD se va volviendo mas lento al escribir (ver log, paso 14)
    if ($d.TrimError) {
        $textoTrim = "no se pudo hacer: $($d.TrimError)"
        # 0x89000015: C: esta marcado para revisar y Windows no optimiza hasta que se repare
        if ($d.TrimError -match '0x89000015') { $textoTrim = "no se pudo hacer: C: tiene una reparacion pendiente; vuelve a funcionar al reparar el disco (README, 'Reparar el disco')" }
        Write-Estado 'AVISO' 'TRIM del SSD' $textoTrim
    }

    # Poco espacio: con menos del 15 % libre Windows y las actualizaciones empiezan a tener problemas
    if ($d.TamanoC -gt 0) {
        $porcentaje = 100 * $d.LibreFin / $d.TamanoC
        $nivelEspacio = if ($porcentaje -lt 15) { 'AVISO' } else { 'OK' }
        $textoEspacio = '{0:N1} GB libres de {1:N0} GB ({2:N0} %)' -f ($d.LibreFin / 1GB), ($d.TamanoC / 1GB), $porcentaje
        if ($nivelEspacio -eq 'AVISO') { $textoEspacio += ': queda poco espacio' }
        Write-Estado $nivelEspacio 'Espacio en C:' $textoEspacio
    }

    if ($salud.Bateria) {
        $nivel = if ($salud.Bateria.Salud -ge 80) { 'OK' } else { 'AVISO' }
        Write-Estado $nivel 'Bateria' "$($salud.Bateria.Salud)% de la capacidad original ($($salud.Bateria.Ciclos) ciclos)"
    }

    # Plan de energia: "Ahorro de energia" limita el procesador (solo informa: en un portatil puede ser a proposito)
    $plan = $salud.PlanEnergia
    if ($plan -and $plan.AhorroEnergia) { Write-Estado 'INFO' 'Plan de energia' "$($plan.Nombre): limita el procesador; para mas rendimiento usa Equilibrado" }
    elseif ($plan) { Write-Estado 'OK' 'Plan de energia' $plan.Nombre }

    # Errores de hardware (WHEA): los graves siempre avisan; los corregidos solo si son muchos
    $h = $salud.Hardware
    if ($null -eq $h) { Write-Estado 'NA' 'Hardware (30 dias)' 'no se pudo leer el registro de eventos' }
    elseif ($h.Graves -gt 0) {
        Write-Estado 'AVISO' 'Hardware (30 dias)' ("$($h.Graves) error(es) grave(s) de RAM/CPU/disco; ultimo {0:dd/MM HH:mm}" -f $h.Ultimo)
    }
    elseif ($h.Corregidos -ge 10) {
        Write-Estado 'AVISO' 'Hardware (30 dias)' "$($h.Corregidos) errores corregidos: puede ser la RAM o un driver"
    }
    elseif ($h.Corregidos -gt 0) { Write-Estado 'OK' 'Hardware (30 dias)' "$($h.Corregidos) error(es) corregido(s), pocos: normal" }
    else { Write-Estado 'OK' 'Hardware (30 dias)' 'sin errores' }

    # Dispositivos con problema (Administrador de dispositivos). "Sin driver" (28) solo informa: suele ser un
    # componente secundario que funciona sin driver propio; lo demas (no inicia, fallo, driver danado) avisa.
    $dv = $salud.Dispositivos
    if ($null -eq $dv) { Write-Estado 'NA' 'Dispositivos' 'no se pudo leer la lista' }
    elseif (@($dv).Count -eq 0) { Write-Estado 'OK' 'Dispositivos' 'todos funcionan' }
    else {
        $dv = @($dv)
        $textoDv = "$($dv.Count) con problema: " + (($dv | Select-Object -First 3 | ForEach-Object { "$($_.Nombre) ($(Get-TextoProblemaDispositivo $_.Codigo))" }) -join '; ')
        if ($dv.Count -gt 3) { $textoDv += "; y $($dv.Count - 3) mas (ver log)" }
        $textoDv += '. Revisalos en el Administrador de dispositivos (Win+X)'
        $nivelDv = if (@($dv | Where-Object { $_.Codigo -ne 28 }).Count -gt 0) { 'AVISO' } else { 'INFO' }
        Write-Estado $nivelDv 'Dispositivos' $textoDv
    }

    $c = $salud.Cuelgues
    if ($null -eq $c) { Write-Estado 'NA' 'Cuelgues (30 dias)' 'no se pudo leer el registro de eventos' }
    elseif ($c.Pantallazos + $c.OtrosApagados -eq 0) { Write-Estado 'OK' 'Cuelgues (30 dias)' 'ningun pantallazo azul ni apagado inesperado' }
    else {
        $partes = @()
        if ($c.Pantallazos) { $partes += "$($c.Pantallazos) pantallazo(s) azul(es)" }
        if ($c.OtrosApagados) { $partes += "$($c.OtrosApagados) apagado(s) inesperado(s)" }
        Write-Estado 'AVISO' 'Cuelgues (30 dias)' (($partes -join ' y ') + ('; ultimo {0:dd/MM HH:mm}' -f $c.Ultimo))
    }

    # Apps que se cerraron solas o se colgaron 3 veces o mas en 7 dias (solo informa: suele ser la app, no el equipo)
    $af = $salud.AppsQueFallan
    if ($null -eq $af) { Write-Estado 'NA' 'Apps que fallan' 'no se pudo leer el registro de eventos' }
    elseif (@($af).Count -eq 0) { Write-Estado 'OK' 'Apps que fallan' 'ninguna se cerro sola ni se colgo 3 veces o mas en 7 dias' }
    else {
        $textoAf = (@($af) | Select-Object -First 3 | ForEach-Object { "$($_.App) ($($_.Veces) veces)" }) -join ', '
        Write-Estado 'INFO' 'Apps que fallan' "en 7 dias: $($textoAf). Si molesta, actualiza o reinstala esa app"
    }

    # Ultima prueba de memoria de Windows (mdsched): solo si alguna vez se hizo
    $pm = $salud.PruebaMemoria
    if ($pm -and $pm.ConErrores) { Write-Estado 'AVISO' 'Memoria RAM' ('la ultima prueba de memoria ({0:dd/MM/yyyy}) encontro errores: revisa o cambia la RAM' -f $pm.Fecha) }
    elseif ($pm) { Write-Estado 'OK' 'Memoria RAM' ('sin errores en la ultima prueba de memoria ({0:dd/MM/yyyy})' -f $pm.Fecha) }

    # --- Windows y seguridad ---
    Write-Seccion 'WINDOWS Y SEGURIDAD'
    $wu = $salud.WindowsUpdate
    if (-not $wu -or $wu.Error) { Write-Estado 'NA' 'Windows Update' 'no se pudo consultar (ver log)' }
    else {
        $partes = @()
        $partes += if ($wu.Pendientes) { "$($wu.Pendientes.Count) pendiente(s)" } else { 'al dia' }
        if ($wu.UltimaInstalada) { $partes += 'ultima instalada ' + (Format-Hace $wu.UltimaInstalada) }
        $nivelWu = 'OK'
        if ($wu.Fallidas) { $nivelWu = 'AVISO'; $partes += "$($wu.Fallidas.Count) fallaron (ver log)" }
        # Windows instala solo cada mes: mas de 45 dias sin nada indica que algo lo esta frenando
        if (-not $wu.UltimaInstalada -or ((Get-Date) - $wu.UltimaInstalada).TotalDays -gt 45) {
            $nivelWu = 'AVISO'; $partes += 'revisa Configuracion > Windows Update'
        }
        Write-Estado $nivelWu 'Windows Update' ($partes -join '; ')
        if ($wu.Opcionales) { Write-Nota "$($wu.Opcionales.Count) actualizacion(es) opcional(es) disponibles (drivers, vistas previas): ver log" }
    }

    $av = $salud.Defender
    if (-not $av) { Write-Estado 'NA' 'Antivirus (Defender)' 'no se pudo leer su estado' }
    elseif ($av.Modo -ne 'Normal') { Write-Estado 'NA' 'Antivirus (Defender)' "en modo '$($av.Modo)': otro antivirus estaria protegiendo el equipo" }
    elseif (-not $av.TiempoReal) { Write-Estado 'AVISO' 'Antivirus (Defender)' 'la proteccion en tiempo real esta DESACTIVADA' }
    elseif ($av.DiasFirmas -gt 7) {
        $hace = if ($av.DiasFirmas -ge 65535) { 'nunca se actualizaron' } else { "son de hace $($av.DiasFirmas) dias" }
        Write-Estado 'AVISO' 'Antivirus (Defender)' "activo, pero sus firmas $hace"
    }
    else { Write-Estado 'OK' 'Antivirus (Defender)' ('activo, firmas al dia ({0:dd/MM HH:mm})' -f $av.FechaFirmas) }

    # Firewall, UAC y Arranque seguro avisan si estan apagados; el cifrado del disco solo se informa
    $s = $salud.Seguridad
    $apagado = @()
    if ($s.FirewallApagado) { $apagado += "firewall de red $($s.FirewallApagado -join '/')" }
    if (-not $s.UacActivo) { $apagado += 'control de cuentas (UAC)' }
    if ($s.ArranqueSeguro -eq $false) { $apagado += 'Arranque seguro' }
    $cifradoTexto = switch ($s.DiscoCifrado) { $true { 'C: cifrado' } $false { 'C: sin cifrar' } default { $null } }
    if ($apagado) {
        Write-Estado 'AVISO' 'Seguridad' ('desactivado: ' + ($apagado -join ', '))
    } elseif (-not $s.FirewallLeido) {
        Write-Estado 'NA' 'Seguridad' 'no se pudo leer el firewall'
    } else {
        $textoSeg = 'firewall, UAC' + $(if ($s.ArranqueSeguro) { ' y Arranque seguro' } else { '' }) + ' activos'
        if ($cifradoTexto) { $textoSeg += "; $cifradoTexto" }
        Write-Estado 'OK' 'Seguridad' $textoSeg
    }

    # Respaldo de Documentos y Escritorio (OneDrive o Historial de archivos)
    $r = $salud.Respaldo
    if ($r.EnOneDrive.Count -eq 2 -and $r.OneDriveAbierto) { Write-Estado 'OK' 'Respaldo de archivos' 'Documentos y Escritorio en OneDrive' }
    # Lo demas solo informa (INFO, no cuenta como aviso): el usuario puede respaldar de otra forma
    elseif ($r.EnOneDrive -and -not $r.OneDriveAbierto) { Write-Estado 'INFO' 'Respaldo de archivos' 'OneDrive esta cerrado: no esta sincronizando' }
    elseif ($r.HistorialArchivos) { Write-Estado 'OK' 'Respaldo de archivos' 'Historial de archivos configurado' }
    elseif ($r.EnOneDrive) { Write-Estado 'INFO' 'Respaldo de archivos' "solo $($r.EnOneDrive -join ' y ') en OneDrive" }
    else { Write-Estado 'INFO' 'Respaldo de archivos' 'Documentos y Escritorio sin OneDrive ni Historial de archivos' }

    if ($d.EsAdmin) {
        if ($r.UltimoPunto) { Write-Estado 'OK' 'Punto de restauracion' ('el mas reciente {0} ({1:dd/MM})' -f (Format-Hace $r.UltimoPunto), $r.UltimoPunto) }
        else { Write-Estado 'AVISO' 'Punto de restauracion' 'no hay ninguno: activa la Proteccion del sistema en C:' }
    }

    if ($salud.UltimoArranque) {
        $textoArranque = '{0} ({1:dd/MM HH:mm})' -f (Format-Hace $salud.UltimoArranque), $salud.UltimoArranque
        if (((Get-Date) - $salud.UltimoArranque).TotalDays -gt 14) {
            # Con el Inicio rapido, Apagar no cuenta como reinicio
            Write-Estado 'AVISO' 'Ultimo reinicio' "$($textoArranque): usa Reiniciar, no Apagar"
        } else {
            Write-Estado 'OK' 'Ultimo reinicio' $textoArranque
        }
    }

    if (-not $d.EsAdmin) { Write-Estado 'NA' 'Recuperacion (WinRE)' 'solo se revisa como administrador' }
    elseif ($salud.WinRE -eq $true) { Write-Estado 'OK' 'Recuperacion (WinRE)' 'activa' }
    elseif ($salud.WinRE -eq $false) { Write-Estado 'AVISO' 'Recuperacion (WinRE)' 'desactivada: si Windows no arranca no habra reparacion' }
    else { Write-Estado 'NA' 'Recuperacion (WinRE)' 'no se pudo leer el estado' }

    if ($salud.ReinicioPendiente) { Write-Estado 'AVISO' 'Reinicio pendiente' 'si: reinicia para terminar actualizaciones' }
    else { Write-Estado 'OK' 'Reinicio pendiente' 'no' }

    # --- Programas de inicio ---
    $inicio = @($d.Inicio)
    Write-Seccion "PROGRAMAS QUE ARRANCAN CON WINDOWS ($($inicio.Count))"
    # Tiempo de arranque (registro de rendimiento de Windows, solo administrador)
    $ar = $salud.Arranque
    if ($d.EsAdmin) {
        if (-not $ar) { Write-Estado 'NA' 'Tiempo de arranque' 'no se pudo leer (ver log)' }
        elseif (-not $ar.Mediana) { Write-Estado 'INFO' 'Tiempo de arranque' ('ultimo {0:N0} s; pocos arranques en 30 dias para comparar' -f $ar.Ultimo) }
        else {
            $textoAr = '{0:N0} s (mediana de {1} arranques en 30 dias)' -f $ar.Mediana, $ar.Cantidad
            if ($ar.MedianaAntes) { $textoAr += '; antes {0:N0} s' -f $ar.MedianaAntes }
            if ($ar.MasLento) { Write-Estado 'AVISO' 'Tiempo de arranque' "$($textoAr): arranca mas lento; abajo, lo que mas lo retrasa" }
            else { Write-Estado 'OK' 'Tiempo de arranque' $textoAr }
        }
    }
    Write-Lista ($inicio | ForEach-Object { $_.Name })
    # Lo que mas retraso el arranque segun Windows: hasta 3, solo si suman 2 s o mas (el resto, en el log)
    $retrasos = @($salud.RetrasosArranque | Where-Object { $_.Segundos -ge 2 } | Select-Object -First 3)
    if ($retrasos) {
        Write-Nota 'Lo que mas retraso el arranque en 30 dias (segun Windows):' Gray
        # El tipo va en el valor: en la etiqueta, con un nombre largo se perdia la alineacion (27/11/2026)
        foreach ($r in $retrasos) { Write-Dato $r.Nombre ('+{0:N0} s en {1} arranque(s), {2}' -f $r.Segundos, $r.Veces, $r.Tipo) White }
    }
    Write-Nota 'Para desactivar: Administrador de tareas (Ctrl+Shift+Esc) > Aplicaciones de arranque'

    # --- Aplicaciones ---
    Write-Seccion 'APLICACIONES'
    if ($d.EstadoWinget -notin 'ok', 'al dia') {
        # No decir "todo al dia" si en realidad no se pudo consultar
        Write-Nota "No se pudo consultar winget: $($d.EstadoWinget). No se sabe si hay actualizaciones" Red
    } elseif ($d.SeActualizo) {
        Write-TablaApps 'Actualizadas' $d.AppsActualizadas Green
        Write-TablaApps 'No se pudieron actualizar' $d.AppsFallidas Red -ConMotivo
        Write-TablaApps 'Siguen pendientes' $d.AppsPendientes Yellow
        Write-TablaApps 'Se actualizan solas' $d.AppsOmitidas DarkGray -ConMotivo
        Write-TablaApps 'Winget no las puede actualizar' $d.AppsNoAplican DarkGray -ConMotivo
        if (-not $d.AppsPendientes -and -not $d.AppsFallidas) { Write-Nota 'Todo lo demas esta al dia' Green }
    } elseif ($d.AppsDisponibles) {
        Write-TablaApps 'Con actualizacion disponible' $d.AppsDisponibles Yellow
        Write-Nota "Para actualizarlas, responde S a 'Actualizar las aplicaciones' la proxima vez"
    } else {
        Write-Nota 'Todas las aplicaciones estan al dia' Green
    }

    # --- Paquetes de Linux en WSL (paso 12): solo si hay distros con apt ---
    if ($d.DistrosApt) {
        Write-Seccion 'PAQUETES DE LINUX (WSL)'
        if (-not $d.ActualizarWsl) {
            Write-Dato 'Distribuciones' (@($d.DistrosApt) -join ', ') White
            Write-Nota "No se actualizaron. Para hacerlo, responde S a 'Actualizar los paquetes de Linux' la proxima vez"
        }
        foreach ($r in $d.ActualizacionesWsl) {
            $paquetes = @($r.Paquetes)
            if (-not $r.Ok) {
                Write-Dato $r.Nombre 'error (ver log)' Red
                Write-Nota $r.Error Red
            } elseif ($paquetes.Count -eq 0) {
                Write-Dato $r.Nombre 'todo al dia' Green
            } else {
                Write-Dato $r.Nombre "$($paquetes.Count) paquete(s) actualizado(s)" Green
                # Con muchos paquetes la lista no aporta en el correo: queda completa en el log
                if ($paquetes.Count -le 15) { Write-TablaApps 'Actualizados' $paquetes Green }
                else { Write-Nota 'La lista completa con las versiones esta en el log' }
            }
            if ($r.Retenidos -gt 0) {
                # Normalmente actualizaciones escalonadas de Ubuntu: llegan solas en otra ejecucion
                Write-Nota ("{0}: {1} paquete(s) retenido(s) por apt; suelen actualizarse en una proxima ejecucion" -f $r.Nombre, $r.Retenidos)
            }
        }
    }

    Close-Tarjeta
    Out-Resumen ''
    Out-Resumen ('  ' + ([string][char]0x2550 * $script:anchoResumen)) Cyan
}

# Documento HTML del correo. Ancho maximo 600 px (el estandar de los correos) y 100 % en el celular.
function Get-ResumenHtml($pie) {
    '<!doctype html><html><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
    # Ya es oscuro: que el modo oscuro del cliente de correo no invierta los colores
    '<meta name="color-scheme" content="dark"><meta name="supported-color-schemes" content="dark"></head>' +
    '<body style="margin:0;padding:0;background:' + $script:fondoHtml + '">' +
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="' + $script:fondoHtml + '" ' +
    'style="background:' + $script:fondoHtml + '"><tr>' +
    '<td align="center" style="padding:16px 10px">' +
    '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" ' +
    'style="max-width:600px;font-family:' + $script:fuenteHtml + ';color:#f4f4f5">' +
    $script:resumenHtml.ToString() +
    '<tr><td style="padding:14px 4px 0;font-size:12px;color:#6b6b74;text-align:center">' + (Format-HtmlTexto $pie) + '</td></tr>' +
    '</table></td></tr></table></body></html>'
}
