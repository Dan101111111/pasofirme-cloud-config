# Guía y Registro de GitHub: `pasofirme-config-repo` y `pasofirme-cloud-config`

**Proyecto**: PasoFirme  
**Subproyecto / Módulo**: `demo-config/`  
**Documento**: `demo-config/docs/GITHUB.md`  
**Fecha de actualización**: 8 de noviembre de 2026  
**Estado de `pasofirme-config-repo`**: **PUBLICADO Y VERIFICADO EN VIVO** (Commit: `47d0249798495bf2cf4c46fc471134aaa42a4d68`)  
**Estado de `pasofirme-cloud-config`**: **CREADO / EN ESPERA** (Se subirá cuando avance el código de la demo)  

---

## 1. Repositorios Remotos Oficiales

| Repositorio | URL Oficial HTTPS | Rama Principal | Propósito | Estado |
|---|---|:---:|---|:---:|
| **Configuración** | `https://github.com/Dan101111111/pasofirme-config-repo.git` | `main` | Almacén de archivos `.properties` para Spring Cloud Config Server. | **OPERATIVO** (Commit `47d0249`) |
| **Código Fuente** | `https://github.com/Dan101111111/pasofirme-cloud-config.git` | `main` | Repositorio general de código de PasoFirme y `demo-config/`. | **EN ESPERA** |  

---

## 1. Mapeo de Correspondencia entre Spring y Archivos Git

Spring Cloud Config Server resuelve las propiedades aplicando la convención estándar del servidor:
`/{application}/{profile}/{label}`

Para que cada microservicio cliente recupere su configuración, la correspondencia entre sus identificadores de aplicación, el perfil activo y el archivo físico en el repositorio Git es la siguiente:

| `spring.application.name` | Perfil (`spring.profiles.active`) | Rama (`label`) | Archivo en la raíz del repositorio | URL de consulta en Config Server |
|---|---|:---:|---|---|
| *(Común a todos)* | *(Cualquiera)* | `main` | `application.properties` | Consolidado en cualquier consulta |
| `catalogo-demo` | `dev` | `main` | `catalogo-demo-dev.properties` | `http://localhost:18888/catalogo-demo/dev/main` |
| `catalogo-demo` | `prod` | `main` | `catalogo-demo-prod.properties` | `http://localhost:18888/catalogo-demo/prod/main` |
| `ofertas-demo` | `dev` | `main` | `ofertas-demo-dev.properties` | `http://localhost:18888/ofertas-demo/dev/main` |
| `ofertas-demo` | `prod` | `main` | `ofertas-demo-prod.properties` | `http://localhost:18888/ofertas-demo/prod/main` |
| `envios-demo` | `dev` | `main` | `envios-demo-dev.properties` | `http://localhost:18888/envios-demo/dev/main` |
| `envios-demo` | `prod` | `main` | `envios-demo-prod.properties` | `http://localhost:18888/envios-demo/prod/main` |

---

## 2. Instrucciones para Crear el Repositorio en GitHub (Interfaz Web)

Para habilitar la lectura remota sin requerir tokens personales (PAT) en la máquina de exposición, se recomienda crear el repositorio de configuración como **público**:

1. **Iniciar sesión en GitHub**: Ingrese con la cuenta del integrante designado a [https://github.com/](https://github.com/).
2. **Crear nuevo repositorio**:
   - Haga clic en el botón **`New`** (o diríjase a `https://github.com/new`).
   - **Repository name**: `pasofirme-config-repo`.
   - **Description**: `Repositorio centralizado de propiedades para PasoFirme Spring Cloud Config`.
   - **Visibility**: Seleccionar **`Public`**.
   - **Initialize this repository with**: No marcar "Add a README file" (se subirá el README preparado localmente).
   - Haga clic en **`Create repository`**.
3. **Subir los archivos preparados**:
   - En la pantalla inicial del repositorio recién creado, seleccione el enlace **`uploading an existing file`** (o en la barra de herramientas: `Add file` > `Upload files`).
   - Arrastre o seleccione los siguientes **8 archivos** ubicados localmente en `demo-config/configuracion-ejemplo/`:
     - `application.properties`
     - `catalogo-demo-dev.properties`
     - `catalogo-demo-prod.properties`
     - `ofertas-demo-dev.properties`
     - `ofertas-demo-prod.properties`
     - `envios-demo-dev.properties`
     - `envios-demo-prod.properties`
     - `README.md`
   - En el campo de commit, coloque: `feat: carga inicial de configuraciones para demo PasoFirme`.
   - Asegúrese de que la opción seleccionada sea **`Commit directly to the main branch`**.
   - Haga clic en **`Commit changes`**.
4. **Verificar rama principal**:
   - Confirme que los archivos se encuentren directamente en la **raíz** de la rama `main` (no dentro de subcarpetas).

---

## 3. Obtención de la URL Remota (`CONFIG_GIT_URI`)

Una vez creado el repositorio, obtenga la URL HTTPS oficial de clonación:

1. En la página principal del repositorio en GitHub, haga clic en el botón verde **`<> Code`**.
2. En la pestaña **`HTTPS`**, copie la dirección completa.
3. La URL debe tener exactamente el siguiente formato:
   ```text
   https://github.com/<USUARIO-O-ORGANIZACION>/pasofirme-config-repo.git
   ```

### Advertencias Críticas sobre el Formato de URL:
> [!WARNING] Errores comunes al configurar la URI de Git
> - **NO** utilice URLs de contenido plano tipo `raw`: `https://raw.githubusercontent.com/...` (JGit no puede clonar ni leer metadatos de Git desde endpoints raw).
> - **NO** utilice URLs del explorador web con rama: `https://github.com/.../tree/main` (esto es una página HTML de GitHub, no un repositorio Git).
> - **NO** utilice la URL directa a un archivo `.properties` o `/blob/main/...`.
> - Spring Cloud Config Server requiere el protocolo Git estándar sobre HTTPS que termina en `.git` para realizar operaciones de clonación y lectura de commits.

---

## 4. Parametrización mediante `CONFIG_GIT_URI`

Para evitar introducir nombres de usuario o credenciales codificadas en duro en el código fuente, la URL del repositorio se parametrizará en `config-server-demo` mediante la variable de entorno:

```properties
spring.cloud.config.server.git.uri=${CONFIG_GIT_URI}
spring.cloud.config.server.git.default-label=main
```

- En entorno local PowerShell:
  ```powershell
  $env:CONFIG_GIT_URI="https://github.com/<USUARIO-O-ORGANIZACION>/pasofirme-config-repo.git"
  ```
- En entorno Docker (`demo-config/.env`):
  ```properties
  CONFIG_GIT_URI=https://github.com/<USUARIO-O-ORGANIZACION>/pasofirme-config-repo.git
  ```

---

## 5. Estado de la Dependencia Externa y Política de Bloqueo

- **Estado actual**: **PENDIENTE DE CREACIÓN REMOTA**.
- **Impacto en el desarrollo**:
  - La ausencia temporal de la URL remota en GitHub **NO bloquea** la codificación, estructuración de POMs, configuración de Maven Wrapper ni la verificación de compilación (`mvn clean compile`) de los microservicios Java (`config-server-demo`, `catalogo-demo`, `ofertas-demo`, `envios-demo`).
  - Únicamente las pruebas de integración en vivo (comprobación de endpoints de red y lectura de commits Git) quedarán a la espera de que el usuario proporcione la URL real creada.

