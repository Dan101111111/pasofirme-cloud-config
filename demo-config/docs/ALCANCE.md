# Alcance y Especificación Técnica: Demostración Spring Cloud Config

**Proyecto**: PasoFirme  
**Subproyecto / Módulo**: `demo-config/`  
**Fecha de definición**: 8 de noviembre de 2026  
**Entorno de ejecución**: Java 21 LTS | Maven Wrapper 3.10.0 | Spring Boot 4.1.2 | Spring Cloud 2025.1.4  

---

## 1. Propósito y Objetivos de la Demostración

El propósito de esta demostración es implementar un módulo mínimo, autónomo y desacoplado de **configuración centralizada y dinámica** basado en **Spring Cloud Config** y respaldado por un repositorio **Git** remoto, contextualizado en el dominio comercial de la tienda de calzado **PasoFirme**.

### Repositorios Oficiales del Proyecto:
- **Repositorio de Configuración**: [`https://github.com/Dan101111111/pasofirme-config-repo.git`](https://github.com/Dan101111111/pasofirme-config-repo.git) (Público, rama `main`, contiene los archivos `.properties`).
- **Repositorio de Código del Proyecto**: [`https://github.com/Dan101111111/pasofirme-cloud-config.git`](https://github.com/Dan101111111/pasofirme-cloud-config.git) (Rama `main`, reservado para el código consolidado del sistema y la demo).

### Objetivos Clave:
1. **Centralización**: Separar la configuración del ciclo de vida del código fuente, almacenando propiedades en un repositorio Git independiente (`pasofirme-config-repo`).
2. **Jerarquía y Perfiles**: Demostrar la resolución jerárquica de propiedades comunes (`application.properties`) y específicas de servicio (`<servicio>-<perfil>.properties`) para los perfiles `dev` y `prod`.
3. **Refresco Dinámico**: Demostrar la actualización en caliente de propiedades de negocio mediante el endpoint `POST /actuator/refresh` con `@RefreshScope`, sin reiniciar los servicios clientes ni provocar caída de servicio.
4. **Aislamiento e Inmutabilidad**: Probar mediante una propiedad singleton (`instanciaArranque` / UUID generado al inicio) que el microservicio no se recrea ni reinicia su JVM tras un refresco.
5. **Cero Impacto en el Sistema Base**: No intervenir los microservicios originales de PasoFirme (`servidor-eureka`, `servicio-zapatos`, `pasarela-gateway`), sus archivos Docker Compose, sus suites de pruebas Postman, sus evidencias ni el volumen de base de datos MySQL `pasofirme_mysql_data`.

---

## 2. Arquitectura de la Demostración

```
┌────────────────────────────────────────────────────────┐
│         Repositorio Remoto GitHub (Público)            │
│               "pasofirme-config-repo"                  │
│  - application.properties (común: tienda, edicion)     │
│  - catalogo-demo-{dev,prod}.properties                │
│  - ofertas-demo-{dev,prod}.properties                 │
│  - envios-demo-{dev,prod}.properties                  │
└───────────────────────────┬────────────────────────────┘
                            │
                            │ HTTPS (Git clone/pull)
                            ▼
┌────────────────────────────────────────────────────────┐
│             config-server-demo (Puerto 18888)          │
│       Spring Cloud Config Server 5.0.6 + Actuator      │
│          Expone: /{application}/{profile}/{label}      │
└──────────────┬────────────┼────────────┬───────────────┘
               │            │            │
  HTTP Config  │            │            │ HTTP Config Data
  Data en boot │            │            │ en boot y refresh
  y refresh    │            │            │
       ┌───────┘            │            └───────┐
       ▼                    ▼                    ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│catalogo-demo │     │ ofertas-demo │     │ envios-demo  │
│(Puerto 18881)│     │(Puerto 18882)│     │(Puerto 18883)│
└──────────────┘     └──────────────┘     └──────────────┘
  GET /api/demo        GET /api/demo        GET /api/demo
  POST /actuator/      POST /actuator/      POST /actuator/
       refresh              refresh              refresh
```

### Principios de Comunicación:
- **Flujo de configuración**: Los microservicios clientes consultan a `config-server-demo` durante su arranque inicial (`spring.config.import=configserver:...`) y únicamente cuando se invoca explícitamente su endpoint de refresco `POST /actuator/refresh`.
- **Independencia en peticiones de negocio**: Las peticiones de negocio (`GET /api/demo`) van dirigidas directamente a cada cliente; en ningún caso pasan ni se enrutan a través del `config-server-demo`.
- **Sin acceso directo a GitHub desde clientes**: Los clientes nunca leen directamente de GitHub; es el Config Server quien clona e inspecciona el repositorio Git y expone el Environment procesado.

---

## 3. Matriz de Componentes, Puertos y Paquetes

| Componente | Carpeta / Proyecto | Puerto Host | Paquete Java Base | Rol y Responsabilidad |
|---|---|:---:|---|---|
| **Config Server Demo** | `demo-config/config-server-demo` | **18888** | `com.pasofirme.configdemo.server` | Servidor central Spring Cloud Config Server conectado al repositorio Git remoto vía HTTPS. Entrega configuraciones versionadas. |
| **Catálogo Demo** | `demo-config/catalogo-demo` | **18881** | `com.pasofirme.configdemo.catalogo` | Cliente Spring Cloud Config. Expone datos configurados del catálogo de calzado (temporadas, líneas de producto). |
| **Ofertas Demo** | `demo-config/ofertas-demo` | **18882** | `com.pasofirme.configdemo.ofertas` | Cliente Spring Cloud Config. Expone datos configurados de promociones y descuentos aplicables al calzado. |
| **Envíos Demo** | `demo-config/envios-demo` | **18883** | `com.pasofirme.configdemo.envios` | Cliente Spring Cloud Config. Expone datos configurados de logística, tiempos de despacho y cobertura de envíos. |

### Verificación de Puertos y Ausencia de Conflictos:
- Los puertos del equipo asignados a la demo (`18888`, `18881`, `18882`, `18883`) han sido comprobados mediante inspección de red del sistema operativo (`netstat` / `Get-NetTCPConnection`) y se encuentran completamente libres.
- **Aislamiento frente a PasoFirme Base**:
  - `servidor-eureka`: Puerto `18760` (sin solapamiento).
  - `servicio-zapatos`: Puerto `18761` (sin solapamiento).
  - `pasarela-gateway`: Puerto `18080` (sin solapamiento).
  - `pasofirme-mysql`: Puerto `3308` (sin solapamiento).
- Ningún proceso preexistente en la máquina anfitriona será finalizado ni alterado.

---

## 4. Coordenadas y Versiones Tecnológicas

Para mantener coherencia rigurosa con la arquitectura preexistente de PasoFirme, la demo utiliza las mismas versiones oficiales verificadas:

| Dependencia / Herramienta | Coordenada / Versión | Origen / Verificación |
|---|---|---|
| **Java Platform** | `21 LTS` | Oracle JDK 25 Runtime en modo de compatibilidad Java 21 / Docker Alpine Temurin 21 |
| **Maven Wrapper** | `3.10.0` (Apache Maven) | Wrapper incluido en cada proyecto independiente (`mvnw.cmd` / `mvnw`) |
| **Spring Boot Parent** | `4.1.2` | `org.springframework.boot:spring-boot-starter-parent:4.1.2` |
| **Spring Cloud BOM** | `2025.1.4` | `org.springframework.cloud:spring-cloud-dependencies:2025.1.4` (`<scope>import</scope>`) |
| **Spring Cloud Config Server** | `5.0.6` | Resuelto automáticamente por el BOM (`spring-cloud-config-server`) |
| **Spring Cloud Config Client** | `5.0.6` | Resuelto automáticamente por el BOM (`spring-cloud-starter-config`) |
| **Spring Boot Actuator** | `4.1.2` | Resuelto por Spring Boot Parent (`spring-boot-starter-actuator`) |
| **Spring Boot Web MVC** | `4.1.2` | Resuelto por Spring Boot Parent (`spring-boot-starter-web`) |

### Regla de Oro sobre Dependencias:
- **Uso estricto del BOM**: Ningún módulo de `demo-config/` fijará manualmente versiones individuales de artefactos de Spring Cloud en sus `<dependencies>`. Todas las versiones se derivan del BOM oficial `spring-cloud-dependencies:2025.1.4`.
- **Prohibido el bypass de compatibilidad**: Está terminantemente prohibido incorporar `spring.cloud.compatibility-verifier.enabled=false` para disimular errores de resolución. Las dependencias deben resolver de manera nativa y limpia.

---

## 5. Reglas, Restricciones y Alcance Negativo (Límites Estrictos)

Para garantizar ligereza, rapidez de arranque y estricto apego al requerimiento, se establecen las siguientes restricciones:

1. **Sin Persistencia de Datos**:
   - **NO** se permite el uso de Spring Data JPA, Hibernate, JDBC, R2DBC, MySQL, PostgreSQL ni bases de datos en memoria (H2, Derby, HSQLDB).
   - No se crearán `@Entity`, `@Repository`, `DataSource` ni scripts SQL (`schema.sql`, `data.sql`).
2. **Sin Eureka ni Pasarela Gateway en la Demo**:
   - La demo no incluye clientes Eureka (`spring-cloud-starter-netflix-eureka-client`) ni enrutamiento por Gateway.
   - Los clientes se comunican directamente con `config-server-demo` por URL declarativa.
3. **Sin Lógica Comercial Compleja**:
   - **NO** se implementa carrito de compras, catálogo relacional, facturación, pasarela de pagos, login/seguridad JWT ni control de inventario transaccional.
   - El contexto de zapatos se utiliza exclusivamente como semántica de configuración (ej. colecciones, descuentos de temporada, tipos de envío).
4. **Sin Mecanismos de Mensajería para Refresco**:
   - **NO** se incluye Spring Cloud Bus, RabbitMQ, Apache Kafka ni webhooks de GitHub.
   - El refresco dinámico se ejecutará mediante peticiones explícitas `POST /actuator/refresh` a cada cliente individual.
5. **Config Data API de Spring Boot**:
   - No se utiliza el soporte legacy `bootstrap.properties` ni `spring-cloud-starter-bootstrap`.
   - Se emplea `spring.config.import=configserver:${CONFIG_SERVER_URL:...}`.
6. **Inalterabilidad de la Aplicación Base**:
   - Los archivos de `servidor-eureka`, `servicio-zapatos`, `pasarela-gateway`, `compose.yaml`, `compose.app.yaml`, `docs/evidencias/` y el volumen Docker `pasofirme_mysql_data` son sagrados y se mantienen 100% inalterados.

---

## 6. Especificación del Contrato de Configuración y Endpoints

### 6.1. Propiedades en el Repositorio Git (`pasofirme-config-repo`)
- **Comunes** (`application.properties`):
  - `demo.tienda = PasoFirme Calzado Exclusivo`
  - `demo.edicion = Demostración Grupal Spring Cloud Config`
- **Específicas por Servicio y Perfil**:
  - `catalogo-demo-dev.properties` / `catalogo-demo-prod.properties`:
    - `demo.mensaje`: Ej. "Catálogo Colección Urbana 2026 (Entorno Desarrollo)" / "Catálogo Oficial PasoFirme (Producción)"
    - `demo.detalle`: Descripción ficticia de calzados y categorías.
  - `ofertas-demo-dev.properties` / `ofertas-demo-prod.properties`:
    - `demo.mensaje`: Ej. "Descuento demostrativo del 10% en calzado deportivo (Dev)" / "Campaña Oficial: Hasta 40% OFF en Botas de Cuero (Prod)"
    - `demo.detalle`: Condiciones ficticias de promociones.
  - `envios-demo-dev.properties` / `envios-demo-prod.properties`:
    - `demo.mensaje`: Ej. "Despacho prioritario 48 horas en zona urbana (Dev)" / "Red Nacional de Logística PasoFirme Express (Prod)"
    - `demo.detalle`: Zonas de cobertura y tiempos de tránsito.

### 6.2. Endpoint de Negocio de la Demo: `GET /api/demo`
Cada uno de los tres microservicios clientes expondrá exactamente la ruta `GET /api/demo`, retornando un objeto JSON con la siguiente estructura:
```json
{
  "servicio": "catalogo-demo",
  "perfil": "dev",
  "tienda": "PasoFirme Calzado Exclusivo",
  "edicion": "Demostración Grupal Spring Cloud Config",
  "mensaje": "Catálogo Colección Urbana 2026 (Entorno Desarrollo)",
  "detalle": "Muestrario de calzado deportivo y casual para pruebas locales",
  "instanciaArranque": "c7a82b49-51f3-42e1-9876-0bf1d13f9c01"
}
```
- **Campos `tienda` y `edicion`**: Obtenidos desde `application.properties` en Git.
- **Campos `mensaje` y `detalle`**: Obtenidos desde `<servicio>-<perfil>.properties` en Git mediante bean anotado con `@RefreshScope`.
- **Campo `instanciaArranque`**: Generado una única vez al iniciar la aplicación mediante un bean Singleton **no refrescable**. Permite comprobar que tras un `POST /actuator/refresh` los valores de Git cambian pero el identificador de la JVM permanece inalterado.

### 6.3. Endpoint de Refresco: `POST /actuator/refresh`
- Expuesto en cada cliente en los puertos correspondientes (`18881`, `18882`, `18883`).
- Responde con un arreglo JSON con los nombres de las propiedades actualizadas (ej. `["demo.mensaje", "demo.detalle"]`).

---

## 7. Criterios de Aceptación de la Demostración

| Código | Criterio de Aceptación | Método de Verificación |
|---|---|---|
| **CA-01** | **Arranque e Integración Git de Config Server** | `config-server-demo` arranca en el puerto 18888, clona el repositorio Git remoto y expone el Environment completo en `http://localhost:18888/catalogo-demo/dev/main`, retornando `propertySources` pobladas y el hash de commit Git en el campo `version`. |
| **CA-02** | **Arranque de los Tres Clientes con Config Data** | `catalogo-demo` (18881), `ofertas-demo` (18882) y `envios-demo` (18883) inician consumiendo la configuración remota de `config-server-demo` sin errores de importación y sin variables de respaldo locales que enmascaren fallos. |
| **CA-03** | **Lectura Jerárquica y de Perfiles** | El endpoint `GET /api/demo` en cada cliente refleja fielmente las propiedades comunes (`application.properties`) y específicas de su nombre y perfil activo (`dev`/`prod`). |
| **CA-04** | **Refresco Dinámico sin Reinicio de Contenedor/JVM** | Tras modificar `demo.mensaje` en GitHub y registrar el commit en `main`: 1) Config Server muestra el nuevo commit inmediatamente; 2) El cliente conserva el valor previo hasta invocar `POST /actuator/refresh`; 3) Luego del POST, `GET /api/demo` entrega el nuevo mensaje pero conserva exactamente la misma `instanciaArranque`. |
| **CA-05** | **Aislamiento Selectivo de Refresco** | La modificación de propiedades de `catalogo-demo` no altera las propiedades de `ofertas-demo` ni de `envios-demo`. |
| **CA-06** | **Independencia Total de Base de Datos** | Ningún microservicio de la demo carga controladores JDBC, JPA, ni se conecta a MySQL. Si MySQL o Eureka están apagados, la demo de Config opera de manera 100% autónoma. |
| **CA-07** | **Preservación Rigurosa de PasoFirme Original** | Todos los archivos, carpetas, imágenes y volúmenes originales de PasoFirme se conservan íntegros e inalterados. |

