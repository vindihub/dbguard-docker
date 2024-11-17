FROM alpine:3.19

# Instalar dependencias necesarias
RUN apk add --no-cache \
    mysql-client \
    postgresql-client \
    curl \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# Crear directorio para backups
RUN mkdir -p /backups

# Copiar los scripts de backup
COPY backup-mysql.sh /usr/local/bin/
COPY backup-postgres.sh /usr/local/bin/

# Hacer ejecutables los scripts
RUN chmod +x /usr/local/bin/backup-mysql.sh \
    && chmod +x /usr/local/bin/backup-postgres.sh

# Configurar zona horaria por defecto
ENV TZ=UTC

# Directorio de trabajo
WORKDIR /backups

VOLUME ["/backups"]

# Banner de bienvenida
CMD ["echo", "DBGuardian - Tu solución de backups para MySQL y PostgreSQL\nUsa backup-mysql.sh o backup-postgres.sh según necesites"]
