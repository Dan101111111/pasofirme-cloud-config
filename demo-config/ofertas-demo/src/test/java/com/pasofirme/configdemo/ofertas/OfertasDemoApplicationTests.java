package com.pasofirme.configdemo.ofertas;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.config.import=",
    "demo.tienda=PasoFirme Test",
    "demo.edicion=Exposicion Test",
    "demo.mensaje=Ofertas Test",
    "demo.detalle=Detalle Test"
})
class OfertasDemoApplicationTests {

    @Test
    void contextLoads() {
    }
}

