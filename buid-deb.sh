#!/bin/bash
# Script para construir el paquete DEB de wlog 1.0.2 en Ubuntu 18.04

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Variables
PACKAGE_NAME="wlog"
VERSION="1.0.2"
MAINTAINER="TEST <test@test.com>"
ARCHITECTURE="all"
BUILD_DIR="$HOME/wlog-deb-build"
PACKAGE_DIR="$BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}"

echo -e "${YELLOW}Construcción de paquete DEB para wlog ${VERSION}${NC}"
echo "=================================================="

# Verificar que existan los archivos necesarios
if [ ! -f wlog ]; then
    echo -e "${RED}Error: No se encuentra el archivo wlog${NC}"
    exit 1
fi

if [ ! -f wlog.1 ]; then
    echo -e "${RED}Error: No se encuentra el archivo wlog.1${NC}"
    exit 1
fi

if [ ! -f README.md ]; then
    echo -e "${RED}Error: No se encuentra el archivo README.md${NC}"
    exit 1
fi

# Instalar herramientas necesarias para construcción de paquetes DEB
echo -e "${YELLOW}Instalando herramientas de construcción...${NC}"
sudo apt-get update
sudo apt-get install -y build-essential debhelper dh-make devscripts lintian

# Limpiar directorio de construcción anterior si existe
echo -e "${YELLOW}Limpiando directorio de construcción...${NC}"
rm -rf "$BUILD_DIR"

# Crear estructura de directorios para el paquete DEB
echo -e "${YELLOW}Creando estructura de directorios...${NC}"
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/usr/bin"
mkdir -p "$PACKAGE_DIR/usr/share/man/man1"
mkdir -p "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME"

# Crear archivo control para el paquete DEB
echo -e "${YELLOW}Creando archivo control...${NC}"
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: admin
Priority: optional
Architecture: $ARCHITECTURE
Depends: bash, bc, coreutils, grep, util-linux, procps
Maintainer: $MAINTAINER
Description: Wrapper para monitoreo y logging de ejecución de scripts
 wlog permite ejecutar cualquier script o programa, registrando automáticamente
 información sobre su ejecución, incluyendo tiempo de inicio, duración,
 resultado, errores y opcionalmente la salida estándar.
 .
 Toda la información se almacena en formato JSON en /var/log/script_monitor.log,
 permitiendo un monitoreo detallado y análisis posterior de las ejecuciones.
 .
 Características principales:
  - Genera un ID de transacción único para cada ejecución
  - Detecta automáticamente el origen de la ejecución (shell, cron, systemd)
  - Maneja correctamente las interrupciones (como Ctrl+C)
  - Captura los argumentos pasados al script y el comando completo
EOF

# Crear script postinst para tareas después de la instalación
echo -e "${YELLOW}Creando script postinst...${NC}"
cat > "$PACKAGE_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
# Script que se ejecuta después de la instalación

set -e

# Crear archivo de log si no existe
if [ ! -f /var/log/script_monitor.log ]; then
    touch /var/log/script_monitor.log
    chmod 644 /var/log/script_monitor.log
fi

# Actualizar base de datos de páginas del manual
if command -v mandb >/dev/null 2>&1; then
    mandb -q
fi

exit 0
EOF

chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"

# Crear script postrm para limpieza después de la desinstalación
echo -e "${YELLOW}Creando script postrm...${NC}"
cat > "$PACKAGE_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
# Script que se ejecuta después de la desinstalación

set -e

case "$1" in
    purge)
        # Solo eliminar el log si se purga completamente el paquete
        if [ -f /var/log/script_monitor.log ]; then
            echo "Eliminando archivo de log /var/log/script_monitor.log"
            rm -f /var/log/script_monitor.log
        fi
        ;;
    remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        # No hacer nada en estos casos
        ;;
    *)
        echo "postrm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

exit 0
EOF

chmod 755 "$PACKAGE_DIR/DEBIAN/postrm"

# Comprimir la página del manual si no está comprimida
echo -e "${YELLOW}Preparando página del manual...${NC}"
if [ -f wlog.1.gz ]; then
    cp wlog.1.gz "$PACKAGE_DIR/usr/share/man/man1/"
else
    gzip -9 -c wlog.1 > "$PACKAGE_DIR/usr/share/man/man1/wlog.1.gz"
fi

# Copiar archivos del paquete
echo -e "${YELLOW}Copiando archivos del paquete...${NC}"
install -m 755 wlog "$PACKAGE_DIR/usr/bin/"
install -m 644 README.md "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME/"

# Crear archivo copyright si no existe
if [ -f LICENSE ]; then
    cp LICENSE "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME/copyright"
else
    echo -e "${YELLOW}Creando archivo copyright...${NC}"
    cat > "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME/copyright" << EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: wlog
Upstream-Contact: $MAINTAINER

Files: *
Copyright: 2025 TEST <test@test.com>
License: GPL-3
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
EOF
fi

# Crear archivo changelog
echo -e "${YELLOW}Creando changelog...${NC}"
cat > "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME/changelog.Debian" << EOF
$PACKAGE_NAME ($VERSION) unstable; urgency=medium

  * Mejora: Registro de argumentos pasados al script y comando completo
  * Mejora: Adición de campos "args" y "command" en el JSON de registro

 -- $MAINTAINER  $(date -R)

$PACKAGE_NAME (1.0.1) unstable; urgency=medium

  * Mejora: Manejo de interrupciones (Ctrl+C) para registrar todas las ejecuciones
  * Mejora: Limpieza de archivos temporales con trap EXIT

 -- $MAINTAINER  Tue, 06 May 2025 12:00:00 +0000

$PACKAGE_NAME (1.0.0) unstable; urgency=medium

  * Versión inicial

 -- $MAINTAINER  Tue, 29 Apr 2025 12:00:00 +0000
EOF

# Comprimir el changelog
gzip -9 "$PACKAGE_DIR/usr/share/doc/$PACKAGE_NAME/changelog.Debian"

# Calcular el tamaño instalado (en KB)
INSTALLED_SIZE=$(du -sk "$PACKAGE_DIR" | cut -f1)
echo "Installed-Size: $INSTALLED_SIZE" >> "$PACKAGE_DIR/DEBIAN/control"

# Construir el paquete DEB
echo -e "${YELLOW}Construyendo paquete DEB...${NC}"
cd "$BUILD_DIR"
dpkg-deb --build "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}"

# Verificar el paquete con lintian
echo -e "${YELLOW}Verificando paquete con lintian...${NC}"
lintian "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb" || true

# Mostrar información del paquete construido
if [ -f "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb" ]; then
    echo -e "${GREEN}¡Paquete DEB construido exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}Archivo generado:${NC}"
    ls -la "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    echo ""
    echo -e "${YELLOW}Información del paquete:${NC}"
    dpkg-deb --info "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    echo ""
    echo -e "${YELLOW}Contenido del paquete:${NC}"
    dpkg-deb --contents "${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    echo ""
    echo -e "${GREEN}Para instalar el paquete, ejecute:${NC}"
    echo "sudo dpkg -i $BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
    echo "sudo apt-get install -f  # Para resolver dependencias si es necesario"
    echo ""
    echo -e "${GREEN}O mejor aún, use gdebi para instalación automática de dependencias:${NC}"
    echo "sudo apt-get install gdebi-core"
    echo "sudo gdebi $BUILD_DIR/${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb"
else
    echo -e "${RED}Error: No se pudo construir el paquete DEB${NC}"
    exit 1
fi