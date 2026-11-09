# Matriz de Validación y Trazabilidad de Requisitos - PasoFirme

Este documento detalla la correspondencia entre los requerimientos funcionales, arquitectónicos y técnicos del proyecto **PasoFirme**, los archivos del repositorio que los implementan y el resultado real obtenido en las comprobaciones.

---

## 1. Adaptaciones Respecto a Guías Académicas de Referencia (PDFs)

Respecto a las especificaciones académicas de referencia (las cuales definen una arquitectura basada en **Spring Boot 3.3.5**, **Spring Cloud 2023.0.3** y **Spring Cloud Gateway Server Web MVC**), PasoFirme adopta una modernización tecnológica controlada manteniendo plena fidelidad a los patrones de diseño originales:

| Aspecto | Guías de Referencia (PDFs) | Implementación Real en PasoFirme | Justificación Técnica |
|---|---|---|---|
| **Spring Boot / Cloud** | Spring Boot 3.3.5 / Spring Cloud 2023.0.3 | **Spring Boot 4.1.2** / **Spring Cloud 2025.1.4** | Soporte oficial vigente para Java 21 LTS y coordenadas Maven Central activas. |
| **API Gateway** | Spring Cloud Gateway Server Web MVC (en Boot 3.3.5) | **Spring Cloud Gateway Server Web MVC 5.0.4** | Arquitectura bloqueante / síncrona sobre Tomcat / Spring MVC estándar, compatible con servlets y LoadBalancer dinámico. |
| **Transporte Eureka** | Cliente HTTP estándar de Spring Cloud Netflix | **Spring Boot RestClient (`spring-boot-restclient:4.1.2`)** | Eureka HTTP Client moderno integrado con el cliente REST nativo de Spring Boot. |
| **Puerto MySQL Host** | Puerto estándar 3306 o 3307 | **Puerto `3308` en el Host (`127.0.0.1:3308->3306`)** | Evita colisiones de puerto, dado que el puerto `3307` está reservado por un contenedor preexistente en la máquina. |
| **Base de Datos** | MySQL local | **MySQL 8.4 LTS en Docker Compose con volumen** | Despliegue reproducible, aislamiento completo y persistencia garantizada en volumen nombrado `pasofirme_mysql_data`. |
| **Dominio de Negocio** | Zapatos con 5 campos de negocio | **Un solo servicio de negocio (`servicio-zapatos`)** | Foco exclusivo en el dominio de calzados con 5 campos de negocio y tabla de exactamente 6 columnas (incluyendo clave primaria autoincremental). |
| **Comunicación Inter-servicio** | Ejemplos ilustrativos de `RestTemplate` entre dos servicios | **No aplica comunicación directa entre microservicios** | PasoFirme cuenta con un único servicio de negocio consumido exclusivamente a través de la pasarela Gateway. Si una rúbrica posterior exige comunicación entre dos servicios, se documenta expresamente que dicha interacción requerirá incorporar un segundo microservicio de negocio. |

---

## 2. Matriz de Requisitos y Comprobaciones

| ID | Requisito Técnico / Contrato | Archivo / Componente | Comprobación Ejecutada | Resultado Real | Evidencia Asociada |
|---|---|---|---|:---:|---|
| **REQ-01** | Coordenadas Maven coherentes en los 3 proyectos (Boot 4.1.2, Cloud 2025.1.4, Java 21). | `servidor-eureka/pom.xml`<br>`servicio-zapatos/pom.xml`<br>`pasarela-gateway/pom.xml` | Inspección de POMs, verificación en Maven Central y compilación limpia con Maven Wrapper. | **APROBADO** | `pom.xml` en los tres proyectos |
| **REQ-02** | Base de datos MySQL en Docker con volumen persistente y puerto unificado 3308. | `compose.yaml`<br>`.env.example` | Inicio de contenedor `pasofirme-mysql` y conexión SQL autenticada en puerto 3308. | **APROBADO** | Healthcheck Docker Compose (`SELECT 1`) |
| **REQ-03** | Tabla `zapato` con exactamente 6 columnas y tipos conformes al contrato. | `servicio-zapatos/.../Zapato.java` | Consulta `SHOW COLUMNS FROM zapato;` en MySQL. | **APROBADO** | Estructura de 6 columnas en MySQL |
| **REQ-04** | Servidor Eureka en puerto 18760 con transporte RestClient. | `servidor-eureka/.../ServidorEurekaApplication.java`<br>`servidor-eureka/src/.../application.properties` | Acceso a `http://localhost:18760/` (dashboard HTTP 200) y `/eureka/apps` (JSON). | **APROBADO** | Dashboard Eureka y endpoint `/eureka/apps` |
| **REQ-05** | Servicio de negocio en puerto 18761 con GET y POST exclusivamente. | `servicio-zapatos/.../ZapatoController.java` | Inspección de métodos (solo `@GetMapping` y `@PostMapping`); GET 200 y POST 201 (`DockerBoot`) evidenciados en vivo. | **APROBADO** | [01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png) |
| **REQ-06** | Inmutabilidad de ID en POST (ID recibido en el cuerpo es ignorado). | `servicio-zapatos/.../CrearZapatoRequest.java`<br>`servicio-zapatos/.../ZapatoServiceImpl.java` | Solicitudes 10a y 10b de Postman: envío de ID en body genera nuevo registro autoincremental sin alterar `id1`. | **APROBADO** | [04-campos-opcionales-e-id-generado.png](evidencias/postman/04-campos-opcionales-e-id-generado.png) |
| **REQ-07** | Validaciones de negocio (`@NotBlank`, `@Positive`, `@DecimalMin`, `@Digits`, deserialización fecha). | `servicio-zapatos/.../CrearZapatoRequest.java`<br>`GlobalExceptionHandler.java` | Solicitudes 07a a 08g de Postman: retorno uniforme de HTTP 400 Bad Request y cantidad de registros inalterada. | **APROBADO** | [02-metodos-rechazados-y-marca-obligatoria.png](evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png)<br>[03-validaciones-y-ausencia-de-inserciones.png](evidencias/postman/03-validaciones-y-ausencia-de-inserciones.png) |
| **REQ-08** | Pasarela Gateway en puerto 18080 con enrutamiento dinámico `lb://servicio-zapatos`. | `pasarela-gateway/src/.../application.properties` | `GET http://localhost:18080/api/zapatos` devuelve HTTP 200 idéntico al servicio. | **APROBADO** | [01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png) |
| **REQ-09** | Reenvío de métodos no admitidos (DELETE, PUT, PATCH devuelven 405 / 404). | `pasarela-gateway` -> `servicio-zapatos` | Solicitudes 05a (DELETE colección -> 405), 05b (DELETE elemento -> 404), 05c (PUT -> 405) y 05d (PATCH -> 405). | **APROBADO** | [01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png)<br>[02-metodos-rechazados-y-marca-obligatoria.png](evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png) |
| **REQ-10** | Scripts de parada segura con verificación estricta de ruta absoluta del JAR. | `servidor-eureka/stop-eureka.ps1`<br>`servicio-zapatos/stop-servicio.ps1`<br>`pasarela-gateway/stop-gateway.ps1` | Verificación de `$jarPath` en `CommandLine` antes de detener procesos. | **APROBADO** | Scripts `stop-*.ps1` verificados |
| **REQ-11** | Contenerización completa multietapa con etiquetas de familia Java 21 y Docker Compose modular. | `servidor-eureka/Dockerfile`<br>`servicio-zapatos/Dockerfile`<br>`pasarela-gateway/Dockerfile`<br>`compose.app.yaml` | Validación con `docker compose -f compose.yaml -f compose.app.yaml config --quiet` (sin volcar credenciales), construcción multietapa y verificación de 4 contenedores `healthy`. (Imágenes usan tags `21-jdk-alpine` y `21-jre-alpine` mutables, no digest). | **APROBADO** | `compose.app.yaml` y Dockerfiles |
| **REQ-12** | Registro conjunto de ambos microservicios en Eureka como UP en Docker. | Eureka API en Docker (`http://localhost:18760/eureka/apps`) | `PASARELA-GATEWAY` (UP) y `SERVICIO-ZAPATOS` (UP) constatados en vivo. | **APROBADO** | Endpoint JSON `/eureka/apps` |
| **REQ-13** | Persistencia real de datos tras reinicio de MySQL sin borrar volumen. | Contenedor `pasofirme-mysql` y volumen `pasofirme_mysql_data` | Registro creado (`DockerBoot`), reinicio con `docker restart` y consulta posterior con datos intactos. | **APROBADO** | `docker restart pasofirme-mysql` |
| **REQ-14** | Colección Postman 2.1 estructurada con 22 solicitudes y aserciones completas. | `postman/PasoFirme.postman_collection.json`<br>`postman/PasoFirme-local.postman_environment.json` | Validación estática de sintaxis JSON (`ConvertFrom-Json`) y revisión de aserciones `pm.test`. | **APROBADO** | Archivos en `postman/` |
| **REQ-15** | Ejecución funcional automatizada de la colección completa en Postman Desktop. | Postman Desktop / Collection Runner | Corrida ejecutada: 22 solicitudes, 31 aserciones aprobadas, 0 fallidas, 0 errores. | **APROBADO** | [docs/evidencias/README.md](evidencias/README.md) |

---

## 3. Estado de Pruebas y Evidencias Ejecutadas

### ✅ Verificaciones Ejecutadas y Evidenciadas en Vivo:
1. **Compilación Maven**: Los tres microservicios compilan exitosamente con sus Wrappers independientes en Java 21.
2. **Infraestructura Docker Completa**: Los cuatro contenedores (`pasofirme-mysql`, `pasofirme-eureka`, `pasofirme-servicio-zapatos`, `pasofirme-gateway`) se construyen, inician y alcanzan el estado `healthy`.
3. **Descubrimiento y Balanceo**: Ambos microservicios se registran dinámicamente como `UP` en Eureka.
4. **Enrutamiento por Pasarela**: La pasarela resuelve `lb://servicio-zapatos` y responde `200 OK` en `http://localhost:18080/api/zapatos`.
5. **Rechazo de Métodos no Permitidos**:
   - `DELETE /api/zapatos` devuelve HTTP 405 Method Not Allowed.
   - `DELETE /api/zapatos/{{id1}}` devuelve HTTP 404 Not Found.
   - `PUT /api/zapatos` devuelve HTTP 405 Method Not Allowed.
   - `PATCH /api/zapatos` devuelve HTTP 405 Method Not Allowed.
   - Evidenciado en [01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png) y [02-metodos-rechazados-y-marca-obligatoria.png](evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png).
6. **Validaciones de Negocio (HTTP 400)**:
   - Marca nula, vacía o con solo espacios.
   - Talla cero o negativa.
   - Precio negativo o con más de dos decimales.
   - Fecha inexistente (`2026-02-30`).
   - JSON sintácticamente mal formado.
   - Verificación de que ninguna solicitud inválida agrega registros a la base de datos.
   - Evidenciado en [02-metodos-rechazados-y-marca-obligatoria.png](evidencias/postman/02-metodos-rechazados-y-marca-obligatoria.png) y [03-validaciones-y-ausencia-de-inserciones.png](evidencias/postman/03-validaciones-y-ausencia-de-inserciones.png).
7. **Campos Opcionales e Inmutabilidad de ID**:
   - Omisión de campos opcionales persistidos como `null`.
   - Envío de `id` en el cuerpo ignorado y generación de nuevo ID autoincremental sin alterar el registro referenciado.
   - Evidenciado en [04-campos-opcionales-e-id-generado.png](evidencias/postman/04-campos-opcionales-e-id-generado.png).
8. **Persistencia MySQL tras Reinicio Físico**:
   - El registro `DockerBoot` sobrevive al reinicio forzado del contenedor `pasofirme-mysql` (`docker restart`) sin pérdida de información, gracias al volumen Docker `pasofirme_mysql_data`.
9. **Resumen de la Suite Postman**:
   - 22 solicitudes ejecutadas en 1 iteración, 31 aserciones aprobadas, 0 fallidas, 0 errores.
   - Evidencias documentadas en [docs/evidencias/README.md](evidencias/README.md) y [docs/evidencias/postman/resultado-ejecucion.json](evidencias/postman/resultado-ejecucion.json).
