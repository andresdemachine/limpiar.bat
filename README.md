# Limpieza de Windows

Script para limpiar y mantener Windows. Se ejecuta con doble clic, muestra un log de lo que va haciendo y al terminar muestra un resumen, lo envia por correo y espera a que presiones Enter.

## Archivos

| Archivo | Para que sirve |
|---|---|
| `limpiar.bat` | El que se ejecuta con **doble clic**. Pide permisos de administrador (UAC) y lanza el script. |
| `crear-acceso-directo.bat` | Doble clic: crea en el Escritorio el acceso directo `Limpieza Windows` a `limpiar.bat` con el icono de la escoba (negro con rojo neon). Si mueves la carpeta, vuelve a ejecutarlo (el acceso directo guarda rutas completas). No necesita permisos de administrador. |
| `crear-acceso-directo.ps1` | Lo que hace `crear-acceso-directo.bat`. No hace falta abrirlo: el `.bat` lo ejecuta sin que falle por la politica de ejecucion de scripts de Windows. |
| `limpiar.ico` | Icono del acceso directo. Windows no deja que un `.bat` tenga icono propio (todos los `.bat` muestran el mismo), por eso `limpiar.bat` se ve con el icono normal en el Explorador. |
| `limpiar.ps1` | Los pasos de la limpieza (PowerShell). |
| `lib\resumen.ps1` | El resumen final: lo muestra en pantalla y arma la version HTML para el correo. |
| `lib\salud.ps1` | Los datos de salud del equipo para el resumen (Windows Update, disco, errores de hardware, seguridad, respaldo...). Solo lee, no cambia nada. |
| `lib\correo.ps1` | El envio del resumen por correo con Resend. |
| `lib\historial.ps1` | Guarda cada ejecucion en `historial.csv` y la lee para comparar con la anterior. |
| `historial.csv` | Una linea por ejecucion: fecha, MB liberados, espacio libre al terminar, avisos, minutos que tardo y segundos de cada paso (se conservan las ultimas 200). Se crea solo. |
| `correo.json` | Configuracion del correo, **incluida la API key de Resend**. No lo compartas. Es opcional: se crea copiando `correo.ejemplo.json`. |
| `correo.ejemplo.json` | Plantilla de `correo.json` sin datos reales. |
| `limpieza.log` | Log de la **ultima** ejecucion. Se reemplaza cada vez. Guarda todo lo util: tus respuestas, que hizo u omitio cada paso, errores y el resumen final. |
| `verificar.ps1` | Solo para quien modifica el script: revisa la sintaxis, que los `.ps1` sean solo ASCII y corre las pruebas. No limpia nada (ver "Si modificas el script"). |
| `tests\` | Pruebas automaticas (Pester) y, en `tests\muestras`, salidas de ejemplo de winget y apt y un evento de arranque, sin datos de ningun equipo. |
| `.githooks\pre-commit` | Ejecuta `verificar.ps1` antes de cada commit. |
| `.vscode\settings.json` | Colores de VS Code para esta carpeta (negro con rojo neon, como el correo). Solo cambia como se ve el editor. |
| `memory-global\` | Notas y reglas para Claude Code (el asistente con el que se mantiene el script). El script no las usa; puedes ignorar la carpeta. |

`correo.json`, `limpieza.log`, `historial.csv` y el acceso directo (`.lnk`) son de cada equipo y estan en `.gitignore`: nunca se suben al repositorio.

## Requisitos

- Windows 10 u 11, instalado en C:.
- Windows PowerShell 5.1 (viene con Windows) y permisos de administrador (se piden con la ventana de UAC). Son obligatorios: sin ellos el script no hace nada.
- Lo demas es opcional: si un programa no esta (Chrome, Brave, Firefox, Teams, Discord, Slack, Docker, WSL, pip, npm, Yarn, pnpm, Go, Composer, uv, Bun, conda, NuGet, PM2, drivers NVIDIA/AMD), su parte simplemente no encuentra nada y se sigue. Si `winget` no esta instalado, el paso 16 lo avisa en rojo.
- Pensado para Windows en espanol o ingles. En otros idiomas funciona igual, pero el estado de WinRE puede aparecer como "N/D".
- Para crear puntos de restauracion (paso 10), la Proteccion del sistema tiene que estar activada en C: (`sysdm.cpl` > Proteccion del sistema). Si no lo esta, el resto funciona igual.

## Instalacion en otro equipo

No se instala nada: es una carpeta que se copia y se ejecuta. No crea servicios ni tareas programadas, ni cambia la configuracion de Windows.

### Que ocupa en el equipo

| Que | Donde | Tamano |
|---|---|---|
| La carpeta del script | Donde la copies (por ejemplo `C:\Herramientas\limpiar.bat`) | ~340 KB (~410 KB con `tests\` y las herramientas de desarrollo) |
| `limpieza.log` | En la carpeta, se reemplaza en cada ejecucion | 30-300 KB |
| `historial.csv` | En la carpeta, guarda las ultimas 200 ejecuciones | 30 KB como maximo |
| Acceso directo `Limpieza Windows` (opcional) | Escritorio | 2 KB |
| Puntos de restauracion | Los de Windows (Proteccion del sistema) | Se conservan solo los 2 mas recientes (paso 15) |

Mientras corre, el paso 9 usa un perfil temporal del Liberador de espacio de Windows (`StateFlags0042` en el registro), y lo quita al terminar. Si la ejecucion se corta, la siguiente lo quita al empezar. Las consultas de winget y Windows Update se hacen en segundo plano (otro proceso de PowerShell que termina con la ejecucion) y no dejan nada en el equipo.

### Pasos

1. **Descarga la carpeta** en una ubicacion fija (el acceso directo guarda la ruta completa: si despues la mueves, vuelve a crearlo):
   - con git: `git clone https://github.com/Mub1522/limpiar.bat.git`
   - o desde GitHub: *Code* > *Download ZIP* y descomprime.
2. **Si la descargaste como ZIP, desbloquea los archivos.** Windows marca lo que viene de internet y puede mostrar el aviso de SmartScreen al abrir `limpiar.bat`. En PowerShell, dentro de la carpeta:
   ```powershell
   Get-ChildItem -Recurse | Unblock-File
   ```
3. **Correo (opcional)**: crea `correo.json` a partir de la plantilla y llena tus datos (ver "Correo con el resumen"):
   ```powershell
   Copy-Item correo.ejemplo.json correo.json
   notepad correo.json
   ```
   | Campo | Que poner |
   |---|---|
   | `activo` | `true` para enviar y `false` para no enviar (la configuracion se guarda) |
   | `apiKey` | Tu API key de Resend: en [resend.com](https://resend.com), *API Keys* > *Create API Key*, con permiso *Sending access*. Empieza con `re_` |
   | `de` | Deja `Limpieza Windows <onboarding@resend.dev>` si no tienes un dominio verificado en Resend |
   | `para` | Con el remitente `onboarding@resend.dev`, solo el correo con el que creaste la cuenta de Resend |

   Puedes usar el mismo `correo.json` en varios equipos: el asunto lleva el nombre de cada equipo.
4. **Acceso directo (opcional)**: doble clic en `crear-acceso-directo.bat`. Crea en el Escritorio `Limpieza Windows` con el icono de la escoba.
5. **Primera ejecucion**: doble clic en `limpiar.bat` (o en el acceso directo). Para la primera, conviene responder N a la reparacion (tarda) y revisar el resumen y `limpieza.log` al terminar.

### Que se copia de un equipo a otro

| Archivo | Se copia? | Por que |
|---|---|---|
| Los archivos del repositorio | Si | Son el script |
| `correo.json` | Si, si quieres el correo | Sirve igual en cualquier equipo. **Tiene la API key**: copialo solo a tus equipos y nunca lo subas a ningun sitio |
| `historial.csv` | No | Es el historial de **ese** equipo: copiado, la tendencia del espacio y la "limpieza anterior" del resumen serian de otro disco |
| `limpieza.log` | No | Es la ultima ejecucion de ese equipo |
| `Limpieza Windows.lnk` | No | Guarda la ruta de la carpeta en el otro equipo: vuelve a crearlo con el paso 4 |

## Como usarlo

1. Doble clic en `limpiar.bat`. Opcional: doble clic una vez en `crear-acceso-directo.bat` para tener en el Escritorio un acceso directo con el icono.
2. Acepta la ventana de permisos de administrador. Si la rechazas, no se limpia nada.
3. Responde las preguntas del inicio.
4. Espera a que aparezca el resumen y presiona **Enter** para cerrar. Ninguna otra tecla cierra la ventana, y las teclas presionadas durante la ejecucion se descartan.

Despues de las preguntas, la seleccion con el mouse queda desactivada hasta el final. En la consola de Windows, un clic en la ventana la pone en modo "Seleccionar" y detiene la limpieza hasta presionar Enter o Esc. Al terminar se vuelve a activar, para poder copiar el resumen.

## Preguntas (todas al inicio)

Al abrirse, el script muestra un encabezado (equipo y fecha) y luego las preguntas, cada una en su tarjeta numerada (`[1/6]`, `[2/6]`...) con una explicacion corta debajo. Solo aparecen las que aplican en ese momento. Despues de responderlas el script corre solo, sin pedir nada mas.

Se responde con `S`/`si` o `N`/`no` (mayusculas o minusculas). **Enter sin escribir nada no vale**: hay que elegir. Con `T` (o `todas`) se responde **si a esa y a todas las que faltan**: las tarjetas siguientes se muestran igual, ya marcadas con `-> SI (todas)`, sin preguntar. Escribirla en la primera marca todo con S. Cualquier otra respuesta se vuelve a preguntar. Debajo de cada pregunta queda la respuesta (`-> SI` / `-> NO`), tambien en el log.

- **Vaciar lo viejo de la papelera de reciclaje** (solo si lo que borraste hace mas de 30 dias ocupa mas de 50 MB). Muestra cuantos elementos son, cuanto ocupan y los 5 mas grandes con la fecha en que los borraste. Lo de los ultimos 30 dias se conserva. Despues ya no se pueden recuperar.
- **Cerrar el navegador** (solo si hay uno abierto) para limpiar su cache. Se cierra recien al llegar al paso 4.
- **Cerrar Teams, Discord o Slack** (solo si esta abierto y su cache pasa de 50 MB) para limpiar su cache. Se cierra al llegar al paso 4 y no se vuelve a abrir solo; si estas en una llamada, responde N.
- **Borrar la cache de NuGet (.NET)** (solo si ocupa mas de 50 MB). Muestra cuanto ocupa; la proxima compilacion de un proyecto .NET volvera a descargar sus paquetes.
- **Borrar navegadores de Playwright sin usar** (solo si ocupan mas de 50 MB). Son los navegadores de prueba que ya no usa ningun proyecto con Playwright: lo mismo que borra Playwright al instalar otra version. Muestra cada uno con su tamano; si un proyecto los vuelve a necesitar, se descargan con `npx playwright install`.
- **Vaciar los logs de PM2 (Node.js)** (solo si ocupan mas de 50 MB). Muestra cuanto ocupan; se pierde el historial de salida y errores de las apps, que siguen corriendo.
- **Limpieza profunda (DISM).** Tarda 5-15 min. Borra versiones viejas de componentes de Windows Update: despues no se pueden desinstalar las actualizaciones ya instaladas.
- **Borrar los restos de la ultima actualizacion grande de Windows** (`Windows.old`, `$WINDOWS.~BT`, `$WINDOWS.~WS`; solo si existen, ocupan mas de 100 MB y ninguno se modifico en los ultimos 10 dias). Muestra cada carpeta con su tamano. Despues ya no se puede volver a la version anterior de Windows.
- **Revisar y reparar Windows (SFC + DISM).** Tarda 10-60 min (en las ejecuciones reales, entre 27 y 52 min; en un equipo con el disco lento, mas de 3 horas) y crea un punto de restauracion antes.
- **Borrar imagenes de Docker sin usar** (solo si Docker esta abierto y hay alguna). Muestra la lista exacta con el tamano de cada una; se borran solo esas.
- **Actualizar los paquetes de Linux en WSL (apt)** (solo si hay alguna distribucion WSL con `apt`, como Ubuntu o Debian; nunca las de Docker). Muestra que distribuciones; necesita internet. Para saber si una distro usa `apt` el script la enciende unos segundos al inicio.
- **Compactar los discos virtuales de Docker/WSL** (solo si existen). Apaga Docker y WSL mientras tanto (los contenedores en marcha se detienen).
- **Actualizar las aplicaciones desactualizadas (winget).** Algunas apps pueden cerrarse mientras se actualizan.

## Pasos

### Limpieza

1. **Temporales del usuario** (`%TEMP%`): solo lo que no se modifico en las ultimas 24 h. Y, si respondiste S, **lo viejo de la papelera de reciclaje**: solo lo que borraste hace mas de 30 dias (lo mismo que hace el Sensor de almacenamiento de Windows), en todas las unidades, y solo de tu cuenta (la papelera de otra cuenta del equipo no se toca). La fecha es la del borrado, no la del archivo. Las fichas de la papelera que ya no tienen su archivo (el Explorador no las muestra) se quitan sin preguntar: no liberan ni pierden nada
2. **Temporales de Windows** (`C:\Windows\Temp`): igual, solo lo de mas de 24 h

   En las carpetas temporales hay archivos de programas que estan trabajando en ese momento (instaladores, Docker, etc.) y que no siempre estan bloqueados; borrarlos puede romper esos programas. Por eso se conserva lo reciente, igual que hace la Liberacion de espacio de Windows. Una carpeta se conserva si cualquier archivo dentro de ella es reciente.
3. **Cache de Windows Update**: detiene sus servicios, borra y los vuelve a iniciar. El log dice si cada servicio quedo en marcha (si alguno no, Windows lo inicia solo cuando lo necesita)
4. **Cache de navegadores** (Chrome, Edge, Brave, Firefox), **de VS Code y de apps de chat** (Teams, Teams clasico, Discord, Slack): solo cache (carpetas `Cache`, `Code Cache` y `GPUCache`). No toca historial, cookies, contrasenas, sesiones ni mensajes. VS Code no se cierra nunca (podria haber archivos sin guardar): si esta abierto, su cache se salta. Con VS Code cerrado tambien se borran las versiones viejas de extensiones que VS Code ya marco para borrar (`.obsolete`; VS Code las borra al volver a abrirse, y si queda abierto dias se acumulan). Las apps de chat abiertas tambien se saltan, salvo que respondieras S a cerrarlas
5. **Cache de shaders de la GPU** (NVIDIA, DirectX, AMD)
6. **Cache de paquetes de desarrollo y logs de PM2**: siempre pip, npm, Yarn 1, pnpm (`pnpm store prune`: solo los paquetes que ya no usa ningun proyecto) y la cache de compilacion de Go (`go clean -cache`). Si estan instalados en Windows, tambien Composer (`composer clear-cache`), uv (`uv cache prune`: solo lo que ya no se usa), Bun (`bun pm cache rm`) y conda (`conda clean --all`: indices, descargas y paquetes que no usa ningun entorno; los entornos no se tocan). uv, Bun y conda enlazan sus archivos en los proyectos, asi que lo liberado se mide por el espacio libre del disco. Gradle y Cargo no estan a proposito: ya borran solos lo que no se usa (Gradle a los 30 dias; Cargo, desde la version 1.88, a los 3 meses). Si respondiste S, los navegadores de Playwright que ningun proyecto usa (Puppeteer no: no registra que version usa cada proyecto, y borrar la equivocada lo romperia). Al final **busca, sin borrar nada**, carpetas `node_modules` de proyectos sin cambios en 90 dias dentro de tu carpeta de usuario (hasta 5 niveles, sin entrar en `AppData` ni carpetas ocultas, como maximo 90 segundos): el resumen las muestra para que decidas. La cache de Yarn 2+ no se toca (con Plug'n'Play los proyectos leen los paquetes de ahi), ni los modulos de Go. Ademas, NuGet (.NET) y los logs de PM2 (`%USERPROFILE%\.pm2\logs`, o `PM2_HOME` si esta definida) si respondiste S. Si PM2 esta en marcha sus logs se vacian con `pm2 flush` (borrarlos no liberaria nada mientras PM2 los tiene abiertos); si esta detenido se borran directamente
7. **Logs, volcados de memoria e informes de error de Windows**: logs CBS y DISM, informes de error ya enviados o en cola (`ProgramData\Microsoft\Windows\WER`) y los volcados de memoria de los pantallazos azules (`MEMORY.DMP`, `Minidump`, `LiveKernelReports`). Los volcados solo sirven para averiguar la causa de un pantallazo azul: si hubo uno en los ultimos 7 dias (o no se pudo leer el registro de eventos) se conservan
8. **Cache de Delivery Optimization**
9. **Limpieza profunda**, cada parte si respondiste S. Si el Liberador de espacio no termina en 20 minutos, se cierra y la limpieza sigue con lo demas; si una ejecucion se corta a mitad, la siguiente quita el perfil temporal que haya quedado:
   - **Restos de la ultima actualizacion grande** (`Windows.old`, `$WINDOWS.~BT`, `$WINDOWS.~WS`): los borra el Liberador de espacio de Windows (`cleanmgr /sagerun`, con un perfil de una sola vez que se quita al terminar), que es la forma que indica Microsoft. Lo liberado se mide por el espacio libre del disco. Si tienen menos de 10 dias se conservan sin preguntar (puede ser una actualizacion en curso, o una que todavia se puede deshacer)
   - **DISM**: borra versiones viejas de componentes de Windows Update. Si Windows tiene actualizaciones esperando un reinicio, DISM falla (error `0x800f0806`) y el log indica que hay que reiniciar y volver a ejecutar

### Mantenimiento

10. **Reparacion del sistema** (si respondiste S): punto de restauracion, DISM RestoreHealth y SFC
11. **Limpieza de Docker** (solo si Docker Desktop esta abierto):
    - Siempre, sin riesgo: contenedores detenidos, imagenes huerfanas, cache de compilacion y redes sin usar (`docker container/image/builder/network prune`).
    - Si respondiste S: las imagenes sin usar que se listaron en la pregunta (solo esas, por nombre).
    - **Nunca toca los volumenes**: ahi estan las bases de datos de los proyectos.
    - Lo liberado queda libre *dentro* del disco virtual de Docker; vuelve a Windows al compactar (paso 13). Por eso va antes.
12. **Paquetes de Linux en WSL** (si respondiste S), en cada distribucion con `apt`, como root y sin pedir nada. Winget (paso 16) solo ve programas de Windows: actualiza WSL en si (`Microsoft.WSL`), pero no lo que esta instalado dentro de Ubuntu (git, svn, openssl, curl...):
    - `apt-get update` y luego `apt-get upgrade`: actualiza solo los paquetes ya instalados. **No instala ni quita paquetes** (no se usa `full-upgrade` ni `autoremove`), y si modificaste un archivo de configuracion se conserva el tuyo (`--force-confold`).
    - Algunos paquetes pueden quedar "retenidos" y el resumen dice cuantos. En Ubuntu suelen ser actualizaciones escalonadas (Ubuntu las va liberando de a poco) y llegan en una proxima ejecucion. Si no, son paquetes que necesitarian instalar o quitar otros, y esos no se tocan.
    - Si otro `apt` esta trabajando en ese momento, espera hasta 2 minutos.
    - Si un repositorio solo cambio su nombre descriptivo (su *etiqueta*, por ejemplo "PPA for PHP" -> "PPA for PHP (deprecated)"), el cambio se acepta solo (`--allow-releaseinfo-change-label`): no cambia lo que se instala. Si cambia algo mas serio (origen, version, codename), `apt-get update` falla, no se actualiza nada y el motivo sale en el log, en el resumen y en el correo.
    - Al final, **aunque `apt-get update` haya fallado**, `apt-get clean` borra los paquetes `.deb` descargados. Igual que con Docker, ese espacio queda dentro del disco virtual de la distro y vuelve a Windows al compactar (paso 13); no se suma al total liberado.
    - En el log queda cada paquete con su version anterior y la nueva, y los errores de `apt`.
13. **Compactar discos virtuales de Docker y WSL** (si respondiste S): libera los bloques sin uso (`fstrim`) dentro de Ubuntu y dentro de los datos de Docker, apaga Docker y WSL, compacta cada `.vhdx` y vuelve a abrir Docker Desktop si estaba abierto. No borra nada de adentro, solo achica el archivo. Lo liberado se mide por cuanto achico cada `.vhdx` (no por el espacio libre de C:, que se mezclaria con el archivo de intercambio de WSL que Windows borra al apagarlo). Para recuperar lo que borro Docker, Docker Desktop tiene que estar abierto al empezar (sus datos solo se pueden liberar con Docker en marcha)
14. **TRIM del SSD** (despues de compactar). Si falla, el log dice por que y el resumen lo avisa (por ejemplo, Windows no lo hace mientras C: tenga una reparacion pendiente)
15. **Puntos de restauracion**: si hay mas de 2, borra los mas viejos
16. **Aplicaciones desactualizadas (winget)**: siempre las lista; si respondiste S las actualiza una por una. La lista se consulta en segundo plano desde el inicio de la limpieza (tarda 10-30 s esperando a internet), asi que al llegar a este paso ya suele estar lista; si esa consulta fallo, se repite aqui. Se saltan las que se actualizan solas: *App Installer* (actualizarlo cierra el propio winget; lo actualiza la Microsoft Store), *Microsoft Edge* (winget no puede actualizarlo; lo hace Edge Update) y *Spotify* (su instalador no funciona como administrador; se actualiza sola). Tambien se saltan *VS Code*, *Epic Games Launcher* (y *Epic Online Services*, que depende de el) y *ShareX* si estan abiertos: su instalador falla o se cancela y el script nunca cierra una app (puede haber trabajo sin guardar). Salen en el resumen como "Se actualizan solas", con el motivo. Si una actualizacion falla, el resumen dice por que en palabras (la app estaba abierta, se cancelo, no hay espacio, sin internet...) y el texto original de winget queda en el log. Las que winget nunca va a poder actualizar salen aparte, en "Winget no las puede actualizar", y no como error: una version nueva que no aplica al equipo (suele ser una version de pago, como WinZip 28 -> 29) o una app que winget instala pero sigue listando porque no compara bien sus versiones (como Google Play Games)

### Revision

17. **Revision de salud del equipo** (solo lectura, no cambia nada): consulta Windows Update (las actualizaciones pendientes y opcionales, la ultima instalada y las que fallaron; no instala nada). Esa busqueda tarda 30-60 s y se hace en segundo plano desde que termina el paso 10, mientras corren los pasos 11 a 16; empieza despues del 10 porque el paso 3 detiene el servicio de Windows Update y los pasos 9 y 10 trabajan con los componentes de Windows. Si esa consulta fallo, se repite aqui. Ademas busca dispositivos con problemas (Administrador de dispositivos), lee del registro de rendimiento de Windows cuanto tardan los arranques y que los retraso, el plan de energia, las apps que se cerraron solas, el resultado de la ultima prueba de memoria y el tamano del archivo de hibernacion, revisa el sistema de archivos de C: sin reiniciar (`Repair-Volume -Scan`; Windows corrige en el momento los errores menores que puede, como hace por su cuenta) y junta el resto de los datos de salud del resumen. El detalle (titulos de las actualizaciones, etc.) queda en el log

### Resumen final

Se muestra en pantalla antes de cerrar, queda en el log y se envia por correo. El encabezado indica el equipo, la version de Windows y la fecha. Esta separado en secciones; en las de salud cada linea lleva `[ OK ]`, `[ !! ]` (aviso), `[ i  ]` (solo informa; no cuenta como aviso) o `[ -- ]` (dato no disponible):

- **Espacio**: total liberado (en GB desde 1000 MB), espacio libre en C: antes y despues, la limpieza anterior (hace cuanto fue y cuanto libero) y cuanto se lleno el disco desde entonces, la **tendencia** (cuantos GB por mes se pierden aunque se limpie, calculada con las limpiezas de los ultimos 120 dias, cuando hay al menos 4 y 14 dias de historial, y en cuantos meses C: bajaria del 15 % libre; si el espacio libre sube, dice "no se esta llenando"), lo liberado dentro de Docker (y que imagenes se borraron), la cache de `apt` borrada en WSL y tamano de los discos virtuales compactados. Ademas:
  - Duracion: cuanto tardo la limpieza (sin contar las preguntas). Aviso si un paso que hace siempre lo mismo (2, 3, 5, 7, 8, 14, 15 y 17) tardo el triple de lo normal y al menos 2 minutos mas, comparado con las ultimas 10 ejecuciones (hacen falta 3). Los pasos que dependen de una respuesta no se comparan: pueden tardar de minutos a una hora. Si cualquier paso pasa de 1 hora, se informa (sin contar como aviso) cual fue y una pista de por que; por ejemplo, SFC tan lento suele indicar un disco lento o muy ocupado. El tiempo de cada paso queda en el log y en `historial.csv`
  - Puntos de restauracion: cuanto ocupaban antes y despues, si cambio 100 MB o mas (sube cuando la reparacion crea uno nuevo y baja cuando el paso 15 borra uno viejo). No se suma a lo liberado, pero explica por que el espacio libre puede cambiar mas, o menos, que lo liberado
  - Si el espacio libre **bajo** durante la limpieza, una nota explica por que: cuanto crecieron los puntos de restauracion (crecen mientras DISM, SFC y los instaladores cambian archivos de Windows; ese espacio vuelve cuando se reemplazan), cuantas apps se actualizaron y que Windows Update pudo descargar archivos. El tamano de los puntos antes y despues tambien queda en el log
  - `node_modules` sin usar (solo informa, desde 200 MB en total): cuanto ocupan, en cuantos proyectos y los 3 mas grandes. Se borran a mano y se recuperan con `npm install`
  - Hibernacion (`hiberfil.sys`, solo si existe): su tamano. Si pasa del 30 % de la RAM, sugiere `powercfg /h /type reduced` (lo reduce a la mitad y mantiene el Inicio rapido; el script no lo cambia)
- **Salud del equipo** (hardware):
  - Disco: estado, vida usada, temperatura y horas de uso del SSD. Aviso si la vida usada llega al 80 %, la temperatura a 80 C (un SSD NVMe trabaja normalmente a 60-75 C con carga, y se mide justo despues del TRIM) o si hay errores de lectura que el disco no pudo corregir (la senal mas clara de que esta fallando)
  - Sistema de archivos: resultado de la revision del paso 17. Si Windows ya corrigio los errores en linea, sale OK. Si queda un error menor (por ejemplo, una entrada de indice de una carpeta), sale como informacion. Si necesita una revision completa, sale como aviso. En los dos casos se repara a mano: el log deja los pasos y estan en "Reparar el disco" (Recomendaciones de uso)
  - TRIM del SSD: solo aparece si el TRIM del paso 14 fallo, como aviso y con el motivo. Si es por una reparacion pendiente del disco, vuelve a funcionar al repararlo ("Reparar el disco")
  - Espacio en C: GB libres y porcentaje (aviso por debajo del 15 %, cuando Windows y sus actualizaciones empiezan a tener problemas)
  - Bateria (solo portatiles): capacidad actual frente a la original y ciclos (aviso por debajo del 80 %)
  - Hardware (30 dias): errores de memoria RAM, CPU o disco que registra Windows (WHEA). Aviso si hay alguno grave o 10 o mas corregidos (unos pocos corregidos son normales)
  - Dispositivos: los que el Administrador de dispositivos marca con un problema (hasta 3 con su nombre y que les pasa; la lista completa en el log). Aviso si alguno no inicia, fallo o tiene el driver danado. Si solo les falta el driver, solo se informa (suele ser un componente secundario que funciona sin el). No cuentan los que deshabilitaste ni los que estan desconectados
  - Plan de energia: el que esta activo. Si es "Ahorro de energia", solo se informa (limita el procesador; en un portatil puede ser a proposito)
  - Apps que fallan: las que se cerraron solas o se colgaron 3 veces o mas en 7 dias (hasta 3). Solo se informa: suele ser problema de la app, no del equipo
  - Memoria RAM (solo si alguna vez se hizo la prueba de memoria de Windows, `mdsched`): aviso si la ultima encontro errores
  - Cuelgues (30 dias): pantallazos azules y apagados inesperados (cortes de luz, boton de encendido), segun el registro de eventos de Windows (eventos 1001 y 41); aviso si hubo alguno
- **Windows y seguridad**:
  - Windows Update: cuantas actualizaciones faltan y hace cuanto se instalo la ultima. Aviso si alguna fallo y no se volvio a instalar, o si pasaron mas de 45 dias sin instalar nada (Windows instala cada mes). Las opcionales (drivers, vistas previas) se mencionan aparte
  - Antivirus (Defender): aviso si la proteccion en tiempo real esta desactivada o sus firmas tienen mas de 7 dias. Si otro antivirus esta a cargo, aparece como no disponible
  - Seguridad: aviso si estan apagados el firewall (en alguna red), el control de cuentas (UAC) o el Arranque seguro. Tambien dice si C: esta cifrado con BitLocker (solo informa)
  - Respaldo de archivos: si Documentos y Escritorio estan en OneDrive (y OneDrive abierto) o si el Historial de archivos esta configurado. Si no, solo se informa (`[ i  ]`): no cuenta como aviso, porque puedes respaldar de otra forma
  - Punto de restauracion: el mas reciente; aviso si no hay ninguno
  - Ultimo reinicio: aviso si pasaron mas de 14 dias. Con el Inicio rapido de Windows, Apagar no cuenta: solo Reiniciar
  - Recuperacion (WinRE): si el entorno de reparacion de Windows esta activo
  - Reinicio pendiente: si Windows espera un reinicio para terminar actualizaciones
- **Programas que arrancan con Windows**: los habilitados, en dos columnas (solo informa, no desactiva nada). Ademas:
  - Tiempo de arranque: la mediana de los arranques de los ultimos 30 dias (la mediana, para que un arranque con actualizaciones no cambie la cifra) y la de los 30 a 120 dias anteriores. Aviso si empeoro un 50 % y al menos 15 segundos. Windows guarda cada arranque, asi que no depende de cuantas veces se ejecute la limpieza
  - Lo que mas retraso el arranque en 30 dias segun Windows (programas, drivers y servicios, sumados): hasta 3, si suman 2 segundos o mas; la lista completa queda en el log. No cuenta las partes de Windows (no se pueden quitar)
- **Aplicaciones**: cuales se actualizaron, cuales no se pudieron actualizar (con el motivo), cuales siguen pendientes, cuales se saltaron porque se actualizan solas y cuales winget no puede actualizar (con el motivo; solo informa). En la pantalla, si el nombre no cabe se recorta; solo si dos nombres recortados quedan iguales se muestra el identificador de winget, que es unico. Si no se pidio actualizar, la lista de las que tienen actualizacion disponible. Si winget no se pudo consultar (sin internet, no instalado), lo dice en rojo en vez de decir que todo esta al dia.
- **Paquetes de Linux (WSL)** (solo si hay distribuciones con `apt`): por cada distro, cuantos paquetes se actualizaron (con sus versiones si son 15 o menos; si son mas, la lista completa queda en el log), si esta todo al dia o si `apt` fallo (en rojo, con el motivo), y cuantos paquetes quedaron retenidos. Si no se pidio actualizar, solo lo dice.

## Correo con el resumen

Al terminar, el resumen se envia usando [Resend](https://resend.com). Tiene el mismo contenido que la pantalla, pero con diseno de correo en negro con rojo neon: una tarjeta por seccion, etiquetas de color (OK / AVISO / N/D) y nombres completos de las apps. Se adapta al ancho del celular (maximo 600 px en el computador). El asunto incluye el equipo, la fecha, lo liberado y la cantidad de avisos, por ejemplo: `Limpieza MI-PC - 08/10/2026 22:56 - 1.2 GB liberados - 1 aviso(s)`.

Es opcional. Para activarlo, crea una cuenta en Resend, copia `correo.ejemplo.json` como `correo.json` (en la misma carpeta que `limpiar.bat`) y pon tu API key y tu correo:

```json
{
  "activo": true,
  "apiKey": "re_...",
  "de": "Limpieza Windows <onboarding@resend.dev>",
  "para": "tu-correo@ejemplo.com"
}
```

- `"activo": false` desactiva el envio sin borrar la configuracion. Si `correo.json` no existe, tampoco se envia.
- Con el remitente `onboarding@resend.dev` Resend solo permite enviar al correo de la cuenta de Resend.
- Si el envio falla (sin internet, API key invalida...), la limpieza no se ve afectada: el log y la pantalla muestran el motivo.
- **`correo.json` contiene la API key**: no lo compartas ni lo subas a ningun sitio. Si se filtra, revocala en el panel de Resend y genera otra.

## Sin permisos de administrador

No se hace nada. Casi todos los pasos necesitan administrador, y una limpieza a medias dejaria el resumen y el historial incompletos. Si se rechaza el permiso, `limpiar.bat` avisa y se cierra; si `limpiar.ps1` se abre directo sin permisos, muestra un aviso y espera Enter para cerrar. En los dos casos no se toca nada: ni archivos, ni `limpieza.log` (queda el de la ejecucion anterior), ni `historial.csv`, ni se envia correo.

## Configuracion

Al inicio de `limpiar.ps1`:

```powershell
$maxPuntos = 2         # puntos de restauracion a conservar (se borran los mas viejos)
$horasTemporales = 24  # en los pasos 1 y 2 solo se borran temporales sin modificar en este tiempo
$diasVolcados = 7      # paso 7: si hubo un pantallazo azul en estos dias, se conservan los volcados de memoria
$diasRestosActualizacion = 10  # paso 9: restos de una actualizacion grande solo se ofrecen borrar pasado este tiempo
$diasPapelera = 30     # paso 1: de la papelera solo se ofrece borrar lo que lleva ahi mas de este tiempo
$diasNodeModules = 90  # paso 6: se informan los node_modules de proyectos sin cambios en este tiempo (no se borran)
```

Y el correo, en `correo.json` (ver arriba).

## Recomendaciones de uso

- **Limpieza normal** (N a DISM y reparacion): cada 2-4 semanas.
- **Reparacion** (S): solo si notas errores o cuelgues, o cada pocos meses.
- **Compactar Docker/WSL** (S): cuando no tengas contenedores haciendo algo importante; tiene sentido despues de borrar imagenes o archivos grandes dentro de Linux.
- **Paquetes de WSL** (S): cada 2-4 semanas, junto con la limpieza normal; mejor sin nada importante corriendo dentro de Linux (un servicio que se actualiza puede reiniciarse). Conviene responder S tambien a compactar, para que vuelva a Windows lo que libera `apt-get clean`.
- El paso 15 cuenta **todos** los puntos de restauracion, incluidos los creados a mano o por Windows Update.

### Reparar el disco

Si el resumen muestra "Sistema de archivos" con un error pendiente, o "TRIM del SSD" con una reparacion pendiente, hay que reparar C: **a mano**. Windows no puede reparar el disco donde esta corriendo: hay que reiniciar, y el script nunca reinicia el equipo. Mientras tanto, Windows tampoco hace el TRIM y puede mostrar "Reparando la unidad C" en cada arranque.

1. En PowerShell **como administrador**: `chkdsk C: /spotfix` (o `chkdsk C: /f` si el resumen lo indica). Cuando pregunte si quieres programarlo para el proximo reinicio, responde **S** y reinicia.
2. Si `chkdsk` responde "Acceso denegado", o la reparacion al arrancar no termina (vuelve a salir en cada arranque), hazlo desde el modo de recuperacion, que trae su propio `chkdsk`:
   1. Configuracion > Sistema > Recuperacion > Inicio avanzado > **Reiniciar ahora**.
   2. Solucionar problemas > Opciones avanzadas > **Simbolo del sistema**.
   3. `dir C:\Windows` para confirmar la letra del disco (ahi puede ser otra; si no existe, prueba con `D:`).
   4. `chkdsk C: /f` con la letra correcta. Al terminar, `exit` y **Continuar**.
3. Para comprobarlo, en PowerShell como administrador: `Repair-Volume -DriveLetter C -Scan` tiene que decir `NoErrorsFound`. En la siguiente limpieza el TRIM vuelve a funcionar.

## Lo que no hace, a proposito

- **Limpiar el registro**: no acelera nada medible y un error puede dejar programas o Windows sin arrancar. Microsoft no da soporte a sistemas danados por limpiadores de registro.
- **Desfragmentar**: en un SSD no sirve y gasta su vida util; Windows ya hace TRIM (paso 14) y desfragmenta solo los discos mecanicos cuando hace falta.
- **Desactivar servicios**: lo que se gana es minimo y puede romper cosas de forma silenciosa (actualizaciones, impresion, Bluetooth, seguridad), a veces semanas despues.
- **"Liberar RAM"**: Windows usa la RAM libre como cache a proposito; vaciarla hace que todo cargue mas lento despues.
- **Borrar `C:\Windows\Installer`**, la cache de miniaturas o instantaneas que no son puntos de restauracion: o es peligroso o libera muy poco.
- **Desactivar programas de inicio**: solo se informan en el resumen; tu decides cuales quitar.
- **Borrar `Prefetch`**: Windows lo usa para abrir rapido los programas; borrarlo hace el arranque mas lento.
- **`ipconfig /flushdns`**: no hace dano, pero tampoco mejora nada.
- **`DISM /ResetBase`**: despues no se pueden desinstalar las actualizaciones ya instaladas. La limpieza profunda (paso 9) usa solo `/StartComponentCleanup`.
- **Desactivar la telemetria, cambiar los efectos visuales, Compact OS o mover el archivo de paginacion**: cambian la configuracion de Windows por una ganancia minima o nula.
- **Borrar `node_modules` o cambiar la hibernacion**: solo se informan en el resumen. Un `node_modules` viejo puede ser de un proyecto que todavia usas sin editarlo, y la hibernacion la decides tu.
- **Vaciar la papelera entera**: lo reciente puede ser algo que borraste por error y todavia quieres recuperar. Solo se ofrece borrar lo de mas de 30 dias, y solo de tu cuenta.

## Si modificas el script

Para usar el script no hace falta nada de esta seccion. Para modificarlo, en un equipo nuevo:

```powershell
git clone https://github.com/Mub1522/limpiar.bat.git
cd limpiar.bat
git config core.hooksPath .githooks                        # una vez: verificar.ps1 corre antes de cada commit
Install-Module PSScriptAnalyzer -Scope CurrentUser         # opcional
```

| Para | Comando (en la carpeta del script; ninguno limpia nada) |
|---|---|
| Revisarlo todo (unos segundos) | `powershell -NoProfile -ExecutionPolicy Bypass -File verificar.ps1` |
| Correr solo las pruebas | `Invoke-Pester -Script tests` |
| Correr un archivo de pruebas | `Invoke-Pester -Script tests\lectura.Tests.ps1` |
| Solo las pruebas de un grupo | `Invoke-Pester -Script tests -TestName 'ConvertFrom-TablaWinget*'` |

Pester 3.4 viene con Windows. Si instalaste Pester 5, antes de `Invoke-Pester` carga la version vieja con `Import-Module Pester -MaximumVersion 4.99` (las pruebas usan la sintaxis de Pester 3; `verificar.ps1` ya lo hace solo).

| Revision | Que comprueba |
|---|---|
| Sintaxis | Que `limpiar.ps1`, `lib\`, `tests\` y los demas `.ps1` se puedan leer (sin ejecutarlos). |
| Solo ASCII | Que ningun `.ps1` tenga tildes ni simbolos: Windows PowerShell 5.1 los desfigura. |
| Pruebas | Con Pester 3.4, que viene con Windows. La lectura de las salidas de winget, apt, Docker y `reagentc`, de las fichas de la papelera, de la lista de dispositivos, de los eventos de arranque (tiempo y retrasos), del plan de energia, de las apps que fallan, de la prueba de memoria, de `.obsolete` de VS Code y de `browsers.json` de Playwright; la medicion de las caches que se limpian con un comando; la busqueda de `node_modules` viejos y de navegadores de Playwright sin usar (en carpetas de prueba); la duracion de los pasos y la deteccion de pasos lentos; el borrado de carpetas y de la papelera (que conserve lo reciente), siempre dentro de una carpeta temporal de prueba; las consultas en segundo plano (que no esperen para siempre); el historial y la tendencia del espacio; el resumen (consola y correo a la vez, y que solo los avisos cuenten); que el codigo no use nada de "Lo que no hace, a proposito"; y que sin permisos de administrador el script se cierre antes de hacer nada. |
| PSScriptAnalyzer | Solo si esta instalado (`Install-Module PSScriptAnalyzer -Scope CurrentUser`). Es opcional. |

Termina con codigo 1 si algo falla. Para que se ejecute solo antes de cada commit, activa el hook una vez en cada equipo con `git config core.hooksPath .githooks`.

## Historial de cambios

- **2026-11-28** - El resumen muestra cuanto ocupaban los puntos de restauracion antes y despues de la limpieza, si cambio 100 MB o mas. Ese dia se liberaron 4,4 GB pero el espacio libre subio 6,6 GB, por un punto viejo que borro el paso 15, y el dato solo estaba en el log.
- **2026-11-27** - Tras la primera ejecucion en otro equipo:
  - Paso 16: el motivo de una actualizacion fallida sale en palabras (la app estaba abierta, cancelado...) en vez de la ruta del log de winget. Las que winget nunca va a poder actualizar (una version de pago, o una que sigue listando aunque la instale) salen en "Winget no las puede actualizar", sin contar como error. Epic Games y ShareX se saltan si estan abiertos, igual que VS Code. Un instalador que pide reiniciar para terminar cuenta como actualizado.
  - Resumen: si el espacio libre baja, una nota explica por que (los puntos de restauracion crecen mientras se repara Windows; ese dia, 5,5 GB menos sin explicacion). Si un paso pasa de 1 hora, se informa cual (ese dia, SFC tardo 3 h 20 min). La tabla de apps ya no mezcla nombres e identificadores.
  - La pregunta de SFC avisa que en un disco lento puede tardar varias horas.
- **2026-11-27** - Ya no sale el error rojo "Get-ChildItem : The system cannot find the file specified" al medir carpetas (se vio en el paso 1). Pasaba cuando un programa borraba una carpeta temporal justo mientras el script la recorria; ahora esa carpeta simplemente se salta. En un Windows en ingles, el log del paso 14 (TRIM) ya no se llena con unas 40 lineas de progreso ("Retrim: NN% complete..."). La limpieza no cambia.
- **2026-11-27** - Tras revisar la primera ejecucion con las mejoras nuevas: las fichas de la papelera sin su archivo (de mas de 30 dias) se quitan sin preguntar, en vez de aparecer en el log de cada ejecucion sin llegar nunca a la pregunta. En "Lo que mas retraso el arranque", el tipo (programa, driver o servicio) pasa al final de la linea, para que los nombres largos no descuadren el resumen.
- **2026-11-27** - "Lo que no hace" suma los "trucos" populares que no ayudan o hacen dano (borrar `Prefetch`, `flushdns`, `DISM /ResetBase`, telemetria, efectos visuales, Compact OS, archivo de paginacion), y las pruebas automaticas fallan si alguno aparece en el codigo, igual que con limpiar el registro o liberar RAM. El script no cambia.
- **2026-11-27** - Mas limpieza para desarrollo y mas datos en el resumen:
  - Paso 4: versiones viejas de extensiones de VS Code que el propio VS Code marco para borrar (con VS Code cerrado).
  - Paso 6: pregunta para borrar los navegadores de Playwright que ya no usa ningun proyecto; y busqueda (solo informa) de `node_modules` de proyectos sin cambios en 90 dias.
  - Resumen: duracion de la limpieza con aviso si un paso tarda el triple de lo normal (el tiempo de cada paso se guarda en `historial.csv`, que suma dos columnas; un historial anterior sigue funcionando), tamano de `hiberfil.sys`, plan de energia, apps que se cerraron solas y resultado de la ultima prueba de memoria.
  - No se agregan: Puppeteer (no se sabe que version usa cada proyecto) ni `wsl --update` (winget ya actualiza WSL en el paso 16). El aviso de poco espacio y el de desgaste o temperatura del SSD ya existian.
- **2026-11-27** - Arranque y mas caches de desarrollo:
  - Resumen: en "Programas que arrancan con Windows", el tiempo de arranque (mediana de 30 dias comparada con los meses anteriores; aviso si empeoro mucho) y lo que mas lo retraso segun Windows. Sale del registro de rendimiento de Windows, que guarda cada arranque.
  - Paso 6: caches de Composer, uv, Bun y conda, cada una con su comando oficial y solo si la herramienta esta instalada. Gradle y Cargo no se agregan: ya se limpian solos.
- **2026-11-27** - Mas rapido, papelera y dispositivos:
  - Las consultas que solo esperan a internet corren en segundo plano mientras se hacen otros pasos: la lista de winget (paso 16) desde el inicio y la busqueda de Windows Update (paso 17) desde el paso 10. Ahorran alrededor de un minuto. Si una falla o tarda mas de 5 minutos, se repite como antes.
  - Paso 1: nueva pregunta para vaciar lo que lleva mas de 30 dias en la papelera de reciclaje (solo si pasa de 50 MB), con la lista de lo mas grande. Si una ficha de la papelera ya no tiene su archivo (el Explorador no la muestra), cuenta 0 MB y se quita igual.
  - Salud del equipo: nueva linea "Dispositivos" con los que el Administrador de dispositivos marca con un problema.
- **2026-11-27** - Un clic en la ventana ya no detiene la limpieza: mientras corre se desactiva la seleccion con el mouse (edicion rapida de la consola) y al final se vuelve a activar. En una ejecucion real, la limpieza quedo 10 minutos parada en el paso 17 hasta que se presiono Enter.
- **2026-11-26** - Nueva seccion "Reparar el disco" (en Recomendaciones de uso): que hacer cuando el resumen muestra un error del sistema de archivos o el TRIM bloqueado, incluido el modo de recuperacion cuando `chkdsk` no funciona dentro de Windows. El resumen remite a esa seccion y el log deja los pasos.
- **2026-11-26** - Tras la primera ejecucion real de esta version: el paso 16 ya no intenta actualizar VS Code si esta abierto (su instalador se cancelaba y el resumen mostraba como motivo la ruta de un log); ahora sale en "Se actualizan solas" con el motivo. El paso 10 muestra la fecha del punto de restauracion como dia/mes.
- **2026-11-26** - Sin permisos de administrador el script ya no hace una limpieza a medias: avisa y se cierra sin tocar nada (ni el log, ni el historial, ni el correo). Por eso ya no hay casos con una sola pregunta.
- **2026-11-26** - Las preguntas del inicio aceptan `T` (o `todas`): si a esa pregunta y a todas las que faltan. Las demas tarjetas se siguen mostrando (y quedan en el log) con `-> SI (todas)`. Enter sin escribir nada ya no cuenta como No: se vuelve a preguntar.
- **2026-11-26** - `.vscode\settings.json` pasa a subirse al repositorio: VS Code se ve en negro con rojo neon (los colores del correo) en cualquier equipo. El script no cambia
- **2026-11-26** - Nuevo `crear-acceso-directo.bat`: el acceso directo ahora se crea con doble clic (antes, `crear-acceso-directo.ps1` con *Ejecutar con PowerShell* a veces fallaba por la politica de ejecucion de scripts). `limpiar.bat` sigue sin icono propio en el Explorador: Windows no lo permite en un `.bat`, por eso el icono va en el acceso directo
- **2026-11-26** - Nueva carpeta `memory-global\` con las notas y reglas de Claude Code que valen en cualquier equipo, para que esten iguales en todos. Lo de cada equipo queda fuera del repositorio. El script no cambia
- **2026-11-26** - README: nueva seccion "Instalacion en otro equipo" (que ocupa, pasos para descargarlo y desbloquearlo, como llenar `correo.json` con la API key de Resend y que archivos se copian o no entre equipos) y comandos para correr las pruebas en "Si modificas el script". El script no cambia
- **2026-11-26** - Pruebas automaticas: nuevo `verificar.ps1`, que revisa la sintaxis, que los `.ps1` sean solo ASCII y corre las pruebas de `tests\` (Pester), mas un hook de git que lo ejecuta antes de cada commit. La lectura de la tabla de winget (paso 16) y de la simulacion de apt (paso 12) quedo en funciones aparte (`ConvertFrom-TablaWinget` y `ConvertFrom-SimulacionApt`) para poder probarla con salidas de ejemplo. El script hace exactamente lo mismo que antes

- **2026-11-26** - Tras la primera ejecucion del paso 12: al medir la cache de apt, el script cortaba `wsl.exe` antes de que terminara, y desde ahi el texto de la consola salia en escalera (cada linea empezaba donde acababa la anterior). El log no se afectaba. Ahora se lee la salida completa antes de usarla
- **2026-11-26** - Nuevo paso 12 (opcional, con pregunta): actualiza los paquetes de Linux de las distribuciones WSL con `apt` (`apt-get update` + `upgrade`, sin instalar ni quitar paquetes y conservando la configuracion) y borra los paquetes descargados (`apt-get clean`, aunque el update falle). Antes nada dentro de WSL se actualizaba: winget actualiza WSL, pero no lo que esta instalado dentro de Ubuntu. Los cambios de etiqueta de un repositorio se aceptan solos (en la primera prueba, el PPA de PHP paso a "deprecated" y `apt-get update` fallaba por eso). Nueva seccion "Paquetes de Linux (WSL)" en el resumen. Los pasos siguientes pasan a ser 13 (compactar), 14 (TRIM), 15 (puntos de restauracion), 16 (winget) y 17 (revision de salud).

- **2026-11-25** - Tras revisar la segunda ejecucion del dia: la limpieza profunda ya no le pide al Liberador de espacio los drivers ya reemplazados (en tres ejecuciones libero 0 MB y tardo mas de una hora, 9 minutos y 20 minutos). Paso 13: si el TRIM falla, el log muestra el motivo (antes salia el error de PowerShell repetido y despues "TRIM terminado") y el resumen agrega la linea "TRIM del SSD" como aviso. Paso 8: la cache de Delivery Optimization se vacia en un proceso aparte, para que el log no muestre "Deleting..." sin hora (redirigir la salida no alcanzaba).
- **2026-11-25** - Correcciones tras la primera ejecucion completa con los pasos nuevos: la tendencia del espacio se calcula con todas las limpiezas de los ultimos 120 dias (recta de minimos cuadrados) en vez de compararse con una sola, y si el espacio libre sube dice "no se esta llenando" (antes decia "ganas 24,6 GB al mes" por archivos borrados a mano). "Sistema de archivos" explica el resultado en espanol: si los errores ya se corrigieron en linea, sale OK; un error menor que solo necesita `chkdsk C: /spotfix` pasa a ser informativo (`[ i  ]`) y el log muestra que carpeta afecta; lo que necesita una revision completa sigue como aviso (`chkdsk C: /f`). El log muestra las fechas de los puntos de restauracion como dia/mes y parte el informe del TRIM en lineas. "hace 1 horas" pasa a "hace 1 hora".
- **2026-11-25** - Correcciones tras la primera ejecucion con los pasos nuevos (24/11): el Liberador de espacio (drivers ya reemplazados, paso 9) paso mas de una hora sin terminar y la ejecucion quedo trabada hasta que se apago el equipo. Ahora tiene un tiempo maximo de 20 minutos y se espera solo a su proceso; si una ejecucion se corta, la siguiente quita el perfil temporal que haya quedado. Paso 3: ya no aparece "ADVERTENCIA: Esperando a que se inicie el servicio BITS" (era normal: BITS tarda unos segundos en arrancar); en su lugar el log dice si cada servicio quedo en marcha. Paso 6: pnpm se ejecuta por `pnpm.cmd`, sin el error rojo ni las lineas repetidas en el log. "Respaldo de archivos" pasa a ser solo informativo (`[ i  ]`, nuevo nivel que no cuenta como aviso).
- **2026-11-24** - Salud y mantenimiento: nuevo paso 16 (revision de solo lectura) con Windows Update (pendientes, ultima instalada y fallidas), revision del sistema de archivos sin reiniciar, errores de hardware (WHEA), chequeo de seguridad (firewall, UAC, Arranque seguro, BitLocker), respaldo de archivos (OneDrive o Historial de archivos) y punto de restauracion mas reciente. El disco suma horas de uso y errores de lectura sin corregir. El resumen separa "Salud del equipo" (hardware) de "Windows y seguridad", muestra la version de Windows en el encabezado y la tendencia del espacio (GB por mes y cuando C: bajaria del 15 %). La limpieza profunda tambien quita los paquetes de drivers ya reemplazados (Liberador de espacio). Los datos de salud pasan a `lib\salud.ps1`. WSL no se agrega aparte: winget ya lo actualiza en el paso 15 (`Microsoft.WSL`).
- **2026-11-24** - Nuevas limpiezas y revisiones de salud, tras investigar que mas se puede hacer de forma segura: paso 4, cache de Teams, Discord y Slack (con pregunta para cerrarlos si estan abiertos y su cache pasa de 50 MB); paso 6, Yarn 1, `pnpm store prune` y `go clean -cache`; paso 7, volcados de memoria (se conservan si hubo un pantallazo azul en los ultimos 7 dias) e informes de error de Windows; paso 9, restos de la ultima actualizacion grande (`Windows.old`, `$WINDOWS.~BT`, `$WINDOWS.~WS`) con pregunta y con el Liberador de espacio de Windows. En Salud del equipo: cuelgues de los ultimos 30 dias, estado del antivirus y dias desde el ultimo reinicio. Nueva seccion "Lo que no hace, a proposito".
- **2026-11-24** - Nuevo estilo negro con rojo neon: el correo del resumen pasa a fondo negro con titulos y bordes en rojo neon (el brillo solo se ve en clientes que lo soportan, como Apple Mail; en Gmail queda el rojo plano) y se marca como oscuro para que el modo oscuro del celular no invierta los colores. Las etiquetas OK / AVISO siguen en verde / amarillo. Nuevo `limpiar.ico` con el mismo estilo; si el acceso directo sigue mostrando el icono anterior, vuelve a ejecutar `crear-acceso-directo.ps1`.

- **2026-11-24** - Correcciones tras revisar una ejecucion en otro equipo: el log del historial no mostraba la cantidad de ejecuciones en la primera (`( registrada(s)`); "Liberado por la limpieza" se muestra en GB desde 1000 MB (`15.823,82 MB` se leia como 15 MB); una app que winget dice instalar pero sigue listando ya no aparece a la vez en "Actualizadas" y "Siguen pendientes"; el paso 9 explica el error `0x800f0806` (reiniciar y volver a ejecutar); la pregunta de reparacion estima 10-60 minutos (una ejecucion tardo 52).
- **2026-11-20** - Paso 6: logs de PM2 (Node.js) con pregunta al inicio, solo si ocupan mas de 50 MB. Con PM2 en marcha se vacian con `pm2 flush`; con PM2 detenido se borran.
- **2026-11-17** - Paso 12: lo liberado al compactar se mide por cuanto achico cada `.vhdx`. Antes se media por el espacio libre de C:, y el archivo de intercambio de WSL que Windows borra al apagarlo se contaba como compactacion (en la ejecucion del 17/11 sumo ~1.2 GB de mas). Paso 15: Spotify se salta como app que se actualiza sola (winget siempre fallaba con "The installer cannot be run from an administrator context").
- **2026-11-17** - Icono: nuevo `limpiar.ico` y `crear-acceso-directo.ps1`, que crea en el Escritorio un acceso directo a `limpiar.bat` con ese icono.
- **2026-11-17** - Preparado para repositorio publico: `.gitignore` (correo.json, log, historial y accesos directos no se suben), plantilla `correo.ejemplo.json`, licencia MIT y seccion de requisitos.
- **2026-10-09** - Historial de ejecuciones (`historial.csv`) y comparacion con la limpieza anterior en el resumen. Aviso en Salud del equipo si C: baja del 15 % libre. Cache de NuGet (.NET) con pregunta en el paso 6. Cache de VS Code en el paso 4 (se salta si VS Code esta abierto). Los tamanos de 1000 MB o mas se muestran en GB.
- **2026-10-09** - La pregunta de reparacion del sistema ahora estima 10-40 minutos (antes 10-20; en las ejecuciones reales tardo 27 y 41 minutos).
- **2026-10-09** - Paso 12: ahora tambien se ejecuta `fstrim` dentro de los datos de Docker antes de compactar. Antes se saltaba, y lo que borraba Docker (1.3 GB de imagenes en la primera prueba) no volvia a Windows: el disco de Docker usaba 4.6 GB por dentro pero el archivo seguia pesando 8 GB.
- **2026-10-09** - Nuevo paso 11: limpieza de Docker (contenedores detenidos, imagenes huerfanas, cache de compilacion y redes sin usar siempre; imagenes sin usar con pregunta que muestra la lista exacta; los volumenes nunca se tocan). Va antes de compactar para que lo liberado vuelva a Windows. Los pasos siguientes pasan a ser 12 (compactar), 13 (TRIM), 14 (puntos de restauracion) y 15 (winget). Inicio redisenado: encabezado y preguntas en tarjetas numeradas con explicacion y la respuesta debajo.
- **2026-10-09** - Revision de errores posibles:
  - Pasos 1 y 2: ya no se borran temporales modificados en las ultimas 24 h. Antes se podian borrar archivos de programas trabajando en ese momento.
  - Paso 14 y resumen: si winget falla o no esta instalado se avisa, en vez de decir "todas las aplicaciones estan al dia". Ya no se recomienda responder S si ya se respondio S y solo quedaban apps que se actualizan solas. Una app que se instala pero pide reiniciar ya no cuenta como error. La lectura de la tabla de winget ya no se corta con filas incompletas ni con apps cuyo nombre empieza con un numero.
  - Paso 10: el mensaje "ya hay un punto de las ultimas 24 h" solo aparece si es cierto.
  - Casos raros que podian cortar el script: una distribucion de WSL registrada sin carpeta, o la ventana cerrada mientras hacia una pregunta.
- **2026-10-09** - Corregido el resumen en el log: cada linea quedaba partida en pedazos (en la ventana se veia bien). Ahora cada linea del resumen va de un solo color. El aviso de temperatura del SSD pasa de 70 C a 80 C (con 70 C saltaria en un uso normal). Quitada una linea vacia que dejaba `wsl --shutdown`.
- **2026-10-09** - Correo redisenado para el celular: antes era texto de ancho fijo que se veia diminuto o cortado; ahora usa tarjetas y filas que se adaptan a la pantalla. Microsoft Edge se salta en el paso 14 (winget siempre fallaba con el; se actualiza solo) y el resumen muestra aparte las apps que se actualizan solas.
- **2026-10-08** - Nuevos pasos 11 (compactar discos virtuales de Docker/WSL) y 14 (aplicaciones desactualizadas con winget); el TRIM pasa a ser el 12 y los puntos de restauracion el 13. Resumen final redisenado por secciones, con salud del equipo (SSD, bateria, WinRE, reinicio pendiente) y resultado de las actualizaciones. Envio del resumen por correo con Resend. El resumen y el correo pasan a `lib\` para que `limpiar.ps1` no crezca.
- **2026-10-08** - Paso 8: lo liberado se mide por el espacio libre del disco. Antes sumaba el tamano aparente de los archivos y mostraba ~4.4 GB que en realidad no se liberaban.
- **2026-10-08** - Las preguntas aceptan S/si/N/no, Enter = No y repiten si la respuesta no es valida. La ventana solo se cierra con Enter (antes cualquier tecla, incluso Alt+Tab o teclas presionadas durante la ejecucion, la cerraba). Menos ruido del TRIM en el log.
- **2026-10-08** - Resumen final en pantalla (espacio, disco y programas de inicio) para verlo sin abrir el log. Agregado el paso de puntos de restauracion (maximo 2).
- **2026-10-08** - Pasos de reparacion (SFC + DISM) y TRIM, y reporte de programas de inicio. Corregido un error al calcular mas de 2 GB y reducido el progreso de DISM/SFC en el log (cada 10 %).
- **2026-10-07** - Pasos 5-9 (shaders, pip/npm, logs de Windows, Delivery Optimization, DISM opcional). Todas las preguntas pasan al inicio.
- **2026-10-07** - Pasos 1-4 (temporales, Windows Update, navegadores). El `.bat` pide permisos de administrador. Un solo archivo de log.
