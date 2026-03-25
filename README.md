# wlog

Wrapper para monitoreo y logging de ejecución de scripts

Versión: 2.1.1  
Autor: JAAP <jalvarez.powell@gmail.com>  
Licencia: GPL v3

## Descripción

`wlog` permite ejecutar cualquier script o programa, registrando automáticamente información sobre su ejecución, incluyendo:

- Tiempo de inicio y duración
- Resultado y código de salida
- Comando y argumentos utilizados
- Errores generados
- Opcionalmente, la salida estándar (stdout)
- **Monitoreo de subprocesos directos** (nuevo en v2.1.0)

Toda la información se almacena en formato JSON en `/var/log/script_monitor.log`, permitiendo un monitoreo detallado y análisis posterior de las ejecuciones.

## Características principales

- Genera un ID de transacción único para cada ejecución
- Detecta automáticamente el origen de la ejecución (shell, cron, systemd)
- Maneja correctamente las interrupciones (como Ctrl+C)
- Captura los argumentos pasados al script y el comando completo
- **Monitoreo en tiempo real de subprocesos directos** (primer nivel)
- **Registro detallado de cada subproceso** con PID, comando y estado del proceso
- **Modo de depuración** para diagnóstico avanzado

## Instalación

### A partir del paquete RPM

```bash
# Instalar el paquete RPM
sudo rpm -ivh wlog-2.1.1-1.el8.noarch.rpm

# Verificar la instalación
which wlog
man wlog
```

## Uso básico

```bash
# Ejecutar un script sin capturar stdout
wlog mi_script.sh

# Ejecutar un script capturando stdout
wlog --stdout mi_script.sh arg1 arg2

# Ejecutar un script monitoreando subprocesos
wlog --follow mi_script.sh

# Ejecutar con todas las opciones y depuración
wlog -s -f -d python3 script.py --verbose
```

## Documentación

Para obtener ayuda detallada:

```bash
# Ver la página del manual
man wlog

# Ver la ayuda incorporada
wlog --help
```

## Opciones disponibles

| Opción | Descripción |
|--------|-------------|
| `-s, --stdout` | Capturar la salida estándar (stdout) |
| `-n, --no-stdout` | No capturar la salida estándar (por defecto) |
| `-f, --follow` | **Monitorear subprocesos directos** (primer nivel) |
| `-d, --debug` | **Habilitar modo de depuración** (logs en `/tmp/wlog_debug.log`) |
| `-h, --help` | Mostrar esta ayuda |

## Formato de logs

### Registro de inicio:
```json
{
  "timestamp":"2025-06-04 14:53:33",
  "type":"start",
  "txid":"I3lN4v",
  "host":"localhost.localdomain",
  "script":"deploy.sh",
  "args":"production --verbose",
  "command":"deploy.sh production --verbose",
  "user":"root",
  "origin":"shell",
  "capture_stdout":true,
  "follow_subprocesses":true
}
```

### Registro de subproceso detectado (con -f):
```json
{
  "timestamp":"2025-06-04 14:53:35",
  "type":"subprocess_detected",
  "txid":"I3lN4v",
  "pid":12345,
  "parent_pid":12340,
  "pgid":12340,
  "command":"rsync -avz /app/ server:/app/",
  "state":"R",
  "cpu":0.0,
  "mem":0.0
}
```

*Nota: Los campos `cpu` y `mem` están presentes por compatibilidad, pero típicamente mostrarán 0.0 ya que los subprocesos se detectan inmediatamente después de ser creados.*

### Registro de finalización:
```json
{
  "timestamp":"2025-06-04 14:53:47",
  "type":"end",
  "txid":"I3lN4v",
  "result":"OK",
  "exit_code":0,
  "time":14.125431892,
  "stdout":"Deployment completed successfully",
  "stderr":"",
  "has_subprocesses":true,
  "subprocess_count":3,
  "subprocess_pids":"12345,12350,12355"
}
```

## Casos de uso avanzados

### Monitoreo de scripts de despliegue

```bash
# Monitorear un script de despliegue que lanza múltiples procesos
wlog -f -s ./deploy.sh production

# Los subprocesos como rsync, ssh, docker build serán registrados automáticamente
# permitiendo ver exactamente qué comandos se ejecutaron y cuándo
```

### Análisis de ejecución de scripts complejos

```bash
# Script que lanza múltiples tareas en paralelo
wlog -f -d ./parallel_tasks.sh

# Revisar logs de depuración
tail -f /tmp/wlog_debug.log

# Analizar qué subprocesos se ejecutaron
jq '.type == "subprocess_detected"' /var/log/script_monitor.log
```

### Depuración de scripts problemáticos

```bash
# Ejecutar con depuración completa
wlog -f -d -s problematic_script.sh

# Ver el flujo de ejecución en tiempo real
tail -f /tmp/wlog_debug.log
```

## Tips y mejores prácticas

### Configuración para cron

Para que `wlog` detecte correctamente que la ejecución viene de cron, añade esta variable de entorno en la parte superior de tu archivo crontab:

```
CRON_ENV=true
```

Ejemplo de crontab con monitoreo de subprocesos:
```
CRON_ENV=true
# m h dom mon dow command
0 2 * * * wlog -f /scripts/backup.sh
*/15 * * * * wlog -f /scripts/sync_data.sh
```

### Monitoreo de scripts periódicos

Para scripts que se ejecutan periódicamente, puedes usar `jq` para analizar los logs:

```bash
# Obtener todos los errores del último día
cat /var/log/script_monitor.log | jq -r 'select(.type == "end" and .result != "OK" and (.timestamp | fromdate) > now - 86400)'

# Calcular el tiempo promedio de ejecución de un script específico
cat /var/log/script_monitor.log | jq -r 'select(.command | startswith("backup.sh") and .type == "end") | .time' | awk '{sum+=$1} END {print sum/NR}'

# Analizar comandos de subprocesos más frecuentes
cat /var/log/script_monitor.log | jq -r 'select(.type == "subprocess_detected") | .command' | sort | uniq -c | sort -nr

# Scripts que más subprocesos generan
cat /var/log/script_monitor.log | jq -r 'select(.type == "end" and .has_subprocesses == true) | [.script, .subprocess_count] | @tsv' | sort -k2 -nr

# Ver estados de procesos detectados
cat /var/log/script_monitor.log | jq -r 'select(.type == "subprocess_detected") | .state' | sort | uniq -c
```
```

### Limpieza y rotación de logs

Se recomienda configurar logrotate para evitar que el archivo de log crezca indefinidamente:

```
/var/log/script_monitor.log {
    missingok
    notifempty
    compress
    size 100M
    weekly
    create 0644 root root
    rotate 4
}

/tmp/wlog_debug.log {
    missingok
    notifempty
    compress
    size 50M
    daily
    create 0644 root root
    rotate 7
}
```

### Captura de errores específicos

Para capturar errores de un script específico:

```bash
# Errores generales
jq -r 'select(.script=="mi_script.sh" and .type=="end" and .result=="ERROR") | [.timestamp, .exit_code, .stderr] | @tsv' /var/log/script_monitor.log

# Scripts que fallan con subprocesos detectados
jq -r 'select(.type=="end" and .result=="ERROR" and .subprocess_count > 0) | [.timestamp, .script, .subprocess_count, .subprocess_pids] | @tsv' /var/log/script_monitor.log
```

## Valores de resultado

| Valor | Descripción |
|-------|-------------|
| `OK` | Ejecución completada con éxito (exit code 0) |
| `ERROR` | Ejecución completada con error (exit code != 0) |
| `INTERRUPTED` | Ejecución interrumpida por el usuario (Ctrl+C) o señal externa |

## Notas importantes

### Precisión del tiempo con monitoreo de subprocesos

Cuando se usa `-f/--follow`, wlog ajusta automáticamente el tiempo de ejecución para no incluir el tiempo de espera interno del monitor (1 segundo), asegurando mediciones precisas del tiempo real de ejecución del script.

### Detección de subprocesos

- El monitoreo se limita a **subprocesos directos** (primer nivel) para evitar ruido excesivo
- Los subprocesos se detectan mediante consultas cada segundo al árbol de procesos
- Se registra principalmente **qué** comandos se ejecutan y su estado, no métricas de rendimiento
- Con `-f`, el script se ejecuta en un nuevo grupo de procesos usando `setsid`

### Rendimiento

- El modo de monitoreo añade un overhead mínimo (consulta cada segundo)
- El modo debug puede generar logs voluminosos, usar solo para depuración
- En sistemas con alta carga, considerar usar `-f` solo cuando sea necesario
- Los campos `cpu` y `mem` en registros de subprocesos típicamente mostrarán 0.0 debido al timing de detección

## Compatibilidad

`wlog` ha sido probado en los siguientes sistemas:
- RHEL 8.5 y superior
- CentOS 8
- Rocky Linux 8
- Fedora 33+
- Requiere `bc` para cálculos de tiempo precisos
- Requiere `ps` con soporte para opciones `--ppid` y `--no-headers`

## Seguridad

- El archivo de log se crea con permisos 644 (lectura/escritura para el propietario, lectura para todos)
- Los logs de debug se crean en `/tmp` con permisos 644
- Se recomienda revisar periódicamente el tamaño de los archivos de log
- En entornos de alta seguridad, considere restringir los permisos de los archivos de log
- Con `-f`, los subprocesos se ejecutan en un grupo controlado que se termina limpiamente

## Changelog

### v2.1.1
- **Fix**: Corrección del cálculo de tiempo cuando se usa `-f/--follow`
- El tiempo ahora excluye correctamente el segundo de espera del monitor

### v2.1.0
- **Nuevo**: Opción `-f/--follow` para monitoreo de subprocesos directos
- **Nuevo**: Opción `-d/--debug` para logs de depuración detallados
- **Nuevo**: Registro automático de subprocesos con PID, comando, estado y recursos
- **Nuevo**: Información agregada de subprocesos en el registro de finalización
- **Mejora**: Ejecución en grupos de procesos para mejor control
- **Mejora**: Manejo robusto de interrupciones con limpieza de subprocesos

### v1.0.2
- Captura de argumentos y comando completo
- Mejoras en el formato JSON

### v1.0.1
- Manejo correcto de interrupciones
- Registro de señales SIGINT, SIGTERM, SIGHUP

## Licencia

Este software está licenciado bajo GNU GPL versión 3.

