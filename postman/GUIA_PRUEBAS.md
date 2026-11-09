# Guía de Ejecución de Pruebas con Postman - PasoFirme

Esta guía detalla los pasos para importar, configurar y ejecutar la suite de pruebas funcionales y de contrato de **PasoFirme** utilizando la herramienta oficial **Postman**.

---

## 1. Requisitos Previos

Antes de ejecutar las pruebas, asegúrese de que el entorno distribuido esté activo:
1. **MySQL 8.4** en Docker (`pasofirme-mysql`, puerto host `3308`).
2. **Servidor Eureka** (`servidor-eureka`, puerto `18760`).
3. **Servicio Zapatos** (`servicio-zapatos`, puerto `18761`).
4. **Pasarela Gateway** (`pasarela-gateway`, puerto `18080`).

> [!IMPORTANT]
> Todas las peticiones de negocio van dirigidas exclusivamente a la pasarela en `http://localhost:18080`. Ninguna petición debe enviarse directamente al puerto del servicio (`18761`).

---

## 2. Archivos Generados

En la carpeta [postman/](./) se encuentran:
- **Colección**: `postman/PasoFirme.postman_collection.json` (Esquema Postman v2.1.0).
- **Entorno Local**: `postman/PasoFirme-local.postman_environment.json` (Define `baseUrl = http://localhost:18080`).
- **Guía**: `postman/GUIA_PRUEBAS.md` (Este documento).

---

## 3. Procedimiento de Importación en Postman

1. Abra **Postman** (versión de escritorio o web).
2. En la barra superior izquierda, haga clic en el botón **Import**.
3. Arrastre o seleccione los siguientes archivos desde el repositorio:
   - `postman/PasoFirme.postman_collection.json`
   - `postman/PasoFirme-local.postman_environment.json`
4. Confirme la importación. Verá:
   - En la sección **Collections**: la colección **PasoFirme** organizada en cuatro carpetas.
   - En la sección **Environments**: el entorno **PasoFirme - Local**.

---

## 4. Selección del Entorno

1. En la esquina superior derecha de la interfaz de Postman, abra el desplegable de entornos (por defecto dirá *No Environment*).
2. Seleccione **PasoFirme - Local**.
3. Verifique que la variable `baseUrl` tenga el valor actual:
   - `baseUrl` -> `http://localhost:18080`

---

## 5. Ejecución Automática con Collection Runner

1. En la barra lateral de Collections, seleccione **PasoFirme**.
2. Haga clic en el botón **Run** (o **Run collection**).
3. En la pantalla del Collection Runner:
   - Verifique que las 22 peticiones estén seleccionadas.
   - **Environment**: Asegúrese de que esté seleccionado `PasoFirme - Local`.
   - **Iterations**: `1`.
   - **Delay**: `0 ms` (o `100 ms` si desea visualizar cada paso).
   - **Data**: Dejar vacío.
   - **Keep variable values**: Opcional (los scripts usan `pm.collectionVariables` dinámicas y la primera petición incluye un script previo que reinicia automáticamente variables transitorias como IDs, snapshots y conteos, sin alterar `baseUrl` ni borrar registros).
4. Haga clic en **Run PasoFirme**.
5. Observe la ejecución secuencial y el reporte de pruebas (`pm.test`).

---

## 6. Estructura de la Colección y Casos Previstos

### Carpeta 01: Flujo Principal de Negocio
| # | Petición | Método y Ruta | Código Esperado | Aserciones Principales |
|---|---|---|---|---|
| 1 | `01 - GET Inicial Zapatos` | `GET {{baseUrl}}/api/zapatos` | `200 OK` | Arreglo JSON válido. Registra IDs iniciales sin forzar base vacía. |
| 2 | `02 - POST Zapato 1 (Bata)` | `POST {{baseUrl}}/api/zapatos` | `201 Created` | ID entero positivo, datos exactos (`Bata`, `39`, `129900.50`, `2026-10-27`, `true`). Guarda `id1`. |
| 3 | `03 - POST Zapato 2 (Adidas - disponible false)` | `POST {{baseUrl}}/api/zapatos` | `201 Created` | ID entero positivo distinto de `id1`, `disponible === false` estricto (no muta a null). Guarda `id2`. |
| 4 | `04 - GET Zapatos (Verificar id1 e id2 y 6 campos)` | `GET {{baseUrl}}/api/zapatos` | `200 OK` | La lista contiene `id1` e `id2`. Cada objeto tiene exactamente los 6 campos: `id`, `marca`, `talla`, `precio`, `fechaIngreso`, `disponible`. |

### Carpeta 02: Métodos No Permitidos y Protección de Rutas
| # | Petición | Método y Ruta | Código Esperado | Aserciones Principales |
|---|---|---|---|---|
| 5a | `05a - DELETE Colección /api/zapatos` | `DELETE {{baseUrl}}/api/zapatos` | `405 Method Not Allowed` | El servicio rechaza borrado masivo. |
| 5b | `05b - DELETE Elemento /api/zapatos/{{id1}}` | `DELETE {{baseUrl}}/api/zapatos/{{id1}}` | `404 Not Found` | Subruta no mapeada en el contrato. |
| 5c | `05c - PUT /api/zapatos` | `PUT {{baseUrl}}/api/zapatos` | `405 Method Not Allowed` | Cuerpo JSON válido. Rechazo por método no implementado. |
| 5d | `05d - PATCH /api/zapatos` | `PATCH {{baseUrl}}/api/zapatos` | `405 Method Not Allowed` | Cuerpo JSON válido. Rechazo por método no implementado. |
| 6 | `06 - GET Zapatos (Confirmar Integridad tras Rechazos)` | `GET {{baseUrl}}/api/zapatos` | `200 OK` | Compara con la lista previa: los registros `id1` e `id2` permanecen inalterados. |

### Carpeta 03: Validaciones de Negocio y Formato (HTTP 400)
| # | Petición | Método y Ruta | Código Esperado | Aserciones Principales |
|---|---|---|---|---|
| 7a | `07a - POST Sin Campo Marca` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | Falta propiedad obligatoria `marca`. |
| 7b | `07b - POST Marca Vacía` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `marca: ""` viola `@NotBlank`. |
| 7c | `07c - POST Marca Solo Espacios` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `marca: "   "` viola `@NotBlank`. |
| 8a | `08a - POST Talla Cero` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `talla: 0` viola `@Positive`. |
| 8b | `08b - POST Talla Negativa` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `talla: -5` viola `@Positive`. |
| 8c | `08c - POST Precio Negativo` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `precio: -50000.00` viola `@DecimalMin`. |
| 8d | `08d - POST Precio Más de 2 Decimales (1.234)` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | `precio: 1.234` viola `@Digits(fraction=2)`. |
| 8e | `08e - POST Fecha Imposible (2026-02-30)` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | Fecha inexistente rechazada en deserialización. |
| 8f | `08f - POST JSON Mal Formado` | `POST {{baseUrl}}/api/zapatos` | `400 Bad Request` | Sintaxis rota tratada como `HttpMessageNotReadableException`. |
| 8g | `08g - GET Zapatos (Confirmar que los 400 no añadieron filas)` | `GET {{baseUrl}}/api/zapatos` | `200 OK` | Cantidad total idéntica: ninguna petición con 400 persistió registros. |

### Carpeta 04: Contrato Opcional e Inmutabilidad de ID
| # | Petición | Método y Ruta | Código Esperado | Aserciones Principales |
|---|---|---|---|---|
| 9 | `09 - POST Campos Opcionales Omitidos` | `POST {{baseUrl}}/api/zapatos` | `201 Created` | Envía solo `marca: "Puma"`. Los otros cuatro campos se persisten y devuelven como `null`. |
| 10a | `10a - POST con ID Recibido en Body (ID Ignorado)` | `POST {{baseUrl}}/api/zapatos` | `201 Created` | Envía `id: {{id1}}`. El ID recibido es ignorado y se asigna un nuevo ID autoincremental (`idNuevo !== id1`). |
| 10b | `10b - GET Zapatos (Verificar Inmutabilidad de id1)` | `GET {{baseUrl}}/api/zapatos` | `200 OK` | Constata que `id1` conserva los datos originales de "Bata" y que existen `idNuevo` y `idOpcional`. |

---

## 7. Notas sobre Ejecuciones Repetidas

- La colección está diseñada sin dependencia del orden absoluto ni de IDs fijos correlativos (1, 2, 3...). En cada ejecución, los scripts extraen los identificadores devueltos dinámicamente mediante `pm.collectionVariables.set("id1", ...)` y los comparan individualmente por ID.
- Al ejecutar la colección por segunda vez o subsecuentes, los `POST` crearán nuevos registros válidos con IDs autoincrementales superiores. Esto es normal y esperado.
- **No se realizan operaciones destructivas de limpieza** (`TRUNCATE` o `DROP`), respetando la regla arquitectónica de no borrar datos para preparar pruebas.

---

## 8. Matriz de Resultados de Ejecución

La colección fue ejecutada formalmente en **Postman Desktop** contra el entorno local `http://localhost:18080`, alcanzando **100% de éxito (31/31 aserciones aprobadas, 0 fallidas, 0 errores)**:

| ID Caso | Nombre de Prueba | Validación Estática | Ejecución en Postman | Resultado Observado |
|---|---|:---:|:---:|:---:|
| CP-01 | GET Inicial Zapatos | ✅ Validada | ✅ Aprobada (HTTP 200) | PASS (2 aserciones) |
| CP-02 | POST Zapato 1 (Bata) | ✅ Validada | ✅ Aprobada (HTTP 201) | PASS (2 aserciones) |
| CP-03 | POST Zapato 2 (Adidas, disponible false) | ✅ Validada | ✅ Aprobada (HTTP 201) | PASS (2 aserciones) |
| CP-04 | GET Verificación id1 e id2 (6 campos) | ✅ Validada | ✅ Aprobada (HTTP 200) | PASS (2 aserciones) |
| CP-05a | DELETE Colección /api/zapatos (405) | ✅ Validada | ✅ Aprobada (HTTP 405) | PASS (1 aserción) |
| CP-05b | DELETE Elemento /api/zapatos/{id} (404) | ✅ Validada | ✅ Aprobada (HTTP 404) | PASS (1 aserción) |
| CP-05c | PUT /api/zapatos (405) | ✅ Validada | ✅ Aprobada (HTTP 405) | PASS (1 aserción) |
| CP-05d | PATCH /api/zapatos (405) | ✅ Validada | ✅ Aprobada (HTTP 405) | PASS (1 aserción) |
| CP-06 | GET Integridad tras Métodos Rechazados | ✅ Validada | ✅ Aprobada (HTTP 200) | PASS (2 aserciones) |
| CP-07a | POST Sin Campo Marca (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-07b | POST Marca Vacía (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-07c | POST Marca Solo Espacios (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08a | POST Talla Cero (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08b | POST Talla Negativa (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08c | POST Precio Negativo (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08d | POST Precio >2 Decimales (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08e | POST Fecha Imposible 2026-02-30 (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08f | POST JSON Mal Formado (400) | ✅ Validada | ✅ Aprobada (HTTP 400) | PASS (1 aserción) |
| CP-08g | GET Verificación No Inserción de 400 | ✅ Validada | ✅ Aprobada (HTTP 200) | PASS (2 aserciones) |
| CP-09 | POST Campos Opcionales Omitidos (201) | ✅ Validada | ✅ Aprobada (HTTP 201) | PASS (2 aserciones) |
| CP-10a | POST con ID Recibido Ignorado (201) | ✅ Validada | ✅ Aprobada (HTTP 201) | PASS (2 aserciones) |
| CP-10b | GET Verificación Inmutabilidad id1 | ✅ Validada | ✅ Aprobada (HTTP 200) | PASS (2 aserciones) |

Las capturas de pantalla de la ejecución y el informe JSON de la corrida están disponibles en [docs/evidencias/](../docs/evidencias/README.md).
