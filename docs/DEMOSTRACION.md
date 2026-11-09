# Guion de Sustentación Académica - PasoFirme

Este documento provee una guía paso a paso para sustentar y demostrar el funcionamiento del sistema distribuido **PasoFirme** ante evaluadores o docentes, junto con las evidencias y capturas de pantalla sugeridas para el informe académico.

---

## 1. Resumen de la Arquitectura a Sustentar

Durante la sustentación, presente la solución explicando sus componentes:
- **Pasarela API Gateway** (`pasarela-gateway`, puerto `18080`): Punto de entrada único para los clientes. Desarrollado con Spring Cloud Gateway Server Web MVC y Spring Cloud LoadBalancer.
- **Servidor de Descubrimiento** (`servidor-eureka`, puerto `18760`): Registro dinámico de microservicios con Netflix Eureka Server.
- **Microservicio de Negocio** (`servicio-zapatos`, puerto `18761`): Dominio de calzados con persistencia Spring Data JPA y validaciones Jakarta Validation. Puerto accesible exclusivamente en la red interna de Docker.
- **Base de Datos Relacional** (`pasofirme-mysql`, puerto `3308`): MySQL 8.4 LTS con volumen persistente nombrado `pasofirme_mysql_data`.

---

## 2. Pasos para la Demostración en Vivo

### Paso 1: Validación y Salud de Contenedores

**Comandos en PowerShell:**
```powershell
# 1. Validar la sintaxis combinada de Compose sin exponer secretos
docker compose -f compose.yaml -f compose.app.yaml config --quiet

# 2. Consultar el estado de salud de los cuatro contenedores
docker compose -f compose.yaml -f compose.app.yaml ps
```

**Qué explicar:**
- La validación con `config --quiet` verifica la estructura YAML y variables sin volcar credenciales ni secretos en pantalla.
- Las imágenes de compilación y ejecución emplean etiquetas oficiales mutables de la familia Java 21 (`eclipse-temurin:21-jdk-alpine` y `eclipse-temurin:21-jre-alpine`), sin fijación por digest inmutable.
- Los cuatro contenedores (`pasofirme-mysql`, `pasofirme-eureka`, `pasofirme-servicio-zapatos`, `pasofirme-gateway`) se encuentran activos en estado **`healthy`**.
- La arquitectura utiliza una cadena estricta de dependencias (`depends_on` con `condition: service_healthy`) garantizando que ningún servicio intente operar sin sus prerrequisitos listos.
- `servicio-zapatos` no expone puertos al host, protegiendo el acceso directo y obligando a pasar por el Gateway.

> **📸 Captura recomendada 1:** Terminal mostrando la salida de `docker compose ps` con los 4 contenedores en estado `(healthy)` y los puertos publicados `127.0.0.1:3308`, `127.0.0.1:18760` y `127.0.0.1:18080`.

---

### Paso 2: Verificación del Registro Dinámico en Eureka

**Acción:**
Abra el navegador en `http://localhost:18760` o consulte la API de Eureka en PowerShell:
```powershell
Invoke-RestMethod -Uri "http://localhost:18760/eureka/apps" -Headers @{ "Accept" = "application/json" }
```

**Qué explicar:**
- Ambos microservicios (`PASARELA-GATEWAY` y `SERVICIO-ZAPATOS`) aparecen registrados dinámicamente con estado **`UP`**.
- Se usan hostnames resolubles de Docker (`pasarela-gateway`, `servicio-zapatos`) e IPs de la red interna `pasofirme-net`, sin depender de `localhost` entre contenedores.

> **📸 Captura recomendada 2:** Navegador web en `http://localhost:18760` mostrando el dashboard oficial de Eureka con las instancias en `Instances currently registered with Eureka`.

---

### Paso 3: Inspección del Esquema de Base de Datos en MySQL

**Comando en PowerShell:**
```powershell
docker compose exec mysql mysql -u zapatos_app -p zapatos_db
```
*(Introduzca la contraseña del usuario `zapatos_app` de forma interactiva cuando la consola lo solicite; no se imprimen ni guardan contraseñas en la documentación).*

Una vez abierta la sesión interactiva de MySQL, ejecute:
```sql
SHOW COLUMNS FROM zapato;
```

**Qué explicar:**
- La tabla `zapato` fue generada automáticamente por Hibernate en la base de datos `zapatos_db`.
- Posee **exactamente seis columnas**: `id` (bigint auto_increment), `marca` (varchar(100) not null), `talla` (int), `precio` (decimal(10,2)), `fecha_ingreso` (date) y `disponible` (bit(1)).
- No existen campos de auditoría ni tablas adicionales que violen el contrato mínimo solicitado.

> **📸 Captura recomendada 3:** Salida del comando `SHOW COLUMNS FROM zapato;` en terminal evidenciando la estructura de las 6 columnas y sus tipos de datos.

---

### Paso 4: Creación de un Calzado Válido vía Gateway (POST)

**Petición HTTP en Postman o PowerShell:**
- **Método y URL:** `POST http://localhost:18080/api/zapatos`
- **Headers:** `Content-Type: application/json`
- **Cuerpo:**
  ```json
  {
    "marca": "Bata",
    "talla": 39,
    "precio": 129900.50,
    "fechaIngreso": "2026-10-27",
    "disponible": true
  }
  ```

**Qué explicar:**
- La petición se envía al puerto de la pasarela (`18080`), la cual resuelve la ubicación del servicio de zapatos a través de Eureka (`lb://servicio-zapatos`).
- El servidor responde con código **`201 Created`** y devuelve el objeto persistido con su `id` positivo autoincremental generado por MySQL.

> **📸 Captura recomendada 4:** Ventana de Postman enviando el POST y recibiendo el código 201 Created con el JSON de respuesta.

---

### Paso 5: Consulta de Calzados Registrados vía Gateway (GET)

**Petición HTTP en Postman o PowerShell:**
- **Método y URL:** `GET http://localhost:18080/api/zapatos`

**Qué explicar:**
- Responde con código **`200 OK`** y el arreglo JSON con todos los calzados registrados.
- Cada elemento contiene exactamente las 6 propiedades del contrato de negocio.

> **📸 Captura recomendada 5:** Ventana de Postman con la petición GET y el cuerpo de respuesta 200 OK en formato JSON.

---

### Paso 6: Intento de Métodos No Permitidos (DELETE / PUT / PATCH)

**Petición HTTP en Postman o PowerShell:**
- **Método y URL:** `DELETE http://localhost:18080/api/zapatos`

**Qué explicar:**
- El contrato prohíbe operaciones destructivas o de modificación en la API pública.
- La pasarela Gateway reenvía el método `DELETE` hacia el microservicio `servicio-zapatos` sin bloquearlo prematuramente, y el controlador del microservicio emite un código **`405 Method Not Allowed`**.
- De igual forma, peticiones a subrutas inexistentes como `DELETE http://localhost:18080/api/zapatos/1` devuelven **`404 Not Found`**.

> **📸 Captura recomendada 6:** Petición DELETE en Postman mostrando la respuesta `405 Method Not Allowed`.

---

### Paso 7: Comprobación de Integridad de Datos

**Petición HTTP en Postman o PowerShell:**
- **Método y URL:** `GET http://localhost:18080/api/zapatos`

**Qué explicar:**
- Tras los intentos de borrado rechazados, se repite la consulta `GET`.
- Se confirma que todos los registros continúan intactos en la base de datos, demostrando que las restricciones de la API protegen los datos contra modificaciones o eliminaciones indebidas.

> **📸 Captura recomendada 7:** Petición GET posterior confirmando que los registros persisten inalterados.

---

### Paso 8: Demostración de Persistencia ante Reinicio de MySQL

**Comando en PowerShell:**
```powershell
docker restart pasofirme-mysql
```

**Qué explicar:**
- Se reinicia físicamente el contenedor de la base de datos `pasofirme-mysql`.
- Al reiniciar, la conexión del pool Hikari en el servicio se restablece automáticamente.
- Se ejecuta nuevamente `GET http://localhost:18080/api/zapatos` y los registros se recuperan intactos gracias al volumen Docker nombrado `pasofirme_mysql_data`.
- Esto comprueba que la persistencia es real y no depende de la vida del contenedor.

> **📸 Captura recomendada 8:** Terminal ejecutando `docker restart pasofirme-mysql` y la respuesta HTTP 200 subsiguiente de la API con los datos preservados.

---

### Paso 9: Suite de Pruebas de Postman y Evidencias

**Qué explicar:**
- El proyecto incluye una colección Postman v2.1 formal con **22 solicitudes** y scripts `pm.test` en [postman/PasoFirme.postman_collection.json](../postman/PasoFirme.postman_collection.json) y su entorno [postman/PasoFirme-local.postman_environment.json](../postman/PasoFirme-local.postman_environment.json).
- **Ejecución Formal Completada:** La suite completa de 22 peticiones fue ejecutada en Postman Desktop obteniendo **31 de 31 aserciones aprobadas (100% de éxito, 0 fallidas, 0 errores)**.
- **Evidencias Documentadas:** Las cuatro capturas de pantalla de la corrida y la exportación JSON del informe se encuentran disponibles y catalogadas en [docs/evidencias/README.md](evidencias/README.md).
- **Tolerancia a datos existentes:** La primera solicitud de la colección ejecuta un script previo que limpia variables transitorias (`id1`, `id2`, etc.) y captura los IDs existentes (`initialIds`), de modo que registros previos (como el calzado `DockerBoot` creado en pruebas de persistencia) son tolerados perfectamente y no se exige una base vacía.

> **📸 Captura recomendada 9:** Vista general del informe de ejecución del Collection Runner en Postman Desktop mostrando las 31 aserciones en estado `Passed` (disponible en [evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png](evidencias/postman/01-registro-consulta-y-rechazo-eliminacion.png)).

---

### Paso 10: Demostración de Alternancia entre Modos (Si se solicita)

Si el evaluador solicita comprobar la ejecución nativa en el host (Modo Local):

1. **Detener contenedores de aplicación conservando MySQL y los datos:**
   ```powershell
   docker compose -f compose.yaml -f compose.app.yaml down
   docker compose up -d mysql
   ```
2. **Cargar variables y arrancar servicios locales en PowerShell:**
   ```powershell
   . .\scripts\set-local-env.ps1
   powershell -ExecutionPolicy Bypass -File servidor-eureka\start-eureka.ps1
   powershell -ExecutionPolicy Bypass -File servicio-zapatos\start-servicio.ps1
   powershell -ExecutionPolicy Bypass -File pasarela-gateway\start-gateway.ps1
   ```
3. **Comprobar persistencia:** Los mismos registros (incluyendo `DockerBoot`) responden inmediatamente en `http://localhost:18080/api/zapatos`.
4. **Regresar a Modo Docker:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File pasarela-gateway\stop-gateway.ps1
   powershell -ExecutionPolicy Bypass -File servicio-zapatos\stop-servicio.ps1
   powershell -ExecutionPolicy Bypass -File servidor-eureka\stop-eureka.ps1
   docker compose -f compose.yaml -f compose.app.yaml up -d --build
   ```
