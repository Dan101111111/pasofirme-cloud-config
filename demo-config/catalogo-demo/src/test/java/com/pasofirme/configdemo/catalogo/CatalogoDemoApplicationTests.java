package com.pasofirme.configdemo.catalogo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.config.import=",
    "demo.tienda=PasoFirme Test",
    "demo.edicion=Exposicion Test",
    "demo.mensaje=Catalogo Test",
    "demo.detalle=Detalle Test"
})
class CatalogoDemoApplicationTests {

    @Test
    void contextLoads() {
    }
}

