# 🛠️ Sistema de Entregas - Ingeniería de Software I

Este repositorio contiene un conjunto de scripts en Bash diseñados para automatizar la gestión de repositorios, grupos y entregas.

Todos los scripts operan sin necesidad de herramientas de terceros (como RepoBee o Classmoji), interactuando directamente con la API de GitHub mediante **Github CLI**

## 📋 Requisitos Previos

Para que cualquier miembro del equipo docente pueda ejecutar estos scripts, debe tener instalado y configurado lo siguiente:

1. **GitHub CLI (`gh`)**: La herramienta oficial de línea de comandos de GitHub.
   * Instalación: [https://cli.github.com/](https://cli.github.com/)
2. **Autenticación**: Haber iniciado sesión en la terminal con una cuenta que posea rol de **Owner** (Propietario) en la organización de la materia.
   * Comando: `gh auth login`
3. **Dependencias adicionales**: Utilidades estándar de Unix/Linux (`jq`, `curl`, `date`, `tail`).

---

## 📂 Archivos de Datos (Inputs)

Los scripts se alimentan de dos archivos de texto que deben estar actualizados antes de ejecutar cualquier comando:

### 1. `alumnos.txt`
Un archivo de texto plano utilizado **únicamente para enviar invitaciones** a la organización. Debe contener un nombre de usuario de GitHub por línea.
```text
usuario_alumno1
usuario_alumno2
```

### 2. `grupos.csv`
Un archivo CSV utilizado para la **creación de equipos, repositorios y verificación de entregas**. Debe contener un encabezado y los usuarios separados por comas.
```text
grupo,alumno1,alumno2
GRUPO01,usuario_alumno1,usuario_alumno2
```
## 🚀 Uso de los Scripts

A continuación, se detalla el propósito de cada script y cómo ejecutarlo.

**IMPORTANTE**: Todos los scripts contienen variables de configuración al inicio (como `ORG`, `ASSIGNMENT_PREFIX`, `TEMPLATE_REPO`) que deben ajustarse al ejercicio actual antes de ejecutarlos.

### 1. `invitar_alumnos.sh`

**Propósito**: Envía invitaciones masivas a los estudiantes para unirse a la organización de GitHub como Members. Es vital que los alumnos acepten esta invitación antes de que se creen los repositorios grupales.

**Funcionamiento interno**: Lee `alumnos.txt`, resuelve el ID numérico interno de GitHub de cada usuario (para evitar errores HTTP 422) y realiza un POST a la API REST de GitHub.

**Uso**:
```bash
./invitar_alumnos.sh
```

### 1.1. `invitar_alumnos_auto.py`

**Propósito**: Versión alternativa que envía las invitaciones leyendo los usuarios desde las respuestas de la encuesta inicial. Para esto, es necesario indicar la URL de la planilla (publicando en formato web la hoja en cuestión, en formato `.csv`) en la constante `SHEET_URL`.

**Funcionamiento interno**: Equivalente al script anterior, pero leyendo los nombres de usuarios con [pandas](https://pandas.pydata.org/), para poder "arreglar" aquellos que hayan enviado la URL completa u algún otro formato poco común.

**Uso**:
```bash
python invitar_alumnos_auto.py
```

### 2. `crear_repositorios.sh`

**Propósito**: Automatiza la creación de la infraestructura de entregas para un nuevo ejercicio.

**Funcionamiento interno**: Lee `grupos.csv` y por cada línea:

1. Crea un Team en GitHub con el nombre del grupo (ej. `GRUPO01`).
2. Agrega a los alumnos (alumno1, alumno2) a ese Team.
3. Crea un repositorio privado clonando el repositorio `TEMPLATE_REPO`
4. Asigna permisos de Escritura (Push) al Team sobre su repositorio correspondiente.

**Uso**:
```bash
./crear_repositorios.sh
```

### 3. `verificar_entregas.sh`

**Propósito**: Revisa rápidamente qué grupos entregaron el ejercicio y cuáles mantienen sus repositorios vacíos.

**Funcionamiento interno**: Utiliza **GraphQL** para consultar velozmente la cantidad de commits en cada repositorio (sin descargarlos). Si la cantidad de commits es igual a 1, asume que solo existe el commit inicial de la plantilla ("Initial commit") y clasifica el ejercicio como "No entregado". Si es mayor a 1, lo marca como "Entregado".

**Uso**:
```bash
./verificar_entregas.sh
```

### 4. `verificar_tardias.sh`

**Propósito**: Identifica qué grupos hicieron commits después de la fecha límite establecida.

**Funcionamiento interno**: Utiliza GraphQL para extraer la fecha exacta del último commit realizado por los alumnos (en UTC) y la compara matemáticamente convirtiéndola a la zona horaria local de Argentina contra la fecha límite ingresada como parámetro.

**Uso**: (Requiere pasar la fecha límite como argumento)
```bash
./verificar_tardias.sh "2026-08-11 18:00:00"
```

### 5. `descargar_entregas.sh`

**Propósito**: Clona ("pullea") todos los repositorios del ejercicio masivamente a la computadora local.

**Funcionamiento interno**: Crea un directorio local (`entregas_codigo-repetido`). Si es la primera vez que se ejecuta, hace un `git clone` de cada grupo. Si la carpeta del grupo ya existe, ejecuta un `git pull --quiet` para actualizar únicamente los últimos cambios.

**Uso**:
```bash
./descargar_entregas.sh
```

### Consideraciones finales sobre el Dashboard de GitHub:

Al ejecutar `crear_repositorios.sh`, el algoritmo de GitHub anclará todos los repositorios creados en la barra lateral izquierda (Top Repositories) de la cuenta de quien corrió el script. Para evitar "contaminar" cuentas personales, se recomienda ejecutar estos comandos utilizando una cuenta alternativa.
