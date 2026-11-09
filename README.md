# PasoFirme: Sistema Distribuido de Gestión de Zapatos

**PasoFirme** es una solución basada en arquitectura de microservicios para el registro y consulta de calzado, construida con **Spring Boot**, **Spring Cloud**, **MySQL** y orquestada con **Docker Compose**.

---

## 1. Arquitectura del Sistema

El sistema implementa un patrón de microservicios con pasarela API y descubrimiento dinámico:

```
[ Cliente HTTP / Postman ]
            │
            ▼ (HTTP 18080)
┌──────────────────────────────────────────────┐
│       pasarela-gateway (18080)               │
│ (Spring Cloud Gateway Server Web MVC + LB)   │
└───────────┬──────────────────────┬───────────┘
            │                      │
            │ Consulta instancia   │ Enrutamiento dinámico
            │ lb://servicio-zapatos│ /api/zapatos/**
            ▼                      ▼
┌─────────────────────────┐  ┌─────────────────────────────────────────┐
│ servidor-eureka (18760) │  │       servicio-zapatos (18761)          │
│ (Eureka Server 5.0.3)   │  │ (Spring Data JPA + Jakarta Validation)  │
└─────────────────────────┘  └────────────────────┬────────────────────┘
                                                  │
                                                  │ JDBC (3306 / 3308)
                                                  ▼
                             ┌─────────────────────────────────────────┐
                             │        pasofirme-mysql (MySQL 8.4.3)    │
                             │        (Base de datos: zapatos_db)      │
                             └─────────────────────────────────────────┘
```

- **`servidor-eureka`**: Servidor de registro y descubrimiento (puerto host `18760`).
- **`servicio-zapatos`**: Microservicio de negocio. Expone **únicamente** `GET /api/zapatos` y `POST /api/zapatos`. No publica borrados, actualizaciones ni consultas por ID.
- **`pasarela-gateway`**: Puerta de enlace (puerto host `18080`). Enruta dinámicamente `/api/zapatos` y subrutas hacia `lb://servicio-zapatos` y reenvía todos los verbos HTTP para permitir al servicio emitir respuestas 405.
- **`pasofirme-mysql`**: Base de datos MySQL 8.4 oficial en contenedor Docker con volumen persistente `pasofirme_mysql_data`.

> [!NOTE] Demostración de Configuración Distribuida (Spring Cloud Config)
> El repositorio incluye un módulo independiente y autónomo de configuración centralizada en caliente respaldado por Git: [demo-config/](demo-config/README.md).
> - **Servidor**: `config-server-demo` (puerto `18888`), conectado a [pasofirme-config-repo](https://github.com/Dan101111111/pasofirme-config-repo.git).
> - **Clientes de Negocio**: `catalogo-demo` (`18881`), `ofertas-demo` (`18882`) y `envios-demo` (`18883`).
> - **Guía de Ejecución y Sustentación**: Consulte [demo-config/README.md](demo-config/README.md) y [Guion de Demostración](demo-config/docs/DEMOSTRACION.md).

---

## 2. Estructura del Repositorio

```text
PasoFirme/
├── compose.yaml                  # Base Compose: contenedor MySQL y volumen
├── compose.app.yaml              # Extensión Compose: Eureka, Zapatos y Gateway
├── .env.example                  # Plantilla de variables de entorno (sin secretos)
├── .gitignore                    # Reglas de exclusión (ignora .env, *.log, *.pid, target)
├── README.md                     # Guía principal de uso y arquitectura
├── GUIA_TECNICA.md               # Especificación técnica y requerimientos
├── docs/
│   ├── CONTRATO.md               # Contrato estricto de datos y endpoints API
│   ├── ESTADO.md                 # Registro cronológico de etapas y estado técnico final
│   ├── VERSIONES.md              # Matriz de compatibilidad y dependencias verificadas
│   ├── DEMOSTRACION.md           # Guion paso a paso para sustentación académica
│   ├── VALIDACION.md             # Matriz de cumplimiento de requisitos y pruebas
│   └── evidencias/               # Evidencias formales de pruebas
│       ├── README.md             # Informe detallado de la corrida de pruebas
│       └── postman/              # 4 capturas de pantalla y resultado-ejecucion.json
├── postman/
│   ├── PasoFirme.postman_collection.json         # Colección Postman 2.1 (22 solicitudes)
│   ├── PasoFirme-local.postman_environment.json  # Entorno local (baseUrl=http://localhost:18080)
│   └── GUIA_PRUEBAS.md                           # Guía detallada de ejecución en Postman
├── scripts/
│   └── set-local-env.ps1         # Carga segura de variables .env a PowerShell
├── servidor-eureka/              # Proyecto Maven: Servidor de descubrimiento
│   ├── Dockerfile                # Compilación multietapa y runtime JRE 21
│   ├── start-eureka.ps1          # Script de arranque local verificado
│   └── stop-eureka.ps1           # Script de parada estricta por ruta de JAR
├── servicio-zapatos/             # Proyecto Maven: Servicio de dominio
│   ├── Dockerfile                # Compilación multietapa y runtime JRE 21
│   ├── start-servicio.ps1        # Script de arranque local verificado
│   └── stop-servicio.ps1         # Script de parada estricta por ruta de JAR
└── pasarela-gateway/             # Proyecto Maven: API Gateway Server Web MVC
    ├── Dockerfile                # Compilación multietapa y runtime JRE 21
    ├── start-gateway.ps1         # Script de arranque local verificado
    └── stop-gateway.ps1          # Script de parada estricta por ruta de JAR
```

---

## 3. Coordenadas y Versiones Oficiales Verificadas

| Componente | Versión / Imagen | Fuente Oficial / Detalle |
|---|---|---|
| **Java** | 21 | OpenJDK 21 LTS |
| **Spring Boot** | `4.1.2` | Maven Central (`spring-boot-starter-parent:4.1.2`) |
| **Spring Cloud** | `2025.1.4` | BOM `spring-cloud-dependencies:2025.1.4` |
| **Gateway Web MVC** | `5.0.4` | Starter `spring-cloud-starter-gateway-server-webmvc` |
| **Eureka Client/Server** | `5.0.3` | Transporte HTTP basado en `spring-boot-restclient:4.1.2` |
| **MySQL (Docker)** | `mysql:8.4.3` | Oracle MySQL LTS en Docker Hub |
| **Builder Docker** | `eclipse-temurin:21-jdk-alpine` | Etiqueta mutable de familia Java 21 sobre Alpine |
| **Runtime Docker** | `eclipse-temurin:21-jre-alpine` | Etiqueta mutable de familia JRE 21 con `curl` |

---

## 4. Requisitos Previos y Configuración

- **Sistema Operativo**: Windows 10/11 con PowerShell 7+ (`pwsh`) o Windows PowerShell 5.1.
- **Docker & Docker Compose**: Docker Desktop en ejecución.
- **Java**: JDK 21 instalado localmente (para ejecución en modo local).
- **Postman**: Postman Desktop v11+ (para ejecución de pruebas funcionales).

### Configuración de Variables de Entorno (`.env`)
Copie el archivo de ejemplo si no dispone de un archivo `.env` local:
```powershell
Copy-Item .env.example .env
```
Ajuste las contraseñas locales si lo desea en `.env`.

> [!NOTE]
> Por diseño del entorno del equipo, el puerto host de MySQL se unificó en `3308` (`127.0.0.1:3308->3306`), ya que el puerto `3307` está reservado por un contenedor de base de datos preexistente en la máquina.

---

## 5. Modos de Ejecución

El sistema soporta dos modos de ejecución completamente aislados. **Nunca ejecute ambos modos al mismo tiempo en los mismos puertos.**

### Modo A: Docker Completo (Recomendado para Demostración)

En este modo, los 4 componentes (`mysql`, `servidor-eureka`, `servicio-zapatos`, `pasarela-gateway`) se ejecutan dentro de la red privada `pasofirme-net`.

#### 1. Validar la configuración combinada sin exponer secretos:
```powershell
docker compose -f compose.yaml -f compose.app.yaml config --quiet
```
*(Si no muestra errores y el código de salida es 0, la sintaxis es correcta).*

#### 2. Iniciar y compilar todos los contenedores:
```powershell
docker compose -f compose.yaml -f compose.app.yaml up -d --build
```

#### 3. Verificar estado de salud y puertos:
```powershell
docker compose -f compose.yaml -f compose.app.yaml ps
```
Los cuatro contenedores deben reportar estado **`Up (healthy)`**:
- `pasofirme-mysql`: `127.0.0.1:3308->3306`
- `pasofirme-eureka`: `127.0.0.1:18760->18760`
- `pasofirme-gateway`: `127.0.0.1:18080->18080`
- `pasofirme-servicio-zapatos`: interno (puerto `18761` no expuesto al host)

#### 4. Detener el modo Docker conservando los datos:
```powershell
docker compose -f compose.yaml -f compose.app.yaml down
```
> [!CAUTION]
> **No utilice el parámetro `-v`**. Ejecutar `down -v` eliminará el volumen `pasofirme_mysql_data` y destruirá los datos persistidos.

---

### Modo B: Ejecución Local

En este modo, MySQL corre en Docker pero los microservicios Java se ejecutan directamente en el host mediante PowerShell y los scripts de ciclo de vida seguro.

#### 1. Detener primero los contenedores de aplicación si venía de Modo Docker:
```powershell
docker compose -f compose.yaml -f compose.app.yaml down
```

#### 2. Iniciar únicamente la base de datos MySQL:
```powershell
docker compose up -d mysql
```

#### 3. Cargar las variables de entorno en la sesión de PowerShell:
```powershell
. .\scripts\set-local-env.ps1
```

#### 4. Iniciar los microservicios en orden:
```powershell
powershell -ExecutionPolicy Bypass -File servidor-eureka\start-eureka.ps1
powershell -ExecutionPolicy Bypass -File servicio-zapatos\start-servicio.ps1
powershell -ExecutionPolicy Bypass -File pasarela-gateway\start-gateway.ps1
```

#### 5. Detener ordenadamente los microservicios locales:
Los scripts de parada verifican de forma estricta la ruta absoluta del JAR (`$jarPath`) en la línea de comando del proceso antes de terminarlo, protegiendo procesos ajenos:
```powershell
powershell -ExecutionPolicy Bypass -File pasarela-gateway\stop-gateway.ps1
powershell -ExecutionPolicy Bypass -File servicio-zapatos\stop-servicio.ps1
powershell -ExecutionPolicy Bypass -File servidor-eureka\stop-eureka.ps1
```

### 5.3. Alternancia entre Modos sin Conflictos de Puertos ni Pérdida de Datos

Dado que ambos modos comparten los mismos puertos host (`3308` para MySQL, `18760` para Eureka, `18080` para Gateway y opcionalmente `18761` para Servicio Zapatos local), es fundamental seguir el procedimiento de alternancia ordenado:

#### Para pasar de Modo Docker a Modo Local:
1. **Detener los contenedores sin borrar volúmenes:**
   ```powershell
   docker compose -f compose.yaml -f compose.app.yaml down
   ```
   *(Esto detiene `pasofirme-eureka`, `pasofirme-servicio-zapatos`, `pasofirme-gateway` y `pasofirme-mysql`, liberando los puertos 18080, 18760 y 3308 sin tocar el volumen `pasofirme_mysql_data`).*
2. **Iniciar únicamente la base de datos MySQL en Docker:**
   ```powershell
   docker compose up -d mysql
   ```
   *(La base reutiliza el volumen existente; registros como `DockerBoot` permanecen intactos).*
3. **Cargar variables de entorno en la sesión de PowerShell:**
   ```powershell
   . .\scripts\set-local-env.ps1
   ```
4. **Iniciar los microservicios locales en orden secuencial:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File servidor-eureka\start-eureka.ps1
   powershell -ExecutionPolicy Bypass -File servicio-zapatos\start-servicio.ps1
   powershell -ExecutionPolicy Bypass -File pasarela-gateway\start-gateway.ps1
   ```

#### Para pasar de Modo Local a Modo Docker:
1. **Detener los procesos Java locales ordenadamente:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File pasarela-gateway\stop-gateway.ps1
   powershell -ExecutionPolicy Bypass -File servicio-zapatos\stop-servicio.ps1
   powershell -ExecutionPolicy Bypass -File servidor-eureka\stop-eureka.ps1
   ```
   *(Los scripts verifican la ruta absoluta del JAR en la línea de comando antes de terminar los procesos, garantizando la liberación de los puertos 18080, 18760 y 18761 sin afectar otros procesos Java).*
2. **Lanzar la arquitectura completa en Docker:**
   ```powershell
   docker compose -f compose.yaml -f compose.app.yaml up -d --build
   ```
   *(Docker reutilizará el contenedor MySQL o lo recreará preservando el volumen `pasofirme_mysql_data`).*

> [!WARNING]
> **Regla de Oro de Persistencia:** Jamás ejecute `docker compose down -v` ni elimine el volumen `pasofirme_mysql_data`. La base de datos conserva su historial y la suite de pruebas no requiere que la base esté vacía.

---

## 6. Demostración de Persistencia ante Reinicio

Para demostrar que los datos sobreviven a reinicios de la base de datos sin pérdida:

1. Registre un nuevo zapato mediante la pasarela Gateway:
   ```powershell
   $body = '{"marca":"TestPersistencia","talla":40,"precio":150000.00,"fechaIngreso":"2026-10-27","disponible":true}'
   Invoke-RestMethod -Uri "http://localhost:18080/api/zapatos" -Method Post -Body $body -ContentType "application/json"
   ```
2. Reinicie el contenedor MySQL:
   ```powershell
   docker restart pasofirme-mysql
   ```
3. Espere 5 segundos a que el contenedor recupere el estado `healthy` y vuelva a consultar:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:18080/api/zapatos"
   ```
4. El registro `TestPersistencia` (junto con el registro inicial `DockerBoot` y demás calzados) permanece intacto, demostrando la persistencia en el volumen Docker nombrado.

---

## 7. Pruebas Funcionales con Postman

La suite de pruebas automatizadas contiene **22 solicitudes** con scripts `pm.test` que validan exhaustivamente el contrato API.

> [!NOTE]
> **Estado de Validación Funcional:**
> La colección completa de 22 solicitudes fue ejecutada formalmente en **Postman Desktop** contra el entorno contenerizado (`http://localhost:18080`), obteniendo **31 de 31 aserciones aprobadas (100% éxito, 0 fallidas, 0 errores)**.
> Las capturas de pantalla y el informe JSON de la corrida se encuentran organizados y explicados en [docs/evidencias/README.md](docs/evidencias/README.md).

### Casos de Prueba Validados en la Suite:
- **Flujo de Negocio**: Registro de calzados válidos (con generación de ID autoincremental positivo), consulta general con exactamente 6 campos por objeto y persistencia de valores booleanos estrictos (`false` sin mutar a `null`).
- **Rechazo de Métodos No Permitidos**: `DELETE /api/zapatos` (405), `DELETE /api/zapatos/{id}` (404), `PUT /api/zapatos` (405), `PATCH /api/zapatos` (405), comprobando la inalterabilidad de los registros existentes tras los rechazos.
- **Validaciones de Negocio (HTTP 400)**: Rechazo por marca ausente, vacía o con espacios; talla cero o negativa; precio negativo o con más de dos decimales; fecha inexistente (`2026-02-30`); y cuerpo JSON mal formado sintácticamente, verificando que ninguna petición rechazada inserta filas en MySQL.
- **Contrato Opcional e Inmutabilidad de ID**: Persistencia de campos opcionales omitidos como `null`, e ignorado estricto de cualquier `id` enviado en el cuerpo de un POST (creando un nuevo registro autoincremental sin alterar el ID enviado).

### Procedimiento para Re-ejecutar en Postman Desktop:
1. Abra **Postman Desktop** e importe los dos archivos ubicados en [postman/](postman/):
   - `postman/PasoFirme.postman_collection.json`
   - `postman/PasoFirme-local.postman_environment.json`
2. Seleccione el entorno **PasoFirme - Local** (variable `baseUrl = http://localhost:18080`).
3. Ejecute la colección mediante el **Collection Runner**:
   - Seleccione la colección **PasoFirme**.
   - Verifique que las 22 peticiones estén seleccionadas.
   - Ejecute con 1 iteración.
4. La primera petición reinicia automáticamente las variables transitorias (`id1`, `id2`, etc.) y captura los IDs iniciales (`initialIds`) sin borrar registros existentes (como `DockerBoot`) ni modificar `baseUrl`.

Consulte [postman/GUIA_PRUEBAS.md](postman/GUIA_PRUEBAS.md) para la matriz completa de casos de prueba.

---

## 8. Contrato de Datos y Códigos HTTP

### Tabla `zapato` en MySQL (`zapatos_db`)
Creada automáticamente por Hibernate JPA con exactamente 6 columnas:
| Columna | Tipo SQL | Mapeo Java | Restricciones |
|---|---|---|---|
| `id` | `BIGINT` | `Long` | Clave primaria autoincremental (`AUTO_INCREMENT`) |
| `marca` | `VARCHAR(100)` | `String` | Obligatorio (`NOT NULL`, longitud máxima 100) |
| `talla` | `INT` | `Integer` | Opcional (entero positivo) |
| `precio` | `DECIMAL(10,2)` | `BigDecimal` | Opcional (mínimo 0.00, hasta 2 decimales) |
| `fecha_ingreso` | `DATE` | `LocalDate` | Opcional (formato ISO `YYYY-MM-DD`) |
| `disponible` | `BIT(1)` | `Boolean` | Opcional (`true` o `false`, no muta a null) |

> [!IMPORTANT]
> Docker inicializa la base de datos vacía `zapatos_db` y el usuario autenticado `zapatos_app`. Hibernate es quien crea la estructura de la tabla `zapato`. No existen tablas de auditoría ni columnas adicionales.

### Códigos de Respuesta HTTP
- **`200 OK`**: `GET /api/zapatos` devuelve el arreglo de calzados.
- **`201 Created`**: `POST /api/zapatos` con cuerpo válido. Cualquier `id` enviado en el cuerpo es ignorado y se genera un nuevo ID autoincremental.
- **`400 Bad Request`**: Datos inválidos (`marca` vacía o nula, `talla <= 0`, `precio < 0` o con >2 decimales, fecha inexistente como `2026-02-30`, o JSON mal formado).
- **`404 Not Found`**: Subrutas no mapeadas en la API, tales como `DELETE /api/zapatos/{id}`.
- **`405 Method Not Allowed`**: Métodos no admitidos sobre `/api/zapatos` (`DELETE`, `PUT`, `PATCH`). La restricción reside en la API, no en permisos administrativos de SQL.
- **`503 Service Unavailable`**: Si el servicio no está registrado aún en Eureka o la pasarela no puede contactarlo.

---

## 9. Solución de Problemas Frecuentes

1. **Error 503 al consultar la pasarela Gateway**:
   - Eureka requiere un tiempo de latencia para propagar el registro del servicio y sincronizar la caché del cliente (generalmente entre 10 y 25 segundos). Espere a que el contenedor `pasofirme-gateway` reporte `(healthy)`.
2. **Puerto 3308 ocupado**:
   - Verifique si un contenedor Docker previo o proceso local retiene el socket: `Get-NetTCPConnection -LocalPort 3308 -State Listen`.
3. **Error de autenticación MySQL (`Access denied for user 'zapatos_app'`)**:
   - Si cambió contraseñas en `.env`, MySQL no actualiza credenciales sobre un volumen Docker ya inicializado. Debe utilizar las credenciales con las que se inicializó el volumen por primera vez.
4. **Conflicto de puertos al alternar de Docker a Local**:
   - Ejecute `docker compose -f compose.yaml -f compose.app.yaml down` antes de lanzar los scripts PowerShell locales para liberar los puertos `18080`, `18760` y `18761`.

---

## 10. Documentación Académica Complementaria

- [docs/CONTRATO.md](docs/CONTRATO.md): Especificación exhaustiva de DTOs, validaciones y reglas de negocio.
- [docs/ESTADO.md](docs/ESTADO.md): Registro cronológico de todas las etapas y estado técnico final del proyecto.
- [docs/VERSIONES.md](docs/VERSIONES.md): Justificación y verificación de dependencias y coordenadas oficiales.
- [docs/DEMOSTRACION.md](docs/DEMOSTRACION.md): Guion paso a paso para la sustentación y capturas recomendadas.
- [docs/VALIDACION.md](docs/VALIDACION.md): Matriz de trazabilidad de requisitos, adaptaciones y resultados de pruebas.
- [docs/evidencias/README.md](docs/evidencias/README.md): Informe formal de ejecución de pruebas y evidencias visuales.
