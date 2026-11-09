# PasoFirme: Módulo de Demostración Spring Cloud Config

Este submódulo implementa una arquitectura distribuida de **configuración centralizada y dinámica en caliente** basada en **Spring Cloud Config** y respaldada por un repositorio remoto de **GitHub**, contextualizada en el dominio comercial de calzado de **PasoFirme**.

---

## 1. Arquitectura y Componentes de la Demo

```
                                  GitHub
                   (Dan101111111/pasofirme-config-repo)
                                    │
                                    │ HTTPS (Git clone/pull)
                                    ▼
                     ┌──────────────────────────────┐
                     │   config-server-demo (18888) │
                     │  Spring Cloud Config Server  │
                     └──────────────┬───────────────┘
                                    │
                 ┌──────────────────┼──────────────────┐
                 │                  │                  │
                 ▼                  ▼                  ▼
        ┌─────────────────┐┌─────────────────┐┌─────────────────┐
        │  catalogo-demo  ││  ofertas-demo   ││   envios-demo   │
        │  (Puerto 18881) ││  (Puerto 18882) ││  (Puerto 18883) │
        │  GET /api/demo  ││  GET /api/demo  ││  GET /api/demo  │
        │ POST /refresh   ││ POST /refresh   ││ POST /refresh   │
        └─────────────────┘└─────────────────┘└─────────────────┘
```

| Componente | Puerto Host | Paquete Java Base | Función en la Demostración |
|---|:---:|---|---|
| **`config-server-demo`** | **18888** | `com.pasofirme.configdemo.server` | Obtiene propiedades desde GitHub vía Git protocol y las entrega a los clientes. |
| **`catalogo-demo`** | **18881** | `com.pasofirme.configdemo.catalogo` | Cliente Spring Cloud Config. Expone colecciones y temporada de calzado. |
| **`ofertas-demo`** | **18882** | `com.pasofirme.configdemo.ofertas` | Cliente Spring Cloud Config. Expone descuentos y promociones de calzado. |
| **`envios-demo`** | **18883** | `com.pasofirme.configdemo.envios` | Cliente Spring Cloud Config. Expone cobertura y tiempos de despacho. |

---

## 2. Requisitos Previos

- **Docker Desktop**: Motor Docker 20+ y Docker Compose v2+ en ejecución.
- **Git**: Cliente Git instalado para clonación y edición.
- **Acceso a Internet**: Conexión saliente a GitHub (`github.com`), Docker Hub y Maven Central.
- **Puertos Disponibles**: `18888`, `18881`, `18882` y `18883` libres en la máquina anfitriona.
- *(Opcional para modo local)*: JDK 21 LTS y terminal PowerShell.

---

## 3. Repositorios Oficiales en GitHub

- **Repositorio de Configuración (Propiedades)**:
  `https://github.com/Dan101111111/pasofirme-config-repo.git` (Público, rama `main`).
- **Repositorio de Código (Proyecto Completo)**:
  `https://github.com/Dan101111111/pasofirme-cloud-config.git` (Rama `main`).

---

## 4. Despliegue Rápido desde Cero con Docker Compose (Recomendado)

### Paso 0: Clonar el Repositorio de Código
En una terminal en la máquina anfitriona, clone el repositorio completo y acceda a la carpeta raíz:

```powershell
git clone https://github.com/Dan101111111/pasofirme-cloud-config.git
cd pasofirme-cloud-config
```

Todos los comandos siguientes se ejecutan desde la **raíz del repositorio**:

### Paso 1: Configurar Variables de Entorno
Cree el archivo `.env` dentro de `demo-config/` a partir de la plantilla:

```powershell
Copy-Item demo-config/.env.example demo-config/.env
```

Contenido del archivo `demo-config/.env`:
```properties
CONFIG_GIT_URI=https://github.com/Dan101111111/pasofirme-config-repo.git
DEMO_PROFILE=dev
```

### Paso 2: Validar la Sintaxis del Compose
```powershell
docker compose --env-file demo-config/.env -f demo-config/compose.yaml config --quiet
```

### Paso 3: Construir e Iniciar los Contenedores
```powershell
docker compose --env-file demo-config/.env -f demo-config/compose.yaml up -d --build
```
> [!NOTE] Primera Descarga y Compilación
> En la primera ejecución, Docker descargará las imágenes base de Eclipse Temurin y compilará los cuatro proyectos mediante Maven Wrapper multietapa dentro de los contenedores. Este proceso suele tomar entre 1 y 2 minutos.

### Paso 4: Comprobar el Estado de Salud de los Contenedores
```powershell
docker compose --env-file demo-config/.env -f demo-config/compose.yaml ps
```
Los 4 servicios deben reportar estado **`Up (healthy)`**.

### Paso 5: Detener y Limpiar la Demostración
```powershell
docker compose --env-file demo-config/.env -f demo-config/compose.yaml down
```

---

## 5. Endpoints de Verificación Rápida

| Servicio | Tipo | Método | URL |
|---|---|:---:|---|
| **Config Server** | Salud Técnica | `GET` | `http://localhost:18888/actuator/health` |
| **Config Server** | Consulta Git Catálogo | `GET` | `http://localhost:18888/catalogo-demo/dev/main` |
| **Catálogo Demo** | Negocio Consolidado | `GET` | `http://localhost:18881/api/demo` |
| **Catálogo Demo** | Refresco Dinámico | `POST` | `http://localhost:18881/actuator/refresh` |
| **Ofertas Demo** | Negocio Consolidado | `GET` | `http://localhost:18882/api/demo` |
| **Ofertas Demo** | Refresco Dinámico | `POST` | `http://localhost:18882/actuator/refresh` |
| **Envíos Demo** | Negocio Consolidado | `GET` | `http://localhost:18883/api/demo` |
| **Envíos Demo** | Refresco Dinámico | `POST` | `http://localhost:18883/actuator/refresh` |

### Script de Verificación Automatizada:
Para comprobar de solo lectura todos los servicios en un único paso:
```powershell
powershell -ExecutionPolicy Bypass -File demo-config/scripts/verificar-demo.ps1
```

---

## 6. Alternativa Local sin Docker (Java 21 + Maven Wrapper)

Si prefiere ejecutar la demo directamente sobre el sistema operativo:

1. **Iniciar Config Server**:
   ```powershell
   cd demo-config/config-server-demo
   .\start-server.ps1
   ```
2. **Iniciar Clientes**:
   ```powershell
   cd ../catalogo-demo; .\start-catalogo.ps1
   cd ../ofertas-demo;  .\start-ofertas.ps1
   cd ../envios-demo;   .\start-envios.ps1
   ```
3. **Detener Servicios**:
   Ejecute `.\stop-server.ps1`, `.\stop-catalogo.ps1`, `.\stop-ofertas.ps1` y `.\stop-envios.ps1` en sus respectivas carpetas.

