# PasoFirme: Guía Técnica de la Arquitectura

Documentación técnica del sistema distribuido de registro y consulta de calzado **PasoFirme**, implementado con Java 21, Spring Boot, Spring Cloud, MySQL y Docker Compose.

---

## 1. Trazabilidad y Especificaciones de Referencia

| Fuente | Requisito / Especificación | Implementación en PasoFirme |
|---|---|---|
| **ELABORAR UN ENDPOINT.pdf** (pág. 1) | Agregar y listar en MySQL; cinco campos de tipos entero, cadena, decimal, fecha y lógico; sin operaciones de borrado. | Implementado como requisito funcional principal. Se incorpora identificador autoincremental en base de datos: tabla `zapato` con exactamente seis columnas. |
| **Eureka.pdf** (págs. 1-5) | Servidor de registro y descubrimiento de microservicios con clientes dinámicos. | Implementado con Netflix Eureka Server (`servidor-eureka`, puerto `18760`) y clientes dinámicos registrados en estado `UP`. |
| **05 Api Gateway 0.pdf** (págs. 1-5) | Punto de entrada único mediante Spring Cloud Gateway Server Web MVC y balanceo de carga. | Implementado en `pasarela-gateway` (puerto `18080`) con enrutamiento dinámico `lb://servicio-zapatos` sobre Spring Cloud LoadBalancer. |
| **Modelo de Negocio** | Foco exclusivo en gestión de calzados. | Alcance estricto: un único microservicio de negocio (`servicio-zapatos`), persistencia JPA y endpoints `GET` y `POST /api/zapatos`. No se añaden entidades accesorias (ventas, clientes, inventario múltiple). |

---

## 2. Modelo de Datos: Cinco Campos de Negocio y un Identificador

La persistencia se realiza en una única tabla relacional `zapato` en la base de datos `zapatos_db`:

| Campo | Tipo Solicitado | Tipo Java | Columna MySQL | Regla y Restricción |
|---|---|---|---|---|
| `id` | Identificador autogenerado | `Long` | `BIGINT AUTO_INCREMENT PRIMARY KEY` | Autogenerado por MySQL. El cliente no puede definirlo; si se envía en el cuerpo de un POST, se ignora y se genera un nuevo ID. |
| `marca` | Cadena | `String` | `VARCHAR(100)` | **Obligatoria**, no nula, no vacía ni conformada solo por espacios (`@NotBlank`). Máximo 100 caracteres. |
| `talla` | Entero | `Integer` | `INT` | Opcional; si aparece, debe ser mayor que cero (`@Positive`). |
| `precio` | Decimal | `BigDecimal` | `DECIMAL(10,2)` | Opcional; mínimo 0.00 (`@DecimalMin("0.00")`), hasta 8 enteros y 2 decimales (`@Digits(integer=8, fraction=2)`). |
| `fechaIngreso` | Fecha | `LocalDate` | `DATE`, columna `fecha_ingreso` | Opcional; formato estándar ISO `YYYY-MM-DD`. Deserialización estricta. |
| `disponible` | Lógico | `Boolean` | `BIT(1)`, columna `disponible` | Opcional; almacena `true` o `false` estrictos (no muta a `null`). Si se omite, se guarda como `null`. |

> [!NOTE]
> La tabla `zapato` es creada automáticamente por Hibernate JPA (`ddl-auto=update`), mientras que la base de datos `zapatos_db` y el usuario `zapatos_app` son inicializados por el motor oficial de MySQL en Docker.

---

## 3. Arquitectura del Sistema Distribuido

```text
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

Eureka participa exclusivamente en la resolución de instancias y balanceo; las peticiones de negocio viajan directamente desde la pasarela hacia el microservicio (`lb://servicio-zapatos`).

| Componente | spring.application.name | Paquete Java | Puerto Host | Puerto Contenedor |
|---|---|---|---|---|
| `servidor-eureka` | `servidor-eureka` | `com.pasofirme.eureka` | `18760` | `18760` |
| `servicio-zapatos` | `servicio-zapatos` | `com.pasofirme.zapatos` | Interno (no publicado en Docker) / `18761` (Local) | `18761` |
| `pasarela-gateway` | `pasarela-gateway` | `com.pasofirme.gateway` | `18080` | `18080` |
| `pasofirme-mysql` | No aplica | No aplica | `3308` | `3306` |

- **Unificación del puerto host de MySQL**: Se fijó en `3308` (`127.0.0.1:3308->3306`) para evitar conflictos con el puerto `3307` (ocupado por un contenedor preexistente en el equipo) y `3306` (instalaciones locales).

---

## 4. Tecnologías y Matriz de Compatibilidad

- **Lenguaje y Plataforma**: Java 21 LTS.
- **Framework Base**: Spring Boot `4.1.2` (`spring-boot-starter-parent:4.1.2`).
- **Arquitectura Cloud**: Spring Cloud `2025.1.4` (BOM `spring-cloud-dependencies:2025.1.4`).
- **Gateway Server**: Spring Cloud Gateway Server Web MVC `5.0.4` (`spring-cloud-starter-gateway-server-webmvc`). Arquitectura bloqueante / síncrona sobre Tomcat / Spring MVC estándar, compatible con servlets y Spring Cloud LoadBalancer.
- **Transporte Eureka**: `spring-boot-restclient:4.1.2` integrado con el cliente nativo RestClient de Spring Boot.
- **Base de Datos**: MySQL `8.4.3` LTS oficial en Docker con volumen nombrado persistente `pasofirme_mysql_data`.
- **Imágenes Docker de Construcción y Runtime**:
  - Builder: `eclipse-temurin:21-jdk-alpine` (etiqueta mutable de la familia Java 21 sobre Alpine Linux).
  - Runtime: `eclipse-temurin:21-jre-alpine` con `curl` incorporado para healthchecks de preparación.

---

## 5. Contrato REST de la API

Punto de entrada oficial: `http://localhost:18080/api/zapatos`.

```json
{
  "marca": "Bata",
  "talla": 39,
  "precio": 129900.50,
  "fechaIngreso": "2026-10-27",
  "disponible": true
}
```

### Respuestas y Códigos HTTP del Contrato:
| Petición | Código HTTP | Comportamiento |
|---|---|---|
| `GET /api/zapatos` | `200 OK` | Retorna el listado completo de calzados ordenados por ID ascendente. |
| `POST /api/zapatos` (válido) | `201 Created` | Persiste el registro y retorna el objeto con su ID autoincremental positivo generado en base de datos. |
| `POST /api/zapatos` (inválido) | `400 Bad Request` | Rechazo inmediato por validación de negocio (`@NotBlank`, `@Positive`, `@DecimalMin`, `@Digits`, fecha inexistente o JSON mal formado). |
| `DELETE`, `PUT` o `PATCH /api/zapatos` | `405 Method Not Allowed` | La pasarela reenvía el método y el microservicio lo rechaza por no estar implementado. |
| `DELETE /api/zapatos/{id}` | `404 Not Found` | Subruta no mapeada en la API. |

---

## 6. Modos de Ejecución Soportados

1. **Modo Docker Completo (Recomendado)**:
   - Los cuatro contenedores corren en la red privada `pasofirme-net`.
   - `pasofirme-servicio-zapatos` permanece aislado en la red interna sin exponer su puerto al host.
   - Orquestado con `compose.yaml` y `compose.app.yaml` con healthchecks encadenados (`service_healthy`).
2. **Modo Local**:
   - MySQL se ejecuta en Docker (puerto `3308`).
   - Los microservicios Java corren directamente en el host mediante scripts PowerShell (`start-*.ps1` / `stop-*.ps1`).
   - Requiere cargar variables de entorno en la sesión con `. .\scripts\set-local-env.ps1`.
   - Los scripts de inicio detectan dinámicamente Java desde `JAVA_HOME` o `PATH`, comprobando que sea versión 21+.

---

## 7. Fuentes Técnicas Verificadas

- [Matriz Oficial Spring Boot / Spring Cloud](https://spring.io/projects/spring-cloud/).
- [Spring Initializr API](https://start.spring.io/).
- [Starter Gateway Server Web MVC](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webmvc/starter.html).
- [Rutas lb y LoadBalancer de Gateway MVC](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webmvc/filters/loadbalancer.html).
- [Eureka: cliente, defaultZone y transporte RestClient](https://docs.spring.io/spring-cloud-netflix/reference/spring-cloud-netflix.html).
- [Docker Compose: orden de inicio y condition service_healthy](https://docs.docker.com/compose/how-tos/startup-order/).
- [Oracle MySQL 8.4 LTS Documentation](https://dev.mysql.com/doc/refman/8.4/en/).
