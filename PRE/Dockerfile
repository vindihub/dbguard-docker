FROM alpine:3.19

# Instalar dependencias necesarias
RUN apk add --no-cache \
    mysql-client \
    postgresql-client \
    mariadb-client \
    mariadb-connector-c \
    mariadb-connector-c-dev \
    mariadb-common \
    libressl \
    curl \
    bash \
    tzdata \
    && rm -rf /var/cache/apk/*

# Crear directorio para backups
RUN mkdir -p /backups

# Copiar los scripts de backup
COPY backup.sh /usr/local/bin/

# Hacer ejecutables los scripts
RUN chmod +x /usr/local/bin/backup.sh

# Configurar zona horaria por defecto
ENV TZ=Europe/Madrid

# Directorio de trabajo
WORKDIR /backups
VOLUME ["/backups"]
