package com.pasofirme.configdemo.envios;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.config.import=",
    "demo.tienda=PasoFirme Test",
    "demo.edicion=Exposicion Test",
    "demo.mensaje=Envios Test",
    "demo.detalle=Detalle Test"
})
class EnviosDemoApplicationTests {

    @Test
    void contextLoads() {
    }
}

