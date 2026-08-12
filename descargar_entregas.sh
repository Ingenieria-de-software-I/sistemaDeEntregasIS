#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"
CSV_FILE="grupos.csv"
DESTINO="entregas_codigo-repetido"

# Verificar que el CSV exista
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: No se encontró el archivo $CSV_FILE"
    exit 1
fi

# Crear la carpeta de destino si no existe
mkdir -p "$DESTINO"
cd "$DESTINO" || exit

echo "📥 Iniciando descarga masiva de entregas en la carpeta: $(pwd)..."
echo "--------------------------------------------------"

# Contador para el resumen
DESCARGADOS=0

# Leer el CSV omitiendo el encabezado
tail -n +2 "../$CSV_FILE" | while IFS=',' read -r GRUPO ALUMNO1 ALUMNO2; do
    
    # Limpiar retornos de carro por si el CSV viene de Windows (\r)
    GRUPO=$(echo "$GRUPO" | tr -d '\r')
    REPO_NAME="${ASSIGNMENT_PREFIX}-${GRUPO}"
    
    echo "Procesando $GRUPO..."

    # Verificar si la carpeta del grupo ya existe para no clonar de nuevo
    if [ -d "$REPO_NAME" ]; then
        echo "   -> ⚠️  La carpeta $REPO_NAME ya existe. Actualizando (git pull)..."
        # Entramos a la carpeta, hacemos git pull, y salimos
        (cd "$REPO_NAME" && git pull --quiet)
        ((DESCARGADOS++))
    else
        echo "   -> Clonando $REPO_NAME..."
        
        # Ejecutar el clonado capturando posibles errores (ej: repo no existe)
        # Se redirige la salida estándar a /dev/null para mantener la consola limpia
        if gh repo clone "$ORG/$REPO_NAME" -- -q 2>/dev/null; then
            ((DESCARGADOS++))
        else
            echo "   -> ❌ Error: No se pudo clonar $REPO_NAME (¿El repositorio no existe?)"
        fi
    fi

done

echo "--------------------------------------------------"
echo "🎉 Proceso finalizado."
