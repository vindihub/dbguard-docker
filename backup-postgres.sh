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
if [ -z "${POSTGRES_PASSWORD}" ]; then
    handle_error "POSTGRES_PASSWORD no está configurado"
fi

# Configurar variables con valores por defecto
DB_HOST=${POSTGRES_HOST:-localhost}
DB_USER=${POSTGRES_USER:-postgres}
DB_NAME=${POSTGRES_DB}
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"

# Exportar contraseña para pg_dump
export PGPASSWORD=${POSTGRES_PASSWORD}

# Crear directorio de backup si no existe
mkdir -p ${BACKUP_DIR}

# Iniciar backup
log "${YELLOW}DBGuardian: Iniciando backup de PostgreSQL...${NC}"
log "Base de datos: ${DB_NAME}"
log "Host: ${DB_HOST}"

# Realizar backup
if pg_dump -h ${DB_HOST} -U ${DB_USER} ${DB_NAME} > ${BACKUP_FILE} 2>/tmp/error.log; then
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
    handle_error "Fallo en pg_dump: ${ERROR}"
fi
