# Etapa 1: Compilación con Maven Wrapper y JDK 21
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Copia de Maven Wrapper y dependencias para cache eficiente
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw
RUN ./mvnw dependency:go-offline -B || true

# Copia de código fuente y empaquetado del artefacto
COPY src/ src/
RUN ./mvnw clean package -DskipTests -B

# Etapa 2: Entorno de ejecución JRE 21
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Herramienta para healthcheck HTTP
RUN apk add --no-cache curl

# Copia determinista del artefacto final reempaquetado
COPY --from=builder /app/target/servidor-eureka-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 18760

ENTRYPOINT ["java", "-jar", "app.jar"]
