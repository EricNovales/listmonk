# Etapa de construcción
FROM golang:1.24-alpine AS builder

# Instalar las dependencias necesarias para la construcción
RUN apk add --no-cache git nodejs yarn gcc musl-dev build-base

# Establecer el directorio de trabajo
WORKDIR /build

# Copiar el código fuente local al contenedor
COPY . .

# Compilar la aplicación
RUN make dist

# Etapa de producción
FROM alpine:latest

# Instalar las dependencias necesarias
RUN apk --no-cache add ca-certificates tzdata shadow su-exec

# Crear usuario no root
RUN addgroup -S listmonk && adduser -S listmonk -G listmonk

# Establecer el directorio de trabajo
WORKDIR /listmonk

# Copiar el binario compilado desde la etapa de construcción
COPY --from=builder /build/listmonk .

# Copiar el archivo de configuración y el script de entrada
COPY config.toml.sample config.toml
COPY docker-entrypoint.sh /usr/local/bin/

# Hacer que el script de entrada sea ejecutable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Exponer el puerto de la aplicación
EXPOSE 9000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://127.0.0.1:9000/health || exit 1

USER listmonk

# Establecer el script de entrada
ENTRYPOINT ["docker-entrypoint.sh"]

# Definir el comando para ejecutar la aplicación
CMD ["./listmonk"]

