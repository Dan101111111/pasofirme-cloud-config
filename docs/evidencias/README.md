# Evidencias de Pruebas y Validación Funcional - PasoFirme

Este directorio almacena las evidencias formales de ejecución de la suite de pruebas del proyecto **PasoFirme**, ejecutadas mediante el **Collection Runner** de Postman Desktop contra la arquitectura contenerizada en `http://localhost:18080`.

---

## 1. Resumen de la Ejecución Observada

| Métrica | Valor Observado |
|---|---|
| **Colección** | PasoFirme |
| **Entorno** | PasoFirme - Local (`baseUrl = http://localhost:18080`) |
| **Iteraciones** | 1 |
| **Solicitudes Ejecutadas** | **22** (100% de la colección) |
| **Aserciones Aprobadas (`Passed`)** | **31** |
| **Aserciones Fallidas (`Failed`)** | **0** |
| **Aserciones Omitidas (`Skipped`)** | **0** |
| **Errores de Ejecución (`Errors`)** | **0** |
| **Duración de la Corrida** | 1 s 772 ms (promedio: 31 ms por solicitud) |
| **Tasa de Aprobación** | **100% (31 / 31)** |

> [!NOTE]
> **Alcance de la evidencia:** Esta ejecución certifica la totalidad del contrato funcional HTTP (validaciones 400, rechazo de métodos 405/404, omisión de opcionales con `null` e inmutabilidad de ID en POST). La prueba de persistencia ante reinicio del motor MySQL corresponde a una comprobación de infraestructura independiente (detallada en `docs/DEMOSTRACION.md` y `docs/ESTADO.md`).

---

## 2. Inventario de Archivos de Evidencia

### 2.1. Informe JSON de Postman Runner
- **Archivo**: [postman/resultado-ejecucion.json](postman/resultado-ejecucion.json)
- **Contenido**: Exportación nativa del informe de corrida de Postman Runner. Registra el identificador de ejecución (`6ae16b2dc41e5ff9b51c0237`), nombre de la colección, variables de entorno, `totalPass: 31`, `totalFail: 0`, `count: 1` y los identificadores de las 22 solicitudes de la colección.
- **Detalle técnico**: Como ocurre de forma estándar en las exportaciones de Postman Runner, el resumen contiene los contadores consolidados y el arreglo `results` vacío; las capturas de pantalla adjuntas complementan y evidencian la totalidad de las 22 solicitudes individuales y sus códigos HTTP.

### 2.2. Capturas de Pantalla de la Ejecución en Postman Desktop

#### 1. [01-registro-consulta-y-rechazo-eliminacion.png](postman/01-registro-consulta-y-rechazo-eliminacion.png)
Evidencia las primeras solicitudes del flujo principal y protección de rutas (Solicitudes 01 a 05b):
- **01 - GET Inicial Zapatos**: HTTP 200 OK. Script previo reinicia variables transitorias (`id1`, `id2`, etc.) y captura `initialIds` sin alterar los registros existentes (como el registro `DockerBoot`).
- **02 - POST Zapato 1 (Bata)**: HTTP 201 Created. Registro de calzado completo con ID autoincremental positivo generado en MySQL.
- **03 - POST Zapato 2 (Adidas - disponible false)**: HTTP 201 Created. ID autoincremental distinto y preservación estricta del valor booleano `false` (sin mutación a `null`).
- **04 - GET Zapatos (Verificar id1 e id2 y 6 campos)**: HTTP 200 OK. Presencia de ambos calzados con exactamente 6 campos del contrato (`id`, `marca`, `talla`, `precio`, `fechaIngreso`, `disponible`).
- **05a - DELETE Colección /api/zapatos**: HTTP 405 Method Not Allowed emitido por el servicio backend a través de la pasarela Gateway.
- **05b - DELETE Elemento /api/zapatos/{{id1}}**: HTTP 404 Not Found, confirmando que la API no expone subrutas con parámetro de ID.

#### 2. [02-metodos-rechazados-y-marca-obligatoria.png](postman/02-metodos-rechazados-y-marca-obligatoria.png)
Evidencia la protección de métodos HTTP, integridad y validaciones de campo obligatorio (Solicitudes 05c a 08a):
- **05c - PUT /api/zapatos**: HTTP 405 Method Not Allowed.
- **05d - PATCH /api/zapatos**: HTTP 405 Method Not Allowed.
- **06 - GET Zapatos (Confirmar Integridad tras Rechazos)**: HTTP 200 OK. Comprueba que las operaciones rechazadas (`DELETE`, `PUT`, `PATCH`) no modificaron ni eliminaron ningún dato.
- **07a - POST Sin Campo Marca**: HTTP 400 Bad Request por validación `@NotBlank`.
- **07b - POST Marca Vacía**: HTTP 400 Bad Request por validación `@NotBlank`.
- **07c - POST Marca Solo Espacios**: HTTP 400 Bad Request por validación `@NotBlank`.
- **08a - POST Talla Cero**: HTTP 400 Bad Request por validación `@Positive`.

#### 3. [03-validaciones-y-ausencia-de-inserciones.png](postman/03-validaciones-y-ausencia-de-inserciones.png)
Evidencia las validaciones numéricas, de fecha, de formato JSON y omisión de opcionales (Solicitudes 08b a 09):
- **08b - POST Talla Negativa**: HTTP 400 Bad Request por validación `@Positive`.
- **08c - POST Precio Negativo**: HTTP 400 Bad Request por validación `@DecimalMin("0.00")`.
- **08d - POST Precio Más de 2 Decimales (1.234)**: HTTP 400 Bad Request por validación `@Digits`.
- **08e - POST Fecha Imposible (2026-02-30)**: HTTP 400 Bad Request por error de deserialización de fecha.
- **08f - POST JSON Mal Formado**: HTTP 400 Bad Request por `HttpMessageNotReadableException`.
- **08g - GET Zapatos (Confirmar que los 400 no añadieron filas)**: HTTP 200 OK. Comprueba que ninguna solicitud errónea incrementó el número de filas en MySQL.
- **09 - POST Campos Opcionales Omitidos**: HTTP 201 Created con solo `marca: "Puma"`, comprobando que los otros 4 campos se persisten y retornan como `null`.

#### 4. [04-campos-opcionales-e-id-generado.png](postman/04-campos-opcionales-e-id-generado.png)
Evidencia la inmutabilidad de ID recibido y cierre de la suite (Solicitudes 08e a 10b):
- **10a - POST con ID Recibido en Body (ID Ignorado)**: HTTP 201 Created. Se envía un `id` en el cuerpo del JSON; el sistema lo ignora y asigna un nuevo ID autoincremental.
- **10b - GET Zapatos (Verificar Inmutabilidad de id1)**: HTTP 200 OK. Comprueba que el registro original `id1` mantiene intactos sus datos ("Bata", 39, etc.) y que coexiste con el nuevo registro creado.
