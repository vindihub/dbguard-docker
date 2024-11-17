#!/bin/bash

# Definir variables
DB_TYPE=${DB_TYPE:-mysql}
DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-root}
DB_NAME=${DB_NAME}
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"
BACKUP_SUCCESS=false

echo "Iniciando script de backup..."
echo "Tipo de base de datos: ${DB_TYPE}"
echo "Host de la base de datos: ${DB_HOST}"
echo "Usuario de la base de datos: ${DB_USER}"
echo "Directorio de backup: ${BACKUP_DIR}"

# Crear directorio de backup
mkdir -p ${BACKUP_DIR}
echo "Directorio de backup creado/verificado: ${BACKUP_DIR}"

# Realizar backup según el tipo de base de datos
case ${DB_TYPE} in
    mysql|mariadb)
        echo "Iniciando backup para MySQL/MariaDB..."
        if mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} > ${BACKUP_FILE}; then
            echo "Backup de MySQL/MariaDB completado: ${BACKUP_FILE}"
            BACKUP_SUCCESS=true
        else
            echo "Error durante el backup de MySQL/MariaDB."
        fi
        ;;
    postgre)
        echo "Iniciando backup para PostgreSQL..."
        export PGPASSWORD=${DB_PASSWORD}
        if pg_dump -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} > ${BACKUP_FILE}; then
            echo "Backup de PostgreSQL completado: ${BACKUP_FILE}"
            BACKUP_SUCCESS=true
        else
            echo "Error durante el backup de PostgreSQL."
        fi
        ;;
    *)
        echo "Tipo de base de datos no soportado: ${DB_TYPE}"
        ;;
esac

# Comprimir y enviar señal a Uptime Kuma si el backup fue exitoso
if [ "${BACKUP_SUCCESS}" = true ]; then
    echo "Comenzando compresión del archivo de backup..."
    gzip ${BACKUP_FILE}
    echo "Backup comprimido exitosamente: ${BACKUP_FILE}.gz"

    if [ ! -z "${UPTIME_KUMA_PUSH_URL}" ]; then
        echo "Enviando señal a Uptime Kuma..."
        curl -s "${UPTIME_KUMA_PUSH_URL}" && echo "Señal enviada exitosamente a Uptime Kuma." || echo "Error al enviar la señal a Uptime Kuma."
    fi
else
    echo "El proceso de backup falló. No se realizará compresión ni notificación."
fi

echo "Script finalizado."
