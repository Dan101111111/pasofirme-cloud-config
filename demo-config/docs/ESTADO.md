# Estado Técnico y Registro de Verificaciones: Demo Spring Cloud Config

**Proyecto**: PasoFirme  
**Módulo**: `demo-config/`  
**Última actualización**: 8 de noviembre de 2026  
**Etapa actual**: **Publicación en GitHub y Validación de Clon Limpio (COMPLETADA)**  

---

## 1. Resumen Ejecutivo del Estado del Proyecto

| Etapa | Descripción | Estado | Observaciones / Verificaciones Reales |
|---|---|:---:|---|
| **00** | **Inspección, Compatibilidad y Alcance** | **COMPLETADA** | Verificación de puertos libres, comprobación del BOM Spring Cloud 2025.1.4 y especificación en `ALCANCE.md`. |
| **01** | **Preparación y Publicación de Configuración Git** | **COMPLETADA** | 7 archivos `.properties` + `README.md` subidos a la raíz de `pasofirme-config-repo` (`main`). Commit: `47d0249798495bf2cf4c46fc471134aaa42a4d68`. |
| **02** | **Implementación de Config Server (`config-server-demo`)** | **COMPLETADA** | Proyecto Maven compilado con Wrapper (`BUILD SUCCESS`). Activo en puerto 18888; lectura remota verificada. |
| **03** | **Implementación de los Tres Clientes (`catalogo`, `ofertas`, `envios`)** | **COMPLETADA** | Proyectos Maven compilados (`BUILD SUCCESS`); Config Data estricto sin `optional:`; `@RefreshScope` e `instanciaArranque` inmutable validados en local. |
| **04** | **Contenerización y Orquestación Docker Compose** | **COMPLETADA** | 4 Dockerfiles multietapa (Java 21); `compose.yaml` autónomo (`pasofirme-config-demo`); los 4 contenedores en estado **`Up (healthy)`**; ensayo de clonación limpia auditado. |
| **05** | **Ensayo de Git, Refresh y Entrega de Código** | **COMPLETADA** | Modificación en GitHub (`013b6e49...`); Config Server detectó cambio en vivo; cliente conservó valor viejo hasta `POST /actuator/refresh`; nuevo mensaje verificado manteniendo el mismo UUID; aislamiento demostrado; colección Postman, script de verificación y guion de sustentación generados. |
| **06** | **Publicación Oficial en GitHub y Validación de Clon Limpio** | **COMPLETADA** | Repositorio `pasofirme-cloud-config.git` publicado con commit `3d7ea36`. Exclusión estricta de `.env`, `target/`, logs y archivos sensibles (119 archivos excluidos). Clonación limpia fuera de la carpeta de trabajo y arranque con Docker Compose auditados con éxito. |
| **07** | *(Opcional) Interfaz Web Básica de Exposición* | *PENDIENTE* | Página HTML estática en `catalogo-demo` (puerto 18881). |

---

## 2. Registro de Repositorios Oficiales en GitHub

| Repositorio | URL HTTPS Oficial | Rama | Estado Actual |
|---|---|:---:|---|
| **Configuración** | `https://github.com/Dan101111111/pasofirme-config-repo.git` | `main` | **OPERATIVO / PUBLICADO EN VIVO**. Contiene los 7 archivos `.properties` y el `README.md`. Commits registrados: `6c5c521` (inicial), `47d0249` (carga inicial propiedades), `013b6e4` (actualización demostrativa). |
| **Código del Proyecto** | `https://github.com/Dan101111111/pasofirme-cloud-config.git` | `main` | **PUBLICADO / VERIFICADO**. Código fuente completo de PasoFirme y `demo-config/` publicado en `main` bajo commit `3d7ea36` (preservando el commit inicial `d24e164`). Clonación limpia y arranque verificado. |

---

## 3. Evidencias Reales del Ensayo de Actualización en Caliente (Etapa 05)

La prueba se realizó sobre los cuatro contenedores en ejecución en Docker Desktop (`pasofirme-config-demo`), **sin reconstruir ni reiniciar ningún contenedor**:

### 3.1. Estado Inicial antes de la Modificación
- **Commit en GitHub**: `47d0249798495bf2cf4c46fc471134aaa42a4d68`
- **Catálogo Demo (`GET http://localhost:18881/api/demo`)**:
  - `mensaje`: `"Catalogo Calzado Deportivo y Casual 2026 (Ambiente Desarrollo)"`
  - `instanciaArranque`: `"b21cec63-8238-4fa3-8a0d-b302d2d185c7"`
- **Ofertas Demo (`GET http://localhost:18882/api/demo`)**:
  - `mensaje`: `"Oferta Demostrativa: 10% de descuento en calzado urbano (Ambiente Desarrollo)"`
  - `instanciaArranque`: `"09a84758-d4bc-424e-8ea5-75c37f591517"`
- **Envíos Demo (`GET http://localhost:18883/api/demo`)**:
  - `mensaje`: `"Logistica PasoFirme: Entrega demostrativa en 48 horas (Ambiente Desarrollo)"`
  - `instanciaArranque`: `"57965334-e808-42a3-8109-875f4b73d50d"`

### 3.2. Publicación de Cambio Remoto en GitHub
- Se modificó únicamente el archivo `catalogo-demo-dev.properties` en el repositorio remoto:
  ```properties
  demo.mensaje=Catalogo Calzado Deportivo y Casual 2026 - Coleccion Verano Actualizada (Dev)
  ```
- Se realizó commit y push directo a la rama `main`:
  - **Nuevo Commit SHA**: `013b6e494077a2c6b5c0d901728ad7197cfe0a8a`
  - **Mensaje**: `demo: actualizacion de mensaje de coleccion verano para prueba de refresh dinamico`

### 3.3. Detección en Config Server vs. Memoria del Cliente
- **Config Server (`GET http://localhost:18888/catalogo-demo/dev/main`)**:
  - Reflejó **de inmediato** la nueva versión `013b6e494077a2c6b5c0d901728ad7197cfe0a8a`.
  - Entregó el nuevo mensaje: `"Catalogo Calzado Deportivo y Casual 2026 - Coleccion Verano Actualizada (Dev)"`.
- **Cliente Catálogo (`GET http://localhost:18881/api/demo`)**:
  - Continuó entregando el valor anterior en memoria: `"Catalogo Calzado Deportivo y Casual 2026 (Ambiente Desarrollo)"`.
  - Demostró que el microservicio preserva su estado y no realiza peticiones innecesarias.

### 3.4. Ejecución del Refresco Dinámico (`POST /actuator/refresh`)
- Se invocó `POST http://localhost:18881/actuator/refresh` con `Content-Type: application/json`.
- Respuesta del Actuator:
  ```json
  [
    "config.client.version",
    "demo.mensaje"
  ]
  ```

### 3.5. Estado Posterior al Refresco y Comprobación de Aislamiento
- **Catálogo Demo (`GET http://localhost:18881/api/demo`)**:
  ```json
  {
    "servicio": "catalogo-demo",
    "perfil": "dev",
    "tienda": "PasoFirme",
    "edicion": "Exposicion grupal",
    "mensaje": "Catalogo Calzado Deportivo y Casual 2026 - Coleccion Verano Actualizada (Dev)",
    "detalle": "Coleccion de prueba local con lineas Running, Urban y Senderismo",
    "instanciaArranque": "b21cec63-8238-4fa3-8a0d-b302d2d185c7"
  }
  ```
  - **Nuevo Mensaje**: Aplicado exitosamente.
  - **Inmutabilidad de JVM**: `instanciaArranque` continuó siendo exactamente `"b21cec63-8238-4fa3-8a0d-b302d2d185c7"`, probando que la aplicación **no se reinició**.
- **Aislamiento Verificado**:
  - Ofertas Demo (`18882`): Mensaje inalterado (`10% de descuento`), UUID inalterado (`09a84758-d4bc...`).
  - Envíos Demo (`18883`): Mensaje inalterado (`Entrega 48 horas`), UUID inalterado (`57965334-e808...`).

---

## 4. Auditoría de Criterios de Aceptación (según `ALCANCE.md`)

| Código | Criterio de Aceptación | Estado | Evidencia Concreta |
|---|---|:---:|---|
| **CA-01** | Arranque e integración Git de Config Server | **CUMPLIDO** | `config-server-demo` clona vía HTTPS `pasofirme-config-repo`, expone commit `013b6e4...` y `propertySources` completas. |
| **CA-02** | Tres clientes con Config Data | **CUMPLIDO** | `catalogo`, `ofertas` y `envios` arrancan consumiendo la configuración por `spring.config.import=configserver:...` sin `optional:`. |
| **CA-03** | Lectura jerárquica y por perfil | **CUMPLIDO** | Valores comunes (`demo.tienda=PasoFirme`) y específicos por perfil (`dev` y `prod`) resueltos correctamente. |
| **CA-04** | Refresco dinámico sin reinicio | **CUMPLIDO** | `POST /actuator/refresh` actualizó `demo.mensaje` conservando el mismo UUID `instanciaArranque`. |
| **CA-05** | Aislamiento de refresco | **CUMPLIDO** | Actualizar `catalogo-demo` no afectó a `ofertas-demo` ni a `envios-demo`. |
| **CA-06** | Independencia total de base de datos | **CUMPLIDO** | Cero JPA, JDBC, MySQL, Eureka o Gateway en los microservicios de la demo. |
| **CA-07** | Preservación de PasoFirme original | **CUMPLIDO** | Todo el sistema base (Eureka, Zapatos, Gateway, MySQL, colecciones y evidencias) permanece intacto. |

---

## 5. Herramientas y Documentación Entregadas

1. **Guía de Uso del Módulo**: [demo-config/README.md](../README.md).
2. **Guion para Sustentación (5-7 min)**: [demo-config/docs/DEMOSTRACION.md](DEMOSTRACION.md).
3. **Colección Postman**: [demo-config/postman/PasoFirme-Config.postman_collection.json](../postman/PasoFirme-Config.postman_collection.json) (11 solicitudes organizadas en 3 carpetas con tests automáticos).
4. **Script de Verificación en PowerShell**: [demo-config/scripts/verificar-demo.ps1](../scripts/verificar-demo.ps1) (verificación de solo lectura con código de salida limpio).

---

## 6. Registro de Tareas Pendientes para Futuras Entregas

Conforme a las instrucciones del proyecto, los siguientes materiales complementarios quedan identificados pero **no forman parte de esta entrega técnica**:
- **Mini Guía Técnica en formato PDF**.
- **Presentación en diapositivas PPT** (máximo 8 diapositivas para sustentación grupal).
- **(Opcional) Etapa 07**: Página HTML sencilla en `catalogo-demo` para visualización web interactiva en navegador.
