#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"
CSV_FILE="grupos.csv"

# Verificar que el CSV exista
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: No se encontró el archivo $CSV_FILE"
    exit 1
fi

echo "📋 Verificando entregas (contando commits) de los grupos..."
echo "--------------------------------------------------"

# Contadores para el resumen final
ENTREGADOS=0
NO_ENTREGADOS=0

# Leer el CSV omitiendo el encabezado
tail -n +2 "$CSV_FILE" | while IFS=',' read -r GRUPO ALUMNO1 ALUMNO2; do
    
    # Limpiar retornos de carro por si el CSV viene de Windows (\r)
    GRUPO=$(echo "$GRUPO" | tr -d '\r')
    REPO_NAME="${ASSIGNMENT_PREFIX}-${GRUPO}"
    
    # 1. Consultar la cantidad de commits usando GraphQL
    # GraphQL es mucho más rápido y directo para obtener solo el conteo
    QUERY="
    query {
      repository(owner: \"$ORG\", name: \"$REPO_NAME\") {
        defaultBranchRef {
          target {
            ... on Commit {
              history {
                totalCount
              }
            }
          }
        }
      }
    }
    "

    # 2. Ejecutar la consulta y extraer el número (silenciando errores por si el repo no existe)
    COMMIT_COUNT=$(gh api graphql -f query="$QUERY" --jq '.data.repository.defaultBranchRef.target.history.totalCount' 2>/dev/null)

    # 3. Validar estado
    if [ -z "$COMMIT_COUNT" ] || [ "$COMMIT_COUNT" == "null" ]; then
        echo "⚠️  $GRUPO: Repositorio no encontrado o vacío ($REPO_NAME)."
        continue
    fi

    # 4. Lógica de evaluación: Si hay 1 commit, no hubo entrega.
    if [ "$COMMIT_COUNT" -eq 1 ]; then
        echo "❌ $GRUPO: NO ENTREGADO (Solo tiene el commit inicial)"
        ((NO_ENTREGADOS++))
    else
        echo "✅ $GRUPO: Entregado (Total de commits: $COMMIT_COUNT)"
        ((ENTREGADOS++))
    fi

done

echo "--------------------------------------------------"
echo "🎉 Verificación finalizada."
