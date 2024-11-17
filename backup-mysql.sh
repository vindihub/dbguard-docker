#!/bin/bash

# Configuración de colores para los mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Función para imprimir mensajes con timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${1}"
}

# Función para manejar errores
handle_error() {
    log "${RED}Error: ${1}${NC}"
    # Notificar error a Uptime Kuma si está configurado
    if [ ! -z "${UPTIME_KUMA_PUSH_URL}" ]; then
        curl -s "${UPTIME_KUMA_PUSH_URL}?status=down&msg=Backup%20failed:%20${1}"
    fi
    exit 1
}

# Verificar variables de entorno requeridas
if [ -z "${MYSQL_PASSWORD}" ]; then
    handle_error "MYSQL_PASSWORD no está configurado"
fi

# Configurar variables con valores por defecto
DB_HOST=${MYSQL_HOST:-localhost}
DB_USER=${MYSQL_USER:-root}
DB_PASS=${MYSQL_PASSWORD}
DB_NAME=${MYSQL_DATABASE}
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"

# Crear directorio de backup si no existe
mkdir -p ${BACKUP_DIR}

# Iniciar backup
log "${YELLOW}DBGuardian: Iniciando backup de MySQL...${NC}"
log "Base de datos: ${DB_NAME}"
log "Host: ${DB_HOST}"

# Realizar backup
if mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} > ${BACKUP_FILE} 2>/tmp/error.log; then
    # Comprimir backup
    gzip ${BACKUP_FILE}
    FINAL_SIZE=$(du -h ${BACKUP_FILE}.gz | cut -f1)
    
    log "${GREEN}✓ Backup completado exitosamente${NC}"
    log "Archivo: ${BACKUP_FILE}.gz"
    log "Tamaño: ${FINAL_SIZE}"
    
    # Notificar éxito a Uptime Kuma
    if [ ! -z "${UPTIME_KUMA_PUSH_URL}" ]; then
        log "Notificando a Uptime Kuma..."
        curl -s "${UPTIME_KUMA_PUSH_URL}?status=up&msg=Backup%20successful%20-%20Size:%20${FINAL_SIZE}"
    fi
else
    ERROR=$(cat /tmp/error.log)
    handle_error "Fallo en mysqldump: ${ERROR}"
fi
