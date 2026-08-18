import pandas as pd
import subprocess
import sys
import os

# --- Configuración ---
ORG = "Ingenieria-de-software-I-alumnos"
SHEET_URL = "TU_LINK_PUBLICADO_AQUI"
COLUMNA_USUARIOS = "Cuenta de GitHub" 
ARCHIVO_HISTORIAL = "ya_invitados.txt"

def ejecutar_comando_gh(comando):
    """Ejecuta un comando en la terminal y devuelve la salida y los errores."""
    resultado = subprocess.run(comando, capture_output=True, text=True)
    return resultado

def cargar_historial():
    """Lee el archivo de historial y devuelve un set con los usuarios ya procesados."""
    if os.path.exists(ARCHIVO_HISTORIAL):
        with open(ARCHIVO_HISTORIAL, "r", encoding="utf-8") as f:
            # Usamos un 'set' para que las búsquedas luego sean más rápidas
            return set(line.strip() for line in f if line.strip())
    return set()

def registrar_en_historial(usuario):
    """Agrega un usuario al archivo de historial para no volver a procesarlo."""
    with open(ARCHIVO_HISTORIAL, "a", encoding="utf-8") as f:
        f.write(f"{usuario}\n")

def main():
    print(f"Iniciando invitaciones para la organización: {ORG}...")
    print("--------------------------------------------------")

    # Cargar los usuarios a los que ya se les procesó la invitación
    historial = cargar_historial()
    if historial:
        print(f"📂 Historial encontrado: {len(historial)} usuarios ya fueron procesados anteriormente.")
    else:
        print("📂 No se encontró historial previo. Se creará uno nuevo.")

    # 1. Leer los datos en vivo desde Google Sheets y limpiar usuarios
    try:
        df = pd.read_csv(SHEET_URL)
        
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
            
        # Verificar si el alumno ya está en el historial
        if alumno in historial:
            print(f"⏭️  Omitiendo a: {alumno} (ya registrado en el historial).")
            continue

        print(f"Procesando a: {alumno}...")

        # --- Paso A: Obtener el ID numérico del usuario ---
        comando_id = ["gh", "api", f"/users/{alumno}", "-q", ".id"]
        resultado_id = ejecutar_comando_gh(comando_id)

        if resultado_id.returncode != 0 or "Not Found" in resultado_id.stderr:
            print(f"❌ Error: El usuario de GitHub '{alumno}' no existe.")
            continue

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
        salida_completa = resultado_invitacion.stdout + resultado_invitacion.stderr

        # --- Paso C: Analizar la respuesta y actualizar historial ---
        if '"id":' in salida_completa:
            print(f"✅ Invitación enviada exitosamente a {alumno}.")
            registrar_en_historial(alumno)
            historial.add(alumno) # Lo agregamos a la memoria actual también
            
        elif "already a part of this organization" in salida_completa:
            print(f"⚠️ {alumno} ya es miembro de la organización.")
            registrar_en_historial(alumno)
            historial.add(alumno)
            
        elif "already has a pending invitation" in salida_completa:
            print(f"⚠️ {alumno} ya tiene una invitación pendiente. Debe revisar su email.")
            registrar_en_historial(alumno)
            historial.add(alumno)
            
        else:
            print(f"❌ Falló la invitación para {alumno}. Detalle del error:")
            print(salida_completa)
            # No lo registramos en el historial para que lo intente de nuevo la próxima vez

    print("--------------------------------------------------")
    print("🎉 Proceso finalizado.")

if __name__ == "__main__":
    main()
