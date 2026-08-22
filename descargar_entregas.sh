#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"
DESTINO="entregas_codigo-repetido"

# Crear la carpeta de destino si no existe
mkdir -p "$DESTINO"
cd "$DESTINO" || exit

echo "🔍 Buscando repositorios con el prefijo '$ASSIGNMENT_PREFIX' en GitHub..."

# Consultar a GitHub la lista de repositorios (hasta 500) y filtrar por el prefijo
# Usamos --json name para traer solo los nombres y grep para coincidencia exacta al inicio (^)
REPOS=$(gh repo list "$ORG" --limit 10000 --json name -q '.[].name' | grep "^$ASSIGNMENT_PREFIX")

# Verificar si se encontró al menos un repositorio
if [ -z "$REPOS" ]; then
    echo "❌ No se encontraron repositorios con el prefijo '$ASSIGNMENT_PREFIX' en la organización '$ORG'."
    exit 1
fi

echo "📥 Iniciando descarga masiva de entregas en la carpeta: $(pwd)..."
echo "--------------------------------------------------"

# Contador para el resumen
DESCARGADOS=0

# Iterar directamente sobre los repositorios encontrados en GitHub
for REPO_NAME in $REPOS; do
    
    echo "Procesando $REPO_NAME..."

    # Verificar si la carpeta del grupo ya existe para no clonar de nuevo
    if [ -d "$REPO_NAME" ]; then
        echo "   -> ⚠️  La carpeta $REPO_NAME ya existe. Actualizando (git pull)..."
        # Entramos a la carpeta, hacemos git pull, y salimos
        (cd "$REPO_NAME" && git pull --quiet)
        ((DESCARGADOS++))
    else
        echo "   -> Clonando $REPO_NAME..."
        
        # Ejecutar el clonado capturando posibles errores
        # Se redirige la salida estándar a /dev/null para mantener la consola limpia
        if gh repo clone "$ORG/$REPO_NAME" -- -q 2>/dev/null; then
            ((DESCARGADOS++))
        else
            echo "   -> ❌ Error: No se pudo clonar $REPO_NAME"
        fi
    fi

done

echo "--------------------------------------------------"
echo "🎉 Proceso finalizado. Se procesaron $DESCARGADOS repositorios."