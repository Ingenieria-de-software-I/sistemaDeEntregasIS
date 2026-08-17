import pandas as pd
import subprocess
import sys

# --- Configuración ---
ORG = "Ingenieria-de-software-I-alumnos"
SHEET_URL = "TU_LINK_PUBLICADO_AQUI"
COLUMNA_USUARIOS = "Cuenta de GitHub" 

def ejecutar_comando_gh(comando):
    """Ejecuta un comando en la terminal y devuelve la salida y los errores."""
    resultado = subprocess.run(comando, capture_output=True, text=True)
    return resultado

def main():
    print(f"Iniciando invitaciones para la organización: {ORG}...")
    print("--------------------------------------------------")

    # 1. Leer los datos en vivo desde Google Sheets y limpiar usuarios "raros"
    try:
        df = pd.read_csv(SHEET_URL)
        
        # Extraer, limpiar espacios, remover URLs de GitHub y barras finales
        usuarios = (
            df[COLUMNA_USUARIOS]
            .dropna()
            .astype(str)
            .str.strip()
            .str.replace(
                r'^(?:https?://)?(?:www\.)?github\.com/', 
                '', 
                case=False, 
                regex=True
            )
            .str.rstrip('/')
        )
        
    except Exception as e:
        print(f"❌ Error al leer la planilla: {e}")
        print("Verificá que el link sea correcto y que el Sheet esté publicado como CSV.")
        sys.exit(1)

    # 2. Iterar sobre cada alumno
    for alumno in usuarios:
        if not alumno:
            continue

        print(f"Procesando a: {alumno}...")

        # --- Paso A: Obtener el ID numérico del usuario ---
        comando_id = ["gh", "api", f"/users/{alumno}", "-q", ".id"]
        resultado_id = ejecutar_comando_gh(comando_id)

        # Validar si el comando falló (ej. usuario no existe o la regex no lo limpió bien)
        if resultado_id.returncode != 0 or "Not Found" in resultado_id.stderr:
            print(f"❌ Error: El usuario de GitHub '{alumno}' no existe.")
            continue

        # Limpiar el ID obtenido
        user_id = resultado_id.stdout.strip()

        # --- Paso B: Enviar la invitación usando el ID ---
        comando_invitacion = [
            "gh", "api",
            "--method", "POST",
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            f"/orgs/{ORG}/invitations",
            "-F", f"invitee_id={user_id}",
            "-f", "role=direct_member"
        ]

        resultado_invitacion = ejecutar_comando_gh(comando_invitacion)
        
        # Combinamos stdout y stderr para buscar las respuestas de GitHub
        salida_completa = resultado_invitacion.stdout + resultado_invitacion.stderr

        # --- Paso C: Analizar la respuesta ---
        if '"id":' in salida_completa:
            print(f"✅ Invitación enviada exitosamente a {alumno}.")
        elif "already a part of this organization" in salida_completa:
            print(f"⚠️ {alumno} ya es miembro de la organización.")
        elif "already has a pending invitation" in salida_completa:
            print(f"⚠️ {alumno} ya tiene una invitación pendiente. Debe revisar su email.")
        else:
            print(f"❌ Falló la invitación para {alumno}. Detalle del error:")
            print(salida_completa)

    print("--------------------------------------------------")
    print("🎉 Proceso finalizado.")

if __name__ == "__main__":
    main()