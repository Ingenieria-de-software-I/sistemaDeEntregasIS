#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"
CSV_FILE="grupos.csv"

# 1. Validar argumentos: requiere la fecha límite
if [ "$#" -ne 1 ]; then
    echo "Uso: $0 \"YYYY-MM-DD HH:MM:SS\""
    echo "Ejemplo: $0 \"2026-08-11 23:59:59\""
    exit 1
fi

DEADLINE_INPUT="$1"

# 2. Convertir la fecha ingresada a formato 'segundos desde 1970' (Epoch)
# Esto permite comparar numéricamente cuál fecha es mayor.
# Al usar `date -d`, asume la zona horaria de tu computadora (Argentina).
DEADLINE_EPOCH=$(date -d "$DEADLINE_INPUT" +%s 2>/dev/null)

if [ -z "$DEADLINE_EPOCH" ]; then
    echo "❌ Error: Formato de fecha inválido. Usá \"YYYY-MM-DD HH:MM:SS\"."
    exit 1
fi

echo "⏰ Límite establecido: $DEADLINE_INPUT (Hora local)"
echo "📋 Verificando entregas de los grupos..."
echo "--------------------------------------------------"

# Leer el CSV omitiendo el encabezado
tail -n +2 "$CSV_FILE" | while IFS=',' read -r GRUPO ALUMNO1 ALUMNO2; do
    
    GRUPO=$(echo "$GRUPO" | tr -d '\r')
    REPO_NAME="${ASSIGNMENT_PREFIX}-${GRUPO}"
    
    # 3. Consultar: Total de commits y la fecha del ÚLTIMO commit
    QUERY="
    query {
      repository(owner: \"$ORG\", name: \"$REPO_NAME\") {
        defaultBranchRef {
          target {
            ... on Commit {
              history {
                totalCount
              }
              pushedDate
              committedDate
            }
          }
        }
      }
    }
    "

    # Capturar la respuesta JSON completa
    RESPONSE=$(gh api graphql -f query="$QUERY" 2>/dev/null)

    # Extraer variables con jq
    COMMIT_COUNT=$(echo "$RESPONSE" | jq -r '.data.repository.defaultBranchRef.target.history.totalCount')
    LAST_COMMIT_DATE=$(echo "$RESPONSE" | jq -r '.data.repository.defaultBranchRef.target.committedDate')

    # Validar si el repo existe
    if [ "$COMMIT_COUNT" == "null" ] || [ -z "$COMMIT_COUNT" ]; then
        echo "⚠️  $GRUPO: Repositorio no encontrado o vacío ($REPO_NAME)."
        continue
    fi

    # 4. Evaluación de "No entregado" (1 solo commit)
    if [ "$COMMIT_COUNT" -eq 1 ]; then
        echo "❌ $GRUPO: NO ENTREGADO (Solo tiene el commit inicial)"
        continue
    fi

    # 5. Evaluación de "Tardía" vs "A tiempo"
    # Convertimos la fecha del último commit de formato ISO (UTC) a Epoch local
    LAST_COMMIT_EPOCH=$(date -d "$LAST_COMMIT_DATE" +%s)

    # Convertimos la fecha nuevamente a un formato legible para mostrarla
    LAST_COMMIT_LOCAL=$(date -d "$LAST_COMMIT_DATE" +"%Y-%m-%d %H:%M:%S")

    if [ "$LAST_COMMIT_EPOCH" -gt "$DEADLINE_EPOCH" ]; then
        echo "⏳ $GRUPO: ENTREGA TARDÍA (Último commit: $LAST_COMMIT_LOCAL)"
    else
        echo "✅ $GRUPO: A tiempo (Último commit: $LAST_COMMIT_LOCAL)"
    fi

done

echo "--------------------------------------------------"
echo "🎉 Verificación finalizada."
