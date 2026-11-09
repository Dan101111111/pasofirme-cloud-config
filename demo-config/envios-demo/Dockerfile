# Etapa 1: Compilacion con Maven Wrapper y JDK 21
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Copia de Maven Wrapper y definicion del proyecto
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw

# Copia de codigo fuente y compilacion limpia
COPY src/ src/
RUN ./mvnw clean package -DskipTests -B

# Etapa 2: Entorno de ejecucion ligero JRE 21
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Herramienta para healthchecks HTTP
RUN apk add --no-cache curl

# Copia determinista del artefacto final
COPY --from=builder /app/target/envios-demo-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 18883

ENTRYPOINT ["java", "-jar", "app.jar"]

