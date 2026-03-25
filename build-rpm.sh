#!/bin/bash
# Script para construir el paquete RPM de wlog

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Verificar que existan los archivos necesarios
if [ ! -f wlog ]; then
    echo -e "${RED}Error: No se encuentra el archivo wlog${NC}"
    exit 1
fi

if [ ! -f wlog.1 ]; then
    echo -e "${RED}Error: No se encuentra el archivo wlog.1${NC}"
    exit 1
fi

# Instalar herramientas necesarias
echo -e "${YELLOW}Instalando herramientas de construcción...${NC}"
sudo dnf install -y rpm-build rpmdevtools

# Crear estructura de directorios para RPM si no existe
echo -e "${YELLOW}Configurando entorno de construcción...${NC}"
rpmdev-setuptree

# Generar la página de manual comprimida
echo -e "${YELLOW}Comprimiendo página de manual...${NC}"
gzip -9 -c wlog.1 > wlog.1.gz

# Crear README si no existe
if [ ! -f README ]; then
    echo -e "${YELLOW}Creando archivo README...${NC}"
    cat > README << 'EOF'
wlog - Wrapper para monitoreo y logging de ejecución de scripts
Versión: 2.2.1
Autor: TEST <test@test.com>
Licencia: GPL v3

Descripción:
  wlog permite ejecutar cualquier script o programa, registrando automáticamente
  información sobre su ejecución, incluyendo tiempo de inicio, duración,
  resultado, errores y opcionalmente la salida estándar.

  Toda la información se almacena en formato JSON en /var/log/script_monitor.log,
  permitiendo un monitoreo detallado y análisis posterior de las ejecuciones.
EOF
fi

# Crear LICENSE si no existe
if [ ! -f LICENSE ]; then
    echo -e "${YELLOW}Creando archivo LICENSE...${NC}"
    cat > LICENSE << 'EOF'
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.
EOF
fi

# Crear archivo spec si no existe
if [ ! -f wlog.spec ]; then
    echo -e "${YELLOW}Creando archivo wlog.spec...${NC}"
    cat > wlog.spec << 'EOF'
Name:           wlog
Version:        2.2.1
Release:        1%{?dist}
Summary:        Wrapper para monitoreo y logging de ejecución de scripts

License:        GPL-3
URL:            https://github.com/wlog/wlog
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       bc
Requires:       coreutils
Requires:       grep
Requires:       util-linux
Requires:       procps-ng

%description
Wrapper para monitoreo y logging de ejecución de scripts.
Esta herramienta permite ejecutar cualquier script o programa, registrando
automáticamente información sobre su ejecución, incluyendo tiempo de inicio,
duración, resultado, errores y opcionalmente la salida estándar.
Toda la información se almacena en formato JSON en /var/log/script_monitor.log.

%prep
%setup -q

%build
# No requiere compilación

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}%{_docdir}/%{name}

# Instalar el script ejecutable
install -m 755 wlog %{buildroot}%{_bindir}/wlog

# Instalar la página del manual
install -m 644 wlog.1.gz %{buildroot}%{_mandir}/man1/wlog.1.gz

# Instalar documentación
install -m 644 README %{buildroot}%{_docdir}/%{name}/README
install -m 644 LICENSE %{buildroot}%{_docdir}/%{name}/LICENSE

%post
if [ ! -f /var/log/script_monitor.log ]; then
    touch /var/log/script_monitor.log
    chmod 644 /var/log/script_monitor.log
fi

%files
%{_bindir}/wlog
%{_mandir}/man1/wlog.1.gz
%doc %{_docdir}/%{name}/README
%license %{_docdir}/%{name}/LICENSE

%changelog
* Tue May 06 2025 TEST <test@test.com> - 2.2.1-1
- Versión inicial
EOF
fi

# Crear directorio para el proyecto
echo -e "${YELLOW}Preparando archivos fuente...${NC}"
mkdir -p ~/wlog-build/wlog-2.2.1

# Copiar los archivos al directorio
cp wlog ~/wlog-build/wlog-2.2.1/
cp wlog.1.gz ~/wlog-build/wlog-2.2.1/
cp README ~/wlog-build/wlog-2.2.1/
cp LICENSE ~/wlog-build/wlog-2.2.1/

# Crear el archivo tar.gz
echo -e "${YELLOW}Creando archivo tar.gz...${NC}"
cd ~/wlog-build/
tar -czvf wlog-2.2.1.tar.gz wlog-2.2.1/

# Copiar archivos a sus ubicaciones correctas
echo -e "${YELLOW}Copiando archivos a directorios de construcción...${NC}"
cp wlog-2.2.1.tar.gz ~/rpmbuild/SOURCES/
cp ../wlog.spec ~/rpmbuild/SPECS/

# Construir el paquete RPM
echo -e "${YELLOW}Construyendo paquete RPM...${NC}"
cd ~/rpmbuild/SPECS
rpmbuild -ba wlog.spec

# Verificar el resultado
if [ $? -eq 0 ]; then
    echo -e "${GREEN}¡Construcción exitosa!${NC}"
    echo -e "${YELLOW}Verificando paquete construido...${NC}"
    RPM_FILE=$(ls -la ~/rpmbuild/RPMS/noarch/wlog-2.2.1-1*.rpm)
    
    if [ -n "$RPM_FILE" ]; then
        echo -e "${GREEN}El paquete RPM se ha construido correctamente:${NC}"
        echo "$RPM_FILE"
        echo ""
        echo -e "${YELLOW}Contenido del paquete:${NC}"
        rpm -qlp ~/rpmbuild/RPMS/noarch/wlog-2.2.1-1*.rpm
        echo ""
        echo -e "${GREEN}Para instalar el paquete, ejecute:${NC}"
        echo "sudo rpm -ivh ~/rpmbuild/RPMS/noarch/wlog-2.2.1-1*.rpm"
    else
        echo -e "${RED}No se encontró el archivo RPM generado.${NC}"
    fi
else
    echo -e "${RED}Error al construir el paquete RPM.${NC}"
fi

