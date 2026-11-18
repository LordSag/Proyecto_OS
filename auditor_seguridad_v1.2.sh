#!/usr/bin/env bash
set -u

if [[ $EUID -ne 0 ]]; then
	echo "Este script debe ejecutarse con privilegios de superusuario."
	echo "Uso: sudo $0"
	exit 1
fi

reporte="Auditoria_$(date +%F-%H%M%S).txt"

{
	echo "Auditoria Basica de Seguridad"
	echo "Por: Luis SEPULVEDA"
	echo "Fecha: $(date)"
	echo "--------------------------------------------"
	echo

	echo "=========Cuentas con UID 0==================="
	cuenta_UID0=$(getent passwd | awk -F: '$3 == 0 { print $1 }')

	if [[ -z "$cuenta_UID0" ]]; then
		echo "No se encontraron cuentas con UID 0"
	else
		printf '%s\n' "$cuenta_UID0"
		while IFS= read -r usuario; do
			if [[ "$usuario" != "root" ]]; then
				echo "Revisar la cuenta distinta de root con UID 0: $usuario"
			fi
		done <<< "$cuenta_UID0"
	fi
	echo "-------------------------------------------------"
	echo

	echo "============Archivos Sensibles==================="
	for archivo in /etc/passwd /etc/shadow /etc/sudoers; do
		if [[ -e "$archivo" ]]; then
			stat -c '%A (%a) propietario=%U grupo=%G archivo=%n' "$archivo" \
				|| echo "No se pudo consultar $archivo"
		else
			echo "El archivo $archivo no existe"
		fi
	done
	echo "----------------------------------------------------"
	echo

	echo "================Verificar Puertos TCP/UDP======================="
	puertos=$(ss -H -tuln)
	if [[ -n "$puertos" ]]; then
		echo "Puertos en escucha:"
		printf '%s\n' "$puertos"
	else
		echo "No se encontraron puertos en escucha"
	fi
	echo "Revisar si cada puerto en escucha es necesario"
	echo
} > "$reporte" 2>&1
echo "Reporte guardado en: $reporte"