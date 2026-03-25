Name:           wlog
Version:        2.2.1
Release:        1%{?dist}
Summary:        Wrapper para monitoreo y logging de ejecución de scripts

License:        GPL-3
URL:            https://github.com/jalvarezpowell/wlog
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash
Requires:       bc
Requires:       coreutils
Requires:       grep
Requires:       util-linux
Requires:       procps-ng
Provides:       wlog = %{version}-%{release}
Conflicts:      wlog < %{version}-%{release} 


%description
Wrapper para monitoreo y logging de ejecución de scripts.
Esta herramienta permite ejecutar cualquier script o programa, registrando
automáticamente información sobre su ejecución, incluyendo tiempo de inicio,
duración, resultado, errores y opcionalmente la salida estándar.
Toda la información se almacena en formato JSON en /var/log/script_monitor.log.

A partir de la versión 2.2.1, wlog registra correctamente las interrupciones
(Ctrl+C) para asegurar que todas las ejecuciones queden documentadas.

En la versión 2.1.0 se añade el registro de los argumentos pasados al script
ejecutado y el comando completo, proporcionando visibilidad total sobre lo
que se ejecutó exactamente.

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



* Wed Jul 02 2025 JAAP <jalvarez.powell@gmail.com> - 2.2.1-1
- Mejora: Puede registrar script son subprocesos 
- Mejora: Registro de argumentos pasados al script y comando completo
- Mejora: Adición de campos "args" y "command" en el JSON de registro

* Tue May 02 2025 JAAP <jalvarez.powell@gmail.com> - 2.1.1-1
- Mejora: Manejo de interrupciones (Ctrl+C) para registrar todas las ejecuciones
- Mejora: Limpieza de archivos temporales con trap EXIT

* Tue Apr 29 2025 JAAP <jalvarez.powell@gmail.com> - 2.0.1-1
- Versión inicial

