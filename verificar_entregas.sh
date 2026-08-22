#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"

echo "🔍 Buscando repositorios con el prefijo '$ASSIGNMENT_PREFIX'..."

# Obtener todos los repositorios de la organización sin límite y filtrar por el prefijo
REPOS=$(gh repo list "$ORG" --limit 10000 --json name -q '.[].name' | grep "^$ASSIGNMENT_PREFIX")

# Verificar que existan repositorios para analizar
if [ -z "$REPOS" ]; then
    echo "Error: No se encontraron repositorios con el prefijo '$ASSIGNMENT_PREFIX'"
    exit 1
fi

echo "📋 Verificando entregas (contando commits) de los grupos..."
echo "--------------------------------------------------"

# Contadores para el resumen final
ENTREGADOS=0
NO_ENTREGADOS=0

# Leer la lista de repositorios (usamos <<< para evitar problemas de variables en subshells)
while IFS= read -r REPO_NAME; do
    
    # Extraer el nombre del grupo/alumno quitando el prefijo y el guion
    GRUPO="${REPO_NAME#$ASSIGNMENT_PREFIX-}"
    
    # 1. Consultar la cantidad de commits usando GraphQL
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
        echo "⚠️  $GRUPO: Repositorio vacío o sin rama por defecto."
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

done <<< "$REPOS"

echo "--------------------------------------------------"
echo "🎉 Verificación finalizada."
echo "📊 Resumen: $ENTREGADOS entregados, $NO_ENTREGADOS no entregados."