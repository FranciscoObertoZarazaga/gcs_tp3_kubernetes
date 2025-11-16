# Informe de Implementación de SonarQube

## Introducción

Este informe documenta la implementación de SonarQube como herramienta de análisis estático de código dentro del proceso de desarrollo de una startup con un proyecto en etapa temprana. Se detalla la elección de la edición Community, el diseño de infraestructura basada en contenedores, la integración con GitHub Actions y las estrategias adoptadas para asegurar la calidad del código sin comprometer velocidad ni costos.

---

## Desarrollo de las actividades

### Investigación

A continuación, se detallan las características disponibles en las distintas ediciones de SonarQube, lo cual fue fundamental para elegir la versión adecuada según las necesidades del proyecto:

| Característica / Edición                         | Community | Developer | Enterprise | Data Center |
|--------------------------------------------------|-----------|-----------|-------------|-------------|
| **Licencia**                                     | Gratuita (Open Source) | Comercial | Comercial | Comercial |
| **Análisis de código**                           | ✅         | ✅         | ✅           | ✅           |
| **Lenguajes soportados**                         | ~15 (Java, JS, etc.) | 25+ (incluye C, C++, C#, Swift, etc.) | 25+ | 25+ |
| **Detección de bugs, code smells, vulnerabilidades** | ✅         | ✅         | ✅           | ✅           |
| **Soporte para ramas**                           | ❌         | ✅         | ✅           | ✅           |
| **Soporte para PR (pull requests)**              | ❌         | ✅         | ✅           | ✅           |
| **Análisis de infraestructura como código (IaC)**| ❌         | ✅ (Terraform, Kubernetes YAML, etc.) | ✅ | ✅ |
| **Gestión de múltiples proyectos**               | Básico     | Básico     | Avanzado (portales, agrupaciones, etc.) | Avanzado |
| **Enterprise Governance / Reporting**            | ❌         | ❌         | ✅ (reportes PDF, historial, etc.) | ✅ |
| **Clustering / Alta disponibilidad**             | ❌         | ❌         | ❌           | ✅ (con balanceo de carga, tolerancia a fallos) |
| **Integraciones DevOps**                         | Limitadas  | Ampliadas  | Ampliadas    | Ampliadas    |
| **Costo**                                        | Gratuito   | Pago por líneas de código | Pago (más costoso que Developer) | Pago (más costoso que Enterprise) |

**Justificación de la elección de la edición Community**

Dado que el proyecto se encuentra en una etapa inicial y forma parte del desarrollo de un **MVP (Producto Mínimo Viable)** dentro de una **startup**, se priorizó el uso de herramientas gratuitas y de código abierto para minimizar los costos sin sacrificar la calidad técnica. La edición **Community** de SonarQube cumple con los requerimientos esenciales del análisis de código, detección de bugs y vulnerabilidades, y soporta los lenguajes utilizados actualmente en el proyecto.

#### Contenedores Docker

- Se investigaron las imágenes disponibles en [Docker Hub - SonarQube oficial](https://hub.docker.com/_/sonarqube).
  
- Se optó por la imagen **LTS Community**, por ser estable y adecuada para el proyecto. En particular se utilizó la versión:
  [lts-community - sha256-579a7e...](https://hub.docker.com/layers/library/sonarqube/lts-community/images/sha256-579a7e9123e0cc39715be70d3ee570f23cc1ee21e3fae94602393ac834c9090b)

- Para realizar los análisis de código desde línea de comandos se utilizó el contenedor oficial del **Sonar Scanner CLI**:
  [sonar-scanner-cli - sha256-7462f1...](https://hub.docker.com/layers/sonarsource/sonar-scanner-cli/11/images/sha256-7462f132388135e32b948f8f18ff0db9ae28a87c6777f1df5b2207e04a6d7c5c)

## Infraestructura

La infraestructura fue diseñada utilizando contenedores Docker para desplegar un entorno reproducible y aislado donde ejecutar el servidor SonarQube. Esta aproximación permite mantener buenas prácticas de calidad de código sin necesidad de instalaciones manuales ni dependencias locales.

### Contenedor: SonarQube

**Base:** Imagen oficial `sonarqube:lts-community`

**Propósito:**  
Este contenedor levanta el servidor SonarQube, el cual expone una interfaz web (en el puerto `SONAR_PORT`) donde se pueden visualizar los resultados del análisis de código, gestionar proyectos y configurar reglas de calidad.

**Configuración técnica destacada:**

- **Puertos expuestos:** `SONAR_PORT:SONAR_PORT`
- **Volúmenes persistentes:**  
  - `data`: para persistencia de resultados de análisis  
  - `logs`: para mantener registros del servidor  
  - `extensions`: para guardar plugins u otras extensiones  
- **Variables de entorno** 

**Uso**

```sh
docker-compose down
docker-compose build
docker-compose up -d
```

![Pasted image 20250603214522](https://github.com/user-attachments/assets/7524219d-67f6-434e-9d66-bfcace9ba85f)

### Configuración inicial del servidor

Con el objetivo de automatizar tareas críticas de configuración y mejorar la seguridad del entorno desde el inicio, se desarrolló un script de shell que realiza la configuración inicial del servidor SonarQube una vez que este se encuentra operativo.

1. **Esperar a que el servidor SonarQube esté completamente levantado.**
2. **Cambiar automáticamente la contraseña del usuario `admin` por una personalizada.**

Este script es ejecutado como parte del `entrypoint`, dentro de un contenedor auxiliar `setup`.

![Pasted image 20250603214614](https://github.com/user-attachments/assets/e14b9be0-b8bb-4922-b643-f934d55143fd)

### Contenedor: Sonar Scanner CLI

**Base:** Imagen oficial `sonarsource/sonar-scanner-cli:11`, extendida con un `Dockerfile` personalizado.

**Propósito:**  
Este contenedor ejecuta el análisis de código fuente y envía los resultados al servidor SonarQube.

**Configuración**

- Monta dinámicamente el directorio del código fuente.
- Usa variables de entorno para configurar:
  - URL del servidor (`SONAR_HOST_URL`)
  - Token de autenticación (`SONAR_TOKEN`)
- Ejecuta automáticamente el análisis al iniciarse.

**Uso**

```sh
docker-compose -f docker-compose.scanner.yml down -v 
docker-compose -f docker-compose.scanner.yml up --force-recreate --build -d
```

![Pasted image 20250603220446](https://github.com/user-attachments/assets/79acc0f3-eee6-4581-ba02-fb40da2084da)

**Ventajas del diseño**

- **Desacoplamiento:** El análisis se ejecuta por demanda, sin afectar al servidor.
- **Reutilización:** Puede usarse en múltiples proyectos.
- **Escalabilidad:** Fácil de integrar a pipelines de CI/CD.
- **Seguridad:** Utiliza tokens en lugar de contraseñas.
- **Soporte para múltiples proyectos:** Permite ejecutar análisis simultáneos o independientes para distintos proyectos.
- **Portabilidad:** El contenedor puede ejecutarse tanto en entornos locales como en servidores de producción o CI, sin necesidad de modificaciones.
  

## Gestión de Proyectos

Para facilitar el análisis de múltiples proyectos con configuraciones independientes, se estructuró un esquema de carpetas bajo el directorio `projects.dist`, que actúa como plantilla reutilizable.

### Estructura base

La estructura de `projects.dist` es la siguiente:

```
projects.dist/
└───project_1/
    │   .env.dist
    │   sonar-project.properties
    ├───src/    (se genera durante del análisis)
    └───logs/   (se genera luego del análisis)
```

Cada subcarpeta dentro de `projects.dist` representa un proyecto candidato a ser analizado por SonarQube. Esta carpeta no se modifica directamente, sino que se utiliza como **base para crear nuevas instancias de análisis**.

### Uso

1. **Copiar la plantilla:**

   Antes de analizar, se copia `projects.dist` a un nuevo directorio llamado `projects`. Dentro de él se pueden crear tantas carpetas como proyectos se deseen analizar:

   ```sh
   cp -r projects.dist projects
   mv projects/project_1 projects/<project_name_1>
   ```

2. **Personalizar cada proyecto:**

   En cada carpeta del nuevo `projects/` se deben configurar:

   - `sonar-project.properties`: con los parámetros del análisis específicos al proyecto.
   - `.env.dist`: renombrado y adaptado si se desea usar variables de entorno personalizadas (por ejemplo, para tokens o `project key`).

3. **Analizar un proyecto:**

   El contenedor del **Sonar Scanner** se ejecuta apuntando a cada una de estas carpetas, permitiendo así análisis individualizados para múltiples proyectos.

### Directorios importantes en cada proyecto

- `src/`: contiene el código fuente del proyecto que será analizado.
- `logs/`: se genera automáticamente junto al análisis y almacena el resultado del proceso de escaneo con SonarScanner.

---

### Ejecución paralela de análisis

Se dispone de un script de automatización que ejecuta los análisis en paralelo.

## Plantilla para Análisis Remoto (`remote.dist`)

La carpeta `remote.dist` fue diseñada como una **plantilla portable** que permite integrar SonarQube en proyectos externos mediante análisis remotos. A diferencia de `projects.dist`, esta plantilla **se copia dentro del propio repositorio del proyecto a analizar**, lo que permite aprovechar su integración con sistemas de CI/CD y ejecutar análisis directamente desde pipelines.

### Estructura base

```
remote.dist/
│   .env.sonar.dist
│   docker-compose.sonar.yml
│   Dockerfile.sonar
│   run-scanner.sh
│   sonar-project.properties
│   sonar-project.properties.dist
│
└───.github/
    └───workflows/
            sonarqube.yml
```

### Componentes clave

- `.env` y `.env.sonar.dist`: Definen variables de entorno necesarias para configurar el entorno de análisis, como el token, URL del servidor SonarQube y el `projectKey`.
- `docker-compose.sonar.yml`: Orquesta la ejecución del scanner en contenedor. Está pensado para ser invocado desde CI.
- `Dockerfile.sonar`: Imagen personalizada para ejecutar `sonar-scanner` con las configuraciones apropiadas.
- `run-scanner.sh`: Script que prepara el entorno y ejecuta el análisis de código.
- `sonar-project.properties` / `.dist`: Archivo principal de configuración del análisis SonarQube. Se adapta al proyecto donde se copie la plantilla.
- `.github/workflows/sonarqube.yml`: Workflow de GitHub Actions para ejecutar análisis automáticamente al hacer push, PR o en eventos configurados.

### Uso

1. **Copiar al repositorio objetivo:**

   Esta plantilla debe copiarse directamente dentro del repositorio del proyecto que se desea analizar. Por ejemplo:

   ```
   cp -r remote.dist/* /ruta/a/mi/proyecto/
   ```

2. **Configurar variables y propiedades:**

   - Rellenar `.env` y/o adaptar `.env.sonar.dist`.
   - Personalizar `sonar-project.properties`.

2. **Ejecutar análisis:**

   - Automáticamente con GitHub Actions al hacer push o pull request, gracias al workflow `sonarqube.yml`.

## Despliegue en Producción

Como parte de la estrategia de integración continua (CI), se realizó el despliegue del servidor SonarQube en un entorno de producción. Esto permite que los proyectos integrados mediante la plantilla `remote.dist` puedan ejecutar análisis automáticos y remotos.

![Pasted image 20250603220656](https://github.com/user-attachments/assets/15b1e84e-db6f-4845-8882-7499d4c2e4be)

## Configuración del Servidor SonarQube

### 1. Generación del Token de Proyecto

Cada proyecto que se analiza requiere un token de autenticación que se utiliza desde el cliente `sonar-scanner`. Para obtenerlo:

- Se ingresó a la interfaz web del servidor.
- Se generó un token seguro para autenticación y se incluyó en la variable de entorno `SONAR_TOKEN`.

![Pasted image 20250603220735](https://github.com/user-attachments/assets/38a8513f-16fd-4157-a672-4597c55424cc)

### 2. Definición del Quality Gate

Se seleccionó y adaptó un **Quality Gate** (puerta de calidad) que actúa como filtro para determinar si un análisis pasa o falla según criterios de calidad (bugs, vulnerabilidades, cobertura, duplicación, etc.).

- Inicialmente se utilizó el `Sonar Way` como base.
- Posteriormente se ajustaron algunos umbrales para permitir una evaluación más realista de proyectos nuevos que aún no tienen estándares completamente aplicados.

![Pasted image 20250603220808](https://github.com/user-attachments/assets/59a85644-7e4c-42d4-8070-7a19dff4b7db)

### 3. Selección del Quality Profile (Python)

Para análisis de código Python, se definió como **perfil de calidad por defecto** el perfil de reglas de `Sonar Way (Python)`, que incluye chequeos generales de estilo, errores y patrones de diseño.

![Pasted image 20250603220847](https://github.com/user-attachments/assets/cb5f4620-eb51-45a8-8c6b-bb4e5cd64902)

### 4. Revisión de Reglas de Calidad

Las reglas activas para Python se mantuvieron según las sugerencias de SonarQube.

![Pasted image 20250603220925](https://github.com/user-attachments/assets/bf72525c-093e-4eec-9f15-5b94b1f6de0d)

### 5. Ejecución del Primer Análisis

Con la configuración inicial completa, se ejecutó el primer análisis desde un contenedor `sonar-scanner`:

```bash
docker compose -p sonarscanner_qa -f docker-compose.scanner.yml down -v 
docker compose -p sonarscanner_qa -f docker-compose.scanner.yml up --force-recreate --build -d
```

![Pasted image 20250603221119](https://github.com/user-attachments/assets/629c83be-6980-4c9d-ab9f-786fecd1b71f)

### 6. Ajuste del Quality Gate según la Situación Inicial

Debido a que el código analizado provenía de una base ya en desarrollo, se identificaron múltiples issues al ejecutar el primer escaneo. Para evitar bloqueos innecesarios:

- Se ajustó temporalmente el Quality Gate para reflejar criterios mínimos aceptables en esta fase.
- Se priorizó permitir la integración continua del código mientras se planifica una mejora progresiva de la calidad.

Este enfoque permite aplicar SonarQube desde el inicio sin frenar el avance del proyecto, promoviendo una cultura de mejora continua.

![Pasted image 20250603221031](https://github.com/user-attachments/assets/3b325e92-5d4a-4c31-9e12-bbd5b1b54aab)

## Integración Continua con GitHub Actions

Para asegurar la calidad del código desde el flujo de trabajo colaborativo, se implementó una acción de GitHub Actions que ejecuta automáticamente el análisis de SonarQube cuando se genera un Pull Request hacia la rama principal (`main`) en un proyecto de la empresa.

### Disparador

La acción está configurada para activarse con el siguiente evento:

```yaml
on:
  pull_request:
    branches:
      - main
```

Esto permite que cada nueva contribución al repositorio sea analizada antes de integrarse a la rama principal, evitando introducir nuevos errores, vulnerabilidades o code smells.

> ⚠️ **Advertencia:**  
> El análisis de SonarQube está configurado para comparar los resultados contra la rama `main`, ya que la edición **Community** no soporta análisis de múltiples ramas ni Pull Requests completos.  

### Workflow: SonarQube Quality Gate Check

### 1. **Configuración de variables de entorno**

```yaml
- name: 🌍 Set environment variables
```

Carga variables sensibles y de configuración como `SONAR_TOKEN`, `SONAR_HOST`, `SONAR_PROJECT_KEY`, y la carpeta fuente desde los `secrets` de GitHub.

### 2. **Ejecución del análisis en contenedor**

```yaml
- name: 🐳 Build and Run SonarQube container
```

Levanta el contenedor definido en `docker-compose.sonar.yml` que ejecuta el `sonar-scanner` con los parámetros definidos. Esta ejecución se detiene si el contenedor finaliza con error, o si el análisis **no cumple con el Quality Gate** configurado en el servidor.

Esto asegura que no se puedan fusionar cambios que degraden la calidad del código, actuando como una barrera automatizada dentro del flujo de CI.

![Pasted image 20250603221312](https://github.com/user-attachments/assets/f7a41483-9084-4e11-ad0a-e1a820808351)

---
## Resultados y aprendizajes

Se logró desplegar SonarQube en un entorno controlado y productivo, ejecutar análisis exitosos para múltiples proyectos, y validar flujos de CI automáticos que integran escaneo y control de calidad. Se aprendió a equilibrar exigencia y flexibilidad inicial mediante ajustes progresivos en los Quality Gates, permitiendo una adopción realista en bases de código existentes.

![Pasted image 20250603221405](https://github.com/user-attachments/assets/1156e785-7867-4e86-9e85-09d249d18a87)

---
## Conclusiones y objetivos para las siguientes fases

SonarQube demostró ser una herramienta adecuada y escalable para nuestro contexto. A futuro, se planifica:

- Abordar progresivamente los findings detectados por SonarQube, realizando cambios en el código para mejorar la calidad técnica y reducir la deuda técnica acumulada.
    
- Elevar y actualizar gradualmente los umbrales de calidad.
    
- Documentar prácticas internas sobre revisión y corrección de findings.
    

Este proceso apunta a establecer una cultura de calidad continua desde etapas tempranas del desarrollo.
