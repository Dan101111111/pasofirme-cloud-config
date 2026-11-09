# PasoFirme: Registro de Versiones y Dependencias

- **Fecha de registro**: 27 de octubre de 2026.
- **Fuentes oficiales consultadas**:
  - [Spring Cloud Project](https://spring.io/projects/spring-cloud) (Matriz oficial de compatibilidad).
  - [Maven Central Repository Search](https://search.maven.org/) e inspección directa en `repo.maven.apache.org`.
  - Spring Initializr API (`https://start.spring.io/metadata/client`).

---

## 1. Comprobación y Decisión del Par Compatible

### 1.1. Verificación de Coordenadas Exactas
- **Spring Boot**:
  - Se verificó la coordenada exacta: `org.springframework.boot:spring-boot-starter-parent:4.1.2`.
  - Resultado real: **HTTP 200 OK** en Maven Central (`https://repo.maven.apache.org/maven2/org/springframework/boot/spring-boot-starter-parent/4.1.2/spring-boot-starter-parent-4.1.2.pom`).
  - *Nota técnica*: Las versiones de Spring Boot desde la rama 2.x en adelante no utilizan el sufijo legacy `.RELEASE` (la búsqueda errónea de `4.1.2.RELEASE` no correspondía a la coordenada real).
- **Spring Cloud**:
  - Coordenada exacta: `org.springframework.cloud:spring-cloud-dependencies:2025.1.4`.
  - Resultado real: **HTTP 200 OK** en Maven Central (`https://repo.maven.apache.org/maven2/org/springframework/cloud/spring-cloud-dependencies/2025.1.4/spring-cloud-dependencies-2025.1.4.pom`).
- **Transporte HTTP de Eureka (RestClient)**:
  - Coordenada exacta: `org.springframework.boot:spring-boot-restclient:4.1.2`.
  - Resultado real: **HTTP 200 OK** en Maven Central. Provee el cliente de transporte REST para Eureka Server y Discovery Client.
- **Spring Cloud Gateway Server Web MVC**:
  - Starter: `org.springframework.cloud:spring-cloud-starter-gateway-server-webmvc`.
  - Versión administrada por BOM 2025.1.4: `5.0.4`.

### 1.2. Par Oficial Confirmado y Coherente
Se adopta de forma uniforme en los tres proyectos el par exacto solicitado por el contrato y la guía técnica:
- **Spring Boot**: `4.1.2`
- **Spring Cloud**: `2025.1.4` (BOM `spring-cloud-dependencies:2025.1.4`)
- **Java**: `21`
- **Maven Wrapper**: `3.3.4` (Apache Maven `3.10.0`)

---

## 2. Dependencias por Proyecto

### 2.1. `servidor-eureka`
- **Nombre de aplicación**: `servidor-eureka`
- **Puerto local**: `18760`
- **Paquete Java**: `com.pasofirme.eureka`
- **Dependencias**:
  - `org.springframework.cloud:spring-cloud-starter-netflix-eureka-server` (versión gestionada: `5.0.3`)
  - `org.springframework.boot:spring-boot-restclient` (versión gestionada: `4.1.2`, transporte HTTP RestClient)
  - `org.springframework.boot:spring-boot-starter-test` (ámbito `test`)
- **BOM**: `org.springframework.cloud:spring-cloud-dependencies:2025.1.4` (ámbito `import`)

### 2.2. `servicio-zapatos`
- **Nombre de aplicación**: `servicio-zapatos`
- **Puerto local**: `18761`
- **Paquete Java**: `com.pasofirme.zapatos`
- **Dependencias**:
  - `org.springframework.boot:spring-boot-starter-web` (Web MVC)
  - `org.springframework.boot:spring-boot-starter-data-jpa` (Hibernate / JPA)
  - `org.springframework.boot:spring-boot-starter-validation` (Jakarta Validation)
  - `com.mysql:mysql-connector-j` (ámbito `runtime`)
  - `org.springframework.cloud:spring-cloud-starter-netflix-eureka-client` (Eureka Client versión 5.0.3)
  - `org.springframework.boot:spring-boot-restclient` (transporte HTTP RestClient)
  - `org.springframework.boot:spring-boot-starter-actuator` (versión gestionada: `4.1.2`, soporte para healthchecks de preparación técnica)
  - `org.springframework.boot:spring-boot-starter-test` (ámbito `test`)
- **BOM**: `org.springframework.cloud:spring-cloud-dependencies:2025.1.4` (ámbito `import`)

### 2.3. `pasarela-gateway`
- **Nombre de aplicación**: `pasarela-gateway`
- **Puerto local**: `18080`
- **Paquete Java**: `com.pasofirme.gateway`
- **Dependencias**:
  - `org.springframework.cloud:spring-cloud-starter-gateway-server-webmvc` (Spring Cloud Gateway Server Web MVC versión 5.0.4)
  - `org.springframework.cloud:spring-cloud-starter-netflix-eureka-client` (Eureka Client versión 5.0.3)
  - `org.springframework.cloud:spring-cloud-starter-loadbalancer` (LoadBalancer)
  - `org.springframework.boot:spring-boot-restclient` (transporte HTTP RestClient)
  - `org.springframework.boot:spring-boot-starter-test` (ámbito `test`)
- **BOM**: `org.springframework.cloud:spring-cloud-dependencies:2025.1.4` (ámbito `import`)

---

## 3. Imágenes y Etiquetas Docker Verificadas

- **Base de Datos**:
  - Imagen: `mysql:8.4.3` (Oracle MySQL oficial).
  - Publicación: Host `127.0.0.1:3308` -> Contenedor `3306`.
  - Healthcheck: Conexión autenticada `mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e 'SELECT 1;' $MYSQL_DATABASE`.
- **Compilación de Microservicios (Builder Multietapa)**:
  - Imagen: `eclipse-temurin:21-jdk-alpine` (Etiqueta mutable de la familia Java 21 sobre Alpine Linux; no está fijada por digest inmutable).
  - Herramienta de compilación: Apache Maven 3.10.0 mediante Maven Wrapper del proyecto (`mvnw`).
- **Entorno de Ejecución (Runtime JRE)**:
  - Imagen: `eclipse-temurin:21-jre-alpine` (Etiqueta mutable de la familia JRE 21 sobre Alpine Linux; no está fijada por digest inmutable).
  - Herramienta de healthcheck: `curl` instalado en la etapa runtime mediante `apk add --no-cache curl`.
- **Red y Volúmenes**:
  - Red: `pasofirme-net` (modo bridge).
  - Volumen persistente: `pasofirme_mysql_data` (montado en `/var/lib/mysql`).

