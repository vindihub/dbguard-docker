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

# Verificar el tipo de base de datos
DB_TYPE=${DB_TYPE:-mysql}  # Valor por defecto: mysql
if [[ ! "${DB_TYPE}" =~ ^(mysql|postgre|mariadb)$ ]]; then
    handle_error "DB_TYPE debe ser mysql, postgre o mariadb"
fi

# Verificar variables de entorno requeridas
if [ -z "${DB_PASSWORD}" ]; then
    handle_error "DB_PASSWORD no está configurado"
fi

# Definir variables
DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-root}
DB_NAME=${DB_NAME}
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql"

# Crear directorio de backup si no existe
mkdir -p ${BACKUP_DIR}

# Iniciar backup
log "${YELLOW}DBGuardian: Iniciando backup de ${DB_TYPE}...${NC}"
log "Base de datos: ${DB_NAME}"
log "Host: ${DB_HOST}"

# Realizar backup según el tipo de base de datos
case ${DB_TYPE} in
    mysql|mariadb)
        if mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} > ${BACKUP_FILE} 2>/tmp/error.log; then
            BACKUP_SUCCESS=true
        else
            ERROR=$(cat /tmp/error.log)
            handle_error "Fallo en mysqldump: ${ERROR}"
        fi
        ;;
    postgre)
        # Para PostgreSQL, establecer PGPASSWORD con el valor de DB_PASSWORD
        export PGPASSWORD=${DB_PASSWORD}
        if pg_dump -h ${DB_HOST} -U ${DB_USER} -d ${DB_NAME} > ${BACKUP_FILE} 2>/tmp/error.log; then
            BACKUP_SUCCESS=true
        else
            ERROR=$(cat /tmp/error.log)
            handle_error "Fallo en pg_dump: ${ERROR}"
        fi
        ;;
esac

if [ "${BACKUP_SUCCESS}" = true ]; then
    # Comprimir backup
    gzip ${BACKUP_FILE}
    FINAL_SIZE=$(du -h ${BACKUP_FILE}.gz | cut -f1)
    
    log "${GREEN}✓ Backup completado exitosamente${NC}"
    log "Archivo: ${BACKUP_FILE}.gz"
    log "Tamaño: ${FINAL_SIZE}"
    
    # Enviar notificación a Uptime Kuma
    if [ ! -z "${UPTIME_KUMA_PUSH_URL}" ]; then
        log "Notificando a Uptime Kuma..."
        curl -s "${UPTIME_KUMA_PUSH_URL}?status=up&msg=Backup%20OK"
    fi
fi