# PasoFirme: Estado Técnico Final y Registro de Verificaciones

Este documento registra el estado técnico final de los componentes del sistema distribuido **PasoFirme**, la trazabilidad de las comprobaciones reales ejecutadas en el entorno y la catalogación de las evidencias obtenidas.

---

## 1. Resumen de Estado Técnico por Componente

| Componente | 1. Compilación / Empaquetado | 2. Estado Operativo en Vivo | 3. Verificación Funcional y Contrato |
|---|---|---|---|
| **Base de Datos Relacional (`pasofirme-mysql`)** | **COMPLETADA** (`compose.yaml`, `.env`, volumen `pasofirme_mysql_data`) | **OPERATIVO / HEALTHY** (`mysql:8.4.3` en `127.0.0.1:3308->3306`) | **VERIFICADO**: `SELECT 1` autenticado; tabla `zapato` con exactamente 6 columnas; persistencia comprobada ante reinicio. |
| **Servidor de Descubrimiento (`servidor-eureka`)** | **COMPLETADA** (JAR ejecutable 60.8 MB / Imagen Docker) | **OPERATIVO / HEALTHY** (Puerto `127.0.0.1:18760`) | **VERIFICADO**: Dashboard HTTP 200 OK; API `/eureka/apps` reporta ambas aplicaciones en estado `UP`. |
| **Microservicio de Dominio (`servicio-zapatos`)** | **COMPLETADA** (JAR ejecutable 79.4 MB / Imagen Docker) | **OPERATIVO / HEALTHY** (Red interna `pasofirme-net`, puerto 18761) | **VERIFICADO**: Entidad JPA y DTOs estrictos; endpoints `GET` y `POST /api/zapatos`; validaciones Jakarta Validation operativas. |
| **Pasarela API Gateway (`pasarela-gateway`)** | **COMPLETADA** (JAR ejecutable 47.1 MB / Imagen Docker) | **OPERATIVO / HEALTHY** (Puerto `127.0.0.1:18080`) | **VERIFICADO**: Enrutamiento dinámico `lb://servicio-zapatos` sobre Spring Cloud LoadBalancer; reenvío de verbos HTTP al backend. |
| **Suite de Pruebas Postman** | **COMPLETADA** (Colección v2.1 de 22 peticiones y entorno) | **EJECUTADA EN DESKTOP** (Collection Runner) | **VERIFICADO**: 31 de 31 aserciones aprobadas (100% éxito, 0 fallidas, 0 errores); evidencias visuales y JSON catalogadas. |
| **Orquestación Docker Compose** | **COMPLETADA** (`compose.yaml` + `compose.app.yaml`) | **OPERATIVO / HEALTHY** (4 contenedores en `pasofirme-net`) | **VERIFICADO**: Dependencias encadenadas (`service_healthy`); validación silenciosa de sintaxis con `config --quiet`. |

---

## 2. Registro Detallado de Verificaciones Ejecutadas

### 2.1. Plataforma Base y Compilación de Microservicios
- **Coordenadas y Versiones**:
  - Java: **OpenJDK 21 LTS**.
  - Spring Boot: **4.1.2** (`spring-boot-starter-parent:4.1.2`).
  - Spring Cloud: **2025.1.4** (BOM `spring-cloud-dependencies:2025.1.4`).
  - Gateway Server Web MVC: **5.0.4** (`spring-cloud-starter-gateway-server-webmvc`).
  - Transporte Eureka: `spring-boot-restclient:4.1.2` (RestClient nativo de Spring Boot).
- **Maven Wrapper**: Cada uno de los tres proyectos cuenta con su Wrapper auténtico independiente (`mvnw.cmd` / `mvnw` con Apache Maven 3.10.0).
- **Compilación Limpia**:
  - `servidor-eureka`: **BUILD SUCCESS** (`servidor-eureka-0.0.1-SNAPSHOT.jar`).
  - `servicio-zapatos`: **BUILD SUCCESS** (`servicio-zapatos-0.0.1-SNAPSHOT.jar`).
  - `pasarela-gateway`: **BUILD SUCCESS** (`pasarela-gateway-0.0.1-SNAPSHOT.jar`).

### 2.2. Base de Datos MySQL en Docker
- **Aislamiento de Puertos**: El puerto host fue unificado en `3308` (`127.0.0.1:3308:3306`) protegiendo el puerto `3307` (ocupado por un contenedor de base de datos preexistente en la máquina) y `3306` (instalaciones locales).
- **Esquema Relacional**: La base de datos `zapatos_db` y el usuario `zapatos_app` son creados por la imagen oficial `mysql:8.4.3`.
- **Estructura de Tabla `zapato`**: Creada automáticamente por Hibernate JPA con exactamente 6 columnas verificadas mediante `SHOW COLUMNS FROM zapato;`:
  - `id`: `BIGINT AUTO_INCREMENT PRIMARY KEY`.
  - `marca`: `VARCHAR(100) NOT NULL`.
  - `talla`: `INT NULL`.
  - `precio`: `DECIMAL(10,2) NULL`.
  - `fecha_ingreso`: `DATE NULL`.
  - `disponible`: `BIT(1) NULL`.

### 2.3. Servidor de Descubrimiento Eureka
- **Configuración**: Puerto host `18760`, modo servidor independiente (`register-with-eureka=false`, `fetch-registry=false`).
- **Verificación**: Acceso HTTP 200 en `http://localhost:18760/` (dashboard visual) y `http://localhost:18760/eureka/apps` (formato JSON).
- **Registro de Clientes**: Ambos microservicios (`PASARELA-GATEWAY` y `SERVICIO-ZAPATOS`) se registran dinámicamente con estado **`UP`**.

### 2.4. Microservicio de Dominio (Servicio Zapatos)
- **Controlador REST**: `@RequestMapping("/api/zapatos")` exponiendo exclusivamente `@GetMapping` (HTTP 200) y `@PostMapping` (HTTP 201). No se exponen endpoints de modificación (`PUT`/`PATCH`), eliminación (`DELETE`) ni consulta individual por ID.
- **DTOs y Validaciones**:
  - `CrearZapatoRequest`: Anotado con `@NotBlank`, `@Size(max=100)`, `@Positive`, `@DecimalMin("0.00")`, `@Digits(integer=8, fraction=2)`.
  - Inmutabilidad de ID: Anotado con `@JsonIgnoreProperties(value = {"id"})` y `zapato.setId(null)` en la capa de servicio. Cualquier ID enviado en el cuerpo es ignorado y el motor genera un ID autoincremental nuevo.
  - Manejo Global de Excepciones: `GlobalExceptionHandler` captura `MethodArgumentNotValidException` y `HttpMessageNotReadableException`, retornando HTTP 400 Bad Request uniforme sin filtrar trazas internas.

### 2.5. Pasarela API Gateway
- **Tecnología**: Spring Cloud Gateway Server Web MVC con Spring Cloud LoadBalancer.
- **Enrutamiento Dinámico**: Regla `ruta-zapatos` mapeando `Path=/api/zapatos,/api/zapatos/**` hacia `lb://servicio-zapatos` sin filtros de eliminación de prefijo ni restricción de verbos HTTP, permitiendo al servicio backend evaluar y responder 405 Method Not Allowed ante métodos no admitidos.
- **Verificación**: Peticiones a `http://localhost:18080/api/zapatos` resuelven la instancia activa en Eureka y entregan la misma respuesta que el servicio directo.

### 2.6. Suite de Pruebas Postman y Evidencias de Validación
- **Colección**: [postman/PasoFirme.postman_collection.json](../postman/PasoFirme.postman_collection.json) (Esquema v2.1.0, 22 solicitudes organizadas en 4 carpetas).
- **Entorno**: [postman/PasoFirme-local.postman_environment.json](../postman/PasoFirme-local.postman_environment.json) (`baseUrl = http://localhost:18080`).
- **Resultado de la Corrida en Postman Desktop**:
  - Solicitudes: **22 ejecutadas**.
  - Iteraciones: **1**.
  - Aserciones aprobadas (`Passed`): **31**.
  - Aserciones fallidas (`Failed`): **0**.
  - Aserciones omitidas (`Skipped`): **0**.
  - Errores de ejecución (`Errors`): **0**.
  - Tasa de aprobación: **100% (31 / 31)**.
- **Catalogación de Evidencias**:
  - [docs/evidencias/README.md](evidencias/README.md): Informe formal detallado.
  - [docs/evidencias/postman/resultado-ejecucion.json](evidencias/postman/resultado-ejecucion.json): Exportación nativa del reporte de Postman Runner.
  - [docs/evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png): Evidencia de solicitudes 01 a 05b.
  - [docs/evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png](evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png): Evidencia de solicitudes 05c a 08a.
  - [docs/evidencias/postman/03-validaciones-y-ausencia-de-inserciones.png](evidencias/postman/03-validaciones-y-ausencia-de-inserciones.png): Evidencia de solicitudes 08b a 09.
  - [docs/evidencias/postman/04-campos-opcionales-e-id-generado.png](evidencias/postman/04-campos-opcionales-e-id-generado.png): Evidencia de solicitudes 08e a 10b.

### 2.7. Contenerización y Despliegue en Docker Compose
- **Dockerfiles Multietapa**: Compilación limpia con Maven Wrapper sobre `eclipse-temurin:21-jdk-alpine` y empaquetado final sobre `eclipse-temurin:21-jre-alpine` con `curl`.
- **Composición Modular**:
  - `compose.yaml`: Servicio de base de datos MySQL con volumen `pasofirme_mysql_data`.
  - `compose.app.yaml`: Servicios `servidor-eureka`, `servicio-zapatos` y `pasarela-gateway`.
- **Validación Segura**: Ejecutada con `docker compose -f compose.yaml -f compose.app.yaml config --quiet`, verificando la sintaxis sin volcar credenciales ni secretos interpolados.
- **Estado de Salud**: Los cuatro contenedores reportan estado **`Up (healthy)`** en la red privada `pasofirme-net`:
  - `pasofirme-mysql`: `127.0.0.1:3308->3306` (healthy).
  - `pasofirme-eureka`: `127.0.0.1:18760->18760` (healthy).
  - `pasofirme-gateway`: `127.0.0.1:18080->18080` (healthy).
  - `pasofirme-servicio-zapatos`: interno `18761/tcp` (healthy).

### 2.8. Comprobación de Persistencia ante Reinicio Físico
- Se registró un calzado inicial (`DockerBoot`, `id: 1`).
- Se ejecutó el reinicio físico del contenedor de base de datos mediante `docker restart pasofirme-mysql`.
- Tras restablecerse el healthcheck, se consultó `http://localhost:18080/api/zapatos` y se constató que los datos persisten intactos, demostrando la durabilidad provista por el volumen persistente `pasofirme_mysql_data`.

### 2.9. Scripts de Operación y Ciclo de Vida Local
- **Resolución Dinámica de Java**: `start-eureka.ps1`, `start-servicio.ps1` y `start-gateway.ps1` resuelven la ruta de Java desde `JAVA_HOME` o `PATH`, comprueban dinámicamente que la versión mayor sea `>= 21` y emiten mensajes explicativos en caso de requerimientos no satisfechos.
- **Parada Segura**: `stop-eureka.ps1`, `stop-servicio.ps1` y `stop-gateway.ps1` verifican de forma estricta la ruta canónica absoluta del JAR (`$jarPath`) en la línea de comando antes de terminar cualquier proceso, evitando interferir con otros procesos del sistema.

---

## 3. Estado Final de Entrega

El proyecto se encuentra **100% completado y verificado**:
- Todos los componentes se encuentran construidos, configurados y operativos.
- Las evidencias funcionales de las 22 solicitudes de Postman están recolectadas y documentadas con 100% de aserciones aprobadas.
- La persistencia en MySQL ante reinicios físicos está demostrada sin alteración de datos.
- No existen desajustes pendientes ni tareas inconclusas en el alcance técnico del proyecto.
