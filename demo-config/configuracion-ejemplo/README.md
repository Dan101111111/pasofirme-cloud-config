# pasofirme-config-repo

Repositorio centralizado de configuraciones para la demostración de **Spring Cloud Config** del sistema **PasoFirme**.

Este repositorio contiene exclusivamente archivos de propiedades de presentación (`.properties`) consumidos por el microservicio `config-server-demo` y distribuidos dinámicamente a los servicios clientes.

---

## 1. Convención de Nomenclatura y Resolución Jerárquica

Spring Cloud Config resuelve las propiedades basándose en la convención `{application}-{profile}.properties`:

| Archivo | `spring.application.name` | Perfil (`spring.profiles.active`) | Propósito y Contenido |
|---|---|---|---|
| `application.properties` | *Todos* (Común) | *Todos* (Global) | Propiedades compartidas (`demo.tienda`, `demo.edicion`). |
| `catalogo-demo-dev.properties` | `catalogo-demo` | `dev` | Catálogo de calzado deportivo y casual (pruebas locales). |
| `catalogo-demo-prod.properties` | `catalogo-demo` | `prod` | Catálogo oficial de calzado alta gama (producción). |
| `ofertas-demo-dev.properties` | `ofertas-demo` | `dev` | Descuento piloto 10% en calzado urbano. |
| `ofertas-demo-prod.properties` | `ofertas-demo` | `prod` | Campaña oficial de hasta 35% de descuento en calzado de cuero. |
| `envios-demo-dev.properties` | `envios-demo` | `dev` | Entrega demostrativa estándar 48 horas en zona urbana. |
| `envios-demo-prod.properties` | `envios-demo` | `prod` | Red logística nacional express 24 horas con rastreo. |

---

## 2. Política de Seguridad y Datos

- **Sin credenciales**: Este repositorio no contiene contraseñas, tokens de acceso, secretos de base de datos ni cadenas de conexión `spring.datasource.*`.
- **Datos ficticios de presentación**: Todas las propiedades corresponden a cadenas de texto demostrativas para validar la inyección y actualización dinámica en caliente.
- **Rama principal**: Todas las lecturas del Config Server apuntan a la rama `main`.

