#!/bin/bash

# Configuración
ORG="Ingenieria-de-software-I-alumnos"
USER_FILE="alumnos.txt"

# Verificar que el archivo exista
if [ ! -f "$USER_FILE" ]; then
    echo "Error: No se encontró el archivo $USER_FILE"
    exit 1
fi

echo "Iniciando invitaciones para la organización: $ORG..."
echo "--------------------------------------------------"

# Leer el archivo línea por línea
while IFS= read -r ALUMNO || [[ -n "$ALUMNO" ]]; do
    
    # Limpiar posibles espacios en blanco en el nombre de usuario
    ALUMNO=$(echo "$ALUMNO" | xargs)
    
    # Ignorar líneas vacías
    if [ -z "$ALUMNO" ]; then
        continue
    fi

    echo "Enviando invitación a: $ALUMNO..."

    # Enviar la invitación a la organización vía API usando GitHub CLI
    # Usamos silenciador (> /dev/null) para errores para manejar el output limpio
    gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/orgs/$ORG/invitations" \
      -F invitee_id="$(gh api /users/$ALUMNO -q .id)" \
      -f role="direct_member" > /dev/null 2>&1

    # Verificar si el comando fue exitoso
    if [ $? -eq 0 ]; then
        echo "✅ Invitación enviada exitosamente."
    else
        echo "❌ Error al invitar. (Posibles causas: el usuario no existe, ya es miembro, o ya tiene una invitación pendiente)."
    fi

done < "$USER_FILE"

echo "--------------------------------------------------"
echo "🎉 Proceso de invitaciones finalizado."
