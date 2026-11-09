# Guion de Demostración: Spring Cloud Config en PasoFirme

**Duración estimada**: 5 a 7 minutos  
**Objetivo**: Demostrar en vivo la centralización de configuraciones respaldada por un repositorio remoto de GitHub, la entrega jerárquica a tres microservicios clientes y la actualización dinámica en caliente mediante `@RefreshScope` sin reinicio de contenedores ni pérdida de estado de la JVM.

---

## 1. Lista de Preparación Previa al Día de la Exposición (Checklist)

Antes de iniciar la sesión de sustentación, verifique cada uno de los siguientes puntos:

- [ ] **Docker Desktop en Ejecución**: Motor de contenedores activo y saludable.
- [ ] **Acceso a Internet**: Conexión activa a `github.com`, `docker.io` y `repo.maven.apache.org`.
- [ ] **Puertos Libres en la Máquina**: Comprobar que `18888`, `18881`, `18882` y `18883` no estén ocupados por procesos externos.
- [ ] **Credenciales de GitHub Listas**: Un integrante del grupo debe tener abierta la sesión en [https://github.com/Dan101111111/pasofirme-config-repo](https://github.com/Dan101111111/pasofirme-config-repo) para editar archivos desde la interfaz web durante la prueba.
- [ ] **Postman o Script de Verificación**: Colección [demo-config/postman/PasoFirme-Config.postman_collection.json](../postman/PasoFirme-Config.postman_collection.json) importada en Postman o terminal con [demo-config/scripts/verificar-demo.ps1](../scripts/verificar-demo.ps1).
- [ ] **Contingencia por Falla de Red**: Si la red institucional bloquea el acceso a GitHub o se corta Internet, se puede apuntar temporalmente la variable `CONFIG_GIT_URI` a un repositorio Git local (`file:///...`); sin embargo, se debe explicar al evaluador que el flujo principal diseñado opera contra GitHub.

---

## 2. Guion Minuto a Minuto de la Demostración (5 a 7 minutos)

### Minuto 0:00 - 1:30 | Arranque y Arquitectura General
1. **Explicación Inicial (30 s)**:
   - *"El sistema PasoFirme desacopla la configuración de sus microservicios utilizando Spring Cloud Config respaldado por el repositorio remoto `pasofirme-config-repo` en GitHub. Disponemos de cuatro aplicaciones contenerizadas: un Config Server (puerto 18888) y tres clientes independientes: Catálogo (18881), Ofertas (18882) y Envíos (18883)."*
2. **Arranque Limpio**:
   - En una terminal en la raíz de `PasoFirme`, ejecute:
     ```powershell
     docker compose --env-file demo-config/.env -f demo-config/compose.yaml up -d
     docker compose --env-file demo-config/.env -f demo-config/compose.yaml ps
     ```
   - Señale que los cuatro contenedores reportan estado **`(healthy)`**.

---

### Minuto 1:30 - 2:30 | Inspección del Estado Inicial y Trazabilidad Git
1. **Abrir en Navegador / Postman las Consultas Iniciales**:
   - Abrir `http://localhost:18888/catalogo-demo/dev/main` (Config Server):
     - Señale el campo **`version`**: muestra el hash exacto del commit actual en GitHub (ej. `013b6e49407...`).
     - Señale las **`propertySources`**: demuestre la jerarquía donde `application.properties` aporta `demo.tienda=PasoFirme` y `catalogo-demo-dev.properties` aporta el mensaje y detalle de desarrollo.
2. **Mostrar los Tres Clientes**:
   - Catálogo: `http://localhost:18881/api/demo`
   - Ofertas: `http://localhost:18882/api/demo`
   - Envíos: `http://localhost:18883/api/demo`
   - Resalte el campo **`instanciaArranque`** en cada uno: es un UUID generado una sola vez en un bean singleton no refrescable. Pida a la audiencia anotar los primeros caracteres del UUID de Catálogo.

---

### Minuto 2:30 - 4:00 | Modificación en Vivo en GitHub
1. **Edición Remota en GitHub**:
   - El integrante proyecta o abre en su navegador el repositorio:  
     `https://github.com/Dan101111111/pasofirme-config-repo/blob/main/catalogo-demo-dev.properties`
   - Hace clic en el icono del lápiz (**Edit this file**).
   - Modifica el valor de `demo.mensaje`:
     ```properties
     demo.mensaje=Catalogo Calzado Deportivo 2026 - Edicion Especial Sustentacion
     ```
   - En la parte inferior, escribe el mensaje de commit: `demo: actualizacion de mensaje para sustentacion en vivo`.
   - Hace clic en **Commit changes** (directo a la rama `main`).
2. **Inspección de Config Server (Lectura Inmediata)**:
   - Regrese a `http://localhost:18888/catalogo-demo/dev/main` y refresque la página (F5):
   - Muestre que Config Server ya detectó el **nuevo commit SHA** y ya tiene el nuevo mensaje en sus `propertySources`.
3. **Inspección del Cliente Catálogo (Persistencia en Memoria)**:
   - Abra `http://localhost:18881/api/demo` y refresque (F5):
   - **Punto Clave Pedagógico**: El cliente **aún muestra el mensaje anterior**. Explique:
     - *"El cliente no sondea permanentemente a GitHub ni al Config Server. Los cambios remotos no impactan la memoria del servicio hasta que se solicita explícitamente una actualización."*

---

### Minuto 4:00 - 5:30 | Refresco Dinámico en Caliente (`POST /actuator/refresh`)
1. **Llamada de Refresco**:
   - En Postman (o mediante terminal PowerShell), ejecute la petición `POST` al endpoint de Actuator:
     ```powershell
     Invoke-RestMethod -Method Post -Uri "http://localhost:18881/actuator/refresh" -ContentType "application/json"
     ```
   - Muestre la respuesta: devuelve las claves que fueron recargadas: `["config.client.version", "demo.mensaje"]`.
   - *Nota pedagógica*: Explique que `/actuator/refresh` es una operación de escritura/administración y por diseño de Spring Boot **debe invocarse con método POST**, no con GET desde la barra de direcciones del navegador.
2. **Comprobación de Actualización sin Reinicio**:
   - Abra nuevamente `http://localhost:18881/api/demo`:
     - El campo `mensaje` **ahora muestra el nuevo valor** modificado en GitHub.
     - El campo `instanciaArranque` **continúa siendo exactamente el mismo UUID inicial**.
   - Conclusión técnica: *"El bean `@RefreshScope` recargó la propiedad sin necesidad de recompilar, reconstruir la imagen ni reiniciar el contenedor Docker."*

---

### Minuto 5:30 - 7:00 | Aislamiento entre Servicios y Manejo de Perfiles
1. **Demostración de Aislamiento**:
   - Consulte Ofertas (`http://localhost:18882/api/demo`) y Envíos (`http://localhost:18883/api/demo`):
   - Muestre que sus valores y UUIDs no sufrieron ningún cambio, demostrando el aislamiento estricto por microservicio.
   - Explique la diferencia:
     - *"Si modificáramos `application.properties` (ej. el nombre de la tienda), esa propiedad afectaría a los tres servicios, pero cada uno requeriría su propio `POST /actuator/refresh` para aplicarla."*
2. **Manejo de Perfiles (`dev` vs. `prod`)**:
   - Explique con base en el código:
     - *"Cada servicio resuelve `catalogo-demo-dev.properties` o `catalogo-demo-prod.properties` según `spring.profiles.active`. Un cambio de perfil define la identidad de despliegue del contenedor; por seguridad y principios de inmutabilidad de 12-Factor App, cambiar de perfil requiere recrear el contenedor con `DEMO_PROFILE=prod`, no un simple refresco en caliente."*

---

## 3. Matriz Rápida de Preguntas y Respuestas para los Evaluadores

| Pregunta Típica del Evaluador | Respuesta Técnica Precisa |
|---|---|
| **¿Por qué los clientes no se actualizan solos al hacer push en GitHub?** | Porque en arquitecturas distribuidas un refresh automático no coordinado provocaría recargas descontroladas. El refresco dinámico se dispara de forma gobernada (operación manual o mediante un pipeline de CI/CD que invoca `/actuator/refresh`). |
| **¿Se reinició el contenedor de Catálogo?** | No. El UUID de `instanciaArranque` demuestra que el bean singleton de la JVM mantuvo su ciclo de vida continuo. Solo el bean proxy anotado con `@RefreshScope` fue destruido y recreado. |
| **¿Las peticiones de los usuarios pasan por el Config Server?** | No. El Config Server solo interviene en el arranque del cliente y ante eventos de `/refresh`. Las peticiones de negocio van directamente a cada microservicio cliente. |
| **¿La demo usa la base de datos MySQL o Eureka de PasoFirme?** | No. Para mantener la demostración ligera y portátil, se desacopló completamente de persistencia y descubrimiento, operando como un subsistema autónomo. |

