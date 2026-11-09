package com.pasofirme.configdemo.envios;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Controlador REST que expone el estado consolidado de la configuración
 * del servicio de logística y envíos de calzado.
 */
@RestController
@RequestMapping("/api/demo")
public class DemoController {

    private final EnviosConfigProperties configProperties;
    private final InstanciaArranqueHolder instanciaHolder;

    @Value("${spring.application.name}")
    private String servicio;

    @Value("${spring.profiles.active:dev}")
    private String perfil;

    public DemoController(EnviosConfigProperties configProperties, InstanciaArranqueHolder instanciaHolder) {
        this.configProperties = configProperties;
        this.instanciaHolder = instanciaHolder;
    }

    @GetMapping
    public DemoResponse getDemo() {
        return new DemoResponse(
            servicio,
            perfil,
            configProperties.getTienda(),
            configProperties.getEdicion(),
            configProperties.getMensaje(),
            configProperties.getDetalle(),
            instanciaHolder.getInstanciaArranque()
        );
    }
}

