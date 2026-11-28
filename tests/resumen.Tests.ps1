# Pruebas de lib\resumen.ps1: que cada bloque escriba en consola y en el correo, y que solo
# AVISO cuente para el asunto del correo.

. (Join-Path $PSScriptRoot 'cargar.ps1')

Describe 'Write-Estado' {
    Mock Out-Resumen { }

    It 'solo AVISO suma al contador del asunto del correo' {
        $script:avisosResumen = 0
        Write-Estado 'OK' 'Disco' 'bien'
        Write-Estado 'INFO' 'Respaldo' 'sin OneDrive'
        Write-Estado 'NA' 'Bateria' 'N/D'
        $script:avisosResumen | Should Be 0
        Write-Estado 'AVISO' 'Espacio' 'queda poco'
        $script:avisosResumen | Should Be 1
    }

    It 'escribe la misma linea en la consola y en el correo' {
        $script:resumenHtml = New-Object Text.StringBuilder
        Write-Estado 'AVISO' 'Windows Update' '2 fallaron'
        Assert-MockCalled Out-Resumen -Scope It -Times 1 -ParameterFilter { $texto -match 'Windows Update' -and $texto -match '2 fallaron' }
        $html = $script:resumenHtml.ToString()
        $html | Should Match 'Windows Update'
        $html | Should Match '2 fallaron'
        $html | Should Match '>AVISO<'
    }

    It 'escapa el texto en el HTML del correo' {
        $script:resumenHtml = New-Object Text.StringBuilder
        Write-Estado 'INFO' 'App <script>' 'a & b'
        $html = $script:resumenHtml.ToString()
        $html | Should Not Match '<script>'
        $html | Should Match '&lt;script&gt;'
        $html | Should Match 'a &amp; b'
    }
}

Describe 'Write-Dato' {
    Mock Out-Resumen { }

    It 'escribe en la consola y en el correo' {
        $script:resumenHtml = New-Object Text.StringBuilder
        Write-Dato 'Liberado' '3.10 GB' Green
        Assert-MockCalled Out-Resumen -Scope It -Times 1 -ParameterFilter { $texto -match 'Liberado \.+ 3\.10 GB' }
        $script:resumenHtml.ToString() | Should Match '3\.10 GB'
    }
}

Describe 'Get-NombresTablaApps' {
    $app = { param($n, $id) [pscustomobject]@{ Nombre = $n; Id = $id } }

    It 'recorta el nombre largo en vez de cambiarlo por el Id' {
        $r = Get-NombresTablaApps @(& $app 'Microsoft Visual Studio Code (User) edicion larga' 'Microsoft.VisualStudioCode'; & $app 'Git' 'Git.Git') 20
        $r[0] | Should Be 'Microsoft Visual...'
        $r[1] | Should Be 'Git'
    }
    It 'usa el Id solo si dos nombres recortados quedan iguales' {
        $r = Get-NombresTablaApps @(& $app 'Microsoft Visual C++ 2013 x64' 'VC2013.x64'; & $app 'Microsoft Visual C++ 2013 x86' 'VC2013.x86') 20
        $r[0] | Should Be 'VC2013.x64'
        $r[1] | Should Be 'VC2013.x86'
    }
}

Describe 'Format-Duracion' {
    It 'minutos por debajo de 1 h y horas con minutos por encima' {
        Format-Duracion 2700 | Should Be '45 min'
        Format-Duracion 12043 | Should Be '3 h 21 min'
        Format-Duracion 10 | Should Be '1 min'
    }
}

Describe 'Get-TextoPuntos' {
    It 'muestra el cambio cuando bajan (caso del 28/11/2026: el paso 15 borro un punto viejo)' {
        Get-TextoPuntos @{ PuntosInicio = 5.07GB; PuntosFin = 2.07GB } | Should Match '^5[.,]07 GB -> 2[.,]07 GB$'
    }
    It 'y cuando suben' {
        Get-TextoPuntos @{ PuntosInicio = 0; PuntosFin = 3GB } | Should Match '^0 MB -> 3[.,]00 GB$'
    }
    It 'nada si cambian menos de 100 MB o si no se pudieron medir' {
        Get-TextoPuntos @{ PuntosInicio = 2GB; PuntosFin = 2.05GB } | Should BeNullOrEmpty
        Get-TextoPuntos @{ PuntosInicio = $null; PuntosFin = 2GB } | Should BeNullOrEmpty
    }
}

Describe 'Get-NotaEspacioBaja' {
    It 'no dice nada si el espacio libre no bajo' {
        Get-NotaEspacioBaja @{ LibreInicio = 50GB; LibreFin = 51GB } | Should BeNullOrEmpty
    }
    It 'explica la baja con los puntos de restauracion y las apps actualizadas (caso del 27/11/2026)' {
        $nota = Get-NotaEspacioBaja @{ LibreInicio = 52GB; LibreFin = 46.5GB; PuntosInicio = 0; PuntosFin = 3GB
            AppsActualizadas = @(1..13 | ForEach-Object { [pscustomobject]@{ Nombre = "app$_" } }) }
        $nota | Should Match 'puntos de restauracion crecieron 3[.,]00 GB'
        $nota | Should Match 'se actualizaron 13 app'
    }
    It 'sin la medida de los puntos (sin permisos) no los nombra' {
        $nota = Get-NotaEspacioBaja @{ LibreInicio = 52GB; LibreFin = 46GB; PuntosInicio = $null; PuntosFin = $null; AppsActualizadas = @() }
        $nota | Should Not Match 'puntos'
        $nota | Should Not Match 'actualizaron'
        $nota | Should Match 'Windows Update'
    }
}

Describe 'Format-Ancho' {
    It 'rellena hasta el ancho' {
        (Format-Ancho 'Git' 10).Length | Should Be 10
    }

    It 'recorta con "..." y deja un espacio antes de la columna siguiente' {
        $t = Format-Ancho 'Microsoft Visual C++ 2015-2022' 12
        $t.Length | Should Be 12
        $t | Should Be 'Microsof... '
    }
}
