# PasoFirme: Contrato y Reglas del Proyecto

## 1. Alcance y Propósito
PasoFirme es un sistema distribuido para el registro y consulta de calzado, construido con Java, Spring Boot, Spring Cloud, MySQL y Docker.
El contrato funcional y técnico se basa estrictamente en [GUIA_TECNICA.md](../GUIA_TECNICA.md) y las especificaciones de referencia adaptadas.

## 2. Dominio y Modelo de Datos
La persistencia se realiza en una única tabla `zapato` dentro de la base de datos `zapatos_db`.

### 2.1. Columnas y Atributos

| Campo | Tipo Solicitado | Tipo Java | Columna MySQL | Reglas y Validaciones |
|---|---|---|---|---|
| `id` | Identificador único | `Long` | `BIGINT AUTO_INCREMENT PRIMARY KEY` | Autogenerado por MySQL. Nunca lo define el cliente. Si se envía en un POST, se ignora y se crea uno nuevo. |
| `marca` | Cadena de texto | `String` | `VARCHAR(100)` | **Obligatorio**, no nulo, no vacío ni conformado solo por espacios. Máximo 100 caracteres. |
| `talla` | Entero | `Integer` | `INT` | Opcional. Si se provee, debe ser un entero estrictamente positivo (`> 0`). |
| `precio` | Decimal | `BigDecimal` | `DECIMAL(10,2)` | Opcional. Si se provee, no puede ser negativo (`>= 0`) y admite hasta 8 dígitos enteros y 2 decimales. |
| `fechaIngreso` | Fecha | `LocalDate` | `DATE` (`fecha_ingreso`) | Opcional. Formato ISO `yyyy-MM-dd`. |
| `disponible` | Lógico | `Boolean` | `BOOLEAN` / `TINYINT(1)` | Opcional. Valores `true`, `false` o `null`. |

### 2.2. Restricciones de Dominio
- No se modelan inventarios complejos, clientes, ventas, imágenes, auditorías ni carritos de compra.
- Solo existe la tabla `zapato`. No se agregan tablas adicionales.

## 3. Contrato de la API REST
Toda interacción de negocio se realiza a través de la pasarela: `http://localhost:18080/api/zapatos`.

### 3.1. Operaciones Permitidas
- **`POST /api/zapatos`**:
  - Entrada: JSON con el DTO de los 5 campos de negocio.
  - Respuesta exitosa: `201 Created` con el objeto persistido conteniendo su `id` generado.
- **`GET /api/zapatos`**:
  - Respuesta exitosa: `200 OK` con un arreglo JSON de zapatos ordenados por `id ASC`. Arreglo vacío `[]` si no hay registros.

### 3.2. Validaciones y Códigos HTTP Esperados
- **`400 Bad Request`**:
  - Envío de `marca` ausente, vacía (`""`) o en blanco (`"   "`).
  - Envío de `talla <= 0`.
  - Envío de `precio < 0` o con más de 2 cifras decimales.
  - Fecha mal formada (ej. formato inválido o día inexistente) o JSON con sintaxis errónea.
- **`405 Method Not Allowed`**:
  - Peticiones `PUT`, `PATCH` o `DELETE` directas sobre `/api/zapatos`.
- **`404 Not Found`**:
  - Peticiones `DELETE` o `GET` por subrutas como `/api/zapatos/{id}`.

### 3.3. Prohibiciones Expresas del Contrato
- **No borrado**: El enunciado y la guía técnica prohíben operaciones de borrado en la API de negocio.
- **No edición/actualización**: No se implementan métodos `PUT` ni `PATCH`.
- **No consulta por ID**: No se expone `GET /api/zapatos/{id}`.
- **No frontend**: No se implementa interfaz de usuario gráfica ni vistas HTML. Pruebas realizadas exclusivamente mediante Postman / HTTP.
- **No Spring Data REST**: El controlador debe ser explícito con `@RestController` y DTOs dedicados.

## 4. Arquitectura y Componentes del Sistema

```text
Postman -> Pasarela Gateway (:18080) -> Servicio Zapatos (:18761) -> MySQL (:3308 local / :3306 docker)
                 |                            |
                 +---- Servidor Eureka (:18760) (Registro y Descubrimiento)
```

| Componente | Carpeta / Directorio | Nombre de Aplicación (`spring.application.name`) | Paquete Base Java | Puerto Local |
|---|---|---|---|---|
| Servidor Eureka | `servidor-eureka` | `servidor-eureka` | `com.pasofirme.eureka` | 18760 |
| Servicio de Negocio | `servicio-zapatos` | `servicio-zapatos` | `com.pasofirme.zapatos` | 18761 |
| Pasarela Gateway | `pasarela-gateway` | `pasarela-gateway` | `com.pasofirme.gateway` | 18080 |
| Base de Datos | `mysql` (Docker) | N/A | N/A | Host: 3308 (propuesto por estar 3307 ocupado por contenedor ajeno) -> Contenedor: 3306 |

### 4.1. Base de Datos MySQL
- Base de datos: `zapatos_db`
- Usuario de aplicación: `zapatos_app`
- Contraseña: Se configurará mediante variables de entorno en archivo `.env` (con plantilla `.env.example`).
- Dialecto y DDL: Hibernate con `ddl-auto=update` para entorno académico.
- Puerto host en modo local: `3308` propuesto (mapeado a `3306` en el contenedor para evitar colisión con el contenedor existente en `3307` y el MySQL nativo en `3306`).

## 5. Stack Tecnológico y Compatibilidad
- **Java**: Java 21 (verificado en el entorno con JDK 25 Runtime compatible).
- **Gestor de proyectos**: Maven con Maven Wrapper independiente (`./mvnw.cmd` / `./mvnw`) por cada microservicio.
- **Spring Boot**: `4.1.2` (verificado y resuelto exitosamente desde Maven Central con coordenadas exactas `org.springframework.boot:spring-boot-starter-parent:4.1.2`).
- **Spring Cloud**: `2025.1.4` (utilizando el BOM `org.springframework.cloud:spring-cloud-dependencies:2025.1.4`).
- **Spring Cloud Gateway**: Starter Server Web MVC (`org.springframework.cloud:spring-cloud-starter-gateway-server-webmvc:5.0.4`) con Spring Cloud LoadBalancer.
- **Eureka Client Transport**: `org.springframework.boot:spring-boot-restclient:4.1.2` integrado explícitamente en los tres proyectos.
- **MySQL Docker**: Imagen oficial `mysql:8.4` (LTS) fijada en Compose.

## 6. Modos de Ejecución
1. **Modo Local (Desarrollo)**:
   - MySQL se ejecuta en contenedor Docker exponiendo `127.0.0.1:3308` (para no interferir con el contenedor en 3307).
   - Las 3 aplicaciones Spring Boot corren localmente desde la terminal/IDE.
   - Conexión JDBC a `localhost:3308`.
   - Registro Eureka en `http://localhost:18760/eureka/`.
2. **Modo Docker Completo (Despliegue Contenerizado)**:
   - Los 4 servicios (`servidor-eureka`, `servicio-zapatos`, `pasarela-gateway`, `mysql`) se orquestan en una red común de Docker Compose.
   - La comunicación interna utiliza nombres de servicio DNS de Docker (`mysql:3306`, `http://servidor-eureka:18760/eureka/`, `servicio-zapatos:18761`).
   - El puerto del Gateway expuesto al host es el 18080.

## 7. Criterios de Aceptación Enumerados
1. Tres proyectos Maven con Wrapper funcional compilables de forma independiente (`mvnw clean package`).
2. Mismas versiones de Spring Boot y Spring Cloud gestionadas uniformemente mediante BOM.
3. Tabla `zapato` creada en MySQL con exactamente 6 columnas (`id`, `marca`, `talla`, `precio`, `fecha_ingreso`, `disponible`).
4. Inserción exitosa de registros válidos mediante `POST /api/zapatos` a través del Gateway (HTTP 201).
5. Consulta exitosa de registros mediante `GET /api/zapatos` a través del Gateway (HTTP 200).
6. Validación rigurosa de entradas y respuesta `400 Bad Request` ante datos inválidos.
7. Rechazo estricto de borrado y modificación (`405 Method Not Allowed` / `404 Not Found`).
8. Descubrimiento dinámico en Eureka con `SERVICIO-ZAPATOS` y `PASARELA-GATEWAY` en estado `UP`.
9. Persistencia de datos comprobada tras reiniciar el contenedor MySQL conservando el volumen Docker.
10. Funcionamiento verificado en Modo Docker Completo con resolución de nombres internos.
11. Colección de Postman exportada en `docs/` lista para importar y ejecutar.
12. Ausencia de afirmaciones no comprobadas y registro estricto en `docs/ESTADO.md`.
