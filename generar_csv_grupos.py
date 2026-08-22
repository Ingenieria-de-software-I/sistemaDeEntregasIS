import pandas as pd
import sys

# --- Configuración ---
SHEET_URL = "TU_LINK_PUBLICADO_AQUI" 

def limpiar_usuario(serie):
    """Aplica la limpieza de espacios, URLs de GitHub y caracteres nulos."""
    return (
        serie
        .astype(str)
        .str.strip()
        .str.replace(
            r'^(?:https?://)?(?:www\.)?github\.com/', 
            '', 
            case=False, 
            regex=True
        )
        .str.rstrip('/')
        .replace('nan', '')
    )

def main():
    print("📥 Descargando y procesando la planilla de Google Sheets...")
    
    try:
        df = pd.read_csv(SHEET_URL)
    except Exception as e:
        print(f"❌ Error al leer la planilla: {e}")
        print("Verificá que el link sea correcto y que el Sheet esté publicado como CSV.")
        sys.exit(1)

    # Nombres de las columnas
    col_user1 = "Usuario de Github de padrón 1"
    col_user2 = "Usuario de Github de padrón 2"

    # Crear un nuevo DataFrame estructurado para el script de Bash
    df_grupos = pd.DataFrame()

    # 1. Generar la columna de Grupos Incrementales (GRUPO01, GRUPO02...)
    cantidad_grupos = len(df)
    df_grupos['grupo'] = [f"GRUPO{str(i).zfill(2)}" for i in range(1, cantidad_grupos + 1)]

    # 2. Extraer y limpiar los usuarios de GitHub
    df_grupos['alumno1'] = limpiar_usuario(df[col_user1])

    
    if col_user2 in df.columns:
        df_grupos['alumno2'] = limpiar_usuario(df[col_user2])
    else:
        df_grupos['alumno2'] = ""

    # 3. Exportar el archivo final
    archivo_salida = "grupos.csv"
    df_grupos.to_csv(archivo_salida, index=False)

    print(f"✅ Archivo '{archivo_salida}' generado exitosamente con {cantidad_grupos} grupos.")
    print("\nVista previa de los primeros registros:")
    print(df_grupos.head())

if __name__ == "__main__":
    main()