#!/bin/bash

# Configuración de la materia
ORG="Ingenieria-de-software-I-alumnos"
TEMPLATE_REPO="Ingenieria-de-software-I-alumnos/ejercicio-codigo-repetido"
ASSIGNMENT_PREFIX="2c2026-codigo-repetido"
CSV_FILE="grupos.csv"

# Verificar que el CSV exista
if [ ! -f "$CSV_FILE" ]; then
    echo "Error: No se encontró el archivo $CSV_FILE"
    exit 1
fi

# Leer el CSV omitiendo el encabezado
tail -n +2 "$CSV_FILE" | while IFS=',' read -r GRUPO ALUMNO1 ALUMNO2; do
    echo "--------------------------------------------------"
    echo "🚀 Procesando: $GRUPO"

    # 1. Crear el equipo en GitHub si no existe
    gh api -X POST "orgs/$ORG/teams" -f name="$GRUPO" -f privacy="closed" > /dev/null 2>&1
    
    # 2. Agregar los alumnos al equipo
    for ALUMNO in "$ALUMNO1" "$ALUMNO2"; do
        if [ -n "$ALUMNO" ]; then
            echo "   -> Agregando a $ALUMNO al equipo $GRUPO..."
            gh api -X PUT "orgs/$ORG/teams/$GRUPO/memberships/$ALUMNO" -f role="member" > /dev/null
        fi
    done

    # 3. Crear el repositorio privado del grupo a partir de la plantilla
    REPO_NAME="${ASSIGNMENT_PREFIX}-${GRUPO}"
    echo "   -> Creando repositorio $REPO_NAME..."
    gh repo create "$ORG/$REPO_NAME" --template "$TEMPLATE_REPO" --private --clone=false > /dev/null

    # 4. Asignar al equipo del grupo permiso de ESCRITURA sobre su repositorio
    gh api -X PUT "orgs/$ORG/teams/$GRUPO/repos/$ORG/$REPO_NAME" -f permission="push" > /dev/null

    echo "✅ $REPO_NAME configurado con éxito."
done

echo "--------------------------------------------------"
echo "🎉 ¡Todos los repositorios y grupos fueron creados correctamente!"
